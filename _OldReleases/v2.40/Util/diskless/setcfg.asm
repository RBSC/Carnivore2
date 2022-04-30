Debug = 0

CHGET = 0x9F
CHPUT = 0xa2
RDSLT = 0x0c
;WRSLT = 0x14
;ENASLT = 0x24

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
MNROM:   equ    #FCC1		; Main-ROM Slot number & Secondary slot flags table

CardMDR: equ	#4F80
AddrM0: equ	#4F80+1
AddrM1: equ	#4F80+2
AddrM2: equ	#4F80+3
DatM0: equ	#4F80+4

AddrFR: equ	#4F80+5

R1Mask: equ	#4F80+6
R1Addr: equ	#4F80+7
R1Reg:  equ	#4F80+8
R1Mult: equ	#4F80+9
B1MaskR: equ	#4F80+10
B1AdrD:	equ	#4F80+11

R2Mask: equ	#4F80+12
R2Addr: equ	#4F80+13
R2Reg:  equ	#4F80+14
R2Mult: equ	#4F80+15
B2MaskR: equ	#4F80+16
B2AdrD:	equ	#4F80+17

R3Mask: equ	#4F80+18
R3Addr: equ	#4F80+19
R3Reg:  equ	#4F80+20
R3Mult: equ	#4F80+21
B3MaskR: equ	#4F80+22
B3AdrD:	equ	#4F80+23

R4Mask: equ	#4F80+24
R4Addr: equ	#4F80+25
R4Reg:  equ	#4F80+26
R4Mult: equ	#4F80+27
B4MaskR: equ	#4F80+28
B4AdrD:	equ	#4F80+29

CardMod: equ	#4F80+30

CardMDR2: equ   #4F80+31
ConfFl:	equ	#4F80+32
ADESCR:	equ	#4010

;--- Important constants

L_STR:	equ	16	 	; number of entries on the screen
MAPPN:	equ	5		; max number of currently supported mappers

;-----------------------------------------------------------------------------
;
; IDE registers and bit definitions

IDE_BANK	equ	0x4104	;bit 0: enable (1) or disable (0) IDE registers
				;bits 5-7: select 16K ROM bank
IDE_DATA	equ	0x7C00	;Data registers, this is a 512 byte area
IDE_ERROR	equ	0x7E01	;Error register
IDE_FEAT	equ	0x7E01	;Feature register
IDE_SECCNT	equ	0x7E02	;Sector count
IDE_SECNUM	equ	0x7E03	;Sector number (CHS mode)
IDE_LBALOW	equ	0x7E03	;Logical sector low (LBA mode)
IDE_CYLOW	equ	0x7E04	;Cylinder low (CHS mode)
IDE_LBAMID	equ	0x7E04	;Logical sector mid (LBA mode)
IDE_CYHIGH	equ	0x7E05	;Cylinder high (CHS mode)
IDE_LBAHIGH	equ	0x7E05	;Logical sector high (LBA mode)
IDE_HEAD	equ	0x7E06	;bits 0-3: Head (CHS mode), logical sector higher (LBA mode)
IDE_STATUS	equ	0x7E07	;Status register
IDE_CMD		equ	0x7E07	;Command register
IDE_DEVCTRL	equ	0x7E0E	;Device control register

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

.NCOMP	equ	0x0FF
.WRERR	equ	0x0FE
.DISK	equ	0x0FD
.NRDY	equ	0x0FC
.DATA	equ	0x0FA
.RNF	equ	0x0F9
.WPROT	equ	0x0F8
.UFORM	equ	0x0F7
.SEEK	equ	0x0F3
.IFORM	equ	0x0F0
.IDEVL	equ	0x0B5
.IPARM	equ	0x08B


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
	
	org	0xC000-7
; BLOAD header, before the ORG so that the header isn�t counted
	db 0xFE     ; magic number
	dw begin    ; begin address
	dw Last - 1  ; end address
	dw exec  ; program execution address (for ,R option)

; Program code entry point
begin:
exec:	
	call	CLRSCR
	call	KEYOFF

askS:
	print	SLOTN
	call	CHGET
	call	CHPUT
	print 	ONE_NL_S
	cp	"1"
	jp	m,askS
	cp	"4"
	jp	p,askS
	sub	"0"
	ld	(Slot),a
	
	or	0x80
	ld	(FlashSlotId),a
	
setSlot:
	print	SWITCHING	
	ld	a,(FlashSlotId)
	ld	h,0x40
	call	ENASLT
	ld	a,(FlashSlotId)
	ld	h,0x80
	call	ENASLT
	call	BCTSF

	ld	hl,DEF_CFG+59
	xor a
	ld	(hl),a	
	inc hl
	ld a,#28
	ld (hl),a
	inc hl
	inc hl
	ld a,#01
	ld (hl),a

	ld	bc,0			; counter for enabled devices
	push	bc
	print	ExtSlot
ADCQ1:
	call	CHGET
	call	CHPUT
	print 	ONE_NL_S
	cp	"n"
	jr	z,ADCQ2
	cp	"y"
	jr	nz,ADCQ1
	ld	hl,DEF_CFG+59
	ld	a,(hl)
	or	#80			; enable expanded slot bit
	ld	(hl),a	
	pop	bc
	inc	bc
	push	bc
ADCQ2:
	print	MapRAM
ADCQ3:
	call	CHGET
	call	CHPUT
	print 	ONE_NL_S
	cp	"n"
	jr	z,ADCQ4
	cp	"y"
	jr	nz,ADCQ3
	ld	hl,DEF_CFG+59
	ld	a,(hl)
	or	#54			; enable RAM bits: 1010100
	ld	(hl),a	
	pop	bc
	inc	bc
	push	bc
ADCQ4:
	print	FmOPLL
ADCQ5:
	call	CHGET
	call	CHPUT
	print 	ONE_NL_S
	cp	"n"
	jr	z,ADCQ6
	cp	"y"
	jr	nz,ADCQ5
	ld	hl,DEF_CFG+59
	ld	a,(hl)
	or	#28			; enable FMPAC bits: 101000
	ld	(hl),a
	pop	bc
	inc	bc
	push	bc
ADCQ6:
	print	IDEContr
ADCQ7:
	call	CHGET
	call	CHPUT
	print 	ONE_NL_S
	cp	"n"
	jr	z,ADCQ8
	cp	"y"
	jr	nz,ADCQ7
	ld	hl,DEF_CFG+59
	ld	a,(hl)
	or	2			; enable IDE bit: 10
	ld	(hl),a	
	pop	bc
	inc	bc
	push	bc
ADCQ8:
	print	MultiSCC
ADCQ9:
	call	CHGET
	call	CHPUT
	print 	ONE_NL_S
	cp	"n"
	jr	z,ADCQ10
	cp	"y"
	jr	nz,ADCQ9
	ld	hl,DEF_CFG+59
	ld	a,(hl)
	or	1			; enable MLTMAP/SCC bit: 1
	ld	(hl),a	
	ld	hl,DEF_CFG+60
	ld	a,(hl)
	or	#10			; enable SCC sound in main control register
	ld	(hl),a	
	pop	bc
	inc	bc
	push	bc

ADCQ10:
	pop	bc
	ld	a,c			; more than 1 device enabled?
	cp	2
	jr	c,ADCQ11
	ld	hl,DEF_CFG+59
	ld	a,(hl)
	or	#80			; enable expanded slot bit
	ld	(hl),a	

ADCQ11:
	ld	hl,DEF_CFG+59
	ld	a,(hl)
	cp	#FF			; all enabled?
	jr	nz,ADCQ12
	ld	hl,DEF_CFG+60
	ld	a,(hl)
	and	#FB			; enable restart for delayed reconfig
	ld	(hl),a
	ld	hl,DEF_CFG+62
	ld	a,1			; enable reset for full config
	ld	(hl),a

ADCQ12:	or	a			; nothing enabled?
	jr	nz,doit
	print	NothingE
	jp	Exit

doit:	
	print NEWMCONF
	ld	hl,DEF_CFG+59
	ld	a,(hl)
	call HEXOUT
	print NEWCARDMDR
	ld	hl,DEF_CFG+60
	ld	a,(hl)
	call HEXOUT
	print 	ONE_NL_S
	print	PROCEED
	call	CHGET
	call	CHPUT
	cp	"y"
	jr	nz,askS

	call	DIRINI

	print	DONE
	jp	Exit

FlshFailed:
	print	FL_er_S
	jp	Exit

BCTSF:
	print DET_FTYP
; test flash
;*********************************
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
	print	NOTD_S
	jp	Exit

PR_Fail:
	print	FL_erd_S
	scf				; set carry flag because of an error
	ret

Ld_Fail:
	print	ONE_NL_S
	print	FR_ER_S
	scf				; set carry flag because of an error
	ret

FBProg:
; Block (0..2000h) programm to flash
; hl - DEF_CFG sourse
; de = flash destination
; bc - size
; (Eblock),(Eblock0) - start address in flash
; output CF - flashing failed flag
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
	;jp	PrEr
PrEr:
;    	save flag CF - fail
	ei
	ret


FBerase:
; Flash block erase 
; Eblock, Eblock0 - block address
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

;**********************
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
    	print	CHECKAT
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

Exit:	jr	askS;Exit
;-----------------------------------------------------------------------------

; Print string (de) terminated by "$"
; alters de
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
	ld	a,#80			; Autostart table
	ld	(EBlock0),a
	call	FBerase
	jr	c,eraFailed
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



;------------------------------------------------------	
DEF_CFG:
	db	#00,#FF,00,00,"C"
	db	"Edited by SETCFG              "
	db	#F8,#50,#00,#8C,#3F,#40 ;35
	db	#F8,#70,#01,#8C,#3F,#60	;41	
	db  #F8,#90,#02,#8C,#3F,#80	;47	
	db	#F8,#B0,#03,#8C,#3F,#A0	;53
	db	#00,#28,#00,#01,#FF ; 59

;
;Variables
;

Slot:	db	0
FlashSlotId:	db	0
CurrentBlock:	ds 2
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

DET_FTYP:db "Detecting flash",13,10,"$"
MfC_S:	db	"Manufacturer's code: $"
DVC_S:	db	"Device's code: $"
EMB_S:	db	"Extended Memory Block: $"
EMBF_S:	db	"EMB Factory Locked",13,10,"$"
EMBC_S:	db	"EMB Customer Lockable",13,10,"$"
M29W640:db      "FlashROM chip detected: M29W640G$"
NOTD_S:	db	13,10,"FlashROM chip's type is not detected!",13,10
	db	"This cartridge may be defective!",13,10
	db	"Try to reboot and hold down F5 key...",13,10 
	db	"$"

DIRINC_S:
	db	"Erasing directory is complete!",13,10,"$"
DIRINC_F:
	db	"Failed to erase directory!",13,10,"$"
Flash_C_S:
	db	"Operation completed successfully!",13,10,"$"
BootWrit:
	db	"Writing Boot Block into FlashROM...",13,10,"$"
IdeWrit:
	db	"Writing IDE BIOS into FlashROM...",13,10,"$"
FmpacWrit:
	db	"Writing FMPAC BIOS into FlashROM...",13,10,"$"
Erasing:
	db	"Erasing FlashROM chip, please wait...",13,10,"$"
EraseOK:
	db	"The FlashROM chip successfully erased!",13,10,"$"
EraseFail:
	db	"Erasing the FlashROM chip failed!",13,10,"$"
FR_ER_S:
	db	"CF read error!",13,10,"$"
FLEB_S:	db	"Erasing FlashROM chip's block(s):",13,10,"$"
FLEBE_S:db	"Error erasing FlashROM's block(s)!",13,10,"$"
LFRI_S:	db	"Writing ROM image, please wait...",13,10,"$"
FL_er_S:
	db	"Writing into FlashROM failed!",13,10,"$"
FL_erd_S:
	db	"Writing directory entry failed!",13,10,"$"
ONE_NL_S:
	db	13,10,"$"
SLOTN:	db "Slot# $"
SUBSLOTN: db "Subslot# $"
PROCEED: db "Proceed programming BIOS in this slot? $"
SWITCHING: db "Switching slot",13,10,"$"
CHECKAT: db "Check@$"
DONE: db "All done. Reset machine to proceed",13,10,"$"
ExtSlot:
	db	10,13,"Enable extended slot? (y/n) $"
MapRAM:
	db	10,13,"Enable RAM and Mapper? (y/n) $"
FmOPLL:
	db	10,13,"Enable FMPAC? (y/n) $"
IDEContr:
	db	10,13,"Enable IDE controller? (y/n) $"
MultiSCC:
	db	10,13,"Enable SCC and MultiMapper? (y/n) $"

EntryOK:
	db	10,13,"Configuration entry added successfully!",10,13,"$"
EntryFAIL:
	db	10,13,"Failed to create configuration entry!",10,13,"$"
NothingE:
	db	10,13,"Ignored! Enable at least one device!",10,13,"$"
NEWMCONF:
	db " New Mconf: #$"
NEWCARDMDR
	db " New CardMDR: #$"

Last:
BUFTOP:
