unit ChPlugin2;

interface
uses Windows, ChTypes;

const
    regFuncName : PAnsiChar = 'RegisterWgcPlugin';
   dispFuncName : PAnsiChar = 'DisplayPlugin';
   scanFuncName : PAnsiChar = 'SearchFirst';
  sieveFuncName : PAnsiChar = 'SearchNext';
   freeFuncName : PAnsiChar = 'FreePlugin';


procedure    SearchPlugins (const path: string);


function     ScanWithPlugin (buff : Pointer; bsize : dword;
                             offsets : POffsetArray) : dword;

function     SieveWithPlugin (buff : Pointer;
                              offsets : POffsetArray; count : dword) : dword;

function     DisplayPlugin : dword;

procedure    FreePlugins;


implementation
uses ChShare, SysUtils, ChHeap, ChServer;

function     DisplayPlugin : dword;
// ����������� ������� �������
begin
 result := 0;
 with ssm, ssm.plugRec do
 if @pgFuncs [plgNum].dispFunc <> nil then
    result := pgFuncs [plgNum].dispFunc (dlgNum, ssm.plgRqsSet);
end;


function    ScanWithPlugin; // ����� ���������� �������
begin
 result := 0;
 if bsize < 8 then exit;
 if ssm <> nil then      // ���� ���� ����� ���������
 with ssm, ssm.plugRec do
 if @pgFuncs [plgNum].scanFunc <> nil then // ������� ����������?
    result := pgFuncs [plgNum].scanFunc (buff, bsize, offsets);
end; // Scan w plugin

function    SieveWithPlugin; // ����� ���������� �������
begin
 result := 0;
 if ssm <> nil then
 with ssm, ssm.plugRec do
 if @pgFuncs [plgNum].scanFunc <> nil then // ������� ����������?
    result := pgFuncs [plgNum].sieveFunc (buff, offsets, count);
end; // Sieve w plugin

procedure    FreePlugins;
var n : byte;
begin
with ssm.plugRec do
for n := 1 to pgCount do
 begin
  // ������������� ������ �������
  if (@pgFuncs [n].freeFunc <> nil) then pgFuncs [n].freeFunc;
  // �������� �����
  if (pgFiles [n] <> nil) then MemSrv (pgFiles [n], sizeOf (str255), MFREE);
  if (pgNames [n] <> nil) then MemSrv (pgNames [n], sizeOf (str64), MFREE);
 end; // with
end; // FreePlugin


function     LoadPlugin (const fileName : string; var r : TFuncRec) : string;
// �������� �������
var
   pp : PAnsiChar;
   c : WSTRZ256;
   h : THandle;
  // s : string;
   p : TRegisterFunc;
begin
 result := '';
 StrPCopy (c, fileName);
 h := LoadLibrary (c);
 if h = 0 then exit;
 @p := GetProcAddress (h, regFuncName);
 if (@p <> nil) then
  begin
   r.dlgCount := p (pp, r.dlgNames, 0);
   result := pp;
   @r.dispFunc := GetProcAddress (h, dispFuncName);
   @r.scanFunc := GetProcAddress (h, scanFuncName);
   @r.sieveFunc := GetProcAddress (h, sieveFuncName);
   @r.freeFunc := GetProcAddress (h, freeFuncName);
   r.hLib := h; // ��������� ����
  end
 else FreeLibrary (h);
end;


procedure    SearchPlugins;
// ����� �������� � �������� �����
var
   f : TSearchRec;
   name : string;
begin
with ssm.plugRec do
begin
 pgCount := 0;
 if FindFirst (path + '\*.dll', faAnyFile xor faDirectory, f) = 0 then
  begin
   repeat
    name := LoadPlugin (path + '\' + f.Name, pgFuncs [pgCount + 1]);
    if name <> '' then // ��������� ������
     begin
      inc (pgCount);
      MemSrv (pgFiles [pgCount], sizeOf (str255), MALLOC);
      pgFiles [pgCount]^ := f.Name;
      MemSrv (pgNames [pgCount], sizeOf (str64), MALLOC);
      pgNames [pgCount]^ := name;
     end;
   until FindNext (f) <> 0;
  end; // on findFirst
end; // with
end;


end.
