unit SimpleArray;

interface
uses Windows, SyncObjs;

// TCriticalSection
type
    TSimpleArray = class
    protected
      FSize: Integer;
     FCount: Integer;
     scshare: TRTLCriticalSection;
     function           AddItems (nCount: Integer): Integer; virtual;
     function           ChkIndex (nItem: Integer): Boolean;
     procedure          SetSize (nSize: Integer); virtual;
    public
     Ident: Integer;
     property           ItemsCount: Integer read FCount;
     constructor        Create (arrayIdent: Integer);
     destructor         Destroy; override;
     procedure          Clear; virtual;
     function           GetDataPtr: Pointer; virtual; abstract;
     function           ItemSize: Integer; virtual; abstract;
     function           TryLock (TimeOut: Integer): Boolean; virtual;
     procedure          Unlock; virtual;
     function           Update (dwParam: DWORD): Boolean; virtual;
    end; // TSimpleArray


implementation
uses ChConst, Chlog, SysUtils, misk;


{ TSimpleArray }

function TSimpleArray.AddItems(nCount: Integer): Integer;
begin
 // раздвижение границ
 if FCount + nCount >= FSize then
             SetSize (FCount + nCount + 16);
 result := FCount; // теперь это индексъ
 Inc (FCount, nCount);              
end;

function TSimpleArray.ChkIndex(nItem: Integer): Boolean;
begin
 result := (nItem >= 0) and (nItem < ItemsCount);
 if not result then
   raise ERangeError.Create (
        format('Ошибочный индекс в TSimpleArray.ChkIndex: %d, count=%d',
                 [nItem, ItemsCount]));
 // LogStr ('WARNING: Using wrong index!');
end;

procedure TSimpleArray.Clear;
begin
 FCount := 0;
end;

constructor TSimpleArray.Create;
begin
 FSize := 0;
 FCount := 0;
 FillChar (scshare, sizeof (scshare), 0);
 InitializeCriticalSection (scshare);
 TryLock (20);
 Unlock;
 SetSize (32);
 Ident := ArrayIdent;
end;

destructor TSimpleArray.Destroy;
begin
 DeleteCriticalSection (scshare);
 SetSize (0);
end;


procedure TSimpleArray.SetSize(nSize: Integer);
begin
 if nSize > 0 then FSize := nSize else FSize := 0;
end;

function TSimpleArray.TryLock;
begin
 repeat
  result := TryEnterCS (scshare);
  if result then Break;
  if (TimeOut > 0) then Sleep (20);
  Dec(TimeOut, 20);
 until TimeOut <= 0;
end; // TryLock

procedure TSimpleArray.Unlock;
begin
 LeaveCriticalSection (scshare);
end; // Unlock

function TSimpleArray.Update(dwParam: DWORD): Boolean;
begin
 result := FALSE;
end;

end.
 