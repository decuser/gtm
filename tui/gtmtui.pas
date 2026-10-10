unit gtmtui;

{$mode objfpc}{$H+}

interface

procedure RunTUI(const RepoArg, BranchArg: string);

implementation

uses
  Classes, SysUtils, StrUtils, Process, ctypes, ncurses, gtmcore, gtmstate, gtmmount, gtmkeys;

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
    init_pair(PairDim, COLOR_WHITE, -1);
  end;
end;

procedure UsePair(PairNo: SmallInt);
begin
  if has_colors then
  begin
    if PairNo = PairDim then
      attrset(COLOR_PAIR(PairDim) or A_DIM)
    else
      attrset(COLOR_PAIR(PairNo));
  end
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

{$push}
{$notes off}
procedure PutText(X, Y: Integer; const S: string; PairNo: SmallInt);
begin
  if (X < 0) or (Y < 0) then
    Exit;
  UsePair(PairNo);
  mvaddnstr(Y, X, PChar(S), Length(S));
end;
{$pop}

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
    PutText(1, H - 1, 'Up/Down PgUp/PgDn  F10 Close', PairTitle);
    refresh;

    K := getch;
    if (K = KEY_F(10)) then
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

  BoxH := Length(Lines) + 5;
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

  PutText(X1 + 2, Y2 - 1, 'F10 Close', PairDim);
  refresh;
  getch;
end;

procedure DrawHelpDialog(const Title: string; Lines: array of string);
var
  W, H, BoxW, BoxH, X1, Y1, X2, Y2, I, MaxLen: Integer;
  K: LongInt;
begin
  getmaxyx(stdscr, H, W);
  MaxLen := Length(Title) + 4;
  for I := Low(Lines) to High(Lines) do
    if Length(Lines[I]) + 4 > MaxLen then
      MaxLen := Length(Lines[I]) + 4;

  BoxW := MaxLen;
  if BoxW < 36 then BoxW := 36;
  if BoxW > W - 4 then BoxW := W - 4;

  BoxH := Length(Lines) + 6;
  if BoxH > H - 2 then BoxH := H - 2;

  X1 := (W - BoxW) div 2;
  Y1 := (H - BoxH) div 2;
  X2 := X1 + BoxW - 1;
  Y2 := Y1 + BoxH - 1;

  while True do
  begin
    ClearScreen;
    DrawBox(X1, Y1, X2, Y2, PairTitle);
    PutText(X1 + 2, Y1, ' ' + Title + ' ', PairTitle);

    for I := Low(Lines) to High(Lines) do
    begin
      if Y1 + 2 + (I - Low(Lines)) >= Y2 - 1 then Break;
      PutText(X1 + 2, Y1 + 2 + (I - Low(Lines)),
        Copy(Lines[I], 1, BoxW - 4), PairNormal);
    end;

    PutText(X1 + 2, Y2 - 1, 'F10 Close', PairDim);
    refresh;

    K := getch;
    if K = KEY_F(10) then
      Exit;
  end;
end;

procedure ShowKeyHelp;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    BuildGTMMainKeyBindingLines(Lines);
    ShowTextViewer('Key Bindings', Lines);
  finally
    Lines.Free;
  end;
end;

procedure ShowMenuHelp;
begin
  DrawHelpDialog('Help - Menu', [
    'Up / Down       select menu item',
    'Enter           activate',
    'F10             close menu'
  ]);
end;

procedure ShowBranchHelp;
begin
  DrawHelpDialog('Help - Branch', [
    'Up / Down       select branch',
    'Home / End      first / last branch',
    'Enter           switch branch',
    'F10             cancel'
  ]);
end;

procedure ShowTagHelp;
begin
  DrawHelpDialog('Help - Tag', [
    'Up / Down       select tag',
    'Home / End      first / last tag',
    'Enter           jump to tag',
    'F10             cancel'
  ]);
end;

procedure ShowMountHelp;
begin
  DrawHelpDialog('Help - Mounted Snapshots', [
    'Up / Down       select mount',
    'o               shell in selected mount',
    'Space           mark / unmark mount',
    'm               mount current snapshot',
    'v               diff selected/marked mounts',
    'u               unmount current snapshot',
    'U               unmount all',
    'F10             close'
  ]);
end;

procedure ShowHistoryHelp;
begin
  DrawHelpDialog('Help - History', [
    'Up / Down       select revision',
    'j               jump to revision',
    'm               mark / unmark revision',
    'v               visual diff selected/marked revisions',
    'F10             close history'
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
      PutText(X1 + 2, Y1 + 2, 'Press a key. F10 exits.', PairNormal)
    else
    begin
      PutText(X1 + 2, Y1 + 2, 'VKEY:   ' + NcursesKeyName(K), PairSelected);
      PutText(X1 + 2, Y1 + 3, 'ncurses: ' + RawNcursesKeyName(K), PairNormal);
      PutText(X1 + 2, Y1 + 4, 'Code:    ' + IntToStr(K), PairNormal);
      PutText(X1 + 2, Y1 + 5, 'Hex:     $' + IntToHex(K, 4), PairNormal);
      PutText(X1 + 2, Y1 + 7, 'Press another key; F10 exits.', PairDim);
    end;
    refresh;
  end;

begin
  getmaxyx(stdscr, H, W);
  BoxW := 62;
  if BoxW > W - 4 then BoxW := W - 4;
  BoxH := 12;
  X1 := (W - BoxW) div 2;
  Y1 := (H - BoxH) div 2;
  X2 := X1 + BoxW - 1;
  Y2 := Y1 + BoxH - 1;

  HaveKey := False;
  Draw;

  while True do
  begin
    K := getch;
    if (K = KEY_F(10)) then
      Exit;
    HaveKey := True;
    Draw;
  end;
end;

procedure DrawMenuPopup(ItemIndex: Integer);
const
  Items: array[0..7] of string = (
    'Navigate - Branch',
    'Navigate - Tag',
    'Mount Current Snapshot',
    'Mounted Snapshots',
    'Control Test',
    'Key Bindings',
    'Help - About',
    'File - Quit'
  );
var
  W, H, BoxW, BoxH, X1, Y1, X2, Y2, I, PairNo: Integer;
begin
  getmaxyx(stdscr, H, W);
  BoxW := 44;
  BoxH := 16;
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

  PutText(X1 + 2, Y2 - 1, 'F1 Help   F10 Quit', PairDim);
  refresh;
end;

{ -1 cancel, 0 branch, 1 tag, 2 quit }
function RunMenu: Integer;
var
  ItemIndex: Integer;
  K: LongInt;
begin
  Result := -1;
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
      if ItemIndex < 7 then
        Inc(ItemIndex);
    end
    else if (K = KEY_F(10)) or (K = 27) then
      Exit(-1)
    else if (K = 10) or (K = 13) then
    begin
      case ItemIndex of
        0: Exit(0);
        1: Exit(1);
        2: Exit(2);
        3: Exit(3);
        4: ShowControlTest;
        5: ShowKeyHelp;
        6: ShowAbout;
        7: Exit(4);
      end;
    end;
  end;
end;

function ChooseFromList(const TitleText: string; Items: TStrings;
  InitialIndex: Integer; IsTagChooser: Boolean): Integer;
var
  W, H, X1, Y1, X2, Y2, BoxW, BoxH: Integer;
  SelectedIndex, TopIndex, VisibleRows, Row, I, PairNo: Integer;
  K: LongInt;
  Line: string;
begin
  Result := -1;
  if (Items = nil) or (Items.Count = 0) then
    Exit;

  SelectedIndex := InitialIndex;
  if SelectedIndex < 0 then SelectedIndex := 0;
  if SelectedIndex >= Items.Count then SelectedIndex := Items.Count - 1;
  TopIndex := 0;

  while True do
  begin
    getmaxyx(stdscr, H, W);
    BoxW := W - 8;
    if BoxW > 70 then BoxW := 70;
    if BoxW < 24 then BoxW := W - 2;
    BoxH := H - 6;
    if BoxH > 22 then BoxH := 22;
    if BoxH < 6 then BoxH := H - 2;

    X1 := (W - BoxW) div 2;
    Y1 := (H - BoxH) div 2;
    X2 := X1 + BoxW - 1;
    Y2 := Y1 + BoxH - 1;
    VisibleRows := BoxH - 3;
    if VisibleRows < 1 then VisibleRows := 1;

    if SelectedIndex < TopIndex then TopIndex := SelectedIndex;
    if SelectedIndex >= TopIndex + VisibleRows then
      TopIndex := SelectedIndex - VisibleRows + 1;
    if TopIndex < 0 then TopIndex := 0;

    ClearScreen;
    DrawBox(X1, Y1, X2, Y2, PairTitle);
    PutText(X1 + 2, Y1, ' ' + TitleText + ' ', PairTitle);

    for Row := 0 to VisibleRows - 1 do
    begin
      I := TopIndex + Row;
      if I >= Items.Count then Break;
      if I = SelectedIndex then PairNo := PairSelected else PairNo := PairNormal;
      Line := Items[I] + StringOfChar(' ', BoxW);
      PutText(X1 + 2, Y1 + 2 + Row, Copy(Line, 1, BoxW - 4), PairNo);
    end;

    PutText(X1 + 2, Y2 - 1, 'Enter Select   F1 Help   F10 Cancel', PairDim);
    refresh;

    K := getch;
    if K = KEY_F(1) then
    begin
      if IsTagChooser then ShowTagHelp else ShowBranchHelp;
    end
    else if K = KEY_UP then
    begin
      if SelectedIndex > 0 then Dec(SelectedIndex);
    end
    else if K = KEY_DOWN then
    begin
      if SelectedIndex < Items.Count - 1 then Inc(SelectedIndex);
    end
    else if K = KEY_HOME then
      SelectedIndex := 0
    else if K = KEY_END then
      SelectedIndex := Items.Count - 1
    else if (K = KEY_F(10)) or (K = 27) then
      Exit(-1)
    else if (K = 10) or (K = 13) then
      Exit(SelectedIndex);
  end;
end;

procedure SwitchBranchTUI(var State: TGTMState; Branches, Entries: TStringList;
  BranchIndex: Integer; var Selected, TopIndex: Integer; var Status: string);
var
  TargetCommit: string;
begin
  if (BranchIndex < 0) or (BranchIndex >= Branches.Count) then
    Exit;

  if not SelectStateBranch(State, Branches[BranchIndex], TargetCommit) then
  begin
    Status := 'unable to switch branch';
    Exit;
  end;

  BuildStateTimeline(State, TargetCommit);
  if not SelectStateTimelineIndex(State, State.Timeline.IndexOf(TargetCommit)) then
  begin
    Status := 'unable to select branch tip';
    Exit;
  end;

  EnsureStateCurrentPath(State);
  LoadEntries(State, Entries);
  Selected := 0;
  TopIndex := 0;
  Status := 'branch: ' + State.Branch;
end;

procedure JumpToTagTUI(var State: TGTMState; Branches, Entries: TStringList;
  TagIndex: Integer; var Selected, TopIndex: Integer; var Status: string);
var
  TargetCommit: string;
  BranchListIndex, TimelineIndex: Integer;
begin
  if (TagIndex <= 0) or (TagIndex >= State.TagCommits.Count) then
    Exit;

  TargetCommit := State.TagCommits[TagIndex];
  if not SelectStateBranchForCommit(State, Branches, TargetCommit, BranchListIndex) then
  begin
    Status := 'tag is not on a browsable branch';
    Exit;
  end;

  BuildStateTimeline(State, TargetCommit);
  TimelineIndex := State.Timeline.IndexOf(TargetCommit);
  if TimelineIndex < 0 then
  begin
    Status := 'unable to locate tagged commit';
    Exit;
  end;

  if not SelectStateTimelineIndex(State, TimelineIndex) then
    Exit;

  State.SelectedCommitTime := CommitUnixTime(State.Repo, State.CommitHash);
  EnsureStateCurrentPath(State);
  LoadEntries(State, Entries);
  Selected := 0;
  TopIndex := 0;
  Status := 'tag: ' + State.TagNames[TagIndex];
end;

function ShowHistoryPopup(var State: TGTMState; Entries: TStringList;
  var Selected, TopIndex: Integer; var Status: string;
  const RepoPath: string): Boolean;
var
  Lines: TStringList;
  Marks: array of Boolean;
  HistSelected, HistTop, VisibleRows: Integer;
  Mark1, Mark2, I, W, H, BoxTop, BoxBottom: Integer;
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
      else if False then
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

function PromptPath(const TitleText, DefaultValue: string;
  out Value: string): Boolean;
var
  W, H, X1, Y1, X2, Y2, BoxW, K: Integer;
  CursorPos, FieldWidth, ViewStart, CursorX: Integer;
  Buffer, VisibleText: string;
begin
  Result := False;
  Buffer := DefaultValue;
  CursorPos := Length(Buffer) + 1;

  while True do
  begin
    getmaxyx(stdscr, H, W);
    BoxW := W - 8;
    if BoxW > 78 then BoxW := 78;
    if BoxW < 24 then BoxW := W - 2;

    X1 := (W - BoxW) div 2;
    Y1 := (H - 7) div 2;
    X2 := X1 + BoxW - 1;
    Y2 := Y1 + 6;
    FieldWidth := BoxW - 4;

    if CursorPos < 1 then CursorPos := 1;
    if CursorPos > Length(Buffer) + 1 then CursorPos := Length(Buffer) + 1;

    ViewStart := 1;
    if CursorPos > FieldWidth then
      ViewStart := CursorPos - FieldWidth + 1;
    if ViewStart < 1 then ViewStart := 1;

    VisibleText := Copy(Buffer, ViewStart, FieldWidth);
    VisibleText := VisibleText + StringOfChar(' ', FieldWidth - Length(VisibleText));
    CursorX := X1 + 2 + (CursorPos - ViewStart);

    ClearScreen;
    DrawBox(X1, Y1, X2, Y2, PairTitle);
    PutText(X1 + 2, Y1, ' ' + TitleText + ' ', PairTitle);
    PutText(X1 + 2, Y1 + 2, 'Path:', PairNormal);
    PutText(X1 + 2, Y1 + 3, VisibleText, PairSelected);
    PutText(X1 + 2, Y2 - 1,
      'Left/Right Edit   Enter Save   F10 Cancel', PairDim);

    move(Y1 + 3, CursorX);
    curs_set(1);
    refresh;

    K := getch;
    if K = KEY_F(10) then
    begin
      curs_set(0);
      Exit(False);
    end
    else if (K = 10) or (K = 13) then
    begin
      curs_set(0);
      Value := Trim(Buffer);
      Result := Value <> '';
      Exit;
    end
    else if K = KEY_LEFT then
    begin
      if CursorPos > 1 then Dec(CursorPos);
    end
    else if K = KEY_RIGHT then
    begin
      if CursorPos <= Length(Buffer) then Inc(CursorPos);
    end
    else if K = KEY_HOME then
      CursorPos := 1
    else if K = KEY_END then
      CursorPos := Length(Buffer) + 1
    else if (K = KEY_BACKSPACE) or (K = 127) or (K = 8) then
    begin
      if CursorPos > 1 then
      begin
        Delete(Buffer, CursorPos - 1, 1);
        Dec(CursorPos);
      end;
    end
    else if K = KEY_DC then
    begin
      if CursorPos <= Length(Buffer) then
        Delete(Buffer, CursorPos, 1);
    end
    else if (K >= 32) and (K <= 126) then
    begin
      Insert(Chr(K), Buffer, CursorPos);
      Inc(CursorPos);
    end;
  end;
end;

function ExpandUserPath(const PathName: string): string;
var
  HomeDir: string;
begin
  Result := PathName;
  if PathName = '' then
    Exit;

  if PathName[1] <> '~' then
    Exit;

  HomeDir := GetEnvironmentVariable('HOME');
  if HomeDir = '' then
    Exit;

  if PathName = '~' then
    Result := HomeDir
  else if (Length(PathName) >= 2) and
          ((PathName[2] = '/') or (PathName[2] = DirectorySeparator)) then
    Result := IncludeTrailingPathDelimiter(HomeDir) + Copy(PathName, 3, MaxInt);
end;

procedure ShowErrorDialog(const MessageText: string);
begin
  DrawDialog('Error', [
    MessageText,
    '',
    'Press any key'
  ]);
end;

function ConfirmOverwrite(const FileName: string): Boolean;
var
  W, H, X1, Y1, X2, Y2, BoxW, K: Integer;
begin
  Result := False;

  while True do
  begin
    getmaxyx(stdscr, H, W);
    BoxW := W - 8;
    if BoxW > 72 then BoxW := 72;
    if BoxW < 28 then BoxW := W - 2;

    X1 := (W - BoxW) div 2;
    Y1 := (H - 7) div 2;
    X2 := X1 + BoxW - 1;
    Y2 := Y1 + 6;

    ClearScreen;
    DrawBox(X1, Y1, X2, Y2, PairTitle);
    PutText(X1 + 2, Y1, ' Confirm Overwrite ', PairTitle);
    PutText(X1 + 2, Y1 + 2,
      Copy(FileName + ' already exists.', 1, BoxW - 4), PairNormal);
    PutText(X1 + 2, Y1 + 4, 'y Overwrite   n/F10 Cancel', PairDim);
    refresh;

    K := getch;
    if (K = Ord('y')) or (K = Ord('Y')) then
      Exit(True)
    else if (K = Ord('n')) or (K = Ord('N')) or (K = KEY_F(10)) then
      Exit(False);
  end;
end;

procedure SaveSelectedFile(const State: TGTMState; Entries: TStringList;
  Selected: Integer; var Status: string);
var
  RepoPath, DestFile, PromptValue, DefaultName: string;
begin
  RepoPath := SelectedRepoPath(State, Entries, Selected);
  if RepoPath = '' then
    Exit;

  DefaultName := ExtractFileName(RepoPath);
  PromptValue := DefaultName;

  while True do
  begin
    if not PromptPath('Save Historical File', PromptValue, DestFile) then
      Exit;

    PromptValue := DestFile;
    DestFile := ExpandUserPath(DestFile);

    if FileExists(DestFile) and (not ConfirmOverwrite(DestFile)) then
    begin
      Status := 'save cancelled';
      Exit;
    end;

    try
      ExtractFile(State.Repo, State.CommitHash, RepoPath, DestFile);
      Status := 'saved ' + DestFile;
      Exit;
    except
      on E: Exception do
      begin
        Status := 'save failed: ' + E.Message;
        ShowErrorDialog(Status);
      end;
    end;
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

procedure RunShellAt(const DirectoryName: string; var Status: string);
var
  ShellName: string;
  P: TProcess;
begin
  ShellName := GetEnvironmentVariable('SHELL');
  if Trim(ShellName) = '' then
    ShellName := '/bin/sh';

  SuspendCurses;
  P := TProcess.Create(nil);
  try
    P.Executable := ShellName;
    P.CurrentDirectory := DirectoryName;
    P.Options := [];
    try
      P.Execute;
      P.WaitOnExit;
      Status := 'returned from ' + DirectoryName;
    except
      on E: Exception do
        Status := 'unable to start shell: ' + E.Message;
    end;
  finally
    P.Free;
    ResumeCurses;
  end;
end;

procedure RecursiveDiff(const LeftDir, RightDir: string; var Status: string);
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
    P.Parameters.Add('-ru');
    P.Parameters.Add(LeftDir);
    P.Parameters.Add(RightDir);
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

    ShowTextViewer('Mounted Snapshot Diff', Lines);
    Status := 'diff complete';
  finally
    Lines.Free;
    SSErr.Free;
    SSOut.Free;
    P.Free;
  end;
end;

procedure MountCurrentSnapshotTUI(Mounts: TGTMMountManager;
  const State: TGTMState; var Status: string);
var
  MountPoint, ErrorMessage: string;
begin
  if Mounts.IsMounted(State.Repo, State.CommitHash) then
  begin
    Status := 'snapshot already mounted';
    Exit;
  end;

  if not Mounts.MountSnapshot(State.Repo, State.CommitHash,
    MountPoint, ErrorMessage) then
  begin
    Status := ErrorMessage;
    ShowErrorDialog(ErrorMessage);
    Exit;
  end;

  Status := 'mounted ' + MountPoint;
end;

procedure UnmountCurrentSnapshotTUI(Mounts: TGTMMountManager;
  const State: TGTMState; var Status: string);
var
  ErrorMessage: string;
begin
  if not Mounts.IsMounted(State.Repo, State.CommitHash) then
  begin
    Status := 'current snapshot is not mounted';
    Exit;
  end;

  if not Mounts.UnmountSnapshot(State.Repo, State.CommitHash, ErrorMessage) then
  begin
    Status := ErrorMessage;
    ShowErrorDialog(ErrorMessage);
    Exit;
  end;

  Status := 'current snapshot unmounted';
end;

procedure ShowMountedSnapshots(Mounts: TGTMMountManager; const State: TGTMState; var Status: string);
var
  Selected, TopIndex, VisibleRows, Row, I, W, H, PairNo: Integer;
  K: LongInt;
  Marks: array of Boolean;
  Mark1, Mark2: Integer;
  Line, ErrorMessage: string;

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

  procedure ClampMountSelection;
  begin
    if Mounts.Count = 0 then
    begin
      Selected := -1;
      TopIndex := 0;
      Exit;
    end;

    if Selected < 0 then Selected := 0;
    if Selected >= Mounts.Count then Selected := Mounts.Count - 1;
    if TopIndex < 0 then TopIndex := 0;
    if Selected < TopIndex then TopIndex := Selected;
    if Selected >= TopIndex + VisibleRows then
      TopIndex := Selected - VisibleRows + 1;
  end;

begin
  Selected := 0;
  TopIndex := 0;
  SetLength(Marks, Mounts.Count);

  while True do
  begin
    getmaxyx(stdscr, H, W);
    VisibleRows := H - 3;
    if VisibleRows < 1 then VisibleRows := 1;
    ClampMountSelection;

    ClearScreen;
    FillRow(0, PairTitle);
    PutText(1, 0, 'Mounted Snapshots', PairTitle);

    if Mounts.Count = 0 then
      PutText(2, 2, '(none)', PairDim)
    else
      for Row := 0 to VisibleRows - 1 do
      begin
        I := TopIndex + Row;
        if I >= Mounts.Count then Break;
        if I = Selected then PairNo := PairSelected else PairNo := PairNormal;
        if (I <= High(Marks)) and Marks[I] then
          Line := '* '
        else
          Line := '  ';
        Line := Line + Copy(Mounts.Commits[I], 1, 8) + '  ' + Mounts.MountPoints[I];
        PutText(1, Row + 1, Copy(Line, 1, W - 2), PairNo);
      end;

    FillRow(H - 1, PairTitle);
    PutText(1, H - 1,
      'o Shell  Space Mark  m Mount  v Diff  u Current  U All  F1 Help  F10 Close',
      PairTitle);
    refresh;

    K := getch;
    if K = KEY_F(1) then
      ShowMountHelp
    else if (K = KEY_F(10)) then
      Exit
    else if K = KEY_UP then
    begin
      if Selected > 0 then Dec(Selected);
    end
    else if K = KEY_DOWN then
    begin
      if Selected < Mounts.Count - 1 then Inc(Selected);
    end
    else if K = KEY_HOME then
      Selected := 0
    else if K = KEY_END then
      Selected := Mounts.Count - 1
    else if (K = Ord('o')) or (K = Ord('O')) then
    begin
      if (Selected >= 0) and (Selected < Mounts.Count) then
        RunShellAt(Mounts.MountPoints[Selected], Status);
    end
    else if K = Ord(' ') then
    begin
      if (Selected >= 0) and (Selected < Mounts.Count) then
      begin
        if Length(Marks) <> Mounts.Count then
          SetLength(Marks, Mounts.Count);
        Marks[Selected] := not Marks[Selected];
        RecountMarks;
        if (Mark1 >= 0) and (Mark2 >= 0) then
        begin
          for I := 0 to High(Marks) do
            if (I <> Mark1) and (I <> Mark2) then
              Marks[I] := False;
        end;
      end;
    end
    else if (K = Ord('m')) or (K = Ord('M')) then
    begin
      MountCurrentSnapshotTUI(Mounts, State, Status);
      SetLength(Marks, Mounts.Count);
      if Selected < 0 then Selected := 0;
    end
    else if (K = Ord('v')) or (K = Ord('V')) then
    begin
      RecountMarks;
      if (Mark1 >= 0) and (Mark2 >= 0) then
      begin
        RecursiveDiff(Mounts.MountPoints[Mark1],
          Mounts.MountPoints[Mark2], Status);
      end
      else if (Mark1 >= 0) and (Selected >= 0) and (Selected <> Mark1) then
      begin
        RecursiveDiff(Mounts.MountPoints[Mark1],
          Mounts.MountPoints[Selected], Status);
      end
      else
        Status := 'mark one mount and select another, or mark two';
    end
    else if K = Ord('u') then
    begin
      UnmountCurrentSnapshotTUI(Mounts, State, Status);
      SetLength(Marks, Mounts.Count);
      if Selected >= Mounts.Count then Selected := Mounts.Count - 1;
    end
    else if K = Ord('U') then
    begin
      Mounts.UnmountAll;
      SetLength(Marks, 0);
      Selected := -1;
      TopIndex := 0;
      Status := 'all snapshots unmounted';
    end;
  end;
end;

function TUIAbstractKey(K: LongInt; const KeyName: string): TGTMKey;
begin
  if (KeyName = 'kLFT5') then Exit(gkLeft);
  if (KeyName = 'kRIT5') then Exit(gkRight);
  if (KeyName = 'kUP5') then Exit(gkUp);
  if (KeyName = 'kDN5') then Exit(gkDown);
  if (KeyName = 'kHOM5') then Exit(gkHome);
  if (KeyName = 'kEND5') then Exit(gkEnd);
  if (KeyName = 'kPRV5') then Exit(gkPageUp);
  if (KeyName = 'kNXT5') then Exit(gkPageDown);

  if K = KEY_LEFT then Result := gkLeft
  else if K = KEY_RIGHT then Result := gkRight
  else if K = KEY_UP then Result := gkUp
  else if K = KEY_DOWN then Result := gkDown
  else if K = KEY_HOME then Result := gkHome
  else if K = KEY_END then Result := gkEnd
  else if K = KEY_PPAGE then Result := gkPageUp
  else if K = KEY_NPAGE then Result := gkPageDown
  else if (K = KEY_BACKSPACE) or (K = 127) or (K = 8) then Result := gkBackspace
  else if (K = 10) or (K = 13) then Result := gkEnter
  else if K = KEY_F(1) then Result := gkF1
  else if K = KEY_F(2) then Result := gkF2
  else if K = KEY_F(10) then Result := gkF10
  else Result := gkNone;
end;

function TUIModifiers(const KeyName: string): TGTMKeyModifiers;
begin
  Result := [];
  if (KeyName = 'kLFT5') or (KeyName = 'kRIT5') or
     (KeyName = 'kUP5') or (KeyName = 'kDN5') or
     (KeyName = 'kHOM5') or (KeyName = 'kEND5') or
     (KeyName = 'kPRV5') or (KeyName = 'kNXT5') then
    Include(Result, gkmCtrl);
end;

function TUIChar(K: LongInt): Char;
begin
  if (K >= 32) and (K <= 126) then
    Result := Chr(K)
  else
    Result := #0;
end;

procedure RunTUI(const RepoArg, BranchArg: string);
var
  State: TGTMState;
  Branches, Entries: TStringList;
  Mounts: TGTMMountManager;
  Selected, TopIndex, VisibleRows: Integer;
  K: LongInt;
  Status, Name, TargetCommit, KeyName, LastCtrlKey: string;
  Running: Boolean;
  RepeatCount, Step, MenuResult, ChoiceIndex, CurrentIndex: Integer;
  Action: TGTMKeyAction;
begin
  Branches := TStringList.Create;
  Entries := TStringList.Create;
  Mounts := TGTMMountManager.Create;
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
    PopulateStateTags(State, Branches);

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
      Action := GTMMainKeyAction(TUIAbstractKey(K, KeyName), TUIChar(K),
        TUIModifiers(KeyName));

      if Action in [gaCommitBackward, gaCommitForward,
                    gaTimeBackward, gaTimeForward] then
      begin
        if KeyName = LastCtrlKey then
          Inc(RepeatCount)
        else
        begin
          LastCtrlKey := KeyName;
          RepeatCount := 1;
        end;
        Step := AccelStep(RepeatCount);

        if Action in [gaCommitBackward, gaTimeBackward] then
          SelectBranchPosition(State, State.CurrentBranchPosition - Step,
            Entries, Selected, TopIndex, Status)
        else
          SelectBranchPosition(State, State.CurrentBranchPosition + Step,
            Entries, Selected, TopIndex, Status);
        Continue;
      end
      else
      begin
        LastCtrlKey := '';
        RepeatCount := 0;
      end;

      case Action of
        gaFirstCommit, gaEarliestTime:
          begin
            SelectBranchPosition(State, 0, Entries, Selected, TopIndex, Status);
            Continue;
          end;

        gaLastCommit, gaLatestTime:
          begin
            SelectBranchPosition(State, State.BranchIndex.Count - 1,
              Entries, Selected, TopIndex, Status);
            Continue;
          end;

        gaHelp:
          ShowKeyHelp;

        gaMenu:
          begin
            MenuResult := RunMenu;
            if MenuResult = 4 then
              Running := False
            else if MenuResult = 0 then
            begin
              CurrentIndex := Branches.IndexOf(State.Branch);
              ChoiceIndex := ChooseFromList('Select Branch', Branches,
                CurrentIndex, False);
              if ChoiceIndex >= 0 then
              begin
                SwitchBranchTUI(State, Branches, Entries, ChoiceIndex,
                  Selected, TopIndex, Status);
                PopulateStateTags(State, Branches);
              end;
            end
            else if MenuResult = 1 then
            begin
              PopulateStateTags(State, Branches);
              CurrentIndex := StateTagIndexForCommit(State, State.CommitHash);
              ChoiceIndex := ChooseFromList('Select Tag', State.TagNames,
                CurrentIndex, True);
              if ChoiceIndex > 0 then
                JumpToTagTUI(State, Branches, Entries, ChoiceIndex,
                  Selected, TopIndex, Status);
            end
            else if MenuResult = 2 then
              MountCurrentSnapshotTUI(Mounts, State, Status)
            else if MenuResult = 3 then
              ShowMountedSnapshots(Mounts, State, Status);
          end;

        gaQuit:
          Running := False;

        gaPreviousEntry:
          if Selected > 0 then Dec(Selected);

        gaNextEntry:
          if Selected < Entries.Count - 1 then Inc(Selected);

        gaFirstEntry:
          begin
            if Entries.Count > 0 then
            begin
              Selected := 0;
              TopIndex := 0;
            end;
          end;

        gaLastEntry:
          if Entries.Count > 0 then
            Selected := Entries.Count - 1;

        gaParentDirectory:
          begin
            if State.CurrentPath <> '' then
            begin
              State.CurrentPath := ParentPath(State.CurrentPath);
              LoadEntries(State, Entries);
              Selected := 0;
              TopIndex := 0;
              Status := '/' + State.CurrentPath;
            end;
          end;

        gaEnterDirectory:
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
          end;

        gaMountCurrent:
          MountCurrentSnapshotTUI(Mounts, State, Status);

        gaShowMounts:
          ShowMountedSnapshots(Mounts, State, Status);

        gaUnmountCurrent:
          UnmountCurrentSnapshotTUI(Mounts, State, Status);

        gaUnmountAll:
          begin
            Mounts.UnmountAll;
            Status := 'all snapshots unmounted';
          end;

        gaOpenFile:
          OpenSelectedFile(State, Entries, Selected, Status);

        gaSaveFile:
          SaveSelectedFile(State, Entries, Selected, Status);

        gaFileHistory:
          begin
            if SelectedRepoPath(State, Entries, Selected) <> '' then
              ShowHistoryPopup(State, Entries, Selected, TopIndex, Status,
                SelectedRepoPath(State, Entries, Selected));
          end;

        gaVisualDiff:
          VisualDiffSelectedFile(State, Entries, Selected, Status);
      end;
    end;
  finally
    endwin;
    Mounts.UnmountAll;
    Mounts.Free;
    DoneGTMState(State);
    Entries.Free;
    Branches.Free;
    Write(#27'[2J'#27'[H'#27'[?25h');
    Flush(Output);
  end;
end;

end.
