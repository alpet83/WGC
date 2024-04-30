function _updPrcsList: boolean;
 var
     li: TListItem;
     pd: Pointer;
     fp: Boolean; // Начато добавление процессов
     count, ii, nadd: Integer;
     selpid: DWORD;
     pinfo: PProcessInfo;
  Begin
   LView.Items.BeginUpdate;
   result := false;
   // Сохранение позиции выделеного элемента
   ii := LView.ItemIndex;
   selpid := 0;
   if (ii >= 0) and (LView.items [ii].Data <> nil) then
     begin
      ii := Integer (LView.items [ii].Data); // to index;
      selpid := prvpids.Items [ii];
     end;
   count := LView.Items.count;
   with LView do
   if (Count > Integer (ItemsCount))  then
     // Удаление лишних элементов с конца списка
     for ii := Count - 1 downto ItemsCount do items.Delete (ii);

   // Далее цикл заполнения списка процессами
   fp := false;
   lIndex := 0; // seek (0)
   nadd := 0;
   Repeat
    pd := ptr (lIndex); // указатель = индексъ
    pinfo := ReadItem;
    if pinfo = nil then break;
    // Тестирование системных процессов(?)
    if ((pinfo.pid < $20) or (pinfo.hwnd = 0)) and not fp then
         fp := TRUE;
     s := pinfo.title;
    with LView do
      begin
       // выборка элементов на замену или создание дополнительных
       if nadd >= items.count then li := Items.Add // Добавление элемента
                              else li := items [nadd];

       if bShowPID then
         li.Caption := Format ('[$%d] - ' + s, [pinfo.pid])
        else li.Caption := s;
       li.Data := pd;
       // выделение элемента бывшего выделенным до обновления
       if (selpid > 0) and (pinfo.pid = selpid) then
          begin
           li.Selected := TRUE;
           li.Focused := TRUE;
          end;
       // Получение индекса иконки процесса
       if (pinfo.icon > 0) then
            li.ImageIndex := pinfo.icon
       else li.ImageIndex := 0;
     result := TRUE; // Есть изменение
    end; // with lView
    Inc (nadd);
  Until FALSE;

  prvpids.Clear;
  for ii := 0 to ItemsCount - 1 do
   prvpids.AddPID ( witems [ii].pid ); // сохранить для использования в выделении
  LView.Items.EndUpdate;
End;
