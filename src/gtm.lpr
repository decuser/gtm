program gtm;

{$mode objfpc}{$H+}

uses
  SysUtils, gtmcore;

procedure Usage;
begin
  WriteLn('Usage:');
  WriteLn('  gtm --repo PATH [--branch NAME] [--at "YYYY-MM-DD HH:MM"]');
  WriteLn('  gtm --repo PATH [--branch NAME] [--at "YYYY-MM-DD HH:MM"] ls [PATH]');
  WriteLn('  gtm --repo PATH [--branch NAME] [--at "YYYY-MM-DD HH:MM"] cat PATH');
  WriteLn('  gtm --repo PATH [--branch NAME] [--at "YYYY-MM-DD HH:MM"] get PATH [DEST]');
  WriteLn('  gtm --repo PATH [--branch NAME] history PATH');
  WriteLn('  gtm --repo PATH [--branch NAME] diff --from TIME --to TIME [PATH]');
  WriteLn('  gtm --repo PATH [--branch NAME] vdiff [--tool NAME] --from TIME --to TIME PATH');
  Halt(1);
end;

var
  Repo, BranchName, RequestedAt, CommandName, CommandPath, CommandDest,
  CommitHash, FromAt, ToAt, ToolName: string;
  I: Integer;
begin
  Repo := '';
  BranchName := 'master';
  RequestedAt := '';
  CommandName := '';
  CommandPath := '';
  CommandDest := '';
  FromAt := '';
  ToAt := '';
  ToolName := '';

  I := 1;
  while I <= ParamCount do
  begin
    if ParamStr(I) = '--repo' then
    begin
      Inc(I); if I > ParamCount then Usage;
      Repo := ParamStr(I);
    end
    else if ParamStr(I) = '--branch' then
    begin
      Inc(I); if I > ParamCount then Usage;
      BranchName := ParamStr(I);
    end
    else if ParamStr(I) = '--at' then
    begin
      Inc(I); if I > ParamCount then Usage;
      RequestedAt := ParamStr(I);
    end
    else if ParamStr(I) = '--from' then
    begin
      Inc(I); if I > ParamCount then Usage;
      FromAt := ParamStr(I);
    end
    else if ParamStr(I) = '--to' then
    begin
      Inc(I); if I > ParamCount then Usage;
      ToAt := ParamStr(I);
    end
    else if ParamStr(I) = '--tool' then
    begin
      Inc(I); if I > ParamCount then Usage;
      ToolName := ParamStr(I);
    end
    else if (ParamStr(I) = 'ls') or
            (ParamStr(I) = 'cat') or
            (ParamStr(I) = 'get') or
            (ParamStr(I) = 'history') or
            (ParamStr(I) = 'diff') or
            (ParamStr(I) = 'vdiff') then
    begin
      if CommandName <> '' then Usage;
      CommandName := ParamStr(I);

      if CommandName = 'get' then
      begin
        if I < ParamCount then begin Inc(I); CommandPath := ParamStr(I); end;
        if I < ParamCount then begin Inc(I); CommandDest := ParamStr(I); end;
      end
      else if (CommandName <> 'diff') and (CommandName <> 'vdiff') then
      begin
        if I < ParamCount then begin Inc(I); CommandPath := ParamStr(I); end;
      end;
    end
    else
    begin
      if (CommandName = 'diff') or (CommandName = 'vdiff') then
      begin
        if CommandPath <> '' then Usage;
        CommandPath := ParamStr(I);
      end
      else
        Usage;
    end;

    Inc(I);
  end;

  if Repo = '' then Usage;

  if CommandName = 'history' then
  begin
    if CommandPath = '' then Die('history requires a path');
    ShowHistory(Repo, BranchName, CommandPath);
    Halt(0);
  end;

  if CommandName = 'diff' then
  begin
    ShowDiff(Repo, BranchName, FromAt, ToAt, CommandPath);
    Halt(0);
  end;

  if CommandName = 'vdiff' then
  begin
    ShowVisualDiff(Repo, BranchName, FromAt, ToAt, ToolName, CommandPath);
    Halt(0);
  end;

  if RequestedAt = '' then
    RequestedAt := CurrentLocalTimeForGit;

  CommitHash := ResolveCommit(Repo, BranchName, RequestedAt);

  if CommandName = '' then
    ShowSnapshot(Repo, BranchName, RequestedAt, CommitHash)
  else if CommandName = 'ls' then
  begin
    if CommandPath = '' then CommandPath := '/';
    ListDirectory(Repo, CommitHash, CommandPath);
  end
  else if CommandName = 'cat' then
  begin
    if CommandPath = '' then Die('cat requires a file path');
    CatFile(Repo, CommitHash, CommandPath);
  end
  else if CommandName = 'get' then
  begin
    if CommandPath = '' then Die('get requires a file path');
    GetFile(Repo, CommitHash, CommandPath, CommandDest);
  end;
end.
