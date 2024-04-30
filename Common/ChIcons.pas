unit ChIcons;

interface
uses Windows, Messages, ChTypes, Classes, Graphics;
{
  Модуль по работе с растровыми значками (иконками)
}
type
    PIcon = ^HICON;
    TIconInfo = record
     hIcon: HICON;
     hWnd: HWND;
     saveIt: Boolean;
     dataSize: Integer;
     streamData: array [0..2047] of Byte;
    end;
    PIconInfo = ^TIconInfo;

  TIconStorage = class (TList)
  protected
   // icvt: TIcon;
   pic: TPicture;
   stm: TStream;
   function           GetIcon (Index: Integer): PIconInfo;
  public
   property           Icons [Index: Integer]: PIconInfo read GetIcon;
   constructor        Create;
   destructor         Destroy; override;
   function           AddIcon (hIcon: HICON): Integer;
   function           AddWindowIcon (hWnd: HWND): Integer;
   procedure          Clear; override;
   function           FindByWindow (hWnd: HWND): Integer;    
   function           FindIcon (hIcon: HICON): Integer;
   procedure          RemoveIcon (hIcon: HICON);
   procedure          BeginUpdate; virtual;
   procedure          DeleteUnmarked (bReleaseIcons: Boolean);
  end;

function    FindWinIcon (const h: THandle): HICON;
function    DrawIcon2MDC (hico: HICON): Boolean;
function    ScanIconBitmap (var ibmp: TIconBitmap): Byte;
function    IconCreateBitmap (ibmp: TIconBitmap; bitsCnt: Byte): DWORD;

implementation

uses Misk, SysUtils, ChPSTools;

var
   palette: array [0..255] of RGBQUAD;
//   tmpbits: TIconBitmap;

function DuplicateIcon (hInst: DWORD; hi: HICON): HICON; stdcall;external 'shell32.dll'


function ExtractIconEx (lpszFile: PChar;
                            nIconIndex:Integer;
                            phiconLarge: PICON;
                            phiconSmall: PICON;
                            nIcons: DWORD): DWORD; stdcall; external 'shell32.dll';


function GetIconMsg (const hwnd: THandle; const ico: WPARAM): HICON;
var i: dword;
begin
 result := 0;
 if (SendMessageTimeOut (hwnd, WM_GETICON, ico, 0,
                          SMTO_ABORTIFHUNG, 200, i) > 0) then result := i;
end;


function GetWinIcon (const hwnd: THandle): HICON;

var
   pp: WSTRZ256;
   h: THandle;
   pid: THandle;
   n: dword;
   hsm: HICON;
begin
 result := 0;
 h := GetWindow (hwnd, GW_OWNER);
 if h = 0 then h := hwnd;
 SetLastError (0);
 FillChar (pp, sizeof (pp), 0);
 GetWindowThreadProcessId (h, pid);
 // GetWindowModuleFileName (h, pp, 200);
 n := warray.psArray.FindById (pid);
 if (n > 0) then
    StrPCopy (pp, warray.psArray.names [n]);    
 if pp = '' then GetWindowModuleFileName (GetWindow (h, GW_CHILD), pp, 200);
 if pp <> '' then
  begin
   ExtractIconEx (pp, 0, nil, @hsm, 1);
   result := hsm;
  end;
end; // GetWinIcon



function  FindWinIcon (const h: THandle): HICON;
var hi: HICON;
begin
 result := 0;
 if (h = 0) then exit;
 hi := 0;
 // retreiving icon
 if hi = 0 then hi := GetIconMsg (h, ICON_SMALL);
 if hi = 0 then hi := GetIconMsg (h, 2);
 if hi = 0 then hi := GetClassLong (h, GCL_HICONSM);
 if hi = 0 then
  hi := GetWinIcon (h) else hi := CopyIcon (hi);
 result := hi;
end;  // FindWinIcon


function BytesPerScanline(PixelsPerScanline, BitsPerPixel, Alignment: Longint): Longint;
begin
  Dec(Alignment);
  Result := ((PixelsPerScanline * BitsPerPixel) + Alignment) and not Alignment;
  Result := Result div 8;
end;

procedure InitializeBitmapInfoHeader(Bitmap: HBITMAP; var BI: TBitmapInfoHeader;
  Colors: Integer);
var
  DS: TDIBSection;
  Bytes: Integer;
begin
  DS.dsbmih.biSize := 0;
  Bytes := GetObject(Bitmap, SizeOf(DS), @DS);
  if Bytes = 0 then exit
  else if (Bytes >= (sizeof(DS.dsbm) + sizeof(DS.dsbmih))) and
    (DS.dsbmih.biSize >= DWORD(sizeof(DS.dsbmih))) then
    BI := DS.dsbmih
  else
  begin
    FillChar(BI, sizeof(BI), 0);
    with BI, DS.dsbm do
    begin
      biSize := SizeOf(BI);
      biWidth := bmWidth;
      biHeight := bmHeight;
    end;
  end;
  case Colors of
    2: BI.biBitCount := 1;
    3..16:
      begin
        BI.biBitCount := 4;
        BI.biClrUsed := Colors;
      end;
    17..256:
      begin
        BI.biBitCount := 8;
        BI.biClrUsed := Colors;
      end;
  else
    BI.biBitCount := DS.dsbm.bmBitsPixel * DS.dsbm.bmPlanes;
  end;
  BI.biPlanes := 1;
  if BI.biClrImportant > BI.biClrUsed then
    BI.biClrImportant := BI.biClrUsed;
  if BI.biSizeImage = 0 then
    BI.biSizeImage := BytesPerScanLine (BI.biWidth, BI.biBitCount, 32) * Abs(BI.biHeight);
end;

var
   hMemDC: THandle = 0;
   hBitmap: THandle = 0;

procedure       OpenMDC;
var DC: HDC;
begin
 DC := CreateDC ('DISPLAY', nil, nil, nil);
 if DC = 0 then exit;
 hMemDC := CreateCompatibleDC (DC);
 hBitmap := CreateCompatibleBitmap (DC, 16, 16);
 // hBitmap := CreateBitmap (16, 16, 1, 16, @tmpbits);
 SelectObject (hMemDC, hBitmap);
 DeleteDC (DC);
end;

function   DrawIcon2MDC (hico: HICON): Boolean;
var r: TRect;
begin
 result := FALSE;
 if hMemDC = 0 then exit;
 SetRect (r, 0, 0, 16, 16);
 FillRect (hMemDC, r, GetStockObject (WHITE_BRUSH));
 result := DrawIconEx (hMemDC, 0, 0, hico, 16, 16, 0, 0, DI_NORMAL);
end;

var
   binfo: record
    bmiHeader: tagBITMAPINFOHEADER;
    bmiColors: array [0..255] of RGBQUAD;
   end;

function    ScanIconBitmap (var ibmp: TIconBitmap): Byte;
var
   pbinfo: ^tagBITMAPINFO;
   colors: Integer;
   bitsCount: Byte;
begin
 result := 0;
 bitsCount := GetDeviceCaps (hMemDC, BITSPIXEL);
 colors := 1 shl bitsCount;
 InitializeBitmapInfoHeader (hBitmap, binfo.bmiHeader, colors);
 FillChar (ibmp, sizeof (ibmp), 255);
 pbinfo := @binfo;
 if GetDIBits (hMemDC, hBitmap, 0, 16, @ibmp,
            pbinfo^, DIB_RGB_COLORS) = 0 then exit;
 result := bitsCount;
end;


function    IconCreateBitmap;
var
   tmp: TBitmapLine;
   hbmp: DWORD;
   y: Integer;
begin
 // reversion
 for y := 0 to 7 do
 begin
   tmp := ibmp [y];
   ibmp [y] := ibmp [15 - y];
   ibmp [15 - y] := tmp;
 end;
 hBmp := CreateBitmap (16, 16, 1, bitsCnt, @ibmp);
 result := hBmp;
end;

function  BitFX (src: DWORD; shift: Byte): Byte;
begin
 src := src and (7 shl shift);
 src := src shr shift;
 src := src * 32;
 if src > 0 then dec (src);
 result := byte (src);
end;

procedure InitBitmapInfo;
var n: Integer;
begin
 binfo.bmiHeader.biWidth := 16;
 binfo.bmiHeader.biHeight := 16;
 binfo.bmiHeader.biPlanes := 1;
 binfo.bmiHeader.biBitCount := GetDeviceCaps (hMemDC, BITSPIXEL);
 for n := 0 to 255 do
 with binfo.bmiColors [n] do
  begin
   rgbRed := BitFX (n, 0);
   rgbGreen := BitFX (n, 2);
   rgbBlue := BitFX (n, 4);
   palette [n] := binfo.bmiColors [n];
  end;
end;

{ TIconStorage }

function TIconStorage.AddIcon(hIcon: HICON): Integer;
var p: PIconInfo;
    szimg: Integer;
begin
 ASSERT (hIcon <> 0);
 New (p); // where is long operation?
 p.hIcon := hIcon;
 p.dataSize := 0;
 //icvt.ReleaseHandle;
 //icvt.Handle := hIcon;
 stm.Size := 0; // reset size
 if DrawIcon2MDC (hIcon) then
  begin
   pic.Bitmap.ReleaseHandle;
   pic.Bitmap.Handle := hBitmap;
  end
 else RaiseLastOSError;
 // pic.Bitmap.ReleaseHandle;
 // icvt.SaveToStream(stm);
 stm.Seek(0, soFromBeginning);
 pic.Bitmap.SaveToStream(stm);
 szimg := stm.Size;
 if (szimg > 0) and (szimg < 2048) then
  begin
   stm.Seek(0, soFromBeginning);
   if stm.Read (p.streamData, szimg) = szimg then
      p.dataSize := szimg;
  end;
 result := Add (p);
end;

procedure TIconStorage.BeginUpdate;
var n: Integer;
begin
 for n := 0 to Count - 1 do
 if Assigned (Items [n]) then
   PIconInfo (Items [n]).saveIt := FALSE;
end;

procedure TIconStorage.DeleteUnmarked;
var n: Integer;
begin
 n := 0;
 while (n < Count) do
 begin
  // сохранять защищенные иконки
  if Assigned (Items [n]) and PIconInfo (Items [n]).saveIt then
   Inc (n) else
    begin
     if bReleaseIcons then DestroyIcon (Icons [n].hIcon);
     Delete (n);
    end; 
 end;
end;

constructor TIconStorage.Create;
begin
 pic := TPicture.Create;
 pic.Bitmap.Width := 16;
 pic.Bitmap.Height := 16;
 pic.Bitmap.PixelFormat := pf32bit;
 pic.Bitmap.ReleaseHandle;
 pic.bitmap.Handle := hBitmap;
 stm := TMemoryStream.Create;
end;

destructor TIconStorage.Destroy;
begin
 pic.Free;
 // icvt.Free;
 stm.Free;
end;

function TIconStorage.FindIcon(hIcon: HICON): Integer;
var n: Integer;
begin
 result := -1;
 for n := 0 to Count - 1 do
  if Assigned (Items [n]) and
      (PIconInfo (Items [n]).hIcon = hIcon) then
  begin
   result := n;
   exit;
  end;
end;

procedure TIconStorage.RemoveIcon(hIcon: HICON);
var n: Integer;
begin
 n := FindIcon (hIcon);
 if n >= 0 then Delete (n);
end;

function TIconStorage.GetIcon(Index: Integer): PIconInfo;
begin
 result := nil;
 if (Index < 0) or (Index >= Count)
    then Error ('Используется неверный индекс.', Index)
    else result := Items [Index]
end;

function TIconStorage.AddWindowIcon(hWnd: HWND): Integer;
var hIco: Integer;
begin
 result := -1;
 hIco := FindWinIcon (hWnd);
 if hIco <> 0 then
  begin
   result := AddIcon (hIco);
   Icons [result].hWnd := hWnd;
   DestroyIcon (hIco);
  end;
end;

function TIconStorage.FindByWindow(hWnd: HWND): Integer;
var n: Integer;
begin
 result := -1;
 for n := 0 to Count - 1 do
  if Assigned (Items [n]) then
    if hWnd = Icons [n].hWnd then
     begin
      result := n;
      break;
     end;
end;

procedure TIconStorage.Clear;
var n: Integer;
begin
 for n := 0 to count - 1 do
 begin
  if Assigned (Items [n]) then Dispose (Items [n]);
  Items [n] := nil; 
 end;
 inherited;
end;

initialization
 OpenMDC;
 InitBitmapInfo;
end.
