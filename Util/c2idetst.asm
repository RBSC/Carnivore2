;
; Tester for Carnivore2 IDE/FDD controller
; Copyright (c) 2019-2021 RBSC
; Version 1.05
;


;--- Macro for printing a $-terminated string

print	macro	
	ld	de,\1
	ld	c,_STROUT
	call	DOS
	endm


;--- System calls and variables

DOS		equ	#0005	; DOS function calls entry point
CURSF		equ	#FCA9
DRVINV		equ	#FB21	; number of drives in a system

;--- DOS function calls

_TERM0:		equ	#00	; Program terminate
_CONIN:		equ	#01	; Console input with echo
_CONOUT:	equ	#02	; Console output
_DIRIO:		equ	#06	; Direct console I/O
_INNOE:		equ	#08	; Console input without echo
_STROUT:	equ	#09	; String output
_BUFIN:		equ	#0A	; Buffered line input
_CONST:		equ	#0B	; Console status
_FOPEN:		equ	#0F	; Open file
_FCLOSE		equ	#10	; Close file
_FSEARCHF	equ	#11	; File Search First
_FSEARCHN	equ	#12	; File Search Next
_FDELETE	equ	#13	; Delete file
_FCREATE	equ	#16	; File Create
_SDMA:		equ	#1A	; Set DMA address
_RBWRITE	equ	#26	; Random block write
_RBREAD:	equ	#27	; Random block read
_TERM:		equ	#62	; Terminate with error code
_DEFAB:		equ	#63	; Define abort exit routine
_DOSVER:	equ	#6F	; Get DOS version


;************************
;***                  ***
;***   MAIN PROGRAM   ***
;***                  ***
;************************

	org	#100			; Needed for programs running under MSX-DOS

;------------------------
;---  Initialization  ---
;------------------------

PRGSTART:

	call	CLRSCR
	call	KEYOFF

	print	PRESENT_S		; print title

	ld	hl,0000
	ld	(PASS),hl		; passed counter
	ld	(FAIL),hl		; failed counter
	inc	hl
	ld	(ITERAT),hl		; number of iterations
	ld	a,11
	ld	(USERIT),a

; Command line options processing
CHECK0:
	ld	a,1
	ld	de,BUFFER
	call	EXTPAR
	jr	c,TSTSTART		; no parameter C- Flag
	ld	hl,BUFFER
	ld	a,(hl)
	cp	"/"
	jr	z,CheckNum		; no Flag NZ - Flag

HelpPr:
	print	FLAGS			; print usage

	call	KEYON
	ld	c,_TERM0
	jp	DOS			; exit
	
CheckNum:
	inc	hl
	ld	a,(hl)
	cp	'?'			; print help?
	jr	z,HelpPr
	call	EXTNUM			; extract number from string
	or	a
	jr	nz,CHECK1
	ld	a,d
	cp	3			; more than 2 chars?
	jr	nc,HelpPr
	ld	a,c
	cp	2			; less that 2 iterations?
	jr	c,HelpPr
	inc	bc
	ld	a,c
	ld	(USERIT),a		; new number of iterations

CHECK1:
	ld	a,2
	ld	de,BUFFER
	call	EXTPAR
	jr	c,TSTSTART		; no parameter C- Flag
	ld	hl,BUFFER
	ld	a,(hl)
	or	#20			; to lowercase
	sub	"a"			; drive number (0='A')
	inc	a
	cp	27
	jr	nc,HelpPr
	ld	(FCB),a
	ld	(FCBCLN),a		; patch FCBs

TSTSTART:
	print	STTEST			; print test info
	ld	de,BUFFER
	ld	a,(USERIT)
	dec	a
	ld	l,a
	ld	h,0
	ex	hl,de
	ld	a,%00001000
	ld	bc,#0200
	call	NUMTOASC		; convert to string
	print	BUFFER
	ld	a,(FCB)
	or	a
	jr	nz,TSTSTART1
	print	STTEST3
	jr	TSTLOOP

TSTSTART1:
	add	#40
	ld	(STTEST2),a		; drive number
	print	STTEST1			; print test info

TSTLOOP:
	print	ITERM
	ld	de,BUFFER
	ld	hl,(ITERAT)
	ex	hl,de
	ld	a,%00001000
	ld	c,'0'
	ld	b,2
	call	NUMTOASC		; convert to string
	print	BUFFER

	ld	hl,#4000
	ld	bc,#8000
	di
CRPAT:
	ld	a,l
	ld	(hl),a			; create pattern
	inc	hl
	dec	bc
	ld	a,c
	or	a
	jr	nz,CRPAT
	ld	a,b
	or	a
	jr	nz,CRPAT
	ei

WRFILE:
	ld	hl,FCBCLN
	ld	de,FCB
	ld	bc,FCBCLN-FCB
	ldir				; clear fcb

	ld	de,FCB
	ld	c,_FCREATE
	call	DOS			; Open file
	ld      hl,#8000
	ld      (FCB+14),hl     	; Record size = 32kb
	or	a
	jr	z,SETDMA

	print	FAILED
	ld	hl,(FAIL)
	inc	hl
	ld	(FAIL),hl		; failed counter increase
	jp	TSTITR
	
SETDMA:
	ld      c,_SDMA
	ld      de,#4000
	call    DOS			; set DMA

	ld	hl,1
	ld	de,FCB
	ld	c,_RBWRITE
	call	DOS			; write 32kb of pattern
	or	a
	jr	z,FCLOSE

	print	FAILED
	ld	hl,(FAIL)
	inc	hl
	ld	(FAIL),hl		; failed counter increase
	ld	de,FCB
	ld	c,_FCLOSE
	call	DOS			; close written file
	jp	TSTITR

FCLOSE:
	ld	de,FCB
	ld	c,_FCLOSE
	call	DOS			; close written file

	di
	xor	a
	ld	hl,#4000
	ld	(hl),a
	ld	de,#4001
	ld	bc,#8000
	ldir				; clear buffer
	ei

RDFILE:
	ld	hl,FCBCLN
	ld	de,FCB
	ld	bc,FCBCLN-FCB
	ldir				; clear fcb

	ld	de,FCB
	ld	c,_FOPEN
	call	DOS			; Open file
	ld      hl,#8000
	ld      (FCB+14),hl     	; Record size = 32kbytes
	or	a
	jr	nz,TSTFAIL

CHKSIZE:
	ld	hl,FCB+#10
	ld	a,(hl)
	or	a
	jr	nz,TSTFAIL
	inc	hl
	ld	a,(hl)
	cp	#80			; check file size (should be 32kb)
	jr	nz,TSTFAIL

SETDMA1:
	ld      c,_SDMA
	ld      de,#4000
	call    DOS			; set DMA

	ld	hl,1
	ld	de,FCB
	ld	c,_RBREAD
	call	DOS			; read 32kb from file
	or	a
	jr	z,FCLOSE1

	ld	de,FCB
	ld	c,_FCLOSE
	call	DOS			; close data file
TSTFAIL:
	ei
	print	FAILED
	ld	hl,(FAIL)
	inc	hl
	ld	(FAIL),hl		; failed counter increase
	jp	TSTITR

FCLOSE1:
	ld	de,FCB
	ld	c,_FCLOSE
	call	DOS			; close data file

	ld	hl,#4000
	ld	bc,#8000
	di
CHKPAT:
	ld	a,(hl)
	cp	l			; check pattern
	jr	nz,TSTFAIL
	inc	hl
	dec	bc
	ld	a,c
	or	a
	jr	nz,CHKPAT
	ld	a,b
	or	a
	jr	nz,CHKPAT
	ei

TSTOK:
	print	PASSED
	ld	hl,(PASS)
	inc	hl
	ld	(PASS),hl		; passed counter increase

TSTITR:
	ld	hl,(ITERAT)
	inc	hl
	ld	(ITERAT),hl
	ld	a,(USERIT)		; requested iterations
	cp	l
	jr	z,Exit

CHKKEY:
	rst	#30			; wait for key and avoid displaying cursor
	db	0
	dw	#009C
	jp	z,TSTLOOP

	rst	#30			; get pressed key
	db	0
	dw	#009F

	cp	27			; ESC?
	jp	nz,TSTLOOP


Exit:
	ld	de,FCB
	ld	c,_FCLOSE		; close data file
	call	DOS

	ld	de,FCB
	ld	c,_FDELETE		; delete data file
	call	DOS

	print	RESULT1
	ld	hl,(ITERAT)
	dec	hl
	ld	de,BUFFER
	ex	hl,de
	ld	a,%00001000
	ld	c,'0'
	ld	b,2
	call	NUMTOASC		; convert to string
	print	BUFFER

	print	RESULT2
	ld	hl,(PASS)
	ld	de,BUFFER
	ex	hl,de
	ld	a,%00001000
	ld	c,'0'
	ld	b,2
	call	NUMTOASC		; convert to string
	print	BUFFER

	print	RESULT3
	ld	hl,(FAIL)
	ld	de,BUFFER
	ex	hl,de
	ld	a,%00001000
	ld	c,'0'
	ld	b,2
	call	NUMTOASC		; convert to string
	print	BUFFER

	print	CRLF
	call	KEYON

	ld	c,_TERM0
	jp	DOS



;---- Out to conlose HEX byte
; A - byte
HEXOUT:
	push	hl
	push	af
	rrc	a
	rrc	a
	rrc	a
	rrc	a
	and	#0F
	ld	b,0
	ld	c,a
	ld	hl,ABCD
	add	hl,bc
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS
	pop	af
	and	#0F
	ld	b,0
	ld	c,a
	ld	hl,ABCD
	add	hl,bc
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS
	pop	hl
	ret



; Clear screen and set screen 0
CLRSCR:
	xor	a
	rst	#30
	db	0
	dw	#005F

	xor	a
	ld	(CURSF),a
	ret

; Hide functional keys
KEYOFF:	
	rst	#30
	db	0
	dw	#00CC
	ret

; Unhide functional keys
KEYON:
	rst	#30
	db	0
	dw	#00CF
	ret

; Convert HEX number to DEC number (8 bit)

HEXDEC: ld	(SHEX),a
	xor	a
	ld	(SDEC),a
	ld	d,#0A
	ld	a,(SHEX)
	ld	b,a
HDCIR:  ld	a,(SDEC)
	inc	a
	cp	d
	call	z,HEXDECE
	ld	(SDEC),a
	djnz	HDCIR
        ret

HEXDECE:ld	c,6
	add	a,c
	ld	(SDEC),a
	ld	l,#10
	ld	a,d
	add	a,l
	ld	d,a
        ld	a,(SDEC)
	ret

;-------------------------------------------------------------------------
;--- NAME: EXTPAR
;      Extracts a parameter from the command line
;    INPUT:   A  = Parameter to extract (the first one is 1)
;             DE = Buffer to put the extracted parameter
;    OUTPUT:  A  = Total number of parameters in the command line
;             CY = 1 -> The specified parameter does not exist
;                       B undefined, buffer unmodified
;             CY = 0 -> B = Parameter length, not including the tailing 0
;                       Parameter extracted to DE, finished with a 0 byte
;                       DE preserved

EXTPAR:	or	a			; Terminates with error if A = 0
	scf
	ret	z

	ld	b,a
	ld	a,(#80)			; Terminates with error if
	or	a			; there are no parameters
	scf
	ret	z
	ld	a,b

	push	af,hl
	ld	a,(#80)
	ld	c,a			; Adds 0 at the end
	ld	b,0			; (required under DOS 1)
	ld	hl,#81
	add	hl,bc
	ld	(hl),0
	pop	hl
	pop	af

	push	hl,de,ix
	ld	ix,0			; IXl: Number of parameter
	ld	ixh,a			; IXh: Parameter to be extracted
	ld	hl,#81

;* Scans the command line and counts parameters

PASASPC:
	ld	a,(hl)			; Skips spaces until a parameter
	or	a			; is found
	jr	z,ENDPNUM
	cp	" "
	inc	hl
	jr	z,PASASPC

	inc	ix			; Increases number of parameters
PASAPAR:	ld	a,(hl)		; Walks through the parameter
	or	a
	jr	z,ENDPNUM
	cp	" "
	inc	hl
	jr	z,PASASPC
	jr	PASAPAR

;* Here we know already how many parameters are available

ENDPNUM:	ld	a,ixl		; Error if the parameter to extract
	cp	ixh			; is greater than the total number of
	jr	c,EXTPERR		; parameters available

	ld	hl,#81
	ld	b,1			; B = current parameter
PASAP2:	ld	a,(hl)			; Skips spaces until the next
	cp	" "			; parameter is found
	inc	hl
	jr	z,PASAP2

	ld	a,ixh			; If it is the parameter we are
	cp	b			; searching for, we extract it,
	jr	z,PUTINDE0		; else...
	                                 
	inc	b
PASAP3:	ld	a,(hl)			; ...we skip it and return to PASAP2
	cp	" "
	inc	hl
	jr	nz,PASAP3
	jr	PASAP2

;* Parameter is located, now copy it to the user buffer

PUTINDE0:
	ld	b,0
	dec	hl
PUTINDE:	inc	b
	ld	a,(hl)
	cp	" "
	jr	z,ENDPUT
	or	a
	jr	z,ENDPUT
	ld	(de),a			; Parameter is copied to (DE)
	inc	de
	inc	hl
	jr	PUTINDE

ENDPUT:	xor	a
	ld	(de),a
	dec	b

	ld	a,ixl
	or	a
	jr	FINEXTP
EXTPERR:	scf
FINEXTP:	pop	ix
		pop     de
		pop	hl
	ret


;--- NAME: NUMTOASC
;      Converts a 16 bit number into an ASCII string
;    INPUT:      DE = Number to convert
;                HL = Buffer to put the generated ASCII string
;                B  = Total number of characters of the string
;                     not including any termination character
;                C  = Padding character
;                     The generated string is right justified,
;                     and the remaining space at the left is padded
;                     with the character indicated in C.
;                     If the generated string length is greater than
;                     the value specified in B, this value is ignored
;                     and the string length is the one needed for
;                     all the digits of the number.
;                     To compute length, termination character "$" or 00
;                     is not counted.
;                 A = &B ZPRFFTTT
;                     TTT = Format of the generated string number:
;                            0: decimal
;                            1: hexadecimal
;                            2: hexadecimal, starting with "&H"
;                            3: hexadecimal, starting with "#"
;                            4: hexadecimal, finished with "H"
;                            5: binary
;                            6: binary, starting with "&B"
;                            7: binary, finishing with "B"
;                     R   = Range of the input number:
;                            0: 0..65535 (unsigned integer)
;                            1: -32768..32767 (twos complement integer)
;                               If the output format is binary,
;                               the number is assumed to be a 8 bit integer
;                               in the range 0.255 (unsigned).
;                               That is, bit R and register D are ignored.
;                     FF  = How the string must finish:
;                            0: No special finish
;                            1: Add a "$" character at the end
;                            2: Add a 00 character at the end
;                            3: Set to 1 the bit 7 of the last character
;                     P   = "+" sign:
;                            0: Do not add a "+" sign to positive numbers
;                            1: Add a "+" sign to positive numbers
;                     Z   = Left zeros:
;                            0: Remove left zeros
;                            1: Do not remove left zeros
;    OUTPUT:    String generated in (HL)
;               B = Length of the string, not including the padding
;               C = Length of the string, including the padding
;                   Tailing "$" or 00 are not counted for the length
;               All other registers are preserved

NUMTOASC:
	push	af,ix,de,hl
	ld	ix,WorkNTOA
	push	af,af
	and	%00000111
	ld	(ix+0),a		; Type
	pop	af
	and	%00011000
	rrca
	rrca
	rrca
	ld	(ix+1),a		; Finishing
	pop	af
	and	%11100000
	rlca
	rlca
	rlca
	ld	(ix+6),a		; Flags: Z(zero), P(+ sign), R(range)
	ld	(ix+2),b		; Number of final characters
	ld	(ix+3),c		; Padding character
	xor	a
	ld	(ix+4),a		; Total length
	ld	(ix+5),a		; Number length
	ld	a,10
	ld	(ix+7),a		; Divisor = 10
	ld	(ix+13),l		; User buffer
	ld	(ix+14),h
	ld	hl,BufNTOA
	ld	(ix+10),l		; Internal buffer
	ld	(ix+11),h

ChkTipo:	ld	a,(ix+0)	; Set divisor to 2 or 16,
	or	a			; or leave it to 10
	jr	z,ChkBoH
	cp	5
	jp	nc,EsBin
EsHexa:	ld	a,16
	jr	GTipo
EsBin:	ld	a,2
	ld	d,0
	res	0,(ix+6)		; If binary, range is 0-255
GTipo:	ld	(ix+7),a

ChkBoH:	ld	a,(ix+0)		; Checks if a final "H" or "B"
	cp	7			; is desired
	jp	z,PonB
	cp	4
	jr	nz,ChkTip2
PonH:	ld	a,"H"
	jr	PonHoB
PonB:	ld	a,"B"
PonHoB:	ld	(hl),a
	inc	hl
	inc	(ix+4)
	inc	(ix+5)

ChkTip2:	ld	a,d		; If the number is 0, never add sign
	or	e
	jr	z,NoSgn
	bit	0,(ix+6)		; Checks range
	jr	z,SgnPos
ChkSgn:	bit	7,d
	jr	z,SgnPos
SgnNeg:	push	hl			; Negates number
	ld	hl,0			; Sign=0:no sign; 1:+; 2:-
	xor	a
	sbc	hl,de
	ex	de,hl
	pop	hl
	ld	a,2
	jr	FinSgn
SgnPos:	bit	1,(ix+6)
	jr	z,NoSgn
	ld	a,1
	jr	FinSgn
NoSgn:	xor	a
FinSgn:	ld	(ix+12),a

ChkDoH:	ld	b,4
	xor	a
	cp	(ix+0)
	jp	z,EsDec
	ld	a,4
	cp	(ix+0)
	jp	nc,EsHexa2
EsBin2:	ld	b,8
	jr	EsHexa2
EsDec:	ld	b,5

EsHexa2:	push	de
Divide:	push	bc,hl			; DE/(IX+7)=DE, remaining A
	ld	a,d
	ld	c,e
	ld	d,0
	ld	e,(ix+7)
	ld	hl,0
	ld	b,16
BucDiv:	rl	c
	rla
	adc	hl,hl
	sbc	hl,de
	jr	nc,$+3
	add	hl,de
	ccf
	djnz	BucDiv
	rl	c
	rla
	ld	d,a
	ld	e,c
	ld	a,l
	pop	hl
	pop	bc

ChkRest9:	cp	10		; Converts the remaining
	jp	nc,EsMay9		; to a character
EsMen9:	add	a,"0"
	jr	PonEnBuf
EsMay9:	sub	10
	add	a,"A"

PonEnBuf:	ld	(hl),a		; Puts character in the buffer
	inc	hl
	inc	(ix+4)
	inc	(ix+5)
	djnz	Divide
	pop	de

ChkECros:	bit	2,(ix+6)	; Checks if zeros must be removed
	jr	nz,ChkAmp
	dec	hl
	ld	b,(ix+5)
	dec	b			; B=num. of digits to check
Chk1Cro:	ld	a,(hl)
	cp	"0"
	jr	nz,FinECeros
	dec	hl
	dec	(ix+4)
	dec	(ix+5)
	djnz	Chk1Cro
FinECeros:	inc	hl

ChkAmp:	ld	a,(ix+0)		; Puts "#", "&H" or "&B" if necessary
	cp	2
	jr	z,PonAmpH
	cp	3
	jr	z,PonAlm
	cp	6
	jr	nz,PonSgn
PonAmpB:	ld	a,"B"
	jr	PonAmpHB
PonAlm:	ld	a,"#"
	ld	(hl),a
	inc	hl
	inc	(ix+4)
	inc	(ix+5)
	jr	PonSgn
PonAmpH:	ld	a,"H"
PonAmpHB:	ld	(hl),a
	inc	hl
	ld	a,"&"
	ld	(hl),a
	inc	hl
	inc	(ix+4)
	inc	(ix+4)
	inc	(ix+5)
	inc	(ix+5)

PonSgn:	ld	a,(ix+12)		; Puts sign
	or	a
	jr	z,ChkLon
SgnTipo:	cp	1
	jr	nz,PonNeg
PonPos:	ld	a,"+"
	jr	PonPoN
	jr	ChkLon
PonNeg:	ld	a,"-"
PonPoN	ld	(hl),a
	inc	hl
	inc	(ix+4)
	inc	(ix+5)

ChkLon:	ld	a,(ix+2)		; Puts padding if necessary
	cp	(ix+4)
	jp	c,Invert
	jr	z,Invert
PonCars:	sub	(ix+4)
	ld	b,a
	ld	a,(ix+3)
Pon1Car:	ld	(hl),a
	inc	hl
	inc	(ix+4)
	djnz	Pon1Car

Invert:	ld	l,(ix+10)
	ld	h,(ix+11)
	xor	a			; Inverts the string
	push	hl
	ld	(ix+8),a
	ld	a,(ix+4)
	dec	a
	ld	e,a
	ld	d,0
	add	hl,de
	ex	de,hl
	pop	hl			; HL=initial buffer, DE=final buffer
	ld	a,(ix+4)
	srl	a
	ld	b,a
BucInv:	push	bc
	ld	a,(de)
	ld	b,(hl)
	ex	de,hl
	ld	(de),a
	ld	(hl),b
	ex	de,hl
	inc	hl
	dec	de
	pop	bc
	ld	a,b			; *** This part was missing on the
	or	a			; *** original routine
	jr	z,ToBufUs		; ***
	djnz	BucInv
ToBufUs:
	ld	l,(ix+10)
	ld	h,(ix+11)
	ld	e,(ix+13)
	ld	d,(ix+14)
	ld	c,(ix+4)
	ld	b,0
	ldir
	ex	de,hl

ChkFin1:	ld	a,(ix+1)	; Checks if "$" or 00 finishing is desired
	and	%00000111
	or	a
	jr	z,Fin
	cp	1
	jr	z,PonDolar
	cp	2
	jr	z,PonChr0

PonBit7:	dec	hl
	ld	a,(hl)
	or	%10000000
	ld	(hl),a
	jr	Fin

PonChr0:	xor	a
	jr	PonDo0
PonDolar:	ld	a,"$"
PonDo0:	ld	(hl),a
	inc	(ix+4)

Fin:	ld	b,(ix+5)
	ld	c,(ix+4)
	pop	hl
	pop     de
	pop	ix
	pop	af
	ret

WorkNTOA:	defs	16
BufNTOA:	ds	10


;--- EXTNUM16
;      Extracts a 16-bit number from a zero-finished ASCII string
;    Input:  HL = ASCII string address
;    Output: BC = Extracted number
;            Cy = 1 if error (invalid string)
;
;EXTNUM16:	call	EXTNUM
;	ret	c
;	jp	c,INVPAR		; Error if >65535
;
;	ld	a,e
;	or	a			; Error if the last char is not 0
;	ret	z
;	scf
;	ret


;--- NAME: EXTNUM
;      Extracts a 5 digits number from an ASCII string
;    INPUT:      HL = ASCII string address
;    OUTPUT:     CY-BC = 17 bits extracted number
;                D  = number of digits of the number
;                     The number is considered to be completely extracted
;                     when a non-numeric character is found,
;                     or when already five characters have been processed.
;                E  = first non-numeric character found (or 6th digit)
;                A  = error:
;                     0 => No error
;                     1 => The number has more than five digits.
;                          CY-BC contains then the number composed with
;                          only the first five digits.
;    All other registers are preserved.

EXTNUM:	push	hl,ix
	ld	ix,ACA
	res	0,(ix)
	set	1,(ix)
	ld	bc,0
	ld	de,0
BUSNUM:	ld	a,(hl)			; Jumps to FINEXT if no numeric character
	ld	e,a			; IXh = last read character
	cp	"0"
	jr	c,FINEXT
	cp	"9"+1
	jr	nc,FINEXT
	ld	a,d
	cp	5
	jr	z,FINEXT
	call	POR10

SUMA:	push	hl			; BC = BC + A 
	push	bc
	pop	hl
	ld	bc,0
	ld	a,e
	sub	"0"
	ld	c,a
	add	hl,bc
	call	c,BIT17
	push	hl
	pop	bc
	pop	hl

	inc	d
	inc	hl
	jr	BUSNUM

BIT17:	set	0,(ix)
	ret
ACA:	db	0			; b0: num>65535. b1: more than 5 digits

FINEXT:	ld	a,e
	cp	"0"
	call	c,NODESB
	cp	"9"+1
	call	nc,NODESB
	ld	a,(ix)
	pop	ix
	pop	hl
	srl	a
	ret

NODESB:	res	1,(ix)
	ret

POR10:	push	de,hl			; BC = BC * 10 
	push	bc
	push	bc
	pop	hl
	pop	de
	ld	b,3
ROTA:	sla	l
	rl	h
	djnz	ROTA
	call	c,BIT17
	add	hl,de
	call	c,BIT17
	add	hl,de
	call	c,BIT17
	push	hl
	pop	bc
	pop	hl
	pop	de
	ret

;------------------------------------------------------------------------------
;
;Variables
;

ITERAT:	dw	0
PASS:	dw	0
FAIL:	dw	0

;
;--- File Control Blocks
;

FCB:	db	0
	db	"TESTTESTDAT"
	ds	28
FCBCLN:	db	0
	db	"TESTTESTDAT"
	ds	28

;
; Text strings
;

ABCD:	db	"0123456789ABCDEF"

FAILED:	db	" - FAILED",10,13,"$"
PASSED:	db	" - PASSED",10,13,"$"

USERIT:	db	0
SHEX:	db	0
SDEC:	db	0

ITERM:
	db	"Iteration: $"

RESULT1:
	db	10,13
	db	"Test results:",10,13
	db	"-------------",10,13
	db	"Total iterations: $" 
RESULT2:
	db	10,13
	db	"Passed: $"

RESULT3:
	db	10,13
	db	"Failed: $"

STTEST:
	db	"Starting $"
STTEST1:
	db	" iterations test on drive "
STTEST2:
	db	"A:...",10,13
	db	"Hold ESC key to stop.",10,13,10,13,"$"
STTEST3:
	db	" iterations test on default drive...",10,13
	db	"Hold ESC key to stop.",10,13,10,13,"$"

CRLF:
	db	13,10,"$"

PRESENT_S:
	db	"Carnivore2 IDE Tester v1.05",13,10
	db	"Copyright (c) 2019-2021 by RBSC",13,10,13,10,"$"

FLAGS:
	db	"Usage:",13,10
	db	" C2IDETST [/?] [/N] [Drive]",13,10
	db	"  where 'N' = number of iterations: 2-99",13,10
	db	"  and 'Drive' = drive letter A-Z",13,10
	db	"  or '?' = show help",13,10,13,10
	db	" Examples:",13,10
	db	"  C2IDETST /25 A",13,10
	db	"  C2IDETST /?",13,10,13,10,"$"

BUFFER:	ds	256

	db	0,0,0
	db	"RBSC:PTERO/WIERZBOWSKY/DJS3000/PYHESTY/GREYWOLF/SUPERMAX:2022"
	db	0,0,0

