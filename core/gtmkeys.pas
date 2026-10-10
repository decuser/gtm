unit gtmkeys;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TGTMKey = (
    gkNone,
    gkLeft, gkRight, gkUp, gkDown,
    gkHome, gkEnd, gkPageUp, gkPageDown,
    gkBackspace, gkEnter,
    gkF1, gkF2, gkF10
  );

  TGTMKeyModifier = (gkmCtrl, gkmShift, gkmAlt);
  TGTMKeyModifiers = set of TGTMKeyModifier;

  TGTMKeyAction = (
    gaNone,
    gaHelp,
    gaMenu,
    gaQuit,
    gaPreviousEntry,
    gaNextEntry,
    gaFirstEntry,
    gaLastEntry,
    gaParentDirectory,
    gaEnterDirectory,
    gaOpenFile,
    gaSaveFile,
    gaFileHistory,
    gaVisualDiff,
    gaMountCurrent,
    gaShowMounts,
    gaUnmountCurrent,
    gaUnmountAll,
    gaCommitBackward,
    gaCommitForward,
    gaTimeBackward,
    gaTimeForward,
    gaFirstCommit,
    gaLastCommit,
    gaLatestTime,
    gaEarliestTime
  );

function GTMMainKeyAction(Key: TGTMKey; Ch: Char;
  Modifiers: TGTMKeyModifiers): TGTMKeyAction;
procedure BuildGTMMainKeyBindingLines(Lines: TStrings);

implementation

type
  TGTMKeyBinding = record
    Key: TGTMKey;
    Ch: Char;
    Modifiers: TGTMKeyModifiers;
    Action: TGTMKeyAction;
    KeyLabel: ShortString;
    ActionLabel: ShortString;
    ShowInHelp: Boolean;
  end;

const
  MainBindings: array[0..30] of TGTMKeyBinding = (
    (Key:gkF1;        Ch:#0;  Modifiers:[];        Action:gaHelp;             KeyLabel:'F1';          ActionLabel:'Key bindings';                 ShowInHelp:True),
    (Key:gkF2;        Ch:#0;  Modifiers:[];        Action:gaMenu;             KeyLabel:'F2';          ActionLabel:'Menu';                         ShowInHelp:True),
    (Key:gkF10;       Ch:#0;  Modifiers:[];        Action:gaQuit;             KeyLabel:'F10';         ActionLabel:'Quit';                         ShowInHelp:True),

    (Key:gkUp;        Ch:#0;  Modifiers:[];        Action:gaPreviousEntry;    KeyLabel:'Up';          ActionLabel:'Previous entry';               ShowInHelp:True),
    (Key:gkDown;      Ch:#0;  Modifiers:[];        Action:gaNextEntry;        KeyLabel:'Down';        ActionLabel:'Next entry';                   ShowInHelp:True),
    (Key:gkHome;      Ch:#0;  Modifiers:[];        Action:gaFirstEntry;       KeyLabel:'Home';        ActionLabel:'First entry';                  ShowInHelp:True),
    (Key:gkEnd;       Ch:#0;  Modifiers:[];        Action:gaLastEntry;        KeyLabel:'End';         ActionLabel:'Last entry';                   ShowInHelp:True),
    (Key:gkLeft;      Ch:#0;  Modifiers:[];        Action:gaParentDirectory;  KeyLabel:'Left';        ActionLabel:'Parent directory';             ShowInHelp:True),
    (Key:gkBackspace; Ch:#0;  Modifiers:[];        Action:gaParentDirectory;  KeyLabel:'Backspace';   ActionLabel:'Parent directory';             ShowInHelp:True),
    (Key:gkRight;     Ch:#0;  Modifiers:[];        Action:gaEnterDirectory;   KeyLabel:'Right';       ActionLabel:'Enter directory';              ShowInHelp:True),
    (Key:gkEnter;     Ch:#0;  Modifiers:[];        Action:gaEnterDirectory;   KeyLabel:'Enter';       ActionLabel:'Enter directory';              ShowInHelp:True),

    (Key:gkNone; Ch:'o'; Modifiers:[]; Action:gaOpenFile;       KeyLabel:'o'; ActionLabel:'Open selected file';             ShowInHelp:True),
    (Key:gkNone; Ch:'O'; Modifiers:[]; Action:gaOpenFile;       KeyLabel:'O'; ActionLabel:'Open selected file';             ShowInHelp:False),
    (Key:gkNone; Ch:'s'; Modifiers:[]; Action:gaSaveFile;       KeyLabel:'s'; ActionLabel:'Save selected file';             ShowInHelp:True),
    (Key:gkNone; Ch:'S'; Modifiers:[]; Action:gaSaveFile;       KeyLabel:'S'; ActionLabel:'Save selected file';             ShowInHelp:False),
    (Key:gkNone; Ch:'h'; Modifiers:[]; Action:gaFileHistory;    KeyLabel:'h'; ActionLabel:'File history';                   ShowInHelp:True),
    (Key:gkNone; Ch:'H'; Modifiers:[]; Action:gaFileHistory;    KeyLabel:'H'; ActionLabel:'File history';                   ShowInHelp:False),
    (Key:gkNone; Ch:'v'; Modifiers:[]; Action:gaVisualDiff;     KeyLabel:'v'; ActionLabel:'Visual diff vs predecessor';     ShowInHelp:True),
    (Key:gkNone; Ch:'V'; Modifiers:[]; Action:gaVisualDiff;     KeyLabel:'V'; ActionLabel:'Visual diff vs predecessor';     ShowInHelp:False),
    (Key:gkNone; Ch:'m'; Modifiers:[]; Action:gaMountCurrent;   KeyLabel:'m'; ActionLabel:'Mount current snapshot';         ShowInHelp:True),
    (Key:gkNone; Ch:'M'; Modifiers:[]; Action:gaShowMounts;     KeyLabel:'M'; ActionLabel:'Show mounted snapshots';         ShowInHelp:True),
    (Key:gkNone; Ch:'u'; Modifiers:[]; Action:gaUnmountCurrent; KeyLabel:'u'; ActionLabel:'Unmount current snapshot';       ShowInHelp:True),
    (Key:gkNone; Ch:'U'; Modifiers:[]; Action:gaUnmountAll;     KeyLabel:'U'; ActionLabel:'Unmount all snapshots';          ShowInHelp:True),

    (Key:gkLeft;     Ch:#0; Modifiers:[gkmCtrl]; Action:gaCommitBackward; KeyLabel:'Ctrl-Left';      ActionLabel:'Previous commit';              ShowInHelp:True),
    (Key:gkRight;    Ch:#0; Modifiers:[gkmCtrl]; Action:gaCommitForward;  KeyLabel:'Ctrl-Right';     ActionLabel:'Next commit';                  ShowInHelp:True),
    (Key:gkUp;       Ch:#0; Modifiers:[gkmCtrl]; Action:gaTimeBackward;   KeyLabel:'Ctrl-Up';        ActionLabel:'Earlier time';                 ShowInHelp:True),
    (Key:gkDown;     Ch:#0; Modifiers:[gkmCtrl]; Action:gaTimeForward;    KeyLabel:'Ctrl-Down';      ActionLabel:'Later time';                   ShowInHelp:True),
    (Key:gkHome;     Ch:#0; Modifiers:[gkmCtrl]; Action:gaFirstCommit;    KeyLabel:'Ctrl-Home';      ActionLabel:'First commit';                 ShowInHelp:True),
    (Key:gkEnd;      Ch:#0; Modifiers:[gkmCtrl]; Action:gaLastCommit;     KeyLabel:'Ctrl-End';       ActionLabel:'Last commit';                  ShowInHelp:True),
    (Key:gkPageUp;   Ch:#0; Modifiers:[gkmCtrl]; Action:gaLatestTime;     KeyLabel:'Ctrl-PageUp';    ActionLabel:'Latest time';                  ShowInHelp:True),
    (Key:gkPageDown; Ch:#0; Modifiers:[gkmCtrl]; Action:gaEarliestTime;   KeyLabel:'Ctrl-PageDown';  ActionLabel:'Earliest time';                ShowInHelp:True)
  );

function BindingMatches(const B: TGTMKeyBinding; Key: TGTMKey; Ch: Char;
  Modifiers: TGTMKeyModifiers): Boolean;
var
  EffectiveModifiers: TGTMKeyModifiers;
begin
  EffectiveModifiers := Modifiers;

  { For printable character bindings, case already represents Shift.
    Treat 'M' as the binding, not "Shift + M" as a separate modifier chord. }
  if Ch <> #0 then
    Exclude(EffectiveModifiers, gkmShift);

  Result := (B.Modifiers = EffectiveModifiers) and
    (((B.Key <> gkNone) and (B.Key = Key)) or
     ((B.Ch <> #0) and (B.Ch = Ch)));
end;

function GTMMainKeyAction(Key: TGTMKey; Ch: Char;
  Modifiers: TGTMKeyModifiers): TGTMKeyAction;
var
  I: Integer;
begin
  Result := gaNone;
  for I := Low(MainBindings) to High(MainBindings) do
    if BindingMatches(MainBindings[I], Key, Ch, Modifiers) then
      Exit(MainBindings[I].Action);
end;

procedure BuildGTMMainKeyBindingLines(Lines: TStrings);
var
  I: Integer;
begin
  if Lines = nil then
    Exit;

  Lines.Clear;
  for I := Low(MainBindings) to High(MainBindings) do
    if MainBindings[I].ShowInHelp then
      Lines.Add(MainBindings[I].KeyLabel +
        StringOfChar(' ', 16 - Length(MainBindings[I].KeyLabel)) +
        MainBindings[I].ActionLabel);
end;

end.
