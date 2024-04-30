unit ChValues;

interface
uses ChTypes, ChConst;

type
     TValuesTable = class
     protected
      //FValues: array of TTableValue;
       Hashes: array of Integer;
      FSize: Integer;
      FCount: Integer;
      //function          GetValue (nVal: Integer): TTableValue;
      //procedure         SetValue (nVal: Integer; const v: TTableValue);
     public
      property          Count: Integer read FCount;
      //property          Items [Index: Integer]: TTableValue read GetValue write SetValue;
      function          ChkIndex (Index: Integer): Boolean;
      constructor       Create;
      destructor        Destroy; override;
      function          AddValue: Integer;
      procedure         Clear;
      procedure         SetSize (nSize: Integer); virtual;
     end;

implementation
uses Misk;

function TValuesTable.AddValue;
begin
 result := Count;
 if Count >= FSize then SetSize (Count + 32);
 Inc (FCount);
end;


function TValuesTable.ChkIndex(Index: Integer): Boolean;
begin
 result := CheckIndex (index, Count);
end;

procedure TValuesTable.Clear;
begin
 FCount := 0;
end;

constructor TValuesTable.Create;
begin
 SetSize (256);
end;

destructor TValuesTable.Destroy;
begin
 SetSize (0);
end;


procedure TValuesTable.SetSize(nSize: Integer);
begin
 SetLength (Hashes, nSize);
 FSize := nSize;
end;


end.
