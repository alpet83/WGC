DEFALGS                 MACRO  ScanFunc, SieveFunc
;---------------------- ----------------------- ---------------------------
ALIGN                   32
ScanFunc                PROC STDCALL uses eax ebx ecx edx esi edi,  buff:DWORD, rslt:DWORD, bsize:DWORD
;---------------------- ----------------------- ---------------------------
; ����� ��������� ��������
; ������� ������� ������������ esi �� ������� ��� ������� 32, � ����� 64 ��� 128
                        ; ��������� ������������� ����
                        mov                     esi, buff     ; ���������� ��������
                        mov                     ecx, bsize    ; ������ ������� � ������
                        mov                     edi, rslt     ; ���������� ��������
                        add                     ecx, esi      ; ������������� � ������
                        mov                     dword ptr [CmpLimit][2], ecx ; ������ ������
                        xor                     eax, eax              ; Index of Buffer = 0
                        mov                     ebx, dword ptr [exampleMin]
                        mov                     ecx, dword ptr [exampleMax]
                        mov                     savebp, ebp
                        xor                     ebp, ebp
                        mov                     [edi], ebp
                        mov                     [edi + 4], ebp
;---------------------- ----------------------- ---------------------------
CmpLoop:                ; ���� ������������
                        OFS = 0
;---------------------- ----------------------- ---------------------------
IF optcache eq 1
                        mov                     edx, [esi + 1Ch]
                        mov                     dword ptr temp [0], edx
                        mov                     eax, [esi + 20h]
                        mov                     dword ptr temp [4], eax
ENDIF
                        xor                     edx, edx
                        xor                     eax, eax
                        n = 0
                        ; ����������� ���� ��� 61 ��������
                        ; ���������� �������� edx
                        REPT                    32
                        cmprset                d, %n, esi
                        OFS = OFS + 1
                        n = n + 1
                        ENDM
                        ; ���������� �������� eax
                        REPT                    29
                        cmprset                a, %n, esi
                        OFS = OFS + 1
                        n = n + 1
                        ENDM
;---------------------- ----------------------- ---------------------------
IF optcache eq 1
                        ; ������ � ���������
                        OFS = 1
                        REPT                    3
                        cmprset                a, %n, temp
                        OFS = OFS + 1
                        n = n + 1
                        ENDM
ELSE  ; ���������� ��������� � ��� �� ����
                        REPT                    3
                        cmprset                a, %n, esi
                        OFS = OFS + 1
                        n = n + 1
                        ENDM
ENDIF
;---------------------- ----------------------- ---------------------------
                        add                     esi, 40h   ; ��������� 32 ��������
                        cmp                     [edi], edx
                        je                      NotSave
;---------------------- ----------------------- ---------------------------
                        mov                     [edi + 4], ebp  ; ��������� ����������
                        mov                     [edi + 8], edx  ; ��������� ���������
                        xor                     ebp, ebp
                        mov                     dword ptr [edi + 12], ebp ; ��������� ����
                        add                     edi, 8     ; ��������� ���������
;---------------------- ----------------------- ---------------------------
NotSave:
                        add                     ebp, 1
                        cmp                     [edi], eax
                        je                      NotSave2
                        mov                     [edi + 4], ebp ; ��������� ����������
                        mov                     [edi + 8], eax ; ��������� ���������
                        xor                     ebp, ebp
                        mov                     dword ptr [edi + 12], ebp ; save 0
                        add                     edi, 8
NotSave2:
                        add                     ebp, 1
CmpLimit:     ;  ��� ������������ ���
                        cmp                     esi, 12345678h
                        jb                      CmpLoop  ; If below
;---------------------- ----------------------- ---------------------------
                        mov                     [edi + 0], edx ; ������������� ���������
                        mov                     [edi + 4], ebp ; ������������� ����������
                        mov                     ebp, savebp
                        mov                     _packalg, RLESET  ; �������� ���������� + RLE
                        mov                     _Found, 1         ; ������� ������� ...
                        sub                     edi, rslt         ; ������� ������
                        mov                     _isize, 8
                        shr                     edi, 3            ; ������ �� 8
                        mov                     _Lcount, edi      ; count of offsets
                        add                     _Lcount, 1
                        ret
ScanFunc                ENDP
;---------------------- ----------------------- ---------------------------
SieveFunc               PROC STDCALL uses eax ebx ecx edx esi edi, lbuff:DWORD, setlst:DWORD, dst:DWORD, count:DWORD
; ��������� ������������� ����
                        mov                     esi, lbuff
                        mov                     edi, dst     ; ����� ����������
                        mov                     edx, setlst  ; �������� ���������
                        mov                     ecx, count
                        shl                     ecx, 2       ; �������� �� 4 (32���� � ��)
                        add                     ecx, edx     ; ������������� � ������
                        mov                     dword ptr [@CmpLimit][2], ecx ; DynaCode (3)
                        mov                     ebx, dword ptr [ExampleMin]
                        mov                     ecx, dword ptr [ExampleMax]
                        xor  eax, eax           ; ������� eax
                        mov                     savebp, ebp
                        mov                     ebp, edx
                        mov                     [edi + 0], eax ; �������
                        mov                     [edi + 4], eax ; �������
;---------------------- ----------------------- ---------------------------
                        ; ����� �������� - ���������
@Repeat:                ; ����������� �������� � ������� �������
                        xor                     edx, edx ; �������� ����� ���������
                        cmp                     dword ptr [ebp], edx
                        je                      nocomp ; ���� ���� - �� ��������� ��������
IF optcache eq 1
                        mov                     eax, [esi + 1Ch]
                        mov                     dword ptr temp [0], eax
                        mov                     eax, [esi + 20h]
                        mov                     dword ptr temp [4], eax
ENDIF                        
;---------------------- ----------------------- ---------------------------
                        OFS = 0                 ; ����� �������� � �������
                        ; ���������� �������� edx
                        REPT                    29
                        cmprset                d, %n, esi
                        OFS = OFS + 1
                        n = n + 1
                        ENDM
;---------------------- ----------------------- ---------------------------
IF optcache eq 1
                        ; ������ � ���������
                        OFS = 1
                        REPT                    3
                        cmprset                d, %n, temp
                        OFS = OFS + 1
                        n = n + 1
                        ENDM
ELSE  ; �� ��������� � �������� �������
                        REPT                    3
                        cmprset                d, %n, esi
                        OFS = OFS + 1
                        n = n + 1
                        ENDM
ENDIF                        
;---------------------- ----------------------- ---------------------------
                        and                     edx, [ebp]     ; ����������� ���������
nocomp:                        
                        add                     esi, 20h       ; ��������� 32 ��������
                        add                     ebp, 4         ; ��������� ��������o
                        cmp                     [edi], edx      ; �������� ���������
                        je                      NotSave1        ; �� ��������� ������
                        mov                     [edi + 8], edx  ; ����� ���������
                        mov                     dword ptr [edi + 12], 0 ; ���-�� = 0
                        add                     edi, 8
NotSave1:
                        add                     dword ptr [edi + 4], 1
@CmpLimit:      ;  SMC3
                        cmp                     ebp, 12345678h ; chto ListLimit
                        jb                      @Repeat  ; If below
                        xor                     eax, eax
                        mov                     ebp, savebp
                        test                    edx, edx  ; flag on Zerro
                        setnz                   al
                        mov                     _packalg, RLESET ; �������� RLE ��������
                        lea                     edi, [edi + eax * 8] ; ��������� ������
                        sub                     edi, dst
                        mov                     _Isize, 8
                        shr                      edi, 3         ; ������ �� 8
                        mov                     _Found, 1
                        mov                     _Lcount, edi    ; ���������� ���������
                        ret
                        ENDP
;---------------------- ----------------------- ---------------------------                        
public                  ScanFunc
public                  SieveFunc
;---------------------- ----------------------- ---------------------------
                        ENDM




