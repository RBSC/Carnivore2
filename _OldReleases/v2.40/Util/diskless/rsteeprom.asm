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
	or	0x04
	ld	(IdeSlotId),a
	
setSlot:
	print	SWITCHING	
	ld	a,(FlashSlotId)
	ld	h,0x40
	call	ENASLT
	ld	a,(FlashSlotId)
	ld	h,0x80
	call	ENASLT
	
	print	PROCEED
	call	CHGET
	call	CHPUT
	cp	"y"
	jr	nz,askS

	ld	a,%01100000	; write enable
	call	EEWEN

	xor a
	ld	e,a             ; data
	ld	a,#18		; address
	call	EEWR		; save dual-reset to EEPROM

	print	DONE
	jp	askS ;Exit


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


;Write enable/disable EEPROM
;A = %01100000 Write Enable
;A = %00000000 Write Disable
;A = %01000000 Erase All! 
EEWEN:
	push	hl
	ld	hl,CardMDR+#23
	ld	c,a
; one CLK pulse
	ld	a,%00000100
	ld	(hl),a
	ld	a,%00000000	
	ld	(hl),a
; start bit
	ld	a,%00000010
	ld	(hl),a
	ld	a,%00001010
	ld	(hl),a
	ld	a,%00001110
	ld	(hl),a
; opcode "00"
	ld	a,%00001000
	ld	(hl),a
	ld	a,%00001100
	ld	(hl),a
	ld	a,%00001000
	ld	(hl),a
	ld	a,%00001100
	ld	(hl),a
; address A6-A0
	ld	b,7
	rrc	c
	rrc	c
	rrc	c
	rrc	c
	rrc	c
EEENa1:
	ld	a,c
	and	%00001010
	or	%00001000
	ld	(hl),a
	or	%00001100
	ld	(hl),a
	rlc	c
	djnz	EEENa1

	ld	a,%00001000
	ld	(hl),a
	ld	a,%00000000
	ld	(hl),a
	pop	hl
	ret

; Write 1 byte to EEPROM
; E - data
; A - address
EEWR:
	push	hl
	ld	hl,CardMDR+#23
	ld	c,a
; one CLK pulse
	ld	a,%00000100
	ld	(hl),a
	ld	a,%00000000	
	ld	(hl),a
; start bit
	ld	a,%00000010
	ld	(hl),a
	ld	a,%00001010
	ld	(hl),a
	ld	a,%00001110
	ld	(hl),a
; opcode "01"
	ld	a,%00001000
	ld	(hl),a
	ld	a,%00001100
	ld	(hl),a
	ld	a,%00001010
	ld	(hl),a
	ld	a,%00001110
	ld	(hl),a
; address A6-A0
	ld	b,7
	rrc	c
	rrc	c
	rrc	c
	rrc	c
	rrc	c
EEWRa1:
	ld	a,c
	and	%00001010
	or	%00001000
	ld	(hl),a
	or	%00001100
	ld	(hl),a
	rlc	c
	djnz	EEWRa1
; Write Data
	rlc	e
	ld	b,8
EEWRd1:
	rlc	e
	ld	a,e
	and	%00001010
	or	%00001000
	ld	(hl),a
	or	%00001100
	ld	(hl),a
	djnz	EEWRd1
	ld	a,%00001000
	ld	(hl),a
	ld	a,%00000000
	ld	(hl),a
; write cycle
EEWRwc:
        ld	a,%00001000
	ld	(hl),a
	ld	a,%00001100
	ld	(hl),a
	ld	a,(hl)
	and	%00000001
	jr	nz,EERWce
	djnz	EEWRwc
EERWce:
	ld	a,%00001000
	ld	(hl),a
	ld	a,%00000000
	ld	(hl),a
	pop	hl
        ret

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
	


;
;Variables
;

Slot:	db	0
FlashSlotId:	db	0
IdeSlotId:	db	0
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

ONE_NL_S:
	db	13,10,"$"
SLOTN:	db "Slot# $"
SUBSLOTN: db "Subslot# $"
PROCEED: db "Proceed resetting EEPROM in this slot? $"
SWITCHING: db "Switching slot",13,10,"$"
DONE: db "All done. Reset machine to proceed",13,10,"$"
Last:
BUFTOP:
