unit ChPointers;

interface
uses Windows;
{ Функции по работе с указателями }
function  DecodePtr (_alias: dword; const src: string): dword;

implementation
uses Misk, SysUtils;

const hxchars: set of WideChar = ['$', '0'..'9','A'..'F'];
function  ParseHex (const src: string; var n: Integer): string;

var
    s: string;
begin
 result := '';
 s := UpperCase (src);
 while (n <= length (s)) and
       (s [n] in hxchars) do
  begin
   result := result + s [n];
   inc (n);
  end;
end; // Parse Hex


function  GetDWORD (const _alias, paddr: dword): dword;
var rd: dword;
begin
 result := 0;
 if (_alias <> 0) then
  ReadProcessMemory (_alias, pointer(paddr), @result,
                        sizeof (result), rd);
end; // GetDWORD

function  DecodePtr;
var
   s: string;
   n, e: Integer;
   base, add: dword;
begin
 base := 0;
 n := 1;
 s := ParseHex (src, n);
 if (s <> '') then val (s, base, e); // Оцифрить
 repeat
  if (n > length (src)) or (e <> 0) then
   begin
    result := base; // Значение завершено
    exit;
   end;
  // Тестирование на указатель
  if (src [n] = '^') then base := GetDword (_alias, base);
  inc (n);
  s := ParseHex (src, n);
  add := 0;
  if (s <> '') then val (s, add, e);
  base := base + add;
 until false; // "вечный цикл"
 // $47A9C0C
end; // DecodePtr

end.
 