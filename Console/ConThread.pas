unit ConThread;

interface
uses Windows, Classes, ChStrings, SimpleArray;

type
    TConsoleThread = class (TThread)
     procedure          Execute; override;
     destructor         Destroy; override;
    end; //

    TStringStorage = class (TSimpleArray)
    private
    protected
     FItems: array of PBaseString;
     bOptimize: Boolean;
     procedure          Add (ps: PBaseString);
     procedure          SetSize (nSize: Integer); override;
     procedure          Lock;
    public
     lastOuted: Integer;
     constructor        Create (arrayIdent: Integer);
     procedure          WriteAttrStr (const s: string; attr: Byte; ncon: Integer = 0);
     function           GetDataPtr: Pointer; override;
     function           ItemSize: Integer; override;
     function           PerformOutput (): Boolean;
     procedure          Optimize;
    end;

procedure WriteConStr (const s: string; attr: Byte; ncon: Integer = 0);

implementation
{ TStringStorage }
uses VConsole, conmgr;


var sstorage: TStringStorage = nil;
    cthread: TConsoleThread = nil;
    hOutput: THandle = 0;

procedure SetAttr (attr: Byte);
begin
 if hOutput = 0 then hOutput := GetStdHandle (STD_OUTPUT_HANDLE);
 if hOutput <> 0 then
    SetConsoleTextAttribute (hOutput, attr);
end;

procedure WriteConStr;
begin
 if not Assigned (sstorage) then exit;
 sstorage.WriteAttrStr (s, attr, ncon);
end;

procedure TStringStorage.Add(ps: PBaseString);
var iadd: Integer;
begin
 if FCount >= FSize then SetSize (FCount + 16); // resize
 iadd := AddItems (1);
 if iadd < 0 then exit;
 FItems [iadd] := ps;
 bOptimize := FCount > 250; // allow optimization
end;

constructor TStringStorage.Create;
begin
 lastOuted := 0;
 bOptimize := FALSE; // optimization needs after some time
 inherited;
end;

function TStringStorage.GetDataPtr: Pointer;
begin
 result := @FItems;
end;

function TStringStorage.ItemSize: Integer;
begin
 result := sizeof (FItems [0]);
end;

procedure TStringStorage.Lock;
begin
 while not TryLock (1000) do ;
end;

procedure TStringStorage.Optimize;
begin
 // Удаление всех элементов, коррекция размера 
 Lock;
 lastOuted := 0;
 FCount := 0;
 if FSize > 256 then SetSize (256);
 Unlock;
end;

function TStringStorage.PerformOutput;
var n: Integer;
    c: TVConsole;
    BS: PBaseString;
begin
 result := FALSE;
 // Простой вывод новых строк
 while (lastOuted < ItemsCount)  do
 begin
   n := lastOuted;    // alias
   bs := FItems [n];  // current string
   ASSERT (Assigned (bs));
   if (bs.nConsole >= conman.Count) then exit;
   c := TVConsole (conman.Items [bs.nConsole]);
   if (not Assigned (c)) then exit;
   c.TextAttr := bs.TextAttr;
   if c.Handle <> 0 then
    begin
     c.WriteText (bs.data + #13#10);
     FreeBStr (bs); // release
    end
   else Break; // console not ready
   result := TRUE;
  Inc (lastOuted);
 end;
 if hOutput <> 0 then SetAttr (7); // default attr
end; // PerformOutput

procedure TStringStorage.SetSize(nSize: Integer);
var n: Integer;
begin
 if nSize < FCount then
    for n := nSize to ItemsCount - 1 do FreeBStr (FItems [n]);

 inherited;
 SetLength (FItems, FSize);
end;


procedure TStringStorage.WriteAttrStr;
var ps: PBaseString;
begin
 Lock;
 ps := AllocBStr (Length (s) + 1);
 ps.nConsole := ncon;
 ps.data := s;
 ps.TextAttr := attr;
 Add (ps);
 Unlock;
end; // Write

{ TConsoleThread }

destructor TConsoleThread.Destroy;
begin
 sstorage.Free;
 sstorage := nil;
end;

procedure TConsoleThread.Execute;
begin
 repeat
  // wait for ready stage
  if not Assigned (sstorage) then
   begin
    sleep (150);
    continue;
   end;
  if hOutput <> 0 then hOutput := GetStdHandle (STD_OUTPUT_HANDLE);
  if not sstorage.PerformOutput then Sleep (250);
  if sstorage.bOptimize and (hOutput <> 0) then sstorage.Optimize;
 until Terminated;
end;

initialization
 sstorage := TStringStorage.Create (0);
 cthread := TConsoleThread.Create (FALSE);
 cthread.Priority := tpLower;
 // cthread.Priority := tpIdle;
 cthread.FreeOnTerminate := TRUE; // self destroyng
finalization
 cthread.Terminate;
end.
