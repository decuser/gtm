unit gtmcore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

procedure Die(const Msg: string);
function CurrentLocalTimeForGit: string;
function NormalizeRepoPath(const S: string): string;
function ResolveCommit(const Repo, BranchName, RequestedAt: string): string;
function ResolveFirstParentCommit(const Repo, BranchName,
  RequestedAt: string): string;
function CommitTime(const Repo, CommitHash: string): string;
function CommitUnixTime(const Repo, CommitHash: string): Int64;
function ResolveCommitAtUnixTime(const Repo, BranchName: string;
  UnixTime: Int64): string;
function CommitSubject(const Repo, CommitHash: string): string;
procedure BuildTimeline(const Repo, BranchName: string; Commits: TStrings);
procedure BuildTimelineWindow(const Repo, BranchName, CenterCommit: string;
  WindowSize: Integer; Commits: TStrings; out OlderCommit: string;
  out HasNewer: Boolean);
procedure ListBranches(const Repo: string; Branches: TStrings);
function FindMergeBase(const Repo, BranchA, BranchB: string): string;
function CountBranchCommits(const Repo, BranchName: string): Integer;
function CountReachableCommits(const Repo, BranchName: string): Integer;
function CountCommitsAfter(const Repo, BaseCommit, BranchName: string): Integer;
function BranchTip(const Repo, BranchName: string): string;
function BranchRoot(const Repo, BranchName: string): string;
function BranchCommitAtPosition(const Repo, BranchName: string;
  Position, TotalCount: Integer): string;

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
const
  BufferSize = 8192;
var
  P: TProcess;
  SSOut, SSErr: TStringStream;
  Buffer: array[0..BufferSize - 1] of Byte;
  I, N: Integer;
begin
  P := TProcess.Create(nil);
  SSOut := TStringStream.Create('');
  SSErr := TStringStream.Create('');
  try
    P.Executable := 'git';
    P.Options := [poUsePipes];
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

function ResolveFirstParentCommit(const Repo, BranchName,
  RequestedAt: string): string;
var
  OutText, ErrText: string;
  Code: Integer;
begin
  Result := '';

  if not RunGit(Repo,
    ['rev-list', '--first-parent', '-1',
     '--before=' + RequestedAt, BranchName],
    OutText, ErrText, Code) then
    Exit;

  if Code = 0 then
    Result := CleanLine(OutText);

  if Result = '' then
    Result := BranchRoot(Repo, BranchName);
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

function CommitUnixTime(const Repo, CommitHash: string): Int64;
var
  OutText, ErrText: string;
  Code: Integer;
begin
  Result := 0;

  if not RunGit(Repo, ['show', '-s', '--format=%ct', CommitHash],
    OutText, ErrText, Code) then
    Die('unable to execute git: ' + ErrText);

  if Code <> 0 then
    Die(Trim(ErrText));

  Result := StrToInt64Def(CleanLine(OutText), 0);
end;

function ResolveCommitAtUnixTime(const Repo, BranchName: string;
  UnixTime: Int64): string;
var
  OutText, ErrText: string;
  Code: Integer;
begin
  Result := '';

  if not RunGit(Repo,
    ['rev-list', '-1', '--before=@' + IntToStr(UnixTime), BranchName],
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

procedure BuildTimelineWindow(const Repo, BranchName, CenterCommit: string;
  WindowSize: Integer; Commits: TStrings; out OlderCommit: string;
  out HasNewer: Boolean);
var
  OutText, ErrText: string;
  Code, DescCount, AfterCount, BeforeCount, SkipCount, I: Integer;
  BeforeLines, AfterLines: TStringList;
begin
  if Commits = nil then
    Exit;

  Commits.Clear;
  OlderCommit := '';
  HasNewer := False;

  if WindowSize < 2 then
    WindowSize := 2;

  if (Trim(CenterCommit) = '') or (Trim(BranchName) = '') then
    Exit;

  { Count descendants so we can take the commits nearest the center,
    rather than the newest commits on the branch.  This returns only a
    scalar even for a very large repository. }
  if not RunGit(Repo,
    ['rev-list', '--first-parent', '--count', CenterCommit + '..' + BranchName],
    OutText, ErrText, Code) then
    Die('unable to execute git: ' + ErrText);

  if Code <> 0 then
    Die(Trim(ErrText));

  DescCount := StrToIntDef(CleanLine(OutText), 0);

  AfterCount := WindowSize div 2;
  if DescCount < AfterCount then
    AfterCount := DescCount;

  BeforeCount := WindowSize - AfterCount;

  { Fetch the center plus bounded ancestors, with one extra commit kept
    as the predecessor just outside the visible window. }
  BeforeLines := TStringList.Create;
  AfterLines := TStringList.Create;
  try
    if not RunGit(Repo,
      ['rev-list', '--first-parent', '--max-count=' + IntToStr(BeforeCount + 1), CenterCommit],
      OutText, ErrText, Code) then
      Die('unable to execute git: ' + ErrText);

    if Code <> 0 then
      Die(Trim(ErrText));

    BeforeLines.Text := StringReplace(OutText, #13, '', [rfReplaceAll]);

    while (BeforeLines.Count > 0) and
          (Trim(BeforeLines[BeforeLines.Count - 1]) = '') do
      BeforeLines.Delete(BeforeLines.Count - 1);

    if BeforeLines.Count > BeforeCount then
    begin
      OlderCommit := Trim(BeforeLines[BeforeLines.Count - 1]);
      BeforeLines.Delete(BeforeLines.Count - 1);
    end;

    for I := BeforeLines.Count - 1 downto 0 do
      if Trim(BeforeLines[I]) <> '' then
        Commits.Add(Trim(BeforeLines[I]));

    if AfterCount > 0 then
    begin
      SkipCount := DescCount - AfterCount;

      if not RunGit(Repo,
        ['rev-list',
         '--skip=' + IntToStr(SkipCount),
         '--max-count=' + IntToStr(AfterCount),
         '--reverse',
         CenterCommit + '..' + BranchName],
        OutText, ErrText, Code) then
        Die('unable to execute git: ' + ErrText);

      if Code <> 0 then
        Die(Trim(ErrText));

      AfterLines.Text := StringReplace(OutText, #13, '', [rfReplaceAll]);

      for I := 0 to AfterLines.Count - 1 do
        if Trim(AfterLines[I]) <> '' then
          Commits.Add(Trim(AfterLines[I]));
    end;

    HasNewer := DescCount > AfterCount;
  finally
    AfterLines.Free;
    BeforeLines.Free;
  end;
end;


procedure ListBranches(const Repo: string; Branches: TStrings);
var
  OutText, ErrText: string;
  Code, I: Integer;
  Lines: TStringList;
  S: string;
begin
  if Branches = nil then
    Exit;

  Branches.Clear;

  if not RunGit(Repo,
    ['for-each-ref', '--format=%(refname:short)',
     'refs/heads', 'refs/remotes'],
    OutText, ErrText, Code) then
    Die('unable to execute git: ' + ErrText);

  if Code <> 0 then
    Die(Trim(ErrText));

  Lines := TStringList.Create;
  try
    Lines.Text := StringReplace(OutText, #13, '', [rfReplaceAll]);

    for I := 0 to Lines.Count - 1 do
    begin
      S := Trim(Lines[I]);

      if S = '' then
        Continue;

      if (Length(S) >= 5) and
         SameText(Copy(S, Length(S) - 4, 5), '/HEAD') then
        Continue;

      if Branches.IndexOf(S) < 0 then
        Branches.Add(S);
    end;
  finally
    Lines.Free;
  end;
end;

function FindMergeBase(const Repo, BranchA, BranchB: string): string;
var
  OutText, ErrText: string;
  Code: Integer;
begin
  Result := '';

  if (Trim(BranchA) = '') or (Trim(BranchB) = '') then
    Exit;

  if not RunGit(Repo, ['merge-base', BranchA, BranchB],
    OutText, ErrText, Code) then
    Exit;

  if Code = 0 then
    Result := CleanLine(OutText);
end;

function CountBranchCommits(const Repo, BranchName: string): Integer;
var
  OutText, ErrText: string;
  Code: Integer;
begin
  Result := 0;

  if not RunGit(Repo, ['rev-list', '--first-parent', '--count', BranchName],
    OutText, ErrText, Code) then
    Exit;

  if Code = 0 then
    Result := StrToIntDef(CleanLine(OutText), 0);
end;

function CountReachableCommits(const Repo, BranchName: string): Integer;
var
  OutText, ErrText: string;
  Code: Integer;
begin
  Result := 0;

  if not RunGit(Repo, ['rev-list', '--count', BranchName],
    OutText, ErrText, Code) then
    Exit;

  if Code = 0 then
    Result := StrToIntDef(CleanLine(OutText), 0);
end;


function CountCommitsAfter(const Repo, BaseCommit, BranchName: string): Integer;
var
  OutText, ErrText: string;
  Code: Integer;
begin
  Result := 0;

  if (Trim(BaseCommit) = '') or (Trim(BranchName) = '') then
    Exit;

  if not RunGit(Repo,
    ['rev-list', '--first-parent', '--count', BaseCommit + '..' + BranchName],
    OutText, ErrText, Code) then
    Exit;

  if Code = 0 then
    Result := StrToIntDef(CleanLine(OutText), 0);
end;

function BranchTip(const Repo, BranchName: string): string;
var
  OutText, ErrText: string;
  Code: Integer;
begin
  Result := '';

  if not RunGit(Repo, ['rev-parse', BranchName],
    OutText, ErrText, Code) then
    Exit;

  if Code = 0 then
    Result := CleanLine(OutText);
end;

function BranchRoot(const Repo, BranchName: string): string;
var
  OutText, ErrText: string;
  Code, NL: Integer;
begin
  Result := '';

  if not RunGit(Repo, ['rev-list', '--first-parent', '--max-parents=0', BranchName],
    OutText, ErrText, Code) then
    Exit;

  if Code <> 0 then
    Exit;

  OutText := Trim(OutText);
  NL := Pos(#10, OutText);
  if NL > 0 then
    Result := Trim(Copy(OutText, 1, NL - 1))
  else
    Result := OutText;
end;

function BranchCommitAtPosition(const Repo, BranchName: string;
  Position, TotalCount: Integer): string;
var
  OutText, ErrText: string;
  Code, SkipCount: Integer;
begin
  Result := '';

  if TotalCount <= 0 then
    Exit;

  if Position < 0 then
    Position := 0;
  if Position >= TotalCount then
    Position := TotalCount - 1;

  { git rev-list is newest-first.  The slider is oldest-left, newest-right. }
  SkipCount := TotalCount - 1 - Position;

  if not RunGit(Repo,
    ['rev-list', '--first-parent',
     '--skip=' + IntToStr(SkipCount),
     '--max-count=1',
     BranchName],
    OutText, ErrText, Code) then
    Exit;

  if Code = 0 then
    Result := CleanLine(OutText);
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
