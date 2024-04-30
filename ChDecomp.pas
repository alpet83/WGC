unit ChDecomp;

interface
uses Windows, SysUtils, ChShare;

type
    tOpType = (_prefix, _command, _unknow);
    OperandCat = (_none, _register, _const, _mem, _ofst);
    TOperand = record
      OprI : byte; // ��� �������� ��� �� ����������  (L/H)  1
       Val : dword;    // Value if Offset/Constant present    4
       siz : byte;     // 8 or (16/32) bit default            1
     opcat : OperandCat; // �������, ���������, ������ ������ 1
    end;

    TOperation = record
     OpType : tOpType; // Operation Type
     OpIndex : word;   // Operation Index (AllNames)
      OComb : byte;    // ���������� ���������
     OpSize : Byte;   // Size of operation
     cnt : byte;   // ���������� ���������
     CurrPtr : dword;
    LimitPtr : dword;
     O1,O2,O3 : TOperand;
     sr : string; // ��������� �������
    end;
  TProc = procedure (const ofst : dword); pascal;

procedure     DisAsm (var buff : string);

var
   funcs : array [$00..$FF] of TProc; // ������ ������� ������������
   opc : TOperation; // � ��������� ���������

type
     tVectorX = array [1..255] of byte;
     pVectorX = ^tVectorX;
     str8 = array [0..7] of AnsiChar;
     str4 = array [0..3] of AnsiChar;
     TStrVec = array [00..$FF] of str8;
     PStrVec = ^TStrVec;
     TRegNames = array [0..7] of str4;   
     PRegNames = ^TRegNames;

implementation
uses ChForm, TlHelp32, Misk, ChCmd;


const
     RegNames08 : TRegNames =
       ('al', 'cl', 'dl', 'bl', 'ah', 'ch', 'dh', 'bh');
     RegNames16 : TRegNames =
       ('ax', 'cx', 'dx', 'bx', 'bp', 'sp', 'si', 'di');
     RegNames32 : TRegNames =
       ('eax', 'ecx', 'edx', 'ebx', 'ebp', 'esp', 'esi', 'edi');
     Types : array [1..4] of str8 =
         ('byte', 'word', '24bit', 'dword');

     OfsVariants32 : array [0..7] of str8 =
      ('[eax]','[ecx]','[edx]','[ebx]','[esp]','[ebp]','[esi]','[edi]');


     OpNames : array [0..124] of str8 =
      ('aaa',   'aad',   'aam',   'aas',   'adc', // 1
       'add',   'and',   'arpl',  'bound', 'bsf', // 2
       'bsr',   'bswap', 'bt',    'btc',   'btr', // 3
       'bts',   'call',  'cbw',   'cwde',  'clc', // 4
       'cld',   'cli',   'clts',  'cmc',   'cmp', // 5
       'cmps','cmpxchg','cmpxchg8','cmov', 'cpuid', // 6
       'cwd',   'cwq',   'daa',   'das',   'dec', // 7
       'das',   'dec',   'div',   'enter', 'hlt', // 8
       'idiv',  'imul',  'in',    'inc',   'ins', // 9
       'int',   'into',  'invd',  'invlpg','iret', // 10
       'jcc',   'jmp',   'lahf',  'lar',   'lds', // 11
       'les',   'lfs',   'lgs',   'lss',   'lea', // 12
       'leave', 'lgdt',  'lidt',  'lldt',  'lmsv',// 13
       'lock',  'lods',  'loop',  'loope', 'loopz', // 14
       'loopne','loopnz','lsl',   'ltr',   'mov',   // 15
       'movs',  'mul',   'neg',   'nop',   'not',   // 16
       'or',    'out',   'pop',   'popa',  'popf',  // 17
       'push',  'pusha', 'pushf', 'rcl',   'rcr',   // 18
       'rdmsr', 'rdpmc', 'rdtsc', 'rep',   'ret',   // 19
       'rol',   'ror',   'sahf',  'sal',   'sar',   // 20
       'sbb',   'scas',  'setcc', 'sgdt',  'shl',   // 21
       'shr',   'sidt',  'sldt',  'smsw',  'stc',   // 22
       'std',   'sti',   'stos',  'str',   'sub',   // 23
       'test',  'ud2',   'verr',  'verw',  'wait',  // 24
       'xadd',  'xchg',  'xlat',  'xor', 'unknow'); // 25


     { ��� �������������� ���� �������� �������
       ������������� ���������� ��������� OperandS1B }
      Handlers010 : array [0..7] of byte =
                  ($00, $01, $02, $03,
                   $08, $09, $0A, $0B);

   { ��� ��� ��������������� ������� ���� �������.
     ������� ���� ��������� ��� ������� �����,
     �������� 0 - ������������� �������� (OpName) }
      CmHash : array [0..11] of word =
       ($0005, $0005, $0005, $0005,  // 0..3
        $0005, $0005, $0053, $0058,
        $0050, $0050, $0050, $0050);

     invop : string = 'Invalid operation';

     // ������� ������
     allRegs : array [1..4] of PRegNames =
      (@RegNames08, @RegNames16, nil, @RegNames32);
     allNames : array [0..1] of PStrVec =
               (@OpNames, nil);

     { ���� ��������� (������� �����):
       ���� 012:
         ��� ��������

      ������� �����:
        ���� 01 - ���������� ����� ��������:
         00 - ����������
         01 - ������
         10 - ������
         11 - ������ (� ������� ���������� � ������ �� �����)

      ���� ��������:
         0 - mem, reg
         1 - reg, reg
         2 - mem, const
         3 - reg, const
     }



{   �������������� ��� ���� �����������:
  � ����������� � ��������� �����������.
    � ������ ������ ��������� ������������ �����
  ������ ���������� � �������, ������� ����� �����
  ������������ ����� ��� �������� �� ����������� �������,
  �������� ������������� ����������� ����� �� ���������
  ��������. ����� ��� ���������� ����� �������������� ���
  ����� � ���������� ����������� ������� � ���������
  ���������������� ����.
  
    �� ������ ������ ��������� - ��� ������:
     � ������ ���� ��������� ���� �������.
     �� ������ ������� ����������.
     � � ������ ��������.
    ��������� ������� ����� ������� ��� ������� �� �����.

 ���������� �� ������ ��������:
  ������ ��������� - ������������� ��� ������ ��������.
  ���������� ��������� - ��� �������� ��������.
  ���������� �������� ��������������
  ����������� UID.
  �������������� �������� ���� ��� ������������ � ��������.
  ��������� �� �������� ��������� ��������� (���� ���� ���������).
}

{ std code 00**xxxxxx
   in $00..$3F - add xxxx ptr [xxx], xxx
   in $40..$7F - add xxxx ptr [xxx + 00], xxx
   in $80..$BF - add xxxx ptr [xxx + 00000000], xxx
   in $C0..$FF - add xxx, xxx
 }

const
   COpSz : byte = 4;
   CAddr : byte = 4;

procedure   opfunc010 (const ofst : dword); pascal;
var vp : pvectorX absolute ofst;
    op1, op2 : byte;
    addx, scal, sib : byte;
    s0 : str8;
    scals, ts, s1, s2 : string;
    sibs, os : String;
    ofst2 : word;
    _mod : byte;
     siz : byte;
    rs : string;
begin
 addx := 0;
 s1 := ''; s2 := '';
 sibs := '';
 if vp^ [1] and 1 = 1 then siz := COpSz else siz := 1;
 op1 := vp^ [2];
 op2 := (op1 shr 3) and 7;
 op1 := (op1 and 7);
 ofst2 := CmHash [vp^ [1]]; // �������� �������
 s0 := AllNames [Hi (ofst2)]^[Lo (ofst2)]; // �������
 _mod := vp^ [2] shr 6; // ���� mod
 case _mod of
  $00, $01, $02 :
   Begin
   case op1 of
    $04: // ���� sib ������������
      begin
       sib := vp^ [3];
       scal := sib shr 6; // scale
       scals := ' * ' +  char (scal + $30);
       inc (addx);
       if scal = 1 then scals := ''; // ��� �����
       // �������� 32 � sib ��������
       if ((sib and 7) <> 5) or (_mod > 0) then
        sibs := RegNames32 [sib and 7] + scals + ' + ' +
                RegNames32 [(sib shr 3) and 7] else
        begin
         sibs := RegNames32 [(sib shr 3) and 7];
         os := dword2hex (pdword (@vp^[4 + addx])^); // ������� ���
        end; 
      end;
    $05: if _mod = 0 then
            os := dword2hex (pdword (@vp^[4 + addx])^)
         else s1 := 'ebp'#0; // ���� �������� ��� ebp
   end; // case op1
    if _mod = 1 then os := dword2hex (vp^ [4 + addx]); // 8-������ ��������
    if _mod = 2 then os := dword2hex (pdword (@vp^[4 + addx])^);
    if sibs <> '' then s1 := sibs
    else s1 := regNames32 [op1];
    if os <> '' then s1 := s1 + ' + ' + os;
    ts := types [siz]; // ... byte ptr/word ptr/dword ptr
    s1 := ts + ' ptr [' + s1 + ']';
    s2 := allRegs [siz]^[op2];
   End;
  $03 :;
 end;
 rs := s0;
 while (Length (rs) < 10) do rs := rs + ' ';

 if (vp^ [1] and 2) = 0 then rs := rs + s1 + ',' + s2
                        else rs := rs + s2 + ',' + s1;
 opc.sr := rs;
end;

function    decodeFirst (const ofst, lim : dword) : bool; stdcall;
var  v : pbyte absolute ofst;
begin
 funcs [v^] (ofst); // ������� ��������
 result := true;
end;

var
    v : array [0..255] of byte;

procedure  DisAsm;
begin
 v [0] := $08;
 v [1] := 1;
 DecodeFirst (dword (addr (v)), 255);
 buff := opc.sr;
end;

var x : byte;
begin
 for x := $00 to $FF do
   funcs [x] := @opfunc010;

end.
