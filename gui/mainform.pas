unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, Forms, Controls, StdCtrls, Dialogs, ComCtrls, LCLIntf,
  Graphics, Menus, Process, ExtCtrls, gtmcore;

type
  TMainForm = class(TForm)
    BranchEdit: TComboBox;
    BranchLabel: TLabel;
    CommitInfoLabel: TLabel;
    CompareLabel: TLabel;
    ScaleLabel: TLabel;
    ForkLabel: TLabel;
    FilePopup: TPopupMenu;
    OpenMenuItem: TMenuItem;
    SaveAsMenuItem: TMenuItem;
    VisualDiffMenuItem: TMenuItem;
    HistoryMenuItem: TMenuItem;
    SaveDialog: TSaveDialog;
    BrowseButton: TButton;
    NextButton: TButton;
    PathLabel: TLabel;
    FirstButton: TButton;
    PrevButton: TButton;
    LastButton: TButton;
    RepoEdit: TEdit;
    RepoLabel: TLabel;
    SnapshotLabel: TLabel;
    TimeEdit: TEdit;
    TimeLabel: TLabel;
    TimeTrackBar: TTrackBar;
    VerticalTimeTrackBar: TTrackBar;
    TimeNowLabel: TLabel;
    TimeStartLabel: TLabel;
    TimeCurrentLabel: TLabel;
    TreeList: TListBox;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    procedure BrowseButtonClick(Sender: TObject);
    procedure BranchEditChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FirstButtonClick(Sender: TObject);
    procedure NextButtonClick(Sender: TObject);
    procedure LastButtonClick(Sender: TObject);
    procedure PrevButtonClick(Sender: TObject);
    procedure NavButtonMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure NavButtonMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure NavTimerTimer(Sender: TObject);
    procedure TimePreviewTimerTimer(Sender: TObject);
    procedure TimeTrackBarChange(Sender: TObject);
    procedure TimeTrackBarMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TimeTrackBarMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TimeTrackBarKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure VerticalTimeTrackBarChange(Sender: TObject);
    procedure VerticalTimeTrackBarMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure VerticalTimeTrackBarMouseUp(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure VerticalTimeTrackBarKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TreeListDblClick(Sender: TObject);
    procedure TreeListDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure FilePopupPopup(Sender: TObject);
    procedure OpenMenuItemClick(Sender: TObject);
    procedure SaveAsMenuItemClick(Sender: TObject);
    procedure VisualDiffMenuItemClick(Sender: TObject);
    procedure HistoryMenuItemClick(Sender: TObject);
    procedure HistoryListDblClick(Sender: TObject);
    procedure HistoryListSelectionChange(Sender: TObject; User: Boolean);
    procedure HistoryPopupPopup(Sender: TObject);
    procedure HistoryJumpMenuItemClick(Sender: TObject);
    procedure HistoryVisualDiffMenuItemClick(Sender: TObject);
  private
    FCommitHash: string;
    FCurrentPath: string;
    FTimeline: TStringList;
    FBranchIndex: TStringList;
    FEntryStates: TStringList;
    FDeletedEntries: TStringList;
    FPreviousCommitHash: string;
    FLoadingTimeline: Boolean;
    FLoadingBranches: Boolean;
    FForkIndex: Integer;
    FForkHash: string;
    FWindowSize: Integer;
    FWindowPredecessor: string;
    FHasNewer: Boolean;
    FBranchCommitCount: Integer;
    FReachableCommitCount: Integer;
    FAfterForkCount: Integer;
    FCurrentBranchPosition: Integer;
    FNavTimer: TTimer;
    FNavDirection: Integer;
    FNavHoldTicks: Integer;
    FNavRepeated: Boolean;
    FDraggingTimeline: Boolean;
    FPendingTimelinePosition: Integer;
    FDraggingTime: Boolean;
    FPendingTimePosition: Integer;
    FOldestUnixTime: Int64;
    FNewestUnixTime: Int64;
    FTimePreviewTimer: TTimer;
    FSelectedUnixTime: Int64;
    FHistoryList: TListBox;
    FHistoryPath: string;
    FHistorySelectionUpdating: Boolean;
    procedure LoadSnapshot;
    procedure LoadCurrentDirectory;
    procedure RefreshCurrentDirectory;
    procedure EnterDirectory(const EntryName: string);
    procedure GoParent;
    procedure OpenHistoricalFile(const EntryName: string);
    procedure BuildBranchIndex;
    procedure BuildBranchTimeline(const CenterCommit: string);
    procedure PopulateBranches;
    procedure SwitchBranch;
    procedure EnsureCurrentPathExists;
    procedure SelectTimelineIndex(Index: Integer);
    procedure UpdateTimelineControls;
    procedure StepNavigation(Delta: Integer);
    procedure UpdateTimelineLabels;
    procedure UpdateForkInfo;
    function ResolveSliderCommit(SliderPos: Integer): string;
    function UnixTimeToSlider(UnixTime: Int64): Integer;
    function SliderToUnixTime(SliderPos: Integer): Int64;
    procedure SelectTimePosition(SliderPos: Integer);
    procedure UpdateVerticalTimeSlider;
    procedure UpdateTimeRailLabels;
    procedure UpdateTimeCurrentLabel;
    procedure SelectCommitHash(const CommitHash: string);
    function PredecessorCommit(const CommitHash: string): string;
    procedure BuildEntryStates(const FromCommit, ToCommit: string);
    function EntryNameFromObject(const S: string): string;
    function EntryHashFromObject(const S: string): string;
    function FindObjectByName(Objects: TStrings; const EntryName: string): string;
    function StripStatusDecoration(const S: string): string;
    function DisplayStatus(const S: string): string;
    function IsDeletedDisplay(const S: string): Boolean;
    function IsDirectoryEntry(const S: string): Boolean;
    function SelectedDisplayEntry: string;
    function SelectedHistoricalPath: string;
    function TempPathForCommit(const CommitHash, RepoPath: string): string;
    procedure MaterializeTempFile(const CommitHash, RepoPath: string;
      out TempFile: string);
    function JoinRepoPath(const BasePath, EntryName: string): string;
  public
  end;

var
  MainWindow: TMainForm;

implementation

{$R *.lfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FTimeline := TStringList.Create;
  FBranchIndex := TStringList.Create;
  FEntryStates := TStringList.Create;
  FDeletedEntries := TStringList.Create;
  FPreviousCommitHash := '';
  FLoadingTimeline := False;
  FLoadingBranches := False;
  FForkIndex := -1;
  FForkHash := '';
  FWindowSize := 100;
  FWindowPredecessor := '';
  FHasNewer := False;
  FBranchCommitCount := 0;
  FReachableCommitCount := 0;
  FAfterForkCount := 0;
  FNavDirection := 0;
  FNavHoldTicks := 0;
  FNavRepeated := False;
  FDraggingTimeline := False;
  FPendingTimelinePosition := 0;
  FDraggingTime := False;
  FPendingTimePosition := 0;
  FOldestUnixTime := 0;
  FNewestUnixTime := 0;
  FSelectedUnixTime := 0;
  FHistoryList := nil;
  FHistoryPath := '';
  FHistorySelectionUpdating := False;
  FNavTimer := TTimer.Create(Self);
  FNavTimer.Enabled := False;
  FNavTimer.Interval := 250;
  FNavTimer.OnTimer := @NavTimerTimer;
  FTimePreviewTimer := TTimer.Create(Self);
  FTimePreviewTimer.Enabled := False;
  FTimePreviewTimer.Interval := 350;
  FTimePreviewTimer.OnTimer := @TimePreviewTimerTimer;
  BranchEdit.Items.Clear;
  ForkLabel.Caption := '';
  ScaleLabel.Caption := '';
  TimeNowLabel.Caption := 'Now';
  TimeStartLabel.Caption := '';
  TimeCurrentLabel.Caption := '';
  TimeEdit.Text := CurrentLocalTimeForGit;
  SnapshotLabel.Caption := 'Snapshot: not loaded';
  CommitInfoLabel.Caption := 'Commit: not loaded';
  CompareLabel.Caption := 'Compare: —';
  PathLabel.Caption := 'Path: /';
  FCommitHash := '';
  FCurrentPath := '';
  PrevButton.Enabled := False;
  NextButton.Enabled := False;
  TimeTrackBar.Enabled := False;
  VerticalTimeTrackBar.Enabled := False;
  if ParamCount >= 1 then
  begin
    RepoEdit.Text := ExpandFileName(ParamStr(1));
    TimeEdit.Text := CurrentLocalTimeForGit;
    PopulateBranches;
    LoadSnapshot;
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FDeletedEntries.Free;
  FEntryStates.Free;
  FBranchIndex.Free;
  FTimeline.Free;
end;

procedure TMainForm.BrowseButtonClick(Sender: TObject);
begin
  if RepoEdit.Text <> '' then
    SelectDirectoryDialog1.FileName := RepoEdit.Text;

  if SelectDirectoryDialog1.Execute then
  begin
    RepoEdit.Text := SelectDirectoryDialog1.FileName;
    TimeEdit.Text := CurrentLocalTimeForGit;
    PopulateBranches;
    LoadSnapshot;
  end;
end;

procedure TMainForm.BranchEditChange(Sender: TObject);
begin
  FBranchIndex.Clear;
  if FLoadingBranches then
    Exit;

  if (FCommitHash <> '') and (Trim(BranchEdit.Text) <> '') then
    SwitchBranch;
end;

procedure TMainForm.PopulateBranches;
var
  Branches: TStringList;
  Wanted: string;
  I: Integer;
begin
  FBranchIndex.Clear;
  if Trim(RepoEdit.Text) = '' then
    Exit;

  Wanted := Trim(BranchEdit.Text);
  if Wanted = '' then
    Wanted := 'master';

  Branches := TStringList.Create;
  try
    ListBranches(RepoEdit.Text, Branches);

    FLoadingBranches := True;
    try
      BranchEdit.Items.Assign(Branches);

      I := BranchEdit.Items.IndexOf(Wanted);
      if I < 0 then
        I := BranchEdit.Items.IndexOf('master');
      if (I < 0) and (BranchEdit.Items.Count > 0) then
        I := 0;

      if I >= 0 then
        BranchEdit.ItemIndex := I
      else
        BranchEdit.ItemIndex := -1;
    finally
      FLoadingBranches := False;
    end;
  finally
    Branches.Free;
  end;
end;

procedure TMainForm.SwitchBranch;
var
  TargetCommit: string;
  I: Integer;
begin
  if Trim(RepoEdit.Text) = '' then
    Exit;
  if Trim(BranchEdit.Text) = '' then
    Exit;
  if Trim(TimeEdit.Text) = '' then
    TimeEdit.Text := CurrentLocalTimeForGit;

  Screen.Cursor := crHourGlass;
  try
    TargetCommit := ResolveCommit(
      RepoEdit.Text,
      BranchEdit.Text,
      TimeEdit.Text
    );

    FPreviousCommitHash := '';
    BuildBranchTimeline(TargetCommit);

    I := FTimeline.IndexOf(TargetCommit);
    if I >= 0 then
    begin
      FCommitHash := '';
      SelectTimelineIndex(I);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TMainForm.LoadSnapshot;
var
  TargetCommit: string;
  I: Integer;
begin
  if Trim(RepoEdit.Text) = '' then
  begin
    MessageDlg('Repository path is required.', mtError, [mbOK], 0);
    Exit;
  end;

  if BranchEdit.Items.Count = 0 then
    PopulateBranches;

  if Trim(BranchEdit.Text) = '' then
  begin
    MessageDlg('No local branch is selected.', mtError, [mbOK], 0);
    Exit;
  end;

  if Trim(TimeEdit.Text) = '' then
    TimeEdit.Text := CurrentLocalTimeForGit;

  Screen.Cursor := crHourGlass;
  try
    TargetCommit := ResolveCommit(
      RepoEdit.Text,
      BranchEdit.Text,
      TimeEdit.Text
    );

    FCurrentPath := '';
    FPreviousCommitHash := '';
    BuildBranchTimeline(TargetCommit);

    I := FTimeline.IndexOf(TargetCommit);
    if I >= 0 then
    begin
      FCommitHash := '';
      SelectTimelineIndex(I);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TMainForm.BuildBranchIndex;
begin
  FBranchIndex.Clear;
  BuildTimeline(RepoEdit.Text, BranchEdit.Text, FBranchIndex);
  FBranchCommitCount := FBranchIndex.Count;
  FReachableCommitCount := FBranchCommitCount;
end;

procedure TMainForm.BuildBranchTimeline(const CenterCommit: string);
var
  CenterIndex, StartIndex, EndIndex, I, HalfWindow: Integer;
begin
  if FBranchIndex.Count = 0 then
    BuildBranchIndex;

  if FBranchIndex.Count = 0 then
    Exit;

  CenterIndex := FBranchIndex.IndexOf(CenterCommit);
  if CenterIndex < 0 then
    CenterIndex := FBranchIndex.Count - 1;

  FCurrentBranchPosition := CenterIndex;

  HalfWindow := FWindowSize div 2;
  StartIndex := CenterIndex - HalfWindow;
  if StartIndex < 0 then
    StartIndex := 0;

  EndIndex := StartIndex + FWindowSize - 1;
  if EndIndex >= FBranchIndex.Count then
  begin
    EndIndex := FBranchIndex.Count - 1;
    StartIndex := EndIndex - FWindowSize + 1;
    if StartIndex < 0 then
      StartIndex := 0;
  end;

  FTimeline.Clear;
  for I := StartIndex to EndIndex do
    FTimeline.Add(FBranchIndex[I]);

  if StartIndex > 0 then
    FWindowPredecessor := FBranchIndex[StartIndex - 1]
  else
    FWindowPredecessor := '';

  FHasNewer := EndIndex < FBranchIndex.Count - 1;

  FOldestUnixTime := CommitUnixTime(
    RepoEdit.Text,
    FBranchIndex[0]
  );
  FNewestUnixTime := CommitUnixTime(
    RepoEdit.Text,
    FBranchIndex[FBranchIndex.Count - 1]
  );

  UpdateTimeRailLabels;

  FLoadingTimeline := True;
  try
    TimeTrackBar.Min := 0;
    TimeTrackBar.Max := FBranchCommitCount - 1;
    TimeTrackBar.Position := FCurrentBranchPosition;
    TimeTrackBar.Enabled := FBranchCommitCount > 0;

    VerticalTimeTrackBar.Min := 0;
    VerticalTimeTrackBar.Max := 1000;
    FSelectedUnixTime := CommitUnixTime(RepoEdit.Text, CenterCommit);
    VerticalTimeTrackBar.Position :=
      UnixTimeToSlider(FSelectedUnixTime);
    VerticalTimeTrackBar.Enabled := FNewestUnixTime > FOldestUnixTime;
  finally
    FLoadingTimeline := False;
  end;

  UpdateForkInfo;
  UpdateTimelineLabels;
end;

procedure TMainForm.EnsureCurrentPathExists;
var
  P: Integer;
begin
  while (FCurrentPath <> '') and
        (not DirectoryExistsAtCommit(RepoEdit.Text, FCommitHash, FCurrentPath)) do
  begin
    P := LastDelimiter('/', FCurrentPath);
    if P = 0 then
      FCurrentPath := ''
    else
      FCurrentPath := Copy(FCurrentPath, 1, P - 1);
  end;
end;

function TMainForm.UnixTimeToSlider(UnixTime: Int64): Integer;
begin
  { The vertical rail is proportional to commit position, not elapsed time.
    Oldest commit is at the bottom; newest commit is at the top. }
  if FBranchCommitCount <= 1 then
    Exit(0);

  Result := 1000 - Round(
    (FCurrentBranchPosition * 1000.0) /
    (FBranchCommitCount - 1)
  );
end;

function TMainForm.SliderToUnixTime(SliderPos: Integer): Int64;
var
  BranchPos: Integer;
begin
  Result := 0;

  if FBranchIndex.Count = 0 then
    Exit;

  if SliderPos < 0 then
    SliderPos := 0;
  if SliderPos > 1000 then
    SliderPos := 1000;

  if FBranchIndex.Count = 1 then
    BranchPos := 0
  else
    BranchPos := Round(
      ((1000 - SliderPos) * (FBranchIndex.Count - 1)) / 1000.0
    );

  if BranchPos < 0 then
    BranchPos := 0;
  if BranchPos >= FBranchIndex.Count then
    BranchPos := FBranchIndex.Count - 1;

  Result := CommitUnixTime(
    RepoEdit.Text,
    FBranchIndex[BranchPos]
  );
end;

procedure TMainForm.SelectTimePosition(SliderPos: Integer);
var
  BranchPos: Integer;
  CommitHash: string;
begin
  if not VerticalTimeTrackBar.Enabled then
    Exit;

  if FBranchIndex.Count = 0 then
    Exit;

  if SliderPos < 0 then
    SliderPos := 0;
  if SliderPos > 1000 then
    SliderPos := 1000;

  if FBranchIndex.Count = 1 then
    BranchPos := 0
  else
    BranchPos := Round(
      ((1000 - SliderPos) * (FBranchIndex.Count - 1)) / 1000.0
    );

  if BranchPos < 0 then
    BranchPos := 0;
  if BranchPos >= FBranchIndex.Count then
    BranchPos := FBranchIndex.Count - 1;

  CommitHash := FBranchIndex[BranchPos];
  SelectCommitHash(CommitHash);
end;

procedure TMainForm.UpdateVerticalTimeSlider;
var
  SliderPos: Integer;
begin
  if FBranchCommitCount <= 0 then
    Exit;

  if FBranchCommitCount = 1 then
    SliderPos := 0
  else
    SliderPos := 1000 - Round(
      (FCurrentBranchPosition * 1000.0) /
      (FBranchCommitCount - 1)
    );

  FLoadingTimeline := True;
  try
    VerticalTimeTrackBar.Position := SliderPos;
  finally
    FLoadingTimeline := False;
  end;

  UpdateTimeCurrentLabel;
end;

procedure TMainForm.UpdateTimeRailLabels;
begin
  if FNewestUnixTime > 0 then
    TimeNowLabel.Caption :=
      FormatDateTime('yyyy-mm-dd hh:nn',
        UnixToDateTime(FNewestUnixTime, False))
  else
    TimeNowLabel.Caption := '';

  if FOldestUnixTime > 0 then
    TimeStartLabel.Caption :=
      FormatDateTime('yyyy-mm-dd hh:nn',
        UnixToDateTime(FOldestUnixTime, False))
  else
    TimeStartLabel.Caption := '';

  UpdateTimeCurrentLabel;
end;

procedure TMainForm.UpdateTimeCurrentLabel;
var
  P, RailTop, RailBottom, Y: Integer;
begin
  if (FSelectedUnixTime <= 0) or
     (FNewestUnixTime <= FOldestUnixTime) then
  begin
    TimeCurrentLabel.Caption := '';
    Exit;
  end;

  P := VerticalTimeTrackBar.Position;

  { Endpoint labels already identify these positions. }
  if (P = 0) or (P = 1000) then
  begin
    TimeCurrentLabel.Caption := '';
    Exit;
  end;

  TimeCurrentLabel.Caption :=
    FormatDateTime('yyyy-mm-dd hh:nn',
      UnixToDateTime(FSelectedUnixTime, False));

  RailTop := VerticalTimeTrackBar.Top;
  RailBottom := VerticalTimeTrackBar.Top +
    VerticalTimeTrackBar.Height;

  Y := RailTop +
    Round((P / 1000.0) * VerticalTimeTrackBar.Height);

  if P >= 500 then
    Y := Y - TimeCurrentLabel.Height - 2
  else
    Y := Y + 18;

  if Y < RailTop + 18 then
    Y := RailTop + 18;
  if Y + TimeCurrentLabel.Height > RailBottom - 18 then
    Y := RailBottom - 18 - TimeCurrentLabel.Height;

  TimeCurrentLabel.Top := Y;
  TimeCurrentLabel.Left :=
    VerticalTimeTrackBar.Left +
    VerticalTimeTrackBar.Width + 8;
end;

function TMainForm.ResolveSliderCommit(SliderPos: Integer): string;
begin
  Result := '';

  if FBranchIndex.Count = 0 then
    Exit;

  if SliderPos < 0 then
    SliderPos := 0;
  if SliderPos >= FBranchIndex.Count then
    SliderPos := FBranchIndex.Count - 1;

  Result := Trim(FBranchIndex[SliderPos]);
end;

procedure TMainForm.SelectCommitHash(const CommitHash: string);
var
  I, J: Integer;
  FullHash: string;
begin
  if CommitHash = '' then
    Exit;

  FullHash := CommitHash;

  { History rows use abbreviated hashes.  Normalize an abbreviation against
    the full branch index before doing exact timeline lookups. }
  if Length(FullHash) < 40 then
  begin
    for J := 0 to FBranchIndex.Count - 1 do
      if Pos(LowerCase(FullHash), LowerCase(FBranchIndex[J])) = 1 then
      begin
        FullHash := FBranchIndex[J];
        Break;
      end;
  end;

  if FTimeline.IndexOf(FullHash) < 0 then
    BuildBranchTimeline(FullHash);

  I := FTimeline.IndexOf(FullHash);
  if I >= 0 then
  begin
    SelectTimelineIndex(I);

    { Direct commit navigation defines the selected time as the commit time.
      This keeps the horizontal commit slider, vertical time slider, and
      snapshot synchronized.  Time-driven navigation restores its requested
      time after this call. }
    FSelectedUnixTime := CommitUnixTime(RepoEdit.Text, FCommitHash);
    UpdateVerticalTimeSlider;
  end;
end;

procedure TMainForm.SelectTimelineIndex(Index: Integer);
begin
  if FTimeline.Count = 0 then
    Exit;

  if Index < 0 then
    Index := 0;
  if Index >= FTimeline.Count then
    Index := FTimeline.Count - 1;

  FPreviousCommitHash := FCommitHash;
  FCommitHash := Trim(FTimeline[Index]);

  FCurrentBranchPosition := FBranchIndex.IndexOf(FCommitHash);
  if FCurrentBranchPosition < 0 then
    FCurrentBranchPosition := 0;

  FLoadingTimeline := True;
  try
    TimeTrackBar.Position := FCurrentBranchPosition;
  finally
    FLoadingTimeline := False;
  end;

  TimeEdit.Text := CommitTime(RepoEdit.Text, FCommitHash);
  SnapshotLabel.Caption := 'Snapshot: ' + FCommitHash + '  @  ' +
    TimeEdit.Text;
  CommitInfoLabel.Caption := 'Commit: ' + Copy(FCommitHash, 1, 8) +
    '  ' + TimeEdit.Text + '  ' + CommitSubject(RepoEdit.Text, FCommitHash);

  if FPreviousCommitHash = '' then
    CompareLabel.Caption := 'Compare: —'
  else if CommitTime(RepoEdit.Text, FPreviousCommitHash) <
          CommitTime(RepoEdit.Text, FCommitHash) then
    CompareLabel.Caption := 'Compare: ' + Copy(FPreviousCommitHash, 1, 8) +
      '  ->  ' + Copy(FCommitHash, 1, 8)
  else
    CompareLabel.Caption := 'Compare: ' + Copy(FCommitHash, 1, 8) +
      '  <-  ' + Copy(FPreviousCommitHash, 1, 8);

  EnsureCurrentPathExists;
  BuildEntryStates(PredecessorCommit(FCommitHash), FCommitHash);
  LoadCurrentDirectory;
  UpdateTimelineControls;
end;

procedure TMainForm.UpdateForkInfo;
begin
  FForkIndex := -1;
  FForkHash := '';
  FBranchCommitCount := FBranchIndex.Count;
  FReachableCommitCount := FBranchCommitCount;
  FAfterForkCount := 0;

  if (Trim(BranchEdit.Text) = '') or
     SameText(Trim(BranchEdit.Text), 'master') then
    Exit;

  if BranchEdit.Items.IndexOf('master') < 0 then
    Exit;

  FForkHash := FindMergeBase(
    RepoEdit.Text,
    'master',
    BranchEdit.Text
  );

  if FForkHash <> '' then
  begin
    FForkIndex := FBranchIndex.IndexOf(FForkHash);
    FAfterForkCount := CountCommitsAfter(
      RepoEdit.Text,
      FForkHash,
      BranchEdit.Text
    );
  end;
end;


procedure TMainForm.UpdateTimelineLabels;
var
  CurrentIndex, PixelRange, X: Integer;
  WindowStartPos, WindowEndPos: Integer;
begin
  if FTimeline.Count = 0 then
  begin
    ForkLabel.Caption := '';
    ScaleLabel.Caption := '';
    Exit;
  end;



  PixelRange := TimeTrackBar.Width;
  if FBranchCommitCount > 1 then
    X := TimeTrackBar.Left +
      Round(FCurrentBranchPosition * PixelRange /
        (FBranchCommitCount - 1))
  else
    X := TimeTrackBar.Left;


  if FForkHash <> '' then
    ForkLabel.Caption := '^ fork ' + Copy(FForkHash, 1, 8)
  else
    ForkLabel.Caption := '';

  CurrentIndex := FTimeline.IndexOf(FCommitHash);
  if CurrentIndex < 0 then
    CurrentIndex := 0;

  WindowStartPos := FCurrentBranchPosition - CurrentIndex;
  WindowEndPos := WindowStartPos + FTimeline.Count - 1;

  ScaleLabel.Caption :=
    'Cached commits ' + IntToStr(WindowStartPos + 1) + '-' +
    IntToStr(WindowEndPos + 1) + ' of ' +
    IntToStr(FBranchCommitCount);

  if FForkHash <> '' then
    ScaleLabel.Caption := ScaleLabel.Caption + ' · ' +
      IntToStr(FAfterForkCount) + ' after fork';
end;


procedure TMainForm.UpdateTimelineControls;
begin
  PrevButton.Enabled := FCurrentBranchPosition > 0;
  NextButton.Enabled := FCurrentBranchPosition < FBranchCommitCount - 1;
  FirstButton.Enabled := FCurrentBranchPosition > 0;
  LastButton.Enabled := FCurrentBranchPosition < FBranchCommitCount - 1;

  UpdateTimelineLabels;
end;

procedure TMainForm.StepNavigation(Delta: Integer);
var
  TargetPos: Integer;
  CommitHash: string;
begin
  if FBranchCommitCount <= 0 then
    Exit;

  TargetPos := FCurrentBranchPosition + Delta;

  if TargetPos < 0 then
    TargetPos := 0;
  if TargetPos >= FBranchCommitCount then
    TargetPos := FBranchCommitCount - 1;

  if TargetPos = FCurrentBranchPosition then
    Exit;

  CommitHash := ResolveSliderCommit(TargetPos);
  SelectCommitHash(CommitHash);
end;

procedure TMainForm.NavButtonMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;

  if Sender = PrevButton then
    FNavDirection := -1
  else if Sender = NextButton then
    FNavDirection := 1
  else
    Exit;

  FNavHoldTicks := 0;
  FNavRepeated := False;
  FNavTimer.Enabled := True;
end;

procedure TMainForm.NavButtonMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;

  FNavTimer.Enabled := False;
  FNavDirection := 0;
  FNavHoldTicks := 0;
end;

procedure TMainForm.NavTimerTimer(Sender: TObject);
var
  StepSize: Integer;
begin
  Inc(FNavHoldTicks);

  { 250 ms ticks: wait about one second before repeating. }
  if FNavHoldTicks < 4 then
    Exit;

  if FNavHoldTicks < 8 then
    StepSize := 1
  else if FNavHoldTicks < 16 then
    StepSize := 2
  else if FNavHoldTicks < 24 then
    StepSize := 5
  else
    StepSize := 10;

  FNavRepeated := True;
  StepNavigation(FNavDirection * StepSize);
end;

procedure TMainForm.PrevButtonClick(Sender: TObject);
begin
  if FNavRepeated then
  begin
    FNavRepeated := False;
    Exit;
  end;

  StepNavigation(-1);
end;

procedure TMainForm.FirstButtonClick(Sender: TObject);
begin
  if FBranchIndex.Count > 0 then
    SelectCommitHash(FBranchIndex[0]);
end;

procedure TMainForm.LastButtonClick(Sender: TObject);
begin
  if FBranchIndex.Count > 0 then
    SelectCommitHash(FBranchIndex[FBranchIndex.Count - 1]);
end;

procedure TMainForm.NextButtonClick(Sender: TObject);
begin
  if FNavRepeated then
  begin
    FNavRepeated := False;
    Exit;
  end;

  StepNavigation(1);
end;

procedure TMainForm.TimePreviewTimerTimer(Sender: TObject);
begin
  FTimePreviewTimer.Enabled := False;
  UpdateTimeCurrentLabel;
end;

procedure TMainForm.VerticalTimeTrackBarChange(Sender: TObject);
begin
  if FLoadingTimeline then
    Exit;

  FPendingTimePosition := VerticalTimeTrackBar.Position;
  FSelectedUnixTime := SliderToUnixTime(FPendingTimePosition);

  FTimePreviewTimer.Enabled := False;
  FTimePreviewTimer.Enabled := True;
end;

procedure TMainForm.VerticalTimeTrackBarMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;

  FDraggingTime := True;
  FPendingTimePosition := VerticalTimeTrackBar.Position;
end;

procedure TMainForm.VerticalTimeTrackBarMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;

  if not FDraggingTime then
    Exit;

  FDraggingTime := False;
  FPendingTimePosition := VerticalTimeTrackBar.Position;
  FSelectedUnixTime := SliderToUnixTime(FPendingTimePosition);

  FTimePreviewTimer.Enabled := False;
  UpdateTimeCurrentLabel;
  SelectTimePosition(FPendingTimePosition);
end;

procedure TMainForm.VerticalTimeTrackBarKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if FLoadingTimeline or FDraggingTime then
    Exit;

  FPendingTimePosition := VerticalTimeTrackBar.Position;
  FSelectedUnixTime := SliderToUnixTime(FPendingTimePosition);

  FTimePreviewTimer.Enabled := False;
  UpdateTimeCurrentLabel;
  SelectTimePosition(FPendingTimePosition);
end;

procedure TMainForm.TimeTrackBarMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;

  FDraggingTimeline := True;
  FPendingTimelinePosition := TimeTrackBar.Position;
end;

procedure TMainForm.TimeTrackBarMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CommitHash: string;
begin
  if Button <> mbLeft then
    Exit;

  if not FDraggingTimeline then
    Exit;

  FDraggingTimeline := False;
  FPendingTimelinePosition := TimeTrackBar.Position;

  CommitHash := ResolveSliderCommit(FPendingTimelinePosition);
  SelectCommitHash(CommitHash);
end;

procedure TMainForm.TimeTrackBarKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
  CommitHash: string;
begin
  if FLoadingTimeline or FDraggingTimeline then
    Exit;

  FPendingTimelinePosition := TimeTrackBar.Position;
  CommitHash := ResolveSliderCommit(FPendingTimelinePosition);
  SelectCommitHash(CommitHash);
end;

procedure TMainForm.TimeTrackBarChange(Sender: TObject);
begin
  if FLoadingTimeline then
    Exit;

  { Never resolve Git history from OnChange.  GTK can emit this before
    MouseDown while the thumb is being grabbed, and resolving here causes
    GTM to move the thumb back underneath the user's drag. }
  FPendingTimelinePosition := TimeTrackBar.Position;
end;

function TMainForm.EntryNameFromObject(const S: string): string;
var
  P1, P2: Integer;
begin
  P1 := Pos(#9, S);
  if P1 = 0 then
    Exit('');
  P2 := Pos(#9, Copy(S, P1 + 1, MaxInt));
  if P2 = 0 then
    Exit('');
  P2 := P1 + P2;
  Result := Copy(S, P2 + 1, MaxInt);
end;

function TMainForm.EntryHashFromObject(const S: string): string;
var
  P1, P2: Integer;
begin
  P1 := Pos(#9, S);
  if P1 = 0 then
    Exit('');
  P2 := Pos(#9, Copy(S, P1 + 1, MaxInt));
  if P2 = 0 then
    Exit('');
  Result := Copy(S, P1 + 1, P2 - 1);
end;

function TMainForm.FindObjectByName(Objects: TStrings;
  const EntryName: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Objects.Count - 1 do
    if EntryNameFromObject(Objects[I]) = EntryName then
      Exit(Objects[I]);
end;

function TMainForm.PredecessorCommit(const CommitHash: string): string;
var
  I: Integer;
begin
  Result := '';
  if (CommitHash = '') or (FTimeline = nil) then
    Exit;

  I := FTimeline.IndexOf(CommitHash);
  if I > 0 then
    Result := Trim(FTimeline[I - 1])
  else if I = 0 then
    Result := FWindowPredecessor;
end;

procedure TMainForm.BuildEntryStates(const FromCommit, ToCommit: string);
var
  OldObjects, NewObjects: TStringList;
  I: Integer;
  NewObject, OldObject, EntryName, NewHash, OldHash: string;
begin
  FEntryStates.Clear;
  FDeletedEntries.Clear;

  if ToCommit = '' then
    Exit;

  NewObjects := TStringList.Create;
  OldObjects := TStringList.Create;
  try
    ListDirectoryObjects(RepoEdit.Text, ToCommit, FCurrentPath, NewObjects);

    if (FromCommit <> '') and
       DirectoryExistsAtCommit(RepoEdit.Text, FromCommit, FCurrentPath) then
      ListDirectoryObjects(RepoEdit.Text, FromCommit, FCurrentPath, OldObjects);

    for I := 0 to NewObjects.Count - 1 do
    begin
      NewObject := NewObjects[I];
      EntryName := EntryNameFromObject(NewObject);
      NewHash := EntryHashFromObject(NewObject);
      OldObject := FindObjectByName(OldObjects, EntryName);

      if OldObject = '' then
        FEntryStates.Values[EntryName] := 'added'
      else
      begin
        OldHash := EntryHashFromObject(OldObject);
        if OldHash <> NewHash then
          FEntryStates.Values[EntryName] := 'modified'
        else
          FEntryStates.Values[EntryName] := 'unchanged';
      end;
    end;

    for I := 0 to OldObjects.Count - 1 do
    begin
      OldObject := OldObjects[I];
      EntryName := EntryNameFromObject(OldObject);

      if FindObjectByName(NewObjects, EntryName) = '' then
      begin
        if Pos('tree' + #9, OldObject) = 1 then
          EntryName := EntryName + '/';
        FDeletedEntries.Add(EntryName);
      end;
    end;
  finally
    OldObjects.Free;
    NewObjects.Free;
  end;
end;

procedure TMainForm.RefreshCurrentDirectory;
begin
  BuildEntryStates(PredecessorCommit(FCommitHash), FCommitHash);
  LoadCurrentDirectory;
  TreeList.Invalidate;
end;

procedure TMainForm.LoadCurrentDirectory;
var
  Entries, DisplayEntries: TStringList;
  I: Integer;
  RawEntry, EntryName, ChangeState, DisplayEntry: string;
begin
  if FCommitHash = '' then
    Exit;

  Entries := TStringList.Create;
  DisplayEntries := TStringList.Create;
  try
    ListDirectoryEntries(
      RepoEdit.Text,
      FCommitHash,
      FCurrentPath,
      Entries
    );

    DisplayEntries.Sorted := True;
    DisplayEntries.CaseSensitive := False;

    for I := 0 to Entries.Count - 1 do
    begin
      RawEntry := Entries[I];
      EntryName := RawEntry;

      while (Length(EntryName) > 0) and
            (EntryName[Length(EntryName)] = '/') do
        Delete(EntryName, Length(EntryName), 1);

      ChangeState := FEntryStates.Values[EntryName];

      if ChangeState = 'added' then
        DisplayEntry := RawEntry + ' [added]'
      else if ChangeState = 'modified' then
        DisplayEntry := RawEntry + ' [modified]'
      else
        DisplayEntry := RawEntry;

      DisplayEntries.Add(DisplayEntry);
    end;

    for I := 0 to FDeletedEntries.Count - 1 do
      DisplayEntries.Add(FDeletedEntries[I] + ' [deleted]');

    TreeList.Items.BeginUpdate;
    try
      TreeList.Items.Clear;

      if FCurrentPath <> '' then
        TreeList.Items.Add('../');

      for I := 0 to DisplayEntries.Count - 1 do
        TreeList.Items.Add(DisplayEntries[I]);
    finally
      TreeList.Items.EndUpdate;
    end;

    if FCurrentPath = '' then
      PathLabel.Caption := 'Path: /'
    else
      PathLabel.Caption := 'Path: /' + FCurrentPath;
  finally
    DisplayEntries.Free;
    Entries.Free;
  end;
end;

function TMainForm.StripStatusDecoration(const S: string): string;
const
  AddedSuffix = ' [added]';
  ModifiedSuffix = ' [modified]';
  DeletedSuffix = ' [deleted]';
begin
  Result := S;

  if (Length(Result) >= Length(AddedSuffix)) and
     (Copy(Result, Length(Result) - Length(AddedSuffix) + 1,
       Length(AddedSuffix)) = AddedSuffix) then
    Delete(Result, Length(Result) - Length(AddedSuffix) + 1,
      Length(AddedSuffix))
  else if (Length(Result) >= Length(ModifiedSuffix)) and
          (Copy(Result, Length(Result) - Length(ModifiedSuffix) + 1,
            Length(ModifiedSuffix)) = ModifiedSuffix) then
    Delete(Result, Length(Result) - Length(ModifiedSuffix) + 1,
      Length(ModifiedSuffix))
  else if (Length(Result) >= Length(DeletedSuffix)) and
          (Copy(Result, Length(Result) - Length(DeletedSuffix) + 1,
            Length(DeletedSuffix)) = DeletedSuffix) then
    Delete(Result, Length(Result) - Length(DeletedSuffix) + 1,
      Length(DeletedSuffix));
end;

function TMainForm.DisplayStatus(const S: string): string;
const
  AddedSuffix = ' [added]';
  ModifiedSuffix = ' [modified]';
  DeletedSuffix = ' [deleted]';
begin
  Result := '';

  if (Length(S) >= Length(AddedSuffix)) and
     (Copy(S, Length(S) - Length(AddedSuffix) + 1,
       Length(AddedSuffix)) = AddedSuffix) then
    Result := 'added'
  else if (Length(S) >= Length(ModifiedSuffix)) and
          (Copy(S, Length(S) - Length(ModifiedSuffix) + 1,
            Length(ModifiedSuffix)) = ModifiedSuffix) then
    Result := 'modified'
  else if (Length(S) >= Length(DeletedSuffix)) and
          (Copy(S, Length(S) - Length(DeletedSuffix) + 1,
            Length(DeletedSuffix)) = DeletedSuffix) then
    Result := 'deleted';
end;

function TMainForm.IsDeletedDisplay(const S: string): Boolean;
begin
  Result := DisplayStatus(S) = 'deleted';
end;

function TMainForm.SelectedDisplayEntry: string;
begin
  Result := '';
  if TreeList.ItemIndex < 0 then
    Exit;
  Result := TreeList.Items[TreeList.ItemIndex];
end;

function TMainForm.SelectedHistoricalPath: string;
var
  EntryText: string;
begin
  Result := '';
  EntryText := SelectedDisplayEntry;
  if (EntryText = '') or (EntryText = '../') or IsDeletedDisplay(EntryText) then
    Exit;

  EntryText := StripStatusDecoration(EntryText);
  while (Length(EntryText) > 0) and
        (EntryText[Length(EntryText)] = '/') do
    Delete(EntryText, Length(EntryText), 1);

  if FCurrentPath = '' then
    Result := EntryText
  else
    Result := FCurrentPath + '/' + EntryText;
end;

function TMainForm.TempPathForCommit(const CommitHash,
  RepoPath: string): string;
var
  BaseRoot, ShortHash: string;
begin
  ShortHash := Copy(CommitHash, 1, 8);
  BaseRoot := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'gtm' +
    DirectorySeparator + ShortHash;

  Result := IncludeTrailingPathDelimiter(BaseRoot) +
    StringReplace(RepoPath, '/', DirectorySeparator, [rfReplaceAll]);
end;

procedure TMainForm.MaterializeTempFile(const CommitHash, RepoPath: string;
  out TempFile: string);
var
  ParentDir: string;
begin
  TempFile := TempPathForCommit(CommitHash, RepoPath);
  ParentDir := ExtractFileDir(TempFile);

  if not ForceDirectories(ParentDir) then
    Die('unable to create temporary directory: ' + ParentDir);

  ExtractFile(RepoEdit.Text, CommitHash, RepoPath, TempFile);
end;

function TMainForm.IsDirectoryEntry(const S: string): Boolean;
var
  EntryText: string;
begin
  EntryText := StripStatusDecoration(S);
  Result := (Length(EntryText) > 0) and
    (EntryText[Length(EntryText)] = '/');
end;

function TMainForm.JoinRepoPath(const BasePath, EntryName: string): string;
begin
  if BasePath = '' then
    Result := EntryName
  else
    Result := BasePath + '/' + EntryName;
end;

procedure TMainForm.EnterDirectory(const EntryName: string);
var
  DirName: string;
begin
  DirName := EntryName;

  while (Length(DirName) > 0) and (DirName[Length(DirName)] = '/') do
    Delete(DirName, Length(DirName), 1);

  if DirName = '' then
    Exit;

  FCurrentPath := JoinRepoPath(FCurrentPath, DirName);
  RefreshCurrentDirectory;
end;

procedure TMainForm.GoParent;
var
  P: Integer;
begin
  if FCurrentPath = '' then
    Exit;

  P := LastDelimiter('/', FCurrentPath);
  if P = 0 then
    FCurrentPath := ''
  else
    FCurrentPath := Copy(FCurrentPath, 1, P - 1);

  RefreshCurrentDirectory;
end;

procedure TMainForm.OpenHistoricalFile(const EntryName: string);
var
  TempFile: string;
begin
  if EntryName = '' then
    Exit;

  MaterializeTempFile(FCommitHash, EntryName, TempFile);

  if not OpenDocument(TempFile) then
    MessageDlg('Unable to open: ' + TempFile, mtError, [mbOK], 0);
end;


procedure TMainForm.TreeListDrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  S, Status: string;
begin
  with TreeList.Canvas do
  begin
    FillRect(ARect);

    S := TreeList.Items[Index];
    Status := DisplayStatus(S);

    if Status = 'added' then
      Font.Color := clGreen
    else if Status = 'modified' then
      Font.Color := clBlue
    else if Status = 'deleted' then
      Font.Color := clRed
    else
      Font.Color := clWindowText;

    TextOut(ARect.Left + 4, ARect.Top + 2, S);
  end;
end;

procedure TMainForm.FilePopupPopup(Sender: TObject);
var
  S, Status: string;
  IsFile: Boolean;
begin
  S := SelectedDisplayEntry;
  Status := DisplayStatus(S);

  IsFile := (S <> '') and (S <> '../') and
    (not IsDeletedDisplay(S)) and (not IsDirectoryEntry(S));

  OpenMenuItem.Enabled := IsFile;
  SaveAsMenuItem.Enabled := IsFile;
  VisualDiffMenuItem.Enabled := IsFile and (Status = 'modified');
  HistoryMenuItem.Enabled := IsFile;
end;

procedure TMainForm.OpenMenuItemClick(Sender: TObject);
var
  PathName: string;
begin
  PathName := SelectedHistoricalPath;
  if PathName = '' then
    Exit;
  OpenHistoricalFile(PathName);
end;

procedure TMainForm.SaveAsMenuItemClick(Sender: TObject);
var
  PathName: string;
begin
  PathName := SelectedHistoricalPath;
  if PathName = '' then
    Exit;

  SaveDialog.FileName := ExtractFileName(PathName);
  if SaveDialog.Execute then
    ExtractFile(RepoEdit.Text, FCommitHash, PathName, SaveDialog.FileName);
end;

procedure TMainForm.VisualDiffMenuItemClick(Sender: TObject);
var
  PathName, PrevCommit, OldFile, NewFile: string;
  P: TProcess;
begin
  PathName := SelectedHistoricalPath;
  if PathName = '' then
    Exit;

  PrevCommit := PredecessorCommit(FCommitHash);
  if PrevCommit = '' then
    Exit;

  MaterializeTempFile(PrevCommit, PathName, OldFile);
  MaterializeTempFile(FCommitHash, PathName, NewFile);

  P := TProcess.Create(nil);
  try
    P.Executable := 'meld';
    P.Parameters.Add(OldFile);
    P.Parameters.Add(NewFile);
    P.Options := [];
    try
      P.Execute;
    except
      on E: Exception do
        MessageDlg('Unable to launch visual diff: ' + E.Message,
          mtError, [mbOK], 0);
    end;
  finally
    P.Free;
  end;
end;


procedure TMainForm.HistoryMenuItemClick(Sender: TObject);
var
  PathName: string;
  Lines: TStringList;
  HistoryForm: TForm;
  ButtonPanel: TPanel;
  CloseButton: TButton;
  HistoryPopup: TPopupMenu;
  JumpItem, VisualDiffItem: TMenuItem;
begin
  PathName := SelectedHistoricalPath;
  if PathName = '' then
    Exit;

  Lines := TStringList.Create;
  try
    GetHistory(
      RepoEdit.Text,
      BranchEdit.Text,
      PathName,
      Lines
    );

    if Lines.Count = 0 then
    begin
      MessageDlg('No history found for ' + PathName,
        mtInformation, [mbOK], 0);
      Exit;
    end;

    HistoryForm := TForm.CreateNew(Self);
    try
      HistoryForm.Caption := 'History: ' + PathName;
      HistoryForm.Position := poScreenCenter;
      HistoryForm.Width := 820;
      HistoryForm.Height := 520;

      ButtonPanel := TPanel.Create(HistoryForm);
      ButtonPanel.Parent := HistoryForm;
      ButtonPanel.Align := alBottom;
      ButtonPanel.Height := 44;
      ButtonPanel.BevelOuter := bvNone;

      CloseButton := TButton.Create(HistoryForm);
      CloseButton.Parent := ButtonPanel;
      CloseButton.Caption := 'Close';
      CloseButton.Left := 8;
      CloseButton.Top := 8;
      CloseButton.Width := 88;
      CloseButton.ModalResult := mrCancel;

      HistoryPopup := TPopupMenu.Create(HistoryForm);
      HistoryPopup.OnPopup := @HistoryPopupPopup;

      JumpItem := TMenuItem.Create(HistoryPopup);
      JumpItem.Caption := 'Jump';
      JumpItem.OnClick := @HistoryJumpMenuItemClick;
      HistoryPopup.Items.Add(JumpItem);

      VisualDiffItem := TMenuItem.Create(HistoryPopup);
      VisualDiffItem.Caption := 'Visual Diff';
      VisualDiffItem.OnClick := @HistoryVisualDiffMenuItemClick;
      HistoryPopup.Items.Add(VisualDiffItem);

      FHistoryList := TListBox.Create(HistoryForm);
      FHistoryList.Parent := HistoryForm;
      FHistoryList.Align := alClient;
      FHistoryList.Font.Name := 'Monospace';
      FHistoryList.Items.Assign(Lines);
      FHistoryList.ItemIndex := 0;
      FHistoryList.MultiSelect := True;
      FHistoryList.ExtendedSelect := True;
      FHistoryList.DoubleBuffered := True;
      FHistoryList.PopupMenu := HistoryPopup;
      FHistoryList.OnDblClick := @HistoryListDblClick;
      FHistoryList.OnSelectionChange := @HistoryListSelectionChange;

      FHistoryPath := PathName;
      FHistorySelectionUpdating := False;

      HistoryForm.ShowModal;
    finally
      FHistoryList := nil;
      FHistoryPath := '';
      FHistorySelectionUpdating := False;
      HistoryForm.Free;
    end;
  finally
    Lines.Free;
  end;
end;

procedure TMainForm.HistoryListDblClick(Sender: TObject);
begin
  HistoryJumpMenuItemClick(Sender);
end;

procedure TMainForm.HistoryListSelectionChange(Sender: TObject; User: Boolean);
var
  I, SelectedCount, KeepOther: Integer;
begin
  if FHistorySelectionUpdating or (FHistoryList = nil) then
    Exit;

  SelectedCount := 0;
  for I := 0 to FHistoryList.Items.Count - 1 do
    if FHistoryList.Selected[I] then
      Inc(SelectedCount);

  if SelectedCount <= 2 then
    Exit;

  FHistorySelectionUpdating := True;
  try
    { Keep the focused row and one other selected row. }
    KeepOther := -1;
    for I := 0 to FHistoryList.Items.Count - 1 do
      if FHistoryList.Selected[I] and (I <> FHistoryList.ItemIndex) then
      begin
        if KeepOther < 0 then
          KeepOther := I
        else
          FHistoryList.Selected[I] := False;
      end;
  finally
    FHistorySelectionUpdating := False;
  end;
end;

procedure TMainForm.HistoryPopupPopup(Sender: TObject);
var
  I, SelectedCount: Integer;
begin
  if (Sender = nil) or not (Sender is TPopupMenu) or
     (FHistoryList = nil) then
    Exit;

  SelectedCount := 0;
  for I := 0 to FHistoryList.Items.Count - 1 do
    if FHistoryList.Selected[I] then
      Inc(SelectedCount);

  TPopupMenu(Sender).Items[0].Enabled :=
    SelectedCount = 1;
  TPopupMenu(Sender).Items[1].Enabled :=
    SelectedCount = 2;
end;

procedure TMainForm.HistoryJumpMenuItemClick(Sender: TObject);
var
  S, CommitHash: string;
  P1, P2: Integer;
begin
  if (FHistoryList = nil) or (FHistoryList.ItemIndex < 0) then
    Exit;

  S := FHistoryList.Items[FHistoryList.ItemIndex];

  P1 := Pos('  ', S);
  if P1 = 0 then
    Exit;

  Delete(S, 1, P1 + 1);
  while (Length(S) > 0) and (S[1] = ' ') do
    Delete(S, 1, 1);

  P2 := Pos('  ', S);
  if P2 = 0 then
    CommitHash := Trim(S)
  else
    CommitHash := Trim(Copy(S, 1, P2 - 1));

  if CommitHash <> '' then
    SelectCommitHash(CommitHash);
end;

procedure TMainForm.HistoryVisualDiffMenuItemClick(Sender: TObject);
var
  I, Sel1, Sel2, TempIndex, P1, P2: Integer;
  S, Hash1, Hash2, OldFile, NewFile: string;
  P: TProcess;

  function HashFromLine(const Line: string): string;
  var
    T: string;
    Q1, Q2: Integer;
  begin
    Result := '';
    T := Line;

    Q1 := Pos('  ', T);
    if Q1 = 0 then
      Exit;

    Delete(T, 1, Q1 + 1);
    while (Length(T) > 0) and (T[1] = ' ') do
      Delete(T, 1, 1);

    Q2 := Pos('  ', T);
    if Q2 = 0 then
      Result := Trim(T)
    else
      Result := Trim(Copy(T, 1, Q2 - 1));
  end;

  function FullHash(const ShortHash: string): string;
  var
    J: Integer;
  begin
    Result := ShortHash;
    if Length(ShortHash) >= 40 then
      Exit;

    for J := 0 to FBranchIndex.Count - 1 do
      if Pos(LowerCase(ShortHash), LowerCase(FBranchIndex[J])) = 1 then
      begin
        Result := FBranchIndex[J];
        Exit;
      end;
  end;

begin
  if (FHistoryList = nil) or (FHistoryPath = '') then
    Exit;

  Sel1 := -1;
  Sel2 := -1;

  for I := 0 to FHistoryList.Items.Count - 1 do
    if FHistoryList.Selected[I] then
    begin
      if Sel1 < 0 then
        Sel1 := I
      else if Sel2 < 0 then
        Sel2 := I;
    end;

  if (Sel1 < 0) or (Sel2 < 0) then
    Exit;

  { git log is newest-first.  Put older on left, newer on right. }
  if Sel1 < Sel2 then
  begin
    TempIndex := Sel1;
    Sel1 := Sel2;
    Sel2 := TempIndex;
  end;

  Hash1 := FullHash(HashFromLine(FHistoryList.Items[Sel1]));
  Hash2 := FullHash(HashFromLine(FHistoryList.Items[Sel2]));

  if (Hash1 = '') or (Hash2 = '') then
    Exit;

  MaterializeTempFile(Hash1, FHistoryPath, OldFile);
  MaterializeTempFile(Hash2, FHistoryPath, NewFile);

  P := TProcess.Create(nil);
  try
    P.Executable := 'meld';
    P.Parameters.Add(OldFile);
    P.Parameters.Add(NewFile);
    P.Options := [];
    try
      P.Execute;
    except
      on E: Exception do
        MessageDlg('Unable to launch visual diff: ' + E.Message,
          mtError, [mbOK], 0);
    end;
  finally
    P.Free;
  end;
end;

procedure TMainForm.TreeListDblClick(Sender: TObject);
var
  S: string;
begin
  if TreeList.ItemIndex < 0 then
    Exit;

  S := TreeList.Items[TreeList.ItemIndex];

  if IsDeletedDisplay(S) then
    Exit;

  if S = '../' then
  begin
    GoParent;
    Exit;
  end;

  if IsDirectoryEntry(S) then
    EnterDirectory(StripStatusDecoration(S))
  else
    OpenHistoricalFile(SelectedHistoricalPath);
end;

end.
