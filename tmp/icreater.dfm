object FormX: TFormX
  Left = 186
  Top = 114
  Width = 311
  Height = 312
  Caption = #1057#1086#1079#1076#1072#1085#1080#1077' '#1080#1085#1089#1090#1072#1083#1103#1094#1080#1080
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object files: TListBox
    Left = 16
    Top = 48
    Width = 177
    Height = 201
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 0
  end
  object btnBrowse: TButton
    Left = 208
    Top = 16
    Width = 75
    Height = 25
    Caption = #1054#1073#1079#1086#1088
    TabOrder = 1
    OnClick = btnBrowseClick
  end
  object fpath: TEdit
    Left = 16
    Top = 16
    Width = 177
    Height = 21
    TabOrder = 2
  end
  object btnAdd: TButton
    Left = 208
    Top = 48
    Width = 75
    Height = 25
    Caption = #1044#1086#1073#1072#1074#1080#1090#1100
    TabOrder = 3
    OnClick = btnAddClick
  end
  object btnDel: TButton
    Left = 208
    Top = 80
    Width = 75
    Height = 25
    Caption = #1059#1076#1072#1083#1080#1090#1100
    TabOrder = 4
    OnClick = btnDelClick
  end
  object btnPack: TButton
    Left = 208
    Top = 192
    Width = 75
    Height = 25
    Caption = #1047#1072#1087#1072#1082#1086#1074#1072#1090#1100
    TabOrder = 5
    OnClick = btnPackClick
  end
  object btnExit: TButton
    Left = 208
    Top = 224
    Width = 75
    Height = 25
    Caption = #1042#1099#1093#1086#1076
    TabOrder = 6
    OnClick = btnExitClick
  end
  object sbar: TStatusBar
    Left = 0
    Top = 259
    Width = 303
    Height = 19
    Panels = <>
    SimplePanel = False
  end
  object odlg: TOpenDialog
    Filter = #1060#1072#1081#1083'|*.*'
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofEnableSizing]
    Left = 208
    Top = 112
  end
end
