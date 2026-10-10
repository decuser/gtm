unit gtmtui;

{$mode objfpc}{$H+}

interface

procedure RunTUI(const RepoArg, BranchArg: string);

implementation

uses
  Classes, SysUtils, StrUtils, Process, ctypes, ncurses, gtmcore, gtmstate;

{$I gtmversion.inc}

function c_setenv(Name, Value: PChar; Overwrite: cint): cint; cdecl;
  external 'c' name 'setenv';

const
  PairNormal = 1;
  PairTitle = 2;
  PairSelected = 3;
  PairDim = 4;

procedure InitColors;
begin
  if has_colors then
  begin
    start_color;
    use_default_colors;
    init_pair(PairNormal, COLOR_WHITE, -1);
    init_pair(PairTitle, COLOR_WHITE, COLOR_BLUE);
    init_pair(PairSelected, COLOR_BLACK, COLOR_WHITE);
    init_pair(PairDim, COLOR_BLACK, -1);
  end;
end;

procedure UsePair(PairNo: SmallInt);
begin
  if has_colors then
    attrset(COLOR_PAIR(PairNo))
  else
  begin
    case PairNo of
      PairTitle: attrset(A_REVERSE);
      PairSelected: attrset(A_REVERSE);
      PairDim: attrset(A_DIM);
    else
      attrset(A_NORMAL);
    end;
  end;
end;

procedure PutText(X, Y: Integer; const S: string; PairNo: SmallInt);
begin
  if (X < 0) or (Y < 0) then
    Exit;
  UsePair(PairNo);
  mvaddnstr(Y, X, PChar(S), Length(S));
end;

procedure FillRow(Y: Integer; PairNo: SmallInt);
var
  W: Integer;
begin
  W := COLS;
  UsePair(PairNo);
  move(Y, 0);
  hline(Ord(' '), W);
end;

procedure ClearScreen;
begin
  erase;
end;

procedure DrawBox(X1, Y1, X2, Y2: Integer; PairNo: SmallInt);
begin
  UsePair(PairNo);
  mvaddch(Y1, X1, ACS_ULCORNER);
  mvaddch(Y1, X2, ACS_URCORNER);
  mvaddch(Y2, X1, ACS_LLCORNER);
  mvaddch(Y2, X2, ACS_LRCORNER);
  mvhline(Y1, X1 + 1, ACS_HLINE, X2 - X1 - 1);
  mvhline(Y2, X1 + 1, ACS_HLINE, X2 - X1 - 1);
  mvvline(Y1 + 1, X1, ACS_VLINE, Y2 - Y1 - 1);
  mvvline(Y1 + 1, X2, ACS_VLINE, Y2 - Y1 - 1);
end;

function StripDecoration(const S: string): string;
begin
  Result := S;
  if RightStr(Result, 8) = ' [added]' then
    Delete(Result, Length(Result) - 7, 8)
  else if RightStr(Result, 11) = ' [modified]' then
    Delete(Result, Length(Result) - 10, 11)
  else if RightStr(Result, 10) = ' [deleted]' then
    Delete(Result, Length(Result) - 9, 10);
end;

function IsDeletedEntry(const S: string): Boolean;
begin
  Result := RightStr(S, 10) = ' [deleted]';
end;

function IsDirectoryEntry(const S: string): Boolean;
var
  T: string;
begin
  T := StripDecoration(S);
  Result := (T <> '') and (T[Length(T)] = '/');
end;

function EntryName(const S: string): string;
begin
  Result := StripDecoration(S);
  while (Result <> '') and (Result[Length(Result)] = '/') do
    Delete(Result, Length(Result), 1);
end;

function JoinPath(const BasePath, Name: string): string;
begin
  if BasePath = '' then
    Result := Name
  else
    Result := BasePath + '/' + Name;
end;

function ParentPath(const Path: string): string;
var
  P: Integer;
begin
  if Path = '' then
    Exit('');
  P := LastDelimiter('/', Path);
  if P = 0 then
    Result := ''
  else
    Result := Copy(Path, 1, P - 1);
end;

function RunAttached(const Executable: string;
  const Args: array of string): Integer;
var
  P: TProcess;
  I: Integer;
begin
  Result := -1;
  P := TProcess.Create(nil);
  try
    P.Executable := Executable;
    for I := Low(Args) to High(Args) do
      P.Parameters.Add(Args[I]);
    P.Options := [];
    try
      P.Execute;
      P.WaitOnExit;
      Result := P.ExitStatus;
    except
      Result := -1;
    end;
  finally
    P.Free;
  end;
end;

procedure SuspendCurses;
begin
  endwin;
end;

procedure ResumeCurses;
begin
  erase;
  refresh;
end;

procedure WaitForReturn;
begin
  WriteLn;
  Write('Press Enter to return to GTM...');
  ReadLn;
end;

procedure OpenInEditor(const FileName: string; var Status: string);
var
  Editor: string;
  Code: Integer;
begin
  Editor := GetEnvironmentVariable('EDITOR');
  if Trim(Editor) = '' then
    Editor := 'vi';

  SuspendCurses;
  try
    Code := RunAttached(Editor, [FileName]);
    if Code <> 0 then
      Status := 'editor exited with status ' + IntToStr(Code)
    else
      Status := 'opened ' + FileName;
  finally
    ResumeCurses;
  end;
end;

procedure ShowTextViewer(const TitleText: string; Lines: TStrings);
var
  W, H, TopIndex, VisibleRows, Row, I: Integer;
  K: LongInt;
begin
  TopIndex := 0;

  while True do
  begin
    getmaxyx(stdscr, H, W);
    ClearScreen;
    FillRow(0, PairTitle);
    PutText(1, 0, Copy(TitleText, 1, W - 2), PairTitle);

    VisibleRows := H - 2;
    if VisibleRows < 1 then
      VisibleRows := 1;

    if TopIndex < 0 then
      TopIndex := 0;
    if TopIndex > Lines.Count - VisibleRows then
      TopIndex := Lines.Count - VisibleRows;
    if TopIndex < 0 then
      TopIndex := 0;

    for Row := 0 to VisibleRows - 1 do
    begin
      I := TopIndex + Row;
      if I >= Lines.Count then
        Break;
      PutText(0, Row + 1, Copy(Lines[I], 1, W), PairNormal);
    end;

    FillRow(H - 1, PairTitle);
    PutText(1, H - 1, 'Up/Down PgUp/PgDn  F10/q Close', PairTitle);
    refresh;

    K := getch;
    if (K = KEY_F(10)) or (K = Ord('q')) or (K = Ord('Q')) then
      Exit
    else if K = KEY_UP then
    begin
      if TopIndex > 0 then
        Dec(TopIndex);
    end
    else if K = KEY_DOWN then
    begin
      if TopIndex < Lines.Count - VisibleRows then
        Inc(TopIndex);
    end
    else if K = KEY_PPAGE then
    begin
      Dec(TopIndex, VisibleRows);
      if TopIndex < 0 then
        TopIndex := 0;
    end
    else if K = KEY_NPAGE then
    begin
      Inc(TopIndex, VisibleRows);
      if TopIndex > Lines.Count - VisibleRows then
        TopIndex := Lines.Count - VisibleRows;
      if TopIndex < 0 then
        TopIndex := 0;
    end;
  end;
end;

procedure SideBySideDiff(const OldFile, NewFile: string; var Status: string);
const
  BufferSize = 8192;
type
  TReadBuffer = array[0..BufferSize - 1] of Byte;
var
  P: TProcess;
  SSOut, SSErr: TStringStream;
  Buffer: TReadBuffer;
  N, ExitCode: Integer;
  Lines: TStringList;
  ErrText: string;
begin
  Buffer := Default(TReadBuffer);
  P := TProcess.Create(nil);
  SSOut := TStringStream.Create('');
  SSErr := TStringStream.Create('');
  Lines := TStringList.Create;
  try
    P.Executable := 'diff';
    P.Parameters.Add('-y');
    P.Parameters.Add(OldFile);
    P.Parameters.Add(NewFile);
    P.Options := [poUsePipes];

    try
      P.Execute;
    except
      on E: Exception do
      begin
        Status := 'unable to run diff: ' + E.Message;
        Exit;
      end;
    end;

    repeat
      while P.Output.NumBytesAvailable > 0 do
      begin
        N := P.Output.Read(Buffer, SizeOf(Buffer));
        if N > 0 then
          SSOut.WriteBuffer(Buffer, N);
      end;

      while P.Stderr.NumBytesAvailable > 0 do
      begin
        N := P.Stderr.Read(Buffer, SizeOf(Buffer));
        if N > 0 then
          SSErr.WriteBuffer(Buffer, N);
      end;

      if P.Running then
        Sleep(1);
    until (not P.Running) and
          (P.Output.NumBytesAvailable = 0) and
          (P.Stderr.NumBytesAvailable = 0);

    ExitCode := P.ExitStatus;
    if ExitCode > 255 then
      ExitCode := ExitCode shr 8;

    if ExitCode > 1 then
    begin
      ErrText := Trim(SSErr.DataString);
      if ErrText = '' then
        ErrText := 'exit status ' + IntToStr(ExitCode);
      Status := 'diff failed: ' + ErrText;
      Exit;
    end;

    Lines.Text := StringReplace(SSOut.DataString, #13, '', [rfReplaceAll]);
    if Lines.Count = 0 then
      Lines.Add('(no differences)');

    ShowTextViewer('Visual Diff', Lines);
    Status := 'diff complete';
  finally
    Lines.Free;
    SSErr.Free;
    SSOut.Free;
    P.Free;
  end;
end;

function SelectedRepoPath(const State: TGTMState;
  Entries: TStringList; Selected: Integer): string;
var
  Name: string;
begin
  Result := '';
  if (Selected < 0) or (Selected >= Entries.Count) then
    Exit;
  if IsDeletedEntry(Entries[Selected]) or IsDirectoryEntry(Entries[Selected]) then
    Exit;

  Name := EntryName(Entries[Selected]);
  Result := JoinPath(State.CurrentPath, Name);
end;

function TempPathForCommit(const CommitHash, RepoPath: string): string;
var
  BaseRoot: string;
begin
  BaseRoot := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'gtm' +
    DirectorySeparator + Copy(CommitHash, 1, 8);
  Result := IncludeTrailingPathDelimiter(BaseRoot) +
    StringReplace(RepoPath, '/', DirectorySeparator, [rfReplaceAll]);
end;

procedure MaterializeTempFile(const State: TGTMState; const CommitHash,
  RepoPath: string; out TempFile: string);
var
  ParentDir: string;
begin
  TempFile := TempPathForCommit(CommitHash, RepoPath);
  ParentDir := ExtractFileDir(TempFile);
  if not ForceDirectories(ParentDir) then
    Die('unable to create temporary directory: ' + ParentDir);
  ExtractFile(State.Repo, CommitHash, RepoPath, TempFile);
end;

function HistoryHashFromLine(const Line: string): string;
var
  T: string;
  P1, P2: Integer;
begin
  Result := '';
  T := Line;
  P1 := Pos('  ', T);
  if P1 = 0 then
    Exit;

  Delete(T, 1, P1 + 1);
  while (T <> '') and (T[1] = ' ') do
    Delete(T, 1, 1);

  P2 := Pos('  ', T);
  if P2 = 0 then
    Result := Trim(T)
  else
    Result := Trim(Copy(T, 1, P2 - 1));
end;

function FullHistoryHash(const State: TGTMState; const ShortHash: string): string;
begin
  Result := ResolveCommitAbbreviation(State.BranchIndex, ShortHash);
end;

procedure SelectCommitHashTUI(var State: TGTMState; const CommitHash: string;
  Entries: TStringList; var Selected, TopIndex: Integer; var Status: string);
var
  FullHash: string;
  I: Integer;
begin
  if CommitHash = '' then
    Exit;

  FullHash := ResolveCommitAbbreviation(State.BranchIndex, CommitHash);
  if State.Timeline.IndexOf(FullHash) < 0 then
    BuildStateTimeline(State, FullHash);

  I := State.Timeline.IndexOf(FullHash);
  if I < 0 then
    Exit;

  if not SelectStateTimelineIndex(State, I) then
    Exit;

  State.SelectedCommitTime := CommitUnixTime(State.Repo, State.CommitHash);
  EnsureStateCurrentPath(State);
  BuildStateDirectoryDisplay(State, Entries);
  Selected := 0;
  TopIndex := 0;
  Status := CommitSubject(State.Repo, State.CommitHash);
end;

procedure LoadEntries(var State: TGTMState; Entries: TStringList);
begin
  EnsureStateCurrentPath(State);
  BuildStateDirectoryDisplay(State, Entries);
end;

procedure SelectBranchPosition(var State: TGTMState; NewPosition: Integer;
  Entries: TStringList; var Selected, TopIndex: Integer; var Status: string);
var
  TimelineIndex: Integer;
begin
  if State.BranchIndex.Count = 0 then
    Exit;

  if NewPosition < 0 then
    NewPosition := 0;
  if NewPosition >= State.BranchIndex.Count then
    NewPosition := State.BranchIndex.Count - 1;

  if NewPosition = State.CurrentBranchPosition then
    Exit;

  BuildStateTimeline(State, State.BranchIndex[NewPosition]);
  TimelineIndex := State.Timeline.IndexOf(State.BranchIndex[NewPosition]);
  if (TimelineIndex < 0) or
     (not SelectStateTimelineIndex(State, TimelineIndex)) then
    Exit;

  EnsureStateCurrentPath(State);
  BuildStateDirectoryDisplay(State, Entries);
  Selected := 0;
  TopIndex := 0;
  Status := CommitSubject(State.Repo, State.CommitHash);
end;

function AccelStep(RepeatCount: Integer): Integer;
begin
  if RepeatCount >= 12 then
    Result := 10
  else if RepeatCount >= 7 then
    Result := 5
  else if RepeatCount >= 3 then
    Result := 2
  else
    Result := 1;
end;

procedure ClampSelection(Entries: TStringList; var Selected, TopIndex: Integer;
  VisibleRows: Integer);
begin
  if Entries.Count = 0 then
    Selected := -1
  else
  begin
    if Selected < 0 then
      Selected := 0;
    if Selected >= Entries.Count then
      Selected := Entries.Count - 1;
  end;

  if TopIndex < 0 then
    TopIndex := 0;
  if (Selected >= 0) and (Selected < TopIndex) then
    TopIndex := Selected;
  if (Selected >= 0) and (Selected >= TopIndex + VisibleRows) then
    TopIndex := Selected - VisibleRows + 1;
  if TopIndex < 0 then
    TopIndex := 0;
end;

procedure DrawDialog(const Title: string; Lines: array of string);
var
  W, H, BoxW, BoxH, X1, Y1, X2, Y2, I, MaxLen: Integer;
begin
  getmaxyx(stdscr, H, W);
  MaxLen := Length(Title) + 4;
  for I := Low(Lines) to High(Lines) do
    if Length(Lines[I]) + 4 > MaxLen then
      MaxLen := Length(Lines[I]) + 4;

  BoxW := MaxLen;
  if BoxW < 32 then BoxW := 32;
  if BoxW > W - 4 then BoxW := W - 4;

  BoxH := Length(Lines) + 4;
  if BoxH > H - 2 then BoxH := H - 2;

  X1 := (W - BoxW) div 2;
  Y1 := (H - BoxH) div 2;
  X2 := X1 + BoxW - 1;
  Y2 := Y1 + BoxH - 1;

  ClearScreen;
  DrawBox(X1, Y1, X2, Y2, PairTitle);
  PutText(X1 + 2, Y1, ' ' + Title + ' ', PairTitle);

  for I := Low(Lines) to High(Lines) do
  begin
    if Y1 + 2 + (I - Low(Lines)) >= Y2 then Break;
    PutText(X1 + 2, Y1 + 2 + (I - Low(Lines)),
      Copy(Lines[I], 1, BoxW - 4), PairNormal);
  end;

  PutText(X1 + 2, Y2 - 1, 'Press any key', PairDim);
  refresh;
  getch;
end;

procedure ShowKeyHelp;
begin
  DrawDialog('Help - Keys', [
    'Up / Down       previous / next entry',
    'Left            parent directory',
    'Right / Enter   enter directory / open',
    'Home / End      first / last entry',
    'Backspace       parent directory',
    'o               open selected file',
    'h               file history',
    'v               visual diff vs predecessor',
    'Ctrl-Left/Right commit slider',
    'Ctrl-Up/Down    time slider',
    'Ctrl-Home/End   first / last commit',
    'Ctrl-PgUp/PgDn  latest / earliest time',
    'F1              this help',
    'F2              menu',
    'F10 / q         close / quit'
  ]);
end;

procedure ShowMenuHelp;
begin
  DrawDialog('Help - Menu', [
    'Up / Down       select menu item',
    'Enter           activate',
    'F1              this help',
    'q / F10         close menu'
  ]);
end;

procedure ShowHistoryHelp;
begin
  DrawDialog('Help - History', [
    'Up / Down       select revision',
    'j               jump to revision',
    'm               mark / unmark revision',
    'v               visual diff selected/marked revisions',
    'F1              this help',
    'q / F10         close history'
  ]);
end;

procedure ShowAbout;
begin
  DrawDialog('Help - About', [
    'Git Time Machine',
    'Version ' + GTMVersion,
    '',
    'Historical Git snapshots as a filesystem.',
    'TUI: Free Pascal ncurses.'
  ]);
end;

function RawNcursesKeyName(K: LongInt): string;
var
  P: PChar;
begin
  P := keyname(K);
  if P = nil then
    Result := '(none)'
  else
    Result := StrPas(P);
end;

function NcursesKeyName(K: LongInt): string;
begin
  if K = 27 then
    Result := 'Esc'
  else if (K = 10) or (K = 13) then
    Result := 'Enter'
  else if (K = 127) or (K = KEY_BACKSPACE) then
    Result := 'Backspace'
  else if K = KEY_LEFT then
    Result := 'Left'
  else if K = KEY_RIGHT then
    Result := 'Right'
  else if K = KEY_UP then
    Result := 'Up'
  else if K = KEY_DOWN then
    Result := 'Down'
  else if K = KEY_HOME then
    Result := 'Home'
  else if K = KEY_END then
    Result := 'End'
  else if K = KEY_PPAGE then
    Result := 'PageUp'
  else if K = KEY_NPAGE then
    Result := 'PageDown'
  else if K = KEY_F(1) then
    Result := 'F1'
  else if K = KEY_F(2) then
    Result := 'F2'
  else if K = KEY_F(10) then
    Result := 'F10'
  else if (K >= 1) and (K <= 26) then
    Result := 'Ctrl+' + Chr(Ord('A') + K - 1)
  else if (K >= 32) and (K <= 126) then
    Result := Chr(K)
  else
    Result := '$' + IntToHex(K, 4);
end;

procedure ShowControlTest;
var
  W, H, BoxW, BoxH, X1, Y1, X2, Y2: Integer;
  K: LongInt;
  HaveKey: Boolean;

  procedure Draw;
  begin
    ClearScreen;
    DrawBox(X1, Y1, X2, Y2, PairTitle);
    PutText(X1 + 2, Y1, ' Control Test ', PairTitle);
    if not HaveKey then
      PutText(X1 + 2, Y1 + 2, 'Press a key. q/F10 exits.', PairNormal)
    else
    begin
      PutText(X1 + 2, Y1 + 2, 'VKEY:   ' + NcursesKeyName(K), PairSelected);
      PutText(X1 + 2, Y1 + 3, 'ncurses: ' + RawNcursesKeyName(K), PairNormal);
      PutText(X1 + 2, Y1 + 4, 'Code:    ' + IntToStr(K), PairNormal);
      PutText(X1 + 2, Y1 + 5, 'Hex:     $' + IntToHex(K, 4), PairNormal);
      PutText(X1 + 2, Y1 + 7, 'Press another key; q/F10 exits.', PairDim);
    end;
    refresh;
  end;

begin
  getmaxyx(stdscr, H, W);
  BoxW := 62;
  if BoxW > W - 4 then BoxW := W - 4;
  BoxH := 10;
  X1 := (W - BoxW) div 2;
  Y1 := (H - BoxH) div 2;
  X2 := X1 + BoxW - 1;
  Y2 := Y1 + BoxH - 1;

  HaveKey := False;
  Draw;

  while True do
  begin
    K := getch;
    if (K = KEY_F(10)) or (K = Ord('q')) or (K = Ord('Q')) then
      Exit;
    HaveKey := True;
    Draw;
  end;
end;

procedure DrawMenuPopup(ItemIndex: Integer);
const
  Items: array[0..3] of string = (
    'Control Test',
    'Help - Keys',
    'Help - About',
    'File - Quit'
  );
var
  W, H, BoxW, BoxH, X1, Y1, X2, Y2, I, PairNo: Integer;
begin
  getmaxyx(stdscr, H, W);
  BoxW := 26;
  BoxH := 8;
  X1 := (W - BoxW) div 2;
  Y1 := (H - BoxH) div 2;
  X2 := X1 + BoxW - 1;
  Y2 := Y1 + BoxH - 1;

  ClearScreen;
  DrawBox(X1, Y1, X2, Y2, PairTitle);
  PutText(X1 + 2, Y1, ' Menu ', PairTitle);

  for I := 0 to High(Items) do
  begin
    if I = ItemIndex then PairNo := PairSelected else PairNo := PairNormal;
    PutText(X1 + 2, Y1 + 2 + I,
      Copy(Items[I] + StringOfChar(' ', BoxW), 1, BoxW - 4), PairNo);
  end;
  refresh;
end;

function RunMenu: Boolean;
var
  ItemIndex: Integer;
  K: LongInt;
begin
  Result := False;
  ItemIndex := 0;
  while True do
  begin
    DrawMenuPopup(ItemIndex);
    K := getch;

    if K = KEY_F(1) then
      ShowMenuHelp
    else if K = KEY_UP then
    begin
      if ItemIndex > 0 then
        Dec(ItemIndex);
    end
    else if K = KEY_DOWN then
    begin
      if ItemIndex < 3 then
        Inc(ItemIndex);
    end
    else if (K = KEY_F(10)) or (K = Ord('q')) or (K = Ord('Q')) or (K = 27) then
      Exit(False)
    else if (K = 10) or (K = 13) then
    begin
      case ItemIndex of
        0: ShowControlTest;
        1: ShowKeyHelp;
        2: ShowAbout;
        3: Exit(True);
      end;
    end;
  end;
end;

function ShowHistoryPopup(var State: TGTMState; Entries: TStringList;
  var Selected, TopIndex: Integer; var Status: string;
  const RepoPath: string): Boolean;
var
  Lines: TStringList;
  Marks: array of Boolean;
  HistSelected, HistTop, VisibleRows: Integer;
  Mark1, Mark2, I, W, H, BoxTop, BoxBottom, Row: Integer;
  K: LongInt;
  S, Hash1, Hash2, File1, File2: string;
  PairNo: Integer;

  procedure RecountMarks;
  var
    J: Integer;
  begin
    Mark1 := -1;
    Mark2 := -1;
    for J := 0 to High(Marks) do
      if Marks[J] then
      begin
        if Mark1 < 0 then
          Mark1 := J
        else if Mark2 < 0 then
          Mark2 := J;
      end;
  end;

  procedure ClampHistory;
  begin
    if Lines.Count = 0 then
      HistSelected := -1
    else
    begin
      if HistSelected < 0 then HistSelected := 0;
      if HistSelected >= Lines.Count then HistSelected := Lines.Count - 1;
    end;

    if HistTop < 0 then HistTop := 0;
    if (HistSelected >= 0) and (HistSelected < HistTop) then
      HistTop := HistSelected;
    if (HistSelected >= 0) and (HistSelected >= HistTop + VisibleRows) then
      HistTop := HistSelected - VisibleRows + 1;
  end;

  procedure DrawHistory;
  var
    DrawRow: Integer;
  begin
    getmaxyx(stdscr, H, W);
    ClearScreen;
    PutText(1, 0, 'History: ' + RepoPath, PairTitle);
    BoxTop := 1;
    BoxBottom := H - 2;
    DrawBox(0, BoxTop, W - 1, BoxBottom, PairNormal);

    VisibleRows := BoxBottom - BoxTop - 1;
    if VisibleRows < 1 then VisibleRows := 1;
    ClampHistory;

    for DrawRow := 0 to VisibleRows - 1 do
    begin
      I := HistTop + DrawRow;
      if I >= Lines.Count then Break;

      if I = HistSelected then PairNo := PairSelected else PairNo := PairNormal;
      if Marks[I] then
        S := '* ' + Lines[I]
      else
        S := '  ' + Lines[I];
      PutText(2, BoxTop + 1 + DrawRow, Copy(S, 1, W - 4), PairNo);
    end;

    FillRow(H - 1, PairTitle);
    PutText(1, H - 1, 'F1 Help  F10 Close', PairTitle);
    refresh;
  end;

begin
  Result := False;
  Lines := TStringList.Create;
  try
    GetHistory(State.Repo, State.Branch, RepoPath, Lines);
    if Lines.Count = 0 then
    begin
      Status := 'no history found for ' + RepoPath;
      Exit;
    end;

    SetLength(Marks, Lines.Count);
    HistSelected := 0;
    HistTop := 0;
    Mark1 := -1;
    Mark2 := -1;

    while True do
    begin
      DrawHistory;
      K := getch;

      if K = KEY_F(1) then
        ShowHistoryHelp
      else if K = KEY_F(10) then
        Exit
      else if (K = Ord('q')) or (K = Ord('Q')) then
        Exit
      else if K = KEY_UP then
      begin
        if HistSelected > 0 then Dec(HistSelected);
      end
      else if K = KEY_DOWN then
      begin
        if HistSelected < Lines.Count - 1 then Inc(HistSelected);
      end
      else if (K = Ord('m')) or (K = Ord('M')) then
      begin
        if HistSelected >= 0 then
        begin
          if Marks[HistSelected] then
            Marks[HistSelected] := False
          else
          begin
            RecountMarks;
            if (Mark1 >= 0) and (Mark2 >= 0) then
              Marks[Mark2] := False;
            Marks[HistSelected] := True;
          end;
          RecountMarks;
        end;
      end
      else if (K = Ord('j')) or (K = Ord('J')) then
      begin
        if HistSelected >= 0 then
        begin
          Hash1 := HistoryHashFromLine(Lines[HistSelected]);
          SelectCommitHashTUI(State, Hash1, Entries, Selected, TopIndex, Status);
          Result := True;
          Exit;
        end;
      end
      else if (K = Ord('v')) or (K = Ord('V')) then
      begin
        RecountMarks;

        { No marks: selected revision versus its predecessor in file history. }
        if (Mark1 < 0) and (Mark2 < 0) then
        begin
          if (HistSelected < 0) or (HistSelected >= Lines.Count - 1) then
          begin
            Status := 'selected revision has no predecessor';
            Continue;
          end;
          Mark1 := HistSelected;
          Mark2 := HistSelected + 1;
        end

        { One mark: if cursor is elsewhere, use cursor as the second mark.
          If cursor is on the mark, compare that revision with its predecessor. }
        else if (Mark1 >= 0) and (Mark2 < 0) then
        begin
          if HistSelected <> Mark1 then
            Mark2 := HistSelected
          else
          begin
            if Mark1 >= Lines.Count - 1 then
            begin
              Status := 'marked revision has no predecessor';
              Continue;
            end;
            Mark2 := Mark1 + 1;
          end;
        end;

        if (Mark1 < 0) or (Mark2 < 0) or (Mark1 = Mark2) then
        begin
          Status := 'unable to choose revisions for visual diff';
          Continue;
        end;

        { git log is newest-first: older left, newer right. }
        if Mark1 < Mark2 then
        begin
          I := Mark1;
          Mark1 := Mark2;
          Mark2 := I;
        end;

        Hash1 := FullHistoryHash(State, HistoryHashFromLine(Lines[Mark1]));
        Hash2 := FullHistoryHash(State, HistoryHashFromLine(Lines[Mark2]));
        if (Hash1 = '') or (Hash2 = '') then
        begin
          Status := 'unable to resolve revisions';
          Continue;
        end;

        MaterializeTempFile(State, Hash1, RepoPath, File1);
        MaterializeTempFile(State, Hash2, RepoPath, File2);
        SideBySideDiff(File1, File2, Status);
      end;
    end;
  finally
    Lines.Free;
  end;
end;

procedure OpenSelectedFile(const State: TGTMState; Entries: TStringList;
  Selected: Integer; var Status: string);
var
  RepoPath, TempFile: string;
begin
  RepoPath := SelectedRepoPath(State, Entries, Selected);
  if RepoPath = '' then
    Exit;

  MaterializeTempFile(State, State.CommitHash, RepoPath, TempFile);
  OpenInEditor(TempFile, Status);
end;

procedure VisualDiffSelectedFile(const State: TGTMState; Entries: TStringList;
  Selected: Integer; var Status: string);
var
  RepoPath, PrevHash, OldFile, NewFile: string;
begin
  RepoPath := SelectedRepoPath(State, Entries, Selected);
  if RepoPath = '' then
    Exit;

  if State.CurrentBranchPosition <= 0 then
  begin
    Status := 'no predecessor commit';
    Exit;
  end;

  if Pos(' [added]', Entries[Selected]) > 0 then
  begin
    Status := 'file does not exist in predecessor';
    Exit;
  end;

  PrevHash := State.BranchIndex[State.CurrentBranchPosition - 1];
  MaterializeTempFile(State, PrevHash, RepoPath, OldFile);
  MaterializeTempFile(State, State.CommitHash, RepoPath, NewFile);
  SideBySideDiff(OldFile, NewFile, Status);
end;

procedure DrawTimeRail(const State: TGTMState;
  X, RailTop, RailBottom: Integer);
var
  Y, ThumbY, RailHeight: Integer;
begin
  if RailBottom < RailTop then
    Exit;

  for Y := RailTop to RailBottom do
    PutText(X, Y, '|', PairDim);

  if State.BranchCommitCount <= 0 then
    Exit;

  RailHeight := RailBottom - RailTop;
  if (State.BranchCommitCount <= 1) or (RailHeight <= 0) then
    ThumbY := RailTop
  else
    ThumbY := RailBottom - Round(
      (State.CurrentBranchPosition * RailHeight * 1.0) /
      (State.BranchCommitCount - 1)
    );

  if ThumbY < RailTop then
    ThumbY := RailTop;
  if ThumbY > RailBottom then
    ThumbY := RailBottom;

  PutText(X, ThumbY, '#', PairSelected);
end;

procedure DrawScreen(const State: TGTMState; Entries: TStringList;
  Selected, TopIndex: Integer; const Status: string);
var
  W, H, BoxTop, BoxBottom, VisibleRows: Integer;
  Row, I, PairNo, TimeRailX, TimeRailTop, TimeRailBottom: Integer;
  S, PathText, CommitText, DateText: string;
begin
  getmaxyx(stdscr, H, W);
  ClearScreen;

  if (W < 40) or (H < 10) then
  begin
    PutText(0, 0, 'GTM TUI: terminal too small', PairTitle);
    refresh;
    Exit;
  end;

  FillRow(0, PairTitle);
  PutText(1, 0, 'Git Time Machine', PairTitle);
  PutText(19, 0, 'repo: ' + State.Repo, PairTitle);

  CommitText := 'branch: ' + State.Branch +
    '  commit: ' + Copy(State.CommitHash, 1, 8) + '  ';

  if State.CurrentBranchPosition > 0 then
    CommitText := CommitText + '<'
  else
    CommitText := CommitText + ' ';

  CommitText := CommitText + '  ' +
    CommitSubject(State.Repo, State.CommitHash) + '  ';

  if (State.BranchCommitCount > 0) and
     (State.CurrentBranchPosition < State.BranchCommitCount - 1) then
    CommitText := CommitText + '>'
  else
    CommitText := CommitText + ' ';

  PutText(1, 1, CommitText, PairNormal);

  BoxTop := 2;
  BoxBottom := H - 3;
  DrawBox(0, BoxTop, W - 1, BoxBottom, PairNormal);

  if State.CurrentPath = '' then PathText := '/'
  else PathText := '/' + State.CurrentPath;
  PutText(2, BoxTop, ' ' + PathText + ' ', PairNormal);

  TimeRailX := W - 3;
  TimeRailTop := BoxTop + 1;
  TimeRailBottom := BoxBottom - 1;
  DrawTimeRail(State, TimeRailX, TimeRailTop, TimeRailBottom);

  VisibleRows := BoxBottom - BoxTop - 1;
  for Row := 0 to VisibleRows - 1 do
  begin
    I := TopIndex + Row;
    if I >= Entries.Count then Break;

    S := Entries[I];
    if I = Selected then PairNo := PairSelected
    else if IsDeletedEntry(S) then PairNo := PairDim
    else PairNo := PairNormal;

    PutText(2, BoxTop + 1 + Row, Copy(S, 1, W - 7), PairNo);
  end;

  FillRow(H - 2, PairNormal);
  DateText := CommitTime(State.Repo, State.CommitHash);
  if Length(DateText) < W - 2 then
    PutText(W - Length(DateText) - 1, H - 2, DateText, PairNormal);
  PutText(1, H - 2,
    Copy(Status, 1, W - Length(DateText) - 4), PairNormal);

  FillRow(H - 1, PairTitle);
  PutText(1, H - 1,
    'F1 Help  F2 Menu  F10 Quit',
    PairTitle);

  refresh;
end;

function ChooseInitialBranch(const Repo, Requested: string;
  Branches: TStringList): string;
begin
  ListBranches(Repo, Branches);
  if Branches.Count = 0 then
    Die('repository has no branches');

  if (Requested <> '') and (Branches.IndexOf(Requested) >= 0) then
    Exit(Requested);
  if Branches.IndexOf('master') >= 0 then Exit('master');
  if Branches.IndexOf('main') >= 0 then Exit('main');
  Result := Branches[0];
end;

procedure RunTUI(const RepoArg, BranchArg: string);
var
  State: TGTMState;
  Branches, Entries: TStringList;
  Selected, TopIndex, VisibleRows: Integer;
  K: LongInt;
  Status, Name, TargetCommit, KeyName, LastCtrlKey: string;
  Running: Boolean;
  RepeatCount, Step: Integer;
begin
  Branches := TStringList.Create;
  Entries := TStringList.Create;
  InitGTMState(State);
  try
    State.Repo := ExpandFileName(RepoArg);
    State.Branch := ChooseInitialBranch(State.Repo, BranchArg, Branches);

    if not SelectStateBranch(State, State.Branch, TargetCommit) then
      Die('unable to build branch path for ' + State.Branch);
    BuildStateTimeline(State, TargetCommit);
    if not SelectStateTimelineIndex(State, State.Timeline.IndexOf(TargetCommit)) then
      Die('unable to select initial commit');
    LoadEntries(State, Entries);

    Selected := 0;
    TopIndex := 0;
    Status := CommitSubject(State.Repo, State.CommitHash);

    c_setenv('ESCDELAY', '25', 1);
    initscr;
    cbreak;
    noecho;
    keypad(stdscr, True);
    curs_set(0);
    InitColors;

    Running := True;
    LastCtrlKey := '';
    RepeatCount := 0;
    while Running do
    begin
      VisibleRows := LINES - 6;
      if VisibleRows < 1 then VisibleRows := 1;
      ClampSelection(Entries, Selected, TopIndex, VisibleRows);
      DrawScreen(State, Entries, Selected, TopIndex, Status);

      K := getch;
      KeyName := RawNcursesKeyName(K);

      if (KeyName = 'kLFT5') or (KeyName = 'kRIT5') or
         (KeyName = 'kUP5') or (KeyName = 'kDN5') then
      begin
        if KeyName = LastCtrlKey then
          Inc(RepeatCount)
        else
        begin
          LastCtrlKey := KeyName;
          RepeatCount := 1;
        end;
        Step := AccelStep(RepeatCount);

        if KeyName = 'kLFT5' then
          SelectBranchPosition(State, State.CurrentBranchPosition - Step,
            Entries, Selected, TopIndex, Status)
        else if KeyName = 'kRIT5' then
          SelectBranchPosition(State, State.CurrentBranchPosition + Step,
            Entries, Selected, TopIndex, Status)
        else if KeyName = 'kUP5' then
          SelectBranchPosition(State, State.CurrentBranchPosition - Step,
            Entries, Selected, TopIndex, Status)
        else if KeyName = 'kDN5' then
          SelectBranchPosition(State, State.CurrentBranchPosition + Step,
            Entries, Selected, TopIndex, Status);
        Continue;
      end
      else
      begin
        LastCtrlKey := '';
        RepeatCount := 0;
      end;

      if KeyName = 'kHOM5' then
      begin
        SelectBranchPosition(State, 0, Entries, Selected, TopIndex, Status);
        Continue;
      end
      else if KeyName = 'kEND5' then
      begin
        SelectBranchPosition(State, State.BranchIndex.Count - 1,
          Entries, Selected, TopIndex, Status);
        Continue;
      end
      else if KeyName = 'kPRV5' then
      begin
        SelectBranchPosition(State, State.BranchIndex.Count - 1,
          Entries, Selected, TopIndex, Status);
        Continue;
      end
      else if KeyName = 'kNXT5' then
      begin
        SelectBranchPosition(State, 0, Entries, Selected, TopIndex, Status);
        Continue;
      end;

      if K = KEY_F(1) then
        ShowKeyHelp
      else if K = KEY_F(2) then
      begin
        if RunMenu then
          Running := False;
      end
      else if K = KEY_F(10) then
        Running := False
      else if K = KEY_UP then
      begin
        if Selected > 0 then
          Dec(Selected);
      end
      else if K = KEY_DOWN then
      begin
        if Selected < Entries.Count - 1 then
          Inc(Selected);
      end
      else if K = KEY_HOME then
      begin
        if Entries.Count > 0 then
        begin
          Selected := 0;
          TopIndex := 0;
        end;
      end
      else if K = KEY_END then
      begin
        if Entries.Count > 0 then
          Selected := Entries.Count - 1;
      end
      else if K = KEY_LEFT then
      begin
        if State.CurrentPath <> '' then
        begin
          State.CurrentPath := ParentPath(State.CurrentPath);
          LoadEntries(State, Entries);
          Selected := 0;
          TopIndex := 0;
          Status := '/' + State.CurrentPath;
        end;
      end
      else if (K = KEY_RIGHT) or (K = 10) or (K = 13) then
      begin
        if (Selected >= 0) and (Selected < Entries.Count) then
        begin
          if IsDeletedEntry(Entries[Selected]) then
            Status := 'deleted entry is not present in this snapshot'
          else if IsDirectoryEntry(Entries[Selected]) then
          begin
            Name := EntryName(Entries[Selected]);
            State.CurrentPath := JoinPath(State.CurrentPath, Name);
            LoadEntries(State, Entries);
            Selected := 0;
            TopIndex := 0;
            Status := '/' + State.CurrentPath;
          end;
        end;
      end
      else if (K = KEY_BACKSPACE) or (K = 127) or (K = 8) then
      begin
        if State.CurrentPath <> '' then
        begin
          State.CurrentPath := ParentPath(State.CurrentPath);
          LoadEntries(State, Entries);
          Selected := 0;
          TopIndex := 0;
          Status := '/' + State.CurrentPath;
        end;
      end
      else if (K = Ord('o')) or (K = Ord('O')) then
        OpenSelectedFile(State, Entries, Selected, Status)
      else if (K = Ord('h')) or (K = Ord('H')) then
      begin
        if SelectedRepoPath(State, Entries, Selected) <> '' then
          ShowHistoryPopup(State, Entries, Selected, TopIndex, Status,
            SelectedRepoPath(State, Entries, Selected));
      end
      else if (K = Ord('v')) or (K = Ord('V')) then
        VisualDiffSelectedFile(State, Entries, Selected, Status)
      else if (K = Ord('q')) or (K = Ord('Q')) then
        Running := False;
    end;
  finally
    endwin;
    DoneGTMState(State);
    Entries.Free;
    Branches.Free;
    Write(#27'[2J'#27'[H'#27'[?25h');
    Flush(Output);
  end;
end;

end.
