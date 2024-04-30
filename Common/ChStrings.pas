unit ChStrings;

interface
uses Windows;
{$WARN IMPLICIT_STRING_CAST OFF}

{ ћодуль обеспечени€ универсальных строк (дл€ обмена в том числе
 по сетевому протоколу) }
type
    TBaseString = object
    protected
     MaxCount, FLength: SmallInt; // 4 bytes (32K max)
      charSize: Byte;
     FTextAttr: Byte;
     flags: WORD;
     nDestConsole: Integer; // destination console

     FBody: array [0..7] of AnsiChar;  // overlayed array - must be last data member in object
     procedure     Assign (const src: String);
     function      GetAnsi: PAnsiChar;
     function      GetString: String;
    public

     property      Length: SmallInt read FLength;
     property      AnsiStr: PAnsiChar read GetAnsi;
     property      data: String read GetString write Assign;
     property      TextAttr: Byte read FTextAttr write FTextAttr;
     property      nConsole: Integer read nDestConsole write nDestConsole;

     constructor   Init (nCount: SmallInt; chsz: SmallInt = 1);
     destructor    Destroy;      
     function      GetSize: DWORD;
    end;
    PBaseString = ^TBaseString;

function AllocBStr (nCharCount: SmallInt;
                    nCharSize: SmallInt = 1): PBaseString;

procedure FreeBStr (var pstr: PBaseString);
implementation
uses SysUtils;
const BSExtraSize = 12;

function AllocBStr (nCharCount, nCharSize: SmallInt): PBaseString;
begin
 GetMem (result, nCharCount * nCharSize + BSExtraSize);
 result.Init(nCharCount, nCharSize);
end;

procedure FreeBStr;
begin
 pstr.Destroy;
 pstr := nil;
end;

{ TBaseString }
procedure TBaseString.Assign(const src: String);
begin
 FLength := System.Length (src);
 if FLength >= MaxCount then FLength := MaxCount -1;
 if charSize = sizeof (WideChar) then
    StringToWideChar (src, PWideChar (@FBody), MaxCount);
 if charSize = sizeof (AnsiChar) then
    StrLCopy (FBody, PAnsiChar ( AnsiString(src) ), MaxCount);
end;

destructor TBaseString.Destroy;
begin
 FreeMem (@self);
end; // Destroy

function TBaseString.GetAnsi: PAnsiChar;
begin
 ASSERT (charSize = sizeof (AnsiChar));
 result := FBody;
end; 

function TBaseString.GetSize: DWORD;
begin
 result := DWORD (FLength * charSize + BSExtraSize);
end;

function TBaseString.GetString: String;
begin
 result := GetAnsi;
end; // GetString

constructor TBaseString.Init;
begin
 FillChar (FBody, nCount * chsz, 0); // object must be allocated!
 charSize := Byte (chsz);
 MaxCount := nCount;
 FLength := 0;
 flags := 1; // initialized
end;

end.
