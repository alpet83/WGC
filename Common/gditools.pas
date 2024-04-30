unit gditools;
{ GDITools = сборная солянка из классов для низкоуровневой работы с GDI }
interface
uses Windows;


type
 TRectClass = object  // rectangle class
 private
  function   GetHeight: Integer;
  function   GetRect: TRect;
  function   GetSmall: SMALL_RECT;
  function   GetWidth: Integer;
  procedure  SetHeight (h: Integer);
  procedure  SetSmall (const r: SMALL_RECT);
  procedure  SetWidth (w: Integer);
 public
  Left, Top, Right, Bottom: Integer;
  procedure  CopyRect (const r: TRect);
  procedure  Extent (const rr: TRect);
  property   Height: Integer read GetHeight write SetHeight;
  procedure  SetRect (const x1, y1, x2, y2: Integer);
  property   Rect: TRect read GetRect write CopyRect;
  property   SRect: SMALL_RECT read GetSmall write SetSmall;
  property   Width: Integer read GetWidth write SetWidth;
 end;

  TGdiBuff = object (TRectClass)
  private
{  hOldPen: HPEN;
   hOldBrush: HBRUSH; {}
  public
    MemDC: HDC;
   MemBMP: HBITMAP;
     hPen: HPEN;
   hBrush: HBRUSH;
   // functions, procedures
   function     CopyFull (DstDC: HDC): Boolean;

   function     CopyTo (DstDC: HDC; x, y, w, h, srcx, srcy: Integer): Boolean;

   // создает новый растр, и возвращает описатель предыдущего.
   function     CreateNewBitmap (DC: HDC): HBITMAP;
   procedure    Init (DC: HDC; BuffW, BuffH: Integer);
   procedure    Release;
   procedure    SetBgColor (col: COLORREF);
   procedure    SetPenColor (col: COLORREF);
   procedure    SetTextColor (col: COLORREF);
   procedure    Rectangle (const r: TRect);
   procedure    TextOut (x, y: Integer; const S: String);
  end;

function IsValidDC (DC: HDC): Boolean;
implementation

function IsValidDC (DC: HDC): Boolean;
begin
 result := false;
 if dc = 0 then exit;
 result := GetDeviceCaps (dc, BITSPIXEL) > 0;
end;
{ TRectClass }

function TRectClass.GetHeight: Integer;
begin
 result := Bottom - Top + 1;
end; // GetHeight

procedure TRectClass.Extent (const rr: TRect);
begin
 if left > rr.left then left := rr.left;
 if top > rr.top then top := rr.top;
 if right < rr.right then right := rr.right;
 if bottom < rr.bottom then bottom := rr.bottom;
end; // ExtentRect

function TRectClass.GetRect: TRect;
begin
 result := PRect (@Left)^; // direct copying
end; // GetRect

function TRectClass.GetWidth: Integer;
begin
 result := Right - Left + 1;
end; // GetWidth

procedure TRectClass.SetHeight(h: Integer);
begin
 Bottom := Top + h - 1;
end;

procedure TRectClass.CopyRect(const r: TRect);
begin
 PRect(@Left)^ := r;
end;

procedure TRectClass.SetRect(const x1, y1, x2, y2: Integer);
begin
 Left := x1; Top := y1;
 Right := x2; Bottom := y2;
end;

procedure TRectClass.SetWidth(w: Integer);
begin
 Right := Left + w - 1;
end;

function TRectClass.GetSmall: SMALL_RECT;
begin
 result.Left := Left;
 result.Top := Top;
 result.Right := Right;
 result.Bottom := Bottom;
end; // GetSmall

procedure TRectClass.SetSmall(const r: SMALL_RECT);
begin
 SetRect (r.Left, r.Top, r.Right, r.Bottom);
end;

{ TGdiBuff }

function TGdiBuff.CopyFull(DstDC: HDC): Boolean;
begin
 result := CopyTo (DstDC, left, top, width, height, left, top);
end;

function  TGdiBuff.CopyTo;
begin
 result := BitBlt (DstDC, x, y, w, h, MemDC, srcx, srcy, SRCCOPY);
end;

function TGdiBuff.CreateNewBitmap(DC: HDC): HBITMAP;
begin
 result := MemBMP;
 MemBMP := CreateCompatibleBitmap (DC, Width, Height);
 SelectObject (MemDC, MemBMP);
end;

procedure TGdiBuff.Init(DC: HDC; BuffW, BuffH: Integer);
var s: string;
begin
 Left := 0;
 Top := 0;
 Width := BuffW;
 Height := BuffH;
 hBrush := 0;
 hPen := 0;
 MemDC := CreateCompatibleDC (DC);
 CreateNewBitmap (DC);
 str (GetDeviceCaps (MemDC, BITSPIXEL), s);
 s := '#Created MemDC, bits per pixel = ' + s;
 // OutputDebugString (PChar (s));
end;

procedure TGdiBuff.Rectangle(const r: TRect);
begin
 with r do
  Windows.Rectangle(MemDC, left, top, right, bottom) 
end;

procedure TGdiBuff.Release;
begin
 if MemDC <> 0 then DeleteObject (MemDC);
 if MemBMP <> 0 then DeleteObject (MemBMP);
 if hPen <> 0 then DeleteObject (hPen);
 if hBrush <> 0 then DeleteObject (hBrush);
 MemDC := 0;
 MemBMP := 0;
end;

procedure TGdiBuff.SetBgColor(col: COLORREF);
begin
 if hBrush <> 0 then DeleteObject (hBrush);
 hBrush := CreateSolidBrush (col);
 SelectObject (MemDC, hBrush);
end;

procedure TGdiBuff.SetPenColor(col: COLORREF);
begin
 if hPen <> 0 then DeleteObject (hPen);
 hPen := CreatePen (PS_SOLID, 0, col);
 SelectObject (MemDC, hPen);
end;

procedure TGdiBuff.SetTextColor(col: COLORREF);
begin
 Windows.SetTextColor (MemDC, col);
end;

procedure TGdiBuff.TextOut(x, y: Integer; const S: String);
begin
 Windows.TextOut (MemDC, x, y, PChar (s), Length (s));
end;

end.

