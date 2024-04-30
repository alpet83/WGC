unit PSLists;

interface
uses Windows, SimpleArray, ChTypes;

type
    TModuleArray = class (TSimpleArray)
    protected
     FItems: array of TModuleInfo;
     procedure  SetSize (nSize: Integer); override;
     function   GetItem (nItem: Integer): TModuleInfo;
    public
     property   Items [Index: Integer]: TModuleInfo read GetItem; default;
     procedure  Add (const mlist: array of TModuleInfo; nCount: Integer);
     function   GetDataPtr: Pointer; override;
     function   ItemSize: Integer; override;
    end;

    TThreadArray = class (TSimpleArray)
    protected
     FItems: array of TThreadInfo;
     procedure  SetSize (nSize: Integer); override;
     function   GetItem (nItem: Integer): TThreadInfo;
    public
     property   Items [Index: Integer]: TThreadInfo read GetItem; default;
     procedure  Add (const tlist: array of TThreadInfo; nCount: Integer);
     function   GetDataPtr: Pointer; override;
     function   ItemSize: Integer; override;
    end;


    TRegionArray = class (TSimpleArray)
    protected
     FItems: array of TRegion;
     function  GetItem (nItem: Integer): TRegion;
     procedure SetSize (nSize: Integer); override;
    public
     VirtualSize: Int64;   // Размер памяти покрываемой регионами
     property   Items [Index: Integer]: TRegion read GetItem; default;
     procedure  AddRegion (const r: TRegion); virtual;
     function   GetDataPtr: Pointer; override;
     function   ItemSize: Integer; override;
    end;


implementation

{ TThreadArray }

procedure TThreadArray.Add;
var iadd, i: Integer;
begin
 iadd := AddItems (nCount);
 for i := 0 to nCount - 1 do
   FItems [i + iadd] := tlist [i];
end;

function TThreadArray.GetDataPtr: Pointer;
begin
 result := FItems;
end;

function TThreadArray.GetItem(nItem: Integer): TThreadInfo;
begin
 FillChar (result, sizeof (result), 0);
 if ChkIndex (nItem) then result := FItems [nItem];
end;

function TThreadArray.ItemSize: Integer;
begin
 result := sizeof (FItems [0]);
end;

procedure TThreadArray.SetSize(nSize: Integer);
begin
 SetLength (FItems, nSize);
 inherited;
end;

{ TModuleArray }

procedure TModuleArray.Add(const mlist: array of TModuleInfo;
  nCount: Integer);
var iadd: Integer;
begin
 iadd := AddItems (nCount);
 if (iadd >= 0) and Assigned (FItems) then
     Move (mlist, FItems [iadd], sizeof (TModuleInfo) * nCount);
end;

function TModuleArray.GetDataPtr: Pointer;
begin
 result := FItems;
end;

function TModuleArray.GetItem(nItem: Integer): TModuleInfo;
begin
 FillChar (result, sizeof (result), 0);
 if ChkIndex (nItem) then result := FItems [nItem];
end;

function TModuleArray.ItemSize: Integer;
begin
 result := sizeof (FItems [0]);
end;

procedure TModuleArray.SetSize(nSize: Integer);
begin
 SetLength (FItems, nSize);
 inherited;
end;


{ TRegionArray }
procedure TRegionArray.AddRegion (const r: TRegion);
var iadd: Integer;
begin
 iadd := AddItems (1);
 VirtualSize := VirtualSize + r.size;
 if iadd >= 0 then FItems [iadd] := r;
end;

function TRegionArray.GetDataPtr: Pointer;
begin
 result := FItems;
end;

function TRegionArray.GetItem(nItem: Integer): TRegion;
begin
 FillChar (result, sizeof (result), 0);
 if ChkIndex (nItem) then result := FItems [nItem];
end;

function TRegionArray.ItemSize: Integer;
begin
 result := sizeof (FItems [0]);
end;

procedure TRegionArray.SetSize(nSize: Integer);
begin
 inherited;
 SetLength (FItems, nSize);
end;

end.
 