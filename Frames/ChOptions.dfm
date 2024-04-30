object frmOptions: TfrmOptions
  Left = 1153
  Top = -21
  ClientHeight = 306
  ClientWidth = 620
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Scaled = False
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object tvOptTree: TTreeView
    Left = 8
    Top = 8
    Width = 217
    Height = 259
    Indent = 19
    ReadOnly = True
    RightClickSelect = True
    TabOrder = 0
    OnClick = tvOptTreeClick
  end
  object pnFrame: TPanel
    Left = 232
    Top = 9
    Width = 380
    Height = 257
    BevelInner = bvRaised
    BevelOuter = bvLowered
    TabOrder = 1
    DesignSize = (
      380
      257)
    object pctrlOptions: TPageControl
      Left = 4
      Top = 5
      Width = 373
      Height = 247
      ActivePage = tsOptions_scaner
      Anchors = [akLeft, akTop, akBottom]
      RaggedRight = True
      Style = tsButtons
      TabOrder = 0
      object tsOptions_scaner: TTabSheet
        Caption = #1057#1082#1072#1085#1077#1088
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 0
        ExplicitHeight = 0
        object gbScanBuffer: TGroupBox
          Left = 8
          Top = 8
          Width = 321
          Height = 65
          Caption = #1041#1091#1092#1077#1088' '#1076#1083#1103' '#1089#1082#1072#1085#1080#1088#1086#1074#1072#1085#1080#1103
          TabOrder = 0
          object lbBuffSize: TLabel
            Left = 16
            Top = 32
            Width = 66
            Height = 13
            Caption = #1056#1072#1079#1084#1077#1088' '#1074' '#1082#1073':'
          end
          object edBuffSz: TEdit
            Left = 128
            Top = 25
            Width = 73
            Height = 21
            Hint = #1056#1072#1079#1084#1077#1088' '#1073#1091#1092#1092#1077#1088#1072' '#1074' '#1050#1080#1083#1086#1073#1072#1081#1090#1072#1093
            TabOrder = 0
            Text = '56'
          end
          object btnSetBuffSz: TButton
            Left = 213
            Top = 18
            Width = 92
            Height = 31
            Caption = #1048#1079#1084#1077#1085#1080#1090#1100
            TabOrder = 1
            OnClick = btnSetBuffSzClick
          end
        end
        object gbOptimization: TGroupBox
          Left = 8
          Top = 80
          Width = 321
          Height = 105
          Caption = 'Optimization'
          TabOrder = 1
          object lPriority: TLabel
            Left = 16
            Top = 31
            Width = 117
            Height = 13
            Caption = #1055#1088#1080#1086#1088#1080#1090#1077#1090' '#1087#1088#1080' '#1087#1086#1080#1089#1082#1077':'
          end
          object cbPriority: TComboBox
            Left = 16
            Top = 23
            Width = 208
            Height = 21
            Style = csDropDownList
            ItemHeight = 13
            ItemIndex = 1
            TabOrder = 0
            Text = 'HIGHEST'
            OnChange = cbPriorityChange
            Items.Strings = (
              'NORMAL'
              'HIGHEST'
              'TIMECRITICAL')
          end
          object cbTimerX: TCheckBox
            Left = 16
            Top = 54
            Width = 113
            Height = 17
            Caption = 'Timer Enable'
            Checked = True
            State = cbChecked
            TabOrder = 1
            OnClick = cbTimerXClick
          end
          object cbFreezze: TCheckBox
            Left = 136
            Top = 54
            Width = 105
            Height = 17
            Hint = #1054#1089#1090#1072#1085#1086#1074' '#1087#1088#1086#1094#1077#1089#1089#1072' '#1087#1088#1080' '#1074#1099#1074#1086#1076#1077' '#1082#1086#1085#1089#1086#1083#1080
            Caption = 'Stop on show'
            Checked = True
            ParentShowHint = False
            ShowHint = True
            State = cbChecked
            TabOrder = 2
            OnClick = cbFreezzeClick
          end
          object cbUIupdate: TCheckBox
            Left = 18
            Top = 78
            Width = 97
            Height = 17
            Hint = 
              #1054#1073#1085#1086#1074#1083#1077#1085#1080#1077' '#1096#1082#1072#1083#1099' '#1074#1086' '#1074#1088#1077#1084#1103' '#1087#1086#1080#1089#1082#1072'. '#1057#1085#1103#1090#1080#1077' '#1092#1083#1072#1078#1082#1072' '#1084#1086#1078#1077#1090' '#1085#1077#1084#1085#1086#1075#1086' '#1091#1074 +
              #1077#1083#1080#1095#1080#1090#1100' '#1089#1082#1086#1088#1086#1089#1090#1100' '#1087#1086#1080#1089#1082#1072'.'
            Caption = 'UI Update'
            ParentShowHint = False
            ShowHint = True
            TabOrder = 3
            OnClick = cbUIupdateClick
          end
          object cbIdleRead: TCheckBox
            Left = 136
            Top = 78
            Width = 97
            Height = 17
            Hint = 
              #1063#1090#1077#1085#1080#1077' '#1087#1072#1084#1103#1090#1080' '#1087#1088#1086#1094#1077#1089#1089#1072' '#1074' '#1093#1086#1083#1086#1089#1090#1091#1102'. '#1053#1077' '#1087#1086#1079#1074#1086#1083#1103#1077#1090' '#1080#1075#1088#1077' '#1083#1077#1095#1100' '#1074' Swap' +
              '. '#1055#1088#1080' '#1084#1072#1083#1086#1084' '#1082#1086#1083#1080#1095#1077#1089#1090#1074#1077' '#1087#1072#1084#1103#1090#1080' '#1083#1091#1095#1096#1077' '#1101#1090#1091' '#1086#1087#1094#1080#1102' '#1086#1090#1082#1083#1102#1095#1080#1090#1100'.'
            Caption = 'Idle Read'
            Checked = True
            ParentShowHint = False
            ShowHint = True
            State = cbChecked
            TabOrder = 4
          end
        end
      end
      object tsOptions_interface: TTabSheet
        Caption = #1048#1085#1090#1077#1088#1092#1077#1081#1089
        ImageIndex = 1
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 0
        ExplicitHeight = 0
        object gbConsole: TGroupBox
          Left = 8
          Top = 112
          Width = 329
          Height = 113
          Caption = #1050#1086#1085#1089#1086#1083#1100
          TabOrder = 0
          object lbTransparency: TLabel
            Left = 16
            Top = 80
            Width = 75
            Height = 13
            Caption = #1055#1088#1086#1079#1088#1072#1095#1085#1086#1089#1090#1100':'
          end
          object cbConsole: TCheckBox
            Left = 16
            Top = 24
            Width = 129
            Height = 17
            Hint = #1042#1099#1074#1086#1076' '#1086#1082#1085#1072' '#1091#1087#1088#1072#1074#1083#1077#1085#1080#1103' '#1074' '#1080#1075#1088#1077', '#1087#1086' '#1085#1072#1078#1072#1090#1080#1102' '#1075#1086#1088#1103#1095#1077#1081' '#1082#1083#1072#1074#1080#1096#1080
            Caption = 'Console Enabled'
            Checked = True
            ParentShowHint = False
            ShowHint = True
            State = cbChecked
            TabOrder = 0
          end
          object tbTransp: TTrackBar
            Left = 128
            Top = 76
            Width = 182
            Height = 25
            Hint = #1056#1077#1075#1091#1083#1080#1088#1086#1074#1072#1085#1080#1077' '#1091#1088#1086#1074#1085#1103' '#1087#1088#1086#1079#1088#1072#1095#1085#1086#1089#1090#1080' '#1082#1086#1085#1089#1086#1083#1080'. '#1041#1086#1083#1100#1096#1077' - '#1087#1088#1086#1079#1088#1072#1095#1085#1077#1077'.'
            Max = 16
            ParentShowHint = False
            Position = 8
            ShowHint = True
            TabOrder = 1
          end
          object cbInputCapture: TCheckBox
            Left = 16
            Top = 48
            Width = 153
            Height = 17
            Caption = #1055#1077#1088#1077#1093#1074#1072#1090' '#1074#1074#1086#1076#1072
            TabOrder = 2
          end
        end
        object gbTab2View: TGroupBox
          Left = 8
          Top = 8
          Width = 329
          Height = 81
          Caption = #1042#1082#1083#1072#1076#1082#1072' '#1087#1086#1080#1089#1082#1072
          TabOrder = 1
          object cbQueryList: TCheckBox
            Left = 8
            Top = 20
            Width = 137
            Height = 25
            Hint = #1054#1090#1086#1073#1088#1072#1078#1077#1085#1080#1077' '#1089#1087#1080#1089#1082#1072' '#1079#1072#1087#1088#1086#1089#1086#1074' '#1085#1072' '#1074#1082#1083#1072#1076#1082#1077' '#1087#1086#1080#1089#1082#1072
            Caption = #1057#1087#1080#1089#1086#1082' '#1079#1072#1087#1088#1086#1089#1086#1074
            TabOrder = 0
            OnClick = cbQueryListClick
          end
          object cbRuleBtns: TCheckBox
            Left = 8
            Top = 48
            Width = 193
            Height = 17
            Caption = #1050#1085#1086#1087#1082#1080' '#1087#1088#1072#1074#1080#1083' '#1087#1086#1080#1089#1082#1072
            TabOrder = 1
            OnClick = cbRuleBtnsClick
          end
        end
      end
      object tsOptions_hotkeys: TTabSheet
        Caption = #1043#1086#1088#1103#1095#1080#1077' '#1082#1083#1072#1074#1080#1096#1080
        ImageIndex = 2
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 0
        ExplicitHeight = 0
        object lbHotKeys: TLabel
          Left = 28
          Top = 8
          Width = 150
          Height = 13
          Caption = #1043#1086#1088#1103#1095#1080#1077' '#1082#1083#1072#1074#1080#1096#1080' '#1087#1088#1086#1075#1088#1072#1084#1084#1099
        end
        object edHotKey: TEdit
          Left = 24
          Top = 205
          Width = 225
          Height = 21
          Color = clBtnFace
          ReadOnly = True
          TabOrder = 0
          OnKeyDown = edHotKeyKeyDown
        end
        object lbxHotKeys: TListBox
          Left = 24
          Top = 27
          Width = 225
          Height = 169
          ItemHeight = 13
          TabOrder = 1
          OnClick = lbxHotKeysClick
        end
      end
      object tsOptions_popup: TTabSheet
        Caption = #1042#1089#1087#1083#1099#1090#1080#1077
        ImageIndex = 3
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 0
        ExplicitHeight = 0
        object gbResolution: TGroupBox
          Left = 8
          Top = 16
          Width = 345
          Height = 89
          Caption = #1056#1072#1079#1088#1077#1096#1077#1085#1080#1077
          TabOrder = 0
          object lClr: TLabel
            Left = 154
            Top = 55
            Width = 21
            Height = 13
            Caption = 'BPP'
          end
          object lFreq: TLabel
            Left = 245
            Top = 56
            Width = 13
            Height = 13
            Caption = 'Hz'
          end
          object cbResres: TCheckBox
            Left = 10
            Top = 23
            Width = 191
            Height = 17
            Hint = #1042#1086#1089#1089#1090#1072#1085#1072#1074#1083#1080#1074#1072#1090#1100' '#1088#1072#1079#1088#1077#1096#1077#1085#1080#1077' '#1087#1088#1080' '#1074#1089#1087#1083#1099#1090#1080#1080' '#1087#1086' Ctrl-Alt-PgUp'
            Caption = #1042#1086#1089#1089#1090#1072#1085#1086#1074' '#1088#1072#1079#1088#1077#1096#1077#1085#1080#1103
            ParentShowHint = False
            ShowHint = True
            TabOrder = 0
          end
          object cbScrRes: TComboBox
            Left = 10
            Top = 48
            Width = 91
            Height = 21
            Style = csDropDownList
            ItemHeight = 13
            ItemIndex = 3
            TabOrder = 1
            Text = '1024x768'
            Items.Strings = (
              '640x480'
              '720x480'
              '800x600'
              '1024x768'
              '1280x1024')
          end
          object cbScrBPP: TComboBox
            Left = 108
            Top = 48
            Width = 41
            Height = 21
            Style = csDropDownList
            ItemHeight = 13
            ItemIndex = 4
            TabOrder = 2
            Text = '32'
            Items.Strings = (
              '4'
              '8'
              '16'
              '24'
              '32')
          end
          object cbScrFreq: TComboBox
            Left = 186
            Top = 48
            Width = 51
            Height = 21
            Style = csDropDownList
            ItemHeight = 13
            ItemIndex = 2
            TabOrder = 3
            Text = '85'
            Items.Strings = (
              '60'
              '75'
              '85'
              '90'
              '100'
              '120')
          end
          object btnResTest: TButton
            Left = 274
            Top = 47
            Width = 55
            Height = 25
            Caption = #1058#1077#1089#1090
            TabOrder = 4
            OnClick = btnResTestClick
          end
        end
      end
    end
  end
  object btnClose: TButton
    Left = 536
    Top = 272
    Width = 75
    Height = 25
    Caption = #1047#1072#1082#1088#1099#1090#1100
    TabOrder = 2
    OnClick = btnCloseClick
  end
end
