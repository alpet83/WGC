unit ChText;

interface

{  Адаптация и развитие HEX-редактора:
   1. Огранизация подкачки и модификации данных через сеть
    1.2 Сетевой вариант должен включаться когда явно идет удаленная работа с
     сервером. В остальное время может использоваться локальный механизм добычи
     данных (ReadProcessMemory).
   2. Цветовое выделение изменяющихся значений (с настройкой периода обновления)
   3. Реализация выделения с клавиатуры и мыша
   4. Создание сохраняемых закладок для адресов
}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls;

const
     NChars = [#32..#$FF];
     HChars = ['0'..'9', 'A'..'F'];

type
  Tmedit = class(TForm)
    panx: TPanel;
    ed_addr: TEdit;
    cbView: TComboBox;
    btnHide: TButton;
    lbAddrs: TListBox;
    ed_ofs: TEdit;
    rgShift: TRadioGroup;
    cbSize: TComboBox;
    DrawTimer: TTimer;
    Flush: TMemo;
    kfbtn: TButton;
    cbIndigCaret: TCheckBox;
    lbCaretPos: TLabel;
    lbCopyPaste: TLabel;
    procedure btnHideClick(Sender: TObject);
    procedure btnDumpClick(Sender: TObject);
    procedure lbAddrsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure DrawTimerTimer(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure FlushKeyPress(Sender: TObject; var Key: Char);
    procedure FlushKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure kfbtnEnter(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    insMode: Boolean;

    DumpOfs: DWORD;
    DumpMaxX: Integer;
    DumpMaxY: Integer;
    procedure DumpMem;
    procedure DrawCaret(x, y: Integer);
    procedure EditHex(var s: string; var pt: TPoint; key: char);
    procedure EditTxt(var s: string; var pt: TPoint; Key: char);
    procedure SetOffset (ofs: Dword);
    procedure WriteHex (const s: string; pt: TPoint);
    function  TokOfst(xs: Integer): DWord;
    function  FullStrTok(const s: string; var dst: string;
      xps: Integer): Integer;
    procedure SwitchMode;
    procedure WriteTxt(const s: string; pt: TPoint);
    function GetColumnPos(nColumn: Integer): Integer;
    function CalcOfs(x, y: Integer; hexMode: Boolean): DWORD;
    function GetCaretOfs: DWORD;
    procedure AdjustSel(prv, cur: DWORD);
    procedure AlignCaretByOfs (dir: Integer);
    procedure PerformCopy;
    procedure PerformPaste;
    function FormatHexData(psrc: Pointer; nBytes: DWORD): String;
    procedure GetCPByClientPos(x, y: Integer; var cp: TPoint);
    { Private declarations }
  public
    { Public declarations }
    Offsets: array [0..16383] of DWORD; // Для смещения/адреса
      ofscnt: dword;
       vsize: dword;
    selStart: DWORD;   // selection pointer
    selLimit: DWORD;
   hexBounds: TRect;   // Ограничение Hex
   txtBounds: TRect;   // Ограничение Txt 
       ybase: Integer;
    HexLines: TStrings; // Для 16-кодов
    TxtLines: TStrings; // Для текста
    CaretPos: TPoint;
      cpBuff: Pointer;  // Буффер для копирования/вставки
      bfSize: Integer;  // Размер буфера и его содержимого
        buff: TBitMap;  // Буффер для рисования
       blcnt: byte;     // Для мерцания каретки
       blink: boolean;  // Для каретки
    CaretHex: Boolean;  // Каретка в hex поле
     freaded: Boolean;  // Память прочитана

    property columns [index: Integer]: Integer read GetColumnPos; // значения столбцов в символьных смещениях

    procedure          DrawDump (dc: HDC = 0); // Рисование дампа на окне
    procedure          PaintBuff;
  end;

  
var
  medit: Tmedit;

implementation
uses ChTypes, ChShare, ChCmd, ChForm, Misk, ChHeap, ChMsg, ChClient, Clipbrd;

{$R *.dfm}

procedure Tmedit.btnHideClick(Sender: TObject);
begin
 hide;
end;

type
     Bytevec = array [0..1048575] of byte;
     Wordvec = array [0..1048575] of word;
     Longvec = array [0..1048575] of LongWord;
     Qwrdvec = array [0..1048575] of Int64;
     Charvec = array [0..1048575] of AnsiChar;
     Widevec = array [0..1048575] of Widechar;
     TDumpMode = (dmHexByte, dmHexWord, dmHexDWord, dmHexQWord, dmText, dmWide);

const
     HexModes: array [0..3] of TDumpMode =
      (dmHexByte, dmHexWord, dmHexDWord, dmHexQWord);
var
   fCRLF: boolean;
   dmode: TDumpMode;
   fedit: boolean = false;
   dfirst, dlast: Byte; // Позиции доступные для цифрового (hex) редактирования
   tfirst, tlast: Byte; // Позиции доступные для текстового редактирования

function GetHex (const src: pointer; var stxt: string; const ofst, typ : dword) : string;

var
    bv: array [0..15] of Byte;
    wv: array [0..07] of Word absolute bv;
    dv: array [0..03] of DWord absolute bv;
    qv: array [0..01] of Int64 absolute bv;
    n: dword;
    s: string;
begin
 Assert (Src <> nil, 'Использование nil в дампе');
 Assert (ofst < 16384, 'Уход за границы буффера');
 s := '';
 Move (byteVec (src^)[ofst], bv, 16);
 //   {$R-}
  case typ of
   1 : begin
        dfirst := 1; // Первый символ
        for n := 0 to 15 do s := s + Byte2Hex (bv [n]) + ' ';
        dlast := Length (s) - 2; // Последний
        tfirst := 1;
        stxt := '';
        for n := 0 to 15 do // Текстовый эквивалент
        if char (bv [n]) in NChars then stxt := stxt + char (bv [n])
           else  stxt := stxt + '.';
        tlast := tfirst + 16; // Общий порядок
       end; // BYTES
    2 : for n := 0 to 7 do
          s := s + Word2Hex  (wv [n]) + ' ';
    4 : for n := 0 to 3 do
          s := s + Dword2Hex (dv [n]) + ' ';
    8 : for n := 0 to 1 do
          s := s + IntToHex (qv [n], 16) + ' ';
   end;
 result := s;
 fCRLF := true;
 {$R+}
end;

function LastSP (const s : string) : byte;
var n : byte;
begin
 result := 0;
 for n := Length (s) downto 1 do
  if s [n] = ' ' then
   begin
    result := n;
    break;
   end;
end; // LastSP


function GetText (const src : pointer;var ofst, ss : dword) : string;
var s : string;
    n : dword;
    ch : AnsiChar;
begin
 {$R-}
 s := '';
 ss := 00;
 for n := 0 to 74 do
  begin
   ch := charvec (src^) [n + ofst];
   inc (ss);
   if (ch = #13) then
    begin
     fCRLF := true;
     break;
    end;
   if ch in NChars then s := s + ch;
  end;
 {$R+}      
 result := s;
end;

function GetWide (const src : pointer;var ofst, ss : dword) : string;
var s : string;
    n : dword;
    ch : WideChar;
begin
 {$R-}
 s := '';
 ss := 00;
 for n := 0 to 74 do
  begin
   ch := widevec (src^) [n + ofst];
   inc (ss);
   s := s + ch;
   if (ch = #0013) or (ch = #0000) then
    begin
     fCRLF := true;
     break;
    end;
  end; {}
 {$R+}
 result := s;
end;




procedure TMedit.btnDumpClick(Sender: TObject);

begin
 DumpMem;
end;//

function   ReadMemoryEx (ipAddr, buff: Pointer;
                         dwSize: dword; var read: dword): Boolean;
{ Функция постраничного чтения памяти }
var
   rsz, rd: dword;
   psrc: dword;
   pdst: dword;

begin
 read := 0;
 psrc := dword (ipAddr);
 result := FALSE;
 pdst := dword (buff);
 if client.localMode then // В противном случае надо через сеть данные получать...
 repeat
  rsz := $1000 - (psrc and $FFF); // Сначала снять остаток
  if (rsz = 0) then rsz := 4096; // По 16 байт далее
  if (dwSize < rsz) then rsz := dwSize;
  result := ReadProcessMemory (csm.svars.alias,
                      ptr (psrc), ptr (pdst), rsz, rd);

  inc (psrc, rsz); // Смещение источника
  inc (pdst, rsz); // Смещение приемника
  inc (read, rd);  // Кол-во считано
  dec (dwSize, rsz);  // Вычесть пройденное
 until (dwSize = 0);
end; // ReadProcessMemory

function   WriteMemoryEx (ipAddr, src: Pointer; dwSize: DWORD; var write: DWORD): Boolean;
var wsz, wd: DWORD;
    psrc, pdst: DWORD;
begin
 result := false;
 psrc := DWORD (src);
 pdst := DWORD (ipAddr);
 write := 0;
 if client.localMode then // В противном случае надо через сеть данные получать...
 repeat
  wsz := $1000 - (pdst and $FFF); // Сначала снять остаток
  if (wsz = 0) then wsz := 4096; // Исключить холостую итерацию
  if (dwSize < wsz) then wsz := dwSize;
  result := WriteProcessMemory (csm.svars.alias,
                      ptr (pdst), ptr (psrc), wsz, wd);

  inc (psrc, wsz); // Смещение источника
  inc (pdst, wsz); // Смещение приемника
  inc (write, wd);  // Кол-во считано
  dec (dwSize, wsz);  // Вычесть пройденное
 until (dwSize = 0);

end;

function   TMedit.CalcOfs;
begin
 if y < 0 then y := 0;
 if hexMode then
    result := DWORD (x) div (vsize * 2 + 1) + offsets [y]
 else result := DWORD (x) + offsets [y];
end;

function   TMedit.GetCaretOfs: DWORD;
begin
 result := CalcOfs (CaretPos.x - 1, CaretPos.y - 1, CaretHex)
end;

function   TMedit.GetColumnPos (nColumn: Integer): Integer;
begin
 case dmode of
  dmHexByte,
  dmHexWord,
  dmHexDWord,
  dmHexQWord: result := nColumn * Integer (vsize * 2 + 1);
 else result := nColumn;
 end;
end;

procedure  TMedit.DumpMem;
var
   ssize, r : dword;
   last, maxview, hs : dword;
   n, scnt, ofst : dword;
   shft : dword;
   buff : pointer;
   e : Integer;
   bs, s : string;
   p : pointer;
   
begin
 if csm.svars.alias = 0 then exit;
 hs := 1 shl cbSize.ItemIndex; // 1, 2, 4, 8
// val (ed_size.text, maxview, e);
 val (ed_addr.text, ofst, e);
 val (ed_ofs.text, shft, e);
 DumpOfs := ofst;
 HexLines.Clear;
 TxtLines.Clear;
 ofscnt := 0;
 // Reserving memory
 maxview := 8192;
 MemSrv (buff, maxview, MALLOC);
 p := pointer (ofst);
 if rgShift.ItemIndex = 0 then p := Pointer (ofst + shft);
 if rgShift.ItemIndex = 1 then p := Pointer (ofst - shft);
 FillChar (buff^, maxview, 0);
 freaded := ReadMemoryEx (p, buff, maxview, r);
 if (not freaded) then r := maxview;
 fCRLF := false;
 case cbView.ItemIndex of
  0 : dmode := HexModes [cbSize.ItemIndex];
  1 : dmode := dmText;
  2 : dmode := dmWide;
 end;
 vsize := 1;
 if (dmode <> dmHexByte) and not CaretHex then
  begin
   CaretHex := true;
   CaretPos.x := 1;
  end;
 case dmode of
   dmHexWord: vsize := 2;  // для слов
  dmHexDWord: vsize := 4; // для дв. слов
  dmHexQWord: vsize := 8; // для чт. слов
 end;
 s := '';
 case dmode of
  dmHexByte: for n := 0 to 15 do
    s := s + Byte2Hex ( n + ofst and $F) + ' ';
  dmHexWord: for n := 0 to 7 do
   s := s + Word2Hex (n shl 1 + ofst and $FFFF) + ' ';
  dmHexDWord: for n := 0 to 3 do
   s := s + DWord2Hex (n shl 2 + ofst) + ' ';
  dmHexQWord: for n := 0 to 1 do
   s := s + IntToHex (n shl 3 + ofst, 16) + ' ';
 end;
 scnt := 0; // Счетчик строк
 HexLines.Add (s);
 TxtLines.Add ('void'); // TODO: Module name
 ofst := 0;
 s := '';
 bs := '';
 if buff <> nil then
 repeat
  last := ofst;
  offsets [ofscnt] := dword (p) + ofst;   // Смещение
  inc (ofscnt);
  case cbView.ItemIndex of
   0: begin
        HexLines.Add ( GetHex (buff, s, ofst, hs) );
        if (s <> '') then TxtLines.Add (s);
        ofst := ofst + 16;
       end;
   1: begin
        TxtLines.Add ( GetText (buff, ofst, ssize) );
        ofst := ofst + ssize;
       end;
   2: begin
        TxtLines.Add ( GetWide (buff, ofst, ssize) );
        ofst := ofst + ssize * 2;
       end;
  end;
  // UI Update
  inc (scnt);
 until (ofst >= r - 160) or (ofst = last) or (scnt > 1000);
 MemSrv (buff, maxview, MFREE);
 DrawDump;
end;

procedure Tmedit.lbAddrsClick(Sender: TObject);
var n : LongInt;
begin
 n := lbAddrs.ItemIndex;
 if n >= 0 then
   ed_addr.Text := lbAddrs.Items [n];
end;

procedure  TMedit.EditHex (var s: string; var pt: TPoint; key: char);
var
   ls, lst: Integer;
   px: Integer;
   eos: Boolean;
begin
 // Цифровое редактирование
 if (UpCase (key) in HChars) then else exit;
 ls := length (s);
 lst := min (dlast + 1, ls);
 px := pt.x + 1;
 if (px = 0) then px := 1;
 // Допустима замена символа
 while (px < lst)
        and not (s [px] in HChars) do
              inc (px); // пропуск пробелов

 if (px <= lst) and
    (s [px] in HChars) then s [px] := UpCase (Key);

 eos := px > lst;
 if not eos then
  begin
   Inc (px);
   eos := pt.x > lst; // тест 2
   if not eos and
          (s [px] = ' ') then inc (px); // пропуск пробела
  end;
 eos := eos or (pt.x >= dlast); // тест 2
 if eos and (pt.y < DumpMaxY) then
  begin
   px := 1;
   inc (pt.y);
  end;
 pt.x := px - 1;
end; // EditHex

procedure TMedit.EditTxt (var s: string; var pt: TPoint; Key: char);
var
   ls: Integer;
   eos: Boolean;
begin
 ls := Length (s);
 eos := (pt.x > 16);
 if not eos and (ls >= pt.X) then
  begin
   s [pt.x] := Key;
   inc (pt.X);
  end;
 eos := (pt.x > 16);
 if eos and (pt.y < DumpMaxY) then
  begin
   pt.x := 1;
   inc (pt.y);
  end;
end; // EditTxt

procedure TMedit.DrawCaret (x, y: Integer);
begin
 if (blcnt > 0) then dec (blcnt) else blink := not blink;
 if blink and flush.Focused then
 with buff.canvas do
 begin
  pen.color := clWhite;
  MoveTo (x, y);
  LineTo (x, y - 16);
 end;
end;

procedure TMedit.PaintBuff;


var y, n, ystp: Integer;
    smax, ofsx: Integer;
        curofs: DWORD;
       s: string;
     szv, tw, twe: Integer;
     fr, ir: TRect;
     rgn: HRGN;

function GetSLeft (nCount: Integer): String;
begin
 result := Copy (s, 1, nCount);
end; // GetSLeft

begin
 with buff, buff.canvas do
  begin
   brush.Style := bsSolid;
   brush.Color := clNavy;  // Закраска фона
   pen.Color := clWhite;
   pen.Style := psSolid;
   Rectangle (0, 0, Width - 1, Height - 1); // Рисование рамки
   SetRect (ir, 2, 2, Width - 3, Height - 3);
   Rectangle (ir);
   fr := ir;
   inc (ir.Top, 20);
   Rectangle (ir);
   rgn := CreateRectRgn (2, 2, Width-4, Height-4); // Создание региона
   ExtSelectClipRgn (canvas.handle, rgn, RGN_COPY); // Выбор региона отсечки
   //dec (ir.right, 20); // Для полосы прокрутки
   font.Name := 'Courier';
   font.Size := 8;
   font.Pitch := fpFixed;
   font.Color := clYellow;
   ystp := 1 + canvas.TextHeight('|');
   ofsx := ir.Left + 3;
   ybase := ir.top + 2;
   DumpMaxX := 0;
   DumpMaxY := 0;
   if (dmode <= dmHexQWord) then
    begin
     y := ir.top + ystp * (CaretPos.Y - 1) + 1;
     Brush.Color := clBlue;
     FillRect (Rect (ir.Left + 2, y, ir.Right, y + 16));
     Brush.Color := clNavy;
     SetBkMode (Canvas.handle, Windows.TRANSPARENT);
     s := Dword2hex (GetCaretOfs);
     TextOut (ofsx, ybase - 18, s);  // Вывод смещения
     // Вывод смещений
     y := ybase;
     smax := 0;
     for n := 1 to ofscnt do
      begin
       s := Dword2hex (offsets [n - 1]);
       TextOut (ofsx, y, s);  // Вывод смещения
       smax := max (smax, TextWidth (s));
       y := y + ystp;
       if (y > buff.Height) then break;
      end;
     ofsx := ofsx + smax + 10;
     MoveTo (ofsx - 5, fr.top);
     LineTo (ofsx - 5, fr.Bottom);
     // Вывод Hex данных
     Font.Color := clCream;     // color
     y := ir.top - 18;
     // Заголовок смещений
     if (HexLines.count > 0) then
      begin
       s := HexLines [0];
       TextOut (ofsx, y, s);      // Header
      end;
     y := ybase;           // y start
     HexBounds.Top := ybase;
     HexBounds.Left := ofsx;
     if vsize <> 0 then szv := vsize else szv := 1;

     // Вывод собственно данных
     for n := 1 to HexLines.Count - 1 do
      begin
       s := HexLines [n];
       curofs := offsets [n - 1];
       // curofs...selstart...(curofs + LineSize)
       // curofs...
       // Подготовка фона для выделенного фрагмента
       if (selStart <= curofs + 15) and (curofs <= selLimit) and
           (selStart < selLimit) then
         begin
          tw := (Integer (selStart) - Integer(curofs)) div szv;
          if (tw < 0) then tw := 0;
          if selLimit > curofs then
               twe := min (Integer (selLimit) - Integer (curofs), 16)
          else twe := 0;
          twe := twe div szv;
          if (twe < 0) then twe := 0;

          tw := TextWidth (GetSLeft (columns [tw]));
          if twe > 0 then
             twe := TextWidth (GetSLeft (columns [twe] - 1)) + 1; // include symbol?
          Canvas.Brush.Color := clPurple; // для выделения данных
          Canvas.Brush.Style := bsSolid;
          FillRect (Rect (tw + ofsx, y, ofsx + twe, y + ystp));
          Canvas.Brush.Color := clNavy; // для выделения данных
          Canvas.Brush.Style := bsClear;
         end;

       TextOut (ofsx, y, s);
       smax := max (smax, TextWidth (s));
       y := y + ystp;
       // Отображение каретки
       if CaretHex and (CaretPos.y = n) then
         begin
          tw := TextWidth (GetSLeft (CaretPos.x - 1));
          DrawCaret (ofsx + tw, y);
         end;
       if (y > buff.Height) then break;
       HexBounds.Bottom := y;
       DumpMaxY := n + 1;
      end;
     if CaretHex and (HexLines.Count > 0)then
         DumpMaxX := Length (HexLines [0]);
     ofsx := ofsx + smax + 2;
     MoveTo (ofsx - 5, fr.top);
     LineTo (ofsx - 5, fr.Bottom);
    end; // Hex mode
   HexBounds.Right := ofsx; 
   y := ybase;           // y start
   TxtBounds.Top := y;
   TxtBounds.Left := ofsx;
   smax := 0;
   if (txtLines.Count > 0) then
   for n := 1 to txtLines.Count - 1 do
    begin
     s := TxtLines [n];
     TextOut (ofsx, y, s);
     smax := Max (smax, TextWidth (s));
     y := y + ystp;
     if not CaretHex and (CaretPos.y = n) then
      begin
       tw := TextWidth (copy (s, 1, CaretPos.x - 1));
       DrawCaret (ofsx + tw, y);
      end;
     if (y > buff.Height) then break;
     TxtBounds.Bottom := y;
     DumpMaxY := n;
    end;
   ofsx := ofsx + smax; 
   TxtBounds.Right := ofsx;
   if not CaretHex then DumpMaxX := 16;
   ExtSelectClipRgn (canvas.handle, rgn, RGN_DIFF);
   DeleteObject (rgn);
  end; // with
end; // PaintBuff;

procedure Tmedit.DrawDump(dc: HDC);
var
   fres: Boolean; // Зарезервирован dc
   cnv: TCanvas;
begin
 fres := (dc = 0);
 if (fres) then dc := Canvas.Handle;
 cnv := TCanvas.Create;
 cnv.Handle := dc;
 // Рисование
 PaintBuff;
 // Вывод
 cnv.CopyRect(Rect (5, 5, 4 + buff.Width, 4 + buff.Height),
               buff.Canvas,
              Rect (0, 0, buff.Width - 1, buff.Height - 1));
 cnv.Handle := 0;
 cnv.Free;
end; // DrawDump

procedure Tmedit.FormCreate(Sender: TObject);
begin
 cpBuff := nil;
 bfSize := 0;
 blcnt := 0;
 ofscnt := 0;
 selStart := 0;
 selLimit := 0;
 HexLines := TStringList.Create;
 TxtLines := TStringList.Create;
 CaretHex := true;
 CaretPos.y := 1;
 CaretPos.x := 2;
 buff := TBitmap.Create;
 buff.Width := Width - 20;
 buff.Height := panx.top - 10;
 buff.PixelFormat := pf32bit;
end; // Create;

procedure Tmedit.FormDestroy(Sender: TObject);
begin
 HexLines.Free;
 TxtLines.Free;
 FreeMem (cpBuff);
end;

procedure Tmedit.FormPaint(Sender: TObject);
begin
 DrawDump;
end;

procedure Tmedit.FormResize(Sender: TObject);
var
   rgn, rgn2: HRGN;
   r: TRect;
begin
 buff.Width := Width - 20;
 buff.Height := panx.top - 10;
 r := GetClientRect;
 r.Bottom := panx.Top - 3;
 rgn :=  CreateRectRgnIndirect (r);
 rgn2 := CreateRectRgnIndirect (Rect (5, 5, buff.width + 4, buff.Height + 4));
 CombineRgn (rgn, rgn, rgn2, RGN_DIFF);
 InvalidateRgn (Handle, rgn, true);
 DrawDump;
end;

procedure Tmedit.DrawTimerTimer(Sender: TObject);
begin
 if (visible) then DumpMem;
end;

procedure Tmedit.GetCPByClientPos (x, y: Integer; var cp: TPoint);
begin
 dec (x, 5);
 dec (y, 5);
 with hexBounds do
 if (x > Left) and (x < Right) and
    (y > Top) and (y < Bottom) then
  begin
   CaretHex := true;
   cp.X := 1 + (x - left) div buff.Canvas.TextWidth('0');
   cp.Y := 1 + (y - top - 6) div (1 + buff.Canvas.TextHeight ('0'));
   if (cp.y <= 0) then cp.y := 1;
  end;

 with txtBounds do
 if (x > Left) and (x < Right) and
    (y > Top) and (y < Bottom) and (dmode = dmHexByte) then
  begin
   CaretHex := false;
   cp.X := 1 + (x - left) div buff.Canvas.TextWidth ('0');
   cp.Y := 1 + (y - top - 6) div (1 + buff.Canvas.TextHeight ('0'));
   if (cp.y <= 0) then cp.y := 1;
  end;

end;
procedure Tmedit.FormClick(Sender: TObject);
var pt: TPoint;
    
begin
 Flush.SetFocus;
 pt := Mouse.CursorPos;
 pt := ScreenToClient (pt);
 GetCPByClientPos (pt.x, pt.y, CaretPos);
 blink := true;
 blcnt := 3;
 DrawDump;
end;

procedure Tmedit.FlushKeyPress(Sender: TObject; var Key: Char);
var
   pt, ptt: TPoint;
   y: Integer;
   s: string;
begin
 // Режим редактирования
 pt := CaretPos;
 if CaretHex then
  begin
   if (dmode <= dmHexQWord) then
   begin // Редактирование Hex: BYTE,WORD,DWORD
        if (pt.y >= HexLines.Count) then
        pt.y := HexLines.Count - 1;
    y := pt.y;
    s := HexLines [y];               // Считывание
    dec (pt.x, dfirst);                     // to relative hex-pos
    ptt := pt;
    EditHex (s, pt, Key);
    WriteHex (s, ptt);        // Модификация памяти процесса
    inc (pt.x, dfirst);
   end;
  end 
  else
  if (dmode = dmHexByte) then
   begin
    if (pt.y >= TxtLines.Count) then
        pt.y := TxtLines.Count - 1;
    y := pt.y;
    ptt := pt;
    s := TxtLines [y];
    EditTxt (s, pt, Key);
    WriteTxt (s, ptt);
   end;
 CaretPos := pt;
 DumpMem;
 if (Length (flush.Text) > 1000) then flush.Clear;
 ShowCursor (true);
end; // OnKeyPress

function  TestOfs (ofsb, ofse, lim: Int64): Boolean;
begin
 result := ofse - ofsb <= lim;
end;

procedure SwapDWORD (var a, b: DWORD);
asm // var a passed as [EAX], b passed as [EDX]
 push   ebx
 mov    ebx, [eax]
 xchg   ebx, [edx]
 mov    [eax], ebx
 pop    ebx
end;

procedure Tmedit.AdjustSel (prv, cur: DWORD);
begin
 { значение смещение уменьшилось - либо уменьшение зоны выделения, за счет
   лимитной границы, либо увеличение за счет базовой
   приоритет совпадения - раздвижение...
 }
 // if prv = cur then exit;

 if prv = selLimit then selLimit := cur
  else
   if prv = selStart then selStart := cur
    else
      begin
       selStart := prv;
       selLimit := cur;
      end;
 if selStart = INFINITE then exit;
 if selLimit < selStart then SwapDWORD (selStart, SelLimit);
end;  // AdjustSel

procedure Tmedit.AlignCaretByOfs;
var dw, vx, nx, ox, lim: Integer;
begin
 //
 if not CaretHex then exit;
 dw := vsize * 2 + 1;
 ox := CaretPos.X - 1; // normal as 0 based position
 vx := ox div dw;      // count of column
 nx := vx * dw;
 if (ox > nx) then
    ox := nx;
 lim := 15;
 case vsize of
  1: lim := 15;
  2: lim := 7;
  4: lim := 3;
 end;
 if (dir > 0) and (vx < lim) then ox := ox + dw; // right move

 CaretPos.X := ox + 1;
end;
type TDWORDArray = array [0..16383] of DWORD;
     PDWORDArray = ^TDWORDArray;


function TMedit.FormatHexData (psrc: Pointer; nBytes: DWORD): String;
// Форматирует данные одной строкой.
var
    pb: PBYTEArray absolute psrc;
    pw: PWORDArray absolute psrc;
    pd: PDWORDArray absolute psrc;
    n: Integer;
begin
 result := '';
 case vsize of
  1: for n := 0 to nBytes - 1 do result := result + Byte2Hex (pb [n]) + ' ';
  2: for n := 0 to nBytes div 2 - 1 do result := result + WORD2Hex (pw [n]) + ' ';
  4: for n := 0 to nBytes div 4 - 1 do result := result + DWORD2Hex (pd [n]) + ' ';
 end;
end;

procedure Tmedit.PerformCopy;

var r: DWORD;
    cp: TClipboard;
    shex: String;
begin
 if selLimit < selStart then exit;
 if Assigned (cpBuff) then FreeMem (cpBuff);
 cpBuff := nil;
 bfSize := selLimit - selStart;
 if bfSize = 0 then exit;
 cpBuff := AllocMem (bfSize);
 FillChar (cpBuff^, 0, bfSize);
 if not ReadMemoryEx (Ptr (selStart), cpBuff, bfSize, r) then exit;
 lbCopyPaste.Caption := Format ('Copied %d bytes', [bfSize]);      
 if CaretHex then
    shex := FormatHexData (cpBuff, bfSize)
 else shex := PAnsiChar (cpBuff); // but #0 this string limited...

 cp := Clipboard; // Retrieve default keyboard.
 cp.Clear;
 cp.AsText := shex;
end; // PerformCopy...

procedure Tmedit.PerformPaste;
var w, pofs: DWORD;
begin
 if not Assigned (cpBuff) or (bfSize = 0) then exit;
 pofs := GetCaretOfs;
 if WriteMemoryEx (Ptr (pofs), cpBuff, bfSize, w) then
  lbCopyPaste.Caption := Format ('Pasted %d bytes', [bfSize]);
end;

procedure Tmedit.FlushKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var sel, sp, cp, id: Boolean;
    dir: Integer;
    pofs, cofs: DWORD;
begin
 // Обработка расширеных клавиш
 sp := (ssShift in Shift);
 sel := sp or insMode;
 id := cbIndigCaret.Checked; // перемещение каретки внутри чисел
 cp := (ssCtrl in Shift);
 pofs := GetCaretOfs; // previous caret pos
 dir := 0;
 case key of
  vk_insert: insMode := not insMode;
  ord ('C'): if cp then PerformCopy; // Perform Copy Operation
  ord ('V'): if cp then PerformPaste; // Perform Past Operation
  vk_up: if (CaretPos.y > 1) then Dec (CaretPos.y)
         else SetOffset (dumpOfs - $10);


 vk_down: if (CaretPos.y < DumpMaxY) then Inc (CaretPos.Y)
           else SetOffset (offsets [1]);

  vk_left: begin
            if (CaretPos.X > 1) then Dec (CaretPos.X);
             dir := -1
           end;
  vk_right: begin
             if (CaretPos.X < DumpMaxX) then Inc (CaretPos.X);
             dir := 1;
            end;

   vk_home: begin CaretPos.X := 1; dir := -1; end;

    vk_end: begin CaretPos.X := DumpMaxX; dir := 1; end;
  vk_prior: SetOffset (dumpOfs - $100);
   vk_next: SetOffset (dumpOfs + $100);
     vk_F5: SwitchMode;
 end;
 if (not id) and (dir <> 0) then AlignCaretByOfs (dir);
 cofs := GetCaretOfs; // Новое значения адреса под кареткой, с учетом смещения
 if sel then AdjustSel (pofs, cofs);
 lbCaretPos.Caption := Format ('%d:%d', [CaretPos.x, CaretPos.y]);
 blink := true;
 blcnt := 2;
 DumpMem;
end;

procedure Tmedit.SetOffset(ofs: Dword);
begin
 ed_addr.text := '$' + dword2hex (ofs);
end; // SetOffset

function  TMedit.FullStrTok;
var l: Integer;
begin
 l := Length (s);
 while (xps > 1) and
       (xps - 1 < l) and
       (s [xps - 1] in HChars) do dec (xps); // Поиск начала лексемы
 result := xps; // Стартовая позишен
 dst := '$';
 while (xps <= l) and (s [xps] in HChars) do
  begin
   dst := dst + s [xps]; // Добавлять символы
   inc (xps)
  end;
end; // FullStrTok

function TMedit.TokOfst (xs: Integer): DWord;
begin
 // Индекс лексемы 0-based *
 result := (DWord(xs) div (vsize shl 1 + 1)) * vsize;
end; // TokIndex

function IsWritable (prot: dword): Boolean;
begin
 result := (prot = PAGE_READWRITE) or
           (prot = PAGE_WRITECOPY) or
           (prot = PAGE_EXECUTE_READWRITE) or
           (prot = PAGE_EXECUTE_WRITECOPY);
          
end;
procedure Tmedit.WriteHex (const s: string; pt: TPoint);
var
   xs, xps: dword;
   l, dstp: dword;
   valx: Int64;
   ss: string;
   e: Integer;
   mbi: TMemoryBasicInformation;
   flock: boolean;
begin
 l := Length (s);
 ss := '$';
 xs := FullStrTok (s, ss, pt.x + 1); // Получение полной лексемы
 //  0123456789ABCDEF - index
 // "00 02 03 04 05 " - string
 //  0  1  2  3
 xps := TokOfst (xs);  // Смещение токена
 Val (ss, valx, e);    // Значение !
 dstp := dword (xps) + offsets [pt.y - 1];
 VirtualQueryEx (_alias, ptr (dstp), mbi, SizeOf (mbi));
 flock := true;
 if (mbi.State and MEM_COMMIT = MEM_COMMIT) and
      not IsWritable (mbi.Protect) then
  flock := VirtualProtectEx (_alias, mbi.BaseAddress,
                    mbi.RegionSize, mbi.Protect or PAGE_READWRITE, @l);
 if flock then
 begin
  if WriteProcessMemory (_alias,
                        ptr (dstp), @valx, vsize, l) and
                         (l > 0) then else
                         AddMsg (Format ('Failing to write %x, %d bytes',
                         [dstp, vsize]));
 end;
end; // WriteHex;

procedure Tmedit.WriteTxt (const s: string; pt: TPoint);
// Записть шестнадцатибайтной строки
var
   dstp: dword;
   mbi: TMemoryBasicInformation;
     l: DWORD;
    ch: char;
begin
 dstp := offsets [pt.y - 1] + dword (pt.x - 1);
 VirtualQueryEx (_alias, ptr (dstp), mbi, SizeOf (mbi));

 if (mbi.State and MEM_COMMIT = MEM_COMMIT) then
  VirtualProtectEx (_alias, mbi.BaseAddress,
                    mbi.RegionSize, mbi.Protect or PAGE_READWRITE, @l);

 if (pt.x > 0) and (pt.x <= Length (s)) then
      ch := s [pt.x]
  else
      ch := '?';
 if WriteProcessMemory (_alias,
                        ptr (dstp), @ch, 1, l) and
                         (l > 0) then;
end; // WriteTxt

procedure Tmedit.kfbtnEnter(Sender: TObject);
begin
 SwitchMode;
end;

procedure Tmedit.SwitchMode;
begin
 // Text-Hex Mode Switcher
 if (dmode = dmHexByte) then
  begin
   if (CaretHex) then
     CaretPos.X := (CaretPos.X + 2) div Integer (1 + vsize shl 1)
   else
     CaretPos.X := CaretPos.X * Integer (1 + vsize shl 1) - 2;
   CaretHex := not CaretHex;
  end; 
 flush.SetFocus;
 blink := true;
 DrawDump;
end;


procedure Tmedit.FormShow(Sender: TObject);
begin
 insMode := FALSE;
end;

procedure Tmedit.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var cofs: DWORD;
begin
 if (ssLeft in Shift) then
  begin
   GetCPByClientPos (x, y, CaretPos);
   cofs := GetCaretOfs;
   // prevent previous select die
   if (selStart = cofs) or (selLimit = cofs) then
    else
     begin
      selStart := cofs;
      selLimit := cofs;
     end;
   DumpMem;
  end;
end;


procedure Tmedit.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var pofs, cofs: DWORD;
begin
 if (ssLeft in Shift) then // only if pressed
  begin
   pofs := GetCaretOfs;
   GetCPByClientPos (x, y, CaretPos);
   cofs := GetCaretOfs;
   AdjustSel (pofs, cofs); // set start/limit of selection
   if pofs <> cofs then DumpMem;
  end;
end;

end.
