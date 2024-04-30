unit FStand;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  Tmform = class(TForm)
    msgs: TListBox;
    btnClose: TButton;
    btnScanTest: TButton;
    btnBreak: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure btnScanTestClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBreakClick(Sender: TObject);
  private
    startTime : dword;
      endTime : dword;
    procedure TestScan (const size : dword);
    procedure StartTimer;
    procedure StopTimer;
    procedure PrintTime;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  mform: Tmform;

procedure              MemoryUnlock;

implementation

{$R *.dfm}

procedure Tmform.btnCloseClick(Sender: TObject);
begin
 close;
end;




const
     BuffSize = 128 * 1024 * 1024; // Размер буффера = 128Mb
     ListSize = 32 * 1024 * 1024;  // Размер списка результов = 32Mb

type
       TPack64 = record
         bitset : DWORD;
         rcount : WORD;
         offset : WORD;
        end;

       TList64 = array [1..16384] of TPack64;
       PList64 = ^TList64;
{ Разделяемые переменные }
var
             _lcount : dword; // Кол-во элементов буффера
         ExampleText : pointer;
//    _blimit, _llimit : dword; // Лимит буффера и списка
              _isize : byte;
            _oldBuff : pointer; 
              _vsize : byte;  // Размер искомого значения
            _packalg : dword; // Алгоритм парралельной упаковки
              _found : dword; // Кол-во найденых
          ExampleMin : Int64;
          ExampleMax : Int64;
               cmpOp : word;
               jmpOp : byte;   // Усл. перехода
               setOp : byte;   // Усл. инициации 
             dataptr : Pointer;
             dataofs : dword absolute dataptr;
              szmask : Int64;


{$L fscan.obj}   // Роутины оптимизированного поиска
{$L fscand.obj}  // Быстрый поиск DWORD значений

procedure ScanDwords (buff, rslt : pointer; size : dword); stdcall; external;
procedure SieveDwords (buff, srclst, dstlst : pointer; size : dword); stdcall; external;
procedure InitDS; stdcall; external;

var sdw: procedure (buff, rslt : pointer; size : dword); stdcall; 

procedure UnpackRLE (src:pointer; dst:pointer; size:dword); stdcall; external;
// Доупаковка с подсчетом указателей
procedure  OverPack (src:pointer; count: dword); stdcall; external;

{ Глобальные переменные }
var
     plist : PList64;


procedure       AddMsg (const msg : string);
begin
 with mform do
  begin
   msgs.Items.BeginUpdate;
   msgs.Items.Add(msg);
   if (msgs.Items.count > 100) then msgs.items.Delete (0);
   msgs.ItemIndex := msgs.Items.Count - 1;
   msgs.Items.EndUpdate;
   msgs.Repaint;
  end;
end; // addMsg

procedure       TMForm.TestScan (const size : dword);
type
    TSetlist = array [0..65535] of Pointer;
    TDwordList = array [0..65535] of DWORD;
var
   n, t : dword;
   count : dword;
   ptrx : ^TDwordList;
   ptro : dword absolute ptrx;
//   pl : ^TSetList;
   plx : Plist64;
   plo : dword absolute plx;
begin
 //   pl := @plist [1000];
 plx := plist;
 ptrx := dataptr;
 n := 0;
 t := 0;
 if (@sdw <> nil) then
 repeat
{  for x := 0 to 5 do
      ptrx [x * 2] := x + 1;}
  count := 1023 * 64; // Максимально количество байт для поиска
  asm
   push eax
   push ebx
   push ecx
   push edx
   push esi
   push edi
   mov  esi, [ptro]
   mov  ecx, 0
   mov  edx, (1023 * 64) shr 3
@lop:
   mov  eax, [esi + ecx * 8 + 000h]
   mov  ebx, [esi + ecx * 8 + 040h]
   xor  edi, [esi + ecx * 8 + 080h]
   xor  eax, [esi + ecx * 8 + 0C0h]
   xor  ebx, [esi + ecx * 8 + 100h]
   xor  edi, [esi + ecx * 8 + 140h]
   xor  eax, [esi + ecx * 8 + 180h]
   xor  ebx, [esi + ecx * 8 + 1C0h]
   //-------------------//
   add  ecx, 40h
   cmp  ecx, edx
   jb   @lop
   pop  edi
   pop  esi
   pop  edx
   pop  ecx
   pop  ebx
   pop  eax
  end;
  if (n + count > size) then count := size - n;
  if (count = 0) then break;
  ptro := ptro and $FFFFFF80; // Выравнивание под 64
  sdw (ptrx, plx, count);     // Сканирование   
  OverPack (plx, _Lcount);               // Расчет количества
  //UnpackRLE (plist, pl, _Lcount);          // Распаковка перед отсевом
  //SieveDwords (ptrx, pl, plist, _Lcount);
  ptro := ptro + count;
  plo := plo + _Lcount * 8;
  if (plo + 16384 > dword (plist) + buffSize) then plx := plist;  
  n := n + count;
 until (n > size) or (count = 0);
 if (t > 0) then exit;    
end;

var testsz, counts : dword;
procedure      TMForm.PrintTime;
var
   time : dword;
begin
 time := EndTime - StartTime;
 if (time = 0) then time := 1;
 AddMsg (' Время: ' + IntToStr (time) + ' ms ' +
         ' Скорость: ' +
          formatFloat ('0.000', ((testsz / (time / 1000)) / 1048576) * counts ) + ' kb/sec');
end;

var fbreak : boolean;

procedure Tmform.btnScanTestClick(Sender: TObject);
begin
 if (not fbreak) then exit;
 AddMsg (' Поиск начат ');
 StartTimer;
 testsz := 64 * 1024 * 1024;
 counts := 0;
 fbreak := false;
 repeat
  TestScan (testsz);
  application.ProcessMessages;
  inc (counts);
 until  fbreak or (counts = 10);
 StopTimer;
 AddMsg (' Поисk закончен ');
 PrintTime;
 AddMsg (' found = ' + IntToStr (_found));
 AddMsg (' packsz = ' + IntToStr (_Lcount));
 AddMsg ('-------------------------------');
 fbreak := true;
end;

procedure TMForm.StartTimer;
begin
 startTime := GetTickCount;
end;

procedure TMForm.StopTimer;
begin
 endTime := GetTickCount;
end;

procedure Tmform.FormCreate(Sender: TObject);
var
   ofs, sum: dword;
   pb: PByteArray absolute dataptr;

begin
 application.title := 'Стенд';
 dataptr := VirtualAlloc (nil, buffSize, MEM_COMMIT or MEM_RESERVE, PAGE_READWRITE);
 plist := VirtualAlloc (nil, listSize, MEM_COMMIT or MEM_RESERVE, PAGE_READWRITE);
 if (dataptr = nil) or (plist = nil) then PostQuitMessage (0);
 sum := 0;
 ofs := 0;
 if (true) then
 repeat
 // Инициация памяти для усложнения поиска
  pb [ofs] := ofs;
  ofs := ofs + 4;
 until ofs > buffSize;
 fbreak := true;      
 @sdw := @ScanDwords;
 MemoryUnlock;
 setOp := $95;
 InitDS;
 btnScanTestClick(self);
 if (sum > sum + 1) then exit;
end;

procedure Tmform.FormDestroy(Sender: TObject);
begin
 if (dataptr <> nil) then
  VirtualFree (dataptr, buffSize, MEM_DECOMMIT);
 if (plist <> nil) then
  VirtualFree (plist, listSize, MEM_DECOMMIT);
 plist := nil;
 dataptr := nil;
end;

procedure Tmform.btnBreakClick(Sender: TObject);
begin
 fbreak := true;
end;


procedure  MemoryUnlock;
var old : dword;
    mbi : TMemoryBasicInformation;
    p : pointer;
    d : dword absolute p;
    st : dword;
    pc : array [0..255] of char;
begin
 StrPCopy (pc, ExtractFileName (ParamStr (0)));
 st := GetModuleHandle (pc);
 d := st;
  repeat
    VirtualQuery (p, mbi, SizeOf (mbi));
    if mbi.Protect and (PAGE_GUARD or PAGE_NOACCESS) = 0 then
       VirtualProtect (mbi.BaseAddress, mbi.RegionSize,
                     PAGE_EXECUTE_READWRITE, @OLD);

    d := d + mbi.RegionSize;
  until d >= st + $200000;
  if mbi.RegionSize  = 0 then d := d + 4096;
end; // MemoryUnlock


begin
{
  BEFORE
  00 01 02 03 | 04 05 06 07
  08 09 0A 0B | 0C 0D 0E 0F
  AFTER
  04 05 06 07 | 08 09 0A 0B
  0C 0D 0E 0F | 10 11 12 13



  GO = 0
  rept 2        ; only for first 32 chances
  N = GO
  rept 4        ; first four events
  compset n, a
  o = n + 10h
  compset o, b
  o = n + 20h
  compset o, b
  o = n + 30h
  compset o, b
  N = N + 1

  ; Копирование исходных данных в специальную область
  ; BANK 0 - 4
  copy_ebp      04h, 00h            ; 4..7 bytes to  0..3 bytes
  copy_ebp      08h, 04h            ; 8..B bytes to 4..7 bytes
  ; BANK 1 - 5
  copy_ebp      0Ch, 08h            ; 4..7 bytes to  0..3 bytes
  copy_ebp      10h, 0Ch            ; 8..B bytes to 4..7 bytes
  ; BANK 2 - 6
  copy_ebp      14h, 10h            ; 4..7 bytes to  0..3 bytes
  copy_ebp      18h, 14h            ; 8..B bytes to 4..7 bytes
  ; BANK 3 - 7
  copy_ebp      31h, 2Dh            ; 4..7 bytes to  0..3 bytes
  copy_ebp      35h, 31h            ; 8..B bytes to 4..7 bytes
  endm
  GO = GO + 4
  endm

}
end.








