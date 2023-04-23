DEBUG	EQU	0		;Debug mode

$BREAK	MACRO
	IF	DEBUG
	DB	0EDH,0F5H
	ENDIF
	ENDM

	ORG	0100H

	;Entry point
KEYBFR	JP	START

	DB	'KEYBFR - French AZERTY keyboard driver installer for BIOS rel. 2.30',0DH,0AH
	DB	'$'

OFF64K	EQU	0EA00H		;Offset to 64k CP/M BIOS

BIOSVER	EQU	23H		;BIOS version to check

	;Entry point
START	;welcome
	LD	DE,MKEYBFR	;hi folks!
	CALL	DISMSG		;display message

	;get boot vectors
	LD	HL,(0001H)	;get Warm boot vector
	DEC	HL		;
	DEC	HL		;
	DEC	HL		;adjust to cold boot

	LD	($CBOOT),HL	;install cold boot vector

	LD	B,H		;save as Offset in BC
	LD	C,L		;

	;check BIOS version
	LD	DE,0036H	;point to BIOS version
	ADD	HL,DE		;
	LD	A,(HL)		;get BIOS version
	CP	BIOSVER		;check BIOS version
	LD	DE,MERRVER	;"BAD BIOS VERSION"
	JP	NZ,ERROR	;go if version is bad

	;adjust banner address
	LD	HL,0EAACH-OFF64K;"LD HL,MBANNER" + 1
	ADD	HL,BC		;adjust with offset
	PUSH	HL		;save it
	LD	E,(HL)		;get current banner address
	INC	HL		;
	LD	D,(HL)		;
	LD	HL,KBDINTL	;"MBANNER:" = expected old banner
	ADD	HL,BC		;adjust with offset
	EX	DE,HL		;to DE
	OR	A		;
	SBC	HL,DE		;compare
	LD	A,H		;
	OR	L		;
	POP	HL		;restore old referring address
	JR	NZ,ERRFAIL	;exit if addresses mismatch

	PUSH	DE		;save old banner address
	EX	DE,HL		;
	LD	HL,MBANNER	;new banner address
	ADD	HL,BC		;add offset
	EX	DE,HL		;
	LD	(HL),E		;store it
	INC	HL		;
	LD	(HL),D		;
	POP	DE		;restore old banner address

	;adjust memory size in banner
	LD	HL,18		;Offset to '64k'
	ADD	HL,DE		;get digits
	LD	E,(HL)		;
	INC	HL		;
	LD	D,(HL)		;
	LD	(MBANNER-PATCH1D+PATCH1B+3),DE
				;store digits in new banner

	;install keyboard driver patches
	LD	IX,TPATCH	;patches table
	;patch loop
LPATCH:	LD	E,(IX+0)	;DE=source begin
	LD	D,(IX+1)	;
	LD	A,E		;check if end of table (0000h)
	OR	D		;
	JR	Z,XPATCH	;exit loop if yes
	PUSH	BC		;save offset
	LD	L,(IX+2)	;HL=source end
	LD	H,(IX+3)	;
	SBC	HL,DE		;get byte count
	PUSH	HL		;push count (will pop to BC)
	LD	L,(IX+4)	;HL=dest begin
	LD	H,(IX+5)	;
	ADD	HL,BC		;add offset
	EX	DE,HL		;HL=source begin, DE=dest begin
	POP	BC		;pop count
	LDIR			;copy block
	LD	BC,0006H	;bump to next table entry
	ADD	IX,BC		;
	POP	BC		;restore offset
	JR	LPATCH		;process next entry

	;exit patch loop -- process infix table
XPATCH:	LD	HL,TINFIX	;infix table
	;infix loop
LINFIX:	LD	E,(HL)		;get infix address to DE
	INC	HL		;
	LD	D,(HL)		;
	INC	HL		;
	LD	A,E		;check if end of table (0000h)
	OR	D		;
	JR	Z,XINFIX	;exit loop if yes
	PUSH	HL		;save infix table address
	EX	DE,HL		;infix address to HL
	ADD	HL,BC		;add offset
	LD	E,(HL)		;get address to adjust to DE
	INC	HL		;
	LD	D,(HL)		;
	EX	DE,HL		;to HL
	ADD	HL,BC		;add offset
	EX	DE,HL		;back to DE
	LD	(HL),D		;store adjusted address
	DEC	HL		;
	LD	(HL),E		;
	POP	HL		;
	JR	LINFIX		;process next infix

	;exit infix loop -- check for SYSGEN parameter '*'
XINFIX	LD	A,(005DH)	;'*' parameter added ?
	CP	20H		;' ' if not, '?' if yes...
	JR	NZ,ISYSGEN	;init sysgen or warm boot
	JP	0		;warm boot

	;Cold Boot vector
CBOOT	JP	$-$		;Jump to Cold Boot
$CBOOT	EQU	$-2		;Cold Boot address

	;Handle 'Failed to install' error
ERRFAIL	LD	DE,MFAILED	;message address
ERROR	CALL	DISMSG		;display message
	JP	0		;warm boot

	;Messages
MERRVER	DB	0DH,0AH,'*** Bad BIOS version !$'
MFAILED	DB	0DH,0AH,'*** Failed to install !$'

	;Prepare for SYSGEN
ISYSGEN	;read boot sector (2x128 bytes)
	LD	C,0		;Drive #0
	LD	E,9		;SELDSK
	CALL	BIOSSVC		;call BIOS
	LD	C,0		;Track #0
	LD	E,10		;SETTRK
	CALL	BIOSSVC		;call BIOS

	LD	C,0		;Sector #0
	LD	E,11		;SETSEC
	CALL	BIOSSVC		;call BIOS
	LD	BC,0900H	;DMA Address, SYSGEN source image
	LD	E,12		;SETDMA
	CALL	BIOSSVC		;call BIOS
	LD	E,13		;READ
	CALL	BIOSSVC		;call BIOS
	OR	A		;check for error
	JR	NZ,ERROR	;abort if yes

	LD	C,1		;Sector #1
	LD	E,11		;SETSEC
	CALL	BIOSSVC		;call BIOS
	LD	BC,0980H	;DMA Address, SYSGEN source image
	LD	E,12		;SETDMA
	CALL	BIOSSVC		;call BIOS
	LD	E,13		;READ
	CALL	BIOSSVC		;call BIOS
	OR	A		;check for error
	JR	NZ,ERROR	;exit if yes

	$BREAK

	LD	HL,(0901H)	;get CP/M origin ptr in boot sector
	LD	H,9		;adjust MSB
	PUSH	HL		;
	POP	IX		;move to IX
	LD	L,(IX+0)	;get BDOS origin
	LD	H,(IX+1)	;
	LD	DE,0A00H	;CP/M image for SYSGEN
	LD	B,(IX+7)	;Number of sectors
	LD	C,0		;
	LD	(0801H),BC	;System Length for SYSGEN
	LDIR			;get CP/M system image

	$BREAK
	LD	A,0FAH		;Signature for SYSGEN ?
	LD	(0800H),A	;store it

	LD	DE,MSYSGEN	;'Ready for SYSGEN'
	CALL	DISMSG		;display message
	JP	0		;warm boot

	;messages
MKEYBFR	DB	'French keyboard driver 1.00',0DH,0AH
	DB	'for BIOS rel. 2.30$'
MSYSGEN	DB	0DH,0AH,'Ready for "SYSGEN"$'

;-----	BDOS disp message
;	IN:	DE = pointer to '$'-terminated string
DISMSG	LD      C,09H		;disp message
	JP      0005H		;BDOS svc

;-----	BIOS SVC Call
;	IN:	BC = service parameter 1
;		E = service number (0=CBOOT,1=WBOOT,...)
BIOSSVC	LD	A,E		;DE := 3*E
	ADD	A,A		;
	ADD	A,E		;
	LD	E,A		;
	LD	D,0		;
	LD	HL,($CBOOT)	;HL := cold boot vector
	ADD	HL,DE		;add service call offset
	JP	(HL)		;execute service

;-----	Patches table
TPATCH	DW	PATCH1B,PATCH1E,PATCH1D
	DW	PATCH2B,PATCH2E,PATCH2D
	DW	PATCH3B,PATCH3E,PATCH3D
	DW	0000H

;-----	Infix table
TINFIX	DW	$INFIX1,$INFIX2
	DW	0000H

;-----	PATCH 1: international keyboard handler extension
PATCH1B	EQU	$		;patch 1 source begin

PATCH1D	EQU	0EAC2H-OFF64K	;intl handler in banner message

	PHASE	PATCH1D

	;intl handler routine begin
KBDINTL	LD	HL,DKBDMAP	;international map
$INFIX1	EQU	$-2
	LD	A,B		;is char < '@'
	CP	20H		;
	JR	NC,KBDINTX	;exit if yes
KBDINT0	LD	A,(HL)		;scan intl map
	INC	HL		;
	INC	A		;end of map?
	JR	Z,KBDINTW	;exit if yes
	DEC	A		;restore A
	CP	B		;compare with char from kbd
	JR	NZ,KBDINT0	;loop until found
	LD	B,(HL)		;get converted scan code (unshifted)
	INC	HL		;
	LD	C,(HL)		;get shifted scan code
	OR	B		;clr Z
KBDINTW	SCF			;set C to signal translation done
	LD	A,B		;A tested after return
	;exit intl map scan
KBDINTX	LD	HL,DKBROW7	;shift/ctrl/clear/special keys (physical)
	RET	NC		;exit if char < '@' (conversion via BIOS table)
	RET	Z		;exit if end of conversion map
	AND	60H		;check if shift must be checked (not letters)
	LD	A,B		;get unshifted char
	SCF			;
	RET	Z		;return if letter (shift not checked)
	LD	A,3		;check SHIFT keys
	AND	(HL)		;
	JR	Z,KBDINTY	;jump if no SHIFT key pressed
	LD	B,C		;get shifted char
KBDINTY	OR	B		;clear Z
	SCF			;set C
	RET			;done

	;Key conversion map
	;- a key code found in the map is converted to the next key/char in map;
	;- for non-letters (code & 60h != 0), the found key code is followed by
	;  2 chars: first the unshifted char, then the shifted char;
	;- The map is terminated by 0FFh
	;	 A   Q   A   W   Z   W   }   M   ,   ?   @   >   <   |   @   *   ~   ù   %   {   ù   %   ^   }   {   END
DKBDMAP	DB	01H,11H,01H,17H,1AH,17H,1DH,0DH,',','?',00H,'>','<',1CH,'@','*',1EH,'u','%',1BH,'^','~',1FH,'}','{',0FFH
	DC	7DH+KBDINTL-$+MBANNER-MDRIVEM,76H
	;Shorter banner message
MBANNER	DB	1AH,07H,16H
	DB	'64k CP/M v2.2',15H,0DH,0AH
	DB	'BIOS r2.30Fr (c)''84 MM/JBO',15H,0EH,0DH,0AH,0AH

MDRIVEM	EQU	$		;0DH,'>>> Memory Drive M: ',16H,'ENABLED',16H,0DH,0AH,0AH,00H

DKIDWN7	EQU	049DH		;shift/ctrl/clear/special keys (logical state)
DKBROW7	EQU	0F480H		;Keyboard row 7 (physical)

	DEPHASE

PATCH1E	EQU	$		;patch 1 source end

;-----	PATCH 2: call the intl kbd handler extension

PATCH2B	EQU	$		;patch 2 source begin

PATCH2D	EQU	0EDD9H-OFF64K	;insert call to intl handler in KBDSCAN

	PHASE	PATCH2D

	CALL	KBDINTL		;call the intl kbd handler extension
$INFIX2	EQU	$-2
	JR	NC,KEYSYMB	;not alpha
	JR	NZ,KBDEXTB	;conversion done
	NOP			;
	BIT	2,(HL)		;CTRL ?
	JR	NZ,KBDEXIT	;exit with char in A
	SET	6,B		;add 40H to char
	OR	A		;
	JR	Z,KBDINT2	;skip CAPS check

KBDINT2	EQU	0EDF2H-OFF64K	;skip CAPS check
KEYSYMB	EQU	0EDFCH-OFF64K	;digits and symbols
KBDEXTB	EQU	0EE15H-OFF64K	;exit with char in B
KBDEXIT	EQU	0EE16H-OFF64K	;exit with char in A

	DEPHASE

PATCH2E	EQU	$		;patch 2 source end


;-----	PATCH 3: numbers and symbols < 40h

PATCH3B	EQU	$		;patch 3 source begin

PATCH3D	EQU	0EEA5H-OFF64K	;CAPS flag and symbols conversion table

	PHASE	PATCH3D

DKBDCPS	DB	00H		;CAPS flag off by default
DKBTRAN	;Unshifted
	DB	'`&["''(#]!^)-$;:=',0DH,1BH,03H,0BH,0AH,08H,09H
	DB	' '
	;Shifted
	DB	'0123456789*_#./+',0DH,18H,03H,0BH,0AH,08H,09H
	DB	' '
	;With CTRL
	DB	'}|@#{[^`^{];{_}\',0DH,7FH,03H,0BH,0AH,08H,09H
	DB	' '

	DEPHASE

PATCH3E	EQU	$		;patch 3 source end


	END	KEYBFR
