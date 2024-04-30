.386
locals
.model flat, STDCALL
;---------------------- ----------------------- ---------------------------
data                    segment public ".DATA"
savesp                  dd              ?
saveofs                 dd              ?
data                    ends
;---------------------- ----------------------- ---------------------------
CODE                    SEGMENT PAGE "_TEXT"
; �������� ������ ����� ������������ � ����� �������.
; ������� ����������
include                 extvars.inc
;---------------------- ----------------------- ---------------------------
ScanFirstDig            PROC uses eax ebx ecx edx esi edi, buff:DWORD, rslt:DWORD, bsize:DWORD
;---------------------- ----------------------- ---------------------------
                        mov                     edi, pwhole ; proxy destination
                        mov                     esi, buff
                        mov                     ecx, bsize
                        ; ��������� SMC
                        mov                     eax, dword ptr [szmask]
                        mov                     dword ptr [masking][1], eax ; ������ �����
                        mov                     ebx, dword ptr [ExampleMin] ; �������
                        and                     ebx, eax ; ����������� �������
                        mov                     dword ptr [CmpLimit][2], ecx   ; ������ ������
                        mov                     passed, 0
                        mov                     ecx, 10
                        push                    ebp
;---------------------- ----------------------- ---------------------------
; ����� ��������� �������� ������������� �� ����� �������
                        xor                     ebp, ebp ; ��������� �������
Repeat:
Loadval:   ;  �������� �������������� �������� �� ����������
                        mov                     eax, [esi + ebp]
masking:   ;  ���������� �������� (���������� � �������)
                        and                     eax, 1FFFFFFFh ; ��� �������� ������ ����������
;---------------------- ----------------------- ---------------------------
; ������ �������� � �. �.
div_cycle:
                        cmp                     eax, ebx         ; ��������� � ��������
                        je                      @SaveOffs
                        jb                      @EndTest         ; ����� ������ �������
                        xor                     edx, edx         ; ������� ���� ����� (:)
                        div                     ecx              ; ������ �� 10
                        jmp                     div_cycle
@SaveOffs:
                        mov                     [edi], bp         ; Save offset
                        add                     edi, 2
@EndTest:
                        add                     ebp, 1
CmpLimit: ;  ��������� � ������� ����������
                        cmp                     ebp, 12345678h ;  ��� ������������ ���  ;
                        jb                      Repeat
                        pop                     ebp
                        sub                     edi, pwhole
                        mov                     _packalg, NPACKED
                        mov                     _Isize, 2
                        shr                     edi, 1
                        mov                     _found, di
                        mov                     _Lcount, edi
                        mov                     passed, 1
                        ret
ScanFirstDig            ENDP
;---------------------- ----------------------- ---------------------------
SieveFirstDig           PROC uses eax ebx ecx edx esi edi, buff:DWORD, setlst:DWORD, dst:DWORD, count:DWORD
                        mov                     savebp, ebp
                        mov                     esi, pprevd ; ������ �������� ��� ������
                        mov                     edi, pwhole ; ������ ��� �����������
                        mov                     ecx, count
                        mov                     eax, dword ptr [szmask]      ; masking
                        shl                     ecx, 1          ; count * 2
                        add                     ecx, esi
; ��������� SMC
                        mov                     dword ptr [@svmask][1], eax ; ������� ������� ����������� (2)
                        mov                     dword ptr [@EndTest2][2], ecx ; ����� ������ �������� (4)
                        mov                     edx, buff   ; ��������� �� ����� ������
                        mov                     ebx, dword ptr [ExampleMin]  ; ecx = Example
                        mov                     ecx, 10     ; �������� = 10
                        mov                     passed, 0   ; debug
                        mov                     ebp, edx    ; @buff



@SieveLoop:
; �������� �������� ������������ ��������
                        movzx                   eax, word ptr [esi]
                        add                     esi, 2
                        mov                     eax, dword ptr [ebp][eax] ; ������� ��������
@svmask: ; SMC, masking loaded value
                        and                     eax, 12345678h ; chto szmask
@TestIt:
                        cmp                     eax, ebx     ; �������� � ��������
                        je                      @SaveIt      ; ��������� ��������� �����
                        jb                      @EndTest2    ;  ��� ������ - �� ��������
; ===================== ������� �� ������� � ���������� ��������/�������
@Div10:
                        xor                     edx, edx     ; ���������� � ������� edx:eax / example
                        div                     ecx          ; divide for example
                        jmp                     @TestIt
@SaveIt:
                        movzx                   eax, word ptr [esi - 2]
                        mov                     [edi], ax
                        add                     edi, 2    ; ��������� ������ (ax)
@EndTest2: ; SMC: immediate changed to limit
                        cmp                     esi, 12345678h  ; 12345678h chto ListLimit
                        jb                      @SieveLoop
                        mov                     ebp, savebp
                        sub                     edi, pwhole
                        mov                     _Isize, 2
                        mov                     _packalg, 0
                        shr                     edi, 1
                        mov                     _found, di
                        mov                     _Lcount, edi
                        mov                     passed, 2
                        ret
                        ENDP
;---------------------- ----------------------- ---------------------------
CODE                    ENDS
public                  ScanFirstDig
public                  SieveFirstDig
END