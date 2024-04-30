{$APPTYPE CONSOLE }


uses madExcept, madLinkDisAsm, madListHardware, madListProcesses, madListModules, Windows, SysUtils;

procedure InitHosted (tid, port: DWORD); stdcall; external 'chdip.dll';
function GetUnloadFlag: PBoolean; stdcall; external 'chdip.dll';

var

    fUnload: PBoolean;
    port: DWORD = 0;
    e: Integer;
    s: String;
begin
 s := ParamStr (1);
 if s <> '' then Val (s, port, e);
 InitHosted (GetCurrentThreadId, port);
 fUnload := GetUnloadFlag;
 if fUnload <> nil then
  repeat 
   Sleep (500);
   if not Assigned (fUnload) then break;
  until fUnload^ = TRUE;
 if Assigned (fUnload) then fUnload^ := TRUE;
 Sleep (500);
end.