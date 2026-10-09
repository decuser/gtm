unit gtmexec;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

function LaunchDetached(const Executable: string;
  const Args: array of string; out ErrorMessage: string): Boolean;
function OpenPath(const PathName: string; out ErrorMessage: string): Boolean;
function VisualDiff(const LeftPath, RightPath: string;
  out ErrorMessage: string): Boolean;

implementation

function LaunchDetached(const Executable: string;
  const Args: array of string; out ErrorMessage: string): Boolean;
var
  P: TProcess;
  I: Integer;
begin
  Result := False;
  ErrorMessage := '';

  P := TProcess.Create(nil);
  try
    P.Executable := Executable;
    for I := Low(Args) to High(Args) do
      P.Parameters.Add(Args[I]);
    P.Options := [];

    try
      P.Execute;
      Result := True;
    except
      on E: Exception do
        ErrorMessage := E.Message;
    end;
  finally
    P.Free;
  end;
end;

function OpenPath(const PathName: string; out ErrorMessage: string): Boolean;
begin
  Result := LaunchDetached('xdg-open', [PathName], ErrorMessage);
end;

function VisualDiff(const LeftPath, RightPath: string;
  out ErrorMessage: string): Boolean;
begin
  Result := LaunchDetached('meld', [LeftPath, RightPath], ErrorMessage);
end;

end.
