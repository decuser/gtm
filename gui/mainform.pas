unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs, LCLIntf, gtmcore;

type
  TMainForm = class(TForm)
    BranchEdit: TEdit;
    BranchLabel: TLabel;
    BrowseButton: TButton;
    LoadButton: TButton;
    PathLabel: TLabel;
    RepoEdit: TEdit;
    RepoLabel: TLabel;
    SnapshotLabel: TLabel;
    TimeEdit: TEdit;
    TimeLabel: TLabel;
    TreeList: TListBox;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    procedure BrowseButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LoadButtonClick(Sender: TObject);
    procedure TreeListDblClick(Sender: TObject);
  private
    FCommitHash: string;
    FCurrentPath: string;
    procedure LoadSnapshot;
    procedure LoadCurrentDirectory;
    procedure EnterDirectory(const EntryName: string);
    procedure GoParent;
    procedure OpenHistoricalFile(const EntryName: string);
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
  BranchEdit.Text := 'master';
  TimeEdit.Text := CurrentLocalTimeForGit;
  SnapshotLabel.Caption := 'Snapshot: not loaded';
  PathLabel.Caption := 'Path: /';
  FCommitHash := '';
  FCurrentPath := '';
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
    SnapshotLabel.Caption := 'Snapshot: ' + FCommitHash + '  @  ' +
      CommitTime(RepoEdit.Text, FCommitHash);
    LoadCurrentDirectory;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TMainForm.LoadCurrentDirectory;
var
  Entries: TStringList;
  I: Integer;
begin
  if FCommitHash = '' then
    Exit;

  Entries := TStringList.Create;
  try
    ListDirectoryEntries(
      RepoEdit.Text,
      FCommitHash,
      FCurrentPath,
      Entries
    );

    TreeList.Items.BeginUpdate;
    try
      TreeList.Items.Clear;

      if FCurrentPath <> '' then
        TreeList.Items.Add('../');

      for I := 0 to Entries.Count - 1 do
        TreeList.Items.Add(Entries[I]);
    finally
      TreeList.Items.EndUpdate;
    end;

    if FCurrentPath = '' then
      PathLabel.Caption := 'Path: /'
    else
      PathLabel.Caption := 'Path: /' + FCurrentPath;
  finally
    Entries.Free;
  end;
end;

function TMainForm.IsDirectoryEntry(const S: string): Boolean;
begin
  Result := (Length(S) > 0) and (S[Length(S)] = '/');
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

procedure TMainForm.TreeListDblClick(Sender: TObject);
var
  S: string;
begin
  if TreeList.ItemIndex < 0 then
    Exit;

  S := TreeList.Items[TreeList.ItemIndex];

  if S = '../' then
  begin
    GoParent;
    Exit;
  end;

  if IsDirectoryEntry(S) then
    EnterDirectory(S)
  else
    OpenHistoricalFile(S);
end;

end.
