object frmAddrs: TfrmAddrs
  Left = 380
  Top = 37
  Caption = #1053#1072#1081#1076#1077#1085#1099#1077' '#1072#1076#1088#1077#1089#1072
  ClientHeight = 362
  ClientWidth = 626
  Color = clBtnFace
  Constraints.MinHeight = 360
  Constraints.MinWidth = 632
  DragKind = dkDock
  DragMode = dmAutomatic
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnEndDock = FormEndDock
  DesignSize = (
    626
    362)
  PixelsPerInch = 96
  TextHeight = 13
  object lbActiveGroup: TLabel
    Left = 8
    Top = 239
    Width = 88
    Height = 13
    Anchors = [akLeft, akBottom]
    Caption = #1040#1082#1090#1080#1074#1085#1072#1103' '#1075#1088#1091#1087#1087#1072':'
  end
  object sgCheat: TStringGrid
    Left = 0
    Top = 3
    Width = 621
    Height = 224
    Anchors = [akLeft, akTop, akRight, akBottom]
    ColCount = 8
    Ctl3D = True
    DefaultRowHeight = 17
    FixedCols = 0
    RowCount = 255
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = 14
    Font.Name = 'Courier New'
    Font.Pitch = fpFixed
    Font.Style = []
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goColSizing, goEditing, goThumbTracking]
    ParentCtl3D = False
    ParentFont = False
    TabOrder = 0
    OnMouseDown = sgCheatMouseDown
    OnMouseMove = sgCheatMouseMove
    OnMouseUp = sgCheatMouseUp
    OnSetEditText = sgCheatSetEditText
    ColWidths = (
      49
      130
      97
      88
      86
      49
      75
      19)
  end
  object pnBtns: TPanel
    Left = 5
    Top = 263
    Width = 617
    Height = 82
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 1
    object lTableFntSz: TLabel
      Left = 446
      Top = 20
      Width = 81
      Height = 13
      Caption = #1056#1072#1079#1084#1077#1088' '#1096#1088#1080#1092#1090#1072
    end
    object btnCheat: TButton
      Left = 24
      Top = 8
      Width = 92
      Height = 30
      Hint = #1055#1077#1088#1077#1079#1072#1087#1080#1089#1100' '#1079#1085#1072#1095#1077#1085#1080#1081
      Caption = '&Cheat'
      TabOrder = 0
      OnClick = btnCheatClick
    end
    object btnLock: TButton
      Left = 24
      Top = 39
      Width = 92
      Height = 31
      Hint = #1047#1072#1084#1086#1088#1086#1079#1082#1072' '#1079#1085#1072#1095#1077#1085#1080#1081
      Caption = 'Lock'
      TabOrder = 1
      OnClick = btnLockClick
    end
    object btnSave: TButton
      Left = 132
      Top = 8
      Width = 93
      Height = 30
      Caption = '&'#1057#1086#1093#1088#1072#1085#1080#1090#1100
      TabOrder = 2
      OnClick = btnSaveClick
    end
    object btnLoad: TButton
      Left = 132
      Top = 39
      Width = 93
      Height = 31
      Caption = '&'#1047#1072#1075#1088#1091#1079#1080#1090#1100
      TabOrder = 3
      OnClick = btnLoadClick
    end
    object btnClear: TButton
      Left = 233
      Top = 8
      Width = 99
      Height = 30
      Caption = '&'#1054#1095#1080#1089#1090#1080#1090#1100
      TabOrder = 4
      OnClick = btnClearClick
    end
    object btnToDbg: TButton
      Left = 233
      Top = 39
      Width = 99
      Height = 31
      Hint = #1055#1077#1088#1077#1076#1072#1077#1090' '#1079#1085#1072#1095#1077#1085#1080#1077' '#1074' '#1086#1090#1083#1072#1076#1095#1080#1082
      Caption = '> '#1054#1090#1083#1072#1076#1095#1080#1082
      TabOrder = 5
    end
    object btnmem: TButton
      Left = 346
      Top = 8
      Width = 90
      Height = 30
      Caption = '&'#1055#1072#1084#1103#1090#1100
      TabOrder = 6
      OnClick = btnmemClick
    end
    object btnVAdd: TButton
      Left = 535
      Top = 9
      Width = 21
      Height = 17
      Caption = '+'
      TabOrder = 7
      OnClick = btnVAddClick
    end
    object btnVSub: TButton
      Left = 535
      Top = 27
      Width = 21
      Height = 17
      Caption = '-'
      TabOrder = 8
      OnClick = btnVSubClick
    end
    object cbFilter: TCheckBox
      Left = 446
      Top = 45
      Width = 113
      Height = 17
      Hint = #1040#1074#1090#1086#1084#1072#1090#1080#1095#1077#1089#1082#1086#1077' '#1080#1079#1073#1072#1074#1083#1077#1085#1080#1077' '#1086#1090' '#1085#1077#1087#1088#1072#1074#1080#1083#1100#1085#1099#1093' '#1091#1082#1072#1079#1072#1090#1077#1083#1077#1081
      Caption = '&'#1060#1080#1083#1100#1090#1088#1072#1094#1080#1103
      TabOrder = 9
    end
    object btnTrainer: TButton
      Left = 346
      Top = 39
      Width = 90
      Height = 30
      Hint = #1055#1086#1082#1072#1079#1072#1090#1100' '#1082#1086#1085#1089#1090#1088#1091#1082#1090#1086#1088' '#1090#1088#1077#1081#1085#1077#1088#1086#1074
      Caption = '&'#1058#1088#1077#1081#1085#1077#1088
      TabOrder = 10
    end
  end
  object cbGroup: TComboBox
    Left = 104
    Top = 234
    Width = 153
    Height = 21
    Anchors = [akLeft, akBottom]
    ItemHeight = 13
    ItemIndex = 0
    TabOrder = 2
    Text = 'All'
    OnSelect = cbGroupSelect
    Items.Strings = (
      'All'
      'Default')
  end
  object btnAddGroup: TButton
    Left = 264
    Top = 232
    Width = 73
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1044#1086#1073#1072#1074#1080#1090#1100
    TabOrder = 3
    OnClick = btnAddGroupClick
  end
  object btnDeleteGroup: TButton
    Left = 344
    Top = 232
    Width = 73
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1059#1076#1072#1083#1080#1090#1100
    TabOrder = 4
    OnClick = btnDeleteGroupClick
  end
  object pmDescriptions: TPopupMenu
    AutoHotkeys = maManual
    Left = 456
    Top = 482
    object mi_descMoney: TMenuItem
      Caption = #1044#1077#1085#1100#1075#1080
      OnClick = miValuePasteClick
    end
    object mi_descLife: TMenuItem
      Caption = #1046#1080#1079#1085#1100
      OnClick = miValuePasteClick
    end
    object mi_descHealth: TMenuItem
      Caption = #1047#1076#1086#1088#1086#1074#1100#1077
      OnClick = miValuePasteClick
    end
    object mi_descSome: TMenuItem
      Caption = #1055#1088#1077#1076#1084#1077#1090#1099
      OnClick = miValuePasteClick
    end
    object mi_descPower: TMenuItem
      Caption = #1069#1085#1077#1088#1075#1080#1103
      OnClick = miValuePasteClick
    end
    object mi_descTime: TMenuItem
      Caption = #1042#1088#1077#1084#1103
      OnClick = miValuePasteClick
    end
    object mi_descBPS: TMenuItem
      Caption = #1041#1086#1077#1087#1088#1080#1087#1072#1089#1099
      object mi_descPistons: TMenuItem
        Caption = #1055#1072#1090#1088#1086#1085#1099
        OnClick = miValuePasteClick
      end
      object mi_descGranati: TMenuItem
        Caption = #1043#1088#1072#1085#1072#1090#1099
        OnClick = miValuePasteClick
      end
      object mi_descArrows: TMenuItem
        Caption = #1057#1090#1088#1077#1083#1099
        OnClick = miValuePasteClick
      end
      object mi_descDynamite: TMenuItem
        Caption = #1044#1080#1085#1072#1084#1080#1090
        OnClick = miValuePasteClick
      end
    end
    object mi_descRes: TMenuItem
      Caption = #1056#1077#1089#1091#1088#1089#1099
      object mi_descTree: TMenuItem
        Caption = #1051#1077#1089
        OnClick = miValuePasteClick
      end
      object mi_descGold: TMenuItem
        Caption = #1047#1086#1083#1086#1090#1086
        OnClick = miValuePasteClick
      end
      object mi_descMinerals: TMenuItem
        Caption = #1050#1088#1080#1089#1090#1072#1083#1083#1099
        OnClick = miValuePasteClick
      end
      object mi_descGas: TMenuItem
        Caption = #1043#1072#1079
        OnClick = miValuePasteClick
      end
      object mi_descSpace: TMenuItem
        Caption = #1057#1087#1072#1081#1089
        OnClick = miValuePasteClick
      end
      object mi_descOil: TMenuItem
        Caption = #1053#1077#1092#1090#1100
      end
    end
  end
  object pmChTable: TPopupMenu
    Left = 563
    Top = 380
    object miKillRow: TMenuItem
      Caption = #1059#1076#1072#1083#1080#1090#1100' '#1089#1090#1088#1086#1082#1091
      OnClick = miKillRowClick
    end
    object miKillAll: TMenuItem
      Caption = #1054#1095#1080#1089#1090#1080#1090#1100' '#1074#1089#1077
      OnClick = btnClearClick
    end
  end
  object pmValues: TPopupMenu
    AutoHotkeys = maManual
    Left = 443
    Top = 475
    object mi1h: TMenuItem
      Caption = '100'
      OnClick = miValuePasteClick
    end
    object mi1t: TMenuItem
      Caption = '1000'
      OnClick = miValuePasteClick
    end
    object mi10t: TMenuItem
      Caption = '10000'
      OnClick = miValuePasteClick
    end
    object mi100t: TMenuItem
      Caption = '100000'
      OnClick = miValuePasteClick
    end
    object mi1m: TMenuItem
      Caption = '1000000'
      OnClick = miValuePasteClick
    end
    object miCustom: TMenuItem
      Caption = 'Custom'
      OnClick = miValuePasteClick
    end
    object mi_move2group: TMenuItem
      Caption = #1055#1077#1088#1077#1084#1077#1089#1090#1080#1090#1100' '#1074' '#1075#1088#1091#1087#1087#1091
      object miDefaultGroup: TMenuItem
        Caption = 'Default'
        OnClick = miDefaultGroupClick
      end
    end
    object mi_DelStrings: TMenuItem
      Caption = #1059#1076#1072#1083#1080#1090#1100' '#1089#1090#1088#1086#1082#1080
    end
  end
  object pmTypes: TPopupMenu
    Left = 411
    Top = 657
    object mi_TypeByte: TMenuItem
      AutoHotkeys = maManual
      AutoLineReduction = maManual
      Caption = 'BYTE'
      OnClick = OnTypeItem
    end
    object mi_TypeWord: TMenuItem
      Caption = 'WORD'
      OnClick = OnTypeItem
    end
    object mi_TypeDword: TMenuItem
      Caption = 'DWORD'
      OnClick = OnTypeItem
    end
    object miHex: TMenuItem
      Caption = 'HEX'
      RadioItem = True
      OnClick = OnTypeItem
    end
    object mi_TypeAnsiStr: TMenuItem
      Caption = 'TEXT'
      OnClick = OnTypeItem
    end
    object mi_TypeWideStr: TMenuItem
      Caption = 'WIDE'
      OnClick = OnTypeItem
    end
    object mi_TypeReal48: TMenuItem
      Caption = 'REAL'
      OnClick = OnTypeItem
    end
    object mi_TypeSingle: TMenuItem
      Caption = 'SINGLE'
      OnClick = OnTypeItem
    end
    object mi_TypeDouble: TMenuItem
      Caption = 'DOUBLE'
      OnClick = OnTypeItem
    end
    object mi_TypeExtended: TMenuItem
      Caption = 'EXTENDED'
      OnClick = OnTypeItem
    end
  end
end
