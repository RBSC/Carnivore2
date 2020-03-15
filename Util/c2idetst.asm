;
; Stress tester for Carnivore2 IDE controller
; Copyright (c) 2019-2020 RBSC
; Version 1.00
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
	ld	(ITERAT),hl		; number of iterations
	ld	(PASS),hl		; passed counter
	ld	(FAIL),hl		; failed counter

	print	STTEST			; print test description

TSTLOOP:

	print	ITERM
	ld	hl,(ITERAT)
	ld	a,h
	call	HEXOUT
	ld	a,l
	call	HEXOUT			; print iteration counter

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
	ld	hl,(ITERAT)		; check for 65536 iterations
	inc	hl
	ld	(ITERAT),hl
	ld	a,l
	or	a
	jr	nz,CHKKEY
	ld	a,h
	cp	#40
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
	ld	a,h
	call	HEXOUT
	ld	a,l
	call	HEXOUT			; print iteration counter

	print	RESULT2
	ld	hl,(PASS)
	ld	a,h
	call	HEXOUT
	ld	a,l
	call	HEXOUT			; print successful counter

	print	RESULT3
	ld	hl,(FAIL)
	ld	a,h
	call	HEXOUT
	ld	a,l
	call	HEXOUT			; print failed counter

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

ITERM:
	db	"Iteration: $"

RESULT1:
	db	10,13
	db	"Stress test results:",10,13
	db	"--------------------",10,13
	db	"Total iterations: $" 
RESULT2:
	db	10,13
	db	"Passed: $"

RESULT3:
	db	10,13
	db	"Failed: $"

STTEST:
	db	"Starting 16384 iteration stress test.",10,13
	db	"Hold ESC key to stop the test...",10,13,10,13,"$"

CRLF:
	db	13,10,"$"

PRESENT_S:
	db	"Carnivore2 IDE Stress Tester v1.00",13,10
	db	"Copyright (c) 2019-2020 by RBSC",13,10,13,10,"$"

	db	0,0,0
	db	"RBSC:PTERO/WIERZBOWSKY/DJS3000/PENCIONER/GREYWOLF:2020"
	db	0,0,0

