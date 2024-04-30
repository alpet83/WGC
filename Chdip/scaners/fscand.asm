.386P
PAGE 255, 255
.model flat, PASCAL

INCLUDE extvars.inc
INCLUDE fscan.inc			; General Macros File

CODE                    SEGMENT PAGE "_TEXT"
                        nn = 0
                        nc = 0

;---------------------- ----------------------- ---------------------------
; ��������� ������������� ���� � ����������
InitDS                  proc
                        mov                     al, setOP
                        nm = 0;
                        cmp                     byte ptr [scc0 + 1], al
                        je                      noset
                        ; ����������� SETCC �������
                        REPT                    50h
                        setscc                  %nm
                        nm = nm + 1
                        ENDM
                        ;mov                     byte ptr old_op, al 
noset:                        
                        ret
InitDS                  endp
ALIGN 32                ; ������������
;db                      8  dup (90h)
;---------------------- ----------------------- ---------------------------
ScanDWORDS              PROC STDCALL uses eax ebx ecx edx esi edi, buff:DWORD, rslt:DWORD, bsize:DWORD
                        ; Loading buffer info
			mov                     esi, buff  ; ebp + 08
                        mov                     edi, rslt  ; ebp + 0C
                        mov                     ecx, bsize ; ebp + 10
                        push                    ebp             ; ���������� ebp
                        add                     ecx, esi        ; ������. �����
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
scan:                   ;// Missalign reads prevent code
                        ;// mov                     eax, [esi + 04h]
                        ;//mov                     ecx, [esi + 08h]
                        mov                     edx, [esi + 1Ch]
                        mov                     ebx, [esi + 20h]
                        ;//mov                     dword ptr temp [00h], eax
                        ;//mov                     dword ptr temp [04h], ecx
                        mov                     dword ptr temp [10h], edx
                        mov                     dword ptr temp [14h], ebx
                        ;xor                     eax, eax
                        ;xor                     ecx, ecx
                        ;xor                     edx, edx
                        ;xor                     ebx, ebx
                        ; ������ ���������
                        ; // 8 bits, LoHalfBytes, HiWORD
                        INDEX = 0
                        ; // xL registers fill, mask = 000F.0000h
                        compsetdl               a, 11h
                        compsetdl               c, 12h
                        compsetdl               d, 13h
                        compsetdl               b, 10h
                        ; // xH registers fill, mask = 0F00.0000h  (+8h)
                        compsetdh               a, 19h
                        compsetdh               c, 1Ah
                        compsetdh               d, 1Bh
                        compsetdh               b, 18h

                        ; // 8 bits, LoHalfBytes, LoWORD
                        ; // xL registers fill, mask = 0000.000Fh
                         ror                     eax, 16 ; repositing  halfwords
                        compsetdl               a, 01h
                         ror                     ecx, 16
                        compsetdl               c, 02h
                         ror                     edx, 16
                        compsetdl               d, 03h
                         ror                     ebx, 16
                        compsetdl               b, 00h
                        ; // xH registers fill, mask = 0000.0F00h
                        compsetdh               a, 09h
                        compsetdh               c, 0Ah
                        compsetdh               d, 0Bh
                        ; // shifting sets to intersect
                         shl                    eax, 1
                         shl                    ecx, 2
                         or                     eax, ecx
                         shl                    edx, 3
                        compsetdh               b, 08h
                        ; // combining sets to one
                         or                     eax, edx
                         or                     eax, ebx
                        mov                     masksv, eax
                        ; // 8 bits, HiHalfBytes, HiWORD
                        compsetdl               b, 14h
                        compsetdh               b, 1Ch
                        ; // missaligned read in 3 operations
                        ;//cmp                     dword ptr temp [01h], ebp
                        ;//regstl                  %nn, a
                        ;//cmp                     dword ptr temp [02h], ebp
                        ;//regstl                  %nn, c
                        ;//cmp                     dword ptr temp [03h], ebp
                        ;//regstl                  %nn, d
                        ;// missaligned read and compare
                        compsetdl               a, 15h
                        compsetdl               c, 16h
                        compsetdl               d, 17h
                        ; // cacheline missalign prevent
                        cmp                     dword ptr temp [11h], ebp
                        regsth                  %nn, a
                        cmp                     dword ptr temp [12h], ebp
                        regsth                  %nn, c
                        cmp                     dword ptr temp [13h], ebp
                        regsth                  %nn, d
                        ;//compsetdh               a, 1Dh
                        ;//compsetdh               c, 1Eh
                        ;//compsetdh               d, 1Fh
                        ;// 8 bits, HiHalfBytes, LoWORD
                        ;// xH registers fill, mask = 0000.00F0
                         ror                    eax, 16
                        compsetdl               a, 05h
                         ror                     ecx, 16
                        compsetdl               c, 06h
                         ror                     edx, 16
                        compsetdl               d, 07h
                         ror                    ebx, 16  ; // swap half-dwords
                        compsetdl               b, 04h
                       ; // xH registers fill, mask = 0000.F000
                        compsetdh               a, 0Dh
                         shl                    eax, 5
                        compsetdh               c, 0Eh
                         shl                    ecx, 6
                        compsetdh               d, 0Fh
                         shl                    edx, 7
                         or                     ecx, masksv
                        compsetdh               b, 0Ch
                        add                     esi, 20h
;// Scanings complete - combining sets and try packing                        
                        shl                     ebx, 4
                        or                      eax, ecx
                        or                      edx, ebx
                        or                      eax, edx
                        xor                     eax, -1
                        ; // testing a set
                        cmp                     dword ptr [edi], eax
                        je                      only_inc
                        mov                     dword ptr [edi + 8], eax
                        mov                     dword ptr [edi + 12], 0
                        add                     edi, 8
only_inc: ;// increment set counter      PDB
                        add                     dword ptr [edi + 4], 1
;//--------------------- ----------------------- ---------------------------//
                        ALIGN 2
dcode010:
                        cmp                     esi, 12345678h
                        jb                      scan
                        ;// Context restoring
;---------------------- ----------------------- ---------------------------
; SCANING LOOP COMPLETE  - ���� ������������ ��������
                        xor                     eax, eax
                        mov                     [edi + 8], eax  ; ���������� 
                        mov                     [edi + 12], eax  ; ����������
                        pop                     ebp             ; �������������� ebp
                        ; ��������� ��������� - �� �������
                        add                     edi, 8
                        sub                     edi, rslt        ; -= @rslt
                        ; �������������� ������� � ����������
                        shr                     edi, 3
                        ; ���-�� ��������� (�� 8 ����) ������
                        mov                     _isize, 8
                        mov                     _lcount, edi
                        mov                     _packalg, RLESET
                        ret
ScanDWORDS              ENDP                   ; ScanDWORDS

;---------------------- ----------------------- ---------------------------
ScanDWORDSA             PROC STDCALL uses eax ebx ecx edx esi edi, buffa:DWORD, rslta:DWORD, bsizea:DWORD
                        ; Loading buffer info
			mov                     esi, buffa  ; ebp + 08
                        mov                     edi, rslta  ; ebp + 0C
                        mov                     ecx, bsizea ; ebp + 10
                        push                    ebp             ; ���������� ebp
                        add                     ecx, esi        ; ������. �����
                        xor                     eax, eax
                        cmp                     dword ptr [dcode0101][2], ecx
                        je                      nsave01
 	                ;  ��� ����� ������e ��������
			mov                     dword ptr [dcode0101][2], ecx ; ����������� ����
nsave01:
                    	; �������
			mov                     dword ptr [edi + 00h], eax
			mov                     dword ptr [edi + 04h], eax
                        mov                     ebp, dword ptr [ExampleMin]
;---------------------- ----------------------- ---------------------------
; �������� ���� ������������
scan0:                  ;// Missalign reads prevent code
                        ; ������ ���������
                        db 0Fh, 18h, 86h  ; prefetchnta
                        dd 300h           ; offset override
                        INDEX = 0
                        ; // High WORD of E*X reigsters
                        ; // 8 offsets  (32 bytes)
                        compsetdl               a, 34h
                        compsetdl               c, 30h
                        compsetdl               d, 14h
                        compsetdl               b, 10h
                        ; // xH registers (halfs)
                        compsetdh               a, 3Ch
                        shl                     eax, 16
                        compsetdh               c, 38h
                        shl                     ecx, 16
                        compsetdh               d, 1Ch
                        shl                     edx, 16
                        compsetdh               b, 18h
                        shl                     ebx, 16
                        ; // Low WORD E*X registers
                        ; // 8 offsets only (32 bytes)
                        compsetdl               a, 24h
                        compsetdl               c, 20h
                        compsetdl               d, 04h
                        compsetdl               b, 00h
                        ; // xH registers
                        compsetdh               a, 2Ch
                        shl                     eax, 4
                        compsetdh               c, 28h
                        or                      eax, ecx
                        compsetdh               d, 0Ch
                        shl                     edx, 4
                        compsetdh               b, 08h
                        xor                     eax, 11111111h
                        or                      ebx, edx  ;// combining complete=
                        mov                     ecx, dword ptr [edi + 4]
                        ; // Fucked invertors
                        xor                     ebx, 11111111h
        		;// add		esi, 20h		// next line
		        ;// +++++++++++++++++++++++++++++++++++++++++++++
                        ;// Scanings complete - combining sets and try packing
                        ; // testing a set
                        ; // for offsets 00..1C
                        add                     esi, 40h
                        cmp                     dword ptr [edi], ebx
                        je                      only_inc0
                        xor                     ecx, ecx
                        mov                     dword ptr [edi + 8], ebx
                        mov                     dword ptr [edi + 12], ecx
                        add                     edi, 8
only_inc0:
                        add                     ecx, 1
                        cmp                     ebx, eax
                        je                      only_inc1
                        mov                     dword ptr [edi + 4], ecx
                        xor                     ecx, ecx
                        mov                     dword ptr [edi + 8], eax
                        mov                     dword ptr [edi + 12], ecx
                        add                     edi, 8
only_inc1: ;// increment set counter      PDB
                        add                     ecx, 1
;//--------------------- ----------------------- ---------------------------//
                        ALIGN 2
dcode0101:
                        cmp                     esi, 12345678h
                        mov                     dword ptr [edi + 4], ecx
                        jb                      scan0
                        ;// Context restoring
;---------------------- ----------------------- ---------------------------
; SCANING LOOP COMPLETE  - ���� ������������ ��������
                        xor                     eax, eax
                        ; // ������ ������� �����
                        mov                     [edi + 8], eax  ; ����������
                        mov                     [edi + 12], eax  ; ����������
                        pop                     ebp             ; �������������� ebp
                        ; ��������� ��������� - �� �������
                        add                     edi, 8
                        sub                     edi, rslta        ; -= @rslt
                        ; �������������� ������� � ����������
                        shr                     edi, 3
                        ; ���-�� ��������� (�� 8 ����) ������
                        mov                     _isize, 8
                        mov                     _lcount, edi
                        mov                     _packalg, RLESET
                        ret
ScanDWORDSA             ENDP                   ; ScanDWORDS

ALIGN 16                
;---------------------- ----------------------- ---------------------------
SieveDWORDS             PROC  STDCALL uses eax ebx ecx edx esi edi ebp,   buff:DWORD, setlst:DWORD, dst:DWORD, count:DWORD
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
                        push                    ebp
                        mov                     dword ptr [edi + 4], eax
                        mov                     dword ptr [edi + 12], eax      ;; ���������
                        mov                     ebp, dword ptr [exampleMin]   ;; �������� �������

;---------------------- ----------------------- ---------------------------
sieve:
                        ;mov                     dl, byte ptr [esi + 40h] ; prefetch
                        ; ��������� ��������� �������� ������
                        ; �� �������� ����������� 32 ��������
                        n = 1
                        compsetd                 a, 00h
                        compsetd                 c, 10h   
                        REPT                    14
                        ; �� ���������������� ���
                        compsetd                 a, n
                        o = n + 10h
                        compsetd                 c, o
                        n = n + 1
                        ENDM
                        compsetd                 a, 0Fh, 17
                        compsetd                 c, 1Fh, 1
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
                        cmp                     ebx, 12345678h ;; test for list end
                        jb                      sieve
                        xor                     eax, eax
                        cmp                     ecx, 0
                        setne                   al
                        shl                     eax, 3          ; * 8
                        add                     edi, 8
                        ; �������������� �������� ����������
                        pop                     ebp
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
SieveDWORDS             ENDP                    ; SieveDWORDS
;---------------------- ----------------------- ---------------------------
CODE                    ENDS
public          InitDS
public          ScanDWORDS
public          ScanDWORDSA
public          SieveDWORDS

END
