unit ChAlgs;
interface
uses Windows, SysUtils, ChShare, ChTypes, ChSettings, ChLog;

(*

  Собственная скорость сканирования функции ReadProcessMemory составляет порядка
   460 Мебибайт/сек на моем компьютере:
   {
       CPU = AMD Athlon 2000XP+@1667 Mhz, 64K + 64K L1 cache, 256K L2 cache
       RAM = 512 MiB DDR333/400
   }
   0,149 sec @ scaning tested process: 68,9MiB
   2,2 sec needs to copy 1 GibiByte from other process

  Общая скорость цикла поиска: 305 MiB/сек.
  Удельное время выполнения алгоритмов упаковки:

  time (RPM) + time (scan in cache) = global time
  0,149 + 0,077 = ~0,230

  Actual speed of scaner algorithm = ~896 MiB/Sec
  Calculated speed = 844 MiB/Sec - 990 MiB/Sec
  Calculated speed of aligned scaned = 5000 - 5500 MiB!!, but really is may
  be not above 427 MiB/Sec 

*)

const
     NPACKED = 0;   // Неупакованные смещения по 16 бит
     SETPACK = 4;   // Простые множества по 32 бита
     RLESET  = 16;  // Множества упакованные RLE
     RLESETP = 32;  // Множества упакованные RLE, с сохраниением смещений, но без нулевых множеств
     PENABLE = TRUE;

    { Список смещений внутри буффера (региона)  }
type
    PReal = ^Real;
    TByteVec = array [0..$FFFF] of byte;
    PByteVec = ^TByteVec;

    TPack32 = packed record
     bitset : dword;
      count : dword;
    end;

    TPack32List = array [0..8191] of TPack32; // Хватит на описание всех массивов
    PPack32List = ^TPack32List;

    TScanProc = procedure (buff, rslt : pointer; size : dword); stdcall;
    TSieveProc = procedure (buff, srclst, dstlst : pointer; count : dword); stdcall;

procedure InitDS; stdcall;

var
    textExample : array [0..255] of AnsiChar;
    wideExample : WSTRZ256;
    // эти переменные расшарены с файлами scan.asm & fscan.asm

     _bsize, _Lcount : dword; // Размер буффера и списка
    _blimit, _llimit : dword; // Лимит буффера и списка
              _vsize : byte;  // Размер искомого значения
              _Isize : byte;  // Текущий Размер элемента архива
            _packalg : dword; // Алгоритм парралельной упаковки
              _found : word; // Кол-во найденых
            _oldBuff : pointer; // Указатель на буффер пред. значения
         ExampleText : Pointer;    // Указатель на строковой образец
              szmask : Int64;
               cmpOp : word;
               jmpOp : byte;
               setOp : byte;
            dataneed : dword;  // Тип данных требуемых функцией отсева
            // 2 *256 * 2 * 1024 = 1024Kb least
               pwhole: pointer = nil;
               pprevd: pointer = nil;
{ Переменная выравниватель - aligner }
               aligner: array [1..35] of byte;
{ Данные здесь должны быть выровнены особым образом !}
               fwhole,
               fprevd: array [0..$FFFF] of word; // internal vectors
                 temp: array [0..4] of Int64;
           ExampleMin: Int64;
           ExampleMax: Int64;
               mmx_ex: Int64;
               _mask0: Int64; // for mmX
               _mask1: Int64; // for mmX
               _mask2: Int64; // for mmX
               _mask3: Int64; // for mmX

               masksv: dword;
               savebp: dword;
               passed: dword; // отловки багов

const  pdb:pointer = ptr ($100);

var   xxd: dword absolute pdb;


procedure ResetVars;
procedure Prefetch (const p: pointer; const sz: dword); stdcall;
procedure PrefetchMMX (const p: pointer; const sz: dword); stdcall;

procedure InitExamples (const r : TRequest);
procedure InitTextExample (const s : string; const fwide : Boolean);
function  GetScanProc (const r : TRequest) : TScanProc;
function  GetSieveProc (const r : TRequest) : TSieveProc;




{ 2.40 Соглашение о параметрах функций поиска
     buff - указатель на исходные данные, aligned 64
     rslt - указатель на архив в который сохраняются смещения
     size - количество данных, кратно 64, не более 1023 * 64

}
procedure ScanSimple (buff, rslt : pointer; size : dword); stdcall;
procedure ScanDWORDS (buff, rslt : pointer; size : dword); stdcall;
procedure ScanDWORDSA (buff, rslt : pointer; size : dword); stdcall;

procedure ScanUnknow (buff, rslt : pointer; size : dword); stdcall;
procedure ScanFirstDig (buff, rslt : pointer; size : dword); stdcall;

procedure ScanRangeD (buff, rslt : pointer; size : dword); stdcall;
procedure ScanRangeW (buff, rslt : pointer; size : dword); stdcall;
procedure ScanRangeB (buff, rslt : pointer; size : dword); stdcall;

procedure ScanText (buff, rslt : pointer; size : dword); stdcall;
procedure ScanWide (buff, rslt : pointer; size : dword); stdcall;

{ 2.40 Соглашение о параметрах функций отсева:
     buff - указатель на исходные данные, aligned 64
   srclst - указатель на массив множеств, aligned 4
   dstlst - указатель на архив, aligned 4

 Дополнительные параметры:
   _oldbuff -  указатель на исходные данные предыдущего поиска/отсева,
   используется для поиска не известного значения.

 Количество 8 или 4 байтных значений записаных в архив функция заносит в _Lcount,
 размер значения в _Isize
}

procedure SieveSimple (buff, srclst, dstlst : pointer; count : dword); stdcall;
procedure SieveDwords (buff, srclst, dstlst : pointer; count : dword); stdcall;
procedure SieveUnknow (buff, srclst, dstlst : pointer; count : dword); stdcall;
procedure SieveFirstDig (buff, srclst, dstlst : pointer; count : dword); stdcall;
procedure SieveRangeD   (buff, srclst, dstlst : pointer; count : dword); stdcall;
procedure SieveRangeW   (buff, srclst, dstlst : pointer; count : dword); stdcall;
procedure SieveRangeB   (buff, srclst, dstlst : pointer; count : dword); stdcall;
procedure SieveText     (buff, srclst, dstlst : pointer; count : dword); stdcall;
procedure SieveWide     (buff, srclst, dstlst : pointer; count : dword); stdcall;

// Алгоритмы упаковки списков
// упаковка списка множеств в RLE архив, с подсчетом еденичных бит
procedure       PackRLE (src: pointer; dst: pointer; count: dword); stdcall
// доупаковка обычного SETRLE, с подсчетом еденичных бит
function        OverPack (src: pointer; count: dword) : dword; stdcall;
// распаковка SETRLE/SETRLE+ в набор множеств
procedure       UnpackRLE (src: pointer; dst: pointer; count:dword); stdcall;

implementation
uses Types, math, ChHeap, misk, ChServer;

// array [1..64 * 1024] of word
var old_op: dword; // old operation

procedure       ResetVars;
begin
 _Found := 0;
 _Lcount := 0;
 _packalg := 0;
 szmask := $FFFFFFFF; // std dword value
end;

procedure       PrefetchMMX; assembler;
// Упреждающее чтение для процессора Athlon
asm
 // int            3
 push           ebx
 push           ecx
 push           edx
 push           esi
 push           edi
 mov            esi, p          // register model
 mov            edx, sz
 xor            ecx, ecx        // half 1, 000..0FFh
 mov            eax, 20h        // half 2, 100..1FFh
 add            esi, 80h
 shr            edx, 3          // Size div 256 = count of cycles
@rept:
 // mixed read
 // 2xNegative = -7F..-40, -3F..-01
 // 2xPositive = 00..3F, 40..7F
 //
 prefetchnta [esi + ecx * 8 - 7Ch] // esi + 004h
 prefetchnta [esi + ecx * 8 - 40h] // esi + 040h
 prefetchnta [esi + ecx * 8 + 04h] // esi + 084h
 prefetchnta [esi + ecx * 8 + 40h] // esi + 0C0h
 add            ecx, 40h // 4 * 64 = 256 bytes, next half = eax
 // half 2, offset + 100h
 prefetchnta [esi + eax * 8 - 7Ch] // esi + 104h
 prefetchnta [esi + eax * 8 - 40h] // esi + 140h
 prefetchnta [esi + eax * 8 + 04h] // esi + 184h
 prefetchnta [esi + eax * 8 + 40h] // esi + 1С0h
 add            eax, 40h {}
 cmp            ecx, edx
 jb             @rept
 pop            edi
 pop            esi
 pop            edx
 pop            ecx
 pop            ebx
end;

procedure       Prefetch; assembler;
// Упреждающее чтение для процессора Athlon
asm
 // int            3
 push           ebx
 push           ecx
 push           edx
 push           esi
 push           edi
 mov            esi, p          // register model
 mov            edx, sz
 xor            ecx, ecx        // half 1, 000..0FFh
 mov            eax, 20h        // half 2, 100..1FFh
 add            esi, 80h
 shr            edx, 3          // Size div 256 = count of cycles
@rept:
 // mixed read
 // 2xNegative = -7F..-40, -3F..-01
 // 2xPositive = 00..3F, 40..7F
 //
 mov            ebx, dword ptr [esi + ecx * 8 - 7Ch] // esi + 004h
 mov            ebx, dword ptr [esi + ecx * 8 - 40h] // esi + 040h
 mov            ebx, dword ptr [esi + ecx * 8 + 04h] // esi + 084h
 mov            ebx, dword ptr [esi + ecx * 8 + 40h] // esi + 0C0h
 add            ecx, 40h // 4 * 64 = 256 bytes, next half = eax
 // half 2, offset + 100h
 mov            ebx, dword ptr [esi + eax * 8 - 7Ch] // esi + 104h
 mov            ebx, dword ptr [esi + eax * 8 - 40h] // esi + 140h
 mov            ebx, dword ptr [esi + eax * 8 + 04h] // esi + 184h
 mov            ebx, dword ptr [esi + eax * 8 + 40h] // esi + 1С0h
 add            eax, 40h {}
 cmp            ecx, edx
 jb             @rept
 pop            edi
 pop            esi
 pop            edx
 pop            ecx
 pop            ebx
end;
{ Внешние подпрограммы }


{$L fscan}   // Роутины упаковки/распаковки
// упаковка обычных множеств в RLE архив множеств
procedure PackRLE (src: pointer; dst: pointer; count: dword); stdcall; external;
// Распаковка архива в набор множеств
procedure UnpackRLE (src:pointer; dst:pointer; count: dword); stdcall; external;
function  OverPack (src:pointer; count: dword) : dword; stdcall; external; // Изпользуется в различных asm файлах


{$L fscand      }  // Быстрый поиск DWORD значений
// var exta: dword; external;
procedure ScanDwords (buff, rslt : pointer; size : dword); stdcall; external;
procedure ScanDwordsA (buff, rslt : pointer; size : dword); stdcall; external;

procedure SieveDwords (buff, srclst, dstlst : pointer; count : dword); stdcall; external;
procedure InitDS; stdcall; external;

{$L fscanw}  // Быстрый поиск WORD значений
procedure ScanWords (buff, rslt : pointer; size : dword); stdcall; external;
procedure SieveWords (buff, srclst, dstlst : pointer; count : dword); stdcall; external;
procedure InitWS; stdcall; external;

{$L fscanb}
procedure ScanBytes (buff, rslt : pointer; size : dword); stdcall; external;
procedure SieveBytes (buff, srclst, dstlst : pointer; count : dword); stdcall; external;
procedure InitBS; stdcall; external;


{$L scanunk}
procedure ScanUnknow (buff, rslt : pointer; size : dword); stdcall; external;
procedure SieveUnknow (buff, srclst, dstlst : pointer; count : dword); stdcall; external;

{$L Scanfdig}
procedure ScanFirstDig; stdcall; external;
procedure SieveFirstDig; stdcall; external;

{$L ScanrngD}
procedure ScanRangeD;  stdcall; external;
procedure SieveRangeD; stdcall; external;
{$L ScanrngW}
procedure ScanRangeW;  stdcall; external;
procedure SieveRangeW; stdcall; external;

{$L ScanrngB}
procedure ScanRangeB;  stdcall; external;
procedure SieveRangeB; stdcall; external;

{$L Scantxt}
procedure ScanText; stdcall; external;
procedure ScanWide; stdcall; external;
procedure SieveText; stdcall; external;
procedure SieveWide; stdcall; external;

{ Целочисленные подпрограммы }
procedure ScanBytes_MMX (buff, rslt : pointer; size: dword); stdcall;
asm
		pushad
		movq	        mm7, _mask1
		movq	        mm6, mmx_ex // db 8 dub (example)
                movq            mm5, _mask2
                movq            mm4, _mask3
		// ================
		mov		esi, buff // large data Q
		mov		ecx, size
		add		ecx, esi
		mov		dword ptr [@smc_cmp + 2], ecx
		mov		edi, rslt
		xor		eax, eax
		mov		dword ptr [edi], eax
		mov		dword ptr [edi + 4], eax
		mov		ebx, 0
		mov		ecx, 0
		mov		edx, 0
		// MMX test algorithm
		// Using parrallel comparing
		// Reading 32 bytes [4x8 but unaligned]
		// This 3 command initialized big_loop
@bint_loop:
		// psllq		mm5, 4 // return / prepare state
		// step - 03
       		movq		        mm0, [esi + 00h]
		pcmpeqb		        mm0, mm6
                movq		        mm1, [esi + 08h]
		pcmpeqb		        mm1, mm6

		movq		        mm2, [esi + 10h]
		pcmpeqb		        mm2, mm6
                movq		        mm3, [esi + 18h]
                pcmpeqb		        mm3, mm6

                //pmovmskb                ecx, mm0
		pand		        mm0, mm7  // 0-1
                pand		        mm1, mm7  // 1-1
                pand		        mm2, mm7  // 2-1
                pand		        mm3, mm7  // 3-1

		pmaddwd	        	mm0, mm5  // 0-2
                pmaddwd		        mm1, mm5  // 1-2

                pmaddwd		        mm2, mm5  // 2-2
                pmaddwd		        mm3, mm5  // 3-2

		packssdw                mm0, mm0  // 0-3
                packssdw                mm1, mm1  // 1-3

                packssdw	        mm2, mm2  // 2-3
                packssdw	        mm3, mm3  // 3-3

		pmaddwd		        mm0, mm4  // 0-4
		psrlq		        mm0, 8
                pmaddwd		        mm1, mm4  // 1-4
		por		        mm0, mm1

                pmaddwd		        mm2, mm4  // 2-4
		psllq		        mm2, 8
                pmaddwd		        mm3, mm4  // 3-4
		psllq		        mm3, 16
		por		        mm2, mm3
		por		        mm2, mm0

		movq		        mm0, [esi + 20h]
		pcmpeqb		        mm0, mm6
                movq		        mm1, [esi + 28h]
		pcmpeqb		        mm1, mm6

		movd		        eax, mm2

		movq		        mm2, [esi + 30h]
		pcmpeqb		        mm2, mm6
                movq		        mm3, [esi + 38h]
                pcmpeqb		        mm3, mm6

		pand		        mm0, mm7  // 0-1
                pand		        mm1, mm7  // 1-1
                pand		        mm2, mm7  // 2-1
                pand		        mm3, mm7  // 3-1

		pmaddwd		        mm0, mm5  // 0-2
                pmaddwd		        mm1, mm5  // 1-2

                pmaddwd		        mm2, mm5  // 2-2
                pmaddwd		        mm3, mm5  // 3-2

		packssdw	        mm0, mm0  // 0-3
                packssdw	        mm1, mm1  // 1-3

                packssdw	        mm2, mm2  // 2-3
                packssdw	        mm3, mm3  // 3-3

		pmaddwd		        mm0, mm4  // 0-4
		psrlq		        mm0, 8
                pmaddwd		        mm1, mm4  // 1-4
		por		        mm0, mm1

                pmaddwd		        mm2, mm4  // 2-4
		psllq		        mm2, 8
                pmaddwd		        mm3, mm4  // 3-4
		psllq		        mm3, 16
		por	       	        mm2, mm3
		por	       	        mm0, mm2
		movd		        edx, mm0
//------------- complete SETS --------------------
                prefetchnta             [esi + 300h]
                //test                    dword ptr [esi + 300h], ebx
		add		        esi, 64
//---------------------------------------------------------
		// saving bitset with packing on fly
		cmp		        eax, ebx // as [EDI]
		je		        @only_inc1
		xor		        ecx, ecx
		mov		        ebx, eax
		mov		        [edi + 08h], eax
		mov		        [edi + 0Ch], ecx
		add		        edi, 8	// saving - OK
@only_inc1:
		// high part of mm4
		add		        ecx, 1
		cmp		        eax, edx
		je		        @only_inc2
		mov		        ebx, edx
		mov		        [edi + 4], ecx // save prevous
		xor		        ecx, ecx
		mov		        [edi + 08h], edx
		mov		        [edi + 0Ch], ecx
                add                     edi, 8
@only_inc2:
		add		        ecx, 1
@smc_cmp: // Next 2 commands are delay for data complete for 3 command
		cmp		        esi, 12345678h
		mov		        [edi + 4], ecx // save last counter
		jb		        @bint_loop
		//==============
                xor                     eax, eax
                mov                     [edi + 8], eax  // концевание
                mov                     [edi + 12], eax // концевание
                // Последние множества - не нулевые
                add                     edi, 8
                sub                     edi, rslt        // -= @rslt
                // преобразование размера в количество
                shr                     edi, 3
                // Кол-во элементов (по 8 байт) архива
                mov                     _isize, 8
                mov                     _lcount, edi
                mov                     _packalg, RLESET
                emms
		popad

end;

procedure ScanDWORDS_MMX (buff, rslt : pointer; size: dword); stdcall;
assembler;
const SCL = 64;
const NOFS = 32;
asm
		push	eax
		push	ebx
		push	ecx
		push	edx
		push	esi
		push	edi
		push	ebp
                // ================
                pxor            mm6, mm4
                movd	        mm6, dword ptr [ExampleMin]
                psllq           mm6, 32
                movd            mm5, dword ptr [ExampleMin]
                por             mm6, mm5
                mov		esi, buff // miniwin in buff
		mov		edi, size
		// sub		edi, 1024 // limitate it (OK)
                // sub             edi, 64   // prevent outbound
		add		edi, esi
                cmp             dword ptr [@smc_cmp + 4], edi
                je              @not_path
                movq	        mm5, _mask0
		mov		dword ptr [@smc_cmp + 2], edi
@not_path:                
                // prepare registers for collecting
                pxor            mm1, mm1
                pxor            mm3, mm3
                mov		edi, [rslt] // set dest3
                movq            [edi + 0], mm1
                movq            [edi + 8], mm3
                mov		eax, - Nofs // in command offset
		mov		ebx, 0
		mov		ecx, 0
		mov		edx, 0
		// MMX test algorithm
@bint_loop:
		movq		        mm2, [esi + eax + 20h + NOFS] // +
		pcmpeqd		        mm2, mm6
		movq		        mm0, [esi + eax + 00h + NOFS] // +
		pcmpeqd		        mm0, mm6
		pand	                mm2, mm5
		movq		        mm7, [esi + eax + 21h + NOFS] //
		pcmpeqd		        mm7, mm6
		pand	                mm0, mm5
		movq		        mm4, [esi + eax + 01h + NOFS] //
		psllq		        mm5, 1	 // common shift
		pcmpeqd		        mm4, mm6
		por			mm3, mm2
		por			mm1, mm0
		pand	                mm7, mm5
		pand	                mm4, mm5
		por			mm3, mm7
		por			mm1, mm4
		psllq	        	mm5, 1	 // common shift
		movq	        	mm2, [esi + eax + 22h + NOFS] //
		pcmpeqd		        mm2, mm6
		movq		        mm0, [esi + eax + 02h + NOFS] //
		pcmpeqd		        mm0, mm6
		pand	                mm2, mm5
		movq		        mm7, [esi + eax + 23h + NOFS] // +
		pcmpeqd		        mm7, mm6
		pand	                mm0, mm5
		movq	        	mm4, [esi + eax + 03h + NOFS] // +
		pcmpeqd		        mm4, mm6
		psllq		        mm5, 1	 // common shift
		por			mm3, mm2		
		por			mm1, mm0
		pand	                mm7, mm5
		pand	                mm4, mm5
		por			mm3, mm7
		por			mm1, mm4
		psllq		        mm5, 5  // additional shift
		add			eax, 8
		// во избежание наложения...
		jnz			@bint_loop
		// Снесение в младшую часть регистра
		// Сместить оба множества в младшие части регистров
		movq		        mm7, mm3
		psrlq		        mm3, 32
		movq		        mm4, mm1
		psrlq		        mm1, 32
		por			mm7, mm3 // store result
		por			mm4, mm1 // store result
		movq		        mm2, [esi + 080h] // +STLF
		pxor		        mm3, mm3 // prepare to collect
		pxor		        mm1, mm1 // prepare to collect
		prefetchnta             [esi + 300h] // [MMX PIII+]
		movq		        mm0, [esi + 060h] // +STLF
		mov			ecx, [edi + 4]
		add			esi, SCL
		movq		        mm5, _mask0
		movd		        edx, mm7  // high 32 bytes
                movd		        eax, mm4 // low 32 bytes

		// xor			edx, -1
		// saving bitset with packing on fly
		cmp		        eax, ebx
		je		        @only_inc1
		xor		        ecx, ecx
                mov                     ebx, eax
		mov		        [edi + 08h], eax
		mov		        [edi + 0Ch], ecx
		add		        edi, 8	// saving - OK
@only_inc1:
		// high part of mm4
		add		        ecx, 1
		cmp		        eax, edx
                je		        @only_inc2
                mov                     ebx, edx
		mov		        [edi + 4], ecx // save prevous
		xor		        ecx, ecx
		mov		        [edi + 08h], edx
		mov		        [edi + 0Ch], ecx
                add                     edi, 8
@only_inc2:
		add		        ecx, 1
                mov		        eax, - Nofs // in command offset
@smc_cmp:
		cmp		        esi, 1234567h
		mov		        [edi + 4], ecx // save counter
		jb		        @bint_loop
                xor                     eax, eax
                mov                     [edi + 8], eax  // концевание
                mov                     [edi + 12], eax // концевание
                // Последние множества - не нулевые
                add                     edi, 8
                sub                     edi, rslt        // -= @rslt
                // преобразование размера в количество
                shr                     edi, 3
                // Кол-во элементов (по 8 байт) архива
                mov                     _isize, 8
                mov                     _lcount, edi
                mov                     _packalg, RLESET
                emms
		//==============
		pop			ebp
		pop			edi
		pop			esi
		pop			edx
		pop			ecx
		pop			ebx
		pop			eax
end;

 procedure   ScanSimple;
 begin
  case _vsize of
   1: begin
       InitBS;
       if pWgcSet.bPrefetch then
          ScanBytes_MMX (buff, rslt, size) else
       ScanBytes (buff, rslt, size);
      end;
   2: begin
       InitWS;
       ScanWords (buff, rslt, size);
      end;
   4, 6, 8, 10:
      begin
       InitDS;
       if ssm.svars.fAligned then
          ScanDwordsA (buff, rslt, size)
       else
        if pWgcSet.bPrefetch then ScanDwords_MMX (buff, rslt, size)
                            else ScanDwords (buff, rslt, size);
      end;
  end;
  OverPack (rslt, _Lcount); // Доупаковка и подсчет
 end;


 procedure  SieveSimple;
 begin
  case _vsize of
   1: begin
       InitBS;
       SieveBytes (buff,  srclst, dstlst, count);
      end;
   2: begin
       InitWS;
       SieveWords (buff, srclst, dstlst, count);
      end;
   4, 6, 8, 10:
      begin
       InitDS;
       SieveDwords (buff, srclst, dstlst, count);
      end;
  end;
  OverPack (dstlst, _Lcount);
 end; // SieveSimple


procedure InitExamples;
var minr, maxr : Extended;
    emin, emax: dword;
begin
 ExampleMin := r.min;
 ExampleMax := r.max;
 _vsize := r.vsize;
 if (r._class = st_text) or (r._class = st_wide) then
     InitTextExample (r.textEx, r._class = st_wide);  // Инциация текстового образца
 // операции SMC
 cmpOP := r.cmpOP;
 setOP := r.setOP;
 jmpOP := r.jmpOP;
 szmask := CalcMask (r.vsize);
 // инициация из вещественного в целый
 if pWgcSet.bPrefetch then
   begin
    if 1 = _vsize then memsetb (@mmx_ex, exampleMin, 8);

   end;
 if (r._class = st_real) then
 begin
  maxr := r.maxr;
  minr := r.minr;
  if (r.rule <> $80) then maxr := r.minr;
  Float2V (minr, maxr, r.vsize, emin, emax);
  ExampleMin := emin + int64 (emin) shl 32; // copy 32 bit value to 64
  ExampleMax := emax;
 end;
end; // InitExamples

procedure InitTextExample;
begin
 if (fWide) then
 begin
  StringToWideChar (s, wideExample, sizeOf (wideExample));
  _vsize := Length (s);
  exampleText := @wideExample;
 end
 else
 begin
  StrPCopy (textExample, s);
  _vsize := Length (s) shl 1;
  exampleText := @textExample;
 end;
end;

function        GetScanProc;
begin
 result := @ScanSimple;
 // выборка по правилу поиска
 case r.rule of
  $10..$7F : result := @scanUnknow;
       $80 : case r.vsize of
              1: result := @ScanRangeB;
              2: result := @ScanRangeW;
              4, 8: result := @ScanRangeD;
             end;
      $100 : result := @scanFirstDig;
 end;
 // выборка по типу значения
 case r._class of
   st_text : result := @scanText;
   st_wide : result := @scanWide;
   st_real : if (ExampleMin >= ExampleMax) then else result := @scanRangeD;
 end;
end;  // GetScanProc;

function  GetSieveProc;
begin
 result := @SieveSimple;
 dataneed := NPACKED;
 case r.rule of
    $10..$7F : result := @SieveUnknow;
        $100 : result := @SieveFirstDig;
         $80 : case r.vsize of
                1: result := @SieveRangeB;
                2: result := @SieveRangeW;
                4, 8: result := @SieveRanged;
               end;
   end;
 case r._class of
   st_text : result := @sieveText;
   st_wide : result := @sieveWide;
   st_real : if (ExampleMin >= ExampleMax) then else result := @SieveRanged;
 end; // case 2
 if (@result = @SieveSimple) or
    (@result = @SieveRangeD) or
    (@result = @SieveRangeW) or
    (@result = @SieveRangeB)   then dataneed := SETPACK; // Требуются данные средней упаковки
end; // GetSieveProc


procedure  TestAlign (var x; mask: dword);
var
   ttp: pointer;
   ttd: dword absolute ttp;
begin
 ttp := @x;
 {$IFOPT D-}
 if ttd and mask <> 0 then
 begin
  LogStr ('Variables is unaligned - optimize spacer');
  OutputDebugString ('Build depended-error caused'#13#10);
  asm int 3 end;
  raise Exception.Create(
        format (#13'Internal RTC: Unaligned variable ptr = $%x mask = $%.4x'#13#10 +
                'Need to insert %d bytes before'#13,
                               [ttd, mask, mask + 1 - (ttd and mask)] ));
 end;
 {$ENDIF}
end;

var
   dwh: dword absolute pwhole;
   dph: dword absolute pprevd;
     n: dword;
initialization
 pwhole := @fwhole;
 pprevd := @fprevd;
 for n := Low (aligner) to High (aligner) do
  aligner [n] := 0;
 TestAlign (fwhole, $3F); // must be aligned at 64
 TestAlign (temp, $0F); // must be aligned at 16
 if (dwh and $3F > 0) then dwh := dwh or $3F + 1;
 if (dph and $3F > 0) then dph := dph or $3F + 1;
 _mask0 := $1000000001;
 _mask1 := $180018001800180;
 _mask2 := $0008000200080002;
 _mask3 := $0010000100100001;
end.








