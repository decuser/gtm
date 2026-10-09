unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, Forms, Controls, StdCtrls, Dialogs, ComCtrls, LCLIntf,
  LCLType,
  Graphics, Menus, Process, ExtCtrls, gtmcore;

type
  TMainForm = class(TForm)
    BranchEdit: TComboBox;
    TagEdit: TEdit;
    TagButton: TButton;
    TagLabel: TLabel;
    BranchLabel: TLabel;
    CommitInfoLabel: TLabel;
    CompareLabel: TLabel;
    ScaleLabel: TLabel;
    ForkLabel: TLabel;
    ForkMarkerLabel: TLabel;
    MergeMarkerLabel: TLabel;
    FilePopup: TPopupMenu;
    OpenMenuItem: TMenuItem;
    SaveAsMenuItem: TMenuItem;
    VisualDiffMenuItem: TMenuItem;
    HistoryMenuItem: TMenuItem;
    SaveDialog: TSaveDialog;
    BrowseButton: TButton;
    MountButton: TButton;
    MountsButton: TButton;
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
    procedure MountButtonClick(Sender: TObject);
    procedure MountsButtonClick(Sender: TObject);
    procedure BranchEditChange(Sender: TObject);
    procedure TagButtonClick(Sender: TObject);
    procedure TagChooserAccept(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FirstButtonClick(Sender: TObject);
    procedure NextButtonClick(Sender: TObject);
    procedure LastButtonClick(Sender: TObject);
    procedure PrevButtonClick(Sender: TObject);
    procedure NavButtonMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure NavButtonMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure NavTimerTimer(Sender: TObject);
    procedure VerticalPreviewTimerTimer(Sender: TObject);
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
    FTagCommits: TStringList;
    FTagNames: TStringList;
    FEntryStates: TStringList;
    FDeletedEntries: TStringList;
    FPreviousCommitHash: string;
    FLoadingTimeline: Boolean;
    FLoadingBranches: Boolean;
    FTagChooser: TForm;
    FTagChooserList: TListBox;
    FForkIndex: Integer;
    FForkHash: string;
    FMergeIndex: Integer;
    FMergeHash: string;
    FWindowSize: Integer;
    FWindowPredecessor: string;
    FBranchCommitCount: Integer;
    FAfterForkCount: Integer;
    FCurrentBranchPosition: Integer;
    FNavTimer: TTimer;
    FNavDirection: Integer;
    FNavHoldTicks: Integer;
    FNavRepeated: Boolean;
    FNavKey: Word;
    FDraggingVerticalSliderline: Boolean;
    FPendingTimelinePosition: Integer;
    FDraggingVerticalSlider: Boolean;
    FPendingVerticalPosition: Integer;
    FOldestCommitTime: Int64;
    FNewestCommitTime: Int64;
    FVerticalPreviewTimer: TTimer;
    FSelectedCommitTime: Int64;
    FHistoryList: TListBox;
    FHistoryPath: string;
    FHistorySelectionUpdating: Boolean;
    FMountCommits: TStringList;
    FMountPoints: TStringList;
    FMountList: TListBox;
    procedure LoadSnapshot;
    procedure LoadCurrentDirectory;
    procedure RefreshCurrentDirectory;
    procedure EnterDirectory(const EntryName: string);
    procedure GoParent;
    procedure OpenHistoricalFile(const EntryName: string);
    procedure BuildBranchIndex;
    procedure BuildBranchTimeline(const CenterCommit: string);
    procedure PopulateBranches;
    procedure PopulateTags;
    procedure UpdateTagSelection;
    procedure SwitchBranch;
    procedure EnsureCurrentPathExists;
    procedure SelectTimelineIndex(Index: Integer);
    procedure UpdateTimelineControls;
    procedure StepNavigation(Delta: Integer);
    procedure UpdateTimelineLabels;
    procedure UpdateForkInfo;
    function ResolveSliderCommit(SliderPos: Integer): string;
    function CurrentCommitToVerticalSlider: Integer;
    function VerticalSliderToCommitTime(SliderPos: Integer): Int64;
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
    function MountHelperPath: string;
    function SnapshotMountPoint(const Repo, CommitHash: string): string;
    procedure MountCurrentSnapshot;
    procedure UnmountIndex(Index: Integer);
    procedure UnmountAllSnapshots;
    procedure RefreshMountList;
    procedure MountOpenClick(Sender: TObject);
    procedure MountUnmountClick(Sender: TObject);
    procedure MountUnmountAllClick(Sender: TObject);
    procedure MountVisualDiffClick(Sender: TObject);
  public
  end;

var
  MainWindow: TMainForm;

implementation

{$R *.lfm}




function TMainForm.MountHelperPath: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ExpandFileName(ParamStr(0)))) +
    'gtm-mount';
end;

function TMainForm.SnapshotMountPoint(const Repo, CommitHash: string): string;
var
  BaseDir, RepoName, ShortHash: string;
begin
  BaseDir := IncludeTrailingPathDelimiter(GetEnvironmentVariable('HOME')) +
    '.cache/gtm/mounts';
  RepoName := ExtractFileName(ExcludeTrailingPathDelimiter(ExpandFileName(Repo)));
  ShortHash := Copy(CommitHash, 1, 8);
  Result := IncludeTrailingPathDelimiter(BaseDir) + RepoName + '-' + ShortHash;
end;

procedure TMainForm.RefreshMountList;
var
  I: Integer;
begin
  if FMountList = nil then
    Exit;

  FMountList.Items.Clear;
  for I := 0 to FMountPoints.Count - 1 do
    FMountList.Items.Add(
      Copy(FMountCommits[I], 1, 8) + '   ' + FMountPoints[I]
    );

  if FMountList.Items.Count > 0 then
    FMountList.ItemIndex := 0;
end;

procedure TMainForm.MountCurrentSnapshot;
var
  Helper, MountPoint, RepoPath: string;
  P: TProcess;
  Existing: Integer;
begin
  if (Trim(RepoEdit.Text) = '') or (Trim(FCommitHash) = '') then
  begin
    ShowMessage('No snapshot is selected.');
    Exit;
  end;

  RepoPath := ExpandFileName(RepoEdit.Text);
  MountPoint := SnapshotMountPoint(RepoPath, FCommitHash);

  Existing := FMountPoints.IndexOf(MountPoint);
  if Existing >= 0 then
  begin
    ShowMessage('Snapshot is already mounted at:' + LineEnding + MountPoint);
    Exit;
  end;

  Helper := MountHelperPath;
  if not FileExists(Helper) then
  begin
    ShowMessage('gtm-mount was not found:' + LineEnding + Helper +
      LineEnding + LineEnding + 'Run make mount first.');
    Exit;
  end;

  if not ForceDirectories(MountPoint) then
  begin
    ShowMessage('Could not create mountpoint:' + LineEnding + MountPoint);
    Exit;
  end;

  P := TProcess.Create(nil);
  try
    P.Executable := Helper;
    P.Parameters.Add(RepoPath);
    P.Parameters.Add(FCommitHash);
    P.Parameters.Add(MountPoint);
    P.Options := [];
    P.Execute;
  finally
    P.Free;
  end;

  FMountCommits.Add(FCommitHash);
  FMountPoints.Add(MountPoint);

  P := TProcess.Create(nil);
  try
    P.Executable := 'xdg-open';
    P.Parameters.Add(MountPoint);
    P.Options := [];
    try
      P.Execute;
    except
      { The mount is still valid even if no desktop file browser is available. }
    end;
  finally
    P.Free;
  end;
end;

procedure TMainForm.UnmountIndex(Index: Integer);
var
  P: TProcess;
  MountPoint: string;
begin
  if (Index < 0) or (Index >= FMountPoints.Count) then
    Exit;

  MountPoint := FMountPoints[Index];

  P := TProcess.Create(nil);
  try
    P.Executable := 'fusermount3';
    P.Parameters.Add('-u');
    P.Parameters.Add(MountPoint);
    P.Options := [poWaitOnExit];
    P.Execute;

    if P.ExitStatus <> 0 then
    begin
      ShowMessage('Could not unmount:' + LineEnding + MountPoint +
        LineEnding + LineEnding +
        'The mount may still be busy.');
      Exit;
    end;
  finally
    P.Free;
  end;

  FMountCommits.Delete(Index);
  FMountPoints.Delete(Index);

  if DirectoryExists(MountPoint) then
    RemoveDir(MountPoint);

  RefreshMountList;
end;

procedure TMainForm.UnmountAllSnapshots;
var
  I: Integer;
  P: TProcess;
  MountPoint: string;
begin
  for I := FMountPoints.Count - 1 downto 0 do
  begin
    MountPoint := FMountPoints[I];

    P := TProcess.Create(nil);
    try
      P.Executable := 'fusermount3';
      P.Parameters.Add('-u');
      P.Parameters.Add(MountPoint);
      P.Options := [poWaitOnExit];
      try
        P.Execute;
      except
        { Best-effort cleanup during shutdown. }
      end;
    finally
      P.Free;
    end;

    if DirectoryExists(MountPoint) then
      RemoveDir(MountPoint);

    FMountCommits.Delete(I);
    FMountPoints.Delete(I);
  end;

  RefreshMountList;
end;

procedure TMainForm.MountButtonClick(Sender: TObject);
begin
  MountCurrentSnapshot;
end;

procedure TMainForm.MountOpenClick(Sender: TObject);
var
  P: TProcess;
begin
  if (FMountList = nil) or
     (FMountList.ItemIndex < 0) or
     (FMountList.ItemIndex >= FMountPoints.Count) then
    Exit;

  P := TProcess.Create(nil);
  try
    P.Executable := 'xdg-open';
    P.Parameters.Add(FMountPoints[FMountList.ItemIndex]);
    P.Options := [];
    P.Execute;
  finally
    P.Free;
  end;
end;

procedure TMainForm.MountUnmountClick(Sender: TObject);
begin
  if FMountList = nil then
    Exit;
  UnmountIndex(FMountList.ItemIndex);
end;

procedure TMainForm.MountUnmountAllClick(Sender: TObject);
begin
  UnmountAllSnapshots;
end;

procedure TMainForm.MountVisualDiffClick(Sender: TObject);
var
  I, FirstIndex, SecondIndex, SelectedCount: Integer;
  P: TProcess;
begin
  if FMountList = nil then
    Exit;

  FirstIndex := -1;
  SecondIndex := -1;
  SelectedCount := 0;

  for I := 0 to FMountList.Items.Count - 1 do
  begin
    if FMountList.Selected[I] then
    begin
      Inc(SelectedCount);
      if FirstIndex < 0 then
        FirstIndex := I
      else if SecondIndex < 0 then
        SecondIndex := I;
    end;
  end;

  if SelectedCount <> 2 then
  begin
    ShowMessage('Select exactly two mounted snapshots.');
    Exit;
  end;

  P := TProcess.Create(nil);
  try
    P.Executable := 'meld';
    P.Parameters.Add(FMountPoints[FirstIndex]);
    P.Parameters.Add(FMountPoints[SecondIndex]);
    P.Options := [];
    try
      P.Execute;
    except
      on E: Exception do
        ShowMessage('Could not launch visual diff:' + LineEnding + E.Message);
    end;
  finally
    P.Free;
  end;
end;

procedure TMainForm.MountsButtonClick(Sender: TObject);
var
  Dialog: TForm;
  ButtonPanel: TPanel;
  OpenButton, VisualDiffButton, UnmountButton, UnmountAllButton, CloseButton: TButton;
begin
  Dialog := TForm.Create(Self);
  try
    Dialog.Caption := 'Mounted Snapshots';
    Dialog.Position := poMainFormCenter;
    Dialog.BorderStyle := bsSizeToolWin;
    Dialog.ClientWidth := 720;
    Dialog.ClientHeight := 330;

    ButtonPanel := TPanel.Create(Dialog);
    ButtonPanel.Parent := Dialog;
    ButtonPanel.Align := alBottom;
    ButtonPanel.Height := 52;
    ButtonPanel.BevelOuter := bvNone;

    OpenButton := TButton.Create(ButtonPanel);
    OpenButton.Parent := ButtonPanel;
    OpenButton.Caption := 'Open';
    OpenButton.Left := 120;
    OpenButton.Top := 10;
    OpenButton.Width := 90;
    OpenButton.OnClick := @MountOpenClick;

    VisualDiffButton := TButton.Create(ButtonPanel);
    VisualDiffButton.Parent := ButtonPanel;
    VisualDiffButton.Caption := 'Visual Diff';
    VisualDiffButton.Left := 216;
    VisualDiffButton.Top := 10;
    VisualDiffButton.Width := 110;
    VisualDiffButton.OnClick := @MountVisualDiffClick;

    UnmountButton := TButton.Create(ButtonPanel);
    UnmountButton.Parent := ButtonPanel;
    UnmountButton.Caption := 'Unmount';
    UnmountButton.Left := 332;
    UnmountButton.Top := 10;
    UnmountButton.Width := 100;
    UnmountButton.OnClick := @MountUnmountClick;

    UnmountAllButton := TButton.Create(ButtonPanel);
    UnmountAllButton.Parent := ButtonPanel;
    UnmountAllButton.Caption := 'Unmount All';
    UnmountAllButton.Left := 438;
    UnmountAllButton.Top := 10;
    UnmountAllButton.Width := 120;
    UnmountAllButton.OnClick := @MountUnmountAllClick;

    CloseButton := TButton.Create(ButtonPanel);
    CloseButton.Parent := ButtonPanel;
    CloseButton.Caption := 'Close';
    CloseButton.Left := 564;
    CloseButton.Top := 10;
    CloseButton.Width := 90;
    CloseButton.ModalResult := mrClose;

    FMountList := TListBox.Create(Dialog);
    FMountList.Parent := Dialog;
    FMountList.Align := alClient;
    FMountList.MultiSelect := True;

    RefreshMountList;
    Dialog.ShowModal;
  finally
    FMountList := nil;
      Dialog.Free;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FTimeline := TStringList.Create;
  FBranchIndex := TStringList.Create;
  FTagCommits := TStringList.Create;
  FTagNames := TStringList.Create;
  FEntryStates := TStringList.Create;
  FDeletedEntries := TStringList.Create;
  FPreviousCommitHash := '';
  FMergeIndex := -1;
  FMergeHash := '';
  FLoadingTimeline := False;
  FLoadingBranches := False;
  FForkIndex := -1;
  FForkHash := '';
  FWindowSize := 100;
  FWindowPredecessor := '';
  FBranchCommitCount := 0;
  FAfterForkCount := 0;
  FNavDirection := 0;
  FNavHoldTicks := 0;
  FNavRepeated := False;
  FNavKey := 0;
  FDraggingVerticalSliderline := False;
  FPendingTimelinePosition := 0;
  FDraggingVerticalSlider := False;
  FPendingVerticalPosition := 0;
  FOldestCommitTime := 0;
  FNewestCommitTime := 0;
  FSelectedCommitTime := 0;
  FHistoryList := nil;
  FHistoryPath := '';
  FHistorySelectionUpdating := False;
  FMountCommits := TStringList.Create;
  FMountPoints := TStringList.Create;
  FMountList := nil;
  FNavTimer := TTimer.Create(Self);
  FNavTimer.Enabled := False;
  FNavTimer.Interval := 250;
  FNavTimer.OnTimer := @NavTimerTimer;
  FVerticalPreviewTimer := TTimer.Create(Self);
  FVerticalPreviewTimer.Enabled := False;
  FVerticalPreviewTimer.Interval := 350;
  FVerticalPreviewTimer.OnTimer := @VerticalPreviewTimerTimer;
  BranchEdit.Items.Clear;
  TagEdit.Text := '(none)';
  TagEdit.ReadOnly := True;
  FTagChooser := nil;
  FTagChooserList := nil;
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
  UnmountAllSnapshots;
  FMountPoints.Free;
  FMountCommits.Free;
  FDeletedEntries.Free;
  FEntryStates.Free;
  FTagNames.Free;
  FTagCommits.Free;
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


procedure TMainForm.PopulateTags;
var
  Tags, Reachable, CandidatePath: TStringList;
  TagName, CommitHash, BranchName: string;
  I, J: Integer;
begin
  try
    FTagNames.Clear;
    FTagCommits.Clear;
    FTagNames.Add('(none)');
    FTagCommits.Add('');
    TagEdit.Text := '(none)';

    if Trim(RepoEdit.Text) = '' then
      Exit;

    Tags := TStringList.Create;
    Reachable := TStringList.Create;
    CandidatePath := TStringList.Create;
    try
      { Tags are browsable only when their commit lies on at least one
        actual GTM branch path.  Build that reachable set once. }
      Reachable.Sorted := True;
      Reachable.Duplicates := dupIgnore;

      for I := 0 to BranchEdit.Items.Count - 1 do
      begin
        BranchName := Trim(BranchEdit.Items[I]);
        if BranchName = '' then
          Continue;

        BuildTimeline(RepoEdit.Text, BranchName, CandidatePath);
        for J := 0 to CandidatePath.Count - 1 do
          Reachable.Add(Trim(CandidatePath[J]));
      end;

      ListTags(RepoEdit.Text, Tags);
      for I := Tags.Count - 1 downto 0 do
      begin
        TagName := Trim(Tags[I]);
        CommitHash := ResolveTagCommit(RepoEdit.Text, TagName);
        if (CommitHash <> '') and (Reachable.IndexOf(CommitHash) >= 0) then
        begin
          FTagNames.Add(TagName);
          FTagCommits.Add(CommitHash);
        end;
      end;
    finally
      CandidatePath.Free;
      Reachable.Free;
      Tags.Free;
    end;
  finally
    end;
end;

procedure TMainForm.UpdateTagSelection;
var
  I: Integer;
begin
  TagEdit.Text := '(none)';

  if FCommitHash = '' then
  begin
    Exit;
  end;

  for I := 1 to FTagCommits.Count - 1 do
    if SameText(FTagCommits[I], FCommitHash) then
    begin
      TagEdit.Text := FTagNames[I];
      Exit;
    end;

end;

procedure TMainForm.TagChooserAccept(Sender: TObject);
begin
  if (FTagChooser <> nil) and (FTagChooserList <> nil) then
  begin
    if FTagChooserList.ItemIndex > 0 then
      FTagChooser.ModalResult := mrOk;
  end;
end;

procedure TMainForm.TagButtonClick(Sender: TObject);
var
  Chooser: TForm;
  List: TListBox;
  ButtonPanel: TPanel;
  SelectButton, CancelButton: TButton;
  SelectedIndex, BranchIndex: Integer;
  TargetCommit: string;
  CandidatePath: TStringList;
  FoundBranch: Boolean;
begin
  Chooser := TForm.Create(Self);
  try
    Chooser.Caption := 'Select Tag';
    Chooser.Position := poMainFormCenter;
    Chooser.BorderStyle := bsSizeToolWin;
    Chooser.ClientWidth := 420;
    Chooser.ClientHeight := 360;

    ButtonPanel := TPanel.Create(Chooser);
    ButtonPanel.Parent := Chooser;
    ButtonPanel.Align := alBottom;
    ButtonPanel.Height := 52;
    ButtonPanel.BevelOuter := bvNone;

    SelectButton := TButton.Create(ButtonPanel);
    SelectButton.Parent := ButtonPanel;
    SelectButton.Caption := 'Select';
    SelectButton.Default := True;
    SelectButton.Left := 220;
    SelectButton.Top := 10;
    SelectButton.Width := 90;
    SelectButton.OnClick := @TagChooserAccept;

    CancelButton := TButton.Create(ButtonPanel);
    CancelButton.Parent := ButtonPanel;
    CancelButton.Caption := 'Cancel';
    CancelButton.ModalResult := mrCancel;
    CancelButton.Cancel := True;
    CancelButton.Left := 316;
    CancelButton.Top := 10;
    CancelButton.Width := 90;

    List := TListBox.Create(Chooser);
    List.Parent := Chooser;
    List.Align := alClient;
    List.Items.Assign(FTagNames);
    List.ItemHeight := 24;
    List.ItemIndex := 0;
    List.OnDblClick := @TagChooserAccept;

    FTagChooser := Chooser;
    FTagChooserList := List;
    try
      if Chooser.ShowModal <> mrOk then
        Exit;
    finally
      FTagChooserList := nil;
      FTagChooser := nil;
    end;

    SelectedIndex := List.ItemIndex;
    if (SelectedIndex <= 0) or (SelectedIndex >= FTagCommits.Count) then
      Exit;

    TargetCommit := FTagCommits[SelectedIndex];

    FoundBranch := FBranchIndex.IndexOf(TargetCommit) >= 0;

    if not FoundBranch then
    begin
      CandidatePath := TStringList.Create;
      try
        for BranchIndex := 0 to BranchEdit.Items.Count - 1 do
        begin
          BuildTimeline(
            RepoEdit.Text,
            BranchEdit.Items[BranchIndex],
            CandidatePath
          );

          if CandidatePath.IndexOf(TargetCommit) >= 0 then
          begin
            FLoadingBranches := True;
            try
              BranchEdit.ItemIndex := BranchIndex;
            finally
              FLoadingBranches := False;
            end;

            FBranchIndex.Assign(CandidatePath);
            FBranchCommitCount := FBranchIndex.Count;
                      FoundBranch := True;
            Break;
          end;
        end;
      finally
        CandidatePath.Free;
      end;
    end;

    { PopulateTags filters unreachable tags.  This guard only handles the
      repository changing after the chooser was populated. }
    if not FoundBranch then
    begin
      PopulateTags;
      Exit;
    end;

    FPreviousCommitHash := '';
    BuildBranchTimeline(TargetCommit);
    FCommitHash := '';
    SelectCommitHash(TargetCommit);
    UpdateTagSelection;
  finally
    FTagChooserList := nil;
    FTagChooser := nil;
    Chooser.Free;
  end;
end;

procedure TMainForm.SwitchBranch;
var
  TargetCommit: string;
begin
  if Trim(RepoEdit.Text) = '' then
    Exit;
  if Trim(BranchEdit.Text) = '' then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    FPreviousCommitHash := '';
    FBranchIndex.Clear;
    BuildBranchIndex;

    if FBranchIndex.Count = 0 then
      Exit;

    { Selecting a branch selects its GTM path and lands at the latest point
      on that path.  A rejoined branch therefore lands on the shared
      continuation, not on the old raw Git branch ref. }
    TargetCommit := FBranchIndex[FBranchIndex.Count - 1];

    BuildBranchTimeline(TargetCommit);

    FCommitHash := '';
    SelectCommitHash(TargetCommit);
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
    PopulateTags;

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


  FOldestCommitTime := CommitUnixTime(
    RepoEdit.Text,
    FBranchIndex[0]
  );
  FNewestCommitTime := CommitUnixTime(
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
    FSelectedCommitTime := CommitUnixTime(RepoEdit.Text, CenterCommit);
    VerticalTimeTrackBar.Position :=
      CurrentCommitToVerticalSlider;
    VerticalTimeTrackBar.Enabled := FNewestCommitTime > FOldestCommitTime;
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

function TMainForm.CurrentCommitToVerticalSlider: Integer;
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

function TMainForm.VerticalSliderToCommitTime(SliderPos: Integer): Int64;
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
  if FNewestCommitTime > 0 then
    TimeNowLabel.Caption :=
      FormatDateTime('yyyy-mm-dd hh:nn',
        UnixToDateTime(FNewestCommitTime, False))
  else
    TimeNowLabel.Caption := '';

  if FOldestCommitTime > 0 then
    TimeStartLabel.Caption :=
      FormatDateTime('yyyy-mm-dd hh:nn',
        UnixToDateTime(FOldestCommitTime, False))
  else
    TimeStartLabel.Caption := '';

  UpdateTimeCurrentLabel;
end;

procedure TMainForm.UpdateTimeCurrentLabel;
var
  P, RailTop, RailBottom, Y: Integer;
begin
  if (FSelectedCommitTime <= 0) or
     (FNewestCommitTime <= FOldestCommitTime) then
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
      UnixToDateTime(FSelectedCommitTime, False));

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
    FSelectedCommitTime := CommitUnixTime(RepoEdit.Text, FCommitHash);
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
  UpdateTagSelection;
end;

procedure TMainForm.UpdateForkInfo;
var
  RefTip: string;
  RefTipIndex: Integer;
begin
  FForkIndex := -1;
  FForkHash := '';
  FMergeIndex := -1;
  FMergeHash := '';
  FBranchCommitCount := FBranchIndex.Count;
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
    FForkIndex := FBranchIndex.IndexOf(FForkHash);

  { BuildTimeline already contains the selected branch's complete ordered
    path.  If the branch ref tip is not the end of that path, the next commit
    is the merge where the branch rejoins the continuation. }
  RefTip := BranchTip(RepoEdit.Text, BranchEdit.Text);
  RefTipIndex := FBranchIndex.IndexOf(RefTip);

  if (RefTipIndex >= 0) and
     (RefTipIndex < FBranchIndex.Count - 1) then
  begin
    FMergeIndex := RefTipIndex + 1;
    FMergeHash := FBranchIndex[FMergeIndex];
  end;

  if FForkIndex >= 0 then
  begin
    if FMergeIndex > FForkIndex then
      FAfterForkCount := FMergeIndex - FForkIndex - 1
    else
      FAfterForkCount := FBranchIndex.Count - FForkIndex - 1;
  end;
end;


procedure TMainForm.UpdateTimelineLabels;
var
  CurrentIndex, PixelRange, ForkX, MergeX: Integer;
  WindowStartPos, WindowEndPos: Integer;
begin
  ForkLabel.Caption := '';
  ForkMarkerLabel.Caption := '';
  MergeMarkerLabel.Caption := '';

  if FTimeline.Count = 0 then
  begin
    ScaleLabel.Caption := '';
    Exit;
  end;

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
  begin
    if FMergeHash <> '' then
      ScaleLabel.Caption := ScaleLabel.Caption +
        ' · fork ' + Copy(FForkHash, 1, 8) +
        ' -> merge ' + Copy(FMergeHash, 1, 8) +
        ' -> continues'
    else
      ScaleLabel.Caption := ScaleLabel.Caption +
        ' · fork ' + Copy(FForkHash, 1, 8) +
        ' · unmerged';
  end;

  if FBranchCommitCount > 1 then
  begin
    PixelRange := TimeTrackBar.Width;

    { Fork and merge annotations live below the slider. }
    if FForkIndex >= 0 then
    begin
      ForkX := TimeTrackBar.Left +
        Round(FForkIndex * PixelRange / (FBranchCommitCount - 1));
      ForkMarkerLabel.AutoSize := False;
      ForkMarkerLabel.Width := 18;
      ForkMarkerLabel.Height := 18;
      ForkMarkerLabel.Alignment := taCenter;
      ForkMarkerLabel.Layout := tlCenter;
      ForkMarkerLabel.Caption := 'F';
      ForkMarkerLabel.Left := ForkX - 9;
      ForkMarkerLabel.Top := TimeTrackBar.Top + TimeTrackBar.Height - 2;
      ForkMarkerLabel.Hint := '';
      ForkMarkerLabel.ShowHint := False;
    end;

    if FMergeIndex >= 0 then
    begin
      MergeX := TimeTrackBar.Left +
        Round(FMergeIndex * PixelRange / (FBranchCommitCount - 1));
      MergeMarkerLabel.AutoSize := False;
      MergeMarkerLabel.Width := 18;
      MergeMarkerLabel.Height := 18;
      MergeMarkerLabel.Alignment := taCenter;
      MergeMarkerLabel.Layout := tlCenter;
      MergeMarkerLabel.Caption := 'M';
      MergeMarkerLabel.Left := MergeX - 9;
      MergeMarkerLabel.Top := TimeTrackBar.Top + TimeTrackBar.Height - 2;
      MergeMarkerLabel.Hint := '';
      MergeMarkerLabel.ShowHint := False;
    end;
  end;

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
  FNavKey := 0;
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
  FNavKey := 0;
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

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Direction: Integer;
begin
  Direction := 0;

  case Key of
    VK_LEFT, VK_DOWN:
      Direction := -1;
    VK_RIGHT, VK_UP:
      Direction := 1;
  else
    Exit;
  end;

  { Ctrl+arrow means endpoint on the selected branch path. }
  if ssCtrl in Shift then
  begin
    FNavTimer.Enabled := False;
    FNavDirection := 0;
    FNavHoldTicks := 0;
    FNavKey := 0;

    if FBranchIndex.Count > 0 then
    begin
      if Direction < 0 then
        SelectCommitHash(FBranchIndex[0])
      else
        SelectCommitHash(FBranchIndex[FBranchIndex.Count - 1]);
    end;

    Key := 0;
    Exit;
  end;

  { The OS may send repeated KeyDown events while a key is held.  Ignore
    those and let the same timer used by the mouse navigation buttons do
    the accelerating repeat. }
  if (FNavKey = Key) and (FNavDirection = Direction) then
  begin
    Key := 0;
    Exit;
  end;

  FNavTimer.Enabled := False;
  FNavKey := Key;
  FNavDirection := Direction;
  FNavHoldTicks := 0;
  FNavRepeated := False;

  StepNavigation(Direction);
  FNavTimer.Enabled := True;

  Key := 0;
end;

procedure TMainForm.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key <> VK_LEFT) and (Key <> VK_RIGHT) and
     (Key <> VK_UP) and (Key <> VK_DOWN) then
    Exit;

  FNavTimer.Enabled := False;
  FNavDirection := 0;
  FNavHoldTicks := 0;
  FNavRepeated := False;
  FNavKey := 0;

  Key := 0;
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

procedure TMainForm.VerticalPreviewTimerTimer(Sender: TObject);
begin
  FVerticalPreviewTimer.Enabled := False;
  UpdateTimeCurrentLabel;
end;

procedure TMainForm.VerticalTimeTrackBarChange(Sender: TObject);
begin
  if FLoadingTimeline then
    Exit;

  FPendingVerticalPosition := VerticalTimeTrackBar.Position;
  FSelectedCommitTime := VerticalSliderToCommitTime(FPendingVerticalPosition);

  FVerticalPreviewTimer.Enabled := False;
  FVerticalPreviewTimer.Enabled := True;
end;

procedure TMainForm.VerticalTimeTrackBarMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;

  FDraggingVerticalSlider := True;
  FPendingVerticalPosition := VerticalTimeTrackBar.Position;
end;

procedure TMainForm.VerticalTimeTrackBarMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;

  if not FDraggingVerticalSlider then
    Exit;

  FDraggingVerticalSlider := False;
  FPendingVerticalPosition := VerticalTimeTrackBar.Position;
  FSelectedCommitTime := VerticalSliderToCommitTime(FPendingVerticalPosition);

  FVerticalPreviewTimer.Enabled := False;
  UpdateTimeCurrentLabel;
  SelectTimePosition(FPendingVerticalPosition);
end;

procedure TMainForm.VerticalTimeTrackBarKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if FLoadingTimeline or FDraggingVerticalSlider then
    Exit;

  FPendingVerticalPosition := VerticalTimeTrackBar.Position;
  FSelectedCommitTime := VerticalSliderToCommitTime(FPendingVerticalPosition);

  FVerticalPreviewTimer.Enabled := False;
  UpdateTimeCurrentLabel;
  SelectTimePosition(FPendingVerticalPosition);
end;

procedure TMainForm.TimeTrackBarMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;

  FDraggingVerticalSliderline := True;
  FPendingTimelinePosition := TimeTrackBar.Position;
end;

procedure TMainForm.TimeTrackBarMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CommitHash: string;
begin
  if Button <> mbLeft then
    Exit;

  if not FDraggingVerticalSliderline then
    Exit;

  FDraggingVerticalSliderline := False;
  FPendingTimelinePosition := TimeTrackBar.Position;

  CommitHash := ResolveSliderCommit(FPendingTimelinePosition);
  SelectCommitHash(CommitHash);
end;

procedure TMainForm.TimeTrackBarKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
  CommitHash: string;
begin
  if FLoadingTimeline or FDraggingVerticalSliderline then
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
