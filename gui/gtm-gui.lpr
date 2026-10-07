program gtm_gui;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, mainform;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainWindow);
  Application.Run;
end.
