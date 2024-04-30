unit spthread;

interface

uses
  Classes, Windows, SysUtils;

type
  TSupThread = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

var
   spcmd, specho: dword;
   sthrd : TSupThread;
   survive: boolean;

procedure     KillThread;
procedure     KillCtrls;

implementation
uses ChConst, ChTypes, ChShare, ChForm, ChConsole, Messages, ChMsg, Misk, ChClient;
var
   fwnd, hwnd, mwnd : THandle;
   wstyle: DWORD;

procedure     KillCtrls;
begin
 if (hwnd <> 0) then DestroyWindow (hwnd);
 if (mwnd <> 0) then DestroyWindow (mwnd);
 hwnd := 0;
 mwnd := 0;
end;


procedure TSupThread.Execute;
var msg: tagMSG;
    tout: dword;
begin
 exit;
 wstyle := WS_CHILD or ES_MULTILINE or ES_WANTRETURN or WS_VSCROLL;
 survive := true;
 hwnd := 0;
 mwnd := 0;
 fwnd := 0;
 tout := GetTickCount;
 { Place thread code here }
 if (csm <> nil) then
 repeat
  if (hwnd) <> 0 then
     begin
      while PeekMessage (msg, 0, 0, WM_USER, PM_REMOVE) do
       begin
        TranslateMessage (msg);
        if (msg.message <> WM_ERASEBKGND) then
            DispatchMessage (msg);
       end;
     end;
   case spcmd of
    CM_CRWIN:
       begin
        {
        fwnd := WindowFromPoint (Point (0, 0));
        mwnd := CreateWindowEx (WS_EX_NOPARENTNOTIFY, 
                                'STATIC', '',
                               CS_SAVEBITS or CS_VREDRAW or CS_HREDRAW or  
                               WS_CHILD or SS_OWNERDRAW
                               ,
                               0, 0, ConWidth, ConHeight,
                               fwnd, 0, HINSTANCE, nil);
        SetParent (mwnd, fwnd);
        ShowWindow (mwnd, SW_SHOW);
        SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or
                     SWP_NOSIZE or SWP_NOACTIVATE);
        PostMessage (mwnd, WM_ACTIVATE, WA_INACTIVE, 0);
        hwnd := CreateWindowEx (WS_EX_TRANSPARENT or WS_EX_NOPARENTNOTIFY
                  , 'EDIT', '>',
                 wstyle,
                 1, 390, 10, 20,
                 GetForegroundWindow, 0, HINSTANCE, nil);
        SetParent (hwnd, GetForegroundWindow);
        ShowWindow (hwnd, SW_SHOW);
        PostMessage (hwnd, WM_SETFOCUS, fwnd, 0); // Установить фокуз
        if (hwnd > 0) then
           PeekMessage (msg, hwnd, 0, WM_USER, PM_REMOVE);
        DispatchMessage (msg);
        SetActiveWindow (hwnd);
        SetForegroundWindow (hwnd);
        SetFocus (hwnd); { Установить фокуз дополнительно }
        specho := 1;
        spcmd := 0;
       end;
    CM_CLWIN:
    if false then
       begin
        tout := 0;  {
        // Поглощение введенных символов
        while PeekMessage (msg, mwnd, 0, WM_USER, PM_REMOVE) and (tout < 20) do
          begin
           TranslateMessage (msg);
           DispatchMessage (msg);
           inc (tout);
          end;
        KillCtrls;{}
        spcmd := 0;
        specho := 1;
        break; // Выход из цикла
       end;
   end; // case
   sleep (20); // wait for change cmd
 until terminated;
 survive := false;
 if (tout = 0) then exit;
end;

procedure     KillThread;
 begin
  if not Assigned (sthrd) then exit;
  sthrd.Terminate;
  if WaitForSingleObject (sthrd.Handle, 500) = WAIT_TIMEOUT then
     TerminateThread (sthrd.Handle, 0);
 end;

end.
