unit strtools;

interface
uses Windows;

function        UpperKey (ch: char): char;

implementation


const htab: PCHAR =
            ('!1@2#3$4%5^6&7*8(9)0' +
              ':;"'#$27'|\<,>.?/_-+=~`');

function        UpperKey (ch: char): char;
var n: Integer;
begin
 result := ch;
 if ( ch in ['a'..'z'] ) then begin result := UpCase (ch); exit; end;
 n := 0;
 if ch <> #0 then
 while (htab [n] <> #0) do
  begin
   if ch = htab [n + 1] then
       begin result := htab [n + 0]; exit; end;
   inc (n, 2);
  end;
end; // UpperKey


end.
 