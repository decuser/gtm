unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs, ComCtrls, LCLIntf,
  Graphics, gtmcore;

type
  TMainForm = class(TForm)
    BranchEdit: TEdit;
    BranchLabel: TLabel;
    CommitInfoLabel: TLabel;
    CompareLabel: TLabel;
    BrowseButton: TButton;
    LoadButton: TButton;
    NextButton: TButton;
    PathLabel: TLabel;
    PrevButton: TButton;
    RepoEdit: TEdit;
    RepoLabel: TLabel;
    SnapshotLabel: TLabel;
    TimeEdit: TEdit;
    TimeLabel: TLabel;
    TimeTrackBar: TTrackBar;
    TreeList: TListBox;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    procedure BrowseButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LoadButtonClick(Sender: TObject);
    procedure NextButtonClick(Sender: TObject);
    procedure PrevButtonClick(Sender: TObject);
    procedure TimeTrackBarChange(Sender: TObject);
    procedure TreeListDblClick(Sender: TObject);
    procedure TreeListDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
  private
    FCommitHash: string;
    FCurrentPath: string;
    FTimeline: TStringList;
    FEntryStates: TStringList;
    FDeletedEntries: TStringList;
    FPreviousCommitHash: string;
    FLoadingTimeline: Boolean;
    procedure LoadSnapshot;
    procedure LoadCurrentDirectory;
    procedure EnterDirectory(const EntryName: string);
    procedure GoParent;
    procedure OpenHistoricalFile(const EntryName: string);
    procedure BuildBranchTimeline;
    procedure EnsureCurrentPathExists;
    procedure SelectTimelineIndex(Index: Integer);
    procedure UpdateTimelineControls;
    function PredecessorCommit(const CommitHash: string): string;
    procedure BuildEntryStates(const FromCommit, ToCommit: string);
    function EntryNameFromObject(const S: string): string;
    function EntryHashFromObject(const S: string): string;
    function FindObjectByName(Objects: TStrings; const EntryName: string): string;
    function StripStatusDecoration(const S: string): string;
    function DisplayStatus(const S: string): string;
    function IsDeletedDisplay(const S: string): Boolean;
    function IsDirectoryEntry(const S: string): Boolean;
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
  FEntryStates := TStringList.Create;
  FDeletedEntries := TStringList.Create;
  FPreviousCommitHash := '';
  FLoadingTimeline := False;
  BranchEdit.Text := 'master';
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
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FDeletedEntries.Free;
  FEntryStates.Free;
  FTimeline.Free;
end;

procedure TMainForm.BrowseButtonClick(Sender: TObject);
begin
  if RepoEdit.Text <> '' then
    SelectDirectoryDialog1.FileName := RepoEdit.Text;

  if SelectDirectoryDialog1.Execute then
    RepoEdit.Text := SelectDirectoryDialog1.FileName;
end;

procedure TMainForm.LoadButtonClick(Sender: TObject);
begin
  LoadSnapshot;
end;

procedure TMainForm.LoadSnapshot;
var
  I: Integer;
begin
  if Trim(RepoEdit.Text) = '' then
  begin
    MessageDlg('Repository path is required.', mtError, [mbOK], 0);
    Exit;
  end;

  if Trim(BranchEdit.Text) = '' then
    BranchEdit.Text := 'master';

  if Trim(TimeEdit.Text) = '' then
    TimeEdit.Text := CurrentLocalTimeForGit;

  Screen.Cursor := crHourGlass;
  try
    FCommitHash := ResolveCommit(
      RepoEdit.Text,
      BranchEdit.Text,
      TimeEdit.Text
    );

    FCurrentPath := '';
    FPreviousCommitHash := '';
    BuildBranchTimeline;

    I := FTimeline.IndexOf(FCommitHash);
    if I >= 0 then
    begin
      FCommitHash := '';
      SelectTimelineIndex(I);
    end
    else
    begin
      SnapshotLabel.Caption := 'Snapshot: ' + FCommitHash + '  @  ' +
        CommitTime(RepoEdit.Text, FCommitHash);
      LoadCurrentDirectory;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TMainForm.BuildBranchTimeline;
begin
  BuildTimeline(RepoEdit.Text, BranchEdit.Text, FTimeline);

  FLoadingTimeline := True;
  try
    if FTimeline.Count > 0 then
    begin
      TimeTrackBar.Min := 0;
      TimeTrackBar.Max := FTimeline.Count - 1;
      TimeTrackBar.Enabled := True;
    end
    else
    begin
      TimeTrackBar.Min := 0;
      TimeTrackBar.Max := 0;
      TimeTrackBar.Enabled := False;
    end;
  finally
    FLoadingTimeline := False;
  end;
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

  FLoadingTimeline := True;
  try
    TimeTrackBar.Position := Index;
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
  else if FTimeline.IndexOf(FPreviousCommitHash) < FTimeline.IndexOf(FCommitHash) then
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

procedure TMainForm.UpdateTimelineControls;
begin
  PrevButton.Enabled := TimeTrackBar.Enabled and (TimeTrackBar.Position > TimeTrackBar.Min);
  NextButton.Enabled := TimeTrackBar.Enabled and (TimeTrackBar.Position < TimeTrackBar.Max);
end;

procedure TMainForm.PrevButtonClick(Sender: TObject);
begin
  SelectTimelineIndex(TimeTrackBar.Position - 1);
end;

procedure TMainForm.NextButtonClick(Sender: TObject);
begin
  SelectTimelineIndex(TimeTrackBar.Position + 1);
end;

procedure TMainForm.TimeTrackBarChange(Sender: TObject);
begin
  if FLoadingTimeline then
    Exit;

  SelectTimelineIndex(TimeTrackBar.Position);
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
    Result := Trim(FTimeline[I - 1]);
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
  BuildEntryStates(PredecessorCommit(FCommitHash), FCommitHash);
  LoadCurrentDirectory;
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

  BuildEntryStates(PredecessorCommit(FCommitHash), FCommitHash);
  LoadCurrentDirectory;
end;

procedure TMainForm.OpenHistoricalFile(const EntryName: string);
var
  RepoPath, TempRoot, TempDir, TempFile: string;
begin
  if EntryName = '' then
    Exit;

  RepoPath := JoinRepoPath(FCurrentPath, EntryName);

  TempRoot := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'git-time-machine';
  if not ForceDirectories(TempRoot) then
  begin
    MessageDlg('Unable to create temporary directory.', mtError, [mbOK], 0);
    Exit;
  end;

  TempDir := IncludeTrailingPathDelimiter(TempRoot) +
    Copy(FCommitHash, 1, 12);
  if not ForceDirectories(TempDir) then
  begin
    MessageDlg('Unable to create snapshot temporary directory.', mtError, [mbOK], 0);
    Exit;
  end;

  TempFile := IncludeTrailingPathDelimiter(TempDir) + EntryName;

  ExtractFile(RepoEdit.Text, FCommitHash, RepoPath, TempFile);

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
    OpenHistoricalFile(StripStatusDecoration(S));
end;

end.
