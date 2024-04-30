unit ChSpy;

interface
uses Windows, Messages, SysUtils, Classes, Forms,
     TlHelp32, ExtCtrls, prcsmap, ChAbout,
     ChShare, ChTypes;

var
     ffbreak : boolean;
     spyWait : boolean = false;
    hSpyThrd : THandle;

// procedure  InfiltrateHook;
// function   InfiltrateDebug: Boolean;
procedure  SetSpyPrior (p : integer);
procedure  SuspendSpy;
procedure  ResumeSpy;


implementation
uses Misk, ChForm, ChCmd, TimeRTS, ChMsg,
        ChConst, ChHeap, ChClient;


procedure  SetSpyPrior;
begin
 if hspyThrd = 0 then exit;
 SetThreadPriority (hspyThrd, p);
end;

procedure  SuspendSpy;
 begin
  if hspyThrd = 0 then exit;
  SuspendThread (hspyThrd);
 end;

procedure  ResumeSpy;
 begin
  if hspyThrd = 0 then exit;
  while (ResumeThread (hspyThrd) > 0) do;
 end;

var
    SpyEntry : pointer;     
   InflBase : pointer;
    ProcLen : dword;
    LoadLib,
    GetProcA : pointer;


procedure  SpyCODE; assembler; stdcall;
// ��� ������������
asm
 pushad
 mov   edi, InflBase // ����� ��������� 
 mov   ebx, offset @SpyStart // begin of SpyCode
 mov   ecx, ebx
 xor   edx, edx
 // LibName offset correcting (chdip.dll)
 mov   eax, offset @libName  // nowstate code
 mov   dl, 1                 // ��������� �������� push
 call  @corr                 // ���������������
 // ������������� �������� call dword ptr [LoadLib]
 mov   ebx, offset @Call_proc0  // nowstate code offset
 mov   eax, offset @Proc0       // nowstate data offset
 mov   dl, 2                    // ��������� �������� call
 call  @corr                    // ���������������
 // ������������� �������� push offset Procname (SpyStart)
 // ������ �������� spy �������� ����� 'SpyStart' � 'chlib.dll'
 mov   ebx, offset @Push_procName // nowstate code offset
 mov   eax, offset @ProcName     // nowstate data offset
 mov   dl, 1                     // ��������� �������� push
 call  @corr                     // ���������������
 // ������������� �������� call dword ptr [GetProcAddr]
 mov   ebx, offset @call_proc1   // nowstate code offset
 mov   eax, offset @proc1        // nowstate data offset
 mov   dl, 2
 call  @corr
 // LoadLibraryPtr
 mov   ebx, offset @proc0
 mov   eax, LoadLib
 mov   dword ptr [ebx], eax   // @LoadLibraryPtr
 // GetProcAddressPtr
 mov   ebx, offset @proc1
 mov   eax, GetProcA
 mov   dword ptr [ebx], eax
 // procedure length calculating
 mov   eax, offset @SpyEnd
 sub   eax, ecx
 or    al, 3   // dword...
 inc   eax      // boundary
 mov   ProcLen, eax
 mov   SpyEntry, ecx
 popad
 jmp      @SpyEnd
// Correct small proc
@Corr:
 sub   eax, ecx
 add   eax, edi
 mov   dword ptr [ebx + edx], eax 
 ret
// Begining SpyCode
@SpyStart:
 push     offset @LibName       // ���������������� �������� libname
@Call_Proc0:
 call     dword ptr [@Proc0]  // LoadLibrary
@Push_ProcName:
 push     offset @ProcName     // ����������������� �������� procname
 push     eax                  // ���������� ����������
@Call_Proc1:
 call     dword ptr [@Proc1]   // GetProcAddress
 call     eax                  // @SpyStart
@self:
 dd       90909090h     // 4 x nop
 jmp      @self
@Proc0:    dd        0           // LoadLibraryA
@Proc1:    dd        0           // GetProcAddress
@LibName:  db        'CHDIP.DLL', 00
@ProcName: db        'WaitIdle', 00
@SpyEnd:   nop
end; // SpyCODE
(*
procedure  InfiltrateHook;
var
    timeOut, n : word;          
begin
 SetPriorityClass (_alias, HIGH_PRIORITY_CLASS);
 SendMsg (CM_HOOK);
 SetPriorityClass (GetCurrentProcess, NORMAL_PRIORITY_CLASS);
 AddMsg ('��������� � ������� �������:');
 AddMsg (' ...');
 timeOut := 0;
 csm.spyvars.fTimeOut := false;
  while (csm.CopyNum < 2) and (timeOut < 40) and
         (not csm.SpyVars.fSpyMode) do
   begin
    UpdLastMsg (format ('�������� �������� %.2f ���.', [timeOut * 10 * 0.01]));
    if timeOut and 3 = 0 then Application.ProcessMessages;
    inc (timeOut);
    csm.WaitEvent (1, 100);
   end;
 if (csm.SpyVars.fSpyMode) then
    begin
     hSpyThrd := 0;
     n := csm.ActiveClient;
     if (n > 0) then
      begin
       DuplicateHandle (
         GetCurrentProcess, csm.clients [n].hThread,
         GetCurrentProcess, @hSpyThrd, THREAD_ALL_ACCESS,
                         LongBool (false), 0);
        inc (ThrdCount);
        ThrdArray [ThrdCount].h := hSpyThrd;
        SendMsg (CM_UPDMAP);
        AddMsg ('��������� ��������� �������.');
      end;
     //ListModules;
    end
  else
 if (csm.SpyVars.fTimeOut) then
    AddMsg ('������� ��������� �� �������, ������� �� chdip.dll');
 SetPriorityClass (_alias, NORMAL_PRIORITY_CLASS);
 {$IFOPT D+} AddMsg ('InfiltrateHook.end');{$ENDIF}
end; // Infiltrate
(**)
(*
function  InfiltrateDebug;
type
    TVector = array [0..1024] of byte;
    PVector = ^TVector;
    PD = ^LongInt;
var
   vb : PVector;


var p : pointer;
    w : dword;
    nc, c : TContext;
        h : THandle;
        n : dword;
    pr, ppr : dword;
    vstack : array [0..4095] of byte;


begin
 result := false;
 if ThrdCount = 0 then // ���� ������� ��� �� "������������"
   begin
    DebugSelected;
    Sleep (1000);
   end;
 if (Attached = 0) or (ThrdCount = 0) then exit; // ���� �������� �� ������� ����������
 if csm.Svars.alias = 0 then exit;
 // ��������� ���������� �������� �������
 h := GetModuleHandle ('KERNEL32.DLL');
 LoadLib := GetProcAddress (h, 'LoadLibraryA');
 GetProcA := GetProcAddress (h, 'GetProcAddress');
 // ���� �� ������� �������� - �����
 if (LoadLib = nil) or (GetProcA = nil) then exit;
 DeleteLost;  // ������� �� ������ ������� �������������
 UpdateBtns;  // �������� ��� ������
 if (ThIndex <= 0) or (ThIndex > ThrdCount) then ThIndex := ThrdCount;
 vb := @SpyCode;
 n := dword (vb) and $FFFFF000; // ���������� �� ��������
 vb := ptr (n);
 // ���������� ������ - ������
 if VirtualProtect(vb, 8192, PAGE_EXECUTE_READWRITE, @w) then;
 
 if (csm.ActiveClient > 0) then KillLibs; // ����� ������� ����������
 if cThread = 0 then cThread := ThrdArray [ThIndex].h;
 if cThread <> 0 then
  begin
   SuspendThread (cThread); // Last Suspending
   c.ContextFlags :=  CONTEXT_FLOATING_POINT or
                      CONTEXT_control or CONTEXT_FULL;
   // ��������� �������� ������ ����� ������� ������������ ������������                   
   GetThreadContext (cThread, c);
   nc := c;
   // �������� ������� ������������
   p := VirtualAllocEx (_alias, nil, 4096, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE );
   if p <> nil then AddMsg ('����� ���������: ' + dword2hex (dword (p))) else  exit;
   nc.eip := dword (p);                // ���������� EIP �� �������� ������������
   InflBase := p;
   SpyCode; // ��������� ���������� ������������
   if (SpyEntry = nil) or (procLen = 0) then exit; // Fail!
   if (p <> nil) then if c.Eip = 0 then SpyCode;
   vb := SpyEntry;
   WriteProcessMemory (_alias, p, vb, ProcLen, w);
   p := Ptr (c.Esp - 2048);
   // ���������� ����� ����������
   ReadProcessMemory (_alias, p, @vstack, 4096, w);
   SpyWait := true; // ���� ��������
   pr := GetThreadPriority (cThread);   // ������� ��������� ������
   SetThreadContext (cThread, nc);      // ������ ����� ��������
   ppr := GetPriorityClass (csm.SVars.alias); // ��������� ����� ���������� ��������
   SetThreadPriority (cThread, THREAD_PRIORITY_TIME_CRITICAL); // ������� ����� �������� ������
   ShowContext (ThIndex); // �������� �������� ������
   // ������� ��������� ���� ������� �������
   csm.SpyVars.fSpyInit := true;
   ResumeThread (cThread);      // ������������� ������ � ������ �����
   PostMessage (csm.prcs.hwnd, WM_USER, $EEEAAA0, 0); // ������ ��������� ������
   AddMsg ('���� ������ �� ���������� ����������� �� ���� ����� �������.');
   csm.svars.fbreak := false;
   AddMsg ('������� �������...');
   n := 0;
   repeat
    Sleep (10);
    Application.ProcessMessages;
    Inc (n);
   until csm.SpyVars.fSpyMode or csm.svars.fbreak or (n >= 500);
   SuspendThread (cThread);
   if csm.SpyVars.fSpyMode then addMsg ('��������� ���������.');
   if csm.svars.fbreak then addMsg ('��������� ��������.');
   if (n >= 500) and (not csm.SpyVars.fSpyMode) then
       addMsg ('������� ��� ���������!');
   // �������������� ���������� ������
   SetThreadPriority (cThread, pr);
   // �������������� ���������� ����������
   SetPriorityClass (csm.SVars.alias, ppr);
   p := Ptr (nc.Esp - 2048);
   // �������������� ����� ����� ����������
   WriteProcessMemory (_alias, p, @vstack, 4096, w);
   c.ContextFlags :=  CONTEXT_FLOATING_POINT or CONTEXT_CONTROL or context_full;
   SetThreadContext (cThread, c); // �������������� ���������
   ResumeThread (cThread);        // ������������� ������ �� ������� �����
   SetSpyPrior (THREAD_PRIORITY_NORMAL);  // ��������� ������
   UpdateBtns;                          // ���������� ������
   ShowContext (ThIndex);
  end;
 n := csm.activeClient;
 if (n > 0) then
 if (csm.clients [n].hThread <> 0) then
 // ������� ���������� ������ ��������� ��� WGC 
  DuplicateHandle (csm.svars.alias, csm.clients [n].hThread, GetCurrentProcess, @csm.clients [n].hThread,
                   THREAD_ALL_ACCESS, false, 0);
end; // Infiltrate
(**)
end.

