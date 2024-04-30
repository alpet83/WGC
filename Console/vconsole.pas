{$WARN SYMBOL_PLATFORM OFF}
unit vconsole;
{  Win32 console-output wrapper class. Created 22.04.06 by alpet.


}
interface
uses Windows, SysUtils;
const defConMode = ENABLE_PROCESSED_OUTPUT;



type
     TVConsole = class // отображаемая консоль Win32
     protected
      bOwner: Boolean;
      FHandle: THandle;
      FInfo: CONSOLE_SCREEN_BUFFER_INFO;
      function   GetAttr: WORD;
      function   GetInfo: CONSOLE_SCREEN_BUFFER_INFO;
      function   GetSize: COORD;
      function   GetHeight: Integer;
      function   GetWidth: Integer;
      procedure  SetAttr (wAttr: WORD);
      procedure  SetHeight (h: Integer);
      procedure  SetWidth (w: Integer);
     public
      property          Handle: THandle read FHandle;
      property          Height: Integer read GetHeight write SetHeight;
      property          Width: Integer read GetWidth write SetWidth;
      property          TextAttr: Word read GetAttr write SetAttr;

      constructor       Create;
      destructor        Destroy; override;
      // other procs/funcs
      procedure         Allocate;
      procedure         Attach (hConsole: THandle);
      procedure         Close;
      procedure         SetActive;
      procedure         SetMode (mode: DWORD = defConMode);

      procedure         SetSize (x, y: Integer);
      procedure         WriteText (const sText: String);
     end;

implementation

{ TVConsole }

procedure TVConsole.Allocate;
begin
 FHandle := CreateConsoleScreenBuffer (GENERIC_READ or GENERIC_WRITE,
                        FILE_SHARE_READ, nil, CONSOLE_TEXTMODE_BUFFER, nil);
 if FHandle = INVALID_HANDLE_VALUE then RaiseLastOSerror;
 bOwner := TRUE;
 SetMode;
end;

procedure TVConsole.Attach(hConsole: THandle);
begin
 Close;
 FHandle := hConsole;
 SetMode;
end;

procedure TVConsole.Close;
begin
 if (FHandle <> 0) and (bOwner) then CloseHandle (FHandle);
 bOwner := FALSE;
 FHandle := 0;
end;

constructor TVConsole.Create;
begin
 FHandle := 0;
end;

destructor TVConsole.Destroy;
begin
 Close;
end;

function TVConsole.GetAttr: WORD;
begin
 result := GetInfo.wAttributes;
end;

function TVConsole.GetHeight: Integer;
begin
 result := GetSize.Y;
end;

function TVConsole.GetInfo: CONSOLE_SCREEN_BUFFER_INFO;
begin
 Win32Check (GetConsoleScreenBufferInfo (Handle, FInfo));
 result := FInfo;
end;

function TVConsole.GetSize: COORD;
begin
 result := GetInfo.dwSize;
end;

function TVConsole.GetWidth: Integer;
begin
 result := GetSize.X;
end;

procedure TVConsole.SetActive;
begin
 Win32Check (SetConsoleActiveScreenBuffer (Handle));
end;

procedure TVConsole.SetAttr(wAttr: WORD);
begin
 Win32Check (SetConsoleTextAttribute (Handle, wAttr));
end;

procedure TVConsole.SetHeight(h: Integer);
begin
 SetSize (Width, h);
end;

procedure TVConsole.SetMode(mode: DWORD);
begin
 if Handle > 0 then
    Win32Check (SetConsoleMode (Handle, mode));
end;

procedure TVConsole.SetSize(x, y: Integer);
begin
 FInfo.dwSize.x := x;
 FInfo.dwSize.y := y;
 Win32Check (SetConsoleScreenBufferSize (Handle, FInfo.dwSize));
end;

procedure TVConsole.SetWidth(w: Integer);
begin
 SetSize (w, Height);
end;

procedure TVConsole.WriteText(const sText: String);
var wrtd: DWORD;

begin
 WriteConsole (Handle, PChar (sText), Length (sText), wrtd, nil);
end;

end.
 