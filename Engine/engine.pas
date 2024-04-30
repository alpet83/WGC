unit engine;
{
   Модуль обеспечения загрузчика трейнеров.
}
interface
uses Misk, SysUtils, Gtrainer, Windows, Types, Messages;

procedure  StartEngine (const fname: string);

var
   train: TTrainer;
implementation

procedure  MessageLoop (fLoop: Boolean = true);
var
     msg: tagMSG;
    fmsg: Boolean;
begin
 while fLoop and (train.hwnd <> 0) do
 begin
  if fLoop then fmsg := GetMessage (msg, NULL, 0, 0) else
                fmsg := PeekMessage (msg, NULL, 0, 0, PM_REMOVE);
  if msg.message = WM_QUIT then DestroyWindow (train.hwnd) else                
  if fmsg then
    begin
     TranslateMessage (msg);
     DispatchMessage (msg);
    end; // if message returned
  // sleep (20); // CPU
 end;
end; // MessageLoop

procedure  StartEngine;
begin
 // InitComCtrls;
 if (fname = '') then exit;
 train := TTrainer.Create;
 train.LoadDesc (fname);
 // checking for controls and values is loaded,
 // open specified game
 if (train.count > 0) then
  try
   train.CreateWnd (0); // Create Main Window and controls
   train.mlist.OnDestroy := train.OnDestroy;
   train.mlist.OnWMTimer := train.OnTimer;
   train.mlist.OnWMCommand := train.OnCommand;
   MessageLoop; // perform message Loop
  except
   On EAccessViolation do asm int 3 end;
  end;
 train.Free;
end; // StartEngine

end.
