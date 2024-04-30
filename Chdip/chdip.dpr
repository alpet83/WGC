library chdip;
{$WARN SYMBOL_PLATFORM OFF}
{$WARN IMPLICIT_STRING_CAST OFF}
{%ToDo 'chdip.todo'}

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  SysUtils,
  Classes,
  Windows,
  Misk in '..\misk.pas',
  ChCmd in '..\chcmd.pas',
  ChShare in '..\chshare.pas',
  ChThread in 'ChThread.pas',
  timerts in '..\timerts.pas',
  ChAlgs in 'scaners\ChAlgs.pas',
  ChSrch in 'scaners\ChSrch.pas',
  ChPlugin2 in 'scaners\ChPlugin2.pas',
  chhook in '..\chhook.pas',
  StrSrv in '..\StrSrv.pas',
  ChConst in '..\ChConst.pas',
  ChStat in 'scaners\ChStat.pas',
  MemMap in 'scaners\MemMap.pas',
  ChTypes in '..\ChTypes.pas',
  ChStorage in 'scaners\ChStorage.pas',
  ChHeap in '..\ChHeap.pas',
  mirror in 'scaners\mirror.pas',
  ChLog,
  ChSettings in '..\Frames\ChSettings.pas',
  netipc in '..\Common\netipc.pas',
  SocketAPI in '..\Common\socketapi.pas',
  TlHelpEx in '..\TlHelpEx.pas',
  ChIcons in '..\Common\ChIcons.pas',
  WatchTable in 'WatchTable.pas',
  ChValues in '..\Common\ChValues.pas',
  ChPointers in '..\Common\ChPointers.pas',
  ChServer in '..\Common\ChServer.pas',
  PSLists in '..\Common\PSLists.pas',
  ChPSinfo in 'ChPSinfo.pas',
  LocalIPC in '..\Common\LocalIPC.pas',
  SimpleArray in '..\Common\SimpleArray.pas',
  ShareData in '..\Common\ShareData.pas',
  DataProvider in '..\Common\DataProvider.pas',
  ConThread in '..\Console\ConThread.pas',
  ChStrings in '..\Common\ChStrings.pas',
  vconsole in '..\Console\vconsole.pas',
  conmgr in '..\Console\conmgr.pas';

{$E .dll}

{$R ..\wgc.res}

var
   ok: boolean;
   ent_count: Integer = 0;

procedure WaitIdle; stdcall; export;
var
   msg : tagMsg;
begin
 repeat
  GetMessage (msg, 0, 0, 0);
  Sleep (100);
 until false;
end; // WaitIdle

procedure InitHosted (tid, port: DWORD); stdcall;
begin
 if port <> 0 then ServerPort := port;
 LogStr (format ('Library initialized by host, with tid = $%x', [tid]));
 bHosted := TRUE;
 host_tid := tid;
end;

function GetUnloadFlag: PBoolean; stdcall;
begin
 result := @bStopping;
end;

procedure SpyStart; stdcall; export;
var tid: DWORD;
begin
 if ent_count > 0 then Exit;
 Inc (ent_count);
 ssm := nil;
 IsMultiThread := true;
 ok := DisableThreadLibraryCalls (GetModuleHandle (PChar (MAINLIB)));
 hStartupEvent := CreateEvent (nil, TRUE, FALSE, nil);
 OutputDebugString ('Creating main message thread'#13#10);
 hServerThread := BeginThread  (nil, 0,
                                @PrimaryThreadProc,
                                nil, 0, tid);
 SetThreadPriority (hServerThread, THREAD_PRIORITY_HIGHEST);                                
end; // SpyStart;



exports
          SpyStart name 'SpyStart',
          WaitIdle name 'WaitIdle',
          InitHosted name 'InitHosted',
          GetUnloadFlag name 'GetUnloadFlag';

begin
 SpyStart;
end.

