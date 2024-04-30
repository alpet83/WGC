unit ChCheat;

interface
uses Windows, SysUtils, misk, ChTypes, Grids, CheatTable;



{
function    GetChValue (n : Integer; var s: string) : boolean;
function    GetChStrVal (n : Integer; var s : string) : boolean;
function    GetChReal (n : Integer; var s : string) : boolean;
}

implementation
Uses ChForm, ChCmd, ChShare, Math, ChSource,
        ChPointers, ChClient;
const lockArray : array [0..1] of string = ('', 'LOCK');
(*
var

   TableSize: Integer = 256;



procedure   ResizeTable (newSize: Integer);
begin
 TableSize := newSize;
 SetLength (ChTable, TableSize);
end;

procedure   AdjustTableSize;
var count: Integer;
begin
 gAddrTable := mform.sgt;
 count := gAddrTable.RowCount;
 // 10
 if (count + 32 > tableSize) or    // test for enlarge
    (tableSize - count > 256) then // test for pack
      ResizeTable (count + 32);
end;


function GetMaxItemIndex: Integer;
begin
 // determine maximal index
 gAddrTable := mform.sgt;
 result := min (TableSize, gAddrTable.RowCount) - 1;
end;

procedure   KillCheat (const sgt: TStringGrid; const num: dword);

procedure CopyRow (const ns, nd: dword);
var x : dword;
begin
 with sgt do
 for x := 1 to ColCount do
  begin
   cells [x - 1, nd] := cells [x - 1, ns]; // Копировать по ячекам
   // Rows [nd] := Rows [ns]; // Копировать по строкам
  end;
end;
var n : dword;
begin
 with sgt do
  begin
    // Смещение строк
    for n := num to RowCount - 1 do CopyRow (n + 1, n);
    // Очистка последней строки таблицы
    for n := 1 to ColCount do cells [n - 1, RowCount - 1] := '';
  end;
end; // KillCheat


procedure   CheatsUpd (const sgt: TStringGrid; const filt: boolean = false);

procedure       Change (num: Integer; const s: string);
begin
  if (sgt.Cells [3, num] <> s) then sgt.cells [3, num] := s;
end; // Display


 var
  rqsn: byte;
     n: Integer;
     s: string;
     maxItem: Integer;

 begin
  maxItem := GetMaxItemIndex;
  with gAddrTable do
 { Обновление текущий значений }
  for n := 1 to maxItem do
  if chTable [n].enabled then
   begin
    s := 'n/a';
    // cells [3, n] := '';
    chTable [n].vtype := st_int; // default
    str2type (cells [5, n], chTable [n].vtype, chTable [n].vsize);
    (*
    case chTable [n].vtype of
     st_real :
      begin
       if GetChReal (n, s) then;
       if chTable [n].lock then
          if CheatReal (n) then else SetValLock (n, 0);
      end;
     st_int :
      begin
       if GetChValue (n, s) then;
       { Запись замороженных значений }
       if chTable [n].lock then
          if CheatIt (n) then else SetValLock (n, 0); // блокировка снимается
      end;
     st_text, st_wide :
      begin
       if GetChStrVal (n, ns) then s := ns;
       if chTable [n].lock then
          if CheatText (n) then else SetValLock (n, 0);
      end;
    end; // case

    Change (n, s);
   end; // for control
   // TODO: Move filtration code to server side
   if (filt) then
   for n := 1 to maxItem do
   if chTable [n].enabled then
   with sgt do
     begin
      rqsn := chtable [n].rqsn;
      if (rqsn <> 0) then
       begin
        // Сверка значений
        s := csm.RqsLst [rqsn].textEx;
        if (s <> cells [3, n]) then
                        KillCheat (sgt, n); // Убрать эту строку из таблицы
       end;
     end; // Проверка на верность
end; // CheatsUpdate;

procedure   SetValLock (const n: Integer; const l: Integer);
begin
 gAddrTable.cells [0, n] := lockArray [l];
end; // SetValLock


procedure  ConvertChTable;
function GetIntCell (x, y: Integer) : LongInt;
var
   s : string;
   l : LongInt;
   c : Integer;
begin
 result := 0;
 s := mform.sgt.cells [x, y];
 if s = '' then exit;
 s := StrExt (s);
 Val (s, l, c);
 if c = 0 then GetIntCell := l;
end; // GetIntCell

function GetRealCell (x, y: Integer) : Extended;
var
   s: string;
   e: Extended;
   c: Integer;
   
begin
 GetRealCell := 0.0;
 s := gAddrTable.cells [x, y];
 if s = '' then exit;
 s := StrExt (s);
 val (s, e, c);
 if c = 0 then
 GetRealCell := e;
end; // GetIntCell


var n, maxItem: Integer;
    s: String;
begin
  maxItem := GetMaxItemIndex;
 if TableSize < gAddrTable.RowCount then
    ResizeTable (gAddrTable.RowCount);
 for n := 1 to maxItem do
 with gAddrTable, ChTable [n]  do
   if (cells [2, n] <> '') then
    begin
     ptr := DecodePtr (_alias, cells [2, n]);
     s := cells [X_DESCR, n];
     StrLCopy (descr, PChar (s), 32);
     lock := cells [X_LOCK, n] <> '';
     vald := GetIntCell (X_VALUE, n);
     valr := GetRealCell (X_VALUE, n);
     s  := cells [X_VALUE, n];
     StrLCopy (valt, PChar (s), 32);
     StringToWideChar (s, valw, 32);
     rqsn := GetIntCell (X_FILTER, n);
     ChTable [n].enabled := true;
     str2type (cells [X_TYPE, n], vtype, vsize);
     hex := (vtype = st_int) and (pos ('H', UpperCase (cells [X_TYPE, n])) > 0);
     if gAddrTable.Cells [X_TYPE, n] = '' then vsize := 4;
    end
   else enabled := false;
end; // ConvertChTable

    (**)
end.
