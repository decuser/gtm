program ncurses_input_test;

{$mode objfpc}{$H+}

uses
  SysUtils, Video, ncurses;

const
  AttrNormal = $07;
  AttrTitle = $1F;

procedure PutCell(X, Y: Integer; C: Char; Attr: Byte);
var
  P: Integer;
begin
  if (X < 0) or (Y < 0) or
     (X >= Integer(ScreenWidth)) or (Y >= Integer(ScreenHeight)) then
    Exit;
  P := Y * Integer(ScreenWidth) + X;
  VideoBuf^[P] := Ord(C) + (Word(Attr) shl 8);
end;

procedure PutText(X, Y: Integer; const S: string; Attr: Byte);
var
  I: Integer;
begin
  for I := 1 to Length(S) do
  begin
    if X + I - 1 >= Integer(ScreenWidth) then
      Break;
    PutCell(X + I - 1, Y, S[I], Attr);
  end;
end;

procedure ClearBuffer;
var
  X, Y: Integer;
begin
  for Y := 0 to Integer(ScreenHeight) - 1 do
    for X := 0 to Integer(ScreenWidth) - 1 do
      PutCell(X, Y, ' ', AttrNormal);
end;

function PrintableKey(K: LongInt): string;
begin
  if (K >= 32) and (K <= 126) then
    Result := Chr(K)
  else if K = 27 then
    Result := 'Esc'
  else if K = 10 then
    Result := 'LF'
  else if K = 13 then
    Result := 'Enter'
  else
    Result := '(special/control)';
end;

var
  Win: PWINDOW;
  K: LongInt;
  Running: Boolean;
begin
  InitVideo;
  Win := initscr;
  cbreak;
  noecho;
  keypad(Win, True);
  curs_set(0);

  try
    Running := True;
    while Running do
    begin
      ClearBuffer;
      PutText(1, 0, 'Video drawing + ncurses input test', AttrTitle);
      PutText(1, 2, 'Press keys. Esc exits on ONE press.', AttrNormal);
      PutText(1, 3, 'Try arrows, Ctrl+arrows, Home/End, Ctrl+Home/End, PgUp/PgDn.', AttrNormal);
      PutText(1, 5, 'Waiting...', AttrNormal);
      UpdateScreen(False);

      K := wgetch(Win);

      ClearBuffer;
      PutText(1, 0, 'Video drawing + ncurses input test', AttrTitle);
      PutText(1, 2, 'ncurses code: ' + IntToStr(K), AttrNormal);
      PutText(1, 3, 'hex:          $' + IntToHex(K, 4), AttrNormal);
      PutText(1, 4, 'key:          ' + PrintableKey(K), AttrNormal);
      PutText(1, 6, 'Press another key. Esc exits.', AttrNormal);
      UpdateScreen(False);

      if K = 27 then
        Running := False;
    end;
  finally
    endwin;
    DoneVideo;
    Write(#27'[2J'#27'[H'#27'[?25h');
    Flush(Output);
  end;
end.
