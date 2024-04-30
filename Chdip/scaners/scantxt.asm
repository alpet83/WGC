 .386
locals
.model flat, STDCALL
;---------------------- ----------------------- ---------------------------
CODE                    SEGMENT PAGE "_TEXT"
;---------------------- ----------------------- ---------------------------
; ������� ����������
include                 extvars.inc
ALIGN 32
;---------------------- ----------------------- ---------------------------
CmpChar                 MACRO                   ord, reg, ofst, islast
                        cmp                     [esi + ofst], reg ;; buff [0] ? extext [0]
IFB <islast>
                        jne                     @@NextComp&ord&ofst  ; �� �������� ���� �����
                        mov                     al, ofst
                        jmp                     CompStr&ord          ; ��������� �� �������
@@NextComp&ord&ofst:
ELSE
                        mov                     al, ofst
                        jne                     @@BreakNFound      ; ������ �� �������
ENDIF
                        ENDM
ScanText                PROC STDCALL uses eax ebx ecx edx esi edi ebp, buff:DWORD, rslt:DWORD, bsize:DWORD
; �����: ������� � ���������� ����������
                        mov                     esi, buff
                        mov                     edi, pwhole   ; ������������ ������ ������
                        mov                     edx, esi     ; ������������ ��� ������ �������
                        mov                     ecx, bsize
                        add                     ecx, esi           ; �������� ������
                        mov                     ebp, ExampleText ; ���������
@@ScanRepeat:
                        xor                     eax, eax ; Index
@@repeat:
                        ;; ������� ��������� ��������� ������� ��������
                        mov                     bl, byte ptr [ebp]  ; ������� [0]..[3]
                        CmpChar                 1, bl, 0
                        CmpChar                 1, bl, 1
                        CmpChar                 1, bl, 2
                        CmpChar                 1, bl, 3, 1
CompStr1:
                        add                     esi, eax   ; buff += ofs
                        mov                     al, 1      ; ������ ������ [esi + eax] = [2]
LCompStr1:
                        ; ����� ���� �� ������ ������ �������
                        mov                     bl, byte ptr [ebp + eax]
                        cmp                     bl, 0                           ; ����� �������
                        je                      @@BreakFound ; ������� ��-���, �.�. ��������� ����� �������
                        cmp                     byte ptr [esi + eax], bl         ; ���� �� �������
                        jne                     @@BreakNFound ; ���� �� �����
                        add                     al, 1
                        cmp                     al, 64        ; ����������������
                        jb                      LCompStr1     ; ������� ����� ������ �������
                        jmp                     @@BreakNFound ; ���� � ��������
@@BreakFound:
                        mov                     ebx, esi ; ������� ����� � �������
                        sub                     ebx, edx ; �������� � �������
                        mov                     [edi], bx
                        add                     edi, 2
@@BreakNFound:
                        add                     eax, 1      ; 0-������ = 1-������
                        add                     esi, eax ; ���������� � ������� �� n
                        cmp                     esi, ecx ; �������� � ������ �������
                        jb                      @@ScanRepeat
@@ScanComplete:
                        mov                    _packalg, 0
                        sub                     edi, pwhole
                        shr                     edi, 1
                        mov                    _found, di
                        mov                    _Lcount ,edi
                        mov                    _Isize, 2
                        ret
ScanText                ENDP
ALIGN 32
;---------------------- ----------------------- ---------------------------
ScanWide                PROC  STDCALL uses eax ebx ecx edx esi edi ebp,  _buff:DWORD, _rslt:DWORD, _bsize:DWORD
; �����: ������� � ���������� ����������
                        mov                     esi, _buff
                        mov                     edi, pwhole
                        mov                     ecx, _bsize
                        mov                     edx, esi
                        add                     ecx, esi ; �������� ������
                        mov                     ebp, dword ptr [ExampleText]
@@ScanRepeat:
                        xor                     eax, eax ; Index
@@repeat:
                        mov                     bx, [eax + ebp]  ; �������
                        ver = 2 
                        CmpChar                 2, bx, 0
                        CmpChar                 2, bx, 1
                        CmpChar                 2, bx, 2
                        CmpChar                 2, bx, 3, 1
CompStr2:
                        add                     esi, eax
                        mov                     al, 1
LCompStr2:
                        mov                     bx, [ebp][eax] ; ������ �� �������
                        cmp                     bx, 0                           ; ����� �������
                        je                      @@BreakFound ; ������ ��������� �.�. ��������� ����� �������
                        cmp                     word ptr [esi][eax], bx         ; ���� �� �������
                        jne                     @@BreakNFound
                        add                     eax, 2   ; ������ WideChar = 2 �����
                        cmp                     ax, 64  ; ����������������
                        jb                      LCompStr2 
                        jmp                     @@BreakNFound ; ���� � ��������
@@BreakFound:
                        mov                     ebx, esi
                        sub                     ebx, edx ; �������� � �������
                        mov                     [edi], bx
                        add                     edi, 2

@@BreakNFound:
                        inc                     eax      ; 0-������ = 1-������
                        add                     esi, eax ; ���������� � ������� �� n
                        cmp                     esi, ecx ; �������� � ������ �������
                        jb                      @@ScanRepeat
@@ScanComplete:
                        sub                     edi, pwhole
                        mov                    _packalg, 0
                        shr                     edi, 1
                        mov                    _found, di
                        mov                    _Lcount, edi
                        mov                    _Isize, 2
                        ret
ScanWide                ENDP
;---------------------- ----------------------- ---------------------------
SieveText               PROC STDCALL uses eax ebx ecx edx esi edi ebp,  buff:DWORD, setlst:DWORD, dst:DWORD, count:DWORD
                        mov                     esi, pprevd
                        mov                     edi, pwhole
                        mov                     ecx, count
                        mov                     edx, buff
                        add                     ecx, esi        ; � ������ ������ ��������
                        mov                     ebp, exampleText
                        mov                     dword ptr @@SMC_CMP [3], edx ; ����� ����������
                        xor                     eax, eax    ; ��������
@@ScanRepeat:
                        movzx                   eax, word ptr [esi] ; ��������� ��������
                        add                     esi, 2
                        xor                     edx, edx    ; ������
@@repeat:
                        mov                     bl, byte ptr [ebp + edx]  ; �������
                        cmp                     bl, 0                           ; ����� �������
                        je                      @@BreakFound ; ������� ��-���, �.�. ��������� ����� �������
                        ;  ������������ ���  ;
@@SMC_CMP:
                        cmp                     byte ptr [12345678h + edx][eax], bl  ; ���� �� �������
                        jne                     @@BreakNFound
                        inc                     edx
                        cmp                     dx, 64  ; ����������������
                        jb                      @@repeat
                        jmp                     @@BreakNFound
@@BreakFound:
                        mov                     [edi], ax
                        add                     edi, 2
@@BreakNFound:
                        cmp                     esi, ecx ; �������� � ������ ������
                        jb                      @@ScanRepeat
@@ScanComplete:
                        sub                     edi, pwhole
                        mov                    _packalg, 0
                        shr                     edi, 1
                        mov                    _found, di
                        mov                    _Lcount, edi
                        mov                    _Isize, 2
                        ret
SieveText               ENDP

;---------------------- ----------------------- ---------------------------
SieveWide               PROC STDCALL uses eax ebx ecx edx esi edi ebp, buff:DWORD, setlst:DWORD, dst:DWORD, count:DWORD
                        mov                     edx, buff
                        mov                     ecx, count
                        mov                     esi, pprevd
                        mov                     edi, pwhole
                        add                     ecx, esi
                        mov                     dword ptr @@SMC_CMP [4], edx ; ����� ����������
                        mov                     ebp, ExampleText
                        xor                     eax, eax    ; ��������
@@ScanRepeat:
                        movzx                   eax, word ptr [esi] ; ��������� ��������
                        add                     esi, 2
                        xor                     edx, edx    ; ������
@@repeat:               ; ��������� ������ �� ������ ������� (���������� ������)
                        mov                     bx, word ptr [ebp + edx]  ; �������
                        cmp                     bx, 0                           ; ����� �������
                        je                      @@BreakFound ; ������� ��-���, �.�. ��������� ����� �������
 ;  ������������ ���  ;
@@SMC_CMP:              ; �������� � �������� �� �������
                        cmp                     word ptr [12345678h + edx][eax], bx
                        jne                     @@BreakNFound
                        inc                     edx ; WideChar is 2byte size
                        inc                     edx
                        cmp                     dx, 64  ; ����������������
                        jb                      @@repeat
                        jmp                     @@BreakNFound
@@BreakFound:
                        mov                     [edi], ax  ; ��������� �������� eax
                        add                     edi, 2
@@BreakNFound:
                        cmp                     esi, ecx ; �������� � ������ ������
                        jb                      @@ScanRepeat
canComplete:
                        sub                     edi, pwhole
                        mov                    _packalg, 0
                        shr                     edi, 1
                        mov                    _Found, di   ;; ������� �������    
                        mov                    _Lcount, edi ;; ������ ������
                        mov                    _packalg, 0
                        mov                    _Isize, 2
                        ret
SieveWide               ENDP
;---------------------- ----------------------- ---------------------------
CODE                    ENDS
public                  ScanText
public                  ScanWide
public                  SieveText
public                  SieveWide
END
