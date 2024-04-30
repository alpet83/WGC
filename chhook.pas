unit chhook;
interface
uses
  Windows,
  SysUtils,
  Messages,
  ChTypes,
  ChShare;

procedure  InstallTo (const tid : THandle); cdecl;

procedure  RemoveHook;

implementation
uses    Misk;

const
    HKINST = $3456789A;
    HKMSG = WM_NULL;
type
    PTagMsg = ^tagMSG;

var
      hhk: THandle = 0;
    first: bool = false;

function    HkGetMsgProc (code,
                wP, lp : LongInt ) : LongInt; stdcall;
var
   pmsg: PTagMsg;

begin
 pmsg := Pointer (lp);
 result := 0;
 if (hhk = 0) and (pmsg <> nil) and
       (pmsg.wParam = HKINST) and (pmsg.lParam <> 0) then
    begin
     hhk := pmsg.lparam;
     exit;   
    end;
 if hhk <> 0 then result := CallNextHookEx (hhk, code, wp, lp);
end;

procedure  InstallTo;
var
    hinst: DWORD;
     proc: Pointer;
     ccnt: DWORD;
  timeOut: dword;
    delay: dword;
begin
 if (tid = 0) then exit;
 if smobj = nil then exit;
 smobj.SpyVars.fSpyInit := true;
 hinst := HINSTANCE;
 proc := @HkGetMsgProc;
 smobj.CopyNum := 1;
 smobj.SpyVars.CanUnload := true;
 ccnt := smobj.CopyNum;
 hhk := SetWindowsHookEx (WH_GETMESSAGE, proc,
                          hinst, tid);
 smobj.spyvars.hhk := hhk;
 // Filling structure
 smobj.SpyVars.fHookMode := (hhk <> 0);
 smobj.SpyVars.fTimeOut := false;
 smobj.bUpload := false;
 PostMessage (smobj.prcs.hwnd, HKMSG, HKINST, hhk);
 timeOut := GetTickCount;
 delay := 100;
 smobj.SetInternalEvent (1, false);
 // ODS ('HHK = ' + dword2hex (hhk));
 if smobj.SpyVars.fHookMode then
 // ожидание загрузки
     smobj.WaitEvent (1, 2500);    
 // инициаци€ SpyMode
 smobj.SpyVars.fTimeOut := not smobj.bUpload; //  оличество либ не изменилось
 if smobj.bUpload then
  begin
   smobj.SpyVars.fSIS := true;
   smobj.SpyVars.fSpyMode := true;
   ods ('Time Installing Hook = ' + IntToStr (GetTickCount - timeOut));
  end
 else exit;
 // ожидание выхода
 smobj.SetInternalEvent (2, false);
 smobj.WaitEvent(2, INFINITE);
 timeOut := 0;
 smobj.fUnload := true; // ¬ыгрузить все остальные библиотеки 
 repeat
  sleep (delay);
  Inc (timeOut);
 until (ccnt = smobj.CopyNum) or (timeOut > 20);
 smobj.fUnload := false;
 // RemoveHook;
 ODS ('chdip.dll - Unhook Complete!');
end;

procedure removeHook;
begin
 if hhk <> 0 then UnhookWindowsHookEx (hhk);
 hhk := 0;
end;

end.

