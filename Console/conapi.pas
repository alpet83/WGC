unit conapi;
interface
uses Windows, Messages, GDITools;
{
  В модуле определяется абстрактное определение класса консоли, что используется
 в библиотеке реализующей ее функциональность.
 }

const // Цвета для текстовых аттрибутов в графическом режиме.
   coltab: array [0..15] of COLORREF =
    ( $000000, $800000, $008000, $808000,
      $000080, $800080, $008080, $C0C0C0,
      $808080, $FF0000, $00FF00, $FFFF00,
      $0000FF, $FF00FF, $00FFFF, $FFFFFF);

    // Console attributes
    COMMON_LVB_REVERSE_VIDEO        = $4000;  // reversed
    COMMON_LVB_UNDERSCORE           = $8000;  // underlined

    // Console Events
    EVENT_CONSOLE_CARET             = $4001;
    EVENT_CONSOLE_UPDATE_REGION     = $4002;
    EVENT_CONSOLE_UPDATE_SIMPLE     = $4003;
    EVENT_CONSOLE_UPDATE_SCROLL     = $4004;
    EVENT_CONSOLE_LAYOUT            = $4005;
    EVENT_CONSOLE_START_APPLICATION = $4006;
    EVENT_CONSOLE_END_APPLICATION   = $4007;

type

 TAbsConsole = class   // Abstract console class
 protected
  function   GetCursorPos: _COORD; virtual;
 public
  hInput, hOutput: THandle; // Console Handle
  bBlink, bPrvBlink: Boolean; // for console cursor
  bFullRedraw: Boolean;
  conrect: TRectClass;
  property      cursorPos: _COORD read GetCursorPos;
  function      ActiveConsoleWindow: Boolean; virtual;
  constructor   Create;
  function      CreateBuff (BaseDC: HDC): TGdiBuff; virtual; abstract;
  procedure     DrawCursor (DC: HDC; const cr: TRect; color, h: ShortInt); virtual; abstract;
  function      GetConsoleWindow: THandle; virtual;
  function      GetUpdatedRect: TRectClass; virtual;
  procedure     PrintTo (DC: THandle; const r: TRect; const org: TPoint); virtual; abstract;
  function      RedrawConsole (y1, y2: Integer): boolean; virtual; abstract;
  procedure     Repaint (hWnd: THandle); virtual;
  procedure     SendKbdInput (key, flags: WORD; press: Boolean); virtual; abstract;
  procedure     SetHandles (hConInput, hConOutput: THandle);
  procedure     SetFont (const FontFace: string; size: Integer); virtual;
  procedure     SetSize (Width, Height: Integer); virtual;
  procedure     OnMouseEvent (x, y: Integer; btns, keys, flags: dword); virtual;
 end;

function memcmpd (p1, p2: pointer; count: dword): Integer;

implementation

type
   DWORD_ARRAY = array [0..0] of DWORD;
   PDWORD_ARRAY = ^DWORD_ARRAY;

function memcmpd (p1, p2: pointer; count: dword): Integer;
var a: PDWORD_ARRAY absolute p1;
    b: PDWORD_ARRAY absolute p2;
    n: dword;
begin
 result := 1; // default is not equal
 for n := 0 to count - 1 do
  if a^[n] <> b^[n] then exit;
 result := 0 // is equal
end;

{ TAbsConsole }

function TAbsConsole.ActiveConsoleWindow: Boolean;
begin
 result := false;
end;

constructor TAbsConsole.Create;
begin
 hInput := GetStdHandle (STD_INPUT_HANDLE);
 hOutput := GetStdHandle (STD_OUTPUT_HANDLE);
 bFullRedraw := False;
 conRect.SetRect(0, 0, 0, 0); // default size
end;

function TAbsConsole.GetConsoleWindow: THandle;
begin
 result := 0;
end;

function TAbsConsole.GetCursorPos: _COORD;
begin
 result.x := 0;
 result.y := 0;
end;

function TAbsConsole.GetUpdatedRect: TRectClass;
begin
 result.SetRect(0, 0, 0, 0); // no updates
end;

procedure TAbsConsole.OnMouseEvent;
begin
 // no handling here
end;

procedure TAbsConsole.Repaint;
begin
 // nothing to works
end;

procedure TAbsConsole.SetFont(const FontFace: string; size: Integer);
begin
 // No some works here
end;

procedure TAbsConsole.SetHandles(hConInput, hConOutput: THandle);
begin
 hInput := hConInput;
 hOutput := hConOutput;
end;

procedure TAbsConsole.SetSize(Width, Height: Integer);
begin
 conrect.Width := Width;
 conrect.Height := Height;
end;

end.
