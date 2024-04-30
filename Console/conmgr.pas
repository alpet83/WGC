unit conmgr;
{ Console Manager unit. Allow creating, swithing, and activating consoles.

}
interface
uses Windows, vconsole, Contnrs;

type
     TConManager = class (TObjectList)
     public
      nActiveCon: Integer;
      function          AddConsole: TVConsole;
      function          AddDefault: TVConsole;
      procedure         Delete (nItem: Integer);
      // Активация консоли по номеру
      procedure         SwitchConsole (nConsole: Integer);
     end;

var conman: TConManager;

implementation

{ TConManager }

function TConManager.AddConsole: TVConsole;
begin
 result := TVConsole.Create;
 result.Allocate;
 Add (result);
end;

function TConManager.AddDefault: TVConsole;
var hOutput: THandle;
begin
 result := nil;
 hOutput := GetStdHandle (STD_OUTPUT_HANDLE);
 if (0 = hOutput) then exit;
 result := TVConsole.Create;
 result.Attach (hOutput);
 Add (result);                         
end;

procedure TConManager.Delete(nItem: Integer);
begin
 if (nItem < Count) and (Assigned (items [nItem])) then
  Remove (items [nItem]); 
end;

procedure TConManager.SwitchConsole(nConsole: Integer);
begin
 if nConsole >= Count then exit;
 if (Assigned (Items [nConsole])) then
  begin
   TVConsole (Items [nConsole]).SetActive;
   nActiveCon := nConsole;
  end;
end;

initialization
 conman := TConManager.Create;
 conman.AddDefault; // items [0]
finalization
 conman.Free;
end.
