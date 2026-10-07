unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs, gtmcore;

type
  TMainForm = class(TForm)
    BranchEdit: TEdit;
    BranchLabel: TLabel;
    BrowseButton: TButton;
    LoadButton: TButton;
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
  private
    procedure LoadSnapshot;
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
  CommitHash: string;
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
    CommitHash := ResolveCommit(
      RepoEdit.Text,
      BranchEdit.Text,
      TimeEdit.Text
    );

    ListDirectoryEntries(
      RepoEdit.Text,
      CommitHash,
      '/',
      TreeList.Items
    );

    SnapshotLabel.Caption := 'Snapshot: ' + CommitHash;
  finally
    Screen.Cursor := crDefault;
  end;
end;

end.
