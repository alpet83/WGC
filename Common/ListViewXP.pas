unit ListViewXP;

interface
uses Windows, SysUtils, Types, ComCtrls;


type
   TLVGroup = packed record
    cbSize: Dword;
      mask: Dword;
    pszHeader: PWideChar;
    cchHeader: Integer;
    pszFooter: PWideChar;
    cchFooter: Integer;
     iGroupId: Integer;
    stateMask: Dword;
        state: Dword;
       uAlign: Dword;
   end; // TLVGroup

 LVITEMXP = packed record
    mask: UINT;
    iItem: Integer;
    iSubItem: Integer;
    state: UINT;
    stateMask: UINT;
    pszText: PWideChar;
    cchTextMax: Integer;
    iImage: Integer;
    lParam: LPARAM;
    iIndent: Integer;
    iGroupId: Integer;
    cColumns: DWORD;
    puColumns: PDword;
  end;

const
     // messages
     LVM_FIRST = $1000;
     LVM_INSERTGROUP = LVM_FIRST + 145;
     LVM_ENABLEGROUPVIEW  = LVM_FIRST + 157;

     LVIF_GROUPID = $100;
     LVIF_COLUMNS = $200;


     LVGF_HEADER = 1;
     LVGF_FOOTER         = $02;
     LVGF_STATE          = $04;
     LVGF_ALIGN          = $08;
     LVGF_GROUPID        = $10;
     LVGS_NORMAL         = $00;
     LVGS_COLLAPSED      = $01;
     LVGS_HIDDEN         = $02;
     LVGA_HEADER_LEFT    = $01;
     LVGA_HEADER_CENTER  = $02;
     LVGA_HEADER_RIGHT   = $04;  // Don't forget to validate exclusivity
     LVGA_FOOTER_LEFT    = $08;
     LVGA_FOOTER_CENTER  = $10;
     LVGA_FOOTER_RIGHT   = $20;  //


function InsertGroup (wnd: THandle; nGroup: Integer;
                        hdr, footer: WideString): Integer;
function SetItemGroup (wnd: THandle; nItem, nGroup: Integer): Boolean;
function SetGroupView (wnd: THandle; bEnable: Boolean = true): Boolean;

implementation
uses CommCtrl;

function InsertGroup;
var
   lg: TLVGroup;
begin
 FillChar (lg, sizeof (lg), 0);
 lg.cbSize := sizeof (lg);
 lg.pszHeader := PWideChar (hdr);
 lg.cchHeader := Length (hdr);
 lg.pszFooter := PWideChar (footer);
 lg.cchFooter := Length (footer);
 lg.iGroupId := nGroup;
 lg.state := LVGF_HEADER or LVGF_FOOTER;
 result := SendMessage (wnd,
                        LVM_INSERTGROUP, 0, dword (@lg));
end; // InsertGroup
                    
function SetGroupView;
begin
 result := SendMessage (wnd,
                LVM_ENABLEGROUPVIEW, Integer (bEnable), 0) <> -1;
end; // SetGroupView

function SetItemGroup;
var item: LVItemXP;
begin
 FillChar (item, sizeof (item), 0);
 item.mask := LVIF_GROUPID;
 item.iItem := nItem;
 item.iGroupId := nGroup;
 result := SendMessage (wnd, LVM_SETITEM, 0, Longint(@item)) <> 0;
end; // SetItemGroup

end.
