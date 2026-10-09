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
function CommitUnixTime(const Repo, CommitHash: string): Int64;
function CommitSubject(const Repo, CommitHash: string): string;
procedure BuildTimeline(const Repo, BranchName: string; Commits: TStrings);
procedure ListBranches(const Repo: string; Branches: TStrings);
procedure ListTags(const Repo: string; Tags: TStrings);
function ResolveTagCommit(const Repo, TagName: string): string;
function FindMergeBase(const Repo, BranchA, BranchB: string): string;
function CountCommitsAfter(const Repo, BaseCommit, BranchName: string): Integer;
function BranchTip(const Repo, BranchName: string): string;
function BranchRoot(const Repo, BranchName: string): string;

function ResolveCommitAbbreviation(Commits: TStrings;
  const CommitHash: string): string;
procedure EnsurePathExistsAtCommit(const Repo, CommitHash: string;
  var PathArg: string);
procedure BuildDirectoryEntryStates(const Repo, FromCommit, ToCommit,
  PathArg: string; EntryStates, DeletedEntries: TStrings);
procedure BuildTimelineSlice(BranchIndex: TStrings; const CenterCommit: string;
  WindowSize: Integer; Timeline: TStrings; out CenterIndex: Integer;
  out WindowPredecessor: string);

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
procedure GetHistory(const Repo, BranchName, PathArg: string; Lines: TStrings);
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
  FillChar(Buffer, SizeOf(Buffer), 0);

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
  OutText, ErrText, S, CommitHash, TailHash, FirstParent: string;
  Code, I, ParentCount: Integer;
  Graph, BranchPath: TStringList;
  Found: Boolean;

  procedure ParseGraphLine(const Line: string; out ACommit, AFirstParent: string;
    out AParentCount: Integer);
  var
    T, H: string;
    Q: Integer;
  begin
    ACommit := '';
    AFirstParent := '';
    AParentCount := 0;
    T := Trim(Line);
    if T = '' then
      Exit;

    Q := Pos(' ', T);
    if Q = 0 then
    begin
      ACommit := T;
      Exit;
    end;

    ACommit := Copy(T, 1, Q - 1);
    Delete(T, 1, Q);
    T := Trim(T);

    while T <> '' do
    begin
      Inc(AParentCount);
      Q := Pos(' ', T);
      if Q = 0 then
      begin
        H := T;
        T := '';
      end
      else
      begin
        H := Copy(T, 1, Q - 1);
        Delete(T, 1, Q);
        T := Trim(T);
      end;

      if AParentCount = 1 then
        AFirstParent := H;
    end;
  end;

  function HasNonFirstParent(const Line, WantedParent: string): Boolean;
  var
    T, H: string;
    Q, N: Integer;
  begin
    Result := False;
    T := Trim(Line);
    Q := Pos(' ', T);
    if Q = 0 then
      Exit;

    Delete(T, 1, Q);
    T := Trim(T);
    N := 0;

    while T <> '' do
    begin
      Inc(N);
      Q := Pos(' ', T);
      if Q = 0 then
      begin
        H := T;
        T := '';
      end
      else
      begin
        H := Copy(T, 1, Q - 1);
        Delete(T, 1, Q);
        T := Trim(T);
      end;

      if (N > 1) and SameText(H, WantedParent) then
        Exit(True);
    end;
  end;

begin
  if Commits = nil then
    Exit;

  Commits.Clear;
  BranchPath := TStringList.Create;
  Graph := TStringList.Create;
  try
    { First build the selected branch's own history.  First-parent traversal
      keeps merges on the selected line from importing the other side. }
    if not RunGit(Repo,
      ['rev-list', '--first-parent', '--reverse', BranchName],
      OutText, ErrText, Code) then
      Die('unable to execute git: ' + ErrText);

    if Code <> 0 then
      Die(Trim(ErrText));

    BranchPath.Text := StringReplace(OutText, #13, '', [rfReplaceAll]);
    while (BranchPath.Count > 0) and
          (Trim(BranchPath[BranchPath.Count - 1]) = '') do
      BranchPath.Delete(BranchPath.Count - 1);

    if BranchPath.Count = 0 then
      Exit;

    { A branch ref may stop at its old tip even though that path later rejoined
      another line.  Find the merge whose non-first parent is the selected
      branch tip, append the merge, then walk the continuation forward by
      following commits whose first parent is the current tail.

      The resulting TStringList is the path.  Forward and reverse navigation
      both index this same list, so reversing through a merge returns down the
      branch that was selected rather than switching to the merge's first
      parent. }
    if not RunGit(Repo,
      ['rev-list', '--all', '--parents', '--topo-order', '--reverse'],
      OutText, ErrText, Code) then
      Die('unable to execute git: ' + ErrText);

    if Code <> 0 then
      Die(Trim(ErrText));

    Graph.Text := StringReplace(OutText, #13, '', [rfReplaceAll]);
    TailHash := Trim(BranchPath[BranchPath.Count - 1]);

    Found := False;
    for I := 0 to Graph.Count - 1 do
    begin
      S := Trim(Graph[I]);
      ParseGraphLine(S, CommitHash, FirstParent, ParentCount);
      if (CommitHash <> '') and (ParentCount > 1) and
         HasNonFirstParent(S, TailHash) then
      begin
        BranchPath.Add(CommitHash);
        TailHash := CommitHash;
        Found := True;
        Break;
      end;
    end;

    if Found then
    begin
      repeat
        Found := False;
        for I := 0 to Graph.Count - 1 do
        begin
          ParseGraphLine(Graph[I], CommitHash, FirstParent, ParentCount);
          if (CommitHash <> '') and SameText(FirstParent, TailHash) and
             (BranchPath.IndexOf(CommitHash) < 0) then
          begin
            BranchPath.Add(CommitHash);
            TailHash := CommitHash;
            Found := True;
            Break;
          end;
        end;
      until not Found;
    end;

    Commits.Assign(BranchPath);
  finally
    Graph.Free;
    BranchPath.Free;
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


procedure ListTags(const Repo: string; Tags: TStrings);
var
  OutText, ErrText: string;
  Code, I: Integer;
  Lines: TStringList;
  S: string;
begin
  if Tags = nil then
    Exit;

  Tags.Clear;

  if not RunGit(Repo,
    ['tag', '--list', '--sort=refname'],
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
      if S <> '' then
        Tags.Add(S);
    end;
  finally
    Lines.Free;
  end;
end;

function ResolveTagCommit(const Repo, TagName: string): string;
var
  OutText, ErrText: string;
  Code: Integer;
begin
  Result := '';

  if Trim(TagName) = '' then
    Exit;

  { rev-parse with the commit peel suffix dereferences annotated tags and
    verifies that the final target is a commit. Lightweight tags resolve
    directly. }
  if not RunGit(Repo, ['rev-parse', TagName + '^{commit}'],
    OutText, ErrText, Code) then
    Exit;

  if Code = 0 then
    Result := CleanLine(OutText);
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


function EntryNameFromObject(const S: string): string;
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

function EntryHashFromObject(const S: string): string;
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

function FindObjectByName(Objects: TStrings;
  const EntryName: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Objects.Count - 1 do
    if EntryNameFromObject(Objects[I]) = EntryName then
      Exit(Objects[I]);
end;

function ResolveCommitAbbreviation(Commits: TStrings;
  const CommitHash: string): string;
var
  I: Integer;
begin
  Result := CommitHash;
  if (CommitHash = '') or (Length(CommitHash) >= 40) then
    Exit;

  for I := 0 to Commits.Count - 1 do
    if Pos(LowerCase(CommitHash), LowerCase(Commits[I])) = 1 then
      Exit(Commits[I]);
end;

procedure EnsurePathExistsAtCommit(const Repo, CommitHash: string;
  var PathArg: string);
var
  P: Integer;
begin
  while (PathArg <> '') and
        (not DirectoryExistsAtCommit(Repo, CommitHash, PathArg)) do
  begin
    P := LastDelimiter('/', PathArg);
    if P = 0 then
      PathArg := ''
    else
      PathArg := Copy(PathArg, 1, P - 1);
  end;
end;

procedure BuildDirectoryEntryStates(const Repo, FromCommit, ToCommit,
  PathArg: string; EntryStates, DeletedEntries: TStrings);
var
  OldObjects, NewObjects: TStringList;
  I: Integer;
  NewObject, OldObject, EntryName, NewHash, OldHash: string;
begin
  EntryStates.Clear;
  DeletedEntries.Clear;

  if ToCommit = '' then
    Exit;

  NewObjects := TStringList.Create;
  OldObjects := TStringList.Create;
  try
    ListDirectoryObjects(Repo, ToCommit, PathArg, NewObjects);

    if (FromCommit <> '') and
       DirectoryExistsAtCommit(Repo, FromCommit, PathArg) then
      ListDirectoryObjects(Repo, FromCommit, PathArg, OldObjects);

    for I := 0 to NewObjects.Count - 1 do
    begin
      NewObject := NewObjects[I];
      EntryName := EntryNameFromObject(NewObject);
      NewHash := EntryHashFromObject(NewObject);
      OldObject := FindObjectByName(OldObjects, EntryName);

      if OldObject = '' then
        EntryStates.Values[EntryName] := 'added'
      else
      begin
        OldHash := EntryHashFromObject(OldObject);
        if OldHash <> NewHash then
          EntryStates.Values[EntryName] := 'modified'
        else
          EntryStates.Values[EntryName] := 'unchanged';
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
        DeletedEntries.Add(EntryName);
      end;
    end;
  finally
    OldObjects.Free;
    NewObjects.Free;
  end;
end;

procedure BuildTimelineSlice(BranchIndex: TStrings; const CenterCommit: string;
  WindowSize: Integer; Timeline: TStrings; out CenterIndex: Integer;
  out WindowPredecessor: string);
var
  StartIndex, EndIndex, I, HalfWindow: Integer;
begin
  Timeline.Clear;
  WindowPredecessor := '';
  CenterIndex := -1;

  if BranchIndex.Count = 0 then
    Exit;

  CenterIndex := BranchIndex.IndexOf(CenterCommit);
  if CenterIndex < 0 then
    CenterIndex := BranchIndex.Count - 1;

  HalfWindow := WindowSize div 2;
  StartIndex := CenterIndex - HalfWindow;
  if StartIndex < 0 then
    StartIndex := 0;

  EndIndex := StartIndex + WindowSize - 1;
  if EndIndex >= BranchIndex.Count then
  begin
    EndIndex := BranchIndex.Count - 1;
    StartIndex := EndIndex - WindowSize + 1;
    if StartIndex < 0 then
      StartIndex := 0;
  end;

  for I := StartIndex to EndIndex do
    Timeline.Add(BranchIndex[I]);

  if StartIndex > 0 then
    WindowPredecessor := BranchIndex[StartIndex - 1];
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

procedure GetHistory(const Repo, BranchName, PathArg: string;
  Lines: TStrings);
var
  OutText, ErrText, FilePath: string;
  Code: Integer;
begin
  if Lines = nil then
    Exit;

  Lines.Clear;
  FilePath := NormalizeRepoPath(PathArg);
  if FilePath = '' then
    Exit;

  if not RunGit(Repo,
    ['log', '--follow',
     '--date=format:%Y-%m-%d %H:%M:%S',
     '--format=%ad  %h  %s',
     BranchName, '--', FilePath],
    OutText, ErrText, Code) then
    Die('unable to execute git: ' + ErrText);

  if Code <> 0 then
    Die(Trim(ErrText));

  Lines.Text := StringReplace(OutText, #13, '', [rfReplaceAll]);
end;

procedure ShowHistory(const Repo, BranchName, PathArg: string);
var
  Lines: TStringList;
  I: Integer;
begin
  Lines := TStringList.Create;
  try
    GetHistory(Repo, BranchName, PathArg, Lines);

    if Lines.Count = 0 then
      Die('no history found for path: ' + NormalizeRepoPath(PathArg));

    for I := 0 to Lines.Count - 1 do
      WriteLn(Lines[I]);
  finally
    Lines.Free;
  end;
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
