unit gtmmount;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

type
  TGTMMountManager = class
  private
    FCommits: TStringList;
    FMountPoints: TStringList;
    function GetCount: Integer;
    function GetCommit(Index: Integer): string;
    function GetMountPoint(Index: Integer): string;
    function HelperPath: string;
    function SnapshotMountPoint(const Repo, CommitHash: string): string;
  public
    constructor Create;
    destructor Destroy; override;

    function MountSnapshot(const Repo, CommitHash: string;
      out MountPoint, ErrorMessage: string): Boolean;
    function IsMounted(const Repo, CommitHash: string): Boolean;
    function UnmountSnapshot(const Repo, CommitHash: string;
      out ErrorMessage: string): Boolean;
    function Unmount(Index: Integer; out ErrorMessage: string): Boolean;
    procedure UnmountAll;

    property Count: Integer read GetCount;
    property Commits[Index: Integer]: string read GetCommit;
    property MountPoints[Index: Integer]: string read GetMountPoint;
  end;

implementation

constructor TGTMMountManager.Create;
begin
  inherited Create;
  FCommits := TStringList.Create;
  FMountPoints := TStringList.Create;
end;

destructor TGTMMountManager.Destroy;
begin
  FMountPoints.Free;
  FCommits.Free;
  inherited Destroy;
end;

function TGTMMountManager.GetCount: Integer;
begin
  Result := FMountPoints.Count;
end;

function TGTMMountManager.GetCommit(Index: Integer): string;
begin
  if (Index < 0) or (Index >= FCommits.Count) then
    Exit('');
  Result := FCommits[Index];
end;

function TGTMMountManager.GetMountPoint(Index: Integer): string;
begin
  if (Index < 0) or (Index >= FMountPoints.Count) then
    Exit('');
  Result := FMountPoints[Index];
end;

function TGTMMountManager.HelperPath: string;
begin
  Result := IncludeTrailingPathDelimiter(
    ExtractFilePath(ExpandFileName(ParamStr(0)))
  ) + 'gtm-mount';
end;

function TGTMMountManager.SnapshotMountPoint(const Repo,
  CommitHash: string): string;
var
  BaseDir, RepoName, ShortHash: string;
begin
  BaseDir := IncludeTrailingPathDelimiter(GetEnvironmentVariable('HOME')) +
    '.cache/gtm/mounts';
  RepoName := ExtractFileName(
    ExcludeTrailingPathDelimiter(ExpandFileName(Repo))
  );
  ShortHash := Copy(CommitHash, 1, 8);
  Result := IncludeTrailingPathDelimiter(BaseDir) +
    RepoName + '-' + ShortHash;
end;

function TGTMMountManager.MountSnapshot(const Repo, CommitHash: string;
  out MountPoint, ErrorMessage: string): Boolean;
var
  Helper, RepoPath: string;
  P: TProcess;
begin
  Result := False;
  MountPoint := '';
  ErrorMessage := '';

  RepoPath := ExpandFileName(Repo);
  MountPoint := SnapshotMountPoint(RepoPath, CommitHash);

  if FMountPoints.IndexOf(MountPoint) >= 0 then
  begin
    ErrorMessage := 'Snapshot is already mounted at:' +
      LineEnding + MountPoint;
    Exit;
  end;

  Helper := HelperPath;
  if not FileExists(Helper) then
  begin
    ErrorMessage := 'gtm-mount was not found:' +
      LineEnding + Helper + LineEnding + LineEnding +
      'Run make mount first.';
    Exit;
  end;

  if not ForceDirectories(MountPoint) then
  begin
    ErrorMessage := 'Could not create mountpoint:' +
      LineEnding + MountPoint;
    Exit;
  end;

  P := TProcess.Create(nil);
  try
    P.Executable := Helper;
    P.Parameters.Add(RepoPath);
    P.Parameters.Add(CommitHash);
    P.Parameters.Add(MountPoint);
    P.Options := [];
    try
      P.Execute;
    except
      on E: Exception do
      begin
        ErrorMessage := 'Could not start gtm-mount:' +
          LineEnding + E.Message;
        Exit;
      end;
    end;
  finally
    P.Free;
  end;

  FCommits.Add(CommitHash);
  FMountPoints.Add(MountPoint);
  Result := True;
end;

function TGTMMountManager.IsMounted(const Repo,
  CommitHash: string): Boolean;
begin
  Result := FMountPoints.IndexOf(
    SnapshotMountPoint(Repo, CommitHash)
  ) >= 0;
end;

function TGTMMountManager.UnmountSnapshot(const Repo, CommitHash: string;
  out ErrorMessage: string): Boolean;
var
  Index: Integer;
begin
  Index := FMountPoints.IndexOf(
    SnapshotMountPoint(Repo, CommitHash)
  );

  if Index < 0 then
  begin
    ErrorMessage := 'Snapshot is not mounted.';
    Exit(False);
  end;

  Result := Unmount(Index, ErrorMessage);
end;

function TGTMMountManager.Unmount(Index: Integer;
  out ErrorMessage: string): Boolean;
var
  P: TProcess;
  MountPoint: string;
begin
  Result := False;
  ErrorMessage := '';

  if (Index < 0) or (Index >= FMountPoints.Count) then
  begin
    ErrorMessage := 'No mounted snapshot is selected.';
    Exit;
  end;

  MountPoint := FMountPoints[Index];

  P := TProcess.Create(nil);
  try
    P.Executable := 'fusermount3';
    P.Parameters.Add('-u');
    P.Parameters.Add(MountPoint);
    P.Options := [poWaitOnExit];
    try
      P.Execute;
    except
      on E: Exception do
      begin
        ErrorMessage := 'Could not unmount:' + LineEnding +
          MountPoint + LineEnding + LineEnding + E.Message;
        Exit;
      end;
    end;

    if P.ExitStatus <> 0 then
    begin
      ErrorMessage := 'Could not unmount:' + LineEnding +
        MountPoint + LineEnding + LineEnding +
        'The mount may still be busy.';
      Exit;
    end;
  finally
    P.Free;
  end;

  FCommits.Delete(Index);
  FMountPoints.Delete(Index);

  if DirectoryExists(MountPoint) then
    RemoveDir(MountPoint);

  Result := True;
end;

procedure TGTMMountManager.UnmountAll;
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

    FCommits.Delete(I);
    FMountPoints.Delete(I);
  end;
end;

end.
