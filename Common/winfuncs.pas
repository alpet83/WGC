unit winfuncs;

interface
uses Windows;




procedure InitTemplate (var template: tagCREATESTRUCTA;
                        szClassName, szWindowText: PAnsiChar;
                        dwStyle: DWORD = 0;
                        pWndRect: PRect = nil);

function MakeWindow (const template: tagCREATESTRUCTA; ctrlId: DWORD = 0): HWND;

function RegClassEx (name: PAnsiChar; wFunc: Pointer; style: DWORD): Boolean;


implementation

procedure  InitArray (dest: Pointer; nCount, nItemSize, nValue: Cardinal); stdcall;

asm
 push ecx
 push edi
 mov  edi, dest
 mov  ecx, nCount
 mov  eax, nValue
 cld
 cmp  nItemSize, 1
 je   @fillb
 cmp  nItemSize, 2
 je   @fillw
 rep  stosd
 jmp  @exit
@fillw:
 rep  stosw
 jmp  @exit
@fillb:
 rep  stosb
 jmp  @exit
@exit:
 pop  edi
 pop  ecx
end;

procedure InitTemplate;
begin
 FillChar (template, sizeof (template), 0);
 with template do
 begin
  hInstance := System.MainInstance;
  if (Assigned (pWndRect)) then with pWndRect^ do
   begin
    x := Left;
    y := Top;
    cx := Right - Left;
    cy := Bottom - Top;
   end
  else
    InitArray (@cy, 4, 4, CW_USEDEFAULT);
  template.style := dwStyle;
  lpszClass := szClassName;
  lpszName := szWindowText;
 end;
end;


function RegClassEx;
var
   wclass: WNDCLASSEXA;
begin
 result := true;
 fillchar (wclass, sizeof (wclass), 0);
 wclass.cbSize := sizeof (wclass);
 if not GetClassInfoExA (hInstance, PAnsiChar (name), wclass) then
  begin
   wclass.cbSize := sizeof (wclass);
   wclass.lpszClassName := name;
   wclass.lpfnWndProc := wFunc;
   wclass.style := style;
   wclass.hInstance := hInstance;
   wclass.hbrBackground := GetSysColorBrush (COLOR_BTNFACE);
   wclass.hCursor := LoadCursor (0, IDC_ARROW);
   result := RegisterClassExA (wclass) <> 0;
  end;
end;

function MakeWindow;
begin
 with template do
 result := CreateWindowExA (dwExStyle, lpszClass, lpszName,
                           style, x, y, cx, cy,
                           hwndParent, 0, hInstance, @template);
 if (ctrlId <> 0) and (result <> 0) then
    SetWindowLong (result, GWL_ID, ctrlId);
end;

end.
