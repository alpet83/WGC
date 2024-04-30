unit ChSource;
interface
uses Classes, SysUtils, Windows, Types, ChConst;
// Классы источников (приемников врочем тоже) данных. По аналогии с TStream
{
   Для создания производных классов достаточно переопределить в потомках
   методы read и write.

   Для поддержки Spy-Mode надо реализовать поддержку буфера, в который
   по умолчанию будет закидываться информация и возвращаться прямой указатель
   на него.
}

type
    TSource = class (TStream)
    private
     FPosition: dword;
    public
     dwResult: dword; // количество проработанных байт
     function         Seek (Offset: LongInt; Origin: Word): Longint; override;
     function         DSeek (offset: LongInt): boolean; virtual;
     // считывание вещественных значений - single, real, double, extended)
     function         ReadFloat (offst, sz: dword): Extended; virtual;
     // считывание целых значений
     function         ReadInt (offst, sz: dword): Int64; virtual;
     // считывание текстовых значений
     function         ReadText (offst, sz: dword;
                                fWide: boolean): string; virtual;
     // запись вещественных значений
     procedure        WriteFloat (offst, sz: dword; const e: extended); virtual;
     // запись целых значений
     procedure        WriteInt (offst, sz: dword; const i: Int64); virtual;
     // запись текстовых значений
     procedure        WriteText (offst, sz: dword;
                                fWide: boolean; const s: string); virtual;
    end; // TSource

  TProcessSrc = class (TSource)
  public
   hProcess: THandle; // hProcess is uses for ReadProcessMemory & WriteProcessMemory
   constructor        Create;
   function           Read (var buffer; Count: Longint): Longint; override;
   function           Write (const buffer; Count: LongInt): Longint; override;
  end; // TProcessSrc

var
   dsrc: TSource; // TProcessSrc is implemented
// получение текстового представления значения
function  ReadProcessValue (offst, vtype: dword): string;
function  WriteProcessValue (offst, vtype: dword; const s: string): boolean;

implementation
uses Misk;

{ Function and Procedures  }
function  ReadProcessValue (offst, vtype: dword): string;
var
   s: string;
begin
 s := 'n/a';
 case vtype of
  // на этом диапазоне тип значения эквивалентен его размеру
  WHOLE1_TYPE..WHOLE8_TYPE :
             s := IntToStr (dsrc.ReadInt(offst, vtype));
  // на этом диапазоне тип значения равен его размеру * 256
  SINGLE_TYPE, REAL48_TYPE,
  DOUBLE_TYPE, EXTEND_TYPE :
             s := FloatToStr (dsrc.ReadInt (offst, vtype shr 8));
  ANTEXT_TYPE: s := dsrc.ReadText (offst, 255, false);
  WDTEXT_TYPE: s := dsrc.ReadText (offst, 255, true);
 end;
 if dsrc.dwResult = 0 then s := 'n/a'; // ничего не прочиталось
 result := s;
end; // ReadValue;
function  WriteProcessValue (offst, vtype: dword; const s: string): Boolean;
var i64: Int64;
      e: Integer;
begin
 case vtype of
  // на этом диапазоне тип значения эквивалентен его размеру
  WHOLE1_TYPE..WHOLE8_TYPE :
        begin
         val (StrExt (s), i64, e);
         dsrc.WriteInt (offst, vtype, i64);
        end; 
  // на этом диапазоне тип значения равен его размеру * 256
  SINGLE_TYPE, REAL48_TYPE,
  DOUBLE_TYPE, EXTEND_TYPE :
             dsrc.WriteFloat (offst, vtype shr 8, StrToFloat (s));
  ANTEXT_TYPE: dsrc.WriteText (offst, 0, false, s);
  WDTEXT_TYPE: dsrc.WriteText (offst, 0, true, s);
 end;
 result := dsrc.dwResult > 0; // хоть что-то записано ?
end; // ReadValue;

{ TSource }
function TSource.DSeek(offset: Integer): boolean;
begin
 result := Seek (offset, soFromBeginning) = offset;
end;

function TSource.ReadFloat (offst, sz: dword): Extended;
var
   fx: Extended;
   f4: Single absolute fx;
   f6: Real48 absolute fx;
   f8: Double absolute fx;

begin
 fx := 0.0;
 DSeek (offst);
 if (sz > 0) and (sz <= 10) then Read (fx, sz);
  try
   case sz of
    4: result := f4;
    6: result := f6;
    8: result := f8;
    else result := fx;
   end;
  except
   on EInvalidOp do result := 0.0;
  end;
end; // ReadFloat

function TSource.ReadInt(offst, sz: dword): Int64;
begin
 result := 0;
 DSeek (offst);
 if (sz > 0) and (sz <= 8) then Read (result, sz);
end; // ReadInt

function TSource.ReadText;
var
   wide: array [0..256] of WideChar;
   ansi: array [0..256] of char absolute wide;
begin
 DSeek (offst);
 if (sz > 256) then sz := 256;
 Read (wide, sz);
 if fWide then
  begin
   wide [sz] := #0; // terminating ASCIIZ
   result := WideCharToString (wide)
  end
 else
  begin
   ansi [sz] := #0;
   result := ansi;
  end; 
end; // ReadText

function TSource.Seek(offset: Integer; origin: word): Longint;
begin
 if (origin = soFromBeginning) then FPosition := offset;
 if (origin = soFromCurrent) then Inc (FPosition, offset);
 if (origin = soFromEnd) then FPosition := High (dword) - dword (offset);
 result := FPosition;
end; // Seek

procedure TSource.WriteFloat(offst, sz: dword; const e: extended);
var
   fx: extended;
   f4: Single absolute fx;
   f6: Real48 absolute fx;
   f8: double absolute fx;
begin
 if sz > 10 then sz := 10;
 if sz = 0 then sz := 4;
 case sz of
  // обрезание точности
  4: f4 := e;
  6: f6 := e;
  8: f8 := e;
  else fx := e;
 end;
 DSeek (offst);
 Write (fx, sz);
end; // WriteFloat

procedure TSource.WriteInt(offst, sz: dword; const i: Int64);
begin
 if sz > 8 then sz := 8;
 if sz = 0 then sz := 1;
 DSeek (offst);
 Write (i, sz);   
end; // WriteInt

procedure TSource.WriteText(offst, sz: dword; fWide: boolean;
  const s: string);
var
   atxt: array [0..256] of char;
   wtxt: array [0..256] of WideChar absolute atxt;
begin
 if sz > 512 then sz := 512;
 if sz = 0 then sz := Length (s) + 1; // with zerro
 DSeek (offst);
 if fWide then StringToWideChar (s, @wtxt, 256)
          else StrPCopy (atxt, s);
 Write (wtxt, sz);           
end; // WriteText

{ TProcessSrc }

constructor TProcessSrc.Create;
begin
end; // TProcessSrc.Create

function TProcessSrc.Read(var buffer; Count: Integer): Longint;
begin
 ASSERT (hProcess <> 0, 'Обращение к TProcessSrc.Read, hProcess = 0');
 if (hProcess <> 0) then
  ReadProcessMemory (hProcess, pointer (position), @buffer,
                        count, dwResult);
 result := dwResult;
end; // Read


function TProcessSrc.Write(const buffer; Count: Integer): Longint;
begin
 ASSERT (hProcess <> 0, 'Обращение к TProcessSrc.Write, hProcess = 0');
 if (hProcess <> 0) then
    WriteProcessMemory (hProcess, pointer (position), @buffer,
                           count, dwResult);
 result := dwResult;
end; // Write

initialization
 dsrc := TProcessSrc.Create;
finalization
 dsrc.Free; 
end.
