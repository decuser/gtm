unit gtmstate;

{$mode objfpc}{$H+}

interface

uses
  Classes;

type
  TGTMState = record
    Repo: string;
    Branch: string;
    CommitHash: string;
    CurrentPath: string;
    Timeline: TStringList;
    BranchIndex: TStringList;
    TagCommits: TStringList;
    TagNames: TStringList;
    EntryStates: TStringList;
    DeletedEntries: TStringList;
    PreviousCommitHash: string;
    WindowPredecessor: string;
    ForkIndex: Integer;
    ForkHash: string;
    MergeIndex: Integer;
    MergeHash: string;
    WindowSize: Integer;
    AfterForkCount: Integer;
    OldestCommitTime: Int64;
    NewestCommitTime: Int64;
    SelectedCommitTime: Int64;
    BranchCommitCount: Integer;
    CurrentBranchPosition: Integer;
  end;

procedure InitGTMState(var State: TGTMState);
procedure DoneGTMState(var State: TGTMState);
procedure SetRepository(var State: TGTMState; const Repo: string);
procedure SetBranch(var State: TGTMState; const Branch: string);
procedure ClearSnapshot(var State: TGTMState);

procedure BuildStateBranchIndex(var State: TGTMState);
function SelectStateBranch(var State: TGTMState; const BranchName: string;
  out TargetCommit: string): Boolean;
procedure BuildStateTimeline(var State: TGTMState; const CenterCommit: string);
procedure UpdateStateForkInfo(var State: TGTMState; BranchNames: TStrings);
procedure PopulateStateTags(var State: TGTMState; BranchNames: TStrings);
function StateTagIndexForCommit(const State: TGTMState;
  const CommitHash: string): Integer;
function SelectStateBranchForCommit(var State: TGTMState; BranchNames: TStrings;
  const CommitHash: string; out BranchListIndex: Integer): Boolean;
function SelectStateTimelineIndex(var State: TGTMState; Index: Integer): Boolean;
procedure EnsureStateCurrentPath(var State: TGTMState);
procedure BuildStateEntryStates(var State: TGTMState;
  const FromCommit, ToCommit: string);
procedure BuildStateDirectoryDisplay(var State: TGTMState; DisplayEntries: TStringList);

implementation

uses
  SysUtils, gtmcore;

procedure InitGTMState(var State: TGTMState);
begin
  State.Repo := '';
  State.Branch := '';
  State.CommitHash := '';
  State.CurrentPath := '';
  State.Timeline := TStringList.Create;
  State.BranchIndex := TStringList.Create;
  State.TagCommits := TStringList.Create;
  State.TagNames := TStringList.Create;
  State.EntryStates := TStringList.Create;
  State.DeletedEntries := TStringList.Create;
  State.PreviousCommitHash := '';
  State.WindowPredecessor := '';
  State.ForkIndex := -1;
  State.ForkHash := '';
  State.MergeIndex := -1;
  State.MergeHash := '';
  State.WindowSize := 100;
  State.AfterForkCount := 0;
  State.OldestCommitTime := 0;
  State.NewestCommitTime := 0;
  State.SelectedCommitTime := 0;
  State.BranchCommitCount := 0;
  State.CurrentBranchPosition := 0;
end;

procedure DoneGTMState(var State: TGTMState);
begin
  State.DeletedEntries.Free;
  State.DeletedEntries := nil;
  State.EntryStates.Free;
  State.EntryStates := nil;
  State.TagNames.Free;
  State.TagNames := nil;
  State.TagCommits.Free;
  State.TagCommits := nil;
  State.BranchIndex.Free;
  State.BranchIndex := nil;
  State.Timeline.Free;
  State.Timeline := nil;
end;

procedure SetRepository(var State: TGTMState; const Repo: string);
begin
  State.Repo := Repo;
end;

procedure SetBranch(var State: TGTMState; const Branch: string);
begin
  State.Branch := Branch;
end;

procedure ClearSnapshot(var State: TGTMState);
begin
  State.CommitHash := '';
  State.CurrentPath := '';
  State.CurrentBranchPosition := 0;
end;

procedure BuildStateBranchIndex(var State: TGTMState);
begin
  State.BranchIndex.Clear;
  if (Trim(State.Repo) = '') or (Trim(State.Branch) = '') then
  begin
    State.BranchCommitCount := 0;
    Exit;
  end;

  BuildTimeline(State.Repo, State.Branch, State.BranchIndex);
  State.BranchCommitCount := State.BranchIndex.Count;
end;

function SelectStateBranch(var State: TGTMState; const BranchName: string;
  out TargetCommit: string): Boolean;
begin
  TargetCommit := '';
  State.Branch := Trim(BranchName);
  BuildStateBranchIndex(State);
  Result := State.BranchIndex.Count > 0;
  if Result then
    TargetCommit := State.BranchIndex[State.BranchIndex.Count - 1];
end;

procedure BuildStateTimeline(var State: TGTMState; const CenterCommit: string);
var
  CenterIndex: Integer;
begin
  if State.BranchIndex.Count = 0 then
    BuildStateBranchIndex(State);

  if State.BranchIndex.Count = 0 then
    Exit;

  BuildTimelineSlice(
    State.BranchIndex,
    CenterCommit,
    State.WindowSize,
    State.Timeline,
    CenterIndex,
    State.WindowPredecessor
  );

  State.CurrentBranchPosition := CenterIndex;
  State.BranchCommitCount := State.BranchIndex.Count;
  State.OldestCommitTime := CommitUnixTime(State.Repo, State.BranchIndex[0]);
  State.NewestCommitTime := CommitUnixTime(
    State.Repo,
    State.BranchIndex[State.BranchIndex.Count - 1]
  );
  State.SelectedCommitTime := CommitUnixTime(State.Repo, CenterCommit);
end;

procedure UpdateStateForkInfo(var State: TGTMState; BranchNames: TStrings);
var
  RefTip: string;
  RefTipIndex: Integer;
begin
  State.BranchCommitCount := State.BranchIndex.Count;
  State.ForkIndex := -1;
  State.ForkHash := '';
  State.MergeIndex := -1;
  State.MergeHash := '';
  State.AfterForkCount := 0;

  if (Trim(State.Branch) = '') or SameText(Trim(State.Branch), 'master') then
    Exit;
  if BranchNames.IndexOf('master') < 0 then
    Exit;

  State.ForkHash := FindMergeBase(State.Repo, 'master', State.Branch);
  if State.ForkHash <> '' then
    State.ForkIndex := State.BranchIndex.IndexOf(State.ForkHash);

  RefTip := BranchTip(State.Repo, State.Branch);
  RefTipIndex := State.BranchIndex.IndexOf(RefTip);
  if (RefTipIndex >= 0) and (RefTipIndex < State.BranchIndex.Count - 1) then
  begin
    State.MergeIndex := RefTipIndex + 1;
    State.MergeHash := State.BranchIndex[State.MergeIndex];
  end;

  if State.ForkIndex >= 0 then
  begin
    if State.MergeIndex > State.ForkIndex then
      State.AfterForkCount := State.MergeIndex - State.ForkIndex - 1
    else
      State.AfterForkCount := State.BranchIndex.Count - State.ForkIndex - 1;
  end;
end;

procedure PopulateStateTags(var State: TGTMState; BranchNames: TStrings);
var
  Tags, Reachable, CandidatePath: TStringList;
  TagName, CommitHash, BranchName: string;
  I, J: Integer;
begin
  State.TagNames.Clear;
  State.TagCommits.Clear;
  State.TagNames.Add('(none)');
  State.TagCommits.Add('');

  if Trim(State.Repo) = '' then
    Exit;

  Tags := TStringList.Create;
  Reachable := TStringList.Create;
  CandidatePath := TStringList.Create;
  try
    Reachable.Sorted := True;
    Reachable.Duplicates := dupIgnore;

    for I := 0 to BranchNames.Count - 1 do
    begin
      BranchName := Trim(BranchNames[I]);
      if BranchName = '' then
        Continue;

      CandidatePath.Clear;
      BuildTimeline(State.Repo, BranchName, CandidatePath);
      for J := 0 to CandidatePath.Count - 1 do
        Reachable.Add(Trim(CandidatePath[J]));
    end;

    ListTags(State.Repo, Tags);
    for I := Tags.Count - 1 downto 0 do
    begin
      TagName := Trim(Tags[I]);
      CommitHash := ResolveTagCommit(State.Repo, TagName);
      if (CommitHash <> '') and (Reachable.IndexOf(CommitHash) >= 0) then
      begin
        State.TagNames.Add(TagName);
        State.TagCommits.Add(CommitHash);
      end;
    end;
  finally
    CandidatePath.Free;
    Reachable.Free;
    Tags.Free;
  end;
end;

function StateTagIndexForCommit(const State: TGTMState;
  const CommitHash: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to State.TagCommits.Count - 1 do
    if SameText(State.TagCommits[I], CommitHash) then
      Exit(I);
end;

function SelectStateBranchForCommit(var State: TGTMState; BranchNames: TStrings;
  const CommitHash: string; out BranchListIndex: Integer): Boolean;
var
  CandidatePath: TStringList;
  I: Integer;
begin
  Result := State.BranchIndex.IndexOf(CommitHash) >= 0;
  BranchListIndex := BranchNames.IndexOf(State.Branch);
  if Result then
    Exit;

  CandidatePath := TStringList.Create;
  try
    for I := 0 to BranchNames.Count - 1 do
    begin
      CandidatePath.Clear;
      BuildTimeline(State.Repo, BranchNames[I], CandidatePath);
      if CandidatePath.IndexOf(CommitHash) >= 0 then
      begin
        State.Branch := BranchNames[I];
        State.BranchIndex.Assign(CandidatePath);
        State.BranchCommitCount := State.BranchIndex.Count;
        BranchListIndex := I;
        Exit(True);
      end;
    end;
  finally
    CandidatePath.Free;
  end;

  Result := False;
end;

function SelectStateTimelineIndex(var State: TGTMState; Index: Integer): Boolean;
begin
  Result := False;
  if State.Timeline.Count = 0 then
    Exit;

  if Index < 0 then
    Index := 0;
  if Index >= State.Timeline.Count then
    Index := State.Timeline.Count - 1;

  State.PreviousCommitHash := State.CommitHash;
  State.CommitHash := Trim(State.Timeline[Index]);
  State.CurrentBranchPosition := State.BranchIndex.IndexOf(State.CommitHash);
  if State.CurrentBranchPosition < 0 then
    State.CurrentBranchPosition := 0;

  Result := True;
end;

procedure EnsureStateCurrentPath(var State: TGTMState);
begin
  EnsurePathExistsAtCommit(State.Repo, State.CommitHash, State.CurrentPath);
end;

procedure BuildStateEntryStates(var State: TGTMState;
  const FromCommit, ToCommit: string);
begin
  BuildDirectoryEntryStates(
    State.Repo,
    FromCommit,
    ToCommit,
    State.CurrentPath,
    State.EntryStates,
    State.DeletedEntries
  );
end;

procedure BuildStateDirectoryDisplay(var State: TGTMState; DisplayEntries: TStringList);
var
  Entries: TStringList;
  I: Integer;
  RawEntry, EntryName, ChangeState, DisplayEntry: string;
begin
  DisplayEntries.Clear;
  if State.CommitHash = '' then
    Exit;

  Entries := TStringList.Create;
  try
    ListDirectoryEntries(State.Repo, State.CommitHash, State.CurrentPath, Entries);

    DisplayEntries.Sorted := True;
    DisplayEntries.CaseSensitive := False;

    for I := 0 to Entries.Count - 1 do
    begin
      RawEntry := Entries[I];
      EntryName := RawEntry;
      while (Length(EntryName) > 0) and
            (EntryName[Length(EntryName)] = '/') do
        Delete(EntryName, Length(EntryName), 1);

      ChangeState := State.EntryStates.Values[EntryName];
      if ChangeState = 'added' then
        DisplayEntry := RawEntry + ' [added]'
      else if ChangeState = 'modified' then
        DisplayEntry := RawEntry + ' [modified]'
      else
        DisplayEntry := RawEntry;

      DisplayEntries.Add(DisplayEntry);
    end;

    for I := 0 to State.DeletedEntries.Count - 1 do
      DisplayEntries.Add(State.DeletedEntries[I] + ' [deleted]');
  finally
    Entries.Free;
  end;
end;

end.
