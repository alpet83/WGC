unit ShareData;

interface

uses Windows;

const
    SHAREDATASIZE = 256 * 1024 - 256;
      _RECVEVENT = 2;
      _SENDEVENT = 3;
      FREADPEEK = 4;
type
    TSyncRec = packed record
    // ������� �������� ������
        hMutex: THandle;
    // hConEvent: THandle; // ������� �������������
    hRecvEvent: THandle; // ������� ��������� ������
    hSendEvent: THandle;
    end;

    TShareDataRec = packed record
    { ��� ��������� ����������� ����� ���������� }
       iCount: Integer;
       Index: Integer;
      refCount: DWORD;
      ownerTID: DWORD;  // ������� ����� ��������
      ownerPID: DWORD;  // ��. �������� ���������
          hWnd: HWND;
            sr: TSyncRec;
     data: array [0..SHAREDATASIZE] of Byte;
    end;

    PShareDataRec = ^TShareDataRec;

    TShareData = class
    protected
     pdatarec: PShareDataRec;
     lockCount: Integer;
    public
     syncrec: TSyncrec;
     hFileMapping: THandle;
     sIdent: String;
     bOwned: Boolean; // ����������� ������ ��������
     constructor        Create (globalName: PAnsiChar; const ident: String);
     destructor         Destroy; override;
     procedure          AddRef;
     function           GetCount: DWORD;
     function           GetRefCount: DWORD;
     function           NeedUnlock: Boolean;
     function           Optimize (lockTimeOut: DWORD): Boolean;
     function           Read(var buff; Count: DWORD; flags: DWORD = 0): Integer;
     procedure          SetHWnd (hWnd: HWND);
     function           SpaceAvail: DWORD;
     function           TryLock (dwTimeOut: DWORD): Boolean;
     function           WaitEvent (idEvent, dwTimeOut: DWORD; log: Boolean = FALSE): Boolean;
     procedure          WaitFlush (dwTimeOut: DWORD);
     function           Write (const buff; Count: DWORD;flags: DWORD = 0): DWORD;
     procedure          Unlock;
    end;


var bDirectMode: Boolean = FALSE;

implementation
uses ChConst, ChLog, SysUtils, Misk, DataProvider;


var bOpenExisted: Boolean = FALSE;

function AllocShareData (globalName: PAnsiChar; var h: THandle): PShareDataRec;
var
    AllocSize: DWORD;
begin
 AllocSize := (sizeof (TShareDataRec) div 4096 + 1) * 4096;
 ASSERT (AllocSize >= 16384);
 h := CreateFileMappingA (INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, AllocSize, globalName);
 if (h= 0) or (h = INVALID_HANDLE_VALUE) then RaiseLastOSError;
 bOpenExisted := GetLastError = ERROR_ALREADY_EXISTS;
 result := MapViewOfFile (h, FILE_MAP_WRITE, 0, 0, AllocSize);
 if result <> nil then exit; // success
 RaiseLastOSError;
end; // AllocShareData

function ReleaseShareData (var sdata: PShareDataRec; h: THandle): Boolean;
begin
 result := UnmapViewOfFile (sdata);
 CloseHandle (h);
end;
{ TShareData }

function TShareData.Read (var buff; Count, flags: DWORD): Integer;
var bPeek: Boolean;
begin
 bPeek := (flags and FREADPEEK <> 0);
 result := 0;
 { ���������� �����������, ��� ����� �� ����� ��������
  � �������� ������ }
 if TryLock (1500) then else exit;
 with pdatarec^ do
 try
  // ����������� ����������
  if count > GetCount then count := GetCount;
  if count > 0 then
   begin
    move (data [Index], buff, Count);
    if (PInteger(@buff)^ = BPHDRVALUE) then
        result := count // ������� ������������ ������
     else
      begin
       result := -1; // unknow data
       LogStr (sIdent + '#ERROR - header not recognized');
      end;
    // �������� ������ - ����� �� ������� ������
    if not bPeek then Inc (Index, count);
    if (GetCount = 0)  then // ��� ���������� ������ ������ - ����� ������ �������
     begin
      // ��������� ������� ������� ������
      SetEvent (syncrec.hRecvEvent); // ������ ���������
      // ����� ������� ������ ������
      ResetEvent (syncrec.hSendEvent); // ������ ������� ���������
     end;
   end;
 finally
  Unlock;
 end;
end;


constructor TShareData.Create;

var srcp : THandle;

function DupHandle (h: THandle): THandle;
begin
 DuplicateHandle (srcp, h, GetCurrentProcess, @result,
                  0, TRUE, DUPLICATE_SAME_ACCESS);
end;

begin
 if Assigned (self) then else exit;
 pdatarec := AllocShareData (globalName, hFileMapping);
 ASSERT (pdatarec <> nil, 'The global memory section is not allocated.');
 sIdent := Ident;
 bOwned := FALSE;
 if not bOpenExisted then
 with syncrec do
  begin
   FillChar (pdatarec^, sizeof (TShareDataRec), 0);
   hMutex := CreateMutex (nil, FALSE, nil);
   hRecvEvent := CreateEvent (nil, TRUE, FALSE, nil);
   hSendEvent := CreateEvent (nil, TRUE, FALSE, nil);
   pdatarec.sr := syncrec;
   pdatarec.ownerPID := GetCurrentProcessId;
   pdatarec.ownerTID := 0; // ������ �� �����
  end
 else
 with pdatarec^ do
  begin
   srcp := OpenProcess (PROCESS_DUP_HANDLE, TRUE, pdatarec.ownerPID);
   syncrec.hMutex := DupHandle (sr.hMutex);
   syncrec.hRecvEvent := DupHandle (sr.hRecvEvent);
   syncrec.hSendEvent := DupHandle (sr.hSendEvent);
   CloseHandle (srcp);
  end;
 AddRef;
 lockCount := 0;
end;

destructor TShareData.Destroy;
begin
 Dec (pdatarec.refCount);
 ReleaseShareData (pdatarec, hFileMapping);
 with syncrec do
 begin
  CloseHandle (hMutex);
  if hRecvEvent <> 0 then CloseHandle (hRecvEvent);
  if hSendEvent <> 0 then CloseHandle (hSendEvent);
 end;
end;


function TShareData.TryLock(dwTimeOut: DWORD): Boolean;
var curtid: DWORD;
begin
 curtid := GetCurrentThreadId;
 // ������� ������� ������� ���������� ���������
 result := TRUE;
 with syncRec, pdatarec^ do
 if ownerTID <> curtid  then
  begin
   // LogStr (sIdent + ': Start wait for acquire');
   result := WaitOneObject (hMutex, dwTimeOut, TRUE);
   if result then
    begin
     bOwned := TRUE;
     // LogStr (sIdent + ': success lock');
     if (ownerTID <> 0) then
        LogStr ('#ERROR: Invalid resource unlocking performed');
     lockCount := 1;
     ownerTID := curtid;
    end
   else LogStr (sIdent + ': Lock timeout expired');
  end
 else Inc (lockCount); // ��������� ������ ��������
end; // TryLock

procedure TShareData.Unlock;
begin
 if lockCount > 0 then Dec (lockCount)
  else LogStr ('#ERROR: To many unlocks');
 if lockCount = 0 then
  begin
   //LogStr (sIdent + ': buffer unlocked');
   bOwned := FALSE;
   pdatarec.ownerTID := 0; // ������ ����������
   ReleaseMutex (syncrec.hMutex);
  end;
 //ASSERT (lockCount >= 0);
end;

function TShareData.GetCount: DWORD;
begin
 result := (pdatarec.iCount - pdatarec.Index);
end;


function TShareData.Write(const buff; Count, flags: DWORD): DWORD;
var max, tt: DWORD;
begin
 result := 0;
 tt := GetTickCount;
 // ��� ������� ������ ���������� �� ���������
 with pdatarec^ do
 begin
  max := SpaceAvail;
  if (Count > max) then
    if not Optimize (2000) then exit;

  if Count > 0 then
   begin
    Move (buff, data [iCount], Count);
    result := Count; // ������� ��������
    Inc (iCount, Count);
    SetEvent (syncrec.hSendEvent); // ������ ����������
    ResetEvent (syncrec.hRecvEvent);
    if IsWindow (pdatarec.hWnd) then
       PostMessage (pdatarec.hWnd, WM_NETREADEVENT, 0, 0);

   end;
 end;
 tt := GetTickCount - tt;
 if tt > 50 then
     LogStr(format(sIdent + ': storing time %d msec', [tt]));
end;

function TShareData.SpaceAvail: DWORD;
begin
 result := SHAREDATASIZE - pdatarec.iCount;
end; // SpaceAvail

function TShareData.WaitEvent;
var hEvent: THandle;
    tt: Int64;
    r: DWORD;
begin
 result := FALSE;
 with syncrec do
 case idevent of
  _RECVEVENT: hEvent := hRecvEvent;
  _SENDEVENT: hEvent := hSendEvent;
  else exit;
 end;
 tt := GetTickCount;
 if hEvent <> 0 then
    r := WaitForSingleObject (hEvent, dwTimeOut)
 else r := $BADF00D;   
 result := r = WAIT_OBJECT_0;
 tt := GetTickCount - tt;
 // if result then LogStr (sIdent + ': WaitEvent - OK');
 if log then
   LogStr (format ('(%d). Waiting %d ms from %d ms, result = $%x',
          [GetCurrentProcessId, tt, dwTimeout, r]));
end;



procedure TShareData.SetHWnd(hWnd: HWND);
begin
 pdatarec.hWnd := hWnd;
end;

procedure TShareData.WaitFlush(dwTimeOut: DWORD);
var i: DWORD;
begin
 i := 0;
 repeat
  WaitEvent (_RECVEVENT, 100, FALSE);
  Inc (i, 100);
 until (i > dwTimeOut) or (GetCount < 16);
end;

function TShareData.NeedUnlock: Boolean;
begin
 result := SpaceAvail <= DPACKETSIZE; 
end;

function TShareData.Optimize;
var rest: Integer;
begin
 result := TryLock (lockTimeOut); // �������������
 if not result then exit;
 {$IFOPT D+}
 // LogStr (sIdent + ': Buffer overloading - optimizing');
 {$ENDIF}
 with pdatarec^ do
 try
  rest := GetCount;
  if rest > 0 then
   begin
    move (data [Index], data, rest); // �������� ������ � ������ ������
    iCount := rest;
   end
  else iCount := 0;
  Index := 0;
 finally
  Unlock
 end;
end;


function TShareData.GetRefCount: DWORD;
begin
 result := pdatarec.refCount;
end;

procedure TShareData.AddRef;
begin
 Inc (pdatarec.refCount);
end;

end.
