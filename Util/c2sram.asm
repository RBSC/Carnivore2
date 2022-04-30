;
; Carnivore2 Cartridge's SRAM Manager
; Copyright (c) 2015-2020 RBSC
; Version 1.07
;


;--- Macro for printing a $-terminated string

print	macro	
	ld	de,\1
	ld	c,_STROUT
	call	DOS
	endm


;--- System calls and variables

DOS	equ	#0005		; DOS function calls entry point
ENASLT	equ	#0024		; BIOS Enable Slot
WRTSLT	equ	#0014		; BIOS Write to Slot
CALLSLT	equ	#001C		; Inter-slot call
SCR0WID	equ	#F3AE		; Screen0 width
CURSF	equ	#FCA9

TPASLOT1	equ	#F342
TPASLOT2	equ	#F343

CSRY	equ	#F3DC
CSRX	equ	#F3DD
ARG:	equ	#F847
EXTBIO:	equ	#FFCA
MNROM:	equ	#FCC1		; Main-ROM Slot number & Secondary slot flags table

SRAMBLK equ	#0F		; SRAM bank (#0F - last logical block of 1mb of RAM)
SRAMBNK	equ	#07		; Last 8kb page of the block (#07=#E000)

CardMDR:equ	#4F80
AddrM0: equ	#4F80+1
AddrM1: equ	#4F80+2
AddrM2: equ	#4F80+3
DatM0:	equ	#4F80+4

AddrFR: equ	#4F80+5

R1Mask: equ	#4F80+6
R1Addr: equ	#4F80+7
R1Reg:  equ	#4F80+8
R1Mult: equ	#4F80+9
B1MaskR:equ	#4F80+10
B1AdrD:	equ	#4F80+11

R2Mask: equ	#4F80+12
R2Addr: equ	#4F80+13
R2Reg:  equ	#4F80+14
R2Mult: equ	#4F80+15
B2MaskR:equ	#4F80+16
B2AdrD:	equ	#4F80+17

R3Mask: equ	#4F80+18
R3Addr: equ	#4F80+19
R3Reg:  equ	#4F80+20
R3Mult: equ	#4F80+21
B3MaskR:equ	#4F80+22
B3AdrD:	equ	#4F80+23

R4Mask: equ	#4F80+24
R4Addr: equ	#4F80+25
R4Reg:  equ	#4F80+26
R4Mult: equ	#4F80+27
B4MaskR:equ	#4F80+28
B4AdrD:	equ	#4F80+29

CardMod:equ	#4F80+30

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

	xor	a
	ld	(F_A),a			; Automatic flag not active by default

; Command line options processing
	ld	a,1
	call	F_Key			; C- no parameter; NZ- not flag; S(M)-ilegal flag
	jr	c,Stfp010
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
	jr	z,Stfp01
	print	I_MPAR_S
	jr	Stfp09

Stfp01:
	ld	a,(F_H)
	or	a
	jr	nz,Stfp09

	ld	a,(F_D)
	or	a
	jr	z,Stfp08
	ld	a,1
	ld	(F_A),a			; Automatic flag active
	jr	Stfp010
Stfp08:
	ld	a,(F_U)
	or	a
	jr	z,Stfp010
	ld	a,1
	ld	(F_A),a			; Automatic flag active

Stfp010:
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
	jr	z,MainM			; no file parameter?

	ld	a,1
	ld	de,BUFFER
	call	EXTPAR
	jr	c,MainM			; No parameter

	ld	ix,BUFFER
	call	FnameP

	ld	a,(F_U)
	or	a
	jp	nz,ADD_OF

Stfp40:
	ld	a,(F_D)
	or	a
	jr	z,MainM
	ld	hl,FCB
	ld	de,FCB2
	ld	bc,1+8+3
	ldir				; copy prepared fcb to fcb2

	jp	rdt921


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
	cp	"0"
	jp	z,Exit
	cp	"1"
	jp	z,DownSRAM
	cp	"2"
	jp	z,UploadSRAM
	cp	"3"
	jr	z,DoReset
	jr	Ma01


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
; Download SRAM's contents into a file
;
DownSRAM:
        print   SRM_FNM
	call	GetFname
	jp	nz,DownSR
	print	ONE_NL_S
	jp	MainM

DownSR:
; test if file exists
	ld	de,FCB2
	ld	c,_FSEARCHF		; Search First File
	call	DOS
	or	a
	jr	nz,rdt921		; file not found

	ld	a,(F_A)
	or	a
	jp	nz,rdt921		; automatic overwrite

	print	F_EXIST_S
rdt922:	ld	c,_INNOE
	call	DOS
	or	%00100000
	call	SymbOut
	cp	"y"
	jp	z,rdt921
	print	ONE_NL_S
	jp	MainM
	
rdt921:
        ld      bc,24         		; Prepare the FCB
        ld      de,FCB2+13
        ld      hl,FCB2+12
        ld      (hl),b
        ldir 

	ld	de,CrFile_S
	ld	c,_STROUT
	call	DOS

	ld	a,(FCB2)
	or 	a
	jr	z,opff1			; dp not print device letter
	add	a,#40			; 1 => "A:"
	ld	e,a
	ld	c,_CONOUT
	call	DOS
	ld	e,":"
	ld	c,_CONOUT
	call	DOS
opff1:	ld	b,8
	ld	hl,FCB2+1
opff2:	push	bc
	push	hl
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS
	pop	hl
	inc	hl
	pop	bc
	djnz	opff2
	ld	e,"."
	ld	c,_CONOUT
	call	DOS
	ld	b,3
	ld	hl,FCB2+9
opff3:	push	bc
	push	hl
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS
	pop	hl
	inc	hl
	pop	bc
	djnz	opff3

	ld	de,FCB2
	ld	c,_FCREATE
	call	DOS
	or	a
	jr	z,rdt923
	print	FR_ERC_S
	print	ONE_NL_S

	ld	a,(F_A)
	or	a
	jp	nz,Exit			; automatic exit
	jp	MainM

rdt923:
	ld      hl,1
	ld      (FCB2+14),hl     	; Record size = 1 byte

	print	ONE_NL_S

	ld	a,SRAMBLK
	ld	(EBlock),a		; shift to the block of RAM where SRAM is located
	ld	a,SRAMBNK
	ld	(PreBnk),a		; shift to the address in block where SRAM is located: 0FE000h-0FFFFFh

        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT
	ld	a,#34			; RAM instead of ROM, Bank write enabled, 8kb pages, control off
	ld	(R2Mult),a		; set value for Bank2
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT

	ld	hl,#8000		; source
	ld	de,BUFTOP		; destination
	ld	bc,#2000		; size
	call	RW_RAM			; read SRAM data to BUFTOP
	jr	nc,rdt997

	print	DATA_ERR
	print	DL_erd_S
	jr	rdt999

rdt997:
	ld      c,_SDMA
	ld      de,BUFTOP
	call    DOS			; set DMA

	ld	hl,8192
	ld	de,FCB2
	ld	c,_RBWRITE
	call	DOS			; write 8192 bytes of SRAM contents
	or	a
	jp	z,rdt998

	print	FR_ERW_S
	print	ONE_NL_S
	jr	rdt999

rdt998:
	print	Success		; print successful operation

rdt999:

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

	ld	de,FCB2
	ld	c,_FCLOSE
	call	DOS

	ld	a,(F_R)
	or	a			; restart?
	jp	nz,Reset1

	ld	a,(F_A)
	or	a			; auto mode?
	jp	nz,Exit

	jp	MainM	

GetFname:
;Bi_FNAM
	ld	de,Bi_FNAM
	ld	c,_BUFIN
	call	DOS
	ld	a,(Bi_FNAM+1)
	or	a
	ret	z

	ld	hl,SRMFN
	ld	de,FCB2
	ld	bc,8+3+1
	ldir

	ld	a,(Bi_FNAM+1)
	ld	b,a
	ld	c,8
	ld	hl,Bi_FNAM+2
	ld	de,FCB2+1
	ld	a,(Bi_FNAM+3)
	cp	":"
	jr	nz,gcn01		; no drive letter
	ld	a,(hl)
	and	%11011111
	sub	"A"-1
	ld	(FCB2),a
	inc	hl
	inc	hl
	dec	b
	ret	z
	dec	b
	ret	z
gcn01:
	ld	a,(hl)
	cp	"."
	jr	z,gcn03			; ext fn detected
	ld	(de),a
	inc	hl
	inc	de
	dec	b
	jr	z,gcn02
	dec	c
	jr	nz,gcn01
gcn05:
	ld	a,(hl)
	cp	"."
	jr	z,gcn03
	inc	hl
	dec	b
	jr	nz,gcn05
	jr	gcn02
gcn03:
	ld	de,FCB2+1+8
	inc	hl
	ld	a," "
	ld	(FCB2+1+8),a
	ld	(FCB2+1+8+1),a
	ld	(FCB2+1+8+2),a
	ld	c,3
gcn04:	dec	b
	jr	z,gcn02
	ld	a,(hl)
	ld	(de),a
	inc	hl
	inc	de
	dec	c
	jr	nz,gcn04

gcn02:
        print   SRM_Name
        ld      bc,24           	; Prepare the FCB
        ld      de,FCB2+13
        ld      hl,FCB2+12
        ld      (hl),b
        ldir 

	ld	hl,FCB2+1
	ld	b,8
gcn06:	push	hl
	push	bc
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS
	pop	bc
	pop	hl
	inc	hl
	djnz	gcn06

	ld	e,"."
	ld	c,_CONOUT
	call	DOS

	ld	hl,FCB2+9
	ld	b,3
gcn07:	push	hl
	push	bc
	ld	e,(hl)
	ld	c,_CONOUT
	call	DOS
	pop	bc
	pop	hl
	inc	hl
	djnz	gcn07

	ld	a,1
	or	a
	ret


;
; Upload file's contents into SRAM
;
UploadSRAM:
	print	WR_SRAM_S
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
USRAM1:
	ld	a,(hl)
	cp	'.'
	jr	z,USRAM2
	or	a
	jr	z,USRAMC
	inc	hl
	djnz	USRAM1

USRAMC:
	ex	de,hl
	ld	hl,SRMEXT		; copy extension and zero in the end
	ld	bc,5
	ldir
	jr	USRAM3

USRAM2:
	inc	hl
	ld	a,(hl)
	or	a
	jr	z,USRAM3
	cp	32			; empty extension?
	jr	c,USRAMC
	
USRAM3:
	ld	ix,Bi_FNAM+2
	call	FnameP
	jp	ADD_OF

SelFile:
	print	SelMode
	ld      c,_SDMA
	ld      de,BUFTOP
	call    DOS

SelFile0:
	ld	de,FCBSRM
	ld	c,_FSEARCHF		; Search First File
	call	DOS
	or	a
	jr	z,SelFile1		; file found!
	print	NoMatch
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
	jp	nz,sf3z
       	print	ONE_NL_S
	jp	MainM
sf3z:
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
	ld	de,ONE_NL_S
	ld	c,_STROUT
	call	DOS

; file open
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
	jp	nz,Exit			; automatic exit

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

; print SRM size in hex
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

	ld	de,ONE_NL_S
	ld	c,_STROUT
	call	DOS	
vrb00:
	ld	hl,(Size)
	ld	a,l
	or	a
	jr	nz,vbr01
	ld	a,h
	cp	#20			; 2000h = 8192 bytes
	jr	z,FMRM01
vbr01:
	print	FileOver_S

	ld	de,FCB
	ld	c,_FCLOSE
	call	DOS

	ld	a,(F_A)
	or	a
	jp	nz,Exit			; automatic exit

	jp	MainM
	
FMRM01:					; fix size

; !!!! file attribute fix by Alexey !!!!
	ld	a,(FCB+#11)
	cp	#20
	jr	nz,DEF10
	ld	a,(FCB+#0D)
	cp	#21
	jr	nz,DEF10
	dec	a
	ld	(FCB+#0D),a
; !!!! file attribute fix by Alexey !!!!

DEF10:
	ld	de,FCB
	ld	c,_FCLOSE
	call	DOS

	call	LoadImage
	jr	c,DEF11			; if failed, C flag is set
	print	Success

DEF11:
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


; Load image and save it to SRAM
;-----------------------------------------------------------------------------
LoadImage:

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

LIFM1:

; !!!! file attribute fix by Alexey !!!!
	ld	a,(FCB+#11)
	cp	#20
	jr	nz,Fpr02a
	ld	a,(FCB+#0D)
	cp	#21
	jr	nz,Fpr02a
	dec	a
	ld	(FCB+#0D),a
; !!!! file attribute fix by Alexey !!!!

;load file
Fpr02a:	ld	c,_RBREAD
	ld	de,FCB
	ld	hl,#2000
	call	DOS
	ld	a,h
	or	l
	jp	z,Ld_Fail

	ld	a,SRAMBLK
	ld	(EBlock),a		; shift to the block of RAM where SRAM is located
	ld	a,SRAMBNK
	ld	(PreBnk),a		; shift to the address in block where SRAM is located: 0FE000h-0FFFFFh

        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT
	ld	a,#34			; RAM instead of ROM, Bank write enabled, 8kb pages, control off
	ld	(R2Mult),a		; set value for Bank2
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT
	
	ld	hl,BUFTOP		; source
	ld	de,#8000		; destination
	ld	bc,#2000		; size
	call	RW_RAM			; save loaded data into SRAM
	jr	nc,LIF04

	print	DATA_ERR
	print	UL_erd_S
	scf				; set carry flag because of an error

LIF04:
	push	af

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

; file close
	ld	de,FCB
	ld	c,_FCLOSE
	call	DOS
	pop	af
	ret

Ld_Fail:
	print	FR_ERS
	scf				; set carry flag because of an error
	jr	LIF04



;-----------------------------------------------------------------------------
RW_RAM:
; Block (0..2000h) save into/from SRAM
; hl - source address
; de = destination address
; bc - length
; (EBlock)x64kB, (PreBnk)x8kB(16kB) - start address in RAM
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

        ld      a,(ERMSlt)
        ld      h,#40
        call    ENASLT
	ld	a,#A4			; RAM instead of ROM, Bank write disabled, 8kb pages, control on
	ld	(R2Mult),a		; set value for Bank2

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
;;;;;;;;;;;;;;;;;;;;;
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
	cp	"D"
	jr	nz,fkey02
	ld	a,1
	ld	(F_D),a
	ret
fkey02:	ld	hl,BUFFER+1
	ld	a,(hl)
	and	%11011111
	cp	"U"
	jr	nz,fkey03
	inc	hl
	ld	a,(hl)
	or	a
	jr	nz,fkey03
	ld	a,2
	ld	(F_U),a
	ret
fkey03:	ld	hl,BUFFER+1
	ld	a,(hl)
	and	%11011111
	cp	"H"
	jr	nz,fkey04
	inc	hl
	ld	a,(hl)
	or	a
	jr	nz,fkey04
	ld	a,3
	ld	(F_H),a			; show help
	ret
fkey04:	ld	hl,BUFFER+1
	ld	a,(hl)
	and	%11011111
	cp	"V"
	jr	nz,fkey05
	inc	hl
	ld	a,(hl)
	or	a
	jr	nz,fkey05
	ld	a,4
	ld	(F_V),a			; verbose mode flag
	ret
fkey05:
	ld	hl,BUFFER+1
	ld	a,(hl)
	and	%11011111
	cp	"R"
	jr	nz,fkey06
	inc	hl
	ld	a,(hl)
	or	a
	jr	nz,fkey06
	ld	a,5
	ld	(F_R),a			; reset after loading ROM
	ret
fkey06:
	xor	a
	dec	a			; S - Illegal flag
	ret


;------------------------------------------------------------------------------

;
;Variables
;
DOS2:	db	0
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
PreBnk:	db	0
EBlock0:
	db	0
EBlock:	db	0
strp:	db	0
strI:	dw	#8000

Bi_FNAM db	14,0,"D:FileName.SRM",0
;--- File Control Block
FCB:	db	0
	db	"           "
	ds	28
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
F_R	db	0
F_A	db	0
F_D	db	0
F_U	db	0
F_V	db	0
F_H	db	0
p1e	db	0

ZeroB:	db	0

Space:
	db	" $"
Bracket:
	db	" ",124," $"
SRMEXT:
	db	".SRM",0
SRMFN:	db	0
	db	"        SRM"
FCB2:	
	db	0
	db	"        SRM"
	ds	28
FCBSRM:	
	db	0
	db	"????????SRM"
	ds	28

BUFFER:	ds	256
	db	0,0,0

B1ON:	db	#F8,#50,#00,#85,#03,#40
B2ON:	db	#F0,#70,#01,#15,#7F,#80
B23ON:	db	#F0,#80,#00,#04,#7F,#80	; for shadow source bank
	db	#F0,#A0,#00,#34,#7F,#A0	; for shadow destination bank

RSTCFG:
	db	#F8,#50,#00,#85,#03,#40
	db	0,0,0,0,0,0
	db	0,0,0,0,0,0
	db	0,0,0,0,0,0
	db	#FF,#30

;------------------------------------------------------------------------------

;
; Text strings
;

DESCR:	db	"CMFCCFRC"
ABCD:	db	"0123456789ABCDEF"

MAIN_S:	db	13,10
	db	"Main Menu",13,10
	db	"---------",13,10
	db	" 1 - Download SRAM's contents to a file",13,10
	db	" 2 - Upload file's contents into SRAM",13,10
	db	" 3 - Restart the computer",13,10
	db	" 0 - Exit to MSX-DOS",13,10,"$"

EXIT_S:	db	10,13,"Thanks for using the RBSC's products!",13,10,"$"
FileSZH:
	db	"File size (hexadecimal): $"
Success:
	db	13,10,"The operation completed successfully!",13,10,"$"
ANIK_S:
	db	"Press any key to continue",13,10,"$"
WR_SRAM_S:
	db	13,10,"Input file name to upload into SRAM or just press Enter to select files: $"
SRM_FNM:
	db	13,10,"Input file name to download SRAM's contents to: $"
SelMode:
	db	10,13,"Selection mode: TAB - next file, ENTER - select, ESC - exit",10,13,"Found file(s):",9,"$"
NoMatch:
	db	10,13,"No SRM files found in the current directory!",10,13,"$"
OpFile_S:
	db	10,13,"Opening file: ","$"
CrFile_S:
	db	10,13,"Creating file: ","$"
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
DATA_ERR:
	db	13,10,"Data copying error!","$"
UL_erd_S:
	db	13,10,"Uploading file into SRAM failed!",13,10,"$"
DL_erd_S:
	db	13,10,"Downloading SRAM into file failed!",13,10,"$"
F_EXIST_S:
        db      13,10,"File already exists, overwrite? (y/n) $"
FileOver_S:
	db	10,13
	db	"Incorrect file's size for loading into the emulated SRAM!",13,10
	db	"The file for uploading into SRAM must be 8192 bytes long.",13,10
	db	"Please select another file...",13,10,"$"
SRM_Name:
        db      10,13,"Destination file name: $"
TWO_NL_S:
	db	13,10
ONE_NL_S:
	db	13,10,"$"
CLS_S:	db	27,"E$"
CLStr_S:
	db	27,"K$"
MD_Fail:
	db	"FAILED...",13,10,"$"

PRESENT_S:
	db	3
	db	"Carnivore2 MultiFunctional Cartridge SRAM Manager v1.07",13,10
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
	db	" c2sram [filename.srm] [/h] [/v] [/d] [/u]",13,10,13,10
	db	"Command line options:",13,10
	db	" /h  - this help screen",13,10
	db	" /v  - verbose mode (show detailed information)",13,10
	db	" /d  - download contents of SRAM into a file",10,13
	db	" /u  - upload file's contents into SRAM",13,10
	db	" /r  - restart computer after up/downloading",10,13,"$"

	db	0,0,0
	db	"RBSC:PTERO/WIERZBOWSKY/DJS3000/PYHESTY/GREYWOLF/SUPERMAX:2022"
	db	0,0,0

BUFTOP:
;
; End of code, further space is reserved for working with data and cartridge's registers
;

