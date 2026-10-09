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

implementation

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

end.
