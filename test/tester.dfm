object FormX: TFormX
  Left = 652
  Top = 111
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsDialog
  Caption = 'Tester'
  ClientHeight = 338
  ClientWidth = 530
  Color = clBtnFace
  Constraints.MaxHeight = 500
  Constraints.MaxWidth = 640
  Constraints.MinHeight = 200
  Constraints.MinWidth = 300
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Scaled = False
  ShowHint = True
  Visible = True
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  DesignSize = (
    530
    338)
  PixelsPerInch = 96
  TextHeight = 13
  object lOffset: TLabel
    Left = 288
    Top = 192
    Width = 118
    Height = 13
    Caption = 'Brush Offset: $00000000'
  end
  object ltext: TLabel
    Left = 300
    Top = 230
    Width = 3
    Height = 13
  end
  object lwtext: TLabel
    Left = 300
    Top = 270
    Width = 3
    Height = 13
  end
  object lbptr: TLabel
    Left = 208
    Top = 312
    Width = 3
    Height = 13
  end
  object btnClose: TButton
    Left = 432
    Top = 312
    Width = 97
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = '&Close'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Pitch = fpFixed
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    OnClick = btnCloseClick
  end
  object btnAdd: TButton
    Left = 136
    Top = 144
    Width = 25
    Height = 25
    Caption = '+'
    TabOrder = 1
    OnClick = btnAddClick
  end
  object BtnSub: TButton
    Left = 160
    Top = 144
    Width = 25
    Height = 25
    Caption = '-'
    TabOrder = 2
    OnClick = BtnSubClick
  end
  object edSize: TEdit
    Left = 8
    Top = 200
    Width = 41
    Height = 21
    Hint = #1056#1072#1079#1084#1077#1088' '#1076#1072#1085#1085#1099#1093' '#1074' '#1084#1077#1075#1072#1073#1072#1081#1090#1072#1093
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
    Text = '128'
  end
  object btnSetSize: TButton
    Left = 56
    Top = 200
    Width = 50
    Height = 25
    Hint = #1048#1079#1084#1077#1085#1077#1085#1080#1077' '#1088#1072#1079#1084#1077#1088#1072' '#1076#1072#1085#1085#1099#1093
    Caption = '&Realloc'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 4
    OnClick = btnSetSizeClick
  end
  object Table: TStringGrid
    Left = 8
    Top = 8
    Width = 513
    Height = 129
    Anchors = [akLeft, akTop, akRight]
    ColCount = 4
    DefaultRowHeight = 16
    FixedCols = 0
    RowCount = 9
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clDefault
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Options = [goFixedVertLine, goVertLine, goHorzLine, goRangeSelect]
    ParentFont = False
    TabOrder = 5
    OnSelectCell = TableSelectCell
    ColWidths = (
      44
      126
      167
      151)
  end
  object cbStay: TCheckBox
    Left = 424
    Top = 144
    Width = 97
    Height = 17
    Caption = 'Stay on top'
    TabOrder = 6
    OnClick = cbStayClick
  end
  object edText: TEdit
    Left = 7
    Top = 144
    Width = 122
    Height = 21
    Hint = 'Example'
    TabOrder = 7
    Text = '12345678'
  end
  object edCount: TEdit
    Left = 208
    Top = 144
    Width = 57
    Height = 21
    Hint = 'Count'
    TabOrder = 8
    Text = '1'
  end
  object btnWrite: TButton
    Left = 136
    Top = 200
    Width = 129
    Height = 25
    Caption = 'Write'
    TabOrder = 9
    OnClick = btnWriteClick
  end
  object edAddr: TEdit
    Left = 8
    Top = 168
    Width = 97
    Height = 21
    Hint = 'Address'
    TabOrder = 10
    Text = '$AC0000'
  end
  object cbType: TComboBox
    Left = 136
    Top = 176
    Width = 129
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 11
  end
  object cbDTLBpref: TCheckBox
    Left = 288
    Top = 208
    Width = 97
    Height = 17
    Caption = 'DTLB prefetch'
    TabOrder = 12
  end
  object msgs: TMemo
    Left = 8
    Top = 232
    Width = 385
    Height = 97
    Lines.Strings = (
      'Test Messages:')
    ScrollBars = ssVertical
    TabOrder = 13
  end
  object T1: TTimer
    Interval = 10
    OnTimer = T1Timer
    Left = 336
    Top = 144
  end
end
