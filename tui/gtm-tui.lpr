program gtm_tui;

{$mode objfpc}{$H+}

uses
  SysUtils, gtmtui;

var
  Repo, Branch: string;
begin
  if ParamCount >= 1 then
    Repo := ParamStr(1)
  else
    Repo := GetCurrentDir;

  if ParamCount >= 2 then
    Branch := ParamStr(2)
  else
    Branch := '';

  RunTUI(Repo, Branch);
end.
