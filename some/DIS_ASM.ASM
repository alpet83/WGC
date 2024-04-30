
;             ╔══════════════════════════════════════════════════╗
;             ║ *** ░▒▓█  Данные для дизассемблирования █▓▒░ *** ║
;             ╚══════════════════════════════════════════════════╝

command_symbol	db	'aaa', 'aad', 'aam', 'aas', 'adc', 'add'
		db	'and', 'arpl', 'bound', 'bsf', 'bsr'
		db	'bt', 'btc', 'btr', 'bts', 'call', 'cbw'
		db	'cdq', 'clc', 'cld', 'cli', 'clts'
		db	'cmc', 'cmp', 'cmpsb', 'cmpsw', 'cmpsd'
		db	'cwd', 'cwde', 'daa', 'das', 'dec', 'div'
		db	'enter', 'esc', 'hlt', 'ibts', 'idiv'
		db	'imul', 'in', 'inc', 'insb', 'insw'
		db	'insd', 'int', 'into', 'iret', 'iretd'
		db	'jmp', 'ja', 'jnc', 'jc', 'jbe', 'jcxz'
		db	'jz', 'jg', 'jnl', 'jl', 'jle', 'jnz'
		db	'jno', 'jnp', 'jns', 'jo', 'jp', 'js'
		db	'lahf', 'lar', 'lea', 'leave', 'lgdt'
		db	'lidt', 'lds', 'les', 'lfs', 'lgs', 'lss'
		db	'lldt', 'lmsw', 'lock', 'lodsb', 'lodsw'
		db	'lodsd', 'loop', 'loopz', 'loopnz'
		db	'lsl', 'ltr', 'mov', 'movsb', 'movsw'
		db	'movsd', 'movsx', 'movzx', 'mul', 'neg'
		db	'nop', 'not', 'or', 'out', 'outsb'
		db	'outsw', 'outsd', 'pop', 'popa', 'popad'
		db	'popf', 'popfd', 'push', 'pusha', 'pushad'
		db	'pushf', 'pushfd', 'rcl', 'rcr'
		db	'rol', 'ror', 'rep', 'repz', 'ret'
		db	'sahf', 'shl', 'sar', 'shr', 'sbb'
		db	'scasb', 'scasw', 'scasd', 'seta'
		db	'setnc', 'setc', 'setna', 'setz', 'setg'
		db	'setnl', 'setl', 'setle', 'setnz', 'setno'
		db	'setnp', 'setns', 'seto', 'setp', 'sets'
		db	'sgdt', 'sidt', 'shld', 'shrd', 'sldt'
		db	'smsw', 'stc', 'std', 'sti', 'stosb'
		db	'stosw', 'stosd', 'str', 'sub', 'test'
		db	'verr', 'verw', 'wait', 'xbts', 'xchg'
		db	'xlat', 'xor', 'db', 'repnz'
		db	'es:', 'cs:', 'ss:', 'ds:', 'fs:', 'gs:'
		db	'fld', 'fild', 'fbld', 'fst', 'fist', 'fstp'
		db	'fistp', 'fbstp', 'fxch', 'fldz', 'fld1'
		db	'fldpi', 'fldl2t', 'fldl2e', 'fldlg2'
		db	'fldln2', 'fcom', 'ficom', 'fcomp', 'ficomp'
		db	'fcompp', 'ftst', 'fxam', 'fadd', 'fiadd'
		db	'faddp', 'fsub', 'fsubr', 'fsubp', 'fsubrp'
		db	'fisub', 'fisubr', 'fmul', 'fimul', 'fmulp'
		db	'fdiv', 'fdivr', 'fdivp', 'fdivrp', 'fidiv'
		db	'fidivr', 'fsqrt', 'fscale', 'fprem'
		db	'frndint', 'fxtract', 'fabs', 'fchs', 'fptan'
		db	'fpatan', 'f2fm1', 'fyl2x', 'fyl2xp1'
		db	'finit', 'fent', 'fdisi', 'fldcw', 'fstcw'
		db	'fstsw', 'fclex', 'fstenv', 'fldenv', 'fsave'
		db	'frstor', 'fincstp', 'fdecstp', 'ffree'
		db	'fnop', 'fsincos'

offset_table	dw	00fh, 00fh, 00fh, 00fh, 00fh, 00fh, 17ch, 167h	; 0
		dw	153h, 153h, 153h, 153h, 153h, 153h, 17ch, 268h

		dw	00ch, 00ch, 00ch, 00ch, 00ch, 00ch, 17ch, 167h	; 1
		dw	1b9h, 1b9h, 1b9h, 1b9h, 1b9h, 1b9h, 17ch, 167h

		dw	012h, 012h, 012h, 012h, 012h, 012h, 268h, 062h	; 2
		dw	246h, 246h, 246h, 246h, 246h, 246h, 268h, 065h

		dw	265h, 265h, 265h, 265h, 265h, 265h, 268h, 000h	; 3
		dw	049h, 049h, 049h, 049h, 049h, 049h, 268h, 009h

		dw	087h, 087h, 087h, 087h, 087h, 087h, 087h, 087h	; 4
		dw	068h, 068h, 068h, 068h, 068h, 068h, 068h, 068h

		dw	17ch, 17ch, 17ch, 17ch, 17ch, 17ch, 17ch, 17ch	; 5
		dw	167h, 167h, 167h, 167h, 167h, 167h, 167h, 167h

		dw	180h, 16ah, 019h, 015h, 268h, 268h, 268h, 268h	; 6
		dw	17ch, 081h, 17ch, 081h, 08ah, 08eh, 158h, 15dh

		dw	0cfh, 0c6h, 0aeh, 0abh, 0b7h, 0c3h, 0b0h, 0a9h	; 7
		dw	0d3h, 0cch, 0d1h, 0c9h, 0beh, 0bbh, 0c0h, 0b9h

		dw	268h, 268h, 268h, 268h, 249h, 249h, 25dh, 25dh	; 8
		dw	12bh, 12bh, 12bh, 12bh, 12bh, 0dch, 12bh, 167h

		dw	14dh, 25dh, 25dh, 25dh, 25dh, 25dh, 25dh, 25dh	; 9
		dw	033h, 05bh, 02fh, 255h, 18bh, 173h, 1ach, 0d5h

		dw	12bh, 12bh, 12bh, 12bh, 12eh, 133h, 04ch, 051h	; A
		dw	249h, 249h, 234h, 239h, 107h, 10ch, 1bch, 1c1h

		dw	12bh, 12bh, 12bh, 12bh, 12bh, 12bh, 12bh, 12bh	; B
		dw	12bh, 12bh, 12bh, 12bh, 12bh, 12bh, 12bh, 12bh

		dw	268h, 268h, 1a9h, 1a9h, 0efh, 0ech, 12bh, 12bh	; C
		dw	06eh, 0dfh, 1a9h, 1a9h, 096h, 096h, 099h, 09dh

		dw	268h, 268h, 268h, 268h, 006h, 003h, 268h, 261h	; D
		dw	073h, 073h, 073h, 073h, 073h, 073h, 073h, 073h

		dw	11fh, 11ah, 116h, 0b3h, 085h, 085h, 155h, 155h	; E
		dw	02fh, 0a6h, 0a6h, 0a6h, 085h, 085h, 155h, 155h

		dw	103h, 268h, 26ah, 1a2h, 076h, 046h, 268h, 268h	; F
		dw	039h, 22bh, 03fh, 231h, 03ch, 22eh, 268h, 268h

length_table	db	03h, 03h, 03h, 03h, 03h, 03h, 04h, 03h		; 0
		db	02h, 02h, 02h, 02h, 02h, 02h, 04h, 02h

		db	03h, 03h, 03h, 03h, 03h, 03h, 04h, 03h		; 1
		db	03h, 03h, 03h, 03h, 03h, 03h, 04h, 03h

		db	03h, 03h, 03h, 03h, 03h, 03h, 02h, 03h		; 2
		db	03h, 03h, 03h, 03h, 03h, 03h, 02h, 03h

		db	03h, 03h, 03h, 03h, 03h, 03h, 02h, 03h		; 3
		db	03h, 03h, 03h, 03h, 03h, 03h, 02h, 03h

		db	03h, 03h, 03h, 03h, 03h, 03h, 03h, 03h		; 4
		db	03h, 03h, 03h, 03h, 03h, 03h, 03h, 03h

		db	04h, 04h, 04h, 04h, 04h, 04h, 04h, 04h		; 5
		db	03h, 03h, 03h, 03h, 03h, 03h, 03h, 03h

		db	05h, 04h, 05h, 04h, 02h, 02h, 02h, 02h		; 6
		db	04h, 04h, 04h, 04h, 04h, 04h, 05h, 05h

		db	02h, 03h, 02h, 03h, 02h, 03h, 03h, 02h		; 7
		db	02h, 03h, 02h, 03h, 02h, 03h, 03h, 02h

		db	02h, 02h, 02h, 02h, 04h, 04h, 04h, 04h		; 8
		db	03h, 03h, 03h, 03h, 03h, 03h, 03h, 03h

		db	03h, 04h, 04h, 04h, 04h, 04h, 04h, 04h		; 9
		db	03h, 03h, 04h, 04h, 05h, 04h, 04h, 04h

		db	03h, 03h, 03h, 03h, 05h, 05h, 05h, 05h		; A
		db	04h, 04h, 05h, 05h, 05h, 05h, 05h, 05h

		db	03h, 03h, 03h, 03h, 03h, 03h, 03h, 03h		; B
		db	03h, 03h, 03h, 03h, 03h, 03h, 03h, 03h

		db	02h, 02h, 03h, 03h, 03h, 03h, 03h, 03h		; C
		db	05h, 05h, 03h, 03h, 03h, 03h, 04h, 04h

		db	02h, 02h, 02h, 02h, 03h, 03h, 02h, 04h		; D
		db	03h, 03h, 03h, 03h, 03h, 03h, 03h, 03h

		db	06h, 05h, 04h, 04h, 02h, 02h, 03h, 03h		; E
		db	04h, 03h, 03h, 03h, 02h, 02h, 03h, 03h

		db	04h, 02h, 05h, 03h, 03h, 03h, 02h, 02h		; F
		db	03h, 03h, 03h, 03h, 03h, 03h, 02h, 02h

system_table	db	80h,  80h,  80h,  80h,  00h,  00h,  00h,  00h	; 0
		db	80h,  80h,  80h,  80h,  00h,  00h,  00h,  00h

		db	80h,  80h,  80h,  80h,  00h,  00h,  00h,  00h	; 1
		db	80h,  80h,  80h,  80h,  00h,  00h,  00h,  00h

		db	80h,  80h,  80h,  80h,  00h,  00h,  84h,  00h	; 2
		db	80h,  80h,  80h,  80h,  00h,  00h,  84h,  00h

		db	80h,  80h,  80h,  80h,  00h,  00h,  84h,  00h	; 3
		db	80h,  80h,  80h,  80h,  00h,  00h,  84h,  00h

		db	00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h	; 4
		db	00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h

		db	00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h	; 5
		db	00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h

		db	00h,  00h, 0C0h,  80h,  84h,  84h,  80h,  80h	; 6
		db	00h, 0A0h,  00h, 0A0h,  10h,  18h,  10h,  18h

		db	00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h	; 7
		db	00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h

		db	88h,  88h,  88h,  88h,  80h,  80h,  80h,  80h	; 8
		db	80h,  80h,  80h,  80h,  80h,  80h,  80h,  80h

		db	00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h	; 9
		db	00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h

		db	82h,  82h,  82h,  82h,  10h,  18h,  10h,  18h	; A
		db	00h,  00h,  10h,  18h,  10h,  18h,  10h,  18h

		db	00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h	; B
		db	00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h

		db	88h,  88h,  00h,  00h,  80h,  80h,  80h,  80h	; C
		db	00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h

		db	88h,  88h,  88h,  88h,  00h,  00h,  00h,  00h	; D
		db	00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h

		db	00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h	; E
		db	00h,  00h,  00h,  00h,  00h,  00h,  00h,  00h

		db	00h,  00h,  00h,  00h,  00h,  00h,  88h,  88h	; F
		db	00h,  00h,  00h,  00h,  00h,  00h,  88h,  88h


;	           ***  Структура байта - кодировщика  ***
;
;	┌───┬───┬───┬───┬───┬───┬───┬───┐
;	│ 7 │ 6 │ 5 │ 4 │ 3 │ 2 │ 1 │ 0 │
;	└─╥─┴─╥─┴─╥─┴─╥─┴─╥─┴─╥─┴─╥─┴─╥─┘
;         ║   ║   ║   ║   ║   ║   ║   ║
;         ║   ║   ║   ║   ║   ║   ║   ╚════>
;         ║   ║   ║   ║   ║   ║   ╚════════> Только с памятью
;         ║   ║   ║   ║   ║   ╚════════════> Переключатель режима
;         ║   ║   ║   ║   ╚════════════════> Операция с расширенным кодом
;         ║   ║   ║   ╚════════════════════> Возможна комбинация с rep
;         ║   ║   ╚════════════════════════> Не определять типа операции
;         ║   ╚════════════════════════════> dword ptr используется в команде
;         ╚════════════════════════════════> Возможна смена сегмента


offset_arop_1	dw	00fh, 153h, 00ch, 1b9h, 012h, 246h, 265h, 049h
length_arop_1	db	03h,  02h,  03h,  03h,  03h,  03h,  03h,  03h
system_arop_1	db	80h,  80h,  80h,  80h,  80h,  80h,  80h,  80h

offset_arop_2	dw	00fh, 153h, 00ch, 1b9h, 012h, 246h, 265h, 049h
length_arop_2	db	03h,  02h,  03h,  03h,  03h,  03h,  03h,  03h
system_arop_2	db	80h,  80h,  80h,  80h,  80h,  80h,  80h,  80h

offset_shift	dw	19ch, 19fh, 196h, 199h, 1b0h, 1b6h, 268h, 1b3h
length_shift	db	03h,  03h,  03h,  03h,  03h,  03h,  02h,  03h
system_shift	db	80h,  80h,  80h,  80h,  80h,  80h,  00h,  80h

offset_group_1	dw	249h, 268h, 150h, 14ah, 147h, 081h, 06bh, 07dh
length_group_1	db	04h,  02h,  03h,  03h,  03h,  04h,  03h,  04h
system_group_1	db	80h,  00h,  80h,  80h,  80h,  80h,  80h,  80h

offset_group_2	dw	087h, 068h, 268h, 268h, 268h, 268h, 268h, 268h
length_group_2	db	03h,  03h,  02h,  02h,  02h,  02h,  02h,  02h
system_group_2	db	80h,  80h,  00h,  00h,  00h,  00h,  00h,  00h

offset_group_3	dw	087h, 068h, 02fh, 02fh, 0a6h, 0a6h, 17ch, 268h
length_group_3	db	03h,  03h,  04h,  04h,  03h,  03h,  04h,  02h
system_group_3	db	80h,  80h,  80h,  80h,  80h,  80h,  80h,  00h


offset_calling	dw	offset code_00h, offset code_01h
		dw	offset code_02h, offset code_03h
		dw	offset code_04h, offset code_05h
		dw	offset code_06h, offset code_07h
		dw	offset code_00h, offset code_01h
		dw	offset code_02h, offset code_03h
		dw	offset code_04h, offset code_05h
		dw	offset code_0eh, offset code_0fh

		dw	offset code_00h, offset code_01h
		dw	offset code_02h, offset code_03h
		dw	offset code_04h, offset code_05h
		dw	offset code_16h, offset code_17h
		dw	offset code_00h, offset code_01h
		dw	offset code_02h, offset code_03h
		dw	offset code_04h, offset code_05h
		dw	offset code_1eh, offset code_1fh

		dw	offset code_00h, offset code_01h
		dw	offset code_02h, offset code_03h
		dw	offset code_04h, offset code_05h
		dw	offset code_26h, offset code_27h
		dw	offset code_00h, offset code_01h
		dw	offset code_02h, offset code_03h
		dw	offset code_04h, offset code_05h
		dw	offset code_2eh, offset code_27h

		dw	offset code_00h, offset code_01h
		dw	offset code_02h, offset code_03h
		dw	offset code_04h, offset code_05h
		dw	offset code_36h, offset code_27h
		dw	offset code_00h, offset code_01h
		dw	offset code_02h, offset code_03h
		dw	offset code_04h, offset code_05h
		dw	offset code_3eh, offset code_27h

		dw	offset code_40h, offset code_41h
		dw	offset code_42h, offset code_43h
		dw	offset code_44h, offset code_45h
		dw	offset code_46h, offset code_47h
		dw	offset code_40h, offset code_41h
		dw	offset code_42h, offset code_43h
		dw	offset code_44h, offset code_45h
		dw	offset code_46h, offset code_47h

		dw	offset code_40h, offset code_41h
		dw	offset code_42h, offset code_43h
		dw	offset code_44h, offset code_45h
		dw	offset code_46h, offset code_47h
		dw	offset code_40h, offset code_41h
		dw	offset code_42h, offset code_43h
		dw	offset code_44h, offset code_45h
		dw	offset code_46h, offset code_47h

		dw	offset code_60h, offset code_61h
		dw	offset code_03h, offset code_01h
		dw	offset code_64h, offset code_65h
		dw	offset code_66h, offset code_67h
		dw	offset code_68h, offset code_69h
		dw	offset code_6ah, offset code_6bh
		dw	offset code_27h, offset code_6dh
		dw	offset code_27h, offset code_6fh

		dw	offset code_70h, offset code_70h
		dw	offset code_70h, offset code_70h
		dw	offset code_70h, offset code_70h
		dw	offset code_70h, offset code_70h
		dw	offset code_70h, offset code_70h
		dw	offset code_70h, offset code_70h
		dw	offset code_70h, offset code_70h
		dw	offset code_70h, offset code_70h

		dw	offset code_80h, offset code_81h
		dw	offset code_82h, offset code_83h
		dw	offset code_00h, offset code_01h
		dw	offset code_00h, offset code_01h
		dw	offset code_00h, offset code_01h
		dw	offset code_02h, offset code_03h
		dw	offset code_8ch, offset code_8dh
		dw	offset code_8eh, offset code_8fh

		dw	offset code_27h, offset code_91h
		dw	offset code_91h, offset code_91h
		dw	offset code_91h, offset code_91h
		dw	offset code_91h, offset code_91h
		dw	offset code_98h, offset code_99h
		dw	offset code_9ah, offset code_27h
		dw	offset code_9ch, offset code_9dh
		dw	offset code_27h, offset code_27h

		dw	offset code_a0h, offset code_a1h
		dw	offset code_a2h, offset code_a3h
		dw	offset code_27h, offset code_a5h
		dw	offset code_27h, offset code_a5h
		dw	offset code_04h, offset code_05h
		dw	offset code_27h, offset code_a5h
		dw	offset code_27h, offset code_a5h
		dw	offset code_27h, offset code_a5h

		dw	offset code_b0h, offset code_b0h
		dw	offset code_b0h, offset code_b0h
		dw	offset code_b0h, offset code_b0h
		dw	offset code_b0h, offset code_b0h
		dw	offset code_b8h, offset code_b8h
		dw	offset code_b8h, offset code_b8h
		dw	offset code_b8h, offset code_b8h
		dw	offset code_b8h, offset code_b8h

		dw	offset code_c0h, offset code_c1h
		dw	offset code_c2h, offset code_c3h
		dw	offset code_8dh, offset code_8dh
		dw	offset code_c6h, offset code_c7h
		dw	offset code_c8h, offset code_27h
		dw	offset code_cah, offset code_cbh
		dw	offset code_cdh, offset code_cdh
		dw	offset code_27h, offset code_cfh

		dw	offset code_d0h, offset code_d1h
		dw	offset code_d2h, offset code_d3h
		dw	offset code_d4h, offset code_d4h
		dw	offset code_d6h, offset code_27h
		dw	offset code_d8h, offset code_d8h
		dw	offset code_d8h, offset code_d8h
		dw	offset code_d8h, offset code_d8h
		dw	offset code_d8h, offset code_d8h

		dw	offset code_70h, offset code_70h
		dw	offset code_70h, offset code_70h
		dw	offset code_e4h, offset code_e4h
		dw	offset code_e6h, offset code_e6h
		dw	offset code_e8h, offset code_e8h
		dw	offset code_9ah, offset code_70h
		dw	offset code_ech, offset code_ech
		dw	offset code_eeh, offset code_eeh

		dw	offset code_27h, offset code_d6h
		dw	offset code_f2h, offset code_f2h
		dw	offset code_27h, offset code_27h
		dw	offset code_f6h, offset code_f7h
		dw	offset code_27h, offset code_27h
		dw	offset code_27h, offset code_27h
		dw	offset code_27h, offset code_27h
		dw	offset code_feh, offset code_ffh

command_regist	db	'al', 'cl', 'dl', 'bl', 'ah', 'ch', 'dh', 'bh'
		db	'ax', 'cx', 'dx', 'bx', 'sp', 'bp', 'si', 'di'
com_386_regist	db	'eax', 'ecx', 'edx', 'ebx'
		db	'esp', 'ebp', 'esi', 'edi'
segment_regist	db	'ds', 'cs', 'ss', 'es', 'fs', 'gs'

mod_rm_symbol	db	'ds:[bx+si]', 'ds:[bx+di]', 'ss:[bp+si]'
		db	'ss:[bp+di]', 'ds:[si]', 'ds:[di]'
		db	'ds:[0000h]', 'ds:[bx]'
		db	'ds:[bx+si+00h]', 'ds:[bx+di+00h]'
		db	'ss:[bp+si+00h]', 'ss:[bp+di+00h]'
		db	'ds:[si+00h]', 'ds:[di+00h]', 'ss:[bp+00h]'
		db	'ds:[bx+00h]'
		db	'ds:[bx+si+0000h]', 'ds:[bx+di+0000h]'
		db	'ss:[bp+si+0000h]', 'ss:[bp+di+0000h]'
		db	'ds:[si+0000h]', 'ds:[di+0000h]'
		db	'ss:[bp+0000h]', 'ds:[bx+0000h]'

mod_rm_offset	dw	0, 10, 20, 30, 40, 47, 54, 64
		dw	71, 85, 99, 113, 127, 138, 149, 160
		dw	171, 187, 203, 219, 235, 248, 261, 274

mod_rm_length	db	10, 10, 10, 10, 7, 7, 10, 7
		db	14, 14, 14, 14, 11, 11, 11, 11
		db	16, 16, 16, 16, 13, 13, 13, 13

mod_386_symbol	db	'ds:[eax]', 'ds:[ecx]', 'ds:[edx]', 'ds:[ebx]'
		db	'sib', 'ds:[00000000h]', 'ds:[esi]', 'ds:[edi]'
		db	'ds:[eax+00h]', 'ds:[ecx+00h]', 'ds:[edx+00h]'
		db	'ds:[ebx+00h]', 'sib'
		db	'ss:[ebp+00h]', 'ds:[esi+00h]', 'ds:[edi+00h]'
		db	'ds:[eax+00000000h]', 'ds:[ecx+00000000h]'
		db	'ds:[edx+00000000h]', 'ds:[ebx+00000000h]', 'sib'
		db	'ss:[ebp+00000000h]', 'ds:[esi+00000000h]'
		db	'ds:[edi+00000000h]'

mod_386_offset	dw	0, 8, 16, 24, 32, 35, 49, 57
		dw	65, 77, 89, 101, 113, 116, 128, 140
		dw	152, 170, 188, 206, 224, 227, 245, 263

mod_386_length	db	8, 8, 8, 8, 3, 14, 8, 8
		db	12, 12, 12, 12, 3, 12, 12, 12
		db	18, 18, 18, 18, 3, 18, 18, 18

mod_sib_symbol	db	'ds:[xxx*0h+eax]', 'ds:[xxx*0h+ecx]'
		db	'ds:[xxx*0h+edx]', 'ds:[ebx+xxx*0h]'
		db	'ds:[xxx*0h+esp]', 'ds:[xxx*0h+00000000h]'
		db	'ds:[xxx*0h+esi]', 'ds:[xxx*0h+edi]'
		db	'ds:[xxx*0h+eax+00h]', 'ds:[xxx*0h+ecx+00h]'
		db	'ds:[xxx*0h+edx+00h]', 'ds:[xxx*0h+ebx+00h]'
		db	'ds:[xxx*0h+esp+00h]', 'ds:[xxx*0h+ebp+00h]'
		db	'ds:[xxx*0h+esi+00h]', 'ds:[xxx*0h+edi+00h]'
		db	'ds:[xxx*0h+eax+00000000h]'
		db	'ds:[xxx*0h+ecx+00000000h]'
		db	'ds:[xxx*0h+edx+00000000h]'
		db	'ds:[xxx*0h+ebx+00000000h]'
		db	'ds:[xxx*0h+esp+00000000h]'
		db	'ds:[xxx*0h+ebp+00000000h]'
		db	'ds:[xxx*0h+esi+00000000h]'
		db	'ds:[xxx*0h+edi+00000000h]'

mod_sib_offset	dw	0, 15, 30, 45, 60, 75, 96, 111
		dw	126, 145, 164, 183, 202, 221, 240, 259
		dw	278, 303, 328, 353, 378, 403, 428, 453

mod_sib_length	db	15, 15, 15, 15, 15, 21, 15, 15
		db	19, 19, 19, 19, 19, 19, 19, 19
		db	25, 25, 25, 25, 25, 25, 25, 25

byte_poz	db	'byte ptr'
word_poz	db	'word ptr'
dword_poz	db	'dword ptr'

string		db	80 dup (0)

adress		db	4 dup (0)		; хранится текущий адрес
cur_adress	db	4 dup (0)		; для расчета jmp - смещений
off_string	db	4 dup (0)		; для строки - смещения

byte_word	db	0			; 1 = байт, 2 = слово
off_code	db	0			; 1 = байт, 2 = слово
cpu_mode_1	db	0			; 1 = 32
cpu_mode_2	db	0			; 1 = 32

yes_sib		db	0			; расширенный байт sib

h_add		db	0			; число байт в команде

new_segment	dw	00			; смещение нового сегмента

dis_cpu		proc	near

		push	ax
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		call	clear			; очистка буфера
		call	gen_adr			; генерация адреса
		call	str_adr			; преобразование адреса
		call	dis_asm			; дизассемблирование команды
		pop	ds
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	ax
		retn

dis_cpu		endp

;                       ***  Очистка буфера строки  ***

clear		proc	near

		mov	cx,40			; длина строки
		mov	di, offset string
		xor	ax,ax			; очистка нулями
		push	es
		push	ds
		pop	es
		cld
		rep	stosw
		pop	es
		mov	byte ptr ds:[off_code], 0
		mov	byte ptr ds:[yes_sib], 0
		xor	ax,ax
		mov	al, byte ptr ds:[h_add]	; число байт в команде
		add	bx,ax			; получим новое смещение
		retn

clear		endp

;                     ***  Генерация адреса строки  ***

gen_adr		proc	near

		mov	si, offset adress
		add	si,3			; младший разряд адреса
		mov	cx,4			; всего восемь разрядов
		mov	al, byte ptr ds:[h_add]	; добавим число байт
raz_loop:
		add	byte ptr ds:[si], al	; предыдущей команды
		cmp	byte ptr ds:[si], 0fh	; переполнение ?
		jbe	not_razr_corr		; нет ==> без коррекции
		xor	ax,ax
		sub	byte ptr ds:[si], 10h
		dec	si			; откорректируем старший
		mov	al,1
		loop	raz_loop		; и так до конца
not_razr_corr:
		retn

gen_adr		endp

;                 ***  Преобразование адреса в строку  ***

str_adr		proc	near

		mov	cx,4			; преобразуем 8 байт
		mov	si, offset adress	; отсюда берем,
		mov	di, offset string	; а сюда заносим
str_loop:
		mov	al, byte ptr ds:[si]	; байт адреса
		cmp	al,9			; это цифра ?
		jbe	cifra			; да ==> перейдем
		add	al,7			; скорректируем 
cifra:
		add	al,30h			; добавим символ нуля
		mov	byte ptr ds:[di], al	; получим ASCII - код
		inc	si
		inc	di
		loop	str_loop		; и так до конца
		retn

str_adr		endp

;                     ***  Дизассемблирование команды  ***

dis_asm		proc	near

		xor	ax,ax
		mov	al, byte ptr es:[bx]	; al = байт кода
		push	ax			; ==> сохраним смещение кода
		shl	ax,1			; смещение в таблице слов !
		mov	si, offset offset_table	; получим смещение
		add	si,ax			; в таблице смещений
		mov	dx, word ptr ds:[si]
		mov	si, offset offset_calling	; смещение в таблице
		add	si,ax				; обработки
		mov	ax, word ptr ds:[si]
		xchg	ax,dx
		mov	si, offset command_symbol	; получим смещение на
		add	si,ax				; машинную инструкцию
		pop	ax
		push	si			; ==> сохраним на стеке
		mov	si, offset length_table
		add	si,ax			; выберем длину для
		xor	cx,cx			; пересылки
		mov	cl, byte ptr ds:[si]
		mov	si, offset system_table
		add	si,ax			; системная информация
		xor	ax,ax
		mov	al, byte ptr ds:[si]
		pop	si			; <== выборка смещения
		xchg	ax,dx
		mov	byte ptr ds:[h_add], 1	; пока длина команды = 1
		call	ax
		retn

dis_asm		endp



;             ***  Обработка типов  Rm / R8  и  Rm / R16  ***

this_rm_r8_r16	proc	near

		call	operation_type
		jz	op_with_regs		; да ==> обработаем отдельно
		call	mnemo_calling
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di			; новый адрес для вывода
		call	form_register		; формируем регистр
		retn				; вернемся из процедуры
op_with_regs:
		call	write_mnemo		; формируем мнемокоманду
		call	reg_addition
		call	form_register		; запись второго регистра
		retn				; вернемся из процедуры

this_rm_r8_r16	endp

;                     ***  Определяет тип операции  ***

operation_type	proc	near

		call	byte_or_word		; определяем тип операции
		call	memory_or_regs		; работаем с регистрами ?
		retn

operation_type	endp

;                    ***  Определение типа операции  ***

byte_or_word	proc	near

		cmp	ah,2
		jz	ok_word
		mov	byte ptr ds:[byte_word], 1	; операция с байтами
		jmp	short  ok_begin
ok_word:
		mov	byte ptr ds:[byte_word], 2	; операция со словами
ok_begin:
		and	dx,40h
		cmp	dx,40h
		jnz	no_dword_op
		mov	byte ptr ds:[byte_word], 3
no_dword_op:
		inc	byte ptr ds:[h_add]		; команда ==> 2 байта
		retn

byte_or_word	endp

;                 ***  Определим, с чем будет операция  ***

memory_or_regs	proc	near

		xor	ax,ax
		mov	al,byte ptr es:[bx+1]	; возьмем второй байт
		push	ax
		and	al,11000000b
		cmp	al,192			; операция с регистрами ?
		pop	ax
		retn

memory_or_regs	endp

;                    ***  Вывод мнемоники команды  ***

mnemo_calling	proc	near

		call	memory_cost		; выборка смещений
		call	write_mnemo		; формируем мнемокоманду
		call	form_memory		; формируем операции с памятью
		mov	di,27			; адрес для вывода
		call	ins_mem_reg		; вставим первую половину
		call	plus_offset		; добавим смещения
		retn

mnemo_calling	endp

;                  ***  Определение довеска смещения  ***

memory_cost	proc	near

		cmp	byte ptr ds:[cpu_mode_2], 1
		jz	d32_operation
		push	ax
		and	al,11000111b		; выделим операцию с памятью
		cmp	al,6			; DS : [d16] ?
		jnz	not_in_first		; нет ==> проверим дальше
		add	byte ptr ds:[h_add], 2	; будет еще слово
		mov	byte ptr ds:[off_code], 2	; которое надо выбрать
		pop	ax
		jmp	short  bits_find
not_in_first:
		pop	ax
		push	ax
		and	al,11000000b		; выделим операцию с памятью
		cmp	al,64			; SEG : [REG + d8] ?
		jnz	not_in_second		; нет ==> проверим дальше
		inc	byte ptr ds:[h_add]	; будет еще байт
		mov	byte ptr ds:[off_code], 1	; необходимо выбрать
		pop	ax
		jmp	short  bits_find
not_in_second:
		cmp	al,128			; SEG : [REG + d16] ?
		jnz	not_in_third		; нет ==> значит смещений нет
		add	byte ptr ds:[h_add], 2	; будет еще слово
		mov	byte ptr ds:[off_code], 2	; необходимо выбрать
		pop	ax
		jmp	short  bits_find
not_in_third:
		mov	byte ptr ds:[off_code], 0	; выбирать ничего
		pop	ax
bits_find:
		retn

d32_operation:
		push	ax
		and	al,11000111b		; выделим операцию с памятью
		cmp	al,4			; sib присутствует ?
		jz	look_386_sib
		cmp	al,68
		jz	look_386_sib
		cmp	al,132
		jz	look_386_sib
		cmp	al,5			; DS : [d32] ?
		jnz	not_386_first		; нет ==> проверим дальше
		add	byte ptr ds:[h_add], 4	; будет еще 2 слова
		mov	byte ptr ds:[off_code], 4	; которые надо выбрать
		pop	ax
		jmp	short  bits_find
not_386_first:
		pop	ax
		push	ax
sib_lock:
		pop	ax
		push	ax
		and	al,11000000b		; выделим операцию с памятью
		cmp	al,64			; SEG : [REG + d8] ?
		jnz	not_386_second		; нет ==> проверим дальше
		inc	byte ptr ds:[h_add]	; будет еще байт
		mov	byte ptr ds:[off_code], 1	; необходимо выбрать
		pop	ax
		jmp	short  bits_find
not_386_second:
		cmp	al,128			; SEG : [REG + d32] ?
		jnz	not_386_third		; нет ==> значит смещений нет
		add	byte ptr ds:[h_add], 4	; будет еще 2 слова
		mov	byte ptr ds:[off_code], 4	; необходимо выбрать
		pop	ax
		jmp	short  bits_find
not_386_third:
		mov	byte ptr ds:[off_code], 0	; выбирать ничего
		pop	ax
		jmp	short	bits_find
look_386_sib:
		inc	byte ptr ds:[h_add]	; расширенный байт
		mov	byte ptr ds:[yes_sib], 1
		mov	al, byte ptr es:[bx+2]
		push	ax
		and	al,00000111b		; проверка на расширенные
		cmp	al,5			; таблицы
		pop	ax
		jnz	sib_lock
		add	byte ptr ds:[h_add], 4	; будет еще 2 слова
		mov	byte ptr ds:[off_code], 4	; необходимо выбрать
		pop	ax
		jmp	short	bits_find

memory_cost	endp

;                 ***  Вывод мнемоники команды в буфер  ***

write_mnemo	proc	near

		push	ax
		push	es
		cmp	byte ptr ds:[cpu_mode_1], 1
		jz	mode_66_problem
		cmp	byte ptr ds:[cpu_mode_2], 1
		jz	mode_67_problem
		cmp	word ptr ds:[new_segment], 0000h
		jz	not_segm_problem	; сегмент не меняется
write_lock:
		inc	byte ptr ds:[h_add]	; команда стала больше
		dec	bx			; на один байт
		call	translate		; выводим код
		inc	bx			; как будто ничего не было
		jmp	short  make_instruction
not_segm_problem:
		call	translate		; выводим код, затем
make_instruction:
		push	cs
		pop	es
		call	ins_instruct		; мнемонику команды
		pop	es
		pop	ax
		retn

mode_66_problem:
		cmp	byte ptr ds:[cpu_mode_2], 1
		jz	mode_@@_problem
		cmp	word ptr ds:[new_segment], 0000h
		jnz	segment_@@_problem
		jmp	short	write_lock
mode_@@_problem:
		cmp	word ptr ds:[new_segment], 0000h
		jnz	segment_@@@_problem
segment_@@_problem:
		add	byte ptr ds:[h_add], 2	; команда стала больше
		dec	bx
		dec	bx
		call	translate		; выводим код
		inc	bx			; как будто ничего не было
		inc	bx
		jmp	short  make_instruction
segment_@@@_problem:
		add	byte ptr ds:[h_add], 3	; команда стала больше
		dec	bx
		dec	bx
		dec	bx
		call	translate		; выводим код
		inc	bx			; как будто ничего не было
		inc	bx
		inc	bx
		jmp	short  make_instruction

mode_67_problem:
		cmp	word ptr ds:[new_segment], 0000h
		jnz	segment_@@_problem
		jmp	short	write_lock

write_mnemo	endp

;                  ***  Вставка машинного кода команды  ***

translate	proc	near

		push	bx
		push	cx
		push	si
		xor	ax,ax
		mov	al, byte ptr ds:[h_add]	; получим число байт
		mov	cx,ax
		cmp	cx,7
		jbe	continue_translate
		mov	cx,7
continue_translate:
		mov	si, offset string
		add	si,6			; вставляем с 12-й позиции
code_loop:
		xor	ax,ax
		mov	al, byte ptr es:[bx]	; получим байт
		call	conv_to_hex		; затем в 16-ричный формат
		inc	bx
		add	si,4			; теперь следующий байт
		loop	code_loop		; и так, пока не кончатся
		xor	ax,ax
		mov	al, byte ptr ds:[h_add]	; получим число байт
		cmp	ax,7
		jbe	exit_translate
		dec	si
		mov	word ptr ds:[si], '>-'	; выход за границу
exit_translate:
		pop	si
		pop	cx
		pop	bx
		retn

translate	endp

;                ***  Преобразование байта в строку  ***

conv_to_hex	proc	near

		push	cx			; ax = байт
		push	dx			; si = смещение конца строки
		push	di
		mov	cx,2			; преобразуем 1 байт
		mov	di,10h			; путем деления на 16
conv_loop:
		xor	dx,dx			; с вычислением остатка
		div	di
		cmp	dl,9			; получили цифру ?
		jbe	conv_cif		; да ==> прейдем
		add	dl,7			; скорректируем
conv_cif:
		add	dl,30h			; добавим символ 'нуля'
		mov	byte ptr ds:[si], dl	; сохраним ASCII - код
		dec	si
		loop	conv_loop		; и так до конца
		pop	di
		pop	dx
		pop	cx
		retn

conv_to_hex	endp

;                    ***  Вставка машинной инструкции  ***

ins_instruct	proc	near

		push	di
		mov	di, offset string
		add	di,20			; вычислим смещение
		cld				; сбросим флаг направления
		rep	movsb			; перешлем байты
		pop	di
		retn

ins_instruct	endp

;                  ***  Формируем операцию с памятью  ***

form_memory	proc	near

		push	ax
		mov	cl,6
		clc
		shr	al,cl			; выделим старшую часть
		mov	cx,8
		mul	cx			; сделаем как старшие биты
		pop	cx
		and	cl,00000111b		; выделим младшую часть
		add	ax,cx			; получим полное смещение
		cmp	byte ptr ds:[cpu_mode_2], 1
		jz	without_sib
		mov	si, offset mod_rm_length
		add	si,ax			; выставим смещение на длину
		mov	cl, byte ptr ds:[si]	; cx = длина mod r/m строки
		shl	ax,1			; преобразуем для слов
		mov	si, offset mod_rm_offset
		add	si,ax			; получим смещение на смещение
		mov	ax, word ptr ds:[si]
		mov	si, offset mod_rm_symbol
		add	si,ax			; теперь смещение на символ
		retn

without_sib:
		cmp	cl,4
		jz	form_sib_present
		mov	si, offset mod_386_length
		add	si,ax			; выставим смещение на длину
		mov	cl, byte ptr ds:[si]	; cx = длина mod r/m строки
		shl	ax,1			; преобразуем для слов
		mov	si, offset mod_386_offset
		add	si,ax			; получим смещение на смещение
		mov	ax, word ptr ds:[si]
		mov	si, offset mod_386_symbol
		add	si,ax			; теперь смещение на символ
		retn

form_sib_present:
		mov	al, byte ptr es:[bx+1]
		mov	cl,6
		clc
		shr	al,cl			; выделим старшую часть
		mov	cx,8
		mul	cx			; сделаем как старшие биты
		xor	cx,cx
		mov	cl, byte ptr es:[bx+2]
		and	cl,00000111b		; выделим младшую часть
		add	ax,cx			; получим полное смещение
		mov	si, offset mod_sib_length
		add	si,ax			; выставим смещение на длину
		mov	cl, byte ptr ds:[si]	; cx = длина mod r/m строки
		shl	ax,1			; преобразуем для слов
		mov	si, offset mod_sib_offset
		add	si,ax			; получим смещение на смещение
		mov	ax, word ptr ds:[si]
		mov	si, offset mod_sib_symbol
		add	si,ax			; теперь смещение на символ
		retn

form_memory	endp

;                    ***  Вставка операций с памятью  ***

ins_mem_reg	proc	near

		push	es
		push	cx
		push	si
		xor	ax,ax
		mov	al, byte ptr es:[bx]
		mov	si, offset system_table
		add	si,ax
		mov	al, byte ptr ds:[si]
		and	al,20h
		push	cs
		pop	es
		add	di, offset string	; формируем позицию вывода
		cmp	byte ptr ds:[cpu_mode_2], 1
		jz	d32_detect
		cmp	byte ptr ds:[byte_word], 3
		jz	this_dword
		cmp	byte ptr ds:[byte_word], 2	; операция словами ?
		jz	this_word			; другое смещение
		mov	si, offset byte_poz		; оперируем с байтами
		jmp	short  b_w_insert
this_dword:
		mov	si, offset dword_poz
		cmp	al,20h
		jz	d32_detect
		mov	cx,9
		cld
		rep	movsb			; пересылка 'dword ptr'
		jmp	short  after_detect
this_word:
		mov	si, offset word_poz	; оперируем со словами
b_w_insert:
		cmp	al,20h
		jz	d32_detect
		mov	cx,8			; пересылка 8 байт сообщения
		cld				; сброс флага направления
		rep	movsb			; пересылка byte/word
after_detect:
		inc	di
d32_detect:
		pop	si
		pop	cx
		mov	dx,di			; сохраним позицию пересылки
		cld				; сброс флага направления
		rep	movsb			; пересылка операции с памятью
		cmp	word ptr ds:[new_segment], 0000h
		jz	leave_segm_alone	; сегмент не корректируем
		mov	ax, word ptr ds:[new_segment]
		mov	si, offset segment_regist
		add	si,ax			; получили смещение на вход
		push	cs
		pop	es
		xchg	dx,di			; формируем смещение на выход
		movsb				; пересылка
		dec	di
		xchg	dx,di
leave_segm_alone:
		cmp	byte ptr ds:[yes_sib], 1
		jnz	no_386_index
		pop	es
		push	es
		xor	ax,ax
		mov	al, byte ptr es:[bx+2]
		push	ax
		and	al,00111000b
		mov	cl,3
		clc
		shr	al,cl
		cmp	al,4
		jz	no_index_reg
		mov	cx,3
		push	dx
		mul	cx
		pop	dx
		mov	si, offset com_386_regist
		add	si,ax
		xchg	dx,di
		add	di,4
		push	cs
		pop	es
		mov	cx,3
		cld
		rep	movsb
		sub	di,7
		xchg	dx,di
		jmp	short	f_mul
no_index_reg:
		xchg	dx,di
		add	di,4
		mov	word ptr ds:[di], '00'
		mov	byte ptr ds:[di+2], 'h'
		sub	di,4
		xchg	dx,di
f_mul:
		pop	ax
		and	al,11000000b
		mov	cl,6
		clc
		shr	al,cl
		xchg	al,cl
		mov	ax,1
		clc
		shl	al,cl
		add	al,30h
		xchg	dx,di
		add	di,8
		mov	byte ptr ds:[di], al
		sub	di,8
		xchg	dx,di
no_386_index:
		pop	es
		retn

ins_mem_reg	endp

;                        ***  Выборка смещений  ***

plus_offset	proc	near

		cmp	byte ptr ds:[off_code], 0	; выбирать нечего ?
		jz	not_take_offset			; не надо ==> не будем
		mov	si,di
		sub	si,3			; выбирать сюда
		cmp	byte ptr ds:[off_code], 4
		jz	take_offset_dword
		cmp	byte ptr ds:[off_code], 2
		jz	take_offset_word
		xor	ax,ax
		mov	al, byte ptr es:[bx+2]	; выберем первый байт
		cmp	byte ptr ds:[yes_sib], 0
		jz	no_@_sib_corr
		mov	al, byte ptr es:[bx+3]
no_@_sib_corr:
		cmp	byte ptr ds:[si-2], '+'
		jnz	no_convert
		test	al,80h
		jz	no_convert
		neg	al
		mov	byte ptr ds:[si-2], '-'
no_convert:
		call	conv_to_hex		; преобразуем в строку
		jmp	short  not_take_offset
take_offset_word:
		mov	ax, word ptr es:[bx+2]	; выберем первый байт
		cmp	byte ptr ds:[yes_sib], 0
		jz	no_@@_sib_corr
		mov	ax, word ptr es:[bx+3]
no_@@_sib_corr:
		cmp	byte ptr ds:[si-4], '+'
		jnz	no_convertw
		test	ax,8000h
		jz	no_convertw
		neg	ax
		mov	byte ptr ds:[si-4], '-'
no_convertw:
		push	ax
		xor	ah,ah
		call	conv_to_hex
		pop	ax
		xchg	ah,al
		xor	ah,ah
		call	conv_to_hex
not_take_offset:
		retn
take_offset_dword:
		cmp	byte ptr ds:[yes_sib], 1
		jz	take_offset_plus
		mov	ax, word ptr es:[bx+2]	; выберем первый байт
		push	ax
		xor	ah,ah
		call	conv_to_hex
		pop	ax
		xchg	ah,al
		xor	ah,ah
		call	conv_to_hex
		mov	ax, word ptr es:[bx+4]	; выберем второй байт
		push	ax
		xor	ah,ah
		call	conv_to_hex
		pop	ax
		xchg	ah,al
		xor	ah,ah
		call	conv_to_hex
		jmp	short	not_take_offset
take_offset_plus:
		mov	byte ptr ds:[yes_sib], 0
		inc	byte ptr ds:[off_code]
		mov	ax, word ptr es:[bx+3]	; выберем первый байт
		push	ax
		xor	ah,ah
		call	conv_to_hex
		pop	ax
		xchg	ah,al
		xor	ah,ah
		call	conv_to_hex
		mov	ax, word ptr es:[bx+5]	; выберем второй байт
		push	ax
		xor	ah,ah
		call	conv_to_hex
		pop	ax
		xchg	ah,al
		xor	ah,ah
		call	conv_to_hex
		jmp	short	not_take_offset

plus_offset	endp

;          ***  Формируем операцию с регистрами - источниками  ***

form_register	proc	near

		push	ax
		push	si
		cmp	byte ptr ds:[cpu_mode_1], 1
		jz	expand_regist
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; получим второй байт
		and	al,00111000b		; выделим второй операнд
		clc				; сбросим carry - флаг
		shr	ax,1
		shr	ax,1
		cmp	byte ptr ds:[byte_word], 1	; операция с байтами ?
		jz	ok_byte			; да ==> перейдем
		add	ax,16			; скорректируем
ok_byte:
		mov	si, offset command_regist
		add	si,ax			; смещение на второй операнд
		push	es
		push	cs
		pop	es
		cld				; сбросим флаг направления
		movsw				; перешлем
		pop	es
		pop	si
		pop	ax
		retn

expand_regist:
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; получим второй байт
		and	al,00111000b		; выделим второй операнд
		clc				; сбросим carry - флаг
		shr	ax,1
		shr	ax,1
		shr	ax,1
		push	cx
		mov	cx,3
		mul	cx
		mov	si, offset com_386_regist
		add	si,ax			; смещение на второй операнд
		push	es
		push	cs
		pop	es
		mov	cx,3
		cld				; сбросим флаг направления
		rep	movsb			; перешлем
		pop	es
		pop	cx
		pop	si
		pop	ax
		retn

form_register	endp

;                  ***  Вставка регистра - приемника  ***

reg_addition	proc	near

		mov	di,27
		call	insert_register		; запись первого регистра
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di			; новый адрес для вывода
		retn

reg_addition	endp

;                 ***  Вставка регистра - приемника  ***

insert_register	proc	near

		push	ax
		push	si
		add	di, offset string
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; выберем байт
		and	al,00000111b		; выделим первый операнд
		cmp	byte ptr ds:[cpu_mode_2], 1
		jz	change_ins_d32
		clc
		shl	ax,1
		cmp	byte ptr ds:[byte_word], 1	; регистр байтовый ?
		jz	ok_byte_reg			; да ==> перейдем
		add	ax,16			; скорректируем
ok_byte_reg:
		mov	si, offset command_regist
		add	si,ax			; смещение на первый операнд
		push	es
		push	cs
		pop	es
		cld				; сброс флага направления
		movsw				; пересылка
		pop	es
		pop	si
		pop	ax
		retn

change_ins_d32:
		push	cx
		mov	cx,3
		mul	cx
		mov	si, offset com_386_regist
		add	si,ax			; смещение на первый операнд
		push	es
		push	cs
		pop	es
		mov	cx,3
		cld				; сброс флага направления
		rep	movsb			; пересылка
		pop	es
		pop	cx
		pop	si
		pop	ax
		retn

insert_register	endp

;             ***  Обработка типов  R8 / Rm  и  R16 / Rm  ***

this_r8_r16_rm	proc	near

		call	operation_type
		jz	op_with_regis		; да ==> обработаем отдельно
		mov	di, offset string
		add	di,27			; формируем адрес для вывода
		call	form_register		; запись первого регистра
		mov	byte ptr ds:[di], 2ch	; ','
		sub	di, offset string
		inc	di
		call	memo_completed
		retn				; вернемся из процедуры
op_with_regis:
		call	write_mnemo		; формируем мнемокоманду
		mov	di, offset string
		add	di,27			; формируем адрес для вывода
		call	form_register		; запись первого регистра
		mov	byte ptr ds:[di], 2ch	; ','
		sub	di, offset string
		inc	di
		call	insert_register		; запись второго регистра
		retn				; вернемся из процедуры

this_r8_r16_rm	endp

;                  ***  Оформление операций с памятью  ***

memo_completed	proc	near

		call	memory_cost		; выборка смещений
		call	write_mnemo		; формируем мнемокоманду
		call	form_memory		; формируем операции с памятью
		call	ins_mem_reg		; вставим первую половину
		call	plus_offset		; добавим смещения
		retn				; вернемся из процедуры

memo_completed	endp

;               ***  Обработка типов AL,i8 и AX,i16  ***

ali8_axi16	proc	near

		push	cx
		push	si
		push	di
		call	byte_or_word		; определим тип операции
		call	write_al_ax		; вставка регистра и запятой
		mov	si,di
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]		; выберем первый байт
		cmp	byte ptr ds:[cpu_mode_2], 1
		jnz	write_byte_or_word
		add	si,7
		call	conv_to_hex		; преобразуем
		inc	byte ptr ds:[h_add]	; плюс байт
		xor	ax,ax
		mov	al,byte ptr es:[bx+2]	; выберем второй байт
		call	conv_to_hex		; преобразуем
		inc	byte ptr ds:[h_add]	; плюс байт
		xor	ax,ax
		mov	al,byte ptr es:[bx+3]	; выберем третий байт
		call	conv_to_hex		; преобразуем
		inc	byte ptr ds:[h_add]	; плюс байт
		xor	ax,ax
		mov	al,byte ptr es:[bx+4]	; выберем четвертый байт
		call	conv_to_hex		; преобразуем
		add	si,9
		jmp	short	quit_al_ax
write_byte_or_word:
		cmp	byte ptr ds:[byte_word], 2	; выбирать слово ?
		jz	take_word			; да ==> выберем
		inc	si
		call	conv_to_hex		; преобразуем
		add	si,3
		jmp	short  quit_al_ax
take_word:
		add	si,3
		call	conv_to_hex		; преобразуем
		inc	byte ptr ds:[h_add]	; плюс байт
		xor	ax,ax
		mov	al,byte ptr es:[bx+2]	; выберем второй байт
		call	conv_to_hex		; преобразуем
		add	si,5
quit_al_ax:
		mov	byte ptr ds:[si],68h	; 'h'
		pop	di
		pop	si
		pop	cx
		call	write_mnemo		; вывод мнемокоманды
		retn

ali8_axi16	endp

;                       ***  Вставка AL или AX  ***

write_al_ax	proc	near

		cmp	byte ptr ds:[cpu_mode_1], 1
		jz	write_eax
		xor	ax,ax
		cmp	byte ptr ds:[byte_word], 1	; операция с байтами ?
		jz	al_byte				; да ==> перейдем
		add	ax,16				; скорректируем
al_byte:
		mov	si, offset command_regist
		add	si,ax			; смещение на второй операнд
		mov	di, offset string
		add	di,27			; смещение для вывода
		push	es
		push	cs
		pop	es
		cld				; сбросим флаг направления
		movsw				; перешлем
exit_write_al_ax:
		pop	es
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di
		retn

write_eax:
		mov	si, offset com_386_regist
		mov	di, offset string
		add	di,27			; смещение для вывода
		push	es
		push	cx
		push	cs
		pop	es
		mov	cx,3
		cld				; сбросим флаг направления
		rep	movsb			; перешлем
		pop	cx
		jmp	short	exit_write_al_ax

write_al_ax	endp

;               ***  Операции типа PUSH / POP регистр  ***

push_pop_oper	proc	near

		push	dx
		call	write_mnemo		; вывод мнемокоманды
		pop	dx
		cmp	dx,2
		jz	push_pop_d32
		cmp	dx,1
		jz	push_pop_segreg
		mov	si, offset command_regist
		add	si,ax
add_register:
		mov	di, offset string
		add	di,27			; формируем вывод
		push	es
		push	cs
		pop	es
		cld				; сброс флага направления
		movsw				; пересылка
		pop	es
		retn

push_pop_segreg:
		mov	si, offset segment_regist
		add	si,ax
		jmp	short	add_register

push_pop_d32:
		mov	si, offset com_386_regist
		add	si,ax
		mov	di, offset string
		add	di,27			; формируем вывод
		push	es
		push	cs
		pop	es
		mov	cx,3
		cld				; сброс флага направления
		rep	movsb			; пересылка
		pop	es
		retn

push_pop_oper	endp

;                 ***  Здесь обрабатывается команда DB  ***

this_db		proc	near

		call	write_mnemo		; выводим мнемонику команды
		xor	ax,ax
		mov	al, byte ptr es:[bx]	; выбираем байт
		mov	si, offset string
		add	si,29			; формируем смещение
		mov	byte ptr ds:[si], 68h	; дописываем 'h'
		dec	si
		call	conv_to_hex		; преобразовываем в строку
		retn		

this_db		endp

;                 *** Количество байт для  push i16/i32 ***

count_detect	proc	near

		add	byte ptr ds:[h_add], 2
		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	exit_detect_count
		add	byte ptr ds:[h_add], 2
exit_detect_count:
		retn

count_detect	endp

;                  *** Вывод байтов для  push i16/i32 ***

insert_number	proc	near

		cmp	byte ptr ds:[cpu_mode_1], 1
		jz	push_offset_dword
		add	si,3
		mov	ax, word ptr es:[bx+1]	; выберем первый байт
		push	ax
		xor	ah,ah
		call	conv_to_hex
		pop	ax
		xchg	ah,al
		xor	ah,ah
		call	conv_to_hex
		add	si,5
		mov	byte ptr ds:[si], 'h'
		retn
push_offset_dword:
		add	si,7
		mov	ax, word ptr es:[bx+1]	; выберем первый байт
		push	ax
		xor	ah,ah
		call	conv_to_hex
		pop	ax
		xchg	ah,al
		xor	ah,ah
		call	conv_to_hex
		mov	ax, word ptr es:[bx+3]	; выберем второй байт
		push	ax
		xor	ah,ah
		call	conv_to_hex
		pop	ax
		xchg	ah,al
		xor	ah,ah
		call	conv_to_hex
		add	si,9
		mov	byte ptr ds:[si], 'h'
		retn

insert_number	endp

;                      *** Вывод байта для  push i8 ***

insert_byte_num	proc	near

		inc	si
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; выберем первый байт
		call	conv_to_hex
		add	si,3
		mov	byte ptr ds:[si], 'h'
		retn

insert_byte_num	endp

;                   ***  Формирование текущего адреса  ***

form_curr_adr	proc	near

		push	es
		push	cs
		pop	es
		mov	si, offset adress	; просто снимаем копию
		mov	di, offset cur_adress	; текущего адреса для
		mov	cx,4			; дальнейшей его обработки
		cld
		rep	movsb
		pop	es
		retn

form_curr_adr	endp

;                   ***  Формирование нового адреса  ***

form_new_adr	proc	near

		push	ax
		push	ax
		push	dx
		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_d32_1_jmp
		mov	ax,1
		call	convert_offset
		call	plus_byte_word
no_d32_1_jmp:
		cmp	byte ptr ds:[cpu_mode_2], 0
		jz	no_d32_2_jmp
		mov	ax,1
		call	convert_offset
		call	plus_byte_word
no_d32_2_jmp:
		pop	dx
		pop	ax
		cmp	dx,2			; длинный jmp ?
		jz	test_word		; да ==> обработка слов
		and	al,10000000b
		cmp	al,128			; старший бит установлен ?
		pop	ax
		jz	mines_byte		; да ==> прыжок "вверх"
		jmp	short  plus_byte	; иначе ==> прыжок "вниз"
test_word:
		and	ah,10000000b
		cmp	ah,128			; аналогичная проверка,
		pop	ax			; но для длинного jmp
		jz	mines_word
		jmp	short  plus_word
mines_byte:
		push	ax
		mov	si, offset off_string
		mov	word ptr ds:[si], 0000h	; производим коррекцию за
		mov	word ptr ds:[si+2], 0100h ; счет добавления байта
		call	plus_byte_word		; (второй получим за счет not)
		pop	ax
		not	ax
		xor	ah,ah
		call	convert_offset		; преобразуем форматы
		call	minus_byte_word		; прыжок "вверх"
		retn
plus_byte:
		call	convert_offset
		call	plus_byte_word
		mov	si, offset off_string
		mov	word ptr ds:[si], 0000h	; аналогичная коррекция
		mov	word ptr ds:[si+2], 0200h
		call	plus_byte_word		; прыжок "вниз"
		retn
mines_word:
		push	ax
		mov	si, offset off_string
		mov	word ptr ds:[si], 0000h	; коррекция для слов
		mov	word ptr ds:[si+2], 0200h
		call	plus_byte_word
		pop	ax
		not	ax
		call	convert_offset		; преобразуем форматы
		call	minus_byte_word		; прыжок "вверх"
		retn
plus_word:
		call	convert_offset		; преобразуем форматы
		call	plus_byte_word
		mov	si, offset off_string
		mov	word ptr ds:[si], 0000h
		mov	word ptr ds:[si+2], 0300h
		call	plus_byte_word		; прыжок "вниз"
		retn

form_new_adr	endp

;                  ***  Вывод сформированного адреса  ***

write_adress	proc	near

		mov	cx,4			; преобразуем 8 байт
		mov	si, offset cur_adress	; отсюда берем,
		mov	di, offset string	; а сюда заносим
		add	di,27
str_adr_loop:
		mov	al, byte ptr ds:[si]	; байт адреса
		cmp	al,9			; это цифра ?
		jbe	adr_cifra		; да ==> перейдем
		add	al,7			; скорректируем 
adr_cifra:
		add	al,30h			; добавим символ нуля
		mov	byte ptr ds:[di], al	; получим ASCII - код
		inc	si
		inc	di
		loop	str_adr_loop		; и так до конца
		retn

write_adress	endp

;                 ***  Добавление к адресу байта/слова  ***

plus_byte_word	proc	near

		mov	si, offset cur_adress
		add	si,3			; младший разряд адреса
		mov	di, offset off_string
		add	di,3			; младший разряд слагаемого
		xor	ax,ax
raz_adr_loop:
		mov	al, byte ptr ds:[di]	; второе слагаемое
		add	byte ptr ds:[si], al	; сложим
		add	byte ptr ds:[si], ah	; и откорректируем
		cmp	byte ptr ds:[si], 0fh	; переполнение ?
		jbe	plus_razr_corr		; нет ==> без коррекции
		mov	ah,1			; был перенос
		sub	byte ptr ds:[si], 10h	; коррекция младшего разряда
		dec	si			; откорректируем старший
		dec	di
		cmp	di, (offset off_string - 1) ; слагаемое кончилось ?
		jbe	ex_off_add
		jmp	short  raz_adr_loop	; и так до конца
ex_off_add:
		inc	di
		mov	byte ptr ds:[di], 0	; только корректируем
		cmp	si, (offset cur_adress - 1)
		jbe	exit_off		; пока все не откорректируем
		jmp	short  raz_adr_loop
plus_razr_corr:
		dec	si
		dec	di			; сложение без коррекции
		xor	ah,ah
		cmp	di, (offset off_string - 1)	; обработка выхода
		jbe	exit_off
		jmp	short  raz_adr_loop
exit_off:
		retn

plus_byte_word	endp

;                 ***  Вычитание из адреса байта/слова  ***

minus_byte_word	proc	near

		mov	si, offset cur_adress
		add	si,3			; младший разряд адреса
		mov	di, offset off_string
		add	di,3			; младший разряд вычитаемого
		xor	ax,ax
razr_adr_loop:
		mov	al, byte ptr ds:[di]	; вычитаемое
		sub	byte ptr ds:[si], al	; вычитаем
		sub	byte ptr ds:[si], ah	; и корректируем
		cmp	byte ptr ds:[si], 0fh	; переполнение ?
		jbe	minus_razr_corr		; нет ==> без коррекции
		mov	ah,1			; был заем
		and	byte ptr ds:[si], 00001111b	; сброс старших битов
		dec	si
		dec	di
		cmp	di, (offset off_string - 1)	; проверка конца
		jbe	ex_of_sub
		jmp	short  razr_adr_loop	; и так до конца
ex_of_sub:
		inc	di
		mov	byte ptr ds:[di], 0		; вычитаемое кончилось
		cmp	si, offset (offset cur_adress - 1)  ; проверка выхода
		jbe	exit_of
		jmp	short  razr_adr_loop
minus_razr_corr:
		dec	si
		dec	di			; вычитание без коррекции
		xor	ah,ah			; с отслеживанием выхода
		cmp	di, (offset off_string - 1)
		jbe	exit_of
		jmp	short  razr_adr_loop
exit_of:
		retn

minus_byte_word	endp

;                     ***  Преобразование смещения  ***

convert_offset	proc	near

		mov	si, offset off_string
		add	si,3
		mov	cx,4			; преобразуем 2 байта
		mov	di,10h			; путем деления на 16
conv_adr_loop:
		xor	dx,dx			; с вычислением остатка
		div	di
		mov	byte ptr ds:[si], dl	; сохраним число
		dec	si
		loop	conv_adr_loop		; и так до конца
		retn

convert_offset	endp

;      ***  Производится обработка типа  Rm <== segment register  ***

rm_seg_reg	proc	near

		call	operation_type
		jz	segm_into_reg		; да ==> обработаем отдельно
		call	memory_cost		; выборка смещений
		call	write_segm_into		; формируем мнемокоманду
		jc	exit_segm_into		; обрабатывается как DB
		call	special_output
		call	form_segm_index		; формируем значение
exit_segm_into:
		retn				; вернемся из процедуры
segm_into_reg:
		call	write_segm_into		; формируем мнемокоманду
		call	reg_addition
		call	form_segm_index		; запись значения
		retn				; вернемся из процедуры

rm_seg_reg	endp

;       ***  Отдельный вывод для операций типа  Rm <== seg_reg  ***

write_segm_into	proc	near

		push	ax
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; al = байт кода
		and	al,00111000b		; выделим второй операнд
		clc				; сбросим carry - флаг
		mov	cl,3			; преобразование форматов
		shr	ax,cl
		cmp	ax,6
		jae	make_segm_like_db
		jmp	short  live_segm_alone
make_segm_like_db:
		mov	byte ptr ds:[h_add], 1	; всего один байт
		pop	ax
		mov	cl,2
		mov	si, offset command_symbol
		add	si,268h			; код DB
		stc
		pushf
		call	this_db			; обработка как DB
		jmp	short  mnemo_segment_write
live_segm_alone:
		pop	ax
		clc
		pushf
		call	write_mnemo		; выводим мнемокоманду
mnemo_segment_write:
		popf
		retn

write_segm_into	endp

;                 ***  Процедура для специального вывода  ***

special_output	proc	near

		call	form_memory		; формируем операции с памятью
		mov	di,27			; адрес для вывода
		call	ins_mem_reg		; вставим первую половину
		call	plus_offset		; добавим смещения
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di			; новый адрес для вывода
		retn

special_output	endp

;   ***  Процедура для определения и формирования сегментных регистров  ***

form_segm_index	proc	near

		push	ax
		push	cx
		push	si
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; al = байт кода
		and	al,00111000b		; выделим второй операнд
		clc				; сбросим carry - флаг
		mov	cl,3			; преобразование форматов
		shr	ax,cl
		cmp	al,0
		jz	may_reg_es
		cmp	al,1
		jz	may_reg_cs		; определение сегментного
		cmp	al,2			; регистра
		jz	may_reg_ss
		cmp	al,3
		jz	may_reg_ds
		cmp	al,4
		jz	may_reg_fs
		mov	al,10
		jmp	short  now_make
may_reg_es:
		mov	al,6
		jmp	short  now_make
may_reg_cs:
		mov	al,2
		jmp	short  now_make
may_reg_ss:
		mov	al,4
		jmp	short  now_make
may_reg_ds:
		mov	al,0
		jmp	short  now_make
may_reg_fs:
		mov	al,8
now_make:
		mov	si, offset segment_regist
		add	si,ax			; смещение на второй операнд
		push	es
		push	cs
		pop	es
		cld				; сбросим флаг направления
		movsw				; перешлем
		pop	es
		pop	si
		pop	cx
		pop	ax
		clc
		retn

form_segm_index	endp

;                     ***  Обработка lea - команд  ***

lea_operation	proc	near

		call	operation_type
		jz	not_lea_compat		; да ==> lea не поддерживает
		mov	di, offset string
		add	di,27			; формируем адрес для вывода
		call	form_register		; запись первого регистра
		mov	byte ptr ds:[di], 2ch	; ','
		call	memory_cost		; выборка смещений
		call	write_mnemo		; формируем мнемокоманду
		call	form_memory		; формируем операции с памятью
		mov	di,30			; адрес для вывода
		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_d32_lea
		inc	di
no_d32_lea:
		call	ins_mem_reg		; вставим первую половину
		call	plus_offset		; добавим смещения
		retn				; вернемся из процедуры
not_lea_compat:
		mov	byte ptr ds:[h_add], 1	; всего один байт
		xor	cx,cx
		mov	cl,2
		mov	si, offset command_symbol
		add	si,268h			; код DB
		call	this_db			; обработка как DB
		retn				; вернемся из процедуры

lea_operation	endp

;             ***  Обработка типов  segment regist <== Rm  ***

seg_reg_rm	proc	near

		call	operation_type
		jz	seg_with_reg		; да ==> обработаем отдельно
		mov	di, offset string
		add	di,27			; формируем адрес для вывода
		call	form_segm_reg		; запись первого регистра
		jc	exit_seg_with_reg
		mov	byte ptr ds:[di], 2ch	; ','
		call	memory_cost		; выборка смещений
		call	write_mnemo		; формируем мнемокоманду
		call	form_memory		; формируем операции с памятью
		mov	di,30			; адрес для вывода
		call	ins_mem_reg		; вставим первую половину
		call	plus_offset		; добавим смещения
exit_seg_with_reg:
		retn				; вернемся из процедуры
seg_with_reg:
		mov	di, offset string
		add	di,27			; формируем адрес для вывода
		call	form_segm_reg		; запись первого регистра
		jc	exit_seg_with_reg
		mov	byte ptr ds:[di], 2ch	; ','
		call	write_mnemo		; формируем мнемокоманду
		mov	di,30
		call	insert_register		; запись второго регистра
		retn				; вернемся из процедуры

seg_reg_rm	endp

;     ***  Вывод сегментных регистров операций типа  seg_reg <== Rm  ***

form_segm_reg	proc	near

		push	ax
		push	cx
		push	si
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; получим второй байт
		and	al,00111000b		; выделим второй операнд
		clc				; сбросим carry - флаг
		mov	cl,3
		shr	al,cl
		cmp	al,6
		jae	i_sure_db
		call	form_segm_index
		pop	si
		pop	cx
		pop	ax
		clc
		retn
i_sure_db:
		mov	byte ptr ds:[h_add], 1	; всего один байт
		pop	si
		pop	cx
		pop	ax
		mov	cl,2
		mov	si, offset command_symbol
		add	si,268h			; код DB
		stc
		pushf
		call	this_db			; обработка как DB
		popf
		retn

form_segm_reg	endp

;                ***  Обработка операции  pop  из памяти  ***

pop_rm_oper	proc	near

		call	look_db_pop		; проверка на корректность
		jc	exit_pop_oper
		call	operation_type
		jz	pop_regs_oper		; да ==> обработаем отдельно
		call	mnemo_calling
exit_pop_oper:
		retn				; вернемся из процедуры
pop_regs_oper:
		call	write_mnemo		; формируем мнемокоманду
		mov	di,27
		call	insert_register		; запись первого регистра
		retn				; вернемся из процедуры

pop_rm_oper	endp

;   ***  Проверка на корректность второго байта операции типа  pop Rm  ***

look_db_pop	proc	near

		push	ax
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; al = байт кода
		and	al,00111000b		; выделим второй операнд
		cmp	ax,0
		pop	ax
		jnz	look_pop_like_db
		jmp	short  keep_db_out
look_pop_like_db:
		mov	byte ptr ds:[h_add], 1	; всего один байт
		mov	cl,2
		mov	si, offset command_symbol
		add	si,268h			; код DB
		stc
		pushf
		call	this_db			; обработка как DB
		popf
		retn
keep_db_out:
		clc
		retn

look_db_pop	endp

;                       ***  Вывод  ax, word_reg  ***

simple_record	proc	near

		push	es
		xor	ax,ax
		mov	al, byte ptr es:[bx]	; получим код команды
		push	cs
		pop	es
		cmp	byte ptr ds:[cpu_mode_1], 1
		jz	simple_d32
		mov	si, offset command_regist  ; указатель на регистры
		add	si,16			   ; типа word
		mov	di, offset string
		add	di,27			; позиция вывода
		cld
		movsw				; вывод регистра ax
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di
		sub	ax,90h			; получим смещение
		clc
		shl	ax,1			; * 2 для адресации к словам
		mov	si, offset command_regist
		add	si,16			; формируем смещение
		add	si,ax			; источника
		cld
		movsw				; вывод второго регистра
		pop	es
		retn
simple_d32:
		mov	si, offset com_386_regist  ; указатель на регистры
		mov	di, offset string
		add	di,27			; позиция вывода
		mov	cx,3
		cld
		rep	movsb			; вывод регистра eax
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di
		sub	ax,90h			; получим смещение
		mov	cx,3
		mul	cx
		mov	si, offset com_386_regist
		add	si,ax
		mov	cx,3
		cld
		rep	movsb			; вывод второго регистра
		pop	es
		retn

simple_record	endp

;               ***  Формируем адрес для  JMP / CALL  FAR  ***

form_far_record	proc	near

		push	ax
		push	si
		mov	si, offset string
		add	si,35			; это последний байт смещения
		cmp	byte ptr ds:[cpu_mode_1], 1
		jz	d32_call_jmp
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; второй байт смещения
		call	conv_to_hex		; перевод в строку
		xor	ax,ax
		mov	al, byte ptr es:[bx+2]	; первый байт смещения
		call	conv_to_hex		; перевод в строку
		mov	byte ptr ds:[si],3ah	; ':'
		dec	si
		xor	ax,ax
		mov	al, byte ptr es:[bx+3]	; второй байт сегмента
		call	conv_to_hex		; перевод в строку
		xor	ax,ax
		mov	al, byte ptr es:[bx+4]	; первый байт сегмента
		call	conv_to_hex		; перевод в строку
		add	byte ptr ds:[h_add], 4	; плюс 4 байта адреса
		pop	si
		pop	ax
		retn
d32_call_jmp:
		add	si,4
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; четвертый байт смещения
		call	conv_to_hex		; перевод в строку
		xor	ax,ax
		mov	al, byte ptr es:[bx+2]	; третий байт смещения
		call	conv_to_hex		; перевод в строку
		xor	ax,ax
		mov	al, byte ptr es:[bx+3]	; второй байт смещения
		call	conv_to_hex		; перевод в строку
		xor	ax,ax
		mov	al, byte ptr es:[bx+4]	; первый байт смещения
		call	conv_to_hex		; перевод в строку
		mov	byte ptr ds:[si],3ah	; ':'
		dec	si
		xor	ax,ax
		mov	al, byte ptr es:[bx+5]	; второй байт сегмента
		call	conv_to_hex		; перевод в строку
		xor	ax,ax
		mov	al, byte ptr es:[bx+6]	; первый байт сегмента
		call	conv_to_hex		; перевод в строку
		add	byte ptr ds:[h_add], 6	; плюс 4 байта адреса
		pop	si
		pop	ax
		retn

form_far_record	endp

;         ***  Обработка операций типа  al (ax) <== mem8 (16)  ***

alx_mem8_16	proc	near

		call	byte_or_word		; определяем тип операции
		mov	di, offset string
		add	di,27			; формируем адрес для вывода
		call	mode_detect		; запись первого регистра
		mov	byte ptr ds:[di], 2ch	; ','
		call	detect_cost		; выборка смещений
		call	write_mnemo		; формируем мнемокоманду
		call	form_memory		; формируем операции с памятью
		mov	di,30			; адрес для вывода
		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_mem8_16_corr
		inc	di
no_mem8_16_corr:
		call	ins_mem_reg		; вставим вторую половину
		call	plus_some_off		; добавим смещения
		retn				; вернемся из процедуры

alx_mem8_16	endp

;                   ***  Проверка и вывод al или ax  ***

mode_detect	proc	near

		push	ax
		push	cx
		push	si
		xor	ax,ax
		cmp	byte ptr ds:[cpu_mode_1], 1
		jz	mode_d32_detect
		cmp	byte ptr ds:[byte_word], 1	; операция с байтами ?
		jz	detect_byte		; да ==> перейдем
		add	ax,16			; скорректируем
detect_byte:
		mov	si, offset command_regist
		add	si,ax			; смещение на второй операнд
		push	es
		push	cs
		pop	es
		cld				; сбросим флаг направления
		movsw				; перешлем
		pop	es
		pop	si
		pop	cx
		pop	ax
		retn
mode_d32_detect:
		mov	si, offset com_386_regist
		add	si,ax
		push	es
		push	cs
		pop	es
		mov	cx,3
		cld				; сбросим флаг направления
		rep	movsb			; перешлем
		pop	es
		pop	si
		pop	cx
		pop	ax
		retn

mode_detect	endp

;                ***  Выборка непосредственного адреса  ***

detect_cost	proc	near

		cmp	byte ptr ds:[cpu_mode_2], 1
		jz	detect_d32_cost
		mov	ax,6				; DS : d16
		add	byte ptr ds:[h_add], 1		; будет еще слово
		mov	byte ptr ds:[off_code], 2	; которое надо выбрать
		retn
detect_d32_cost:
		mov	ax,5				; DS : d32
		add	byte ptr ds:[h_add], 3		; будет еще слово
		mov	byte ptr ds:[off_code], 3	; которое надо выбрать
		retn

detect_cost	endp

;             ***  Выборка смещений для упрощенных команд  ***

plus_some_off	proc	near

		cmp	byte ptr ds:[off_code], 0 ; выбирать ничего не надо ?
		jz	not_make_offset		  ; не надо ==> не будем
		mov	si,di
		sub	si,3			; выбирать сюда
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; выберем первый байт
		call	conv_to_hex		  ; преобразуем в строку
		cmp	byte ptr ds:[off_code], 1 ; еще выбирать ?
		jz	not_make_offset
		xor	ax,ax
		mov	al, byte ptr es:[bx+2]	; выберем второй байт
		call	conv_to_hex		; преобразуем в строку
		cmp	byte ptr ds:[off_code], 2 ; еще выбирать ?
		jz	not_make_offset
		xor	ax,ax
		mov	al, byte ptr es:[bx+3]	; выберем второй байт
		call	conv_to_hex		; преобразуем в строку
		xor	ax,ax
		mov	al, byte ptr es:[bx+4]	; выберем второй байт
		call	conv_to_hex		; преобразуем в строку
not_make_offset:
		retn

plus_some_off	endp

;         ***  Обработка операций типа  mem8 (16) <== al (ax)  ***

mem8_16_alx	proc	near

		call	byte_or_word		; определяем тип операции
		call	detect_cost		; выборка смещений
		call	write_mnemo		; формируем мнемокоманду
		call	form_memory		; формируем операции с памятью
		mov	di,27			; адрес для вывода
		call	ins_mem_reg		; вставим первую половину
		call	plus_some_off		; добавим смещения
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di			; новый адрес для вывода
		call	mode_detect		; формируем регистр
		retn				; вернемся из процедуры

mem8_16_alx	endp

;       ***  Обработка команд типа  al(ax) - bh(di) <== im8(16)  ***

alax_bhdi_im8_16	proc	near

		push	cx
		push	si
		call	byte_or_word		; определим тип операции
		dec	byte ptr ds:[h_add]
		call	write_al_di		; вставка регистра и запятой
		call	small_cause		; выборка значения
		pop	si
		pop	cx
		call	write_mnemo		; вывод мнемокоманду
		retn

alax_bhdi_im8_16	endp

;                        ***  Вставка AL - DI  ***

write_al_di	proc	near

		xor	ax,ax
		mov	al, byte ptr es:[bx]	; получим байт кода
		sub	ax,00b0h		; коррекция
		cmp	byte ptr ds:[cpu_mode_1], 1
		jz	write_d32_al_di
		clc
		shl	ax,1
		mov	si, offset command_regist
		add	si,ax			; смещение на второй операнд
		mov	di, offset string
		add	di,27			; смещение для вывода
		push	es
		push	cs
		pop	es
		cld				; сбросим флаг направления
		movsw				; перешлем
		pop	es
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di
		retn
write_d32_al_di:
		cmp	ax,8
		jb	corr_@@_d32
		sub	ax,8
corr_@@_d32:
		mov	cx,3
		mul	cx
		mov	si, offset com_386_regist
		add	si,ax			; смещение на второй операнд
		mov	di, offset string
		add	di,27			; смещение для вывода
		push	es
		push	cs
		pop	es
		mov	cx,3
		cld				; сбросим флаг направления
		rep	movsb			; перешлем
		pop	es
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di
		retn

write_al_di	endp

;            ***  Выборка смещений для сокращенных команд  ***

small_cause	proc	near

		mov	si,di
		cmp	byte ptr ds:[byte_word], 2	; выбирать слово ?
		jz	make_word			; да ==> выберем
		inc	byte ptr ds:[h_add]
		call	insert_byte_num
		retn
make_word:
		call	count_detect
		call	insert_number
		retn

small_cause	endp

;         ***  Обслуживание операций типа  ret((n/f)+offset)  ***

return_oper	proc	near

		mov	di, offset string
		add	di,23
		cmp	ah,1			; обработка retn ?
		jnz	not_ret_near
		mov	byte ptr ds:[di], 6eh	; 'n'
		jmp	short  make_only
not_ret_near:
		cmp	ah,3			; обработка retn+offset ?
		jnz	not_ret_near_off
		mov	byte ptr ds:[di], 6eh	; 'n'
		jmp	short  making_off
not_ret_near_off:
		cmp	ah,2			; обработка retf ?
		jnz	not_ret_far
		mov	byte ptr ds:[di], 66h	; 'f'
		jmp	short  make_only
not_ret_far:
		mov	byte ptr ds:[di], 66h	; обработка retf+offset
making_off:
		push	cx
		push	si
		mov	byte ptr ds:[byte_word], 2	; выборка слова
		mov	di, offset string
		add	di,27			; формируем смещение
		call	small_cause		; выборка смещения
		pop	si
		pop	cx
make_only:
		call	write_mnemo		; выводим мнемокоманду
		retn

return_oper	endp

;        ***  Обработка операций подмножества mem <== im8(16)  ***

this_mem_im8_16	proc	near

		push	cx
		push	si
		call	operation_type
		jz	mem_with_regs		; да ==> обработаем отдельно
		call	memory_cost		; выборка смещений
		call	form_memory
		mov	di,27
		call	ins_mem_reg
		call	plus_offset
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di
		push	bx
		xor	ax,ax
		mov	al, byte ptr ds:[off_code]
		add	bx,ax
		inc	bx
		cmp	byte ptr ds:[yes_sib], 0
		jz	no_@_mem_corr
		inc	bx
no_@_mem_corr:
		call	small_cause		; формируем значение
		pop	bx
		pop	si
		pop	cx
		call	write_mnemo
		retn				; вернемся из процедуры
mem_with_regs:
		call	reg_addition
		push	bx
		xor	ax,ax
		mov	al, byte ptr ds:[off_code]
		add	bx,ax
		inc	bx
		call	small_cause		; запись значения
		pop	bx
		pop	si
		pop	cx
		call	write_mnemo
		retn				; вернемся из процедуры

this_mem_im8_16	endp

;  ***  Арифметические операции с расширенным кодом типа Rm/i8 и Rm/i16  ***

ariph_oper_1	proc	near

		cmp	ah,2
		jz	no_@_ariph_1_minus
		dec	byte ptr ds:[h_add]
no_@_ariph_1_minus:
		call	operation_type
		jz	ariph_1_with_regs	; да ==> обработаем отдельно
		call	memory_cost		; выборка смещений
		call	form_memory
		mov	di,27
		call	ins_mem_reg
		call	plus_offset
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di
		push	bx
		xor	ax,ax
		mov	al, byte ptr ds:[off_code]
		add	bx,ax
		inc	bx
		cmp	byte ptr ds:[yes_sib], 0
		jz	no_@_ariph_1_corr
		inc	bx
no_@_ariph_1_corr:
		call	small_cause		; формируем значение
		pop	bx
		call	write_ariph_1
		retn				; вернемся из процедуры
ariph_1_with_regs:
		call	reg_addition
		push	bx
		xor	ax,ax
		mov	al, byte ptr ds:[off_code]
		add	bx,ax
		inc	bx
		call	small_cause		; запись значения
		pop	bx
		call	write_ariph_1
		retn				; вернемся из процедуры

ariph_oper_1	endp

;           ***  Вывод мнемокода арифметической операции типа 1  ***

write_ariph_1	proc	near

		push	ax
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; al = байт кода
		and	al,00111000b		; выделим второй операнд
		clc				; сбросим carry - флаг
		mov	cl,3			; преобразование форматов
		shr	ax,cl
		push	ax			; ==> сохраним смещение кода
		shl	ax,1			  ; смещение в таблице слов !
		mov	si, offset offset_arop_1  ; получим смещение в
		add	si,ax			  ; таблице смещений
		mov	ax, word ptr ds:[si]	  ; получим требуемое смещение
		mov	si, offset command_symbol ; получим смещение на
		add	si,ax			  ; машинную инструкцию
		pop	ax			  ; <== выберем смещение
		push	si			  ; ===> сохраним на стеке
		mov	si, offset length_arop_1
		add	si,ax			; выберем длину для
		xor	cx,cx			; пересылки
		mov	cl, byte ptr ds:[si]
		pop	si			; <=== выборка смещения
		pop	ax
		call	write_mnemo		; выводим мнемокоманду
		retn

write_ariph_1	endp

; ***  Арифметические операции с расширенным кодом типа Rm8/i8 и Rm16/i8  ***

ariph_oper_2	proc	near

		call	operation_type
		jz	ariph_2_with_regs	; да ==> обработаем отдельно
		call	memory_cost		; выборка смещений
		call	form_memory
		mov	di,27
		call	ins_mem_reg
		call	plus_offset
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di
		push	bx
		xor	ax,ax
		mov	al, byte ptr ds:[off_code]
		add	bx,ax
		inc	bx
		cmp	byte ptr ds:[yes_sib], 0
		jz	no_@_ariph_2_corr
		inc	bx
no_@_ariph_2_corr:
		mov	si,di
		call	insert_byte_num
		pop	bx
		call	write_ariph_2
		retn				; вернемся из процедуры
ariph_2_with_regs:
		call	reg_addition
		push	bx
		xor	ax,ax
		mov	al, byte ptr ds:[off_code]
		add	bx,ax
		inc	bx
		mov	si,di
		call	insert_byte_num
		pop	bx
		call	write_ariph_2
		retn				; вернемся из процедуры

ariph_oper_2	endp

;           ***  Вывод мнемокода арифметической операции типа 1  ***

write_ariph_2	proc	near

		push	ax
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; al = байт кода
		and	al,00111000b		; выделим второй операнд
		clc				; сбросим carry - флаг
		mov	cl,3			; преобразование форматов
		shr	ax,cl
		push	ax			; ==> сохраним смещение кода
		shl	ax,1			  ; смещение в таблице слов !
		mov	si, offset offset_arop_2  ; получим смещение в
		add	si,ax			  ; таблице смещений
		mov	ax, word ptr ds:[si]	  ; получим требуемое смещение
		mov	si, offset command_symbol ; получим смещение на
		add	si,ax			  ; машинную инструкцию
		pop	ax			  ; <== выберем смещение
		push	si			  ; ===> сохраним на стеке
		mov	si, offset length_arop_2
		add	si,ax			; выберем длину для
		xor	cx,cx			; пересылки
		mov	cl, byte ptr ds:[si]
		pop	si			; <=== выборка смещения
		pop	ax
		call	write_mnemo		; выводим мнемокоманду
		retn

write_ariph_2	endp

;              ***  Сдвиговые операции типа shift, im  ***

shift_oper_im	proc	near

		inc	byte ptr ds:[h_add]
		call	operation_type
		jz	shift_im_with_regs	; да ==> обработаем отдельно
		call	memory_cost		; выборка смещений
		call	write_shift_im		; формируем мнемокоманду
		jc	no_shift_im_this	; такой команды нет
		call	form_memory		; формируем операции с памятью
		mov	di,27			; адрес для вывода
		call	ins_mem_reg		; вставим первую половину
		call	plus_offset		; добавим смещения
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di			; новый адрес для вывода
		push	bx
		xor	ax,ax
		mov	al, byte ptr ds:[off_code]
		add	bx,ax
		inc	bx
		cmp	byte ptr ds:[yes_sib], 0
		jz	no_@_shift_im_corr
		inc	bx
no_@_shift_im_corr:
		mov	si,di
		call	insert_byte_num
		pop	bx
no_shift_im_this:
		retn				; вернемся из процедуры
shift_im_with_regs:
		call	write_shift_im		; формируем мнемокоманду
		jc	no_shift_im_this	; такой команды нет
		call	reg_addition
		push	bx
		xor	ax,ax
		mov	al, byte ptr ds:[off_code]
		add	bx,ax
		inc	bx
		mov	si,di
		call	insert_byte_num
		pop	bx
		retn				; вернемся из процедуры

shift_oper_im	endp

;             ***  Вывод мнемоники для shift - операции  ***

write_shift_im	proc	near

		push	ax
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; al = байт кода
		and	al,00111000b		; выделим второй операнд
		clc				; сбросим carry - флаг
		mov	cl,3			; преобразование форматов
		shr	ax,cl
		push	ax			; ==> сохраним смещение кода
		shl	ax,1			; смещение в таблице слов !
		mov	si, offset offset_shift	; получим смещение в
		add	si,ax			; таблице смещений
		mov	ax, word ptr ds:[si]	  ; получим требуемое смещение
		mov	si, offset command_symbol ; получим смещение на
		add	si,ax			  ; машинную инструкцию
		pop	ax			; <== выберем смещение
		push	si			; ===> сохраним на стеке
		mov	si, offset length_shift
		add	si,ax			; выберем длину для
		xor	cx,cx			; пересылки
		mov	cl, byte ptr ds:[si]
		pop	si			; <=== выборка смещения
		cmp	ax,6			; в таблицу дизассемблера
		jz	shift_like_db
		jmp	short  shift_alone
shift_like_db:
		mov	byte ptr ds:[h_add], 1	; всего один байт
		pop	ax
		stc
		pushf
		call	this_db			; обработка как DB
		jmp	short  mnemo_shift_write
shift_alone:
		pop	ax
		clc
		pushf
		call	write_mnemo		; выводим мнемокоманду
mnemo_shift_write:
		popf
		retn

write_shift_im	endp

;              ***  Сдвиговые операции типа shift, 1  ***

shift_oper_1	proc	near

		call	operation_type
		jz	shift_1_with_regs	; да ==> обработаем отдельно
		call	memory_cost		; выборка смещений
		call	write_shift_im		; формируем мнемокоманду
		jc	no_shift_1_this		; такой команды нет
		call	form_memory		; формируем операции с памятью
		mov	di,27			; адрес для вывода
		call	ins_mem_reg		; вставим первую половину
		call	plus_offset		; добавим смещения
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di			; новый адрес для вывода
		mov	byte ptr ds:[di], 31h	; формируем значение "1"
no_shift_1_this:
		retn				; вернемся из процедуры
shift_1_with_regs:
		call	write_shift_im		; формируем мнемокоманду
		jc	no_shift_1_this		; такой команды нет
		call	reg_addition
		mov	byte ptr ds:[di], 31h	; формируем значение "1"
		retn				; вернемся из процедуры

shift_oper_1	endp

;              ***  Сдвиговые операции типа shift, cl  ***

shift_oper_cl	proc	near

		call	operation_type
		jz	shift_cl_with_regs	; да ==> обработаем отдельно
		call	memory_cost		; выборка смещений
		call	write_shift_im		; формируем мнемокоманду
		jc	no_shift_cl_this	; такой команды нет
		call	form_memory		; формируем операции с памятью
		mov	di,27			; адрес для вывода
		call	ins_mem_reg		; вставим первую половину
		call	plus_offset		; добавим смещения
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di			; новый адрес для вывода
		mov	word ptr ds:[di], 6c63h	; формируем значение "cl"
no_shift_cl_this:
		retn				; вернемся из процедуры
shift_cl_with_regs:
		call	write_shift_im		; формируем мнемокоманду
		jc	no_shift_cl_this	; такой команды нет
		call	reg_addition
		mov	word ptr ds:[di], 6c63h	; формируем значение "cl"
		retn				; вернемся из процедуры

shift_oper_cl	endp

;         ***/  Операции с расширенным кодом команды группы 1  /***

ariph_group_1	proc	near

		call	operation_type
		jz	group_1_with_regs	; да ==> обработаем отдельно
		call	memory_cost		; выборка смещений
		push	ax
		push	cx
		xor	ax,ax
		xor	cx,cx
		mov	al, byte ptr es:[bx+1]
		and	al,00111000b
		mov	cl,3
		clc
		shr	ax,cl
		cmp	ax,0
		jz	expand_test
		cmp	ax,1
		pop	cx
		pop	ax
		jz	exit_group_1
		call	form_memory		; формируем операции с памятью
		mov	di,27			; адрес для вывода
		call	ins_mem_reg		; вставим первую половину
		call	plus_offset		; добавим смещения
exit_group_1:
		call	write_group_1		; формируем мнемокоманду
		retn				; вернемся из процедуры
expand_test:
		pop	cx
		pop	ax
		call	form_memory		; формируем операции с памятью
		mov	di,27			; адрес для вывода
		call	ins_mem_reg		; вставим первую половину
		call	plus_offset		; добавим смещения

this_is_a_test:
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di			; новый адрес для вывода
		push	bx
		xor	ax,ax
		mov	al, byte ptr ds:[off_code]
		add	bx,ax
		inc	bx
		cmp	byte ptr ds:[yes_sib], 0
		jz	no_@@_gr_corr
		inc	bx
no_@@_gr_corr:
		mov	si,di
		call	small_cause
		pop	bx
		jmp	short	exit_group_1
group_1_with_regs:
		push	ax
		push	cx
		xor	ax,ax
		xor	cx,cx
		mov	al, byte ptr es:[bx+1]
		and	al,00111000b
		mov	cl,3
		clc
		shr	ax,cl
		cmp	ax,0
		jz	expand_test_reg
		cmp	ax,1
		pop	cx
		pop	ax
		jz	exit_group_1
		mov	di,27
		call	insert_register		; запись первого регистра
		jmp	short	exit_group_1
expand_test_reg:
		pop	cx
		pop	ax
		mov	di,27
		call	insert_register		; запись первого регистра
		jmp	short	this_is_a_test

ariph_group_1	endp

;               ***  Вывод мнемоники для команд группы 1  ***

write_group_1	proc	near

		push	ax
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; al = байт кода
		and	al,00111000b		; выделим второй операнд
		clc				; сбросим carry - флаг
		mov	cl,3			; преобразование форматов
		shr	ax,cl
		push	ax			; ==> сохраним смещение кода
		shl	ax,1			   ; смещение в таблице слов !
		mov	si, offset offset_group_1  ; получим смещение в
		add	si,ax			   ; таблице смещений
		mov	ax, word ptr ds:[si]	   ; получим смещение
		mov	si, offset command_symbol  ; получим смещение на
		add	si,ax			   ; машинную инструкцию
		pop	ax			; <== выберем смещение
		push	si			; ===> сохраним на стеке
		mov	si, offset length_group_1
		add	si,ax			; выберем длину для
		xor	cx,cx			; пересылки
		mov	cl, byte ptr ds:[si]
		pop	si			; <=== выборка смещения
		cmp	ax,1			; в таблицу дизассемблера
		jz	group_1_like_db
		jmp	short  group_1_alone
group_1_like_db:
		mov	byte ptr ds:[h_add], 1	; всего один байт
		pop	ax
		call	this_db			; обработка как DB
		retn
group_1_alone:
		pop	ax
		call	write_mnemo		; выводим мнемокоманду
		retn

write_group_1	endp

;         ***/  Операции с расширенным кодом команды группы 2  /***

ariph_group_2	proc	near

		call	operation_type
		jz	group_2_with_regs	; да ==> обработаем отдельно
		call	memory_cost		; выборка смещений
		call	write_group_2		; формируем мнемокоманду
		jc	exit_group_2		; такой команды нет
		call	form_memory		; формируем операции с памятью
		mov	di,27			; адрес для вывода
		call	ins_mem_reg		; вставим первую половину
		call	plus_offset		; добавим смещения
exit_group_2:
		retn				; вернемся из процедуры
group_2_with_regs:
		call	write_group_2		; формируем мнемокоманду
		jc	exit_group_2
		mov	di,27
		call	insert_register		; запись первого регистра
		retn

ariph_group_2	endp

;               ***  Вывод мнемоники для команд группы 2  ***

write_group_2	proc	near

		push	ax
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; al = байт кода
		and	al,00111000b		; выделим второй операнд
		clc				; сбросим carry - флаг
		mov	cl,3			; преобразование форматов
		shr	ax,cl
		push	ax			; ==> сохраним смещение кода
		shl	ax,1			; смещение в таблице слов !
		mov	si, offset offset_group_2	; получим смещение в
		add	si,ax			; таблице смещений
		mov	ax, word ptr ds:[si]	; получим требуемое смещение
		mov	si, offset command_symbol	; получим смещение на
		add	si,ax			; машинную инструкцию
		pop	ax			; <== выберем смещение
		push	si			; ===> сохраним на стеке
		mov	si, offset length_group_2
		add	si,ax			; выберем длину для
		xor	cx,cx			; пересылки
		mov	cl, byte ptr ds:[si]
		pop	si			; <=== выборка смещения
		cmp	ax,1			; в таблицу дизассемблера
		ja	group_2_like_db
		jmp	short  group_2_alone
group_2_like_db:
		mov	byte ptr ds:[h_add], 1	; всего один байт
		pop	ax
		stc
		pushf
		call	this_db			; обработка как DB
		jmp	short  mnemo_group_2_write
group_2_alone:
		pop	ax
		clc
		pushf
		call	write_mnemo		; выводим мнемокоманду
mnemo_group_2_write:
		popf
		retn

write_group_2	endp

;         ***/  Операции с расширенным кодом команды группы 3  /***

ariph_group_3	proc	near

		call	operation_type
		jz	group_3_with_regs	; да ==> обработаем отдельно
		call	memory_cost		; выборка смещений
		call	write_group_3		; формируем мнемокоманду
		jc	exit_group_3		; такой команды нет
		call	form_memory		; формируем операции с памятью
		mov	di,27			; адрес для вывода
		call	ins_mem_reg		; вставим первую половину
		call	plus_offset		; добавим смещения
exit_group_3:
		retn				; вернемся из процедуры
group_3_with_regs:
		call	write_group_3		; формируем мнемокоманду
		jc	exit_group_3
		mov	di,27
		call	insert_register		; запись первого регистра
		retn

ariph_group_3	endp

;               ***  Вывод мнемоники для команд группы 3  ***

write_group_3	proc	near

		push	ax
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; al = байт кода
		and	al,00111000b		; выделим второй операнд
		clc				; сбросим carry - флаг
		mov	cl,3			; преобразование форматов
		shr	ax,cl
		push	ax			; ==> сохраним смещение кода
		shl	ax,1			   ; смещение в таблице слов !
		mov	si, offset offset_group_3  ; получим смещение в
		add	si,ax			   ; таблице смещений
		mov	ax, word ptr ds:[si]	   ; получим требуемое смещение
		mov	si, offset command_symbol  ; получим смещение на
		add	si,ax			   ; машинную инструкцию
		pop	ax			; <== выберем смещение
		push	si			; ===> сохраним на стеке
		mov	si, offset length_group_3
		add	si,ax			; выберем длину для
		xor	cx,cx			; пересылки
		mov	cl, byte ptr ds:[si]
		pop	si			; <=== выборка смещения
		cmp	ax,7			; в таблицу дизассемблера
		jz	group_3_like_db
		cmp	ax,2
		jz	exp_w_c_j_p
		cmp	ax,3
		jz	exp_d_c_j
		cmp	ax,4
		jz	exp_w_c_j_p
		cmp	ax,5
		jz	exp_d_c_j
		cmp	ax,6
		jz	exp_w_c_j_p
		jmp	short  group_3_alone
group_3_like_db:
		mov	byte ptr ds:[h_add], 1	; всего один байт
		pop	ax
		stc
		pushf
		call	this_db				; обработка как DB
		jmp	short  mnemo_group_3_write
exp_w_c_j_p:
		mov	byte ptr ds:[byte_word], 2	; word - операция
		jmp	short  group_3_alone
exp_d_c_j:
		mov	byte ptr ds:[byte_word], 3	; dword - операция
group_3_alone:
		pop	ax
		clc
		pushf
		call	write_mnemo		; выводим мнемокоманду
mnemo_group_3_write:
		popf
		retn

write_group_3	endp

;                 ***  Обслуживание изменений сегментов  ***

seg_reg_oper	proc	near

		xor	ax,ax
		mov	al, byte ptr es:[bx+1]
		mov	si, offset system_table
		add	si,ax
		mov	al, byte ptr ds:[si]
		test	al,80h
		jnz	segment_may_be_change

		jmp	short	like_register

segment_may_be_change:
		test	al,02h
		jnz	used_in_next
		test	al,04h
		jnz	like_register
		test	al,08h
		jnz	use_like_expand
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]
		cmp	al,66h
		jz	used_in_next
		cmp	al,67h
		jz	used_in_next
		xor	ax,ax
		mov	al, byte ptr es:[bx+2]
		and	al,0c0h
		cmp	al,0c0h
		jz	like_register

used_in_next:
		mov	word ptr ds:[new_segment], dx
		inc	bx
		call	dis_asm
		dec	bx
		mov	word ptr ds:[new_segment], 0
		retn

use_like_expand:
		xor	ax,ax
		mov	al, byte ptr es:[bx+2]
		cmp	al,81h
		ja	no_@_arop_1
		mov	si, offset system_arop_1
		jmp	short	second_@_continue
no_@_arop_1:
		cmp	al,83h
		ja	no_@_arop_2
		mov	si, offset system_arop_2
		jmp	short	second_@_continue
no_@_arop_2:
		cmp	al,0d3h
		ja	no_@_shift
		mov	si, offset system_shift
		jmp	short	second_@_continue
no_@_shift:
		cmp	al,0f7h
		ja	no_group_1
		mov	si, offset system_group_1
		jmp	short	second_@_continue
no_group_1:
		cmp	al,0feh
		jnz	no_group_2
		mov	si, offset system_group_2
		jmp	short	second_@_continue
no_group_2:
		mov	si, offset system_group_3
second_@_continue:
		and	al,00111000b
		mov	cl,3
		clc
		shr	ax,cl
		add	si,ax
		mov	al, byte ptr ds:[si]
		test	al,80h
		jz	like_register
		jmp	short	used_in_next

like_register:
		mov	byte ptr ds:[h_add], 1
		xor	cx,cx
		mov	cl,3
		mov	si, offset command_symbol
		xor	ax,ax
		mov	al, byte ptr es:[bx]
		cmp	al,26h
		jnz	no_@_es
		add	si, 26fh
		jmp	short	seg_@_continue
no_@_es:
		cmp	al,2eh
		jnz	no_@_cs
		add	si, 272h
		jmp	short	seg_@_continue
no_@_cs:
		cmp	al,36h
		jnz	no_@_ss
		add	si, 275h
		jmp	short	seg_@_continue
no_@_ss:
		cmp	al,3eh
		jnz	no_@_ds
		add	si, 278h
		jmp	short	seg_@_continue
no_@_ds:
		cmp	al,64h
		jnz	no_@_fs
		add	si, 27bh
		jmp	short	seg_@_continue
no_@_fs:
		add	si, 27eh
seg_@_continue:
		call	write_mnemo
		retn

seg_reg_oper	endp


;   ┌────────────────────────────────────────────────────────────────────┐
;   │  *** ░▒▓█  Началось непосредственное дизассемблирование  █▓▒░ ***  │
;   └────────────────────────────────────────────────────────────────────┘


code_00h	proc	near

		mov	ah,1
		call	this_rm_r8_r16
		retn

code_00h	endp

code_01h	proc	near

		mov	ah,2
		call	this_rm_r8_r16
		retn

code_01h	endp

code_02h	proc	near

		mov	ah,1
		call	this_r8_r16_rm
		retn

code_02h	endp

code_03h	proc	near

		mov	ah,2
		call	this_r8_r16_rm
		retn

code_03h	endp

code_04h	proc	near

		mov  ah,1
		call ali8_axi16
		retn

code_04h	endp

code_05h	proc	near

		mov  ah,2
		call ali8_axi16
		retn

code_05h	endp

code_06h	proc	near

		mov	ax,6
		mov	dx,1
		call	push_pop_oper
		retn

code_06h	endp

code_07h	proc	near

		mov	ax,6
		mov	dx,1
		call	push_pop_oper
		retn

code_07h	endp

code_0eh	proc	near

		mov	ax,2
		mov	dx,1
		call	push_pop_oper
		retn

code_0eh	endp

code_0fh	proc	near

		call	this_db
		retn

code_0fh	endp

code_16h	proc	near

		mov	ax,4
		mov	dx,1
		call	push_pop_oper
		retn

code_16h	endp

code_17h	proc	near

		mov	ax,4
		mov	dx,1
		call	push_pop_oper
		retn

code_17h	endp

code_1eh	proc	near

		mov	ax,0
		mov	dx,1
		call	push_pop_oper
		retn

code_1eh	endp

code_1fh	proc	near

		mov	ax,0
		mov	dx,1
		call	push_pop_oper
		retn

code_1fh	endp

code_26h	proc	near

		mov	dx,06h
		call	seg_reg_oper
		retn

code_26h	endp

code_27h	proc	near

		call	write_mnemo
		retn

code_27h	endp

code_2eh	proc	near

		mov	dx,02h
		call	seg_reg_oper
		retn

code_2eh	endp

code_36h	proc	near

		mov	dx,04h
		call	seg_reg_oper
		retn

code_36h	endp

code_3eh	proc	near

		mov	dx,00h
		call	seg_reg_oper
		retn

code_3eh	endp

code_40h	proc	near

		mov	ax,16
		xor	dx,dx
		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_40h_32bit_reg
		xor	ax,ax
		mov	dx,2
no_40h_32bit_reg:
		call	push_pop_oper
		retn

code_40h	endp

code_41h	proc	near

		mov	ax,18
		xor	dx,dx
		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_41h_32bit_reg
		mov	ax,3
		mov	dx,2
no_41h_32bit_reg:
		call	push_pop_oper
		retn

code_41h	endp

code_42h	proc	near

		mov	ax,20
		xor	dx,dx
		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_42h_32bit_reg
		mov	ax,6
		mov	dx,2
no_42h_32bit_reg:
		call	push_pop_oper
		retn

code_42h	endp

code_43h	proc	near

		mov	ax,22
		xor	dx,dx
		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_43h_32bit_reg
		mov	ax,9
		mov	dx,2
no_43h_32bit_reg:
		call	push_pop_oper
		retn

code_43h	endp

code_44h	proc	near

		mov	ax,24
		xor	dx,dx
		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_44h_32bit_reg
		mov	ax,12
		mov	dx,2
no_44h_32bit_reg:
		call	push_pop_oper
		retn

code_44h	endp

code_45h	proc	near

		mov	ax,26
		xor	dx,dx
		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_45h_32bit_reg
		mov	ax,15
		mov	dx,2
no_45h_32bit_reg:
		call	push_pop_oper
		retn

code_45h	endp

code_46h	proc	near

		mov	ax,28
		xor	dx,dx
		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_46h_32bit_reg
		mov	ax,18
		mov	dx,2
no_46h_32bit_reg:
		call	push_pop_oper
		retn

code_46h	endp

code_47h	proc	near

		mov	ax,30
		xor	dx,dx
		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_47h_32bit_reg
		mov	ax,21
		mov	dx,2
no_47h_32bit_reg:
		call	push_pop_oper
		retn

code_47h	endp

code_60h	proc	near

		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_32bit_push
		add	si,5
		inc	cx
no_32bit_push:
		call	write_mnemo
		retn

code_60h	endp

code_61h	proc	near

		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_32bit_pop
		add	si,4
		inc	cx
no_32bit_pop:
		call	write_mnemo
		retn

code_61h	endp

code_64h	proc	near

		mov	dx,0ah
		call	seg_reg_oper
		retn

code_64h	endp

code_65h	proc	near

		mov	dx,0ch
		call	seg_reg_oper
		retn

code_65h	endp

code_66h	proc	near

		mov	byte ptr ds:[cpu_mode_1], 1
		inc	bx
		call	dis_asm
		dec	bx
		mov	byte ptr ds:[cpu_mode_1], 0
		retn

code_66h	endp

code_67h	proc	near

		mov	byte ptr ds:[cpu_mode_2], 1
		inc	bx
		call	dis_asm
		dec	bx
		mov	byte ptr ds:[cpu_mode_2], 0
		retn

code_67h	endp

code_68h	proc	near

		call	count_detect
		call	write_mnemo
		mov	si, offset string
		add	si,27
		call	insert_number
		retn

code_68h	endp

code_69h	proc	near

		call	count_detect
		call	code_03h
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di
		mov	si,di
		push	bx
		xor	ax,ax
		mov	al, byte ptr ds:[off_code]
		add	bx,ax
		inc	bx
		call	insert_number
		pop	bx
		retn

code_69h	endp

code_6ah	proc	near

		inc	byte ptr ds:[h_add]
		call	write_mnemo
		mov	si, offset string
		add	si,27
		call	insert_byte_num
		retn

code_6ah	endp

code_6bh	proc	near

		inc	byte ptr ds:[h_add]
		call	code_03h
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di
		mov	si,di
		push	bx
		xor	ax,ax
		mov	al, byte ptr ds:[off_code]
		add	bx,ax
		inc	bx
		call	insert_byte_num
		pop	bx
		retn

code_6bh	endp

code_6dh	proc	near

		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_32bit_insd
		add	si,4
no_32bit_insd:
		call	write_mnemo
		retn

code_6dh	endp

code_6fh	proc	near

		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_32bit_outsd
		add	si,5
no_32bit_outsd:
		call	write_mnemo
		retn

code_6fh	endp

code_70h	proc	near

		inc	byte ptr ds:[h_add]	; плюс байт смещения
		call	write_mnemo		; вывод мнемоники команды
		call	form_curr_adr		; формирование текущего адреса
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; байт смещения
		mov	dx,1			; только байт
		call	form_new_adr		; генерация нового адреса
		call	write_adress		; вывод нового адреса
		retn

code_70h	endp

code_80h	proc	near

		mov	ah,1
		inc	byte ptr ds:[h_add]	; будет выборка i8
		call	ariph_oper_1
		retn

code_80h	endp

code_81h	proc	near

		mov	ah,2
		call	ariph_oper_1
		retn

code_81h	endp

code_82h	proc	near

		mov	ah,1
		inc	byte ptr ds:[h_add]	; будет выборка i8
		call	ariph_oper_2
		retn

code_82h	endp

code_83h	proc	near

		mov	ah,2
		inc	byte ptr ds:[h_add]	; будет выборка i8
		call	ariph_oper_2
		retn

code_83h	endp

code_8ch	proc	near

		mov	ah,2
		call	rm_seg_reg
		retn

code_8ch	endp

code_8dh	proc	near

		mov	ah,2
		call	lea_operation
		retn

code_8dh	endp

code_8eh	proc	near

		mov	ah,2
		call	seg_reg_rm
		retn

code_8eh	endp

code_8fh	proc	near

		mov	ah,2
		call	pop_rm_oper
		retn

code_8fh	endp

code_91h	proc	near

		call	write_mnemo
		call	simple_record
		retn

code_91h	endp

code_98h	proc	near

		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_32bit_cwde
		add	si,2bh
		inc	cx
no_32bit_cwde:
		call	write_mnemo
		retn

code_98h	endp

code_99h	proc	near

		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_32bit_cdq
		sub	si,25h
no_32bit_cdq:
		call	write_mnemo
		retn

code_99h	endp

code_9ah	proc	near

		call	form_far_record
		call	write_mnemo
		retn

code_9ah	endp

code_9ch	proc	near

		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_32bit_pushfd
		add	si,5
		inc	cx
no_32bit_pushfd:
		call	write_mnemo
		retn

code_9ch	endp

code_9dh	proc	near

		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_32bit_popfd
		add	si,4
		inc	cx
no_32bit_popfd:
		call	write_mnemo
		retn

code_9dh	endp

code_a0h	proc	near

		mov	ah,1
		call	alx_mem8_16
		retn

code_a0h	endp

code_a1h	proc	near

		mov	ah,2
		call	alx_mem8_16
		retn

code_a1h	endp

code_a2h	proc	near

		mov	ah,1
		call	mem8_16_alx
		retn

code_a2h	endp

code_a3h	proc	near

		mov	ah,2
		call	mem8_16_alx
		retn

code_a3h	endp

code_a5h	proc	near

		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_32bit_movsd
		add	si,5
no_32bit_movsd:
		call	write_mnemo
		retn

code_a5h	endp

code_b0h	proc	near

		mov	ah,1
		call	alax_bhdi_im8_16
		retn

code_b0h	endp

code_b8h	proc	near

		mov	ah,2
		call	alax_bhdi_im8_16
		retn

code_b8h	endp

code_c0h	proc	near

		mov	ah,1
		call	shift_oper_im
		retn

code_c0h	endp

code_c1h	proc	near

		mov	ah,2
		call	shift_oper_im
		retn

code_c1h	endp

code_c2h	proc	near

		mov	ah,3
		call	return_oper
		retn

code_c2h	endp

code_c3h	proc	near

		mov	ah,1
		call	return_oper
		retn

code_c3h	endp

code_c6h	proc	near

		mov	ah,1
		call	this_mem_im8_16
		retn

code_c6h	endp

code_c7h	proc	near

		mov	ah,2
		call	this_mem_im8_16
		retn

code_c7h	endp

code_c8h	proc	near

		call	count_detect
		inc	byte ptr ds:[h_add]
		call	write_mnemo
		mov	si, offset string
		add	si,27
		call	insert_number
		inc	si
		mov	byte ptr ds:[si], 2ch	; ','
		inc	si
		push	bx
		add	bx,2
		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	d32_@_enter
		add	bx,2
d32_@_enter:
		call	insert_byte_num
		pop	bx
		retn

code_c8h	endp

code_cah	proc	near

		mov	ah,4
		call	return_oper
		retn

code_cah	endp

code_cbh	proc	near

		mov	ah,2
		call	return_oper
		retn

code_cbh	endp

code_cdh	proc	near

		mov	al, byte ptr es:[bx]
		cmp	al,0cch			; int 3 ?
		jz	one_byte_int
		inc	byte ptr ds:[h_add]	; плюс номер прерывания
		call	write_mnemo		; выводим мнемокоманду
		xor	ax,ax
		mov	al,byte ptr es:[bx+1]	; выбираем байт номера
print_int:
		mov	si, offset string
		add	si,29			; формируем смещение
		mov	byte ptr ds:[si], 68h	; дописываем 'h'
		dec	si
		call	conv_to_hex		; преобразовываем в строку
		retn		
one_byte_int:
		call	write_mnemo		; выводим мнемокоманду
		xor	ax,ax
		mov	al,3			; debugger int 3
		jmp	short  print_int

code_cdh	endp

code_cfh	proc	near

		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	no_32bit_iretd
		add	si,4
		inc	cx
no_32bit_iretd:
		call	write_mnemo
		retn

code_cfh	endp

code_d0h	proc	near

		mov	ah,1
		call	shift_oper_1
		retn

code_d0h	endp

code_d1h	proc	near

		mov	ah,2
		call	shift_oper_1
		retn

code_d1h	endp

code_d2h	proc	near

		mov	ah,1
		call	shift_oper_cl
		retn

code_d2h	endp

code_d3h	proc	near

		mov	ah,2
		call	shift_oper_cl
		retn

code_d3h	endp

code_d4h	proc	near

		inc	byte ptr ds:[h_add]
		call	write_mnemo
		retn

code_d4h	endp

code_d6h	proc	near

		call	this_db
		retn

code_d6h	endp

code_d8h	proc	near

		call	write_mnemo
		retn

code_d8h	endp

code_e4h	proc	near

		push	cx
		push	si
		inc	byte ptr ds:[h_add]
		mov	di, offset string
		add	di,27				; первый байт команды
		cmp	byte ptr ds:[cpu_mode_1], 1
		jz	d32_in_i8_oper
		mov	si, offset command_regist
		xor	ax,ax
		mov	al, byte ptr es:[bx]
		cmp	al,0e4h
		jz	no_@_in_corr
		add	si,16
no_@_in_corr:
		push	es
		push	ds
		pop	es
		cld
		movsw
		pop	es
		jmp	short	in_i8_continue
d32_in_i8_oper:
		mov	si, offset com_386_regist
		mov	cx,3
		push	es
		push	ds
		pop	es
		cld
		rep	movsb
		pop	es
in_i8_continue:
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di
		mov	si,di
		call	insert_byte_num
		pop	si
		pop	cx
		call	write_mnemo		; вывод мнемокоманду
		retn

code_e4h	endp

code_e6h	proc	near

		push	cx
		push	si
		inc	byte ptr ds:[h_add]
		mov	byte ptr ds:[byte_word], 1
		mov	di, offset string
		add	di,27			; первый байт команды
		mov	si,di
		call	insert_byte_num
		add	di,3
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di
		xor	ax,ax
		mov	al, byte ptr es:[bx]
		cmp	al,0e7h			; код команды 0e7h ?
		jnz	no_word_out
		mov	byte ptr ds:[byte_word], 2	; слово
no_word_out:
		call	mode_detect		; вывод al (ax)
		pop	si
		pop	cx
		call	write_mnemo		; вывод мнемокоманду
		retn

code_e6h	endp

code_e8h	proc	near

		add	byte ptr ds:[h_add], 2	; плюс 2 байта смещения
		call	write_mnemo		; вывод мнемоники команды
		call	form_curr_adr		; формирование текущего адреса
		xor	ax,ax
		mov	ax, word ptr es:[bx+1]	; слово смещения
		mov	dx,2			; слово выбрать
		call	form_new_adr		; генерация нового адреса
		call	write_adress		; вывод нового адреса
		retn

code_e8h	endp

code_ech	proc	near

		mov	byte ptr ds:[byte_word], 1
		xor	ax,ax
		mov	al, byte ptr es:[bx]
		cmp	al,0ech
		jz	this_in_al_dx
		mov	byte ptr ds:[byte_word], 2
this_in_al_dx:
		call	write_mnemo		; выводим мнемокоманду
		mov	di, offset string	; формируем смещение для
		add	di,27			; вывода
		call	write_al_ax		; вывод al(ax)
		mov	word ptr ds:[di], 7864h	; 'dx'
		retn

code_ech	endp

code_eeh	proc	near

		mov	di, offset string
		add	di,27			; первый байт команды
		mov	word ptr ds:[di], 7864h	; 'dx'
		inc	di
		inc	di
		mov	byte ptr ds:[di], 2ch	; ','
		inc	di
		cmp	byte ptr ds:[cpu_mode_1], 1
		jz	d32_out
		mov	word ptr ds:[di], 'la'	; al
		xor	ax,ax
		mov	al, byte ptr es:[bx]
		cmp	al,0eeh
		jz	this_out_dx_al
		mov	word ptr ds:[di], 'xa'	; ax
		jmp	short	this_out_dx_al
d32_out:
		mov	word ptr ds:[di], 'ae'	; eax
		mov	byte ptr ds:[di+2], 'x'
this_out_dx_al:
		call	write_mnemo		; вывод мнемокоманду
		retn

code_eeh	endp

code_f2h	proc	near

		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; al = байт кода
		mov	di, offset system_table
		add	di,ax
		xor	dx,dx
		mov	dl, byte ptr ds:[di]
		and	dx,0010h
		cmp	dx,10h
		jz	repeat
		call	write_mnemo		; выводим мнемокоманду
		retn
repeat:
		inc	byte ptr ds:[h_add]	; длина команды = 2
		call	write_mnemo		; выводим мнемокоманду
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]	; al = байт кода
		push	ax			; ==> сохраним смещение кода
		shl	ax,1			; смещение в таблице слов !
		mov	si, offset offset_table	; получим смещение в
		add	si,ax
		mov	ax, word ptr ds:[si]
		mov	si, offset command_symbol
		add	si,ax
		pop	ax			; <== выберем смещение
		push	si			; ===> сохраним на стеке
		mov	si, offset length_table
		add	si,ax
		xor	cx,cx
		mov	cl, byte ptr ds:[si]
		pop	si			; <=== выборка смещения
		mov	di, offset string
		add	di,27				; вычислим смещение
		cmp	byte ptr ds:[cpu_mode_1], 0
		jz	d32_rep
		xor	ax,ax
		mov	al, byte ptr es:[bx+1]
		push	ax
		push	di
		mov	di, offset system_table
		add	di,ax
		xor	dx,dx
		mov	dl, byte ptr ds:[di]
		pop	di
		pop	ax
		and	dx,0008h
		cmp	dx,8
		jnz	d32_rep
		cmp	al,6dh
		jnz	no_insw
		dec	si
no_insw:
		add	si,5
d32_rep:
		push	es
		push	cs
		pop	es
		cld				; сбросим флаг направления
		rep	movsb			; перешлем байты
		pop	es
		retn

code_f2h	endp

code_f6h	proc	near

		mov	ah,1
		call	ariph_group_1
		retn

code_f6h	endp

code_f7h	proc	near

		mov	ah,2
		call	ariph_group_1
		retn

code_f7h	endp

code_feh	proc	near

		mov	ah,1
		call	ariph_group_2
		retn

code_feh	endp

code_ffh	proc	near

		mov	ah,2
		call	ariph_group_3
		retn

code_ffh	endp
