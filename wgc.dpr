program wgc;

{$WARN IMPLICIT_STRING_CAST OFF}
uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Forms,
  Windows,
  Dialogs,
  Controls,
  SysUtils,
  Messages,
  Misk,
  ChTypes,
  ChForm in 'ChForm.pas' {MForm},
  ChCmd in 'ChCmd.pas',
  ChAbout in 'ChAbout.pas' {AboutBox},
  ChDecomp in 'ChDecomp.pas',
  ChText in 'ChText.pas' {medit},
  ChLang in 'ChLang.pas',
  TlHelpEx in 'TlHelpEx.pas',
  ChCodes in 'ChCodes.pas' {fcodes},
  StrSrv in 'StrSrv.pas',
  ChHelp in 'ChHelp.pas' {HelpForm},
  ChPlugin in 'ChPlugin.pas',
  ChShare in 'ChShare.pas',
  vmisk in 'vmisk.pas',
  ConfDlg in 'Dialogs\ConfDlg.pas' {ConfirmDlg},
  ChMsg in 'ChMsg.pas',
  ChSpy in 'ChSpy.pas',
  ChView in 'Dialogs\ChView.pas' {GVfo rm},
  ChConsole in 'ChConsole.pas',
  spthread in 'spthread.pas',
  mirror in 'Chdip\scaners\mirror.pas',
  ChSimp in 'ChSimp.pas' {sform},
  Scandlg in 'Dialogs\Scandlg.pas' {scpdlg},
  ChBtns in 'ChBtns.pas',
  ChConst in 'ChConst.pas',
  Prcsmap in 'prcsmap.pas',
  ChTrain in 'ChTrain.pas' {FormConstructor},
  engine in 'Engine\engine.pas',
  gtrainer in 'Engine\gtrainer.pas',
  rects in 'Common\rects.pas',
  ChModeDlg in 'Dialogs\ChModeDlg.pas' {ModeSelDlg},
  ListViewXP in 'Common\ListViewXP.pas',
  HotKeyDlg in 'Dialogs\HotKeyDlg.pas' {HKeyDlg},
  KbdAPI in 'Common\KbdAPI.pas',
  conapi in 'Console\conapi.pas',
  wconapi in 'Console\wconapi.pas',
  gditools in 'Common\gditools.pas',
  KbdDefs in 'Common\KbdDefs.pas',
  strtools in 'Common\strtools.pas',
  ChOptions in 'Frames\ChOptions.pas' {frmOptions: TFrame},
  ChSettings in 'Frames\ChSettings.pas',
  CheatTable in 'Frames\CheatTable.pas' {frmAddrs},
  ChLog in 'ChLog.pas',
  netipc in 'Common\netipc.pas',
  SocketAPI in 'Common\socketapi.pas',
  ChIcons in 'Common\ChIcons.pas',
  ChValues in 'Common\ChValues.pas',
  ChPointers in 'Common\ChPointers.pas',
  ChClient in 'Common\ChClient.pas',
  ChPStools in 'Chdip\ChPStools.pas',
  SimpleArray in 'Common\SimpleArray.pas',
  PSLists in 'Common\PSLists.pas',
  ShareData in 'Common\ShareData.pas',
  LocalIPC in 'Common\LocalIPC.pas',
  DataProvider in 'Common\DataProvider.pas',
  splash in 'splash.pas' {frmSplash},
  ChStrings in 'Common\ChStrings.pas',
  ConThread in 'Console\ConThread.pas',
  winfuncs in 'Common\winfuncs.pas',
  vconsole in 'Console\vconsole.pas',
  conmgr in 'Console\conmgr.pas';

{$R *.RES}
{$R \Res\help.res}
{$R \Res\hints.res}
{$R \Res\toolbar.res}
{$R \Res\visual.res}

function AlreadyLoaded: Boolean;
var  wgc_copy, n: Integer;
     s, ps: String;
     pc: WFILE_PATH;
begin
 // psArray - global variable, and may be used outside this function
 wgc_copy := 0;
 psArray := TProcessArray.Create(256);
 psArray.Clear;
 psArray.Update; // copy check
 GetModuleFileName (0, pc, 260);
 s := LowerCase (ExtractFileName (pc));
 LogStr ('Checking for already loading client', TRUE, TRUE);
 for n := 0 to psArray.ItemsCount - 1 do
 with psArray [n] do
 begin
  ps := LowerCase (szExeFile);
  ps := ExtractFileName (ps);
  if s = ps then
    begin
     Inc (wgc_copy);
     LogStr (format ('PID=$%x ' + ps, [th32ProcessID]));
    end;
 end;
 LogStr ('Number of process ' + s + ' loaded = ' + IntToStr (wgc_copy));
 result := (wgc_copy > 1);
end;

procedure StartConsole;
var
   sTitle: String;
   cc: COORD;
   n: Integer;

begin
 AllocConsole;
 cc.x := 100;
 cc.Y := 70;
 SetConsoleScreenBufferSize (GetStdHandle (STD_OUTPUT_HANDLE), cc);
 sTitle := 'WGC CONSOLE ' + IntToHex(GetCurrentProcessId, 8);
 SetConsoleTitle (PChar(sTitle));
 n := 0;
 repeat
  Sleep (100);
  hConWnd := FindWindow (nil, PChar (sTitle));
  Inc (n);
 until (hConWnd <> 0) or (n > 10);
 SetConsoleTitle ('WGC Command console');
end;

var
   si: STARTUPINFO;
{$IFOPT D-}   pi: PROCESS_INFORMATION; {$ENDIF}
begin
 // con := TConsole.Create;
 sleep (100);
 GetStartupInfo (si);
 {$IFOPT D-}
 if si.wShowWindow <> SW_HIDE then
  begin
   FillChar (si, sizeof (si), 0);
   //si.lpDesktop := PChar ('Winsta0\Default');
   si.dwFlags := STARTF_USESHOWWINDOW;
   si.wShowWindow := SW_HIDE;
   si.cb := sizeof (si);
   FillChar (pi, sizeof (pi), 0);
   if CreateProcess (PChar (ParamStr (0)), nil, nil, nil, false, 0,
     nil, nil, si, pi) then exit;
  end else
 {$ENDIF}
 if AlreadyLoaded then
  begin
   Windows.Beep (1200, 1000);
   exit;
  end;
 StartConsole; 
 {$IFOPT D-}
 if hConWnd = 0 then exit;
 ShowWindow (hConWnd, SW_HIDE);
 {$ENDIF}
  ismultithread := true;  { }
  try
   Application.Initialize;
   Application.Title := 'Winner Game Cheater';
   Application.CreateForm(TMForm, MForm);
  Application.CreateForm(TfMessages, fMessages);
  Application.CreateForm(Tsform, sform);
  Application.CreateForm(Tscpdlg, scpdlg);
  Application.CreateForm(TfrmAddrs, frmAddrs);
  Application.CreateForm(TfrmSplash, frmSplash);
  mForm.AfterInit;
   Application.CreateForm(TFormConstructor, FormConstructor);
   Application.Run;
  except
   on EAccessViolation do
      showMessage ('Программа вызвала исключение и будет наказана');
  end;
  // ExitProcess (0);
  LogStrEx ('#NOTIFY: Application.Run exited.', 10);
end.
