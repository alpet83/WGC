unit ChLang;
(* -------------------------------------------------------------------- *)
{ Модуль поддержки локализации WGC }
interface
uses Windows;

type
    TLclStr = record
     id : string;
     lc : string;
    end;

var
   lclFile : string = 'none';
   lclMsgs : array [1..24] of TLclStr;
   lclCount: dword = 0;

function    LocStr (const id: string): string;   

procedure   Localize (const filename : string);

implementation
uses ChForm, Classes, Forms, Controls, StdCtrls, ComCtrls, SysUtils, Menus;

function    LocStr;
var
   n: dword;
begin
 result := id;
 for n := 1 to High (lclMsgs) do
 if lclMsgs [n].id = id then
  begin
   result := lclMsgs [n].lc;
   exit;
  end;
end; // LocStr

procedure  AddStr (const _id, _lc: string);
// Добавление строки локализации
begin
 if (lclCount < High (lclMsgs)) then Inc (lclCount);
 lclmsgs [lclcount].id := _id;
 lclmsgs [lclcount].lc := _lc;
end;

procedure  SetStr (const _id, _lc: string);
// Замена строки локализации
var n: dword;
begin
 for n := 1 to High (lclMsgs) do
 if lclMsgs [n].id = _id then
  begin
   lclMsgs [n].lc := _lc;
   exit;
  end;
end; // SetStr

procedure   InitRussian;
begin
 lclCount := 0;
 AddStr ('%MapCreatingMsg%', 'Инициализация...');
 AddStr ('%MapCreateComplete%', 'Инициализация завершена.');
 AddStr ('%AliasCreated%', 'Для процесса $%x создан алиас $%x');
 AddStr ('%AliasKilled%', 'Алиас процесса $%p уничтожен.');
 AddStr ('%Process_Size%','Размер процесса:');
 AddStr ('%ProcessNotSelected%','Процесс не выбран');
 AddStr ('%Process_Start%', ' Процесс %sа начат');
 AddStr ('%Process_Complete%', ' Процесс %sа завершен');
 AddStr ('%FirstScan%', 'поиск');
 AddStr ('%NextScan%', 'отсев');
 AddStr ('%ScanError%', 'Ошибка %sa:  %s');
 AddStr ('%TimeOfProcess%', 'Время %sa : %s сек      Скорость ~= %s/ сек');
 AddStr ('%FoundValues%','Найдено значений: %u ');
end;

procedure   Localize;
var
   t : text;
   s, s2 : string;
   i : byte;
   c : TComponent;
   fHint : boolean;
   fMssg : boolean;
begin
 if (filename = 'none') or (filename = '') then exit;
 assign (t, filename);
 {$I-}
  reset (t);
  if IOresult <> 0 then exit;
 {$I+}
 lclFile := filename;
 try
 while not eof (t) do
  begin
   readln (t, s);
   if pos (';', s) = 1 then continue; // Пропуск комментария
   i := pos ('.hint', LowerCase (s));
   fHint := i > 0;
   if fHint then Delete (s, i, 5);
   i := pos ('=', s);
   s2 := copy (s, 1, i - 1);           // component name
   delete (s, 1, i);  // new caption
   fMssg := false;
   if (s2 <> '') then
    fMssg := (s2 [1] = '%') and (s2 [Length (s2)] = '%');
   if fMssg then
    begin
     SetStr (s2, s); // Замена строки локализации
     continue;
    end;
   c := mform.FindComponent (s2); // Найти локализуемый компонент
   if (c <> nil) then
   if fHint then
    begin
     if c is TButton  then (c as TButton).hint := s;
     if c is TCheckBox then (c as TCheckBox).hint := s;
     continue;
    end
   else
    begin
     if c is TButton    then (c as TButton).caption := s;
     if c is TCheckBox  then (c as TCheckBox).caption := s;
     if c is TGroupBox  then TGroupBox(c).Caption := s;
     if c is TLabel     then TLabel (c).Caption := s;
     if c is TTabSheet  then (c as TTabSheet).caption := s;
     if c is TMenuItem  then (c as TMenuItem).caption := s;
    end;
  end;
 finally
  close (t);
 end; //
end;


var
   n : dword;
begin
 for n := 1 to high (lclmsgs) do
 with lclmsgs [n] do
  begin
   id := ''; lc := '';
  end;
 InitRussian;
end.
