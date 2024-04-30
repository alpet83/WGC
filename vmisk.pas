unit vmisk;

interface
uses StdCtrls, Controls, ComCtrls, Windows, Forms;

function     GetCtrl (name : string) : TControl;
procedure    GetChecked (name : string; var rslt : boolean);
procedure    LDelay (const msec : dword);
function     LoadStr (const id: dword): string;
function     ForceForegroundWindow(wnd: HWND): BOOL;
procedure     DockForm (form: TForm; parentCtrl: TWinControl);

implementation

uses ChForm, SysUtils;

procedure DockForm;
begin
 with form do
  begin
   BorderStyle := bsNone;
   Align := alTop;
   Parent := parentCtrl;
   Visible := true;
  end;
end;

function   LoadStr; // Загрузка строки из ресурса
var pc: array [0..32767] of AnsiChar;
     h: THandle;
     hinfo: dword;
     p: PAnsiChar;
begin
 result := '';
 StrPCopy (pc, '#' + IntToStr (id));
 hinfo := FindResourceA (HINSTANCE, pc, AnsiChar(RT_RCDATA) );
 h := LoadResource (HINSTANCE, hinfo);
 if (h > 0) then
  begin
   p := LockResource (h);
   result := p;
  end;
end;

procedure GetChecked;
var t : TControl;
begin
 t := GetCtrl (name);
 if (t <> nil) and (t is TCheckBox) then
  rslt := (t as TCheckBox).checked;
end; // GetChecked

function  GetCtrl;

procedure  _GetCtrl (const name : string; const start : TWinControl);
var n : dword;
begin
 for n := 1 to start.ControlCount do
  if start.Controls [n - 1].Name = name then
    result := start.Controls [n - 1] else
   begin
    if (start.controls [n - 1] is TWinControl) then
     _GetCtrl (name, (start.controls [n - 1] as TWinControl));
   end;
end;// _GetCtrl
begin
 result := nil;
 _GetCtrl (name, (mForm as TWinControl));
end; // GetCtrl


procedure       LDelay;
var n : dword;
begin
 for n := 1 to msec div 100 do
 begin
  sleep (100);
  Application.ProcessMessages;
 end;
end;

function ForceForegroundWindow(wnd: HWND): BOOL;
const
 SPI_GETFOREGROUNDLOCKTIMEOUT = $2000;
 SPI_SETFOREGROUNDLOCKTIMEOUT = $2001;
var
 OsVerInfo: TOSVersionInfo;
 Win32MajorVersion: Integer;
 Win32MinorVersion: Integer;
 Win32Platform: Integer;
 ForegroundThreadID: DWORD;
 ThisThreadID: DWORD;
 Timeout: DWORD;
begin
 OsVerInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
 GetVersionEx(osVerInfo);
 Win32MajorVersion := OsVerInfo.dwMajorVersion;
 Win32MinorVersion := OsVerInfo.dwMinorVersion;
 Win32Platform := OsVerInfo.dwPlatformId;
 if IsIconic(Wnd) then ShowWindow(Wnd, SW_RESTORE);
 if GetForegroundWindow = Wnd then Result := True
 else
 begin
   if ((Win32Platform = VER_PLATFORM_WIN32_NT) and (Win32MajorVersion > 4)) or
     ((Win32Platform = VER_PLATFORM_WIN32_WINDOWS) and ((Win32MajorVersion > 4)
       or ((Win32MajorVersion = 4) and (Win32MinorVersion > 0)))) then
   begin
     Result := False;
     ForegroundThreadID := GetWindowThreadProcessID(GetForegroundWindow, nil);
     ThisThreadID := GetWindowThreadPRocessId(Wnd, nil);
     if AttachThreadInput(ThisThreadID, ForegroundThreadID, True) then
     begin
       BringWindowToTop(Wnd);
       SetForegroundWindow(Wnd);
       AttachThreadInput(ThisThreadID, ForegroundThreadID, False);
       Result := (GetForegroundWindow = Wnd);
     end;
     if not Result then
     begin
       SystemParametersInfo(SPI_GETFOREGROUNDLOCKTIMEOUT, 0, @Timeout, 0);
       SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, TObject(0),
         SPIF_SENDCHANGE);
       BringWindowToTop(Wnd);
       SetForegroundWindow(Wnd);
       SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, TObject(Timeout),
                                                              SPIF_SENDCHANGE);
     end;
   end
   else
   begin
     BringWindowToTop(Wnd);
     SetForegroundWindow(Wnd);
   end;
   Result := (GetForegroundWindow = Wnd);
 end;
end; // End of function ForceForegroundWindow
end.
