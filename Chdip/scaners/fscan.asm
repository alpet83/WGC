locals
.386
.model flat, STDCALL
;---------------------- ----------------------- ---------------------------
CODE                    SEGMENT PAGE "_TEXT"
;---------------------- ----------------------- ---------------------------
; ������� ����������
include                 extvars.inc
ALIGN                   32
;---------------------- ----------------------- ---------------------------
PackRLE                 proc uses eax ebx ecx edx esi edi, src:DWORD, dst:DWORD, count:DWORD
; �������� �������� ������ �������� � RLE ������ �������� ;
;---------------------- ----------------------- ---------------------------
                        mov                     savebp, ebp
                        mov                     esi, src        ; ��������
                        mov                     ecx, count      ; ����������
                        mov                     edi, dst        ; ��������
                        shl                     ecx, 2          ; size = count * 4
                        add                     ecx, esi        ; ������
                        mov                     dword ptr [smc_cmp0][2], edx
                        xor                     ebp, ebp        ; ���������� ��������
                        mov                     _Found, bp
                        xor                     ecx, ecx
                        mov                     ebx, [esi]
                        mov                     [edi], ebx ; ��������� �������� ���������
;---------------------- ----------------------- ---------------------------
packloop:       ; ���� �������� �������� ==================================
                        add                     esi, 4     ; �������� ���������
                ; �������� �� �� ��� ���� �����, � ����� ����������
                        cmp                     dword ptr [edi], ebx
                        je                      NoSave  ; �������� �����������
                        xor                     eax, eax       ; ������� eax
                        test                    ebx, ebx       ; �������� � 0
                        jz                      NoSave         ; 0 �� ���������
                        ; ���������� �������������� ����������� ��������
                        mov                     dword ptr [edi + 4], ecx ; ���������� �������� � ����������
                        ; ���������� ��������� �������� ��������
                        mov                     dword ptr [edi + 8], ebx
                        add                     edi, 8         ; ������ �������� ��������
;---------------------- ----------------------- ---------------------------
;  ������ ���������� �������� � ���������� ���������
                        REPT                    32
                        shr                     ebx, 1         ; ��������� ���
                        adc                     al, 0          ; �������� ���
                        ENDM
;---------------------- ----------------------- ---------------------------
                        xor                     cx, cx         ; �������� count`er
NoSave:
                        add                     ebp, eax       ; ������� �������� += set.founds
                        add                     ecx, 200001h   ; ��������� ���-�� & ��������
;---------------------- ----------------------- ---------------------------
smc_cmp0:
                        cmp                     esi, 12345678h
                        mov                     ebx, [esi]    ; ��������� ����. ���������                        
                        jb                      packloop
                        mov                     _Found, bp      ; ���-�� ��������
                        mov                     ebp, savebp
                        mov                     [edi + 4], cx   ; ��������� ��� ��� ����������
                        sub                     edi, dst        ; �������� ��������� ���������
                        mov                     _packalg, RLESETP  ; �������� ��������
                        shr                     edi, 3             ; ������ �� 8!
                        mov                     _Isize, 8          ; ������ ��������
                        mov                     _Lcount, edi       ; ��������� ���-�� ���������
                        ret
;---------------------- ----------------------- ---------------------------
PackRLE                 endp
ALIGN                   32
;---------------------- ----------------------- ---------------------------
; ������� ���������� ��������� ��� � ���������� ������
OverPack                proc  uses eax ebx ecx edx esi edi, src:DWORD, count:DWORD
                        mov                     savebp, ebp
                        mov                     esi, src
                        mov                     edx, count
                        shl                     edx, 3         ; � ������ = count * 8
                        add                     edx, esi
                        mov           dword ptr [smc_cmp][2], edx       ; ������ ������
                        xor                     ebp, ebp       ; ������� ��������
                        xor                     ecx, ecx       ; �������� � ������ �������
                        mov                     edi, esi       ; ��������� dst = src
cmplp:
                        mov                     ebx, [esi + 0] ; �������� ���������
                        ; �������� ����������
                        mov                     cx, word ptr [esi + 4]
                        test                    ecx, ecx
                        jz                      skipall        ; ������� �� ����
;---------------------- ----------------------- ---------------------------
                        test                    ebx, ebx       ; �������� �� ������� ���������
                        jz                      skipcalc       ; �� ������� ����
                        mov                     [edi + 0], ebx
                        ; ���������� �������� � ��������
                        mov                     [edi + 4], ecx
                        add                     edi, 8         ; ��������� @dst
;---------------------- ----------------------- ---------------------------
                        xor                     eax, eax       ; ������� eax
                        ; ������� 32 ��� ��������
                        REPT                    32
                        shr                     ebx, 1    ; ��������� ���
                        adc                     al, 0     ; �������� ���
                        ENDM
                        ; ������ � �l ���������� ��������� ���
;---------------------- ----------------------- ---------------------------
                        ; ��������� �� ���������� �������� (���������������)
                        mul                     cx
                        add                     ebp, eax   ; ������� ��������
skipcalc:
                        ; edx = count
                        movzx                   edx, cx     ; ������ ��������
                        mov                     eax, ecx    ; ��������� ����������
                        ; rep count * 32 to hi word
                        shl                     edx, 21
                        add                     ecx, edx     ; ��������
skipall:
                        ; ��������� 8 ����
                        add                     esi, 8     ; ����. �������
smc_cmp:                        
                        cmp                     esi, 12345678h
                        jb                      cmplp
;---------------------- ----------------------- ---------------------------
; ���� �������� ��������
                        mov                     cx, ax     ; ����������
                        mov                     _found, bp ; ��������� ��������
                        xor                     eax, eax
                        mov                     [edi + 00h], ebx ; ���������
                        mov                     [edi + 04h], ecx ; counter + offset
                        ; ������������� ��� ���������� �������
                        mov                     [edi + 08h], eax
                        mov                     [edi + 0Ch], eax
                        mov                     ebp, savebp
                        sub                     edi, src          ; ������� ������
                        mov                     _packalg, RLESETP
                        shr                     edi, 3            ; ������ � ��������� (/8)
                        mov                     _Isize, 8         ; ������ ��������
                        mov                     _lcount, edi      ; �������� ����������
                        ret
                        endp
;---------------------- ----------------------- ---------------------------
; ����������� ������ �� ���������, �� ���� ����������� ������ ����������� ����������
; ���������� �������� ����� ����, ����� ���������� ������������� ������ �� ���������
; ������ ����� ����� �������. ��� ������� ��������������� ����� 64� - ������ ������ 8�.
ALIGN                   32
UnpackRLE               proc                    src:DWORD, dst:DWORD, count:DWORD
                        pushad
                        mov                     esi, src
                        mov                     edi, dst
                        mov                     ecx, count
                        shl                     ecx, 3
                        add                     ecx, esi    ; ��������� �������
                        mov                     dword ptr [dcode012 + 2], ecx
                        xor                     ebp, ebp
                        xor                     edx, edx
unpack:
                        mov                     eax, dword ptr [esi]
                        ; ���������� ����������
                        movzx                   ecx,  word ptr [esi + 4]
                        or                      ecx, ecx
                        jz                      skipit                     
                        ; ��������������� �������� � �������
                        movzx                   ebx,  word ptr [esi + 6]
                        ; 1 index = 32 bytes (if set decoded)
                        shr                     ebx, 5
                        cmp                     ebx, edx
                        je                      fill
fill0:
                        mov                     [edi + edx * 4], ebp
                        add                     edx, 1
                        cmp                     edx, ebx
                        jb                      fill0
                        ;������� 32 - ������� ���������
fill:
                        ; ���������� ������ ����������
                        mov                     [edi + edx * 4], eax
                        add                     edx, 1
                        sub                     ecx, 1
                        jnz                     fill
skipit:
                        add                     esi, 8
dcode012:
                        cmp                     esi, 12345678h 
                        jb                      unpack
                        xor                     eax, eax
                        mov                     _Lcount, edx  ; ��������� ������ ������������� ������
                        mov                     [edi + edx * 4 +  4], eax
                        mov                     _packAlg, SETPACK
                        popad
                        ret                     ; ����� �� ������
UnpackRLE               endp
CODE                    ENDS
;---------------------- ----------------------- ---------------------------
public                  OverPack
public                  PackRLE
public                  UnpackRLE

END
