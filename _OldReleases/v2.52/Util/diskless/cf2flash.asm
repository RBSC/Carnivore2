;
; Carnivore2 CF2Flash Utility v1.10
; Created by Vladimir & RBSC [2022]
;


Debug = 0

CHGET = #9F
CHPUT = #a2
RDSLT = #0c
;WRSLT = #14
;ENASLT = #24

ENASLT:	equ	#0024		; BIOS Enable Slot
WRTSLT:	equ	#0014		; BIOS Write to Slot
CALLSLT:equ	#001C		; Inter-slot call
SCR0WID	equ	#F3AE		; Screen0 width

TPASLOT1:	equ	#F342
TPASLOT2:	equ	#F343

CSRY	equ	#F3DC
CSRX	equ	#F3DD
ARG:	equ	#F847
EXTBIO:	equ	#FFCA
MNROM:	equ	#FCC1		; Main-ROM Slot number & Secondary slot flags table

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

CardMDR2:	equ   #4F80+31
ConfFl:	equ	#4F80+32
ADESCR:	equ	#4010

;--- Important constants

L_STR:	equ	16	 	; number of entries on the screen
MAPPN:	equ	5		; max number of currently supported mappers

;-----------------------------------------------------------------------------
;
; IDE registers and bit definitions

IDE_BANK	equ	#4104	;bit 0: enable (1) or disable (0) IDE registers
				;bits 5-7: select 16K ROM bank
IDE_DATA	equ	#7C00	;Data registers, this is a 512 byte area
IDE_ERROR	equ	#7E01	;Error register
IDE_FEAT	equ	#7E01	;Feature register
IDE_SECCNT	equ	#7E02	;Sector count
IDE_SECNUM	equ	#7E03	;Sector number (CHS mode)
IDE_LBALOW	equ	#7E03	;Logical sector low (LBA mode)
IDE_CYLOW	equ	#7E04	;Cylinder low (CHS mode)
IDE_LBAMID	equ	#7E04	;Logical sector mid (LBA mode)
IDE_CYHIGH	equ	#7E05	;Cylinder high (CHS mode)
IDE_LBAHIGH	equ	#7E05	;Logical sector high (LBA mode)
IDE_HEAD	equ	#7E06	;bits 0-3: Head (CHS mode), logical sector higher (LBA mode)
IDE_STATUS	equ	#7E07	;Status register
IDE_CMD		equ	#7E07	;Command register
IDE_DEVCTRL	equ	#7E0E	;Device control register

; Bits in the error register

UNC	equ	6	;Uncorrectable Data Error
WP	equ	6	;Write protected
MC	equ	5	;Media Changed
IDNF	equ	4	;ID Not Found
MCR	equ	3	;Media Change Requested
ABRT	equ	2	;Aborted Command
NM	equ	1	;No media

M_ABRT	equ	1<<ABRT

; Bits in the head register

DEV	equ	4	;Device select: 0=master, 1=slave
LBA	equ	6	;0=use CHS mode, 1=use LBA mode

M_DEV	equ	1<<DEV
M_LBA	equ	1<<LBA

; Bits in the status register

BSY	equ	7	;Busy
DRDY	equ	6	;Device ready
DF	equ	5	;Device fault
DRQ	equ	3	;Data request
ERR	equ	0	;Error

M_BSY	equ	1<<BSY
M_DRDY	equ	1<<DRDY
M_DF	equ	1<<DF
M_DRQ	equ	1<<DRQ
M_ERR	equ	1<<ERR

; Bits in the device control register register

SRST	equ	2	;Software reset

M_SRST	equ	1<<SRST
;-----------------------------------------------------------------------------
;
; Error codes for DEV_RW and DEV_FORMAT
;

.NCOMP	equ	#0FF
.WRERR	equ	#0FE
.DISK	equ	#0FD
.NRDY	equ	#0FC
.DATA	equ	#0FA
.RNF	equ	#0F9
.WPROT	equ	#0F8
.UFORM	equ	#0F7
.SEEK	equ	#0F3
.IFORM	equ	#0F0
.IDEVL	equ	#0B5
.IPARM	equ	#08B


;-----------------------------------------------------------------------------

print	macro	
	ld	de,\1
	call	prints
	endm

; Shift a left arg bits
; modifies b
shftL	macro
	ld	b,\1
	local shftLLp
shftLLp	or	a	; clear Cy
	rla
	djnz	shftLLp	
	endm
	
	org	#C000-7

; BLOAD header, before the ORG so that the header isn’t counted

	db	#FE 		; magic number
	dw	begin		; begin address
	dw	Last - 1	; end address
	dw	Exec		; program execution address (for ,R option)

; Program code entry point
begin:
Exec:	
	call	CLRSCR
	call	KEYOFF

SltInp:
	print	SLOTN
	call	CHGET
	call	CHPUT
	print 	ONE_NL_S
	cp	"1"
	jp	m,SltInp
	cp	"4"
	jp	p,SltInp
	sub	"0"
	ld	(Slot),a
	
	or	#80
	ld	(FlashSlotId),a
	or	#04
	ld	(IdeSlotId),a
	
setSlot:
;	print	SWITCHING	
	ld	a,(FlashSlotId)
	ld	h,#40
	call	ENASLT
	ld	a,(FlashSlotId)
	ld	h,#80
	call	ENASLT
	
	print	PROCEED			; confirmation
	call	CHGET
	call	CHPUT
	or	%00100000		; lowercase
	cp	"y"
	jp	nz,0000
		
	call	BCTSF			; test flash

	call	ChipErase		; erase flashrom

	call	DIRINI			; init directory

	print	BootWrit

; Erase 8 blocks of 1st 64kb block
	xor	a
	ld	(EBlock),a
	ld	(EBlock0),a
	call	FBerase	
	ld	a,#20
	ld	(EBlock0),a
	call	FBerase	
	ld	a,#80
	ld	(EBlock0),a
	call	FBerase	
	ld	a,#A0
	ld	(EBlock0),a
	call	FBerase	
	ld	a,#C0
	ld	(EBlock0),a
	call	FBerase	
	ld	a,#E0
	ld	(EBlock0),a
	call	FBerase	
	xor	a
	ld	(EBlock),a
	ld	(EBlock0),a

;Program 64kb Boot block + directory

	call	SET2PD
	ld	a,#15
	ld	(R2Mult),a		; 16kb pages
	xor	a
	ld	(PreBnk),a		; 0-page #0000 (Boot)
	
	ld	hl,#2000
	ld	(Size),hl
	xor	a
	ld	(Size+2),a

	ld	hl,0			; CF card's sector (mult. 512)
	ld	de,#8000
	call	FBProgCF		; 8kb block 1
	jp	c,FlashFailed
	ld	hl,#10
	ld	de,#A000
	call	FBProgCF		; 8kb block 2
	jp	c,FlashFailed

;	ld	a,2			; 2nd boot menu block
;	ld	(PreBnk),a
;	ld	hl,#40
;	ld	de,#8000
;	call	FBProgCF		; 8kb block 5
;	jp	c,FlashFailed
;	ld	hl,#50
;	ld	de,#A000
;	call	FBProgCF		; 8kb block 6
;	jp	c,FlashFailed

	ld	a,3			; 3rd boot menu block
	ld	(PreBnk),a
	ld	hl,#60
	ld	de,#8000
	call	FBProgCF		; 8kb block 7
	jp	c,FlashFailed
	ld	hl,#70
	ld	de,#A000
	call	FBProgCF		; 8kb block 8
	jp	c,FlashFailed
	print	Flash_C_S		; Successful flashing

	call	SET2PD
	print	IdeWrit			; Writing IDE BIOS
	ld	a,#01
	ld	(Record+2),a		; set start block #10000
	ld	a,#02
	ld	(Record+3),a		; set length 2 bl #10000-#2FFFF
	ld	(Size+2),a
	ld	hl,0
	ld	(Size),hl
	ld	hl,#80	
	call	LoadImage
	jr	c,FlashFailed
	print	ONE_NL_S
	print	Flash_C_S		; success!

	print	FmpacWrit		; Writing FMPAC BIOS
	ld	a,#03
	ld	(Record+2),a		; set start block #30000
	ld	a,#01
	ld	(Record+3),a		; set length 1 bl #30000-#3FFFF
	ld	(Size+2),a
	ld	hl,#180
	call	LoadImage
	jr	c,FlashFailed
	print	ONE_NL_S
	print	Flash_C_S		; success!

	print	DONE			; All done
	xor	a
	jp	Exit

FlashFailed:
	print	FL_er_S			; Error message
	print	FAILED			; Failed
	ld	a,1
	jp	Exit


; Test flash
;*********************************
;
BCTSF:
	print DET_FTYP
;TestROM:
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
	
Trp02:
	print	MfC_S
	ld	a,(Det00)
	call	HEXOUT
	print	ONE_NL_S

	print	DVC_S
	ld	a,(Det02)
	call	HEXOUT
	ld	a," "
	call	CHPUT	
	ld	a,(Det1C)
	call	HEXOUT
	ld	a," "
	call	CHPUT	
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
	jr	z,Trp02b
	cp	#20
	jr	nz,Trp03	
Trp02b:
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
Trp04:
	ld	a,e
	call	CHPUT
	print	ONE_NL_S

	ld	a,(Det06)
	cp	80
	jp	c,Trp11	
	print	EMBF_S
	xor	a
	ret
Trp11:
	print	EMBC_S
	xor	a
	ret	
Trp03:
	print	NOTD_S			; no detection
	ld	a,1
	jp	Exit


;-----------------------------------------------------------------------------
; Erase block's and load ROM-image from CF
; Input: hl - first block of image in CF
;
LoadImage:
	ld	(CurrentBlock),hl
;;; 1st operation - erase flash block(s)
;;	print	FLEB_S
;;	xor	a
;;	ld	(EBlock0),a
;;	ld	a,(Record+02)		; start bloc
;;	ld	(EBlock),a
;;	ld	a,(Record+03)		; len b
;;	or	a
;;	jp	z,LIF04
;;	ld	b,a
;;LIF03:	push	bc
;;	call	FBerase
;;	jr	nc,LIF02
;;	pop	bc			
;;	print 	FLEBE_S
;;	jp	LIF04
;;LIF02:
;;	ld	a,(EBlock)
;;	call	HEXOUT
;;	ld	a," "
;;	call	CHPUT
;;	pop	bc
;;	ld	hl,EBlock
;;	inc	(hl)
;;	djnz	LIF03
;;	print	ONE_NL_S

; 2nd operation - loading ROM-image to flash
LIFM1:
	ld	a,#14			; #14 #84
	ld	(R2Mult),a		; set 8kB Bank
	ld	a,(Record+02)		; start block (absolute block 64kB)
	ld	(EBlock),a
	ld	(AddrFR),a

LIFM2:	xor	a
	ld	(PreBnk),a

	print	LFRI_S

; calc loading cycles
; Size 3 = 0 ( or oversize )
; Size 2 (x 64 kB ) - cycles for (Eblock) 
; Size 1,0 / #2000 - cycles for FBProg portions

; Size / #2000 
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
;program portion
;      	ld      a,(ERMSlt)
;	ld	e,#94			; sent bank2 to 8kb
;	call	WRTSLT

	call	FBProg2
	jr	c,PR_Fail
	ld	a,">"			; flashing indicator
	call	CHPUT
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

LIF04:
; finish loading ROMimage
	ret

PR_Fail:
	print	FL_erd_S
	scf				; set carry flag because of an error
	jr	LIF04

Ld_Fail:
	print	ONE_NL_S
	print	FR_ER_S
	scf				; set carry flag because of an error
	jr	LIF04


; Block (0..2000h) programm to flash
; hl - buffer sourse
; de = flash destination
; bc - size
; (Eblock),(Eblock0) - start address in flash
; output CF - flashing failed flag
;
FBProg:
	exx
	ld	a,(PreBnk)
	ld	(R2Reg),a
	ld	a,(EBlock)
	ld	(AddrFR),a
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
	jp	PrEr


; Block (0..#2000) programm to flash
; de = flash destination
; (Eblock),(Eblock0) - start address in flash
; output CF - flashing failed flag
;
FBProgCF:
	ld	(CurrentBlock),hl
	push	de
	ld	a,(PreBnk)
	ld	(R2Reg),a
	ld	a,(EBlock)
	ld	(AddrFR),a
        ld	b,#20
        pop	de
	di
Loop1Block:
	exx
	ld	c,1
	ld	de,(CurrentBlock)
	ld	hl,BUFTOP
	call	ReadBlocks
	exx
	jp	nz,Ld_Fail
	ld	hl,(CurrentBlock)
	inc	hl
	ld	(CurrentBlock),hl
	ld	hl,BUFTOP
	ld	c,0
Loop1CF:
	ld	a,#AA
	ld	(#8AAA),a		; (AAA)<-AA
	ld	a,#55		
	ld	(#8555),a		; (555)<-55
	ld	a,#A0
	ld	(#8AAA),a		; (AAA)<-A0

	ld	a,(hl)
	ld	(de),a			; byte programm

	call	CHECK			; check
	jp	c,PrEr
	inc	hl
	inc	de
	dec	c
	jr	nz,Loop1CF
	dec	b
	ld	a,b
	and	1
	jr	nz,Loop1CF
	or	b
	jr	nz,Loop1Block
	jr	PrEr


; Block (0..#2000) programm to flash
; (Eblock)x64kB, (PreBnk)x8kB(16kB) - start address in flash
; CurrentBlock - start block of image in CF
; output CF - flag Programm fail
;
FBProg2:
	ld	a,(PreBnk)
	ld	(R2Reg),a
	ld	a,(EBlock)
	ld	(AddrFR),a

        ld	b,#20
	ld	de,#8000
	di

Loop2Block:
	exx
	ld	c,1
	ld	de,(CurrentBlock)
	ld	hl,BUFTOP
	call	ReadBlocks
	exx
	jp	nz,Ld_Fail
	ld	hl,(CurrentBlock)
	inc	hl
	ld	(CurrentBlock),hl
	ld	hl,BUFTOP
	ld	c,0
Loop2:
	ld	a,#50
	ld	(#8AAA),a		; double byte programm

	ld	a,(hl)
	ld	(de),a			; 1st byte programm
	inc	hl
	inc	de
	ld	a,(hl)			; 2nd byte programm
	ld	(de),a
	call	CHECK			; check
	jp	c,PrEr
	inc	hl
	inc	de
	dec	c
	jr	nz,Loop2
	ld	a,b
	sub	a,2
	ld	b,a
	jr	nz,Loop2Block
PrEr:
;    	save flag CF - fail
	ei
	ret


; Flash block erase 
; Eblock, Eblock0 - block address
;
FBerase:
	di
	ld	a,(ShadowMDR)
	and	#FE
	ld	(CardMDR),a
	xor	a
	ld	(AddrM0),a
	ld	a,(EBlock0)
	ld	(AddrM1),a
	ld	a,(EBlock)		; block address
	ld	(AddrM2),a
	ld	a,#AA
	ld	(#4AAA),a
	ld	a,#55
	ld	(#4555),a
	ld	a,#80
	ld	(#4AAA),a		; Erase Mode
	ld	a,#AA
	ld	(#4AAA),a
	ld	a,#55
	ld	(#4555),a
	ld	a,#30			; command Erase Block
	ld	(DatM0),a

	ld	a,#FF
    	ld	de,DatM0
    	call	CHECK
; save flag CF - erase fail
	push	af
	ld	a,(ShadowMDR)
	ld	(CardMDR),a
	ei
	pop	af
	ret


CHECK:
    	push	bc
    	ld	c,a
    	ld	a,Debug
    	or	a
    	jr	nz,CHK_R1
CHK_L1: ld	a,(de)
    	xor	c
    	jp	p,CHK_R1		; Jump if readed bit 7 = written bit 7
    	xor	c
    	and	#20
    	jr	z,CHK_L1		; Jump if readed bit 5 = 1
    	ld	a,(de)
    	xor	c
    	jp	p,CHK_R1		; Jump if readed bit 7 = written bit 7

    	push	de
    	print	CHECKAT			; print failure address
    	pop	de
    	ld	a,d
    	call	HEXOUT
    	ld	a,e
    	call	HEXOUT
    	ld	a," "
    	call	CHPUT
    	ld	a,(de)
    	call	HEXOUT
    	ld	a," "
    	call	CHPUT
	print	ONE_NL_S		; skip line
    	
    	scf
CHK_R1:	pop bc
	ret	

SET2PD:
	ld	hl,B2ON
	ld	de,CardMDR+#0C		; set Bank2
	ld	bc,6
	ldir
	ld	a,1
	ld	(CardMDR+#0E),a 	; set 2nd bank to directory map
	ret
	
B1ON:	db	#F8,#50,#00,#85,#03,#40
B2ON:	db	#F0,#70,#01,#15,#7F,#80
B23ON:	db	#F0,#80,#00,#04,#7F,#80	; for shadow source bank
	db	#F0,#A0,#00,#34,#7F,#A0	; for shadow destination bank

Exit:
	push	af
	ld      a,(TPASLOT2)
        ld      h,#80
        call    ENASLT
        ld      a,(TPASLOT1)
        ld      h,#40
        call    ENASLT

	call	CHGET			; Press any key
	pop	af
	or	a
	jp	z,0000			; reboot
	jp	Exec			; restart


;-----------------------------------------------------------------------------

; Print string (de) terminated by "$"
; Alters de
prints:	
	push	af
prints1:
	ld a,(de)
	cp	"$"
	jr	nz, prints2
	pop	af
	ret
prints2:call CHPUT
	inc de
	jr prints1

;---- Out to conlose HEX byte
; A - byte
; alters bc

HEXOUT:
	push	hl
	push	bc
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
	ld	a,(hl)
	call CHPUT
	pop	af
	push	af
	and	#0F
	ld	b,0
	ld	c,a
	ld	hl,ABCD
	add	hl,bc
	ld	a,(hl)
	call	CHPUT
	pop	af
	pop	bc
	pop	hl
	ret
	
;*********************************************
;input a - Slot Number
;*********************************************	
ChipErase:
	print	Erasing
	di
	ld	a,(ShadowMDR)
	and	#FE
	ld	(CardMDR),a
	ld	a,#95			; enable write to bank (current #85)
	ld	(R1Mult),a  

	ld	a,#AA
	ld	(#4AAA),a
	ld	a,#55
	ld	(#4555),a
	ld	a,#80
	ld	(#4AAA),a		; Erase Mode
	ld	a,#AA
	ld	(#4AAA),a
	ld	a,#55
	ld	(#4555),a
	ld	a,#10			; Command Erase Block
	ld	(#4AAA),a

	ld	a,#FF
    	ld	de,#4000
    	call	CHECK
	push	af
	ld	a,(ShadowMDR)
	ld	(CardMDR),a
	ei
	pop	af

	jp	nc,ChipErOK
	print	EraseFail
	jp	Exit
ChipErOK:
	print	EraseOK
	ret

	
; Erase directory + add 00 Record (empty SCC)
DIRINI:
; erase directory area
	xor	a
	ld	(EBlock),a
	ld	a,#40			; 1st 1/2 Directory
	ld	(EBlock0),a
	call	FBerase	
	jr	c,eraFailed
	ld	a,#60			; 2nd 1/2 Directory
	ld	(EBlock0),a
	call	FBerase		
	jr	c,eraFailed
;	ld	a,#80			; Autostart table
;	ld	(EBlock0),a
;	call	FBerase
;	jr	c,eraFailed
	call	SET2PD

; load 00 - record "empty SCC"
	ld	a,#15
	ld	(R2Mult),a
	xor	a
	ld	(EBlock),a		; Block = 0 system (x 64kB)
	inc	a
	ld	(PreBnk),a		; Bank=1 (x 16kB)
;	ld	hl,MAP_E_SCC
	ld	hl,DEF_CFG
	ld	de,#8000
	ld	bc,#40
	call	FBProg
	jr	c,UT04
	print	DIRINC_S
	ret
UT04:
	print	DIRINC_F
	jp	Exit
eraFailed:
	print	FLEBE_S
	jp	Exit

; Clear screen and set mode 40
CLRSCR:
	ld	a,40			; 40 symbols for screen0
	ld	(SCR0WID),a		; set default width of screen0
	xor	a
	ld	ix, #005F
	ld	iy,0
	call	CALLSLT			; set screen 0
	ret

; Hide functional keys
KEYOFF:	ld	ix, #00CC
	ld	iy,0
	call	CALLSLT			; set screen 0
	ret

;----------------------------------------------------------------------------
;          C = Number of sectors to read
;          HL = Destination memory address for the transfer
;          DE = 2 byte sector number
;Output:   A = Error code (the same codes of MSX-DOS are used):
;              0: Ok
;          B = Number of sectors actually read/written
;
ReadBlocks:
	push	bc
	push	de
	push	hl
	ld	a,(IdeSlotId)
	ld	h,#40
	call	ENASLT
	pop	hl
	pop	de
	pop	bc
	xor	a
	ld	b,a
	ld	a,c
	or	a
	jr	nz,DEV_RW_NO0SEC
	xor	a
	ld	b,0
	jr	ReadBlocksDone
DEV_RW_NO0SEC:
	call	IDE_ON
	xor	a
	or	M_LBA
	ld	(IDE_HEAD),a	;IDE_HEAD must be written first,
	ld	a,e		;or the other IDE_LBAxxx and IDE_SECCNT
	ld	(IDE_LBALOW),a	;registers will not get a correct value
	ld	a,d		;(blueMSX issue?)
	ld	(IDE_LBAMID),a
	xor	a
	ld	(IDE_LBAHIGH),a
	ld	a,c
	ld	(IDE_SECCNT),a
	call	WAIT_CMD_RDY
	jr	c,ReadBlocksRwErr
	ld	a,#20
	push	bc	;Save sector count
	call	DO_IDE
	pop	bc
	jr	c,ReadBlocksRwErr

	call	DEV_RW_FAULT
	jr	nz,ReadBlocksDone

	ld	b,c	;Retrieve sector count
	ex	de,hl
DEV_R_GDATA:
	push	bc
	ld	hl,IDE_DATA
	ld	bc,512
	ldir
	pop	bc
	djnz	DEV_R_GDATA

	call	IDE_OFF
	xor	a
ReadBlocksDone:
	push	af
	push	bc
	ld	a,(FlashSlotId)
	ld	h,#40
	call	ENASLT
	pop	bc
	pop	af
	ret
ReadBlocksRwErr:
	call	DEV_RW_ERR
	jr	ReadBlocksDone


;-----------------------------------------------------------------------------
; Enable or disable the IDE registers
; Note that bank 7 (the driver code bank) must be kept switched
;
IDE_ON:
	ld	a,1+7*32
	ld	(IDE_BANK),a
	ret

IDE_OFF:
	ld	a,7*32
	ld	(IDE_BANK),a
	ret
	
DEV_RW_ERR:
	ld	a,(IDE_ERROR)
	ld	b,a
	call	IDE_OFF
	ld	a,b	

	bit	NM,a	;Not ready
	jr	nz,DEV_R_ERR1
	ld	a,.NRDY
	ld	b,0
	ret
DEV_R_ERR1:

	bit	IDNF,a	;Sector not found
	jr	nz,DEV_R_ERR2
	ld	a,.RNF
	ld	b,0
	ret
DEV_R_ERR2:

	bit	WP,a	;Write protected
	jr	nz,DEV_R_ERR3
	ld	a,.WPROT
	ld	b,0
	ret
DEV_R_ERR3:

	ld	a,.DISK	;Other error
	ld	b,0
	ret

	;--- Check for device fault
	;    Output: NZ and A=.DISK on fault

DEV_RW_FAULT:
	ld	a,(IDE_STATUS)
	and	M_DF	;Device fault
	ret	z

	call	IDE_OFF
	ld	a,.DISK
	ld	b,0
	or	a
	ret


;-----------------------------------------------------------------------------
; Wait the BSY flag to clear and RDY flag to be set
; if we wait for more than 30s, send a soft reset to IDE BUS
; if the soft reset didn't work after 30s return with error
;
; Input:  Nothing
; Output: Cy=1 if timeout after soft reset 
; Preserves: DE and BC
;
WAIT_CMD_RDY:
	push	de
	push	bc
	ld	de,8142		;Limit the wait to 30s
WAIT_RDY1:
	ld	b,255
WAIT_RDY2:
	ld	a,(IDE_STATUS)
	and	M_BSY+M_DRDY
	cp	M_DRDY
	jr	z,WAIT_RDY_END	;Wait for BSY to clear and DRDY to set		
	djnz	WAIT_RDY2	;End of WAIT_RDY2 loop
	dec	de
	ld	a,d
	or	e
	jr	nz,WAIT_RDY1	;End of WAIT_RDY1 loop
	scf
WAIT_RDY_END:
	pop	bc
	pop	de
	ret	


;-----------------------------------------------------------------------------
; Execute a command
; Input:  A = Command code
;         Other command registers appropriately set
; Output: Cy=1 if ERR bit in status register set
;
DO_IDE:
	ld	(IDE_CMD),a

WAIT_IDE:
	nop	; Wait 50us
	ld	a,(IDE_STATUS)
	bit	DRQ,a
	jr	nz,IDE_END
	bit	BSY,a
	jr	nz,WAIT_IDE

IDE_END:
	rrca
	ret


;------------------------------------------------------	
; Default CFG block
;
DEF_CFG:
	db	#00,#FF,00,00,"C"
	db	"DefConfig: RAM+IDE+FMPAC+SCC  "
	db	#F8,#50,#00,#85,#3F,#40
	db	#F8,#70,#01,#8C,#3F,#60		
	db      #F8,#90,#02,#8C,#3F,#80		
	db	#F8,#B0,#03,#8C,#3F,#A0	
	db	#FF,#38,#00,#01,#FF


;
;Variables
;

Slot:	db	0
FlashSlotId:	db	0
IdeSlotId:	db	0
CurrentBlock:
	ds	2
protect:
	db	1
ShadowMDR
	db	#21
Det00:	db	0
Det02:	db	0
Det1C:	db	0
Det1E:	db	0
Det06:	db	0

C8k:	dw	0
PreBnk:	db	0
EBlock0:
	db	0
EBlock:	db	0

Size:	db 0,0,0,0
Record:	ds	#40


;------------------------------------------------------------------------------
;
; Text strings
;

ABCD:	db	"0123456789ABCDEF"

DET_FTYP:
	db	13,10,13,10
	db	"Detecting flash chip:",13,10,"$"
MfC_S:	db	"Manufacturer's code: $"
DVC_S:	db	"Device's code: $"
EMB_S:	db	"Extended Memory Block: $"
EMBF_S:	db	"EMB Factory Locked",13,10,"$"
EMBC_S:	db	"EMB Customer Lockable",13,10,"$"
M29W640:db      "FlashROM chip detected: M29W640G$"
NOTD_S:	db	13,10,"FlashROM chip's type is not detected!",13,10
	db	"This cartridge may be defective!",13,10
	db	"Try to reboot and hold down F5 key...",13,10,13,10
	db	"Press any key to restart the utility.",13,10,"$"

DIRINC_S:
	db	13,10
	db	"Erasing directory is complete!",13,10,"$"
DIRINC_F:
	db	"Failed to erase directory!",13,10,"$"
Flash_C_S:
	db	"Operation completed successfully!",13,10,"$"
BootWrit:
	db	13,10
	db	"Writing Boot Block into FlashROM...",13,10,"$"
IdeWrit:
	db	13,10
	db	"Writing IDE BIOS into FlashROM...",13,10,"$"
FmpacWrit:
	db	13,10
	db	"Writing FMPAC BIOS into FlashROM...",13,10,"$"
Erasing:
	db	13,10
	db	"Erasing FlashROM chip, please wait...",13,10,"$"
EraseOK:
	db	"The FlashROM chip successfully erased!",13,10,"$"
EraseFail:
	db	"Erasing the FlashROM chip failed!",13,10,"$"
FR_ER_S:
	db	"CF card reading failed!",13,10,"$"
FLEB_S:	db	"Erasing FlashROM chip's block(s):",13,10,"$"
FLEBE_S:db	"Error erasing FlashROM's block(s)!",13,10,"$"
LFRI_S:	db	"Writing ROM image, please wait...",13,10,"$"
FL_er_S:
	db	"Writing into FlashROM failed!",13,10,"$"
FL_erd_S:
	db	"Writing directory entry failed!",13,10,"$"
ONE_NL_S:
	db	13,10,"$"
SLOTN:	
	db	13,10
	db	"Carnivore2 CF2Flash Utility v1.10",13,10
	db	"Created by Vladimir & RBSC [2022]",13,10,13,10
	db	"Enter Carnivore2's slot number: $"
SUBSLOTN:
	db	"Enter subslot number: $"
PROCEED:
	db	"Start flashing Carnivore2 (y/n)? $"
;SWITCHING:
;	db	"Switching slot...",13,10,"$"
CHECKAT:
	db	"Failure at: 0x$"
DONE:
	db	13,10
	db	"All done! Computer needs to be rebooted.",13,10
	db	"Press any key to restart the computer.",13,10,"$"
FAILED:
	db	13,10
	db	"Flashing data into Carnivore2 failed!.",13,10
	db	"Press any key to restart the utility.",13,10,"$"

Last:
BUFTOP:
