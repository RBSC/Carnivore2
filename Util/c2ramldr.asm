;
; Carnivore2 Cartridge's ROM->RAM Loader
; Copyright (c) 2015-2020 RBSC
; Version 1.32
;


;--- Macro for printing a $-terminated string

print	macro	
	ld	de,\1
	ld	c,_STROUT
	call	DOS
	endm


;--- System calls and variables

DOS:	equ	#0005		; DOS function calls entry point
ENASLT:	equ	#0024		; BIOS Enable Slot
WRTSLT:	equ	#0014		; BIOS Write to Slot
CALLSLT:equ	#001C		; Inter-slot call
SCR0WID	equ	#F3AE		; Screen0 width
CURSF	equ	#FCA9

TPASLOT1:	equ	#F342
TPASLOT2:	equ	#F343
CSRY	equ	#F3DC
CSRX	equ	#F3DD
ARG:	equ	#F847
EXTBIO:	equ	#FFCA
MNROM:	equ	#FCC1		; Main-ROM Slot number & Secondary slot flags table

CardMDR:	equ	#4F80
AddrM0:	equ	#4F80+1
AddrM1:	equ	#4F80+2
AddrM2:	equ	#4F80+3
DatM0:	equ	#4F80+4

AddrFR:	equ	#4F80+5

R1Mask:	equ	#4F80+6
R1Addr:	equ	#4F80+7
R1Reg:	equ	#4F80+8
R1Mult:	equ	#4F80+9
B1MaskR:	equ	#4F80+10
B1AdrD:	equ	#4F80+11

R2Mask:	equ	#4F80+12
R2Addr:	equ	#4F80+13
R2Reg:	equ	#4F80+14
R2Mult:	equ	#4F80+15
B2MaskR:	equ	#4F80+16
B2AdrD:	equ	#4F80+17

R3Mask:	equ	#4F80+18
R3Addr:	equ	#4F80+19
R3Reg:	equ	#4F80+20
R3Mult:	equ	#4F80+21
B3MaskR:	equ	#4F80+22
B3AdrD:	equ	#4F80+23

R4Mask:	equ	#4F80+24
R4Addr:	equ	#4F80+25
R4Reg:	equ	#4F80+26
R4Mult:	equ	#4F80+27
B4MaskR:	equ	#4F80+28
B4AdrD:	equ	#4F80+29

CardMod:	equ	#4F80+30

CardMDR2:	equ	#4F80+31
ConfFl:	equ	#4F80+32
ADESCR:	equ	#4010

;--- Important constants

L_STR:	equ	16	 	; number of entries on the screen
MAPPN:	equ	5		; max number of currently supported mappers

;--- DOS function calls

_TERM0:	equ	#00		; Program terminate
_CONIN:	equ	#01		; Console input with echo
_CONOUT:	equ	#02	; Console output
_DIRIO:	equ	#06		; Direct console I/O
_INNOE:	equ	#08		; Console input without echo
_STROUT:	equ	#09	; String output
_BUFIN:	equ	#0A		; Buffered line input

_CONST:	equ	#0B		; Console status
_FOPEN: equ	#0F		; Open file
_FCLOSE	equ	#10		; Close file
_FSEARCHF	equ	#11	; File Search First
_FSEARCHN	equ	#12	; File Search Next
_FCREATE	equ	#16	; File Create
_SDMA:	equ	#1A		; Set DMA address
_RBWRITE	equ	#26	; Random block write
_RBREAD:	equ	#27	; Random block read
_TERM:	equ	#62		; Terminate with error code
_DEFAB:	equ	#63		; Define abort exit routine
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
; Set screen
	call	CLRSCR
	call	KEYOFF
;--- Checks the DOS version and sets DOS2 flag

	ld	c,_DOSVER
	call	DOS
	or	a
	jr	nz,PRTITLE
	ld	a,b
	cp	2
	jr	c,PRTITLE

	ld	a,#FF
	ld	(DOS2),a		; #FF for DOS 2, 0 for DOS 1
;	print	USEDOS2_S		; !!! Commented out by Alexey !!!

;--- Prints the title
PRTITLE:
	print	PRESENT_S

; Command line options processing
	ld	a,1
	call	F_Key			; C- no parameter; NZ- not flag; S(M)-ilegal flag
	jr	c,Stfp01
	jr	nz,Stfp07
	jp	p,Stfp02
Stfp03:
	print	I_FLAG_S
	jr	Stfp09
Stfp07:
	ld	a,1
	ld	(p1e),a			; File parameter exists!

Stfp02:
	ld	a,2
	call	F_Key
	jr	c,Stfp01
	jp	m,Stfp03
	jr	z,Stfp04
Stfp05:
	print	I_PAR_S
Stfp09:	
	print	H_PAR_S
	jp	Exit
Stfp04:
	ld	a,3
	call	F_Key
	jr	c,Stfp01
	jp	m,Stfp03
	jr	nz,Stfp05
	ld	a,4
	call	F_Key
	jr	c,Stfp01
	jp	m,Stfp03
	jr	nz,Stfp05
	ld	a,5
	call	F_Key
	jr	c,Stfp01
	jp	m,Stfp03
	jr	nz,Stfp05
	print	I_MPAR_S
	jr	Stfp09
Stfp01:
	ld	a,(p1e)
	jr	nz,Stfp06		; if not file parameter
	xor	a
	ld	(F_A),a			; Automatic flag not active
Stfp06:
	ld	a,(F_P)
	or	a
	jr	z,Stfp08
	ld	a,#FF

Stfp08:	inc	a
	ld	(protect),a		; set protection status

	ld	a,(F_H)
	or	a
	jr	nz,Stfp09

; Find used slot
	call	FindSlot
	jp	c,Exit
	call	Testslot
	jp	z,Stfp30

; print warning for incompatible or uninit cartridge and exit
	print	M_Wnvc
	ld	c,_INNOE
	call	DOS
	jp	Exit

Stfp30:       	
        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT
	ld	a,#20			; immediate changes enabled
	ld	(CardMDR),a
	ld	hl,B2ON
	ld	de,CardMDR+#0C		; set Bank2
	ld	bc,6
	ldir

	ld	a,(p1e)
	or	a
	jr	z,MainM			; no file parameter

	ld	a,1
	ld	de,BUFFER
	call	EXTPAR
	jr	c,MainM			; No parameter

	ld	ix,BUFFER
	call	FnameP

	jp	ADD_OF			; continue loading ROM image


; Main menu
MainM:
	xor	a
	ld	(CURSF),a

	print	MAIN_S
Ma01:
	ld	a,1
	ld	(CURSF),a

	ld	c,_INNOE
	call	DOS	

	push	af
	xor	a
	ld	(CURSF),a
	pop	af

	cp	27
	jp	z,Exit
	cp	"3"
	jr	z,DoReset
	cp	"0"
	jp	z,Exit
	cp	"1"
	jr	z,ADDimage
	cp	"2"
	jr	nz,Ma01
	xor 	a
	jr	ADDimgR

DoReset:
; Restore slot configuration!
        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT

	xor	a
	ld	(AddrFR),a
	ld	a,#38
	ld	(CardMDR),a
	ld	hl,RSTCFG
	ld	de,R1Mask
	ld	bc,26
	ldir

	in	a,(#F4)			; read from F4 port on MSX2+
	or	#80
	out	(#F4),a			; avoid "warm" reset on MSX2+

	rst	#30			; call to BIOS
	db	0			; slot
	dw	0			; address

;
; ADD ROM image
;
ADDimage:
	ld	a,1
ADDimgR:
	ld	(protect),a	

	print	ADD_RI_S
	ld	de,Bi_FNAM
	ld	c,_BUFIN
	call	DOS
	ld	a,(Bi_FNAM+1)
	or	a			; Empty input?
	jr	z,SelFile	

	ld	c,a
	ld	b,0
	ld	hl,Bi_FNAM+2
	add	hl,bc
	ld	(hl),0

	ld	hl,Bi_FNAM+2
	ld	b,13
ADDIM1:
	ld	a,(hl)
	cp	'.'
	jr	z,ADDIM2
	or	a
	jr	z,ADDIMC
	inc	hl
	djnz	ADDIM1

ADDIMC:
	ex	de,hl
	ld	hl,ROMEXT		; copy extension and zero in the end
	ld	bc,5
	ldir
	jr	ADDIM3

ADDIM2:
	inc	hl
	ld	a,(hl)
	or	a
	jr	z,ADDIM3
	cp	32			; empty extension?
	jr	c,ADDIMC

ADDIM3:
	ld	ix,Bi_FNAM+2
	call	FnameP
	jp	ADD_OF

SelFile:
	print	SelMode
	ld      c,_SDMA
	ld      de,BUFTOP
	call    DOS

SelFile0:
	ld	de,FCBROM
	ld	c,_FSEARCHF		; Search First File
	call	DOS
	or	a
	jr	z,SelFile1		; file found!
	print	NoMatch

	ld	a,(F_A)
	or	a
	jp	nz,Exit			; Automatic exit

	jp	MainM

SelFile1:
	ld	b,8
	ld	hl,BUFTOP+1
Sf1:	push	bc
	push	hl
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS
	pop	hl
	inc	hl
	pop	bc
	djnz	Sf1	
	ld	e,"."
	ld	c,_CONOUT
	call	DOS
	ld	b,3
	ld	hl,BUFTOP+9
Sf2:	push	bc
	push	hl
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS
	pop	hl
	inc	hl
	pop	bc
	djnz	Sf2

Sf3:	ld	c,_INNOE
	call	DOS
	cp	13			; Enter? -> select file
	jr	z,Sf5
	cp	27			; ESC? -> exit
	jp	nz,Sf3z
	print	ONE_NL_S
	jp	MainM
Sf3z:
	cp	9			; Tab? -> next file
	jr	nz,Sf3	

	ld	a,(F_V)			; verbose mode?
	or	a
	jr	nz,Sf3b

	ld	b,12
Sf3a:	push	bc
	ld	e,8
	ld	c,_CONOUT
	call	DOS			; Erase former file name with backspace
	pop	bc
	djnz	Sf3a
	jr	Sf4

Sf3b:	ld	e,9
	ld	c,_CONOUT
	call	DOS			;  Output a tab before new file

Sf4:
	ld	c,_FSEARCHN		; Search Next File
	call	DOS
	or	a
	jp	nz,SelFile0		; File not found? Start from beginning
	jp	SelFile1		; Print next found file

Sf5:
	ld	de,Bi_FNAM+2
	ld	hl,BUFTOP+1
	ld	bc,8
	ldir
	ld	a,"."
	ld	(de),a
	inc	de
	ld	bc,3
	ldir				; copy selected file name
	xor	a
	ld	(de),a			; zero in the end of the file

	ld	ix,Bi_FNAM+2
	call	FnameP

ADD_OF:
;Open file
	ld	de,OpFile_S
	ld	c,_STROUT
	call	DOS

	ld	a,(FCB)
	or 	a
	jr	z,opf1			; dp not print device letter
	add	a,#40			; 1 => "A:"
	ld	e,a
	ld	c,_CONOUT
	call	DOS
	ld	e,":"
	ld	c,_CONOUT
	call	DOS
opf1:	ld	b,8
	ld	hl,FCB+1
opf2:	push	bc
	push	hl
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS
	pop	hl
	inc	hl
	pop	bc
	djnz	opf2	
	ld	e,"."
	ld	c,_CONOUT
	call	DOS
	ld	b,3
	ld	hl,FCB+9
opf3:	push	bc
	push	hl
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS
	pop	hl
	inc	hl
	pop	bc
	djnz	opf3
	print	ONE_NL_S

; load RCP file if exists
	xor	a
	ld	(RCPData),a		; erase RCP data

	ld	hl,FCB
	ld	de,FCBRCP
	ld	bc,40
	ldir				; copy FCB
	ld	hl,RCPExt
	ld	de,FCBRCP+9
	ld	bc,3
	ldir				; change extension to .RCP

	ld	de,FCBRCP
	ld	c,_FOPEN
	call	DOS			; Open RCP file
	or	a
	jr	nz,opf4
	ld      hl,30
	ld      (FCBRCP+14),hl     	; Record size = 30 bytes

	ld      c,_SDMA
	ld      de,BUFTOP
	call    DOS

	ld	hl,1
	ld      c,_RBREAD
	ld	de,FCBRCP
	call    DOS			; read RCP file

	push	af
	push	hl
	ld	de,FCBRCP
	ld	c,_FCLOSE
	call	DOS			; close RCP file
	pop	hl
	pop	af
	or	a
	jr	nz,opf4
	ld	a,l
	cp	1			; 1 record (30 bytes) read?
	jr	nz,opf4

	ld	a,(F_A)
	or	a
	jr	nz,opf32		; skip question

	print	RCPFound		; ask to skip autodetection

opf31:	ld	c,_INNOE		; load RCP?
	call	DOS
	or	%00100000
	cp	"n"
	jr	z,opf4
	cp	"y"
	jr	nz,opf31

opf32:
	ld	hl,BUFTOP
	ld	de,RCPData
	ld	bc,30
	ldir				; copy read RCP data to its place
	ld	hl,RCPData+#04
	ld	a,(hl)
	or	%00100000		; for ROM use and %11011111
	ld	(hl),a			; set RAM as source
	ld	hl,RCPData+#0A
	ld	a,(hl)
	or	%00100000		; for ROM use and %11011111
	ld	(hl),a			; set RAM as source
	ld	hl,RCPData+#10
	ld	a,(hl)
	or	%00100000		; for ROM use and %11011111
	ld	(hl),a			; set RAM as source
	ld	hl,RCPData+#16
	ld	a,(hl)
	or	%00100000		; for ROM use and %11011111
	ld	(hl),a			; set RAM as source

; ROM file open
opf4:
	ld	de,FCB
	ld	c,_FOPEN
	call	DOS			; Open file
	ld      hl,1
	ld      (FCB+14),hl     	; Record size = 1 byte
	or	a
	jr	z,Fpo

	ld	de,F_NOT_F_S
	ld	c,_STROUT
	call	DOS
	ld	a,(F_A)
	or	a
	jp	nz,Exit			; Automatic exit
	jp	MainM		
	
Fpo:
; set DMA
	ld      c,_SDMA
	ld      de,BUFTOP
	call    DOS

; get file size
	ld	hl,FCB+#10
	ld	bc,4
	ld	de,Size
	ldir

; print ROM size in hex
	ld	a,(F_V)			; verbose mode?
	or	a
	jr	z,vrb00

	print	FileSZH			; print file size
	ld	a,(Size+3)
	call	HEXOUT
	ld	a,(Size+2)
	call	HEXOUT
	ld	a,(Size+1)
	call	HEXOUT
	ld	a,(Size)
	call	HEXOUT

	print	ONE_NL_S

vrb00:

; File size <= 32 κα ?
;	ld	a,(Size+3)
;	or	a
;	jr	nz,Fptl
;	ld	a,(Size+2)
;	or	a
;	jr	nz,Fptl
;	ld	a,(Size+1)
;	cp	#80
;	jr	nc,Fptl
; ROM Image is small, use no mapper
; bla bla bla :)

FMROM:
	print	MROMD_S
	ld	hl,(Size)
	exx
	ld	hl,(Size+2)
	ld	bc,0
	exx

	ld	a,%00000100
	ld	de,ssr08
	ld	bc,#2001		; >8Kb
	or	a
	sbc	hl,bc
	exx
	sbc	hl,bc
	exx
	jr	c,FMRM01

	ld	a,%00000101
	ld	de,ssr16
	ld	bc,#4001-#2001		; (#2000) >16kB
	sbc	hl,bc
	exx
	sbc	hl,bc
	exx
	jr	c,FMRM01

	ld	a,%00000110
	ld	de,ssr32
	ld	bc,#8001-#4001		; (#4000) >32kb
	sbc	hl,bc
	exx
	sbc	hl,bc
	exx
	jr	c,FMRM01

	ld	a,%00001110
	ld	de,ssr48
	ld	bc,#C001-#8001		; (#4000) >48kB
	sbc	hl,bc
	exx
	sbc	hl,bc
	exx
	jr	c,FMRM01

	ld	a,%00000111
	ld	de,ssr64
	ld	bc,#4000		; #10001-#C001 >64kB
	sbc	hl,bc
	exx
	sbc	hl,bc
	exx
	jr	c,FMRM01

	xor	a
	ld	de,ssrMAP


FMRM01:					; fix size
	ld	(SRSize),a
	ld	c,_STROUT
	call	DOS
	print	ONE_NL_S

; !!!! file attribute fix by Alexey !!!!
	ld	a,(FCB+#0D)
	cp	#20
	jr	z,Fptl
	ld	a,#20
	ld	(FCB+#0D),a
; !!!! file attribute fix by Alexey !!!!

; Analyze ROM-Image

; load first 8000h bytes for analysis	
Fptl:	ld	hl,#8000
	ld      c,_RBREAD
	ld	de,FCB
	call    DOS
	ld	a,l
	or	h
	jp	z,FrErr

; descriptor analysis
;ROMABCD - % 0, 0, CD2, AB2, CD1, AB1, CD0, AB0	
;ROMJT0	 - CD, AB, 0,0,TEXT ,DEVACE, STAT, INIT
;ROMJT1
;ROMJT2
;ROMJI0	- high byte INIT jmp-address
;ROMJI1
;ROMJI2
	ld	bc,6
	ld	hl,ROMABCD
	ld	de,ROMABCD+1
	ld	(hl),b
	ldir				; clear descr tab

	ld	ix,BUFTOP		; test #0000
	call	fptl00
	ld	(ROMJT0),a
	and	#0F
	jr	z,fpt01
	ld	a,e
	ld	(ROMJI0),a
fpt01:
	ld	a,(SRSize)
	and	#0F		
	jr	z,fpt07			; MAPPER
	cp	6
	jr	c,fpt03			; <= 16 kB 
fpt07:
	ld	ix,BUFTOP+#4000		; test #4000
	call	fptl00
	ld	(ROMJT1),a
	and	#0F
	jr	z,fpt02
	ld	a,e
	ld	(ROMJI1),a
fpt02:
	ld	a,(SRSize)
	and	#0F
	jr	z,fpt08			; MAPPER
	cp	7
	jr	c,fpt03			; <= 16 kB 
fpt08:
	ld      c,_SDMA
	ld      de,BUFFER
	call    DOS

	ld	hl,#0010
	ld      c,_RBREAD
	ld	de,FCB
	call    DOS
	ld	a,l
	or	h
	jp	z,FrErr

	ld	ix,BUFFER		; test #8000
	call	fptl00
	ld	(ROMJT2),a
	and	#0F
	jr	z,fpt03
	ld	a,e
	ld	(ROMJI2),a

fpt03:
	ld      c,_SDMA
	ld      de,BUFTOP
	call    DOS
	jp	FPT10

fptl00:
	ld	h,(ix+1)
	ld	l,(ix)
	ld	bc,"A"+"B"*#100
	xor	a
	push	hl
	sbc	hl,bc
	pop	hl
	jr	nz,fptl01
	set	6,a
fptl01: ld	bc,"C"+"D"*#100
	or	a
	sbc	hl,bc
	jr	nz,fptl02
	set	7,a
fptl02:	ld	e,a	
	ld	d,0
	or	a
	jr	z,fptl03		; no AB,CD descriptor

	ld	b,4
	push	ix
	pop	hl
	inc	hl			; +1
fptl05:
	inc	hl			; +2
	ld	a,(hl)
	inc	hl
	or	(hl)			; +3
	jr	z,fptl04
	scf
fptl04:	rr	d
	djnz	fptl05
	rrc	d
	rrc	d
	rrc	d
	rrc	d
fptl03:
	ld	a,d
	or	e
	ld	d,a
	ld	e,(ix+3)
	bit	0,d
	jr	nz,fptl06
	ld	e,(ix+5)
	bit	1,d
	jr	nz,fptl06
	ld	e,(ix+7)
	bit	2,d
	jr	nz,fptl06
	ld	e,(ix+9)
fptl06:
;	ld	e,a
;	ld	a,d
	ret
FPT10:

; file close NO! saved for next block
;	ld	de,FCB
;	ld	c,_FCLOSE
;	call	DOS

; print test ROM descriptor table
	ld	a,(F_V)			; verbose mode?
	or	a
	jr	z,vrb02

	print	TestRDT
	ld	a,(ROMJT0)
	call	HEXOUT
	ld	e," "
	ld	c,_CONOUT
	call	DOS
	ld	a,(ROMJT1)
	call	HEXOUT
	ld	e," "
	ld	c,_CONOUT
	call	DOS
	ld	a,(ROMJT2)
	call	HEXOUT
	print	ONE_NL_S
	ld	a,(ROMJI0)
	call	HEXOUT
	ld	e," "
	ld	c,_CONOUT
	call	DOS
	ld	a,(ROMJI1)
	call	HEXOUT
	ld	e," "
	ld	c,_CONOUT
	call	DOS
	ld	a,(ROMJI2)
	call	HEXOUT
	print	ONE_NL_S

vrb02:
; Map / miniROm select
	ld	a,(SRSize)
	and	#0F
	jr	z,FPT01A		; MAPPER ROM
	cp	7
	jp	c,FPT04			; MINI ROM

;	print	MRSQ_S
;FPT03:	ld	c,_INNOE		; 32 < ROM =< 64
;	call	DOS
;	cp	"n"
;	jr	z,FPT01			; no minirom (mapper)
;	cp	"y"			; yes minirom
;	jr	nz,FPT03

	jr	FPT01B			; Mapper detected!

FPT01A:
	xor	a
	ld	(SRSize),a	
FPT01B:
	ld	a,(RCPData)
	or	a			; RCP data available?
	jp	z,DTMAP

	ld	de,FCB
	ld	c,_FCLOSE
	call	DOS			; close file

	ld	hl,RCPData
	ld	de,Record+#04
	ld	a,(hl)
	ld	(de),a			; copy mapper type
	inc	hl
	ld	de,Record+#23
	ld	bc,29
	ldir				; copy the RCP record to directory record

	print	UsingRCP
	jp	SFM80


; Mapper types Singature
; Konami:
;    LD    (#6000),a
;    LD    (#8000),a
;    LD    (#a000),a
; 
;    Konami SCC:
;    LD    (#5000),a
;    LD    (#7000),a
;    LD    (#9000),a
;    LD    (#b000),a
; 
;    ASCII8:
;    LD    (#6000),a
;    LD    (#6800),a
;    LD    (#7000),a
;    LD    (#7800),a
; 
;    ASCII16:
;    LD    (#6000),a
;    LD    (#7000),a
;
;    32 00 XX
; 
;    For Konami games is easy since they always use the same register addresses.
; 
;    But ASC8 and ASC16 is more difficult because each game uses its own addresses and instructions to access them.
;    I.e.:
;    LD    HL,#68FF 2A FF 68
;    LD    (HL),A   77
;
;    BIT E 76543210
; 	   !!!!!!!. 5000h
;          !!!!!!.- 6000h
;          !!!!!.-- 6800h
;	   !!!!.--- 7000h
;	   !!!.---- 7800h
;          !!.----- 8000h
;          !.------ 9000h
;	   .------- A000h
;    BIT D 76543210
;	          . B000h
DTMAP:
	print	Analis_S
	ld	de,0
DTME6:				; point next portion analis
	ld	ix,BUFTOP
	ld	bc,#8000
DTM01:	ld	a,(ix)
	cp	#2A
	jr	nz,DTM03
	ld	a,(ix+1)
	cp	#FF
	jr	nz,DTM02
	ld	a,(ix+3)
	cp	#77
	jr	nz,DTM02
	ld	a,(ix+2)
	cp	#60
	jr	z,DTM60	
	cp	#68
	jr	z,DTM68
	cp	#70
	jr	z,DTM70
	cp	#78
	jr	z,DTM78
	jr	DTM02
DTM03:	cp	#32
	jr	nz,DTM02
	ld	a,(ix+1)
	cp	#00
	jr	nz,DTM02
	ld	a,(ix+2)
	cp	#50
	jr	z,DTM50
	cp	#60
	jr	z,DTM60
	cp	#68
	jr	z,DTM68
	cp	#70
	jr	z,DTM70
	cp	#78
	jr	z,DTM78
	cp	#80
	jr	z,DTM80
	cp	#90
	jr	z,DTM90
	cp	#A0
	jr	z,DTMA0
	cp	#B0
	jr	z,DTMB0
	
DTM02:	inc	ix
	dec	bc
	ld	a,b
	or	c
	jr	nz,DTM01
	jr	DTME
DTM50:
	set	0,e
	jr	DTM02
DTM60:
	set	1,e
	jr	DTM02
DTM68:
	set	2,e
	jr	DTM02
DTM70:
	set	3,e
	jr	DTM02
DTM78:
	set	4,e
	jr	DTM02
DTM80:
	set	5,e
	jr	DTM02
DTM90:
	set	6,e
	jr	DTM02
DTMA0:
	set	7,e
	jr	DTM02

DTMB0:
	set	0,d
	jr	DTM02
	

DTME:
	ld	(BMAP),de		; save detected bit mask

	ld	a,(F_V)			; verbose mode?
	or	a
	jr	z,DTME23
; print bitmask
	ld	a,(BMAP+1)
	call	HEXOUT
	ld	a,(BMAP)
	call	HEXOUT	
	ld	e," "
	ld	c,_CONOUT
	call	DOS
DTME23:

	ld	a,0

;    BIT E 76543210
; 	   !!!!!!!. 5000h
;          !!!!!!.- 6000h
;          !!!!!.-- 6800h
;	   !!!!.--- 7000h
;	   !!!.---- 7800h
;          !!.----- 8000h
;          !.------ 9000h
;	   .------- A000h
;    BIT D 76543210
;	          . B000h
	ld	a,(BMAP+1)
	bit	0,a
;	cp	%00000001
	ld	a,(BMAP)
;	jr	z,DTME2			; Konami5
	jr	nz,DTME2			; Konami5

	ld	b,4			; AsCII 16
	cp	%00001010		; 6000h 7000h
	jp	z,DTME1		
;	cp	%00000010		; Zanax-EX
;	jr	z,DTME1

	ld	b,1			; Konami (4)
	cp	%10100010		; 6000h 8000h A000h
	jp	z,DTME1
	cp	%10100000		; Aleste
	jp	z,DTME1
	cp	%00100010		; 6000h 8000h
	jp	z,DTME1			;
	cp	%00100000		; 8000h
	jp	z,DTME1


	ld	b,3			; ASCII 8
	cp	%00011110		; 6000h,6800h,7000h,8700h
	jr	z,DTME1
	cp	%00011100
	jr	z,DTME1
	cp	%00011000		; 0018
	jr	z,DTME1

DTME3:					; Mapper not detected
					; second portion ?
					; next block file read
	ld      c,_SDMA
	ld      de,BUFTOP
	call    DOS
	ld	hl,#8000
	ld      c,_RBREAD
	ld	de,FCB
	call    DOS
	ld	a,l
	or	h
	ld	de,(BMAP)		; load previos bitmask
	jp	z,DTME5
	set	7,d			; bit second seach
	jp	DTME6			; next analise search

DTME5:					; fihish file
	ld	a,e
	ld	b,4
	cp	%00000010		; 0002 = ASCII 16 ZanacEX
	jr	z,DTME1
	cp	%00001000		; 0008 = ASCII 16
	jr	z,DTME1
	cp	%01001000		; 0048 = ASCII 16
	jr	z,DTME1
	ld	b,3
	cp	%00001110		; 000E = ASCII 8
	jr	z,DTME1
	cp	%00000100		; 0004 = ASCII 8
	jr	z,DTME1
	cp	%00100000		; 0010 = ASCII 8
	jr	z,DTME1
	ld	b,0
	jr	DTME1
DTME2:
	cp	%01001001		; 5000h,7000h,9000h	
	ld	b,2			; Konami 5 (SCC)
	jr	z,DTME1
	cp	%01001000		; 5000h,7000h
	jr	z,DTME1
	cp	%01101001		; 
	jr	z,DTME1
	cp	%11101001		; 01E9
	jr	z,DTME1
	cp	%01101000		; 0168
	jr	z,DTME1
	cp	%11001000		; 01C8
	jr	z,DTME1
	cp	%01000000		; 0140
	jr	z,DTME1

	ld	b,3
	cp	%00011000
	jr	z,DTME1
	ld	b,1
	cp	%10100000
	jr	z,DTME1
	jr	DTME3	
DTME1:
	ld	a,b
	ld	(DMAP),a		; save detected Mapper type
	or	a
	jr	nz,DTME21
	
;mapper not found
	ld	a,(SRSize)
	or	a
	jr	z,DTME22		; size > 64k ? not minirom

	print	MD_Fail

	ld	a,(F_A)
	or	a
	jr	nz,FPT04		; flag auto yes

	print	MRSQ_S
FPT03:	ld	c,_INNOE		; 32 < ROM =< 64
	call	DOS
	or	%00100000
	cp	"n"
	jp	z,MTC			; no minirom (mapper), select manually
	cp	"y"			; yes minirom
	jr	nz,FPT03

FPT04:
	ld	a,(RCPData)
	or	a			; RCP data available?
	jp	z,FPT05

	ld	hl,RCPData
	ld	de,Record+#04
	ld	a,(hl)
	ld	(de),a			; copy mapper type
	inc	hl
	ld	de,Record+#23
	ld	bc,29
	ldir				; copy the RCP record to directory record

	print	UsingRCP
	jp	SFM80

FPT05:
; Mini ROM set
	print	NoAnalyze
	ld	a,5
	ld	(DMAP),a		; Minirom
	jr	DTME22

DTME21:
	xor	a
	ld	(SRSize),a

DTME22:
					; file close
	ld	de,FCB
	ld	c,_FCLOSE
	call	DOS

	ld	a,(DMAP)
	ld	b,a
	call	TTAB
	inc	hl
	ex	hl,de
	ld	c,_STROUT		; print selected MAP
	call	DOS
	print	ONE_NL_S

	ld	a,(SRSize)
	and	#0F
	jp	nz,DE_F1		; do not confirm the mapper type

	ld	a,(F_A)
	or	a
	jp	nz,DE_F1		; do not confirm the type mapper (auto)

	ld	a,(DMAP)
	or	a
	jr	z,MTC
	print	CTC_S			; (y/n)?
DTME4:	ld	c,_INNOE
	call	DOS
	or	%00100000
	cp	"y"
	jp	z,DE_F1
	cp	"n"
	jr	nz,DTME4
MTC:					; Manually select MAP type
	print	CoTC_S
	ld	a,1
MTC2:	ld	(DMAPt),a		; prtint all tab MAP
	ld	b,a
	call	TTAB
	ld	a,(hl)
	or	a
	jr	z,MTC1	
	push	hl
	ld	a,(DMAPt)
	ld	e,a
	ld	d,0
	ld	hl,BUFFER
	ld	b,2
	ld	c," "
	ld	a,%00001000		; print 2 decimal digit number
	call	NUMTOASC
	print	BUFFER
	ld	e," "
	ld	c,_CONOUT
	call	DOS
	pop	hl
	inc	hl
	ex	hl,de
	ld	c,_STROUT
	call	DOS
	print	ONE_NL_S
	ld	a,(DMAPt)
	inc	a
	jr	MTC2
MTC1:
	print	Num_S

MTC3:		
	ld	c,_INNOE
	call	DOS			; input one character
	cp	"1"
	jr	c,MTC3
	cp	MAPPN + "1"		; number of supported mappers + 1
	jr	nc,MTC3
	push	af
	ld	e,a
	ld	c,_CONOUT
	call	DOS			; print selection
	print	ONE_NL_S
	pop	af
	sub	a,"0"

MTC6:
; check input
	ld	hl,DMAPt
	cp	(hl)
	jp	nc,MTC
	or	a
	jp	z,MTC
	ld	b,a
	push	af
	push	bc
	print	SelMapT
	pop	bc
	pop	af
	jp	DTME1

DE_F1:
; Save MAP config to Record form
	ld	a,(DMAP)
	ld	b,a
	call	TTAB
	ld	a,(hl)
	ld	(Record+04),a		; type descriptos symbol
	ld	bc,35			; TAB register map
	add	hl,bc
	ld	de,Record+#23		; Record register map
	ld	bc,29			; (6 * 4) + 5
	ldir

	ld	a,(SRSize)
	ld	(Record+#3D),a

; Correction start metod

; ROMJT0
	ld	ix,ROMJT0
	and	#0F
	jp	z,Csm01			; mapper ROM

;Mini ROM-image
	cp	5			; =< 8Kb
	jr	nc,Csm04

	ld	a,#A4			; set size 8kB no Ch.reg
	ld	(Record+#26),a		; Bank 0
	ld	a,#AD			; set Bank off
	ld	(Record+#2C),a		; Bank 1
	ld	(Record+#32),a		; Bank 2
	ld	(Record+#38),a		; Bank 3
Csm08:	ld	a,(ix)
	cp	#41
	ld	a,#40
	jr	nz,Csm06		; start on reset
	ld	a,(ix+3)
	and	#C0
	ld	(Record+#28),a		; set Bank Addr	
	cp	#40
	jr	z,Csmj4			; start on #4000
	cp	#80	
	jr	z,Csmj8			; start Jmp(8002)
Csm06:
	ld	a,(ix+3)
	and	#C0
	ld	(Record+#28),a		; set Bank Addr	

	ld	a,01			; start on reset
Csm05:	ld	(Record+#3E),a		
	jp	Csm80

Csmj4:	ld	a,2
	jr	Csm05
Csmj8:	ld	a,6
	jr	Csm05

;
Csm04:	cp	6			; =< 16 kB
	jr	nc,Csm07

	ld	a,#A5			; set size 16kB noCh.reg
	ld	(Record+#26),a		; Bank 0
	ld	a,#AD			; set Bank off
	ld	(Record+#2C),a		; Bank 1
	ld	(Record+#32),a		; Bank 2
	ld	(Record+#38),a		; Bank 3
	jp	Csm08

Csm07:	cp	7			; =< 32 kb
	jr	nc,Csm09
	ld	a,#A5			; set size 16kB noCh.reg
	ld	(Record+#26),a		; Bank 0
	ld	a,#A5			; set size 16kB noCh.reg
	ld	(Record+#2C),a		; Bank 1
	ld	a,#AD			; set Bank off
	ld	(Record+#32),a		; Bank 2
	ld	(Record+#38),a		; Bank 3
	ld	a,(ix)
	ld	b,a
;	cp	#41
	or	a
;	jr	z, Csm071
	jr	nz,Csm071
	ld	a,(ix+1)
	cp	#41
	jr	nz,Csm06
	ld	a,(ix+4)
	and	#C0
	cp	#80
	jr	nz,Csm06
	jr	Csmj8			; start Jmp(8002)	
Csm071:	ld	a,(ix+3)	
	and	#C0
	cp	#40			; #4000
	jr	nz,Csm072
	ld	a,b
	cp	#41
	jp	nz,Csm06		; R
	ld	a,2
	jp	Csm05			; start Jmp(4002)
	cp	#00			; #0000 subrom
	jr	nz,Csm072
	ld	(Record+#28),a		; Bank1 #0000 
	ld	a,#40
	ld	(Record+#2E),a		; Bank2 #4000
	jp	Csm06			; start on reset 	
Csm072:	cp	#80
	jp	nz,Csm06		; start on reset
	ld	(Record+#28),a		; Bank1 #0000 
	ld	a,#C0
	ld	(Record+#2E),a		; Bank2 #4000
	ld	a,6
	jp	Csm05			; start Jmp(8002)

Csm09:
	cp	7			; 64 kB ROM
	jr	nz,Csm10
	ld	a,#A7			; set size 64kB noCh.reg
	ld	(Record+#26),a		; Bank 0
	ld	a,#AD			; set Bank off
	ld	(Record+#2C),a		; Bank 1
	ld	(Record+#32),a		; Bank 2
	ld	(Record+#38),a		; Bank 3
	ld	a,0
	ld	(Record+#28),a		; Bank 0 Address=0
	ld	a,(ix)
	or	a
	jp	nz,Csm06		; start on Reset
	ld	a,(ix+1)
	or	a
	jr	z,Csm11
	cp	#41
	jp	nz,Csm06
	ld	a,2			; start jmp(4002)
	jp	Csm05				
Csm11:	ld	a,(ix+2)
	cp	#41
	jp	nz,Csm06
	ld	a,6			; staer jmp(8002)
	jp	Csm05		


Csm10:
;                               	; %00001110 48 kB
	ld	a,#A5			; set size 16kB noCh.reg
	ld	(Record+#26),a		; Bank 0
	ld	a,#A5			; set size 16kB noCh.reg
	ld	(Record+#2C),a		; Bank 1
	ld	a,#A5			; set size 16kB noCh.reg
	ld	(Record+#32),a		; Bank 2
	ld	a,#AD			; set Bank off
	ld	(Record+#38),a		; Bank 3
	ld	a,1
	ld	(Record+#2B),a		; correction for bank 1
	ld	a,(ix)
	or	a			
	jr	z,Csm12
	cp	41
	jr	nz,Csm13
	ld	a,2			; start jmp(4002)
	jp	Csm05
Csm13:	ld	a,(ix+3)
	and	#C0
	jp	nz,Csm06		; start on Reset
	xor	a			; 0 address
	ld	(Record+#28),a
	ld	a,#40
	ld	(Record+#2E),a
	ld	a,#80
	ld	(Record+#34),a
	jp	Csm06			; start on Reset
Csm12:	ld	a,(ix+1)
	or	a
	jr	z,Csm14
	ld	a,(ix+4)
	and	#C0
	cp	#40
	jr	nz,Csm15
	xor	a			; 0 address
	ld	(Record+#28),a
	ld	a,#40
	ld	(Record+#2E),a
	ld	a,#80
	ld	(Record+#34),a
	ld	a,(ix+1)
	cp	#41
	jp	nz,Csm06
	ld	a,2			; start jmp(4002)
	jp	Csm05
Csm15:	jp	Csm06

Csm14:	ld	a,(ix+2)
	or	a
	jp	nz,Csm06
	xor	a			; 0 address
	ld	(Record+#28),a
	ld	a,#80
	ld	(Record+#2E),a
	ld	a,(ix+2)
	cp	#41	
	jp	nz,Csm06
	ld	a,6			; start jmp(8002)
	jp	Csm05

Csm01:

; Mapper ROM IMAGE start Bank #4000
; 
	ld	a,(ix+1)		; ROMJT1 (#8000)
	or	a
	jr	z,Csm02	
Csm03:	ld	a,01			; Complex start
	ld	(Record+#3E),a		; need Reset
	jp	Csm80
Csm02:
	ld	a,(ix)			; ROMJT0 (#4000)
	cp	#41
	jr	nz,Csm03		; Reset
	ld	a,02			; Start to jump (#4002)	
	ld	(Record+#3E),a

Csm80:	cp	1			; reset needed?
	jr	nz,Csm80a
	ld	a,(Record+#3C)
	and	%11111011		; set reset bit to match 01 at #3E
	ld	(Record+#3C),a
	jr	Csm80b
Csm80a:
	cp	2
	jr	nz,Csm80b
	ld	a,(Record+#3C)
	or	%00000100		; zero reset bit to match 02 at #3E
	ld	(Record+#3C),a

Csm80b:
; test print Size-start metod
	ld	a,(F_V)			; verbose mode?
	or	a
	jr	z,Csm81

	print	Strm_S
	ld	a,(Record+#3D)
	call	HEXOUT
	ld	e,"-"
	ld	c,_CONOUT
	call	DOS
	ld	a,(Record+#3E)
	call	HEXOUT
	print	ONE_NL_S

Csm81:	ld	a,(Record+#3D)
	and	#0F
	jp	SFM80			; mapper ROM

; Search free space in flash
SFM01:
;find
	ld	e,a
	push	de

	ld	a,(TPASLOT1)		; reset 1 page
	ld	h,#40
	call	ENASLT

	ld	a,(F_V)			; verbose mode?
	or	a
	jr	z,SFM01A

	print	FNRE_S

	pop	de
	push	de
	ld	a,d			; print N record
	call	HEXOUT
	ld	e,"-"
	ld	c,_CONOUT
	call	DOS
	ld	a,(ix+2)		; print N FlashBlock
	call	HEXOUT
	ld	e,"-"
	ld	c,_CONOUT
	call	DOS
	pop	de

	push	de
	ld	a,e			; print N Bank
	call	HEXOUT
	print	ONE_NL_S

SFM01A:
	pop	de

	ld	a,(Record+#3D)
	and	#0F
	cp	6
	ld	a,e
	jr	c,SFM70
	rlc	a
SFM70:	
	ld	(Record+#25),a		; R1Reg
	inc	a
	ld	(Record+#2B),a		; R2Reg
	inc	a
	ld	(Record+#31),a		; R3Reg
	inc	a
	ld	(Record+#37),a		; R4Reg

	ld	a,e
	rlc	a
	rlc	a
	rlc	a
	rlc	a
	ld	b,a
	ld	a,(Record+#3D)
	and	#0F
	or	b
	ld	(Record+#3D),a

	ld	d,1
	ld	e,(ix+2)
	ld	a,d
	ld	(multi),a

	jp	DEFMR1

SFM80:
	xor	a
	ld	(multi),a

; Size  - size file 4 byte
; calc blocks len
	ld	a,(Size+3)
	or	a
	jr	nz,DEFOver
	ld	a,(Size+2)
	cp	#0C			; < 720kb?
	jr	c,DEFMR1

DEFOver:
	print	FileOver_S
	ld	a,(F_A)
	or	a
	jp	nz,Exit			; Automatic exit
	jp	MainM

DEFMR1:
	ld	a,4			; start from 4th block in RAM
	ld	(Record+02),a		; Record+02 - starting block
	ld	a,(Size+2)
	or	a
	jr	nz,DEFMR2
	inc	a			; set minumum 1 block for any file
DEFMR2:
	ld	(Record+03),a		; Record+03 - length in 64kb blocks
	ld	a,#FF
	ld	(Record+01),a		; set active flag

DEF09:
	ld	a,(F_A)
	or	a
	jr	nz,DEF10AA

	print	CreaDir			; create directory entry?
	xor	a
	ld	(F_D),a			; by default create directory
DEF10A:
	ld	c,_INNOE
	call	DOS
	or	%00100000
	cp	"y"
	jr	z,DEF10AA
	cp	"n"
	jp	nz,DEF10A
	ld	a,1
	ld	(F_D),a			; don't create directory
	jp	DEF10

DEF10AA:
	print	ONE_NL_S
	call	FrDIR			; search free DIR record
	jr	nz,DEF06

	print	DirOver_S		; no action on directory overfilling
	jp	MainM

DEF06:	
	ld	(Record),a		; save DIR number

	ld	a,(F_V)			; verbose mode?
	or	a
	jr	z,DEF06A

	print	FDE_S
	ld	a,(Record)
	call	HEXOUT
	print	ONE_NL_S

; Filename -> Record name
DEF06A:	
	ld	bc,30
	ld	de,Record+05
	ld	hl,RAM_TEMPL+1
	ldir				; copy info from RAM template to record excluding "R" identifier (RAM)

	ld	hl,FCB+1
	ld	de,Record+10
	ld	bc,8			; move file name without extension
	ldir

	ld	a,(F_V)			; verbose mode?
	or	a
	jr	z,DEF13

	ld	a,"."
	ld	(de),a
	inc	de
	ld	bc,3			; transfer extension in verbose mode
	ldir

; print Record name
DEF13:
	print	NR_I_S
	ld	b,25			; 30-5 for "RAM: "
	ld	hl,Record+10
DEF12:
	push	hl
	push	bc
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS
	pop	bc
	pop	hl
	inc	hl
	djnz	DEF12

	ld	a,(F_A)
	or	a
	jr	nz,DEF10		; Flag automatic confirm
	print	ONE_NL_S
	print	NR_L_S

	ld	a,25			; 30-5 for "RAM: "
	ld	(BUFFER),a
	ld	c,_BUFIN
	ld	de,BUFFER
	call	DOS
	ld	a,(BUFFER+1)	
	or	a
	jr	z,DEF10

	ld	bc,30
	ld	de,Record+05
	ld	hl,RAM_TEMPL+1
	ldir				; copy info from RAM template to record excluding "R" identifier (RAM)

	ld	a,(BUFFER+1)
	ld	b,0
	ld	c,a
	ld	hl,BUFFER+2
	ld	de,Record+10
	ldir
	jr	DEF13

DEF10:
	ld	a,(F_A)
	or	a
	jr	nz,DEF11		; flag automatic confirm

	print	ONE_NL_S
	print	LOAD_S			; ready?

DEF10B:
	ld	c,_INNOE
	call	DOS
	or	%00100000
	cp	"y"
	jr	z,DEF11
	cp	"n"
	jp	nz,DEF10B
	print	ONE_NL_S
	jp	MainM

DEF11:
	print	ONE_NL_S
	call	LoadImage		; load file into RAM

; Restore slot configuration!
        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT
	ld	a,#15
	ld	(R2Mult),a		; set 16kB Bank write
	xor	a
	ld	(EBlock),a
	ld	(AddrFR),a
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT
        ld      a,(TPASLOT2)
        ld      h,#80
        call    ENASLT          	; Select Main-RAM at bank 8000h~BFFFh

	ld	a,(F_D)
	or	a
	jr	nz,DEF11A		; skip directory entry creation?

	call	SaveDIR			; save directory
	jr	c,DEF11B

DEF11A:
	print	ONE_NL_S
	print	Prg_Su_S

DEF11B:
	ld	a,(F_R)
	or	a			; restart?
	jr	nz,Reset1

	ld	a,(F_A)
	or	a			; auto mode?
	jp	nz,Exit
	jp	MainM	

Reset1:
; Restore slot configuration!
        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT

	xor	a
	ld	(AddrFR),a
	ld	a,#38
	ld	(CardMDR),a
	ld	hl,RSTCFG
	ld	de,R1Mask
	ld	bc,26
	ldir

	in	a,(#F4)			; read from F4 port on MSX2+
	or	#80
	out	(#F4),a			; avoid "warm" reset on MSX2+

	rst	#30			; call to BIOS
	db	0			; slot
	dw	0			; address


;-----------------------------------------------------------------------------
LoadImage:
; Erase block's and load ROM-image

; Reopen file image

        ld      bc,24			; Prepare the FCB
        ld      de,FCB+13
        ld      hl,FCB+12
        ld      (hl),b
        ldir                    	; Initialize the second half with zero
	ld	de,FCB
	ld	c,_FOPEN
	call	DOS			; Open file
	ld      hl,1
	ld      (FCB+14),hl     	; Record size = 1 byte
	or	a
	jr	z,LIF01			; file open
	print	F_NOT_F_S
	ret
LIF01:	ld      c,_SDMA
	ld      de,BUFTOP
	call    DOS

; loading ROM-image to RAM
LIFM1:
        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT
	ld	a,#34			; RAM instead of ROM, Bank write enabled, 8kb pages, control off
	ld	(R2Mult),a		; set value for Bank2

	ld	a,(Record+02)		; start block (absolute block 64kB), 4 for RAM/Flash
	ld	(EBlock),a
	ld	(AddrFR),a
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT

	xor	a
	ld	(PreBnk),a		; no shift for the first block

	print	LFRI_S

; calc loading cycles
; Size 3 = 0 ( or oversize )
; Size 2 (x 64 kB ) - cycles for (Eblock) 
; Size 1,0 / 2000h - cycles for RAMProg portions

;Size / #2000 
	ld	h,0
	ld	a,(Size+2)
	ld	l,a
	xor	a
	ld	a,(Size+1)
	rl	a
	rl	l
	rl	h			; 00008000
	rl	a
	rl	l
	rl	h			; 00004000
	rl	a
	rl	l
	rl	h			; 00002000
	ld	b,a
	ld	a,(Size)
	or	b
	jr	z,Fpr03
	inc	hl			; rounding up
Fpr03:	ld	(C8k),hl		; save Counter 8kB blocks

Fpr02:	

; !!!! file attribute fix by Alexey !!!!
	ld	a,(FCB+#0D)
	cp	#20
	jr	z,Fpr02a
	ld	a,#20
	ld	(FCB+#0D),a
; !!!! file attribute fix by Alexey !!!!

;load portion from file
Fpr02a:	ld	c,_RBREAD
	ld	de,FCB
	ld	hl,#2000
	call	DOS
	ld	a,h
	or	l
	jp	z,Ld_Fail
;program portion
	ld	hl,BUFTOP
	ld	de,#8000
	ld	bc,#2000
 
	call	RAMProg			; save part of file to RAM
	jp	c,PRR_Fail

	ld	e,">"			; indicator
	ld	c,_CONOUT
	call	DOS
	ld	a,(PreBnk)
	inc	a			; next PreBnk 
	and	7
	ld	(PreBnk),a	
	jr	nz,FPr01
	ld	hl,EBlock
	inc	(hl)	
FPr01:	ld	bc,(C8k)
	dec	bc
	ld	(C8k),bc
	ld	a,c
	or	b
	jr	nz,Fpr02	

; finishing loading ROMimage

        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT
	ld	a,#A4			; RAM instead of ROM, Bank write disabled, 8kb pages, control on
	ld	(R2Mult),a		; set value for Bank2

        ld      a,(TPASLOT2)
        ld      h,#80
        call    ENASLT          	; Select Main-RAM at bank 8000h~BFFFh

	ret


SaveDIR:
; save directory record
        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT
	ld	a,#15
	ld	(R2Mult),a		; set 16kB Bank write
	xor	a
	ld	(EBlock),a
	ld	(AddrFR),a
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT
 
	ld	a,1	
	ld	(PreBnk),a

        ld      a,(ERMSlt)
        ld      h,#80
        call    ENASLT

	ld	a,(Record)
	ld	d,a
	call	c_dir			; calc address directory record
	push	ix
	pop	de			; set flash destination

	xor	a
	ld	(Record+03),a		; correct image size for RAM -> 0

	ld	a,(RCPData)
	or	a			; RCP data available?
	jr	z,SaveDIR0

	push	de
	ld	hl,RCPData
	ld	de,Record+#04
	ld	a,(hl)
	ld	(de),a			; copy mapper type
	inc	hl
	ld	de,Record+#23
	ld	bc,29
	ldir				; copy the RCP record to directory record
	pop	de

SaveDIR0:
	ld	a,(protect)
	or	a
	jr	nz,SaveDIR1

	ld	a,(Record+#26)
	or	#10			; set protect bit to 1 (unprotected)
	ld	(Record+#26),a		; Bank 0
	ld	a,(Record+#2C)
	or	#10			; set protect bit to 1 (unprotected)
	ld	(Record+#2C),a		; Bank 1
	ld	a,(Record+#32)
	or	#10			; set protect bit to 1 (unprotected)
	ld	(Record+#32),a		; Bank 2
	ld	a,(Record+#38)
	or	#10			; set protect bit to 1 (unprotected)
	ld	(Record+#38),a		; Bank 3
	jr	SaveDIR2

SaveDIR1:
	ld	a,(Record+#26)
	and	#EF			; set protect bit to 0 (protected)
	ld	(Record+#26),a		; Bank 0
	ld	a,(Record+#2C)
	and	#EF			; set protect bit to 0 (protected)
	ld	(Record+#2C),a		; Bank 1
	ld	a,(Record+#32)
	and	#EF			; set protect bit to 0 (protected)
	ld	(Record+#32),a		; Bank 2
	ld	a,(Record+#38)
	and	#EF			; set protect bit to 0 (protected)
	ld	(Record+#38),a		; Bank 3

SaveDIR2:
	ld	hl,Record		; set source
	ld	bc,#40			; record size
	call	FBProg			; save
	jr	c,PR_Fail

LIF04:
; file close
	push	af
	ld	de,FCB
	ld	c,_FCLOSE
	call	DOS

	ld	a,(TPASLOT1)		; reset 1 page
	ld	h,#40
	call	ENASLT
	ld	a,(TPASLOT2)		; reset 1 page
	ld	h,#80
	call	ENASLT

	pop	af
	ret

PR_Fail:
	print	ONE_NL_S
	print	FL_erd_S
	print	ONE_NL_S
	scf				; set carry flag because of an error
	jr	LIF04

PRR_Fail:
	print	ONE_NL_S
	print	FL_er_S
	print	ONE_NL_S
	scf				; set carry flag because of an error
	jr	LIF04

Ld_Fail:
	print	ONE_NL_S
	print	FR_ER_S
	print	ONE_NL_S
	scf				; set carry flag because of an error
	jr	LIF04


FBProg:
; Block (0..2000h) programm to Flash
; hl - buffer source
; de = Flash destination
; bc - size
; (Eblock),(Eblock0) - start address in Flash
; output CF - failed flag
	exx
        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT  
	ld	a,(PreBnk)
	ld	(R2Reg),a
	ld	a,(EBlock)
	ld	(AddrFR),a
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT
        ld      a,(ERMSlt)
        ld      h,#80
        call    ENASLT 
	ld	hl,#8AAA
	ld	de,#8555
	exx
	di
Loop1:
	exx
	ld	(hl),#AA		; (AAA)<-AA
	ld	a,#55		
	ld	(de),a			; (555)<-55
	ld	(hl),#A0		; (AAA)<-A0
	exx
	ld	a,(hl)
	ld	(de),a			; byte programm

	call	CHECK			; check
	jp	c,PrEr
	inc	hl
	inc	de
	dec	bc
	ld	a,b
	or	c
	jr	nz,Loop1
	jr	PrEr


RAMProg:
; Block (0..2000h) program to RAM
; hl - buffer source
; de = #8000
; bc - Length
; (Eblock)x64kB, (PreBnk)x8kB(16kB) - start address in RAM
; output CF - failed flag
	exx
        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT  
	ld	a,(PreBnk)
	ld	(R2Reg),a
	ld	a,(EBlock)
	ld	(AddrFR),a
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT
        ld      a,(ERMSlt)
        ld      h,#80
        call    ENASLT 
	exx
	di

Loop2:
	ld	a,(hl)			; 1st byte copy
	ld	(de),a
	inc	hl
	inc	de
	ld	a,(hl)			; 2nd byte copy
	ld	(de),a
	call	CHECK			; check
	jp	c,PrEr
	inc	hl
	inc	de
	dec	bc
	dec	bc
	ld	a,b
	or	c
	jr	nz,Loop2
PrEr:
; save flag (CF - fail)
	push	af
	ei

        ld      a,(TPASLOT2)
        ld      h,#80
        call    ENASLT          	; Select Main-RAM at bank 8000h~BFFFh
	pop	af
	exx
	ret


;**********************
CHECK:
    	push	bc
    	ld	c,a
CHK_L1: ld	a,(de)
    	xor	c
    	jp	p,CHK_R1		; Jump if readed bit 7 = written bit 7
    	xor	c
    	and	#20
    	jr	z,CHK_L1		; Jump if readed bit 5 = 1
    	ld	a,(de)
    	xor	c
    	jp	p,CHK_R1		; Jump if readed bit 7 = written bit 7
    	scf
CHK_R1:	pop bc
	ret	


; Search free DIR record
; output A - DIR number, otherwise NZ - free record found
FrDIR:
	ld	a,(ERMSlt)
	ld	h,#40			; set 1 page
	call	ENASLT

	ld	hl,B2ON
	ld	de,CardMDR+#0C		; set Bank2
	ld	bc,6
	ldir
 
	ld	a,(ERMSlt)		; set 2 page
	ld	h,#80
	call	ENASLT
	ld	a,1
	ld	(CardMDR+#0E),a 	; set 2nd bank to directory map

	ld	d,0
FRD02:	call	c_dir
	ld	a,(ix)
	cp	#ff			; empty or last record?
	jr	nz,FRD00
	ld	a,(ix+1)
	cp	#ff			; active record?
	jr	nz,FRD00
	ld	a,d
	cp	#ff			; last record?
	jr	nz,FRD01
FRD00:	inc	d
	ld	a,d
	or	a
	jr	nz,FRD02		; next DIR
	xor	a
	or	a
	jr	FRD03			; not found Zero
FRD01:	ld	a,d
	or	a			; not zero?
FRD03:	push	af
	ld	a,(TPASLOT1)		; reset 1 page
	ld	h,#40
	call	ENASLT
	ld	a,(TPASLOT2)		; reset 2 page
	ld	h,#80
	call	ENASLT
	pop	af
	ret


B1ON:	db	#F8,#50,#00,#85,#03,#40
B2ON:	db	#F0,#70,#01,#15,#7F,#80
B23ON:	db	#F0,#80,#00,#04,#7F,#80
	db	#F0,#A0,#00,#34,#7F,#A0


c_dir:
; input d - dir idex num
; outut	ix - dir point enter
; output Z - last/empty/deleted entry
 	ld	b,0
	or	a 
	ld	a,d
	rl	a
	rl	b
	rl	a
	rl	b
	rl	a
	rl	b
	rl	a
	rl	b
	rl	a
	rl	b
	rl	a
	rl	b
	ld	c,a
	ld	ix,#8000
	add	ix,bc			; 8000h + b*64

	ld	a,(ix)
	cp	#FF			; last record?
	ret	z

	ld	a,(ix+1)
	or	a			; deleted record ?
	ret

;-------------------------------
TTAB:
;	ld	b,(DMAP)
	inc	b
	ld	hl,CARTTAB
	ld	de,64
TTAB1:	dec	b
	ret	z
	add	hl,de
	jr	TTAB1


FrErr:
; file close
	ld	de,FCB
	ld	c,_FCLOSE
	call	DOS
; print error
	ld	de,FR_ER_S
	ld	c,_STROUT
	call	DOS
; return main	
	ld	a,(F_A)
	or	a
	jr	nz,Exit			; Automatic exit
	jp	MainM		

Exit:
	ld      a,(TPASLOT2)
        ld      h,#80
        call    ENASLT
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT

	xor	a
	ld	(CURSF),a

	ld	de,EXIT_S
	jp	termdos



;-----------------------------------------------------------------------------

FnameP:
; File Name prepearing
; input	ix - buffer file name
; output - FCB	
	ld	b,8+3
	ld	hl,FCB
	ld	(hl),0
fnp3:	inc	hl
	ld	(hl)," "
	djnz	fnp3	

        ld      bc,24			; Prepare the FCB
        ld      de,FCB+13
        ld      hl,FCB+12
        ld      (hl),b
        ldir                    	; Initialize the second half with zero
;
; File name processing
	ld	hl,FCB+1
;	ld	ix,BUFFER

	ld	b,8
	ld	a,(ix+1)
	cp	":"
	jr	nz,fnp0
; device name
	ld	a,(ix)
	and	a,%11011111
	sub	#40
	ld	(FCB),a
	inc	ix
	inc	ix
; file name
fnp0:	ld	a,(ix)
	or	a
	ret	z
	cp	"."
	jr	z,fnp1
	ld	(hl),a
	inc	ix
	inc	hl
	djnz	fnp0
	ld	a,(ix)
	cp	"."
	jr	z,fnp1
	dec	ix
; file ext
fnp1:
	ld	hl,FCB+9
	ld	b,3
fnp2:	ld	a,(ix+1)
	or 	a
	ret	z
	ld	(hl),a
	inc	ix
	inc	hl
	djnz	fnp2	

	ret


; Output one symbol
SymbOut:
	push	af
	ld	e,a
	ld	c,_CONOUT
	call	DOS
	pop	af
	ret


FindSlot:
; Auto-detection 
	ld	ix,TRMSlt		; Tabl Find Slt cart
        ld      b,3             	; B=Primary Slot
BCLM:
        ld      c,0             	; C=Secondary Slot
BCLMI:
        push    bc
        call    AutoSeek
        pop     bc
        inc     c
	bit	7,a	
	jr      z,BCLM2			; not extended slot	
        ld      a,c
        cp      4
        jr      nz,BCLMI		; Jump if Secondary Slot < 4
BCLM2:  dec     b
        jp      p,BCLM			; Jump if Primary Slot < 0
	ld	a,#FF
	ld	(ix),a			; finish autodetect
; slot analise
	ld	ix,TRMSlt
	ld	a,(ix)
	or	a
	jr	z,BCLNS			; No detection
; print slot table
	ld	(ERMSlt),a		; save first detected slot

	print	Findcrt_S

BCLT1:	ld	a,(ix)
	cp	#FF
	jr	z,BCLTE
	and	3
	add	a,"0"
	ld	c,_CONOUT
	ld	e,a
	call	DOS			; print primary slot number
	ld	a,(ix)
	bit	7,a
	jr	z,BCLT2			; not extended
	rrc	a
	rrc	a
	and	3
	add	a,"0"
	ld	e,a
	ld	c,_CONOUT
	call	DOS			; print extended slot number
BCLT2:	ld	e," "
	ld	c,_CONOUT
	call	DOS	
	inc	ix
	jr	BCLT1

BCLTE:
	ld	a,(F_A)
	or	a               
	jr	nz,BCTSF 		; Automatic flag (No input slot)
	print	FindcrI_S
	jp	BCLNE
BCLNS:
	print	NSFin_S
	jp	BCLNE1
BCLNE:
	ld	a,(F_A)
	or	a
	jr	nz,BCTSF 		; Automatic flag (No input slot)

; input slot number
BCLNE1:	ld	de,Binpsl
	ld	c,_BUFIN
	call	DOS
	ld	a,(Binpsl+1)
	or	a
	jr	z,BCTSF			; no input slot
	ld	a,(Binpsl+2)
	sub	a,"0"
	and	3
	ld	(ERMSlt),a
	ld	a,(Binpsl+1)
	cp	2
	jr	nz,BCTSF		; no extended
	ld	a,(Binpsl+3)
	sub	a,"0"
	and	3
	rlc	a
	rlc	a
	ld	hl,ERMSlt
	or	(hl)
	or	#80
	ld	(hl),a	

BCTSF:
; test flash
;*********************************
	ld	a,(ERMSlt)
;TestROM:
	ld	(cslt),a
	ld	h,#40
	call	ENASLT
	ld	a,#21
	ld	(CardMDR),a
	ld	hl,B1ON
	ld	de,CardMDR+#06		; set Bank1
	ld	bc,6
	ldir

	ld	a,#95			; enable write  to bank (current #85)
	ld	(R1Mult),a  

	di
	ld	a,#AA
	ld	(#4AAA),a
	ld	a,#55
	ld	(#4555),a
	ld	a,#90
	ld	(#4AAA),a		; Autoselect Mode ON

	ld	a,(#4000)
	ld	(Det00),a		; Manufacturer Code 
	ld	a,(#4002)
	ld	(Det02),a		; Device Code C1
	ld	a,(#401C)
	ld	(Det1C),a		; Device Code C2
	ld	a,(#401E)
	ld	(Det1E),a		; Device Code C3
	ld	a,(#4006)
	ld	(Det06),a		; Extended Memory Block Verify Code

	ld	a,#F0
	ld	(#4000),a		; Autoselect Mode OFF
	ei
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT          	; Select Main-RAM at bank 4000h~7FFFh

	
; Print result
	
	print 	SltN_S
	ld	a,(cslt)
	ld	b,a
	cp	#80
	jp	nc,Trp01		; exp slot number
	and	3
	jr	Trp02
Trp01:	rrc	a
	rrc	a
	and	%11000000
	ld	c,a
	ld	a,b
	and	%00001100
	or	c
	rrc	a
	rrc	a
Trp02:	call	HEXOUT	
	print	ONE_NL_S

	ld	a,(F_V)			; verbose mode?
	or	a
	jr	z,Trp02a

	print	MfC_S
	ld	a,(Det00)
	call	HEXOUT
	print	ONE_NL_S

	print	DVC_S
	ld	a,(Det02)
	call	HEXOUT
	ld	e," "
	ld	c,_CONOUT
	call	DOS	
	ld	a,(Det1C)
	call	HEXOUT
	ld	e," "
	ld	c,_CONOUT
	call	DOS
	ld	a,(Det1E)
	call	HEXOUT
	print	ONE_NL_S

	print	EMB_S
	ld	a,(Det06)
	call	HEXOUT
	print	ONE_NL_S

Trp02a:	ld	a,(Det00)
	cp	#20
	jr	nz,Trp03	
	ld	a,(Det02)
	cp	#7E
	jr	nz,Trp03
	print	M29W640
	ld	e,"x"
	ld	a,(Det1C)
	cp	#0C
	jr	z,Trp05
	cp	#10
	jr	z,Trp08
	jr	Trp04
Trp05:	ld	a,(Det1E)
	cp	#01
	jr	z,Trp06
	cp	#00
	jr	z,Trp07
	jr	Trp04
Trp08:	ld	a,(Det1E)
	cp	#01
	jr	z,Trp09
	cp	#00
	jr	z,Trp10
	jr	Trp04
Trp06:	ld	e,"H"
	jr	Trp04
Trp07:	ld	e,"L"
	jr	Trp04
Trp09:	ld	e,"T"
	jr	Trp04
Trp10:	ld	e,"B"
Trp04:	ld	c,_CONOUT
	call	DOS
	print	ONE_NL_S

	ld	a,(Det06)
	cp	80
	jp	c,Trp11		

	ld	a,(F_V)			; verbose mode?
	or	a
	ret	z

	print	EMBF_S
	xor	a
	ret
Trp11:
	ld	a,(F_V)			; verbose mode?
	or	a
	ret	z

	print	EMBC_S	
	xor	a
	ret	
Trp03:
	print	NOTD_S
	scf
	ret


;---- Out to conlose HEX byte
; A - byte
HEXOUT:
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
	ret
HEX:
;--- HEX
; input  a- Byte
; output a - H hex symbol
;        b - L hex symbol
	ld	c,a
	and 	#0F
	add	a,48
	cp	58
	jr	c,he2
	add	a,7
he2:	ld	b,a
	ld	a,c
	rrc     a
	rrc     a
	rrc     a
	rrc     a
	and 	#0F
	add	a,48
	cp	58
	ret	c
	add	a,7	
   	ret


NO_FND:
;
AutoSeek:
; return reg A - slot
;	    
;	     
	ld	a,b
	xor	3			; Reverse the bits to reverse the search order (0 to 3)
	ld	hl,MNROM
	ld	d,0
	ld	e,a
	add	hl,de
	bit	7,(hl)
	jr	z,primSlt		; Jump if slot is not expanded
	or	(hl)			; Set flag for secondary slot
	sla	c
	sla	c
	or	c			; Add secondary slot value to format FxxxSSPP
primSlt:
	ld	(ERMSlt),a
; ---
;	ld	b,a			; Keep actual slot value
;
;	bit	7,a
;	jr	nz,SecSlt		; Jump if Secondary Slot
;	and	3			; Keep primary slot bits
;SecSlt:
;	ld	c,a
;
;	ld	a,b			; Restore actual slot value
; ---
	ld	h,#40
	call	ENASLT			; Select a Slot in Bank 1 (4000h ~ 7FFFh)

	ld	hl,ADESCR
	ld	de,DESCR
	ld	b,7
ASt00	ld	a,(de)
	cp	(hl)
	ret	nz
	inc	hl
	inc	de
	djnz	ASt00
	ld	a,(ERMSlt)
	ld	(ix),a
	inc	ix
	ret

Testslot:
	ld	a,(ERMSlt)
	ld	h,#40
	call	ENASLT

	ld	hl,ADESCR
	ld	de,DESCR
	ld	b,7
ASt01:	ld	a,(de)
	cp	(hl)
	jr	nz,ASt02
	inc	hl
	inc	de
	djnz	ASt01
	jr	ASt03
ASt02:
	ld	de,DESCR
	ld	b,7
ASt04:	ld	a,(de)
	cp	#FF
	jr	nz,ASt03
	inc	de
	djnz	ASt04
ASt03:
	push	af
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT	
	pop	af
	ret


HEXA:
; HEX symbol (A) to halfbyte (A)
	cp	"0"
	ret	c			; < "0"
	cp	"9"+1
	jr	nc,hexa1		; > "9"
	sub	"0"
	ret
hexa1:	and	%11011111		; (inv #20) abc -> ABC
	cp	"A"
	ret	c			; < "A"
	cp	"F"+1
	jr	c,hexa2
	scf
	ret
hexa2:	sub	"A"-#A
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


termdos:
	ld	c,_STROUT
	call	DOS

	ld	c,_TERM0
	jp	DOS



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


F_Key:
; Input A - Num parameter
; Output C,Z Flags, set key variable

	ld	de,BUFFER
	call	EXTPAR
	ret	c			; no parameter C- Flag
	ld	hl,BUFFER
	ld	a,(hl)
fkey01:	cp	"/"
	ret	nz			; no Flag NZ - Flag
	inc	hl
	ld	a,(hl)
	and	%11011111
	cp	"P"
	jr	nz,fkey02
	ld	a,1
	ld	(F_P),a
	ret
fkey02:	ld	hl,BUFFER+1
	ld	a,(hl)
	and	%11011111
	cp	"A"
	jr	nz,fkey03
	inc	hl
	ld	a,(hl)
	or	a
	jr	nz,fkey03
	ld	a,2
	ld	(F_A),a
	ret
fkey03:	ld	hl,BUFFER+1
	ld	a,(hl)
	and	%11011111
	cp	"V"
	jr	nz,fkey04
	inc	hl
	ld	a,(hl)
	or	a
	jr	nz,fkey04
	ld	a,3
	ld	(F_V),a			; verbose mode flag
	ret
fkey04:	ld	hl,BUFFER+1
	ld	a,(hl)
	and	%11011111
	cp	"H"
	jr	nz,fkey05
	inc	hl
	ld	a,(hl)
	or	a
	jr	nz,fkey05
	ld	a,4
	ld	(F_H),a			; show help
	ret
fkey05:
	ld	hl,BUFFER+1
	ld	a,(hl)
	and	%11011111
	cp	"D"
	jr	nz,fkey06
	inc	hl
	ld	a,(hl)
	or	a
	jr	nz,fkey06
	ld	a,4
	ld	(F_D),a			; disable directory creation
	ret
fkey06:
	ld	hl,BUFFER+1
	ld	a,(hl)
	and	%11011111
	cp	"R"
	jr	nz,fkey07
	inc	hl
	ld	a,(hl)
	or	a
	jr	nz,fkey07
	ld	a,4
	ld	(F_R),a			; reset after loading ROM
	ret
fkey07:
	xor	a
	dec	a			; S - Illegal flag
	ret


;------------------------------------------------------------------------------

; Mapper and directory data areas

RAM_TEMPL:
	db	"R"
	db	"RAM:                          "
	db	#F8,#50,#00,#AC,#3F,#40
	db	#F8,#70,#01,#AC,#3F,#60		
	db      #F8,#90,#02,#AC,#3F,#80		
	db	#F8,#B0,#03,#AC,#3F,#A0	
	db	#FF,#BC,#00,#02,#FF

RSTCFG:
	db	#F8,#50,#00,#85,#03,#40
	db	0,0,0,0,0,0
	db	0,0,0,0,0,0
	db	0,0,0,0,0,0
	db	#FF,#30

CARTTAB: ; (N x 64 byte) 
	db	"U"					;1
	db	"Unknown mapper type              $"	;34
	db	#F8,#50,#00,#A4,#FF,#40			;6
	db	#F8,#70,#01,#A4,#FF,#60			;6	
	db      #F8,#90,#02,#A4,#FF,#80			;6	
	db	#F8,#B0,#03,#A4,#FF,#A0			;6
	db	#FF,#BC,#00,#02,#FF			;5

CRTT1:	db	"k"
	db	"Konami (Konami 4)                $"
	db	#F8,#50,#00,#24,#FF,#40			
	db	#F8,#60,#01,#A4,#FF,#60				
	db      #F8,#80,#02,#A4,#FF,#80				
	db	#F8,#A0,#03,#A4,#FF,#A0			
	db	#FF,#AC,#00,#02,#FF
CRTT2:	db	"K"
	db	"Konami SCC (Konami 5)            $"
	db	#F8,#50,#00,#A4,#FF,#40			
	db	#F8,#70,#01,#A4,#FF,#60				
	db      #F8,#90,#02,#A4,#FF,#80				
	db	#F8,#B0,#03,#A4,#FF,#A0			
	db	#FF,#BC,#00,#02,#FF
CRTT3:	db	"a"
	db	"ASCII 8 bit                      $"
	db	#F8,#60,#00,#A4,#FF,#40			
	db	#F8,#68,#01,#A4,#FF,#60				
	db      #F8,#70,#02,#A4,#FF,#80				
	db	#F8,#78,#03,#A4,#FF,#A0			
	db	#FF,#AC,#00,#02,#FF
CRTT4:	db	"A"
	db	"ASCII 16 bit                     $"		
	db	#F8,#60,#00,#A5,#FF,#40			
	db	#F8,#70,#01,#A5,#FF,#80				
	db      #F8,#70,#02,#28,#3F,#80				
	db	#F8,#78,#03,#28,#3F,#A0			
	db	#FF,#8C,#00,#01,#FF
CRTT5:	db	"M"
	db	"Mini ROM (without mapper)        $"		
	db	#F8,#60,#00,#26,#7F,#40			
	db	#F8,#70,#01,#28,#7F,#80				
	db      #F8,#70,#02,#28,#3F,#C0				
	db	#F8,#78,#03,#28,#3F,#A0			
	db	#FF,#8C,#07,#01,#FF
	
	db	0			; end of mapper table

;
;Variables
;
protect:
	db	1
DOS2:	db	0
ShadowMDR
	db	#21
ERMSlt	db	1
TRMSlt	db	#FF,#FF,#FF,#FF,#FF,#FF,#FF,#FF,#FF
Binpsl	db	2,0,"1",0
slot:	db	1
cslt:	db	0
Det00:	db	0
Det02:	db	0
Det1C:	db	0
Det1E:	db	0
Det06:	db	0
;Det04:	ds	134
DMAP:	db	0
DMAPt:	db	1
BMAP:	ds	2
Dpoint:	db	0,0,0
StartBL:
	ds	2
C8k:	dw	0
PreBnk:	db	0
EBlock0:
	db	0
EBlock:	db	0
strp:	db	0
strI:	dw	#8000
ROMEXT:	db	".ROM",0

Bi_FNAM db	14,0,"D:FileName.ROM",0
;--- File Control Block
FCB:	db	0
	db	"           "
	ds	28
	db	0

FCBRCP:	db	0
	db	"           "
	ds	28
	db	0

RCPExt:	db	"RCP"

FILENAME:
	db	"                                $"
	db	0
Size:	db	0,0,0,0
Record:	ds	#40
SRSize:	db	0
multi	db	0
ROMABCD:
	db	0
ROMJT0:	db	0
ROMJT1:	db	0
ROMJT2:	db	0
ROMJI0:	db	0
ROMJI1:	db	0
ROMJI2:	db	0

DIRCNT:	db	0,0
DIRPAG:	db	0,0
CURPAG:	db	0,0

; /-flags parameter
F_H	db	0
F_P	db	0
F_A	db	0
F_V	db	0
F_D	db	0
F_R	db	0
p1e	db	0

ZeroB:	db	0

Space:
	db	" $"
Bracket:
	db	" ",124," $"

FCBROM:	
	db	0
	db	"????????ROM"
	ds	28

BUFFER:	ds	256
	db	0,0,0


;------------------------------------------------------------------------------

;
; Text strings
;

DESCR:	db	"CMFCCFRC"
ABCD:	db	"0123456789ABCDEF"

ssrMAP:	db	"64kb or more (mapper is required)$"
ssr64:	db	"64kb$"
ssr48:	db	"48kb$"
ssr32:	db	"32kb$"
ssr16:	db	"16kb$"
ssr08:	db	"8kb or less$"

MAIN_S:	db	13,10
	db	"Main Menu",13,10
	db	"---------",13,10
	db	" 1 - Write ROM image into cartridge's RAM with protection",13,10
	db	" 2 - Write ROM image into cartridge's RAM without protection",13,10
	db	" 3 - Restart the computer",13,10
	db	" 0 - Exit to MSX-DOS",13,10,"$"

EXIT_S:	db	10,13,"Thanks for using the RBSC's products!",13,10,"$"
ANIK_S:
	db	"Press any key to continue",13,10,"$"
ADD_RI_S:
	db	13,10,"Input full ROM's file name or just press Enter to select files: $"
SelMode:
	db	10,13,"Selection mode: TAB - next file, ENTER - select, ESC - exit",10,13,"Found file(s):",9,"$"
NoMatch:
	db	10,13,"No ROM files found in the current directory!",10,13,"$"
OpFile_S:
	db	10,13,"Opening file: ","$"
RCPFound:
	db	"RCP file with the same name found!"
	db	10,13,"Use loaded RCP data for this ROM? (y/n)",10,13,"$"
UsingRCP:
	db	"Autodetection ignored, using data from RCP file...",10,13,"$"
F_NOT_F_S:
	db	"File not found!",13,10,"$"
F_NOT_FS:
	db	13,10,"File not found!","$"
FSizE_S:
	db	"File size error!",13,10,"$"
FR_ER_S:
	db	"File read error!",13,10,"$"
FR_ERS:
	db	13,10,"File read error!","$"
FR_ERW_S:
	db	13,10,"File write error!","$"
FR_ERC_S:
	db	13,10,"File create error!","$"
Analis_S:
	db 	"Detecting ROM's mapper type: $"
SelMapT:
	db	"Selected ROM's mapper type: $"
NoAnalyze:
	db	"The ROM's mapper type is set to: $"
MROMD_S:
	db	"ROM's file size: $" 
CTC_S:	db	"Do you confirm this mapper type? (y/n)",10,13,"$"
CoTC_S:	db	10,13,"Manual mapper type selection:",13,10,"$"
Num_S:	db	"Your selection - $"
FileOver_S:
	db	"File is too big to be loaded into the cartridge's RAM!",13,10
	db	"You can only upload ROM files up to 720kb into RAM.",13,10
	db	"Please select another file...",13,10,"$"
MRSQ_S:	db	10,13,"The ROM's size is between 32kb and 64kb. Create Mini ROM entry? (y/n)",13,10,"$"
Strm_S:	db	"MMROM-CSRM: $"
FNRE_S:	db	"Using Record-FBlock-NBank for Mini ROM",#0D,#0A
	db	"[Multi ROM entry] - $"
DirOver_S:
	db	"No more free directory entries!",13,10
	db	"Please optimize the directory with c2man utility...",13,10,"$"
FDE_S:	db	"Found free directory entry at: $"
NR_I_S:	db	"Name of directory entry: $"
FileSZH:
	db	"File size (hexadecimal): $"
NR_L_S: db	"Press ENTER to confirm or input a new name below:",13,10,"$"
LFRI_S:	db	"Writing ROM image, please wait...",13,10,"$"
Prg_Su_S:
	db	13,10,"The ROM image was successfully written into cartridge's RAM!"
	db	13,10,"Please reboot (NO POWER OFF!) your MSX now...",13,10,"$"
FL_er_S:
	db	13,10,"Writing into cartridge's RAM failed!",13,10,"$"
FL_erd_S:
	db	13,10,"Writing directory entry failed!",13,10,"$"
CreaDir:
	db      "Create directory entry for the loaded ROM? (y/n)$"
LOAD_S: db      "Ready to write the ROM image. Proceed? (y/n)$"
TWO_NL_S:
	db	13,10
ONE_NL_S:
	db	13,10,"$"
CLS_S:	db	27,"E$"
CLStr_S:
	db	27,"K$"
MD_Fail:
	db	"FAILED...",13,10,"$"
TestRDT:
	db	"ROM's descriptor table:",10,13,"$"

PRESENT_S:
	db	3
	db	"Carnivore2 MultiFunctional Cartridge RAM Loader v1.32",13,10
	db	"(C) 2015-2020 RBSC. All rights reserved",13,10,13,10,"$"
NSFin_S:
	db	"Carnivore2 cartridge was not found. Please specify its slot number - $"
Findcrt_S:
	db	"Found Carnivore2 cartridge in slot(s): $"
M_Wnvc:
	db	10,13,"WARNING!",10,13
	db	"Uninitialized cartridge or wrong version of Carnivore cartridge found!",10,13
	db	"Only Carnivore2 cartridge is supported. The program will now exit.",10,13
	db	"Press any key...",10,13,"$"
FindcrI_S:
	db	13,10,"Press ENTER for the found slot or input new slot number - $"

SltN_S:	db	13,10,"Using slot - $"

M29W640:
        db      "FlashROM chip detected: M29W640G$"
NOTD_S:	db	13,10,"FlashROM chip's type is not detected!",13,10
	db	"This cartridge is not open for writing or may be defective!",13,10
	db	"Try to reboot and hold down F5 key...",13,10 
	db	"$"
MfC_S:	db	"Manufacturer's code: $"
DVC_S:	db	"Device's code: $"
EMB_S:	db	"Extended Memory Block: $"
EMBF_S:	db	"EMB Factory Locked",13,10,"$"
EMBC_S:	db	"EMB Customer Lockable",13,10,"$"

I_FLAG_S:
	db	"Incorrect flag!",13,10,13,10,"$"
I_PAR_S:
	db	"Incorrect parameter!",13,10,13,10,"$"
I_MPAR_S:
	db	"Too many parameters!",13,10,13,10,"$"
H_PAR_S:
	db	"Usage:",13,10,13,10
	db	" c2ramldr [filename.rom] [/h] [/v] [/a] [/p] [/d] [/r]",13,10,13,10
	db	"Command line options:",13,10
	db	" /h  - this help screen",13,10
	db	" /v  - verbose mode (show detailed information)",13,10
	db	" /p  - switch RAM protection off after copying the ROM",10,13
	db	" /d  - don't create a directory entry for the uploaded ROM",13,10
	db	" /a  - autodetect and write ROM image (no user interaction)",13,10
	db	" /r  - restart the computer after uploading the ROM",10,13,"$"

RCPData:
	ds	30

	db	0,0,0
	db	"RBSC:PTERO/WIERZBOWSKY/DJS3000/PENCIONER/GREYWOLF:2020"
	db	0,0,0

BUFTOP:
;
; End of code, further space is reserved for working with data and cartridge's registers
;

