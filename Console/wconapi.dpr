{$D+}
library wconapi;
uses
  conapi,
  Windows,
  Messages,
  ChConst in '..\ChConst.pas',
  ChTypes in '..\ChTypes.pas',
  gditools in '..\Common\gditools.pas',
  KbdDefs in '..\Common\KbdDefs.pas';

type
  // Implements console version, that drawing on some DC
  TGdiConsole = class (TAbsConsole)
  protected
   hConWnd: THandle;
   function       GetCursorPos: _COORD; override;
  private
   scbi: _CONSOLE_SCREEN_BUFFER_INFO;  // for regular internal using
   brushList: array [0..15] of HBrush; // using to fast paints background
   hFont: THandle;
   xtab: array of SmallInt;
   ytab: array of SmallInt;
     Conorg: TPoint;
    ConSize: SIZE;     // GDI size of console.
   CharSize: SIZE;     // max size of symbol
      gbuff: TGdiBuff; // internal console buffer
   curspos, prvcpos: _COORD;  // position of cursor
   mousePos, prvmpos: _COORD; // position of mouse cursor

   CharData: array of CHAR_INFO; // dynamic array
     nChars: DWORD;
   UpdatedRect: TRectClass;
   procedure      CreateBrushs;
   procedure      DeleteBrushs;
   procedure      DrawLine(y: Integer; const line: array of CHAR_INFO);
   procedure      RecalcGrid;
   procedure      CalcCursorRect(cpos: _COORD; var r: TRect; hc: byte);
  public
   constructor    Create;
   destructor     Destroy; override;

   function       ActiveConsoleWindow: Boolean; override;
   procedure      DrawCursor (DC: HDC; const cr: TRect; color, h: ShortInt); override;
   function       CreateBuff (BaseDC: HDC): TGdiBuff; override;
   function       GetConsoleWindow: THandle; override;
   function       GetUpdatedRect: TRectClass; override;
   procedure      PrintTo (DC: THandle; const r: TRect; const org: TPoint); override;
   // reading data from hOutput, and draw it to GBuff
   function       RedrawConsole (y1, y2: Integer): Boolean; override;
   procedure      Repaint (hWnd: THandle); override;
   procedure      SetFont (const FontFace: string; size: Integer); override;
   procedure      SetSize (Width, Height: Integer); override;
   procedure      SendKbdInput (key, flags: WORD; press: Boolean); override;
   // Event handlers
   procedure      OnMouseEvent (x, y: Integer; btns, keys, flags: dword); override;
  end; // TGdiConsole

const htab: PAnsiCHAR =
            ('!1@2#3$4%5^6&7*8(9)0' +
              ':;"'#$27'|\<,>.?/_-+=~`');


function  MakeConsole: TAbsConsole; stdcall;
begin
 result := TGdiConsole.Create;
end;

function SetConsoleEventHook (ConEventProc: TFNWndProc): THandle; stdcall;
begin
 result := SetWinEventHook (EVENT_CONSOLE_CARET,
       EVENT_CONSOLE_END_APPLICATION, 0, ConEventProc, 0, 0, WINEVENT_OUTOFCONTEXT);
end;

exports
  MakeConsole name 'MakeConsole',
  SetConsoleEventHook name 'SetConsoleEventHook';
{ TGdiConsole }

function TGdiConsole.ActiveConsoleWindow: Boolean;
begin
 result := false;
 if (hConWnd = 0) then exit;
 result := (hConWnd = GetActiveWindow) or
           (hConWnd = GetForegroundWindow) or
           (hConWnd = GetFocus);
end; // ActiveConsoleWindow

procedure  TGdiConsole.CalcCursorRect;
begin
  r.left := xtab [cpos.x];
  r.Top := ytab [cpos.y] + CharSize.cy - hc;
  r.Right := r.Left + CharSize.cx;          
  r.Bottom := r.Top + hc;
end; // CalcCursorRect

constructor TGdiConsole.Create;

begin
 inherited Create;
 if hOutput <> 0 then
  begin
   hConWnd := GetConsoleWindow;
  end;
 // precreating sizes for gdi buffer
 conSize.cx := GetSystemMetrics (SM_CXSCREEN);
 conSize.cy :=  GetSystemMetrics (SM_CYSCREEN);
 CharSize.cx := 0;
 CharSize.cy := 0;
 ConOrg.X := 0;
 ConOrg.Y := 0;
 FillChar (scbi, sizeof (scbi), 0);
 GetConsoleScreenBufferInfo (hOutput, scbi);
 SetSize (scbi.dwSize.X, scbi.dwSize.Y);
 // init default size for buffer
 FillChar (GBuff, sizeof (GBuff), 0);
 CreateBrushs;
end;

procedure TGdiConsole.CreateBrushs;
var n: dword;
begin
 for n := 0 to 15 do
     BrushList [n] := CreateSolidBrush (coltab [n]);
end;

function TGdiConsole.CreateBuff (BaseDC: HDC): TGdiBuff; 
begin
 GBuff.Init (BaseDC, ConSize.cx, ConSize.cy);
 bFullRedraw := true;
 GBuff.SetBgColor($7F7F00);
 with gBuff do Rectangle (rect);
 // TextOut (gBuff.MemDC, 0, 0, 'Test', 4);
 result := GBuff;
end;


procedure TGdiConsole.DeleteBrushs;
var n: dword;
begin
 for n := 0 to 15 do
  begin
   DeleteObject (BrushList [n]);
   BrushList [n] := 0;
  end;
end; // DeleteBrushs


destructor TGdiConsole.Destroy;
begin
 DeleteBrushs;
 if gBuff.MemDC <> 0 then
   GBuff.Release;
 SetSize (0, 0); // for all releasing
 if hFont <> 0 then DeleteObject (hFont);
 inherited;
end;

function EquivChar (const a, b: CHAR_INFO): Boolean;
begin
 result := DWORD(a) = DWORD(b);
end; // EquivChar

function CharBgColor (const ci: CHAR_INFO): COLORREF;
begin
 result := (ci.Attributes shr 4) and $0F;
 if (ci.Attributes and COMMON_LVB_REVERSE_VIDEO <> 0) then
     result := result xor $0F;
end; // CharBgColor

function CharColor (const ci: CHAR_INFO): COLORREF;
begin
 result := ci.Attributes and $0F;
 if (ci.Attributes and COMMON_LVB_REVERSE_VIDEO <> 0) then
     result := result xor $0F;
end; // CharColor

procedure TGdiConsole.DrawCursor; // this drawed mouse and caret cursor 
var hBr, hOldBr: dword;
begin
 hBr := BrushList [color and $F];
 hOldBr := SelectObject (GBuff.MemDC, hBr);
 UpdatedRect.Extent(cr);
 with cr do
      BitBlt (DC, left, top, right - left, bottom - top, GBuff.MemDC,
                    left, top, PATINVERT);
 SelectObject (GBuff.MemDC, hOldBr);
end; // DrawCursor

procedure TGdiConsole.DrawLine;
var ofst: Integer;
    x, xx, yy: Integer;
    hBrush: THandle;
    fgcol, prvcol: COLORREF;
    r: TRect;
    bits: Integer;
begin
 ofst := ConRect.Width * y; // in CharData
 yy := ytab [y];
 bits := GetDeviceCaps (gBuff.MemDC, BITSPIXEL);
 prvcol := $FFFFFFFE;
 if bits < 8 then
    prvcol := $FF;
 for x := 0 to ConRect.Right do
  if (bFullRedraw or 
      not EquivChar (line [x], CharData [x + ofst]) ) then
   begin
    xx := xtab [x];
    hBrush := CharBgColor (line [x]); // select char bgcolor
    // hBrush := 9;
    SetBkColor (GBuff.MemDC, coltab [hBrush]);
    if (hBrush <= 15) then hBrush := BrushList [hBrush] // determine brush
                      else DebugBreak;
    fgcol := coltab [ CharColor (line [x]) ];  // char color
    // calculate rect of char
    SetRect(r, xx, yy, xx + CharSize.cx, yy + CharSize.cy);
    // LineTo (GBuff.MemDC, xx, yy);
    UpdatedRect.Extent (r);
    FillRect (GBuff.MemDC, r, hBrush); // paint background
    if fgcol <> prvcol then
     begin
      GBuff.SetTextColor(fgcol);
      // GBuff.SetPenColor(fgcol);
      // SetTextColor (GBuff.MemDC, $FFFF00); // changing current color
      prvcol := fgcol;
     end;
    DrawTextW (GBuff.MemDC, @line [x].UnicodeChar, 1, r, 0); // Output char
    // TextOutW (GBuff.MemDC, xx, yy, @line [x].UnicodeChar, 1);
   end;
end; // DrawLine


function TGdiConsole.GetConsoleWindow: THandle;
var
   tmp: WSTRZ256;
   s: String;
begin
 result := 0;
 if 0 = GetConsoleTitle (tmp, 255) then exit;
 str (GetCurrentProcessId, s);
 s := 'UniqueConsole' + s;
 if SetConsoleTitle (PChar (s)) then
  begin
   Sleep (150);
   hConWnd := FindWindow (nil, PChar (s));
   SetConsoleTitle (tmp); // restore title
   if IsWindow (hConWnd) then Writeln ('Console hWnd = ', (hConWnd));
  end;
 result := hConWnd;  
end; // GetConsoleWindow;

function TGdiConsole.GetCursorPos: _COORD;
begin
 FillChar (scbi, sizeof (scbi), 0);
 GetConsoleScreenBufferInfo (hOutput, scbi);
 result := scbi.dwCursorPosition;
end; // GetCursorPos

function TGdiConsole.GetUpdatedRect: TRectClass;
var cr: TRect;
begin
 if DWORD (curspos) <> DWORD (prvcpos) then
 begin
  // обеспечение условий перерисовки курсора в новом месте
  bBlink := true;
  bPrvBlink := false;
  CalcCursorRect (prvcpos, cr, CharSize.cy);
  updatedRect.Extent (cr); // добавить в область перерисовки
 end;

 if (bPrvBlink <> bBlink) then
 begin
  CalcCursorRect (CursPos, cr, CharSize.cy);
  updatedRect.Extent (cr);
 end;
 result := UpdatedRect;
end;

procedure TGdiConsole.OnMouseEvent;
var rec: TInputRecord;
    num: dword;
begin
 // limititation coords
 dec (x, conorg.x);
 dec (y, conorg.y);
 if x < 0 then X := 0;
 if y < 0 then y := 0;
 if x >= ConSize.cx then x := ConSize.cx - 1;
 if y >= ConSize.cy then y := ConSize.cy - 1;
 prvmpos := MousePos;
 MousePos.X := x div CharSize.cx;
 MousePos.Y := y div CharSize.cy;
 RedrawConsole (prvmpos.y, mousePos.y);
 if hInput <> 0 then
 with rec.Event.MouseEvent do
  begin
   rec.EventType := _MOUSE_EVENT;
   dwMousePosition := MousePos;
   dwButtonState := btns;
   dwControlKeyState := keys;
   dwEventFlags := flags;
   WriteConsoleInputW (hInput, rec, 1, num);
  end;
end;

procedure TGdiConsole.PrintTo;
var rr: TRectClass;
    xr, cr: TRect;
    ci: _CONSOLE_CURSOR_INFO;
    curh: Integer;
    bd: Boolean;
begin
 rr.rect := r;
 GBuff.CopyTo (DC, rr.Left + org.x, rr.Top + org.y,
                   rr.Width, rr.Height,
                   rr.Left, rr.Top);

 with CursPos, charSize do
  begin
   // отображение курсора в исходной позиции
   GetConsoleCursorInfo (hOutput, ci);
   curh := integer (ci.dwSize) * cy div 100;
   // Получение позиции кусрора
   CalcCursorRect (CursPos, cr, curh);
   // проверка наложения прямоугольников
   if IntersectRect (xr, cr, updatedRect.rect) then
        bPrvBlink := not bBlink;
   if bBlink and (not bPrvBlink) then
      DrawCursor (DC, cr, charData [x + y * cx].Attributes, curh);
   bPrvBlink := bBlink;
   prvcpos := CursPos;
  end;
 with MousePos, charSize do
  begin
   CalcCursorRect (MousePos, cr, cy);
   bd := IntersectRect (xr, cr, updatedRect.rect);
   bd := bd or (X <> prvmpos.X) or (Y <> prvmpos.Y); 
   if bd then DrawCursor (DC, cr, charData [x + y * cx].Attributes, cy);
  end;
end; // PrintTo

procedure FillVector (var v: array of SmallInt; start, count, step: Integer);
var n, nn: Integer;
begin
 nn := start;
 for n := 0 to count - 1 do
  begin
   v [n] := nn;
   Inc (nn, step);
  end;
end; // FillVector

procedure TGdiConsole.RecalcGrid;
var 
    tm: TextMetricW;

begin
 if GBuff.MemDC = 0 then exit;
 GetTextMetricsW (GBuff.MemDC, tm);
 CharSize.cx := tm.tmMaxCharWidth;
 CharSize.cy := tm.tmHeight;
 with ConRect do
 begin
  if (Width > 0) then
    FillVector (xtab, conorg.x, Width, CharSize.cx);
  if (Height > 0) then
    FillVector (ytab, conorg.y, Height, CharSize.cy);
 end;
 ConSize.cx := CharSize.cx * ConRect.Width;
 ConSize.cy := CharSize.cy * ConRect.Height;
end; // RecalcGrid;

function TGdiConsole.RedrawConsole;
var
    charLine: array [0..250] of CHAR_INFO; // used for testing
    ls, ofst: Integer;
     y: Integer;
    cc, cs: _COORD;
    rr: SMALL_RECT;
begin
 result := false;
 updatedRect.SetRect (0, 0, 0, 0);
 if GBuff.MemDC = 0 then exit; // no possible to draw
 if not Assigned (CharData) then exit;
 GdiSetBatchLimit (8192);
 SetBkMode (GBuff.MemDC, TRANSPARENT);
 if bFullRedraw then
 with gBuff do
   FillRect (MemDC, Rect, GetStockObject (GRAY_BRUSH));

 // получние информации о буфере консоли
 if not GetConsoleScreenBufferInfo (hOutput, scbi) then   exit;
 with scbi.dwSize do
 if (x <> ConRect.Width) or (y <> ConRect.Height) then
  SetSize (x, y);
 CursPos := scbi.dwCursorPosition;
 with GBuff do
 begin
  rr := ConRect.srect;
  cs.X := ConRect.Width;
  ls := cs.x * sizeof (CHAR_INFO);
  cs.Y := 1;
  cc.X := 0; cc.Y := 0; // Single Line loads
  for y := y1 to y2 do
   begin
    rr.Top := y;
    rr.Bottom := y + 1;
    ofst := y * cs.x;
    if (ReadConsoleOutputW (hOutput, @charLine, cs, cc, rr)) then else break;
    // returns 0 if equal
    if  bFullRedraw or (memcmpd (@charLine, @CharData [ofst], ls div 4) <> 0) then
     begin
      result := true;
      DrawLine (y, CharLine);
      Move (CharLine, CharData [ofst], ls);
     end;
   end; // for Loop
 end; // with
 bFullRedraw := false;
 GdiFlush;
 GdiSetBatchLimit (1); 
end; // RedrawConsole

procedure TGdiConsole.Repaint(hWnd: THandle);
var dc: HDC;
    org: TPoint;
    r: TRect;
    bPaint: Boolean;
begin
 bPaint := RedrawConsole (0, ConRect.Bottom);
 org.x := 0;
 org.y := 0;
 dc := GetDC (hWnd);
 GetClipBox (dc, r);
 UpdatedRect.Extent(r);
 bPaint := bPaint or (UpdatedRect.Width <> 0) and (UpdatedRect.Height <> 0);
 if bPaint then PrintTo (dc, UpdatedRect.rect, org);
 ReleaseDC (hWnd, DC);
 ValidateRect (hWnd, nil);
end;

function FlagsToState (flags: WORD): WORD;
type TCvtHash = array [1..3, 0..1] of WORD;
const
   fcvthashl: TCvtHash =
     ((KF_SHIFT, SHIFT_PRESSED),
      (KF_ALT, LEFT_ALT_PRESSED),
      (KF_CTRL, LEFT_CTRL_PRESSED));
  fcvthashr: TCvtHash =
     ((KF_SHIFT, SHIFT_PRESSED),
      (KF_ALT, RIGHT_ALT_PRESSED),
      (KF_CTRL, RIGHT_CTRL_PRESSED));

var
   ptab: ^TCvtHash;
   n: DWORD;
begin
 result := 0;
 ptab := @fcvthashl;
 if (flags and KF_RKEY <> 0) then ptab := @fcvthashr;
 // conversion flags
 for n := 1 to 3 do
  if (flags and ptab^ [n, 0] <> 0) then
    result := result or ptab^ [n, 1];
end;

function InitKbdInputRec (vkcode, flags: WORD; press: Boolean): TInputRecord;
var state: WORD;
    ch: AnsiCHAR;
    n: Integer;
begin
 FillChar (result, sizeof (result), 0);
 state := FlagsToState (flags); // crp conversion
 press := press or (flags and KF_PRESS <> 0); // key pressed
 press := press and (flags and KF_KEYUP = 0); // key released
 with result, result.Event do
 begin
  EventType := KEY_EVENT;
  KeyEvent.dwControlKeyState := state;
  // инициация символьного кода
  if (state and LEFT_ALT_PRESSED = 0) and
     (vkcode <> VK_MENU) and (vkcode <> VK_CONTROL) then
   begin
    KeyEvent.AsciiChar := AnsiChar (MapVirtualKey (vkcode, 2));
    KeyEvent.UnicodeChar := WideChar (MapVirtualKeyW (vkcode, 2));
   end;
  ch := KeyEvent.AsciiChar;
  // Авто-инициация символьных данных 
  if (state and SHIFT_PRESSED = 0) and (ch <> #0) then
  with KeyEvent do
   begin
    if (KeyEvent.AsciiChar in ['A'..'Z']) then
     begin
      AsciiChar := AnsiChar ( Byte(AsciiChar) or $20);
      UnicodeChar := WideChar ( word(UnicodeChar) or $20);
     end
   end
  else
   begin
    n := 0;
    ch := KeyEvent.AsciiChar;
    if ch <> #0 then
    while (htab [n] <> #0) do
     begin
      if ch = htab [n + 1] then
         ch := htab [n + 0];
      inc (n, 2);
     end;
    KeyEvent.AsciiChar := ch;
    KeyEvent.UnicodeChar := WideChar (ch);
   end;
  KeyEvent.wRepeatCount := 0;
  KeyEvent.wVirtualKeyCode := vkcode;
  KeyEvent.wVirtualScanCode := MapVirtualKeyW (vkcode, 0);
  KeyEvent.bKeyDown := press;
 end;
end; // InitKbdInputRec

procedure TGdiConsole.SendKbdInput(key, flags: WORD; press: Boolean);
// Отправка события нажатия/отпускания клавиши
var r: TInputRecord;
    num: DWORD;
begin
 r := InitKbdInputRec (key, flags, press);
 WriteConsoleInputW (hInput, r, 1, num);
 // if (key = VK_RETURN) then Sleep (20); // take to program hanlde keypress
end; // TGdiConsole.SendKbdInput


procedure TGdiConsole.SetFont(const FontFace: string; size: Integer);
var newFont: THandle;
begin
 newFont := CreateFont (size, 0, 0, 0, 300, 0, 0, 0,
            OEM_CHARSET, 0, 0, 0, FIXED_PITCH, PChar (FontFace));
 if (newFont <> 0) then
 begin
  if (hFont <> 0) then DeleteObject (hFont);
  hFont := newFont;
  if GBuff.MemDC <> 0 then SelectObject (GBuff.MemDC, hFont);
  RecalcGrid;
 end;
end; // SetFont

procedure TGdiConsole.SetSize(Width, Height: Integer);
var n: dword;
begin
 inherited; // setting internal var ConRect
 // ReCreating chardata buffer
 nChars := conRect.Width * conRect.Height;
 SetLength (CharData, nChars);
 if (nChars > 0) then
 for n := 0 to nChars - 1 do
   CharData [0].UnicodeChar := #0;
 // FillChar (CharData, sizeof (CHAR_INFO) * nChars, 0); // set buffer to zeros
 SetLength (xtab, Width);
 SetLength (ytab, Height);
 if (Width > 0) and (Height > 0) then
     RecalcGrid; // calculating grid of graphic positions for chars
end;



end.
