; ������� ����������
extrn                   pascal cmpOP:WORD               ; �������� ���������
extrn                   pascal setOP:BYTE               ; setcc ��������
extrn                   pascal jmpOP:BYTE               ; jcc ��������
extrn                   pascal ExampleMin:QWORD         ; ����������� ����. �������
extrn                   pascal ExampleMax:QWORD         ; ����������� ����. �������
extrn                   pascal ExampleText:DWORD        ; ��������� �� ��������� ������� 
extrn                   pascal szmask:QWORD             ; ���������� (��� ����������� � ����)
extrn                   pascal _packalg:DWORD           ; �������� ��������
extrn                   pascal _found:WORD             ; ���-�� �������� ��������
extrn                   pascal _vsize:BYTE              ; ������ ������� � ������
extrn                   pascal _isize:BYTE              ; ������ �������� ������
extrn                   pascal _lcount:DWORD            ; ���-�� ��������� ������
extrn                   pascal _oldBuff:DWORD           ; ��������� �� ������ ������
extrn                   pascal temp:QWORD               ; ��� DWORD
extrn                   pascal savebp:DWORD             ; EBP Save
extrn                   pascal pwhole:DWORD             ; StoreHouse for unpacked functions
extrn                   pascal pprevd:DWORD             ; Source for unpacked functions
extrn                   pascal passed:DWORD             ; ��� �������
extrn                   pascal masksv:DWORD             ; Save Mask intermediate
extrn                   pascal old_op:DWORD             ; Old Operation
NPACKED = 0   ; ������������� �������� �� 16 ���
SETPACK =  4; ; ������� ��������� �� 32 ����
RLESET  = 16; ; ��������� ����������� RLE
RLESETP = 32; ; RLESET, � ����������� ��������, �� ��� ������� ��������


