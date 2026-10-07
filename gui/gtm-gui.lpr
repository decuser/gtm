program gtm_gui;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, mainform;

{$R *.res}

{$I gtmversion.inc}

begin
  if (ParamCount = 1) and (ParamStr(1) = '--version') then
  begin
    WriteLn('gtm-gui ', GTMVersion);
    Halt(0);
  end;

  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainWindow);
  Application.Run;
end.
