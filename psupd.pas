function _updPrcsList: boolean;
 var
     li: TListItem;
     pd: Pointer;
     fp: Boolean; // ������ ���������� ���������
     count, ii, nadd: Integer;
     selpid: DWORD;
     pinfo: PProcessInfo;
  Begin
   LView.Items.BeginUpdate;
   result := false;
   // ���������� ������� ���������� ��������
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
     // �������� ������ ��������� � ����� ������
     for ii := Count - 1 downto ItemsCount do items.Delete (ii);

   // ����� ���� ���������� ������ ����������
   fp := false;
   lIndex := 0; // seek (0)
   nadd := 0;
   Repeat
    pd := ptr (lIndex); // ��������� = �������
    pinfo := ReadItem;
    if pinfo = nil then break;
    // ������������ ��������� ���������(?)
    if ((pinfo.pid < $20) or (pinfo.hwnd = 0)) and not fp then
         fp := TRUE;
     s := pinfo.title;
    with LView do
      begin
       // ������� ��������� �� ������ ��� �������� ��������������
       if nadd >= items.count then li := Items.Add // ���������� ��������
                              else li := items [nadd];

       if bShowPID then
         li.Caption := Format ('[$%d] - ' + s, [pinfo.pid])
        else li.Caption := s;
       li.Data := pd;
       // ��������� �������� ������� ���������� �� ����������
       if (selpid > 0) and (pinfo.pid = selpid) then
          begin
           li.Selected := TRUE;
           li.Focused := TRUE;
          end;
       // ��������� ������� ������ ��������
       if (pinfo.icon > 0) then
            li.ImageIndex := pinfo.icon
       else li.ImageIndex := 0;
     result := TRUE; // ���� ���������
    end; // with lView
    Inc (nadd);
  Until FALSE;

  prvpids.Clear;
  for ii := 0 to ItemsCount - 1 do
   prvpids.AddPID ( witems [ii].pid ); // ��������� ��� ������������� � ���������
  LView.Items.EndUpdate;
End;
