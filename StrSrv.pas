unit StrSrv;

interface
uses SysUtils;

type
     TStrSrv = class
     private
      s : string;
      i : Integer;                                                      // Текущий индекс
      l : Integer;
     public
      constructor               Create;
      procedure                 Assign (const src : string); virtual;
      function                  GetStr : string; virtual;
      procedure                 SetStart; virtual;                      // Seek to start
      function                  ReadSub: string; virtual;               // Read sub string
      function                  ReadRest: string;
      destructor                Destroy; override;
     end;

implementation

procedure  TStrSrv.Assign (const src : string);
begin
 s := src;
 i := 1;
 l := Length (src);
end; // Assing

constructor TStrSrv.Create;
begin
 s := '';
 l := 0;
 i := 1;
end; // Create

destructor TStrSrv.Destroy;
begin
 s := '';
 inherited;
end; // Destroy

function TStrSrv.GetStr: string;
begin
 result := s;
end; // GetStr

const
    spltrs: Set of WideChar = [' ', ',', ';', #9];

function TStrSrv.ReadRest: string;
begin
 result := '';
 l := length (s);
 // Пропусk пробелов
 while (i < l) and ( CharInSet ( s [i], spltrs ) ) do Inc (i);
 if (i < l) then
  result := copy (s, i, l - i + 1);
end; // ReadRest

function TStrSrv.ReadSub: string;
var n : Integer;


begin
 result := '';
 l := length (s);
 // Пропусk пробелов
 while (i < l) and (s [i] in spltrs) do Inc (i);
 n := i;
 // Scaning to space
 while (n <= l) and not (s [n] in spltrs) do Inc (n);
 // Testing for difference
 if (n > i) then
  begin
   l := n - i;
   result := copy (s, i, l);
  end;
 i := n;
end; // ReadSub

procedure TStrSrv.SetStart;
begin
 i := 1;
end; // SetStart

end.
 