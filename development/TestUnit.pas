unit TestUnit;

{$i crystal_options.inc}

interface
  uses
  {$ifdef MSWINDOWS}
  Windows,
  {$endif}
  SysUtils,
  CrystalLUA;



procedure RUN;
procedure ShowMessage(const S: string); overload;
procedure ShowMessage(const StrFmt: string; const Args: array of const); overload;

implementation

var
  Lua: TLua;


procedure RUN;
begin


  ShowMessage('Test');
end;

procedure ShowMessage(const S: string);
var
  BreakPoint: string;
begin
  BreakPoint := S;

  {$ifdef MSWINDOWS}
    Windows.MessageBox(0, PChar(BreakPoint), '���������:', 0);
  {$endif}

  Halt;
end;

procedure ShowMessage(const StrFmt: string; const Args: array of const);
begin
  ShowMessage(Format(StrFmt, Args));
end;

initialization
  LuaLibraryPath := '..\dll\' + LuaLibraryPath;
  Lua := CreateLua;

finalization
  Lua.Free;

end.