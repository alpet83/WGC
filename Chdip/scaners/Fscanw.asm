.386
PAGE 255, 255
.model flat, PASCAL
INCLUDE extvars.inc
INCLUDE fscan.inc			; General Macros File


CODE                    SEGMENT PAGE "_TEXT"
                        nn = 0
                        nc = 0

;---------------------- ----------------------- ---------------------------
; ��������� ������������� ���� � ����������
InitWS                  proc
                        mov                     al, setOP
                        nm = 0;
                        cmp                     byte ptr [scc0 + 1], al
                        je                      noset
                        ; ����������� 96-� SETCC �������
                        REPT                    60h
                        setscc                  %nm
                        nm = nm + 1
                        ENDM
noset:                        
                        ret
InitWS                  endp
ALIGN 32                ; ������������
;db                      8  dup (90h)
;---------------------- ----------------------- ---------------------------
ScanWORDS               PROC STDCALL uses eax ebx ecx edx esi edi ebp, buff:DWORD, rslt:DWORD, bsize:DWORD
                        ; Loading buffer info
			mov                     esi, buff  ; ebp + 08
                        mov                     edi, rslt  ; ebp + 0C
                        mov                     ecx, bsize ; ebp + 10
                        add                     ecx, esi        ; ������. �����
                        mov                     savebp, ebp     ; ���������� ebp
                        xor                     eax, eax
                        cmp                     dword ptr [dcode010][2], ecx
                        je                      nsave0
 	                ;  ��� ����� ������e ��������
			mov                     dword ptr [dcode010][2], ecx ; ����������� ����
nsave0:                        
                    	; �������
			mov                     dword ptr [edi + 00h], eax
			mov                     dword ptr [edi + 04h], eax
                        mov                     ebp, dword ptr [ExampleMin]
;---------------------- ----------------------- ---------------------------

                        nn = 0
; �������� ���� ������������
scan:
                        xor                     ecx, [esi + 40h] ; ������� ���������
                        ; ������ ���������
                        INDEX = 0
                        REPT                    0Fh
                        compsetw                 a, 0
                        compsetw                 c, 10h
                        compsetw                 d, 20h
                        compsetw                 b, 30h
                        INDEX = INDEX + 1
                        ENDM
;---------------------- ----------------------- ---------------------------
                        INDEX = 0;
                        ; ������ ��������� ���� � ��������
                        compsetw                 a, 0Fh, 17        ; 16 middle bits - set
                        compsetw                 c, 1Fh            ; 16 high bits - set
                        compsetw                 d, 2Fh, 17
                        compsetw                 b, 3Fh,           ; Bank conflict !!
;=============== ���������� �������� --------------------------------------------------
                        mov                      cx, ax    ; ������ eax ��������, � ecx �����
                        mov                      bx, dx    ; ���� ����� � ebx � edx
;---------------------- ----------------------- --------------------------
                        ; �������� �������� ��������
                        mov                     eax, [edi + 4] ; counter
                        xor                     ecx, -1
                        xor                     ebx, -1
                        xor                     edx, edx
                        add                     esi, 40h   ; ����������� ��������� src 1
;---------------------- ----------------------- ---------------------------
                        ; RLE PACKING
                        ; �������� ��������
                        cmp                     [edi], ecx
                        je                      $+0Dh
;---------------------- ----------------------- ---------------------------
                        ; ���������� �������� �������� (1)
                        mov                     [edi + 4], eax
                        ; c��������� ���������
                        mov                     [edi + 8], ecx
                        ; ����� �������� � 0
                        xor                     eax, eax
                        ; ���������� ��������� dst
                        add                     edi, 8
nsave1:
                        ; ��������� �������� (1)
                        inc                     eax
;---------------------- ----------------------- ---------------------------
                        ; �������� � ����. ���������
                        cmp                     ecx, ebx
                        je                      $+0DH
                        ; ���������� �������� (2)
                        mov                     [edi + 4], eax
                        ; ���������� ��������� (2)
                        mov                     [edi + 8], ebx
                        ; ����� �������� � 0
                        xor                     eax, eax
                        add                     edi, 8
nsave2:
                        inc                     eax
                        ; ���������� �������� (2)
                        mov                     dword ptr [edi + 4], eax
                        ALIGN 2
dcode010:
                        cmp                     esi, 12345678h
                        ; ����� ���������� ��������
                        jb                      scan
                        ;// Context restoring
;---------------------- ----------------------- ---------------------------
; SCANING LOOP COMPLETE  - ���� ������������ ��������
                        xor                     eax, eax
                        ; �������������� ebp
                        mov                     ebp, savebp
                        xor                     eax, eax        ; ������� eax
                        ; ��������� ��������� - �� �������
                        cmp                     ebx, 0
                        setne                   al
                        ; ���������� � ������� = ������
                        lea                     edi, [edi + eax * 8]
                        sub                     edi, rslt        ; -= @rslt
                        ; �������������� ������� � ����������
                        shr                     edi, 3
                        ; ���-�� ��������� (�� 8 ����) ������
                        mov                     _isize, 8
                        mov                     _lcount, edi
                        mov                     _packalg, RLESET
                        ret
ScanWORDS               ENDP                   ; ScanDWORDS

ALIGN 16                
;---------------------- ----------------------- ---------------------------
SieveWORDS              PROC  STDCALL uses eax ebx ecx edx esi edi ebp,   buff:DWORD, setlst:DWORD, dst:DWORD, count:DWORD
; �� ����� ������ 32-������ ��������� (+ ���-��) 
; ���������� ��������������: esi@buff, ebx@setlst (src), edi@setlst(dst)
; ������ � setlst - �� �����, ������� ����� ����������� ����������
                        pushad
                        mov                     ebx, setlst       ; �������� �����
                        mov                     esi, buff
                        mov                     edi, dst          ; ���������� (2-��� ��������)
                        ; ���-�� ��������� ������ ��������
                        mov                     ecx, count
                        shl                     ecx, 2          ; * 4, ���-�� � ������
                        add                     ecx, ebx          ; ������
                        mov                     dword ptr [dcode011+2], ecx
                        xor                     eax, eax
                        mov                     savebp, ebp
                        mov                     dword ptr [edi + 4], eax
                        mov                     dword ptr [edi + 12], eax      ;; ���������
                        mov                     ebp, dword ptr [exampleMin]   ;; �������� �������

;---------------------- ----------------------- ---------------------------
sieve:
                        mov                     dl, byte ptr [esi + 40h]
                        ; ��������� ��������� �������� ������
                        ; �� �������� ����������� 32 ��������
                        n = 1
                        compsetw                 a, 00h
                        compsetw                 c, 10h   
                        REPT                    14
                        ; �� ���������������� ���
                        compsetw                 a, n
                        o = n + 10h
                        compsetw                 c, o
                        n = n + 1
                        ENDM
                        compsetw                 a, 0Fh, 17
                        compsetw                 c, 1Fh, 1
                        ; ���������� �������� � ecx
                        mov                     cx, ax ; ������ � ecx - 32 ������ ���������
                        xor                     ecx, -1       
                        ; ����� �����������
                        and                     ecx, dword ptr [ebx]
                        xor                     eax, eax
                        add                     esi, 20h        ; c���. ��������� ������
                        add                     ebx, 4          ; ����. ��������� ���������
                        cmp                     dword ptr [edi], ecx
                        setne                   al
                        ; ����������� ���������
                        lea                     edi, [edi + eax * 8]
                        ; ���������� ���������
                        mov                     dword ptr [edi], ecx
                        ; ��������� ��������
                        add                     word ptr [edi + 4], 1
                        ; ��������������� ��������� ��������
                        mov                     word ptr [edi + 12], 0
;---------------------- ----------------------- ---------------------------
dcode011:
                        cmp                     ebx, 12345678h
                        jb                      sieve
                        xor                     eax, eax
                        cmp                     ecx, 0
                        setne                   al
                        shl                     eax, 3          ; * 8
                        add                     edi, eax
                        ; �������������� �������� ����������
                        mov                     ebp, savebp
                        mov                     esi, setlst
                        sub                     edi, dst
                        shr                     edi, 3          ; div 8
                        ; ������ �������� ������
                        mov                     _isize, 8
                        ; ���-�� ��������� ������
                        mov                     _lcount, edi
                        mov                     _packalg, RLESET 
                        popad
                        ret             
SieveWORDS              ENDP                    ; SieveDWORDS
;---------------------- ----------------------- ---------------------------
CODE                    ENDS
public          InitWS
public          ScanWORDS
public          SieveWORDS

END
