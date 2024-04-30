unit ChPlugin;
(* ================ Модуль поддержки плагинов ====================== *)
interface
Uses Windows, SysUtils, ChTypes, Menus;




procedure    StoreToMenu (var menu : TMenuItem);
function     GetIndex (var mi : TMenuItem; var plgNum : Integer) : Integer;

implementation
uses    StrSrv, ChShare, ChForm, Forms, ChClient;

function     GetIndex;
var
   sub : TMenuItem;
begin
 result := -1;
 sub := mi.Parent;
 if (sub = nil) then exit;
 plgNum := mform.mmenu.Items.IndexOf (sub) + 1;
 result := sub.IndexOf (mi);
end; // GetIndex;

procedure    StoreToMenu;
var x, y, i : Integer;
    m : TMenuItem;
begin
 //debugBreak;
 menu.Clear;
 with csm.plugRec do
 for y := 1 to pgCount do
  begin
   m := TMenuItem.Create(menu.Owner); // Создать элемент меню
   if pgNames [y] <> nil then m.Caption := pgNames [y]^;
   menu.Add(m);
   i := menu.IndexOf(m);
   if i >= 0 then
   for x := 0 to pgFuncs [y].dlgCount - 1 do
    begin
     m := TMenuItem.Create (menu.Owner);
     if pgFuncs [y].dlgNames [x] <> nil then
        m.Caption := pgFuncs [y].dlgNames [x];
     m.OnClick := mform.miPluginClick;
     menu.items [i].Add(m); // Добавление подэлемента
    end;
  end;
end; // StoreToMenu





end.
 