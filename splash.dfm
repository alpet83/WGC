object frmSplash: TfrmSplash
  Left = 540
  Top = 160
  BorderStyle = bsDialog
  Caption = 'WGC - '#1089#1086#1077#1076#1080#1085#1077#1085#1080#1077' c '#1089#1077#1088#1074#1077#1088#1086#1084'...'
  ClientHeight = 104
  ClientWidth = 383
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Visible = True
  PixelsPerInch = 96
  TextHeight = 13
  object pnDock: TPanel
    Left = 8
    Top = 8
    Width = 369
    Height = 89
    BevelInner = bvRaised
    BevelOuter = bvLowered
    TabOrder = 0
    object lbMessage: TLabel
      Left = 16
      Top = 56
      Width = 248
      Height = 13
      Caption = #1055#1086#1078#1072#1081#1083#1091#1089#1090#1072' '#1076#1086#1078#1076#1080#1090#1077#1089#1100' '#1089#1086#1077#1076#1080#1085#1077#1085#1080#1103' '#1089' '#1089#1077#1088#1074#1077#1088#1086#1084'.'
    end
    object btnBreak: TButton
      Left = 278
      Top = 51
      Width = 75
      Height = 25
      Caption = #1055#1088#1077#1088#1074#1072#1090#1100
      TabOrder = 0
      OnClick = btnBreakClick
    end
    object pgBar: TProgressBar
      Left = 16
      Top = 16
      Width = 337
      Height = 16
      Min = 0
      Max = 100
      Position = 5
      TabOrder = 1
    end
  end
  object uTimer: TTimer
    Interval = 50
    OnTimer = uTimerTimer
    Left = 256
    Top = 40
  end
end
