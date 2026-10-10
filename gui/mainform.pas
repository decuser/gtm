unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, Forms, Controls, StdCtrls, Buttons, Dialogs, ComCtrls, LCLIntf,
  LCLType,
  Graphics, Menus, ExtCtrls, gtmcore, gtmmount, gtmexec, gtmstate;

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
    MainMenu: TMainMenu;
    FileMenu: TMenuItem;
    OpenRepositoryMenuItem: TMenuItem;
    QuitMenuItem: TMenuItem;
    NavigateMenu: TMenuItem;
    FirstCommitMenuItem: TMenuItem;
    PreviousCommitMenuItem: TMenuItem;
    NextCommitMenuItem: TMenuItem;
    LastCommitMenuItem: TMenuItem;
    SelectTagMenuItem: TMenuItem;
    SnapshotMenu: TMenuItem;
    MountSnapshotMenuItem: TMenuItem;
    MountedSnapshotsMenuItem: TMenuItem;
    SnapshotSeparatorMenuItem: TMenuItem;
    UnmountAllMenuItem: TMenuItem;
    HelpMenu: TMenuItem;
    AboutMenuItem: TMenuItem;
    NextButton: TButton;
    PathLabel: TLabel;
    FirstButton: TButton;
    PrevButton: TButton;
    LastButton: TButton;
    RepoEdit: TEdit;
    RepoLabel: TLabel;
    SnapshotLabel: TLabel;
    SnapshotMountButton: TSpeedButton;
    SnapshotUnmountButton: TSpeedButton;
    SnapshotMountsButton: TSpeedButton;
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
    procedure OpenRepositoryMenuItemClick(Sender: TObject);
    procedure QuitMenuItemClick(Sender: TObject);
    procedure FirstCommitMenuItemClick(Sender: TObject);
    procedure PreviousCommitMenuItemClick(Sender: TObject);
    procedure NextCommitMenuItemClick(Sender: TObject);
    procedure LastCommitMenuItemClick(Sender: TObject);
    procedure SelectTagMenuItemClick(Sender: TObject);
    procedure MountSnapshotMenuItemClick(Sender: TObject);
    procedure MountedSnapshotsMenuItemClick(Sender: TObject);
    procedure UnmountAllMenuItemClick(Sender: TObject);
    procedure SnapshotMountButtonClick(Sender: TObject);
    procedure SnapshotUnmountButtonClick(Sender: TObject);
    procedure SnapshotMountsButtonClick(Sender: TObject);
    procedure AboutMenuItemClick(Sender: TObject);
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
    procedure TreeListKeyDown(Sender: TObject; var Key: Word;
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
    FState: TGTMState;
    FLoadingTimeline: Boolean;
    FLoadingBranches: Boolean;
    FTagChooser: TForm;
    FTagChooserList: TListBox;
    FNavTimer: TTimer;
    FNavDirection: Integer;
    FNavHoldTicks: Integer;
    FNavRepeated: Boolean;
    FNavKey: Word;
    FDraggingTimeline: Boolean;
    FPendingTimelinePosition: Integer;
    FDraggingVerticalSlider: Boolean;
    FPendingVerticalPosition: Integer;
    FVerticalPreviewTimer: TTimer;
    FHistoryList: TListBox;
    FHistoryPath: string;
    FHistorySelectionUpdating: Boolean;
    FMounts: TGTMMountManager;
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
    procedure MountCurrentSnapshot;
    procedure UpdateSnapshotMountToggle;
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

{$I gtmversion.inc}

{$R *.lfm}






procedure TMainForm.RefreshMountList;
var
  I: Integer;
begin
  if FMountList = nil then
    Exit;

  FMountList.Items.Clear;
  for I := 0 to FMounts.Count - 1 do
    FMountList.Items.Add(
      Copy(FMounts.Commits[I], 1, 8) + '   ' + FMounts.MountPoints[I]
    );

  if FMountList.Items.Count > 0 then
    FMountList.ItemIndex := 0;
end;


procedure TMainForm.UpdateSnapshotMountToggle;
var
  HasSnapshot, Mounted: Boolean;
begin
  HasSnapshot :=
    (Trim(RepoEdit.Text) <> '') and (Trim(FState.CommitHash) <> '');

  Mounted :=
    (FMounts <> nil) and
    HasSnapshot and
    FMounts.IsMounted(RepoEdit.Text, FState.CommitHash);

  SnapshotMountButton.Enabled := HasSnapshot and (not Mounted);
  SnapshotUnmountButton.Enabled := HasSnapshot and Mounted;
  SnapshotMountsButton.Enabled := (FMounts <> nil) and (FMounts.Count > 0);
end;


procedure TMainForm.SnapshotMountButtonClick(Sender: TObject);
begin
  if (Trim(RepoEdit.Text) = '') or (Trim(FState.CommitHash) = '') then
    Exit;

  if not FMounts.IsMounted(RepoEdit.Text, FState.CommitHash) then
    MountCurrentSnapshot;
end;


procedure TMainForm.SnapshotUnmountButtonClick(Sender: TObject);
var
  ErrorMessage: string;
begin
  if (Trim(RepoEdit.Text) = '') or (Trim(FState.CommitHash) = '') then
    Exit;

  if not FMounts.UnmountSnapshot(
    RepoEdit.Text,
    FState.CommitHash,
    ErrorMessage
  ) then
  begin
    if ErrorMessage <> '' then
      ShowMessage(ErrorMessage);
    Exit;
  end;

  RefreshMountList;
  UpdateSnapshotMountToggle;
end;

procedure TMainForm.SnapshotMountsButtonClick(Sender: TObject);
begin
  MountedSnapshotsMenuItemClick(Sender);
end;


procedure TMainForm.MountCurrentSnapshot;
var
  MountPoint, ErrorMessage: string;
begin
  if (Trim(RepoEdit.Text) = '') or (Trim(FState.CommitHash) = '') then
  begin
    ShowMessage('No snapshot is selected.');
    Exit;
  end;

  if not FMounts.MountSnapshot(
    RepoEdit.Text,
    FState.CommitHash,
    MountPoint,
    ErrorMessage
  ) then
  begin
    ShowMessage(ErrorMessage);
    Exit;
  end;

  UpdateSnapshotMountToggle;

  { The mount is still valid even if no desktop file browser is available. }
  OpenPath(MountPoint, ErrorMessage);
end;


procedure TMainForm.MountSnapshotMenuItemClick(Sender: TObject);
begin
  MountCurrentSnapshot;
end;

procedure TMainForm.MountOpenClick(Sender: TObject);
var
  ErrorMessage: string;
begin
  if (FMountList = nil) or
     (FMountList.ItemIndex < 0) or
     (FMountList.ItemIndex >= FMounts.Count) then
    Exit;

  if not OpenPath(
    FMounts.MountPoints[FMountList.ItemIndex],
    ErrorMessage
  ) then
    ShowMessage('Could not open mounted snapshot:' +
      LineEnding + ErrorMessage);
end;


procedure TMainForm.MountUnmountClick(Sender: TObject);
var
  ErrorMessage: string;
begin
  if FMountList = nil then
    Exit;

  if not FMounts.Unmount(FMountList.ItemIndex, ErrorMessage) then
  begin
    if ErrorMessage <> '' then
      ShowMessage(ErrorMessage);
    Exit;
  end;

  RefreshMountList;
  UpdateSnapshotMountToggle;
end;

procedure TMainForm.MountUnmountAllClick(Sender: TObject);
begin
  FMounts.UnmountAll;
  RefreshMountList;
  UpdateSnapshotMountToggle;
end;

procedure TMainForm.MountVisualDiffClick(Sender: TObject);
var
  I, FirstIndex, SecondIndex, SelectedCount: Integer;
  ErrorMessage: string;
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

  if not VisualDiff(
    FMounts.MountPoints[FirstIndex],
    FMounts.MountPoints[SecondIndex],
    ErrorMessage
  ) then
    ShowMessage('Could not launch visual diff:' +
      LineEnding + ErrorMessage);
end;


procedure TMainForm.MountedSnapshotsMenuItemClick(Sender: TObject);
var
  Dialog: TForm;
  ButtonPanel: TPanel;
  CloseButton: TButton;
  MountPopup: TPopupMenu;
  OpenItem, VisualDiffItem, SeparatorItem, UnmountItem,
    UnmountAllItem: TMenuItem;
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

    CloseButton := TButton.Create(ButtonPanel);
    CloseButton.Parent := ButtonPanel;
    CloseButton.Caption := 'Close';
    CloseButton.Left := 614;
    CloseButton.Top := 10;
    CloseButton.Width := 90;
    CloseButton.ModalResult := mrClose;

    MountPopup := TPopupMenu.Create(Dialog);

    OpenItem := TMenuItem.Create(MountPopup);
    OpenItem.Caption := 'Open';
    OpenItem.OnClick := @MountOpenClick;
    MountPopup.Items.Add(OpenItem);

    VisualDiffItem := TMenuItem.Create(MountPopup);
    VisualDiffItem.Caption := 'Visual Diff';
    VisualDiffItem.OnClick := @MountVisualDiffClick;
    MountPopup.Items.Add(VisualDiffItem);

    SeparatorItem := TMenuItem.Create(MountPopup);
    SeparatorItem.Caption := '-';
    MountPopup.Items.Add(SeparatorItem);

    UnmountItem := TMenuItem.Create(MountPopup);
    UnmountItem.Caption := 'Unmount';
    UnmountItem.OnClick := @MountUnmountClick;
    MountPopup.Items.Add(UnmountItem);

    UnmountAllItem := TMenuItem.Create(MountPopup);
    UnmountAllItem.Caption := 'Unmount All';
    UnmountAllItem.OnClick := @MountUnmountAllClick;
    MountPopup.Items.Add(UnmountAllItem);

    FMountList := TListBox.Create(Dialog);
    FMountList.Parent := Dialog;
    FMountList.Align := alClient;
    FMountList.MultiSelect := True;
    FMountList.PopupMenu := MountPopup;
    FMountList.OnDblClick := @MountOpenClick;

    RefreshMountList;
    Dialog.ShowModal;
  finally
    FMountList := nil;
    Dialog.Free;
  end;
end;


procedure TMainForm.UnmountAllMenuItemClick(Sender: TObject);
begin
  FMounts.UnmountAll;
  RefreshMountList;
  UpdateSnapshotMountToggle;
end;


procedure TMainForm.FormCreate(Sender: TObject);
begin
  InitGTMState(FState);
  FLoadingTimeline := False;
  FLoadingBranches := False;
  FNavDirection := 0;
  FNavHoldTicks := 0;
  FNavRepeated := False;
  FNavKey := 0;
  FDraggingTimeline := False;
  FPendingTimelinePosition := 0;
  FDraggingVerticalSlider := False;
  FPendingVerticalPosition := 0;
  FHistoryList := nil;
  FHistoryPath := '';
  FHistorySelectionUpdating := False;
  FMounts := TGTMMountManager.Create;
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
  UpdateSnapshotMountToggle;
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
  DoneGTMState(FState);
  FMounts.UnmountAll;
  FMounts.Free;
end;

procedure TMainForm.OpenRepositoryMenuItemClick(Sender: TObject);
begin
  BrowseButtonClick(Sender);
end;

procedure TMainForm.QuitMenuItemClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.FirstCommitMenuItemClick(Sender: TObject);
begin
  FirstButtonClick(Sender);
end;

procedure TMainForm.PreviousCommitMenuItemClick(Sender: TObject);
begin
  PrevButtonClick(Sender);
end;

procedure TMainForm.NextCommitMenuItemClick(Sender: TObject);
begin
  NextButtonClick(Sender);
end;

procedure TMainForm.LastCommitMenuItemClick(Sender: TObject);
begin
  LastButtonClick(Sender);
end;

procedure TMainForm.SelectTagMenuItemClick(Sender: TObject);
begin
  TagButtonClick(Sender);
end;

procedure TMainForm.AboutMenuItemClick(Sender: TObject);
begin
  MessageDlg(
    'Git Time Machine' + LineEnding +
    'Version ' + GTMVersion + LineEnding + LineEnding +
    'Browse Git history as filesystem snapshots.',
    mtInformation, [mbOK], 0
  );
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
  FState.BranchIndex.Clear;
  if FLoadingBranches then
    Exit;

  if (FState.CommitHash <> '') and (Trim(BranchEdit.Text) <> '') then
    SwitchBranch;
end;

procedure TMainForm.PopulateBranches;
var
  Branches: TStringList;
  Wanted: string;
  I: Integer;
begin
  SetRepository(FState, Trim(RepoEdit.Text));
  FState.BranchIndex.Clear;
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
begin
  TagEdit.Text := '(none)';
  FState.TagCommits.Clear;
  FState.TagNames.Clear;

  if Trim(RepoEdit.Text) = '' then
    Exit;

  SetRepository(FState, Trim(RepoEdit.Text));
  PopulateStateTags(FState, BranchEdit.Items);
end;

procedure TMainForm.UpdateTagSelection;
var
  I: Integer;
begin
  TagEdit.Text := '(none)';
  if FState.CommitHash = '' then
    Exit;

  I := StateTagIndexForCommit(FState, FState.CommitHash);
  if I > 0 then
    TagEdit.Text := FState.TagNames[I];
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
    List.Items.Assign(FState.TagNames);
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
    if (SelectedIndex <= 0) or (SelectedIndex >= FState.TagCommits.Count) then
      Exit;

    TargetCommit := FState.TagCommits[SelectedIndex];

    FoundBranch := SelectStateBranchForCommit(
      FState, BranchEdit.Items, TargetCommit, BranchIndex
    );

    if FoundBranch and (BranchIndex >= 0) then
    begin
      FLoadingBranches := True;
      try
        BranchEdit.ItemIndex := BranchIndex;
      finally
        FLoadingBranches := False;
      end;
    end;

    { PopulateTags filters unreachable tags.  This guard only handles the
      repository changing after the chooser was populated. }
    if not FoundBranch then
    begin
      PopulateTags;
      Exit;
    end;

      BuildBranchTimeline(TargetCommit);
    FState.CommitHash := '';
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

  SetRepository(FState, Trim(RepoEdit.Text));

  Screen.Cursor := crHourGlass;
  try
    if not SelectStateBranch(FState, Trim(BranchEdit.Text), TargetCommit) then
      Exit;

    BuildBranchTimeline(TargetCommit);
    FState.CommitHash := '';
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

  SetRepository(FState, Trim(RepoEdit.Text));
  SetBranch(FState, Trim(BranchEdit.Text));

  Screen.Cursor := crHourGlass;
  try
    TargetCommit := ResolveCommit(
      RepoEdit.Text,
      BranchEdit.Text,
      TimeEdit.Text
    );

    FState.CurrentPath := '';
      BuildBranchTimeline(TargetCommit);
    PopulateTags;

    I := FState.Timeline.IndexOf(TargetCommit);
    if I >= 0 then
    begin
      FState.CommitHash := '';
      SelectTimelineIndex(I);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TMainForm.BuildBranchIndex;
begin
  FState.BranchIndex.Clear;
  if Trim(RepoEdit.Text) = '' then
    Exit;
  if Trim(BranchEdit.Text) = '' then
    Exit;

  SetRepository(FState, Trim(RepoEdit.Text));
  SetBranch(FState, Trim(BranchEdit.Text));
  BuildStateBranchIndex(FState);
end;

procedure TMainForm.BuildBranchTimeline(const CenterCommit: string);
begin
  BuildStateTimeline(FState, CenterCommit);
  if FState.BranchIndex.Count = 0 then
    Exit;

  UpdateTimeRailLabels;

  FLoadingTimeline := True;
  try
    TimeTrackBar.Min := 0;
    TimeTrackBar.Max := FState.BranchCommitCount - 1;
    TimeTrackBar.Position := FState.CurrentBranchPosition;
    TimeTrackBar.Enabled := FState.BranchCommitCount > 0;

    VerticalTimeTrackBar.Min := 0;
    VerticalTimeTrackBar.Max := 1000;
    VerticalTimeTrackBar.Position := CurrentCommitToVerticalSlider;
    VerticalTimeTrackBar.Enabled :=
      FState.NewestCommitTime > FState.OldestCommitTime;
  finally
    FLoadingTimeline := False;
  end;

  UpdateForkInfo;
  UpdateTimelineLabels;
end;

procedure TMainForm.EnsureCurrentPathExists;
begin
  EnsureStateCurrentPath(FState);
end;


function TMainForm.CurrentCommitToVerticalSlider: Integer;
begin
  { The vertical rail is proportional to commit position, not elapsed time.
    Oldest commit is at the bottom; newest commit is at the top. }
  if FState.BranchCommitCount <= 1 then
    Exit(0);

  Result := 1000 - Round(
    (FState.CurrentBranchPosition * 1000.0) /
    (FState.BranchCommitCount - 1)
  );
end;

function TMainForm.VerticalSliderToCommitTime(SliderPos: Integer): Int64;
var
  BranchPos: Integer;
begin
  Result := 0;

  if Trim(RepoEdit.Text) = '' then
    Exit;
  if FState.BranchIndex.Count = 0 then
    Exit;

  if SliderPos < 0 then
    SliderPos := 0;
  if SliderPos > 1000 then
    SliderPos := 1000;

  if FState.BranchIndex.Count = 1 then
    BranchPos := 0
  else
    BranchPos := Round(
      ((1000 - SliderPos) * (FState.BranchIndex.Count - 1)) / 1000.0
    );

  if BranchPos < 0 then
    BranchPos := 0;
  if BranchPos >= FState.BranchIndex.Count then
    BranchPos := FState.BranchIndex.Count - 1;

  Result := CommitUnixTime(
    RepoEdit.Text,
    FState.BranchIndex[BranchPos]
  );
end;

procedure TMainForm.SelectTimePosition(SliderPos: Integer);
var
  BranchPos: Integer;
  CommitHash: string;
begin
  if not VerticalTimeTrackBar.Enabled then
    Exit;

  if FState.BranchIndex.Count = 0 then
    Exit;

  if SliderPos < 0 then
    SliderPos := 0;
  if SliderPos > 1000 then
    SliderPos := 1000;

  if FState.BranchIndex.Count = 1 then
    BranchPos := 0
  else
    BranchPos := Round(
      ((1000 - SliderPos) * (FState.BranchIndex.Count - 1)) / 1000.0
    );

  if BranchPos < 0 then
    BranchPos := 0;
  if BranchPos >= FState.BranchIndex.Count then
    BranchPos := FState.BranchIndex.Count - 1;

  CommitHash := FState.BranchIndex[BranchPos];
  SelectCommitHash(CommitHash);
end;

procedure TMainForm.UpdateVerticalTimeSlider;
var
  SliderPos: Integer;
begin
  if FState.BranchCommitCount <= 0 then
    Exit;

  if FState.BranchCommitCount = 1 then
    SliderPos := 0
  else
    SliderPos := 1000 - Round(
      (FState.CurrentBranchPosition * 1000.0) /
      (FState.BranchCommitCount - 1)
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
  if FState.NewestCommitTime > 0 then
    TimeNowLabel.Caption :=
      FormatDateTime('yyyy-mm-dd hh:nn',
        UnixToDateTime(FState.NewestCommitTime, False))
  else
    TimeNowLabel.Caption := '';

  if FState.OldestCommitTime > 0 then
    TimeStartLabel.Caption :=
      FormatDateTime('yyyy-mm-dd hh:nn',
        UnixToDateTime(FState.OldestCommitTime, False))
  else
    TimeStartLabel.Caption := '';

  UpdateTimeCurrentLabel;
end;

procedure TMainForm.UpdateTimeCurrentLabel;
var
  P, RailTop, RailBottom, Y: Integer;
begin
  if (FState.SelectedCommitTime <= 0) or
     (FState.NewestCommitTime <= FState.OldestCommitTime) then
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
      UnixToDateTime(FState.SelectedCommitTime, False));

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

  if FState.BranchIndex.Count = 0 then
    Exit;

  if SliderPos < 0 then
    SliderPos := 0;
  if SliderPos >= FState.BranchIndex.Count then
    SliderPos := FState.BranchIndex.Count - 1;

  Result := Trim(FState.BranchIndex[SliderPos]);
end;

procedure TMainForm.SelectCommitHash(const CommitHash: string);
var
  I: Integer;
  FullHash: string;
begin
  if CommitHash = '' then
    Exit;

  FullHash := ResolveCommitAbbreviation(FState.BranchIndex, CommitHash);

  if FState.Timeline.IndexOf(FullHash) < 0 then
    BuildBranchTimeline(FullHash);

  I := FState.Timeline.IndexOf(FullHash);
  if I >= 0 then
  begin
    SelectTimelineIndex(I);

    { Direct commit navigation defines the selected time as the commit time.
      This keeps the horizontal commit slider, vertical time slider, and
      snapshot synchronized.  Time-driven navigation restores its requested
      time after this call. }
    FState.SelectedCommitTime := CommitUnixTime(RepoEdit.Text, FState.CommitHash);
    UpdateVerticalTimeSlider;
  end;
end;

procedure TMainForm.SelectTimelineIndex(Index: Integer);
begin
  if not SelectStateTimelineIndex(FState, Index) then
    Exit;

  FLoadingTimeline := True;
  try
    TimeTrackBar.Position := FState.CurrentBranchPosition;
  finally
    FLoadingTimeline := False;
  end;

  TimeEdit.Text := CommitTime(RepoEdit.Text, FState.CommitHash);
  SnapshotLabel.Caption := 'Snapshot: ' + FState.CommitHash + '  @  ' +
    TimeEdit.Text;
  CommitInfoLabel.Caption := 'Commit: ' + Copy(FState.CommitHash, 1, 8) +
    '  ' + TimeEdit.Text + '  ' + CommitSubject(RepoEdit.Text, FState.CommitHash);

  if FState.PreviousCommitHash = '' then
    CompareLabel.Caption := 'Compare: —'
  else if CommitTime(RepoEdit.Text, FState.PreviousCommitHash) <
          CommitTime(RepoEdit.Text, FState.CommitHash) then
    CompareLabel.Caption := 'Compare: ' + Copy(FState.PreviousCommitHash, 1, 8) +
      '  ->  ' + Copy(FState.CommitHash, 1, 8)
  else
    CompareLabel.Caption := 'Compare: ' + Copy(FState.CommitHash, 1, 8) +
      '  <-  ' + Copy(FState.PreviousCommitHash, 1, 8);

  EnsureCurrentPathExists;
  BuildEntryStates(PredecessorCommit(FState.CommitHash), FState.CommitHash);
  LoadCurrentDirectory;
  UpdateTimelineControls;
  UpdateTagSelection;
  UpdateSnapshotMountToggle;
end;

procedure TMainForm.UpdateForkInfo;
begin
  UpdateStateForkInfo(FState, BranchEdit.Items);
end;


procedure TMainForm.UpdateTimelineLabels;
var
  CurrentIndex, PixelRange, ForkX, MergeX: Integer;
  WindowStartPos, WindowEndPos: Integer;
begin
  ForkLabel.Caption := '';
  ForkMarkerLabel.Caption := '';
  MergeMarkerLabel.Caption := '';

  if FState.Timeline.Count = 0 then
  begin
    ScaleLabel.Caption := '';
    Exit;
  end;

  CurrentIndex := FState.Timeline.IndexOf(FState.CommitHash);
  if CurrentIndex < 0 then
    CurrentIndex := 0;

  WindowStartPos := FState.CurrentBranchPosition - CurrentIndex;
  WindowEndPos := WindowStartPos + FState.Timeline.Count - 1;

  ScaleLabel.Caption :=
    'Cached commits ' + IntToStr(WindowStartPos + 1) + '-' +
    IntToStr(WindowEndPos + 1) + ' of ' +
    IntToStr(FState.BranchCommitCount);

  if FState.ForkHash <> '' then
  begin
    if FState.MergeHash <> '' then
      ScaleLabel.Caption := ScaleLabel.Caption +
        ' · fork ' + Copy(FState.ForkHash, 1, 8) +
        ' -> merge ' + Copy(FState.MergeHash, 1, 8) +
        ' -> continues'
    else
      ScaleLabel.Caption := ScaleLabel.Caption +
        ' · fork ' + Copy(FState.ForkHash, 1, 8) +
        ' · unmerged';
  end;

  if FState.BranchCommitCount > 1 then
  begin
    PixelRange := TimeTrackBar.Width;

    { Fork and merge annotations live below the slider. }
    if FState.ForkIndex >= 0 then
    begin
      ForkX := TimeTrackBar.Left +
        Round(FState.ForkIndex * PixelRange / (FState.BranchCommitCount - 1));
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

    if FState.MergeIndex >= 0 then
    begin
      MergeX := TimeTrackBar.Left +
        Round(FState.MergeIndex * PixelRange / (FState.BranchCommitCount - 1));
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
  PrevButton.Enabled := FState.CurrentBranchPosition > 0;
  NextButton.Enabled := FState.CurrentBranchPosition < FState.BranchCommitCount - 1;
  FirstButton.Enabled := FState.CurrentBranchPosition > 0;
  LastButton.Enabled := FState.CurrentBranchPosition < FState.BranchCommitCount - 1;

  UpdateTimelineLabels;
end;

procedure TMainForm.StepNavigation(Delta: Integer);
var
  TargetPos: Integer;
  CommitHash: string;
begin
  if FState.BranchCommitCount <= 0 then
    Exit;

  TargetPos := FState.CurrentBranchPosition + Delta;

  if TargetPos < 0 then
    TargetPos := 0;
  if TargetPos >= FState.BranchCommitCount then
    TargetPos := FState.BranchCommitCount - 1;

  if TargetPos = FState.CurrentBranchPosition then
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
  { GTM navigation is Ctrl-only at form level.
    Plain navigation keys are left to the browser/control that owns focus. }
  if not (ssCtrl in Shift) then
    Exit;

  { Ctrl-Home / Ctrl-End select first / last commit. }
  if Key = VK_HOME then
  begin
    FNavTimer.Enabled := False;
    FNavDirection := 0;
    FNavHoldTicks := 0;
    FNavRepeated := False;
    FNavKey := 0;
    if FState.BranchIndex.Count > 0 then
      SelectCommitHash(FState.BranchIndex[0]);
    Key := 0;
    Exit;
  end;

  if Key = VK_END then
  begin
    FNavTimer.Enabled := False;
    FNavDirection := 0;
    FNavHoldTicks := 0;
    FNavRepeated := False;
    FNavKey := 0;
    if FState.BranchIndex.Count > 0 then
      SelectCommitHash(FState.BranchIndex[FState.BranchIndex.Count - 1]);
    Key := 0;
    Exit;
  end;

  { Ctrl-PageUp = latest/newest time; Ctrl-PageDown = earliest/oldest. }
  if Key = VK_PRIOR then
  begin
    FNavTimer.Enabled := False;
    FNavDirection := 0;
    FNavHoldTicks := 0;
    FNavRepeated := False;
    FNavKey := 0;
    if FState.BranchIndex.Count > 0 then
      SelectCommitHash(FState.BranchIndex[FState.BranchIndex.Count - 1]);
    Key := 0;
    Exit;
  end;

  if Key = VK_NEXT then
  begin
    FNavTimer.Enabled := False;
    FNavDirection := 0;
    FNavHoldTicks := 0;
    FNavRepeated := False;
    FNavKey := 0;
    if FState.BranchIndex.Count > 0 then
      SelectCommitHash(FState.BranchIndex[0]);
    Key := 0;
    Exit;
  end;

  Direction := 0;

  { Horizontal slider: older/newer. }
  if Key = VK_LEFT then
    Direction := -1
  else if Key = VK_RIGHT then
    Direction := 1

  { Vertical slider follows the visual time axis. }
  else if Key = VK_UP then
    Direction := -1
  else if Key = VK_DOWN then
    Direction := 1
  else
    Exit;

  { Ignore OS key-repeat events; our timer provides the same acceleration
    used by the TUI: 1, 2, 5, then 10 commits per step. }
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
  if (FNavKey = 0) or (Key <> FNavKey) then
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
  if FState.BranchIndex.Count > 0 then
    SelectCommitHash(FState.BranchIndex[0]);
end;

procedure TMainForm.LastButtonClick(Sender: TObject);
begin
  if FState.BranchIndex.Count > 0 then
    SelectCommitHash(FState.BranchIndex[FState.BranchIndex.Count - 1]);
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
  FState.SelectedCommitTime := VerticalSliderToCommitTime(FPendingVerticalPosition);

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
  FState.SelectedCommitTime := VerticalSliderToCommitTime(FPendingVerticalPosition);

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
  FState.SelectedCommitTime := VerticalSliderToCommitTime(FPendingVerticalPosition);

  FVerticalPreviewTimer.Enabled := False;
  UpdateTimeCurrentLabel;
  SelectTimePosition(FPendingVerticalPosition);
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




function TMainForm.PredecessorCommit(const CommitHash: string): string;
var
  I: Integer;
begin
  Result := '';
  if (CommitHash = '') or (FState.Timeline = nil) then
    Exit;

  I := FState.Timeline.IndexOf(CommitHash);
  if I > 0 then
    Result := Trim(FState.Timeline[I - 1])
  else if I = 0 then
    Result := FState.WindowPredecessor;
end;

procedure TMainForm.BuildEntryStates(const FromCommit, ToCommit: string);
begin
  BuildStateEntryStates(FState, FromCommit, ToCommit);
end;


procedure TMainForm.RefreshCurrentDirectory;
begin
  BuildEntryStates(PredecessorCommit(FState.CommitHash), FState.CommitHash);
  LoadCurrentDirectory;
  TreeList.Invalidate;
end;

procedure TMainForm.LoadCurrentDirectory;
var
  DisplayEntries: TStringList;
  I: Integer;
begin
  if FState.CommitHash = '' then
    Exit;

  DisplayEntries := TStringList.Create;
  try
    BuildStateDirectoryDisplay(FState, DisplayEntries);

    TreeList.Items.BeginUpdate;
    try
      TreeList.Items.Clear;
      if FState.CurrentPath <> '' then
        TreeList.Items.Add('../');
      for I := 0 to DisplayEntries.Count - 1 do
        TreeList.Items.Add(DisplayEntries[I]);
    finally
      TreeList.Items.EndUpdate;
    end;

    if FState.CurrentPath = '' then
      PathLabel.Caption := 'Path: /'
    else
      PathLabel.Caption := 'Path: /' + FState.CurrentPath;
  finally
    DisplayEntries.Free;
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

  if FState.CurrentPath = '' then
    Result := EntryText
  else
    Result := FState.CurrentPath + '/' + EntryText;
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

  FState.CurrentPath := JoinRepoPath(FState.CurrentPath, DirName);
  RefreshCurrentDirectory;
end;

procedure TMainForm.GoParent;
var
  P: Integer;
begin
  if FState.CurrentPath = '' then
    Exit;

  P := LastDelimiter('/', FState.CurrentPath);
  if P = 0 then
    FState.CurrentPath := ''
  else
    FState.CurrentPath := Copy(FState.CurrentPath, 1, P - 1);

  RefreshCurrentDirectory;
end;

procedure TMainForm.OpenHistoricalFile(const EntryName: string);
var
  TempFile: string;
begin
  if EntryName = '' then
    Exit;

  MaterializeTempFile(FState.CommitHash, EntryName, TempFile);

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
    ExtractFile(RepoEdit.Text, FState.CommitHash, PathName, SaveDialog.FileName);
end;

procedure TMainForm.VisualDiffMenuItemClick(Sender: TObject);
var
  PathName, PrevCommit, OldFile, NewFile, ErrorMessage: string;
begin
  PathName := SelectedHistoricalPath;
  if PathName = '' then
    Exit;

  PrevCommit := PredecessorCommit(FState.CommitHash);
  if PrevCommit = '' then
    Exit;

  MaterializeTempFile(PrevCommit, PathName, OldFile);
  MaterializeTempFile(FState.CommitHash, PathName, NewFile);

  if not VisualDiff(OldFile, NewFile, ErrorMessage) then
    MessageDlg('Unable to launch visual diff: ' + ErrorMessage,
      mtError, [mbOK], 0);
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
  I, Sel1, Sel2, TempIndex: Integer;
  Hash1, Hash2, OldFile, NewFile, ErrorMessage: string;

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

    for J := 0 to FState.BranchIndex.Count - 1 do
      if Pos(LowerCase(ShortHash), LowerCase(FState.BranchIndex[J])) = 1 then
      begin
        Result := FState.BranchIndex[J];
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

  if not VisualDiff(OldFile, NewFile, ErrorMessage) then
    MessageDlg('Unable to launch visual diff: ' + ErrorMessage,
      mtError, [mbOK], 0);
end;

procedure TMainForm.TreeListKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  { Ctrl-navigation belongs to the GTM sliders and is handled by the form. }
  if ssCtrl in Shift then
    Exit;

  case Key of
    VK_LEFT, VK_BACK:
      begin
        GoParent;
        Key := 0;
      end;

    VK_RIGHT, VK_RETURN:
      begin
        TreeListDblClick(TreeList);
        Key := 0;
      end;

    { Up/Down/Home/End are the list box's native browser navigation. }
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
