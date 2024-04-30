object mform: Tmform
  Left = 227
  Top = 207
  Width = 559
  Height = 220
  Caption = #1048#1089#1087#1099#1090#1072#1090#1077#1083#1100#1085#1099#1081' '#1089#1090#1077#1085#1076
  Color = clBtnFace
  DefaultMonitor = dmMainForm
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object msgs: TListBox
    Left = 8
    Top = 8
    Width = 369
    Height = 177
    ItemHeight = 13
    TabOrder = 1
  end
  object btnClose: TButton
    Left = 472
    Top = 160
    Width = 75
    Height = 25
    Caption = #1042#1099#1093#1086#1076
    TabOrder = 2
    OnClick = btnCloseClick
  end
  object btnScanTest: TButton
    Left = 472
    Top = 8
    Width = 75
    Height = 25
    Caption = #1055#1086#1080#1089#1082
    TabOrder = 0
    OnClick = btnScanTestClick
  end
  object btnBreak: TButton
    Left = 472
    Top = 128
    Width = 75
    Height = 25
    Caption = #1055#1088#1077#1088#1074#1072#1090#1100
    TabOrder = 3
    OnClick = btnBreakClick
  end
end
