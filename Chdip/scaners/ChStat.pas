unit ChStat;
interface
uses Windows, ChTypes, ChConst;
{
  Модуль поддержки статистики

  Статистика в библиотеке используется для оптимизации процесса отсева.
  Параметры функции составляются во внутреннем цикле сканирования большого буффера (ScanBBuff).

    AddStat - эта функция добавляет в текущий регион (или создает новый)
  блок памяти в котором при поиске/отсеве были замечены указатели.
  При следующем отсеве будут использоваться только те регионы которые
  были созданы в процессе сбора статистики/
}
type

    TStatRec = record
     reg : TRegion;
     fnd : dword; // Found values in region
     // tic : int64; // Время создания элемента статистики в PerfTicks
    end;
    // Массив статистики

    TStatArray = array [1..MaxStat] of TStatRec;

    TStatMan = class (TObject)
      stats : TStatArray;
      stati : dword;    // Текущий элемент статистики
      statc : dword;    // Количество элементов статистики
     nStatc : dword;    // Количество обновленных элементов
      lastP : dword;
       NewF : Integer;    // Найдено сейчас
      LastF : Integer;    // Найдено в предыдущий раз

      index : dword;    // Для оптимизации
     constructor                Create;
     procedure                  Reset;
     procedure                  ResetX;
     procedure                  Save;
     procedure                  AddStat (paddr, plimit : dword; const src: TRegion);
     function                   TestPtr (const ptr : dword) : boolean;
     // Поиск региона с найдеными значениями
     function                   Find (const paddr: dword): dword;
  private

   end;


var
     statman : TStatMan;

implementation
uses  ChShare, ChServer;

 constructor            TStatMan.Create;
 begin
 end;

function               TStatMan.Find;
var n: dword;
begin
 result := 0;
 if (statc = 0) then exit;
 if (index > 0) and (stats [index].reg.ofst <= paddr) then
                      else index := 1; // Сброс индекса
 for n := index to statc do
 if (stats [n].reg.ofst >= paddr) and
    (stats [n].fnd > 0) then
  begin
   result := n;      // Найден подходящий регион
   index := n;       // Значение оптимизатора
   exit;
  end;
end; //TStatMan.Find

procedure               TStatMan.ResetX;
begin
 LastF := 0;
 LastP := 0;
 nStatc := 0;      // Новая статистика
 statI := 0;
end; // ResetX

procedure              TStatMan.Reset;
begin
 statc := 0;
end;

procedure              TStatMan.Save;
begin
 Statc := nStatc; // Сохранить количество данных статистики
end;


function               TStatMan.TestPtr;
begin
 result :=  (ptr < LastP) and (LastP > 0);
end;
{
 function   TStatMan.TestMerge (const paddr, count: dword): boolean;
 begin
  result := false;
  if (nStatc = 0) then exit; // не почему определить
  if (stats [nstatc].reg.limit + 64 >= paddr) then // можно слить эти регионы
  with stats [nstatc] do
   begin
    reg.limit := paddr + count;        // расширить лимит
    reg.size := reg.limit - reg.ofst;  // скорректировать размер региона
    reg.rsize := reg.size;
    result := true; // слияние прошло
   end;
 end; // TestMerge {}

 procedure   TStatMan.AddStat;
   var n : Integer;
    NewF : Integer;
    count: Integer;
 begin
  NewF := 0; // общее число найденых за итерацию указателей
  count := plimit - paddr; // Количество байт..
  for n := 1 to MaxRqs do
  if ssm.RqsLst [n].enabled then
     NewF := NewF + ssm.svars.Fnds [n].FoundCount; // Получить сумму
  if (count > 0) and (NewF > LastF) and (paddr > LastP) then // Если найдены указатели
   begin
    if (nStatc < MaxStat) then // пока не презаполнен массив
     begin
      inc (nStatc); // добавление региона статистики
      with stats [nStatc] do
        begin
         fnd := Abs (NewF - LastF);
         reg.ofst := paddr;     // смещение в процессе
         reg.size := count;     // размер региона
         reg.rsize := count;
         reg.limit := reg.ofst + DWORD(count); // предел региона
         reg.state := src.state;        // состояние региона
         reg.protect := src.protect;    // доступ к региону, защита
         LastF := NewF;
        end;
     end; // Добавление нового региона статистики   
   end;
  LastP := paddr; // запомнить смещение
 end;

end.
 