;
; Carnivore2 ROM Dump/IDE Test Utility v1.10
; Created by Vladimir & RBSC [2022]
;


CHGET = 0x9F
CHPUT = 0xa2
RDSLT = 0x0c
WRSLT = 0x14
CALLSLT = 0x1c
ENASLT = 0x24

SLTTBL = 0xFCC5

TPASLOT1:	equ	#F342
TPASLOT2:	equ	#F343
CALLSLT:equ	#001C		; Inter-slot call
SCR0WID	equ	#F3AE		; Screen0 width

PPI_SLOT = 0xa8

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
	
	org	0xc000 - 7

; BLOAD header, before the ORG so that the header isn’t counted

	db	0xFE     ; magic number
	dw	begin    ; begin address
	dw	Last - 1  ; end address
	dw	exec  ; program execution address (for ,R option)

; Program code entry point

begin:
exec:
	call	CLRSCR
	call	KEYOFF
	print	Title	
askS:
	print	SLOTN
	call	CHGET
	call	CHPUT
	print 	ONE_NL_S
	cp	"0"
	jp	m,askS
	cp	"4"
	jp	p,askS
	sub	"0"
	ld	(Slot),a
askSubslot:
	print SUBSLOTN
	call	CHGET
	call	CHPUT
	print 	ONE_NL_S
	cp	" "
	jr	nz, checkSubslot
	xor	a
	jr	setSlot
checkSubslot:
	cp	"0"
	jp	m,askSubslot
	cp	"4"
	jp	p,askSubslot
	sub	"0"
	ld	(Subslot),a
	cp	0
	or	a
	rla
	rla
	or	0x80
setSlot:
	ld	hl,Slot
	or	(hl)
	ld	(SlotID),a

	print	SSlotContent
	ld	a,(Slot)
	call	getSSlot
	call	HEXOUT
	print 	ONE_NL_S
	print	Switching
	ld	a,(SlotID)
	ld	h,0x40
	call	ENASLT
	ld	a,(SlotID)
	ld	h,0x80
	call	ENASLT
	print	SSlotContent
	ld	a,(Slot)
	call	getSSlot
	call	HEXOUT
	print 	ONE_NL_S
AskChoice:
	print	Choice
	call	CHGET
	print	ONE_NL_S
	cp	27
	jp	z,askS
	or	%00100000		; lowercase
	cp	"r"
	jr	z,CallDumpRom
	cp	"i"
	jr	nz,AskChoice
	call	dumpIDE
	jp	askS
CallDumpRom:
	call	dumpROM
	jp	askS

;
; Read ROM and dump it
;	
dumpROM:
	print	ROMOFFS
	ld	hl,BUFTOP
	call	inps
	print 	ONE_NL_S
	ret	c
	or	a
	jr	nz,dumpROM_ofs
	ld	hl,(dumpROM_addr)
	jr	dumpROM_do
dumpROM_ofs:
	call	EXTNUM
	ld	a,d
	or	a
	jr	z,dumpROM
;	ld	hl,0x4000
	ld	hl,0x0000
	add	hl,bc
dumpROM_do:
	call	dumpBlock
	ld	(dumpROM_addr),hl
	jr	dumpROM
dumpROM_addr:	dw	0x4000

;
; Read IDE sector and dump it
;
dumpIDE:
	print	BLOCKN
	ld	hl,BUFTOP
	call	inps
	print 	ONE_NL_S
	ret	c
	or	a
	jr	nz,dumpIDE_inp
	ld	de,(dumpROM_addr)
	inc	de
	jr	dumpIDE_do
dumpIDE_inp:
	call	EXTNUM
	ld	a,d
	or	a
	jr	z,dumpIDE
	ld	de,bc
dumpIDE_do:
	ld	(dumpROM_addr),de
	ld	bc,1
	ld	hl,BUFTOP
	call	READSECT
	or	a
	jr	z,sect0_OK
	print	SECT0_ERR
	call 	HEXOUT
	print	ONE_NL_S
	jr	dumpIDE
sect0_OK:
	ld	hl,BUFTOP
	call	dumpBlock
	jr	dumpIDE


; Get subslot register
; Input:
;	a - slot number
; Output:
;	a - subslot register
getSSlot:
	push	hl
	push	bc
	ld	hl,SLTTBL
	ld	c,a
	ld	b,0
	add	hl,bc
	ld	a,(hl)
	pop	bc
	pop	hl
	ret
	
	
	
;----------------------------------------------------------------------------
;          C = Number of sectors to read
;          HL = Destination memory address for the transfer
;          DE = 2 byte sector number
;Output:   A = Error code (the same codes of MSX-DOS are used):
;              0: Ok
;          B = Number of sectors actually read/written
READSECT:	
	xor	a
	ld	b,a
	ld	a,c
	or	a
	jr	nz,DEV_RW_NO0SEC
	xor	a
	ld	b,0
	ret	
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
	jr	c,DEV_RW_ERR
	ld	a,0x20
	push	bc	;Save sector count
	call	DO_IDE
	pop	bc
	jr	c,DEV_RW_ERR

	call	DEV_RW_FAULT
	ret	nz

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
	ret
;-----------------------------------------------------------------------------
;
; Enable or disable the IDE registers

;Note that bank 7 (the driver code bank) must be kept switched

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
;
; Wait the BSY flag to clear and RDY flag to be set
; if we wait for more than 30s, send a soft reset to IDE BUS
; if the soft reset didn't work after 30s return with error
;
; Input:  Nothing
; Output: Cy=1 if timeout after soft reset 
; Preserves: DE and BC

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
;
; Execute a command
;
; Input:  A = Command code
;         Other command registers appropriately set
; Output: Cy=1 if ERR bit in status register set

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
	
;-----------------------------------------------------------------------------

; Input string to buffer in HL
; return - a number of characters read
;  CY - cancelled
inps:
	push	hl
inps_l:
	call	CHGET
	cp	13
	jr	z,inps_done
	cp	27
	jr	z,inps_esc
	call	CHPUT
	cp	8
	jr	nz,inps_store
	dec	hl
	jr	inps
inps_store:
	ld	(hl),a
	inc	hl
	jr	inps_l
inps_done:
	xor	a
	ld	(hl),a
	ld	a,l
	pop	hl
	sub	l
	or	a
	ret
inps_esc:
	pop	hl
	scf
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

; dump one block at HL
dumpBlock:
	print	ONE_NL_S
	ld	bc,0
dumpBlock_row:
	push	hl
	push	bc
	ld	a,h
	call	HEXOUT
	ld	a,l
	call	HEXOUT
	print	COLON
dumpBlock_byte:	
	ld	a,(hl)
	call	HEXOUT
	ld	a," "
	call	CHPUT
	inc	hl
	inc	c
	ld	a,c
	and	7
	jr	nz,dumpBlock_byte
	ld	a," "
	call	CHPUT
	pop	bc
	pop	hl
dumpBlock_char:
	ld	a,(hl)
	cp	a," "
	jp	m,dumpBlock_nonp
	cp	a,126
	jp	m,dumpBlock_p
dumpBlock_nonp:
	ld	a,"."
dumpBlock_p:
	call	CHPUT
	inc	hl
	inc	c
	ld	a,c
	and	7
	jr	nz,dumpBlock_char
	
	print	ONE_NL_S
	ld	a,c
	and	0x7f
	jr	nz,dumpBlock_row
	ret

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


Slot:	db	0
Subslot:db	0
SlotID:	db	0
PpiSlt: db	0

TWO_NL_S:
	db	13,10
ONE_NL_S:
	db	13,10,"$"
ABCD:	db	"0123456789ABCDEF"
COLON:	db	": $"
Title:	
	db	13,10
	db	"Carnivore2 ROM/IDE Dumper v1.10",13,10
	db	"Created by Vladimir & RBSC [2022]",13,10,"$"
SLOTN:	
	db	13,10
	db	"Enter Carnivore2's slot number: $"

SUBSLOTN:
	db	"Enter subslot number (1=IDE): $"
Choice: db	"Dump ROM or IDE sector (r/i): $"
BLOCKN:
	db	13,10	
	db	"Sector number (decimal): $"
ROMOFFS:
	db	13,10
	db	"ROM's address (decimal): $"
SECT0_ERR:
	db	"Error reading sector 0: $"
SSlotContent:
	db	"Subslot's register: $"
Switching:
	db	"Switching slot...",13,10,"$"

BUFTOP:
Last:
Dummy:
