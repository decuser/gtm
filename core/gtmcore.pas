unit gtmcore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

procedure Die(const Msg: string);
function CurrentLocalTimeForGit: string;
function NormalizeRepoPath(const S: string): string;
function ResolveCommit(const Repo, BranchName, RequestedAt: string): string;
function CommitTime(const Repo, CommitHash: string): string;
function CommitSubject(const Repo, CommitHash: string): string;
procedure BuildTimeline(const Repo, BranchName: string; Commits: TStrings);

procedure ShowSnapshot(const Repo, BranchName, RequestedAt, CommitHash: string);
function DirectoryExistsAtCommit(const Repo, CommitHash, PathArg: string): Boolean;
procedure ListDirectoryEntries(const Repo, CommitHash, PathArg: string;
  Entries: TStrings);
procedure ListDirectoryObjects(const Repo, CommitHash, PathArg: string;
  Entries: TStrings);
procedure ListDirectory(const Repo, CommitHash, PathArg: string);
procedure CatFile(const Repo, CommitHash, PathArg: string);
procedure GetFile(const Repo, CommitHash, PathArg, DestArg: string);
procedure ExtractFile(const Repo, CommitHash, PathArg, DestFile: string);
procedure ShowHistory(const Repo, BranchName, PathArg: string);
procedure ShowDiff(const Repo, BranchName, FromAt, ToAt, PathArg: string);
procedure ShowVisualDiff(const Repo, BranchName, FromAt, ToAt,
  ToolName, PathArg: string);

implementation

function RunGit(const Repo: string; const Args: array of string;
  out OutputText, ErrorText: string; out ExitCode: Integer): Boolean;
var
  P: TProcess;
  SSOut, SSErr: TStringStream;
  I: Integer;
begin
  P := TProcess.Create(nil);
  SSOut := TStringStream.Create('');
  SSErr := TStringStream.Create('');
  try
    P.Executable := 'git';
    P.Options := [poUsePipes, poWaitOnExit];
    P.Parameters.Add('-C');
    P.Parameters.Add(Repo);

    for I := Low(Args) to High(Args) do
      P.Parameters.Add(Args[I]);

    try
      P.Execute;
    except
      on E: Exception do
      begin
        OutputText := '';
        ErrorText := E.Message;
        ExitCode := -1;
        Exit(False);
      end;
    end;

    SSOut.CopyFrom(P.Output, 0);
    SSErr.CopyFrom(P.Stderr, 0);
    OutputText := SSOut.DataString;
    ErrorText := SSErr.DataString;
    ExitCode := P.ExitStatus;
    Result := True;
  finally
    SSErr.Free;
    SSOut.Free;
    P.Free;
  end;
end;

function RunGitInteractive(const Repo: string; const Args: array of string;
  out ExitCode: Integer): Boolean;
var
  P: TProcess;
  I: Integer;
begin
  P := TProcess.Create(nil);
  try
    P.Executable := 'git';
    P.Options := [poWaitOnExit];
    P.Parameters.Add('-C');
    P.Parameters.Add(Repo);

    for I := Low(Args) to High(Args) do
      P.Parameters.Add(Args[I]);

    try
      P.Execute;
    except
      on E: Exception do
      begin
        WriteLn(StdErr, 'gtm: unable to execute git: ', E.Message);
        ExitCode := -1;
        Exit(False);
      end;
    end;

    ExitCode := P.ExitStatus;
    Result := True;
  finally
    P.Free;
  end;
end;

procedure Die(const Msg: string);
begin
  WriteLn(StdErr, 'gtm: ', Msg);
  Halt(1);
end;

function CleanLine(const S: string): string;
begin
  Result := Trim(StringReplace(StringReplace(S, #13, '', [rfReplaceAll]),
    #10, '', [rfReplaceAll]));
end;

function NormalizeRepoPath(const S: string): string;
begin
  Result := S;
  while (Length(Result) > 0) and (Result[1] = '/') do
    Delete(Result, 1, 1);
  while (Length(Result) > 0) and (Result[Length(Result)] = '/') do
    Delete(Result, Length(Result), 1);
end;

function CurrentLocalTimeForGit: string;
begin
  Result := FormatDateTime('yyyy"-"mm"-"dd hh":"nn":"ss', Now);
end;

function ResolveCommit(const Repo, BranchName, RequestedAt: string): string;
var
  OutText, ErrText: string;
  Code: Integer;
begin
  if not RunGit(Repo,
    ['rev-list', '-1', '--before=' + RequestedAt, BranchName],
    OutText, ErrText, Code) then
    Die('unable to execute git: ' + ErrText);

  if Code <> 0 then
  begin
    ErrText := Trim(ErrText);
    if ErrText = '' then ErrText := 'git rev-list failed';
    Die(ErrText);
  end;

  Result := CleanLine(OutText);
  if Result = '' then
    Die('no commit found at or before requested time');
end;

function CommitTime(const Repo, CommitHash: string): string;
var
  OutText, ErrText: string;
  Code: Integer;
begin
  if not RunGit(Repo, ['show', '-s', '--format=%ci', CommitHash],
    OutText, ErrText, Code) then
    Die('unable to execute git: ' + ErrText);

  if Code <> 0 then
    Die(Trim(ErrText));

  Result := CleanLine(OutText);
end;

function CommitSubject(const Repo, CommitHash: string): string;
var
  OutText, ErrText: string;
  Code: Integer;
begin
  if not RunGit(Repo, ['show', '-s', '--format=%s', CommitHash],
    OutText, ErrText, Code) then
    Die('unable to execute git: ' + ErrText);

  if Code <> 0 then
    Die(Trim(ErrText));

  Result := CleanLine(OutText);
end;

procedure BuildTimeline(const Repo, BranchName: string; Commits: TStrings);
var
  OutText, ErrText: string;
  Code: Integer;
begin
  if Commits = nil then
    Exit;

  Commits.Clear;

  if not RunGit(Repo,
    ['rev-list', '--reverse', BranchName],
    OutText, ErrText, Code) then
    Die('unable to execute git: ' + ErrText);

  if Code <> 0 then
    Die(Trim(ErrText));

  Commits.Text := StringReplace(OutText, #13, '', [rfReplaceAll]);
end;

procedure ShowSnapshot(const Repo, BranchName, RequestedAt, CommitHash: string);
var
  OutText, ErrText: string;
  Code, NL: Integer;
begin
  if not RunGit(Repo, ['show', '-s', '--format=%ci%n%s', CommitHash],
    OutText, ErrText, Code) then
    Die('unable to execute git: ' + ErrText);

  if Code <> 0 then
    Die(Trim(ErrText));

  WriteLn('Repository: ', ExpandFileName(Repo));
  WriteLn('Branch:     ', BranchName);
  WriteLn('Requested:  ', RequestedAt);
  WriteLn('Snapshot:   ', CommitHash);

  OutText := StringReplace(OutText, #13, '', [rfReplaceAll]);
  NL := Pos(#10, OutText);
  if NL > 0 then
  begin
    WriteLn('Committed:  ', Copy(OutText, 1, NL - 1));
    Delete(OutText, 1, NL);
    WriteLn('Message:    ', Trim(OutText));
  end
  else
    WriteLn('Committed:  ', Trim(OutText));
end;

function DirectoryExistsAtCommit(const Repo, CommitHash, PathArg: string): Boolean;
var
  OutText, ErrText, TreePath, ObjectSpec: string;
  Code: Integer;
begin
  TreePath := NormalizeRepoPath(PathArg);

  if TreePath = '' then
    Exit(True);

  ObjectSpec := CommitHash + ':' + TreePath;

  if not RunGit(Repo, ['cat-file', '-t', ObjectSpec],
    OutText, ErrText, Code) then
    Exit(False);

  Result := (Code = 0) and (CleanLine(OutText) = 'tree');
end;

procedure ListDirectoryObjects(const Repo, CommitHash, PathArg: string;
  Entries: TStrings);
var
  OutText, ErrText, TreeSpec, S: string;
  Code: Integer;
  Lines: TStringList;
  I, TabPos, P1, P2: Integer;
  TypeText, HashText, NameText: string;
begin
  if Entries = nil then
    Exit;

  Entries.Clear;

  TreeSpec := NormalizeRepoPath(PathArg);
  if TreeSpec = '' then
    TreeSpec := CommitHash
  else
    TreeSpec := CommitHash + ':' + TreeSpec;

  if not RunGit(Repo, ['ls-tree', TreeSpec], OutText, ErrText, Code) then
    Die('unable to execute git: ' + ErrText);

  if Code <> 0 then
    Die(Trim(ErrText));

  Lines := TStringList.Create;
  try
    Lines.Text := StringReplace(OutText, #13, '', [rfReplaceAll]);

    for I := 0 to Lines.Count - 1 do
    begin
      S := Lines[I];
      if Trim(S) = '' then
        Continue;

      TabPos := Pos(#9, S);
      if TabPos = 0 then
        Continue;

      NameText := Copy(S, TabPos + 1, MaxInt);
      Delete(S, TabPos, MaxInt);

      P1 := Pos(' ', S);
      if P1 = 0 then
        Continue;
      Delete(S, 1, P1);

      P2 := Pos(' ', S);
      if P2 = 0 then
        Continue;

      TypeText := Copy(S, 1, P2 - 1);
      HashText := Copy(S, P2 + 1, MaxInt);

      Entries.Add(TypeText + #9 + HashText + #9 + NameText);
    end;
  finally
    Lines.Free;
  end;
end;

procedure ListDirectoryEntries(const Repo, CommitHash, PathArg: string;
  Entries: TStrings);
var
  OutText, ErrText, TreeSpec, S: string;
  Code: Integer;
  Lines: TStringList;
  I, TabPos, P1, P2: Integer;
  TypeText, NameText: string;
begin
  if Entries = nil then
    Exit;

  Entries.Clear;

  TreeSpec := NormalizeRepoPath(PathArg);
  if TreeSpec = '' then
    TreeSpec := CommitHash
  else
    TreeSpec := CommitHash + ':' + TreeSpec;

  if not RunGit(Repo, ['ls-tree', TreeSpec], OutText, ErrText, Code) then
    Die('unable to execute git: ' + ErrText);

  if Code <> 0 then
    Die(Trim(ErrText));

  Lines := TStringList.Create;
  try
    Lines.Text := StringReplace(OutText, #13, '', [rfReplaceAll]);

    for I := 0 to Lines.Count - 1 do
    begin
      S := Lines[I];
      if Trim(S) = '' then
        Continue;

      TabPos := Pos(#9, S);
      if TabPos = 0 then
        Continue;

      NameText := Copy(S, TabPos + 1, MaxInt);
      Delete(S, TabPos, MaxInt);

      P1 := Pos(' ', S);
      if P1 = 0 then
        Continue;
      Delete(S, 1, P1);

      P2 := Pos(' ', S);
      if P2 = 0 then
        Continue;
      TypeText := Copy(S, 1, P2 - 1);

      if TypeText = 'tree' then
        Entries.Add(NameText + '/')
      else
        Entries.Add(NameText);
    end;
  finally
    Lines.Free;
  end;
end;

procedure ListDirectory(const Repo, CommitHash, PathArg: string);
var
  Entries: TStringList;
  I: Integer;
begin
  Entries := TStringList.Create;
  try
    ListDirectoryEntries(Repo, CommitHash, PathArg, Entries);
    for I := 0 to Entries.Count - 1 do
      WriteLn(Entries[I]);
  finally
    Entries.Free;
  end;
end;

procedure CatFile(const Repo, CommitHash, PathArg: string);
var
  OutText, ErrText, FilePath, ObjectSpec: string;
  Code: Integer;
begin
  FilePath := NormalizeRepoPath(PathArg);
  if FilePath = '' then Die('cat requires a file path');

  ObjectSpec := CommitHash + ':' + FilePath;

  if not RunGit(Repo, ['show', ObjectSpec], OutText, ErrText, Code) then
    Die('unable to execute git: ' + ErrText);

  if Code <> 0 then Die(Trim(ErrText));
  Write(OutText);
end;

function SourceBaseName(const PathArg: string): string;
var
  P: string;
  I: Integer;
begin
  P := NormalizeRepoPath(PathArg);
  if P = '' then Exit('');

  I := Length(P);
  while (I > 0) and (P[I] <> '/') do Dec(I);
  Result := Copy(P, I + 1, MaxInt);
end;

procedure GetFile(const Repo, CommitHash, PathArg, DestArg: string);
var
  OutText, ErrText, FilePath, ObjectSpec, DestPath: string;
  Code: Integer;
  FS: TFileStream;
begin
  FilePath := NormalizeRepoPath(PathArg);
  if FilePath = '' then Die('get requires a file path');

  DestPath := DestArg;
  if DestPath = '' then DestPath := SourceBaseName(FilePath);

  if FileExists(DestPath) or DirectoryExists(DestPath) then
    Die('destination already exists: ' + DestPath);

  ObjectSpec := CommitHash + ':' + FilePath;

  if not RunGit(Repo, ['show', ObjectSpec], OutText, ErrText, Code) then
    Die('unable to execute git: ' + ErrText);

  if Code <> 0 then Die(Trim(ErrText));

  FS := TFileStream.Create(DestPath, fmCreate);
  try
    if Length(OutText) > 0 then
      FS.WriteBuffer(OutText[1], Length(OutText));
  finally
    FS.Free;
  end;

  WriteLn('Recovered:  ', FilePath);
  WriteLn('From:       ', CommitHash);
  WriteLn('To:         ', ExpandFileName(DestPath));
end;

procedure ExtractFile(const Repo, CommitHash, PathArg, DestFile: string);
var
  OutText, ErrText, FilePath, ObjectSpec: string;
  Code: Integer;
  FS: TFileStream;
begin
  FilePath := NormalizeRepoPath(PathArg);
  if FilePath = '' then
    Die('extract requires a file path');

  if DestFile = '' then
    Die('extract requires a destination path');

  ObjectSpec := CommitHash + ':' + FilePath;

  if not RunGit(Repo, ['show', ObjectSpec], OutText, ErrText, Code) then
    Die('unable to execute git: ' + ErrText);

  if Code <> 0 then
    Die(Trim(ErrText));

  FS := TFileStream.Create(DestFile, fmCreate);
  try
    if Length(OutText) > 0 then
      FS.WriteBuffer(OutText[1], Length(OutText));
  finally
    FS.Free;
  end;
end;

procedure ShowHistory(const Repo, BranchName, PathArg: string);
var
  OutText, ErrText, FilePath: string;
  Code: Integer;
begin
  FilePath := NormalizeRepoPath(PathArg);
  if FilePath = '' then Die('history requires a path');

  if not RunGit(Repo,
    ['log', '--date=format:%Y-%m-%d %H:%M:%S',
     '--format=%ad  %h  %s', BranchName, '--', FilePath],
    OutText, ErrText, Code) then
    Die('unable to execute git: ' + ErrText);

  if Code <> 0 then Die(Trim(ErrText));
  if Trim(OutText) = '' then
    Die('no history found for path: ' + FilePath);

  Write(OutText);
end;

procedure ShowDiff(const Repo, BranchName, FromAt, ToAt, PathArg: string);
var
  FromCommit, ToCommit, FilePath: string;
  Code: Integer;
begin
  if FromAt = '' then Die('diff requires --from');
  if ToAt = '' then Die('diff requires --to');

  FromCommit := ResolveCommit(Repo, BranchName, FromAt);
  ToCommit := ResolveCommit(Repo, BranchName, ToAt);
  FilePath := NormalizeRepoPath(PathArg);

  if FilePath = '' then
  begin
    if not RunGitInteractive(Repo, ['--no-pager', 'diff', FromCommit, ToCommit], Code) then
      Halt(1);
  end
  else
  begin
    if not RunGitInteractive(Repo,
      ['--no-pager', 'diff', FromCommit, ToCommit, '--', FilePath], Code) then
      Halt(1);
  end;

  if Code <> 0 then
    Die('git diff failed with exit code ' + IntToStr(Code));
end;

procedure ShowVisualDiff(const Repo, BranchName, FromAt, ToAt,
  ToolName, PathArg: string);
var
  FromCommit, ToCommit, FilePath: string;
  Code: Integer;
begin
  FilePath := NormalizeRepoPath(PathArg);
  if FilePath = '' then Die('vdiff requires a path');
  if FromAt = '' then Die('vdiff requires --from');
  if ToAt = '' then Die('vdiff requires --to');

  FromCommit := ResolveCommit(Repo, BranchName, FromAt);
  ToCommit := ResolveCommit(Repo, BranchName, ToAt);

  if ToolName <> '' then
  begin
    if not RunGitInteractive(Repo,
      ['difftool', '--tool=' + ToolName, FromCommit, ToCommit, '--', FilePath],
      Code) then Halt(1);
  end
  else
  begin
    if not RunGitInteractive(Repo,
      ['difftool', FromCommit, ToCommit, '--', FilePath],
      Code) then Halt(1);
  end;

  if Code <> 0 then
    Die('git difftool failed with exit code ' + IntToStr(Code));
end;

end.
