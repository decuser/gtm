unit gtmtui;

{$mode objfpc}{$H+}

interface

procedure RunTUI(const RepoArg, BranchArg: string);

implementation

uses
  Classes, SysUtils, StrUtils, ctypes, ncurses, gtmcore, gtmstate;

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
    'Ctrl-Left/Right commit slider',
    'Ctrl-Up/Down    time slider',
    'Ctrl-Home/End   first / last commit',
    'Ctrl-PgUp/PgDn  latest / earliest time',
    'F1              this help',
    'F2              menu',
    'F10 / q         close / quit'
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

    if K = KEY_UP then
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
          end
          else
            Status := 'file: ' + EntryName(Entries[Selected]);
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
