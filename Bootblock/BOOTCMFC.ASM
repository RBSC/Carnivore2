;
; Carnivore/Carnivore2 Cartridge's Boot Block
; Copyright (c) 2015-2017 RBSC
; Version 1.15
;

; !COMPILATION OPTIONS!
CV	equ	2		; 1 = Canivore
				; 2 = Canivore2
EFF	equ	1		; 1 = effects (fade, palette) enabled
				; 0 = effects disabled

; !COMPILATION OPTIONS!

; Bios Calls
ENASLT	equ	#0024
CHPUT	equ	#00A2
CLEARS	equ	#00C3
POSIT	equ	#00C6
CHGET	equ	#009F
SSCREEN	equ	#005F
MODE40	equ	#0078
MODE40A	equ	#006C
CHCOLOR	equ	#0062
ENAKEYS	equ	#00CF
DISKEYS	equ	#00CC
KILBUF	equ	#0156

FORCLR 	equ	#F3E9
BAKCLR 	equ	#F3EA
BDRCLR 	equ	#F3EB
CHSETA	equ	#F920
CHSETS	equ	#F91F
SCR0WID	equ	#F3AE
BSLT	equ	#F560
BFNT	equ	#F562
DIRCNT	equ	#F564
DIRPAG	equ	#F566
CURPAG	equ	#F568

; Card configuration registers
CardMDR equ	#4F80

; Delay for fading
FDelay	equ	#1000

R_Base	equ	#C010
L_STR	equ	16

	org	#4000
	db	"AB"	; ROM Identeficator
	dw	Boot	; Start INIT
	dw	0	; STATEMENT
	dw	0	; DEVICE
	dw	0	; TEXT
	db	0,0,0,0,0,0
  if CV=2
	db	"CMFCCFRC"
  else
	db	"CSCCFRC"
  endif

;	Frames ASCII codes
;	
;	Thick
;	#80,#85,#85,#81
;	#86,#20,#20,#87
;	#82,#84,#84,#83
;	
;	Thin
;	#01,#50,#01,#51,#01,#51,#01,#52
;	#01,#57,#20,#20,#01,#53
;	#01,#56,#01,#55,#01,#55,#01,#54
;	
;	Medium
;	#88,#8A,#8A,#8F
;	#8C,#20,#20,#8D
;	#8E,#8B,#8B,#89
;	
;	Double
;	#01,#58,#01,#59,#01,#59,#01,#5A
;	#01,#5B,#20,#20,#01,#5F
;	#01,#5E,#01,#5D,#01,#5D,#01,#5C
;	

Boot:
	ld	a,(#FBEC)
	and	%00000010	; F5 - don't start cartridge
	ret	z

; set slot
	call	SltDet
	ld	h,#80
	call	ENASLT		; Set slot 8000-BFFF the same on 4000-3FFF

; set cart, register
	ld	hl,B2ON
	ld	de,CardMDR+#0C	; set Bank2
	ld	bc,6
	ldir

; check for autostart
	ld	d,#FF
	ld	a,2
	ld	(CardMDR+#0E),a ; set 2nd bank to autostart map
	ld	hl,#8000
TA_00:	ld	a,(hl)
	or	a
	jr	z,TA_01
	inc	hl
	ld	a,(hl)
	ld	d,a
	cp	#FF
	jp	z,Menu		; deselected autostart

; autostart entry found!
	ld	a,1
	ld	(CardMDR+#0E),a ; set 2nd bank to directory map		
	call 	c_dir
	jr	z,Menu		; empty record, go to menu
	ld	a,(#FBEC)
	and	%00001101	; ESC, F4 no autostart
	cp	%00001101
	jr	nz,Menu
	ld	bc,#FFFF	; autostart flag, disable effects
	jp	RUN_CT		; not empty record, go to start
TA_01:	inc	hl		; next auto
	inc	hl
	ld	a,h
	cp	#A0		; 8kb limit?
	jp	c,TA_00		; next entry


; Main Menu
; Search records (64b) max - 256
Menu:
; !!! check for incompatible systems and skip font loading
        call	Setfnt		; set font

	ld	c,d
	exx
	ld	a,1
	ld	(CardMDR+#0E),a ; set 2nd bank to directory map
	exx
	ld	d,0
	exx

; Count all directory enrties and pages
DirCnt:
	ld	hl,0
	ld	(DIRCNT),hl	; zero dir entry count
	ld	d,0		; first entry
	ld	a,1
	ld	(DIRPAG),a	; one page by default
	ld	(CURPAG),a	; 1st page to output first
DirC0:
	call 	c_dir		; calc dir entry point
	jr	nz,DirC1	; normal entry?
	inc	d
	ld	a,d
	or	a		; 255+1 limit
	jr	z,DirC2
	jr	DirC0

DirC1:	inc	d
	ld	a,d
	or	a		; 255+1 limit
	jr	z,DirC2
	ld	hl,DIRCNT
	inc	(hl)		; add one entry
	jr	DirC0

DirC2:  ld	hl,DIRCNT
	ld	a,(hl)
	ld	hl,DIRPAG
DirC3:
	cp	L_STR		; number of strings on page
	jr	z,Menu1		; last page?
	jr	c,Menu1		; last page?
	inc	(hl)		; add one dir page
	sub	L_STR		; more dir pages?
	jr	DirC3

; Set screen for menu
Menu1:
	ld	a,15
	ld	hl,#1701
	call	PALETTE
	ld	a,4
	ld	hl,#1701
	call	PALETTE
	ld	a,15
	ld	(FORCLR),a
	ld	a,4
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors (foreground=background)
	push	de
	ld	de,#1101
	ld	hl,#1701
	ld	bc,#040D
	call	FadeOut		; fade out background
  if CV=2
	ld	de,#4301
  else
	ld	de,#1304
  endif
	ld	hl,#1101
	ld	bc,#040D
	call	FadeIn		; fade in background
	pop	de

	ld	a,15
  if CV=2
	ld	hl,#4301
  else
	ld	hl,#1304
  endif
	call	PALETTE

Pagep:	
	ld	a,15
	ld	(FORCLR),a
	ld	a,4
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors (foreground=background)

  if EFF=1
	call	CLS
  endif
	ld	hl,#0101
	call    POSIT
	ld	hl,StMSG_S	; print main screen messages
	call	print	

	call	PrintPN		; Print page number

; Print autostarted entry
	ld	hl,#2305
	call    POSIT
	exx
	ld	a,c
	exx
	cp	#FF		; skip printing #FF
	jr	z,Pagep1
	call	hexout		; print autostart entry number

Pagep1:
	ld	e,0		; set first string
	exx
	ld	a,d	
	exx
	ld	d,a

; print page ( 16 record )
sPrr1:	call 	c_dir		; calc dir entry point
	jr	nz,prStr	; valid dir entry?
nRec:	inc	d
	jp	z,dRec		; done, last record
	jr	sPrr1

; Print directory entry
prStr:
;----str---------------------
; (ix , d) - record num , e - str num
; *(h,l, a b)

; set cursor position
	ld	h,3
	ld	a,e
	add	a,7
	ld	l,a
	call	POSIT
; record number
	ld	a,d
	call	hexout
; space
	ld	a,' '
	call	CHPUT

; set hl-point
	push 	ix
	pop	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
; mapper symbol
	ld	a,(hl)
	call	CHPUT
	inc	hl

; spaces
	ld	a,' '
	call	CHPUT
	ld	a,' '
	call	CHPUT

; print record name
	ld	b,30
sPr:	ld	a,(hl)
	call	CHPUT
	inc	hl
	djnz	sPr

	inc	d
	jr	z,dRec		; last found dir entry?
	inc	e
	ld	a,e		; last string on the page?
	cp	L_STR
	jp	c,sPrr1

dRec:
	ld	e,0		; cursor at 0
	exx	
	ld	a,d
	exx
	ld	d,a		; restore dir entries to top page
	push	de
	ld	de,#7707
  if CV=2
	ld	hl,#4301
  else
	ld	hl,#1304
  endif
	ld	bc,#0F0D
	call	FadeIn		; fade in text
	pop	de

; set cursor pos on first entry
CH00:
	call	c_dir
	ld	h,7
	ld	a,e
	add	a,7
	ld	l,a
	call	POSIT

	ld	a,">"		; print cursor
	call	CHPUT

	call	POSIT

CH01:
	ld	bc,#0000	; no autostart - effects enabled
	call	KILBUF
	call	CHGET
	cp	27		; ESC
	jp	z,Exit
	cp	30		; UP
	jp	z,C_UP
	cp	31		; DOWN
	jp	z,C_DOWN
	cp	29		; LEFT
	jp	z,P_B
	cp	28		; RIGTH
	jp	z,P_F
	cp	32		; SPACE
	jp	z,RUN_CT	; run selected record
	cp	"R"
	jp	z,RUN_CR	; run on reset
	cp	"G"
	jp	z,RUN_CJ	; run directly
	cp	"A"
	jp	z,AUTO_R	; set selected record for autorun
	cp	"D"
	jp	z,DAUTO_R	; disable autorun record
	cp	"?"
	jp	z,Help		; show help
	cp	"h"
	jp	z,Help
	cp	"H"
	jp	z,Help
	jr	CH01


; Cursor up (previous str select)
C_UP:
	ld	a,e
	or	a
	jr	z,CH01		; 1-st string?
	ld	a," "
	call	CHPUT		; clear cursor
C_U00:	dec	e
C_U01:	dec	d
	ld	a,#FF
	cp	d
	jp	z,C_D00
	call	c_dir
	jr	z,C_U01
	jp	CH00


; Cursor down (next str select)
C_DOWN:
	ld	a,e
	cp	L_STR-1
	jp	nc,CH01		; last str
	ld	a," "	
	call	CHPUT		; clear cursor
C_D00:	inc	e
C_D01:	inc	d
	ld	a,#FF
	cp	d
	jp	z,C_U00
	call	c_dir
	jr	z,C_D01
	jp	CH00


; Flip page forward
P_F:
	ld	hl,DIRPAG
	ld	a,(hl)
	cp	1		; only one page?
	jp	z,CH01
	ld	hl,CURPAG
	cp	(hl)		; current page = max pages?
	jp	z,CH01

  if EFF=1
	push	de
	ld	hl,#7707
  if CV=2
	ld	de,#4301
  else
	ld	de,#1304
  endif
	ld	bc,#0F0D
	call	FadeOut		; fade out text
	pop	de
  endif
	exx
	ld	a,d
	exx
	ld	d,a		; extract 1st page

; next N str
	ld	e,L_STR
PF01:	inc	d
	ld	a,#FF
	cp	d
	jp	z,Pagep		; out of dir?
	call	c_dir
	jr	z,PF01		; empty/deleted?
	dec	e
	jr	nz,PF01

; save new start d
	ld	a,d
	exx
	ld	d,a
	exx

	ld	hl,CURPAG
	inc	(hl)		; increment page number
	jp	Pagep


; Flip page back
P_B:
	ld	hl,DIRPAG
	ld	a,(hl)
	cp	1		; only one page?
	jp	z,CH01
	ld	hl,CURPAG
	ld	a,(hl)
	cp	1		; current page = first page?
	jp	z,CH01

  if EFF=1
	push	de
	ld	hl,#7707
  if CV=2
	ld	de,#4301
  else
	ld	de,#1304
  endif
	ld	bc,#0F0D
	call	FadeOut		; fade out text
	pop	de
  endif

	exx
	ld	a,d
	exx
	ld	d,a		; extract 1st page

; previos N str
	ld	e,L_STR
PB01:	dec	d
	ld	a,#FF
	cp	d
	jr	z,PB02		; out of dir?
	call	c_dir
	jr	z,PB01
	dec	e
	jr	nz,PB01

; save new start d
PB03:	ld	a,d
	exx
	ld	d,a
	exx

	ld	hl,CURPAG
	dec	(hl)		; increment page number
	jp	Pagep

PB02:	ld	d,0
	ld	hl,CURPAG
	ld	a,1
	ld	(hl),a
	jp	PB03


; Run selected record
RUN_CT:
; Start and autostart
; ix - point entry pointer

	ld	a,(ix+#3E)
	bit	0,a
	jp	nz,RUN_CR
	bit	1,a
	jp	nz,RUN_CJ

	ld	a,b
	cp	#FF
	jr	nz,RUN_CT1
	ld	a,c
	cp	#FF
	jr	z,RUN_CT2

RUN_CT1:
	ld	hl,#7707
  if CV=2
	ld	de,#4301
  else
	ld	de,#1304
  endif
	ld	bc,#0F0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#1101
  if CV=2
	ld	hl,#4301
  else
	ld	hl,#1304
  endif
	ld	bc,#040D
	call	FadeOut		; fade out background

	ld	a,15
	ld	hl,#1101
	call	PALETTE
	ld	a,4
	ld	hl,#1101
	call	PALETTE

	ld	a,15
	ld	(FORCLR),a
	ld	a,4
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors (foreground=background)

	ld	de,#1701
	ld	hl,#1101
	ld	bc,#040D
	call	FadeIn		; fade in background

	call	Restfnt		; restore font

RUN_CT2:
	ld	a,%00101100
	ld	(CardMDR),a
	ld	a,(ix+2)
	ld	(CardMDR+#05),a	; set start block
	push	ix
	pop	hl
	ld	bc,#23
	add	hl,bc		; config data
	ld	de,CardMDR+#06
	ld	bc,26
	ldir

;	ld	a,(hl)
;	or	%00001100
;	ld	(de),a
	
	ld	hl,RJP
	ld	de,R_Base
	ld	bc,RJPE-RJP
	ldir

	ld	a,#C9
	ld	(R_Base+3),a
	jp	R_Base


; Run selected record via reset
RUN_CR:
	ld	a,b
	cp	#FF
	jr	nz,RUN_CR1
	ld	a,c
	cp	#FF
	jr	z,RUN_CR2

RUN_CR1:
	ld	hl,#7707
  if CV=2
	ld	de,#4301
  else
	ld	de,#1304
  endif
	ld	bc,#0F0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#1101
  if CV=2
	ld	hl,#4301
  else
	ld	hl,#1304
  endif
	ld	bc,#040D
	call	FadeOut		; fade out background

	ld	a,15
	ld	hl,#1101
	call	PALETTE
	ld	a,4
	ld	hl,#1101
	call	PALETTE

	ld	a,15
	ld	(FORCLR),a
	ld	a,4
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors (foreground=background)

	ld	de,#1701
	ld	hl,#1101
	ld	bc,#040D
	call	FadeIn		; fade in background

	ld	a,15
	ld	hl,#1701
	call	PALETTE

	call	Restfnt		; restore font

; Configure cart register and restart
; ix - point dir entry
; 
RUN_CR2:
	ld	a,%00101000
	ld	(CardMDR),a
	ld	a,(ix+2)
	ld	(CardMDR+#05),a	; set start block
	push	ix
	pop	hl
	ld	bc,#23
	add	hl,bc		; config data for registers
	ld	de,CardMDR+#06
	ld	bc,24
	ldir

	ld	a,(ix+3)
	cp	1		; only one block long?
	jr	nz,RUN_CR3
	ld	a, (hl)
	and	%00000001
	or	1
	ld	(de),a		; disable extended slot for small games
	inc	hl
	inc	de
	ld	a,(hl)
	and	%11111011
	ld	(de),a		; set reconfig after jp 0
	jr	RUN_CR4

; !!! Check the reset flag for F4 port from the directory entry!
; Support for this flag is pending, may be not implemented after all
RUN_CR3:
	ld	a,(hl)
	ld	(de),a
	inc	hl
	inc	de
	ld	a,(hl)
	ld	(de),a

RUN_CR4:
	in	a,(#F4)
	or	#80
	out	(#F4),a		; avoid "warm" reset on MSX2+

Reset:
	ld	hl,ResetMSG	; print rebooting message
	call	print	

	jp	0000		; reset system
;	db	#F7,#80,#00,#00	; RST #30 = reset if previous fails


; Run selected record directly (using the ROM's start adddress
RUN_CJ:
	ld	a,b
	cp	#FF
	jr	nz,RUN_CJ1
	ld	a,c
	cp	#FF
	jr	z,RUN_CJ2

RUN_CJ1:
	ld	hl,#7707
  if CV=2
	ld	de,#4301
  else
	ld	de,#1304
  endif
	ld	bc,#0F0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#1101
  if CV=2
	ld	hl,#4301
  else
	ld	hl,#1304
  endif
	ld	bc,#040D
	call	FadeOut		; fade out background

	ld	a,15
	ld	hl,#1101
	call	PALETTE
	ld	a,4
	ld	hl,#1101
	call	PALETTE

	ld	a,15
	ld	(FORCLR),a
	ld	a,4
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors (foreground=background)

	ld	de,#1701
	ld	hl,#1101
	ld	bc,#040D
	call	FadeIn		; fade in background

	ld	a,15
	ld	hl,#1701
	call	PALETTE

	call	Restfnt		; restore font

RUN_CJ2:
; Configure cart register and start ROM
; ix - point dir entry

	ld	a,%00101100
	ld	(CardMDR),a
	ld	a,(ix+2)
	ld	(CardMDR+#05),a	; set start block
	push	ix
	pop	hl
	ld	bc,#23
	add	hl,bc		; config data
	ld	de,CardMDR+#06
	ld	bc,26
	ldir

;	ld	a,(hl)		; corr
;	or	%00001100	; corr
;	ld	(de),a		; corr

	ld	hl,RJP
	ld	de,R_Base
	ld	bc,RJPE-RJP
	ldir
	ld	a,(ix+#3E)
	bit	2,a
	jp	z,R_Base
	ld	a,#80
	ld	(R_Base+5),a
	jp	R_Base

RJP:
	ld	a,(#4000)
	ld	hl,(#4002)
	jp	(hl)
RJPE:	nop


; Disable autostart
DAUTO_R:
	ld	a,2
	ld	(CardMDR+#0E),a	; set 2nd bank to autostart map

; seek to active autostart
	ld	hl,#8000
DSA_01:	ld	a,(hl)
	cp	#FF
	jr	nz,DSA_02	; next entry?
 	inc	hl
	ld	a,(hl)	
	cp	#FF		; deselected?
	jp	z,ATR_04	; do nothing

; deactivate autostart entry
	dec	hl
	call	ATR_B_Erase
	ld	a,#FF
	jp	ATR_04	
DSA_02:
	inc	hl
	inc	hl
	ld	a,h
	cp	#A0		; out of range ?
	jp	c,DSA_01

; erase autostart map
	call	ATR_M_Erase
	ld	hl,#8000
	ld	a,#FF
	jp	ATR_04	


; Set current recod (d) for autostart
AUTO_R:
	ld	a,2
	ld	(CardMDR+#0E),a	; set 2nd bank to autostart map

; seek to active autostart
	ld	hl,#8000
ATR_01:	ld	a,(hl)
	cp	#FF
	jr	nz,ATR_02	; next
 	inc	hl
	ld	a,(hl)	
	cp	d		; the same record ?
	jp	z,ATR_05	; do nothing
	cp	#FF		; not autostart record?
	jr	z,ATR_00	; save autostart record

; deactivate record
	dec	hl
	call	ATR_B_Erase

; save new autostart record
	inc	hl
	inc	hl
	inc	hl
ATR_00:	call	ATR_B_Prog
ATR_05:	ld	a,d
ATR_04:	exx
	ld	c,a
	exx
	ld	a,1
	ld	(CardMDR+#0E),a	; set 2nd bank to directory map

; print new autostart record number
	ld	hl,35*256+05	; #23 position
	call	POSIT
	exx
	ld	a,c
	exx
	cp	#FF
	jr	nz,ATR_03

	ld	hl,Spaces	; print spaces instead of #FF
	call	print	
	jp	CH00

ATR_03:
	call	hexout	
	jp	CH00
ATR_02:
	inc	hl
	inc	hl
	ld	a,h
	cp	#A0		; out of range?
	jp	c,ATR_01	

; erase autostart map
	call	ATR_M_Erase
	ld	hl,#8001
	jp	ATR_05


ATR_B_Erase:
	di
	push	de
	push	hl
	ld	hl,RABE
	ld	de,R_Base
	ld	bc,RABEE-RABE
	ldir
	pop	hl
	pop	de
	jp	R_Base
RABE:
	ld	a,#AA
	ld	(#8AAA),a
	ld	a,#55
	ld	(#8555),a
	ld	a,#A0
	ld	(#8AAA),a
	xor	a
	ld	(hl),a
	ld	b,a
RABE2:	ld	a,(hl)
	xor	b
	bit	7,a
	jr	z,RABE1
	xor	b
	and	#20
	jr	z,RABE2
RABE1:	ret
RABEE

	
ATR_B_Prog:
	di
	push	de
	push	hl
	ld	hl,RABT
	ld	de,R_Base
	ld	bc,RABTE-RABT
	ldir
	pop	hl
	pop	de
	jp	R_Base
RABT:
	ld	a,#AA
	ld	(#8AAA),a
	ld	a,#55
	ld	(#8555),a
	ld	a,#A0
	ld	(#8AAA),a
	ld	a,d
	ld	(hl),a
	ld	b,a
RABT2:	ld	a,(hl)
	xor	b
	bit	7,a
	jr	z,RABT1
	xor	b
	and	#20
	jr	z,RABT2
RABT1:	ret
RABTE


ATR_M_Erase:
	di
	push	de
	push	hl
	ld	hl,RAME
	ld	de,R_Base
	ld	bc,RAMEE-RAME
	ldir
	pop	hl
	pop	de
	jp	R_Base
RAME:
	ld	a,#AA
	ld	(#8AAA),a
	ld	a,#55
	ld	(#8555),a
	ld	a,#80
	ld	(#8AAA),a
	ld	a,#AA
	ld	(#8AAA),a
	ld	a,#55
	ld	(#8555),a
	ld	a,#30
	ld	(#8000),a
RAME2:	ld	a,(#8000)
	xor	#FF
	bit	7,a
	jr	z,RAME1
	xor	#FF
	and	#20
	jr	z,RAME2
RAME1:	ret
RAMEE


; Print help information page
Help:
  if CV=2
	ld	de,#4301
  else
	ld	de,#1304
  endif
	ld	hl,#7707
	ld	bc,#0F0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#1101
  if CV=2
	ld	hl,#4301
  else
	ld	hl,#1304
  endif
	ld	bc,#040D
	call	FadeOut		; fade out background

	ld	a,4
	ld	hl,#1101
	call	PALETTE
	ld	a,15
	ld	(FORCLR),a
	ld	a,4
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors (foreground=background)

	ld	a,15
	ld	hl,#1401
	call	PALETTE

	ld	de,#1401
	ld	hl,#1101
	ld	bc,#040D
	call	FadeIn		; fade in background

	ld	hl,helpmsg
	call	print
	ld	hl,#1D16	; position cursor after "Press any key"
	call    POSIT

	ld	de,#7707
	ld	hl,#1401
	ld	bc,#0F04
	call	FadeIn		; fade in text

	call	KILBUF
	call	CHGET		; wait for a key

	ld	de,#1401
	ld	hl,#7707
	ld	bc,#0F04
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#1101
	ld	hl,#1401
	ld	bc,#040D
	call	FadeOut		; fade out background

  if CV=2
	ld	de,#4301
  else
	ld	de,#1304
  endif
	ld	hl,#1101
	ld	bc,#040D
	call	FadeIn		; fade in background

	ld	a,15
  if CV=2
	ld	hl,#4301
  else
	ld	hl,#1304
  endif
	call	PALETTE

	jp	Pagep


; Exit from boot block
Exit:
  if CV=2
	ld	de,#4301
  else
	ld	de,#1304
  endif
	ld	hl,#7707
	ld	bc,#0F0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#1101
  if CV=2
	ld	hl,#4301
  else
	ld	hl,#1304
  endif
	ld	bc,#040D
	call	FadeOut		; fade out background

	ld	a,15
	ld	hl,#1101
	call	PALETTE
	ld	a,4
	ld	hl,#1101
	call	PALETTE

	ld	a,15
	ld	(FORCLR),a
	ld	a,4
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors (foreground=background)

	ld	de,#1701
	ld	hl,#1101
	ld	bc,#040D
	call	FadeIn		; fade in background

	ld	a,15
	ld	hl,#1701
	call	PALETTE

	call	Restfnt		; restore font
	ret


; Fade-in effect
; In: de (target palette)
; In: hl (current palette)
; In: bc (foreground/background colors)
FadeIn:
  if EFF=0
	ld	a,b
	push	de
	pop	hl
	call	PALETTE		; set target palette without fade effect
	ret
  endif

	ld	a,b
	call	PALETTE		; initial palette set for color

FadeL0:
	push	bc
	ld	bc,FDelay
	call	Delay
	pop	bc
	
	ld	a,l
	cp	e
	jr	z,FadeL1
	inc	l
FadeL1:	ld	a,h
	and	#0F
	push	de
	push	af
	ld	a,d
	and	#0F
	ld	d,a
	pop	af
	cp	d
	jr	z,FadeL2
	inc	h
FadeL2:
	pop	de
	ld	a,h
	and	#F0
	push	de
	push	af
	ld	a,d
	and	#F0
	ld	d,a
	pop	af
	cp	d
	jr	z,FadeL3
	ld	a,h
	add	a,#10
	ld	h,a
FadeL3:	
	pop	de
	ld	a,b
	call	PALETTE		; set modified palette for foreground color
	ld	a,h
	cp	d
	jr	nz,FadeL0
	ld	a,l
	cp	e
	jr	nz,FadeL0
	ret


; Fade-out effect
; In: de (target palette)
; In: hl (current palette)
; In: bc (foreground/background colors)
FadeOut:
  if EFF=0
	ld	a,b
	push	de
	pop	hl
	call	PALETTE		; set target palette without fade effect
	ret
  endif

	ld	a,b
	call	PALETTE		; initial palette set for foreground color

FadeL4:
	push	bc
	ld	bc,FDelay
	call	Delay
	pop	bc
	
	ld	a,l
	cp	e
	jr	z,FadeL5
	dec	l
FadeL5:	ld	a,h
	and	#0F
	push	de
	push	af
	ld	a,d
	and	#0F
	ld	d,a
	pop	af
	cp	d
	jr	z,FadeL6
	dec	h
FadeL6: 
	pop	de
	ld	a,h
	and	#F0
	push	de
	push	af
	ld	a,d
	and	#F0
	ld	d,a
	pop	af
	cp	d
	jr	z,FadeL7
	ld	a,h
	ld	h,#10
	sub	h
	ld	h,a
FadeL7:	
	pop	de
	ld	a,b
	call	PALETTE		; set modified palette for foreground color
	ld	a,h
	cp	d
	jr	nz,FadeL4
	ld	a,l
	cp	e
	jr	nz,FadeL4
	ret


; Artificial delay
; In: bc (number of loops)
Delay:
	dec	bc
	ld	a,b
	or	a
	jr	nz,Delay
	ret


; Restore font address and slot
Restfnt:
	push	af
	push	hl
	push	de
	push	bc
	ld	a,(BSLT)
        ld	(CHSETS),a	; restore bios font's slot
	ld	hl,(BFNT)
	ld	(CHSETA),hl	; restore bios font's address
	ld	a,15
	ld	(FORCLR),a
	ld	a,4
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors
        ld	a,15
  	ld	hl,#7707
	call	PALETTE
        ld	a,4
  	ld	hl,#1701
	call	PALETTE
	xor	a
	call	SSCREEN
	call	MODE40A
	call	CLS
	pop	bc
	pop	de
	pop	hl
	pop	af
	ret


; Set font address and slot
Setfnt:	push	af
	push	hl
	push	de
	push	bc

;	ld	hl,#0F84
;	ld	(#4F81),hl
;	xor	a
;	ld	(#4F83),a	; disable 'hole' in ROM
;	ld	a,(#4F80)
;	or	1
;	ld	(#4F80),a	; disable 'holes' in ROM

	ld	a,(CHSETS)
	ld	(BSLT),a	; save bios font's slot
	ld	hl,(CHSETA)
	ld	(BFNT),hl	; save bios font's address
	call	SltDet
	ld	(CHSETS),a
	ld	hl,fontdat+1
	ld	(CHSETA),hl	; set new font address
	ld	a,40
	ld	(SCR0WID),a	; set default width of screen0
	xor	a
	call	SSCREEN		; set screen 0
	call	MODE40		; set 40x25 mode
	call	DISKEYS		; no functional key display
	call	CLS
	pop	bc
	pop	de
	pop	hl
	pop	af
	ret


; Set palette for a color
; In: a - color
; In: hl = palette in BRG format
PALETTE:
	out	(#99),a
	ld	a,#90
	out	(#99),a
	ei
	ex	(sp),hl
	ex	(sp),hl
        ld	a,h
        out	(#9A),a
        ld	a,l
        out	(#9A),a
	ret


; Print	string
; Inp reg hl - point start string
; (hl) = 0 -> end
print:
	ld	a,(hl)
	or	a
	ret	z
	call	CHPUT
	inc	hl
	jr	print


; Detect slot
; Out reg A = present value slot on 4000-7FFF
SltDet:
	di
	in	a,(#A8)
	ld	b,a		; save primary slot
	and	%00111111
	ld	c,a
	ld	a,b
	and	%00001100
	rlc	a
	rlc	a
	rlc	a
	rlc	a
	or	c
	out	(#A8),a		; set page3 to slot from page1
	ld	a,(#FFFF)
	xor	#FF
	ld	c,a		; save secondary slot
	xor	%11000000
	ld	d,a		; test page3
	ld	(#FFFF),a
	ld	a,(#FFFF)
	cp	d		; Z - (#FFFF)= RAM
	jr	z,notExpS
	xor	#FF
	cp	c		; Z - (#FFFF)= constant		
	jr	z,notExpS	
	cp	d		; rd = neg(wr) - Slot register
	jr	nz,notExpS		
	ld	a,c
	ld	(#FFFF),a	; restore value Expand slot
	and	%00001100
	or	%10000000       ; record detect secondary
	jr	sldet1	
notExpS:
	ld	a,c
	xor	#FF
	ld	(#FFFF),a 	; restore value memory byte
	xor	a
sldet1:	ld	c,a
	ld	a,b
	rrc	a
	rrc	a
	and	%00000011       ; record detect primary
	or	c		; A - out value
	ld	c,a
	ld	a,b
	out	(#A8),a
	ld	a,c
	ret


; Find position of the entry in the directory
c_dir:
; input d - dir index num
; outut	ix - dir entry pointer
; output Z - empty/deleted entry

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
	add	ix,bc		; 8000h + b*64

; test empty/delete
	ld	a,(ix)
	cp	#FF		; empty record?
	ret	z
	ld	a,(ix+1)
	or	a		; deleted/empty record?
	ret


; Print HEX number
hexout:	push	af
	rrc     a
	rrc     a
	rrc     a
	rrc     a
	and 	#0F
	add	a,48
	cp	58
	jr	c,he1
	add	a,7
he1:	call	CHPUT
	pop	af
	and 	#0F
	add	a,48
	cp	58
	jr	c,he2
	add	a,7
he2:	call	CHPUT
	ret

CLS:	push	af
	push	de
	push	bc
	xor	a
	call	CLEARS
	pop	bc
	pop	de
	pop	af
	ret


; Print page number
PrintPN:
	push	hl
	ld	hl,DIRPAG
	ld	a,(hl)
	cp	1		; only one page?
	pop	hl
	ret	z
	push	hl
	push	de
	push	bc
	ld	hl,#1B17
	call    POSIT
	ld	hl,PageNum	; print page number string
	call	print	
	ld	hl,#2317
	call    POSIT
	ld	hl,CURPAG
	ld	a,(hl)
	call	hexout		; print current directory page
	pop	bc
	pop	de
	pop	hl
	ret


;
; DATA AREA
; The data area must start above the registers (#4F80...)
;	

	org	#5000

StMSG_S:
	db	#88,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8F
  if CV=2
	db	#8C," Carnivore2 MultiFunctional Cartridge ",#8D
	db	#8C,"  (C) 2017 RBSC.  Press '?' for Help  ",#8D
  else
	db	#8C,"  Carnivore MultiFlash SCC Cartridge  ",#8D
	db	#8C,"  (C) 2016 RBSC.  Press '?' for Help  ",#8D
  endif
	db	#8C,"                                      ",#8D
	db	#8C,"  Entry selected for autostart: [  ]  ",#8D
	db	#8C,"                                      ",#8D
	db	#8C,#01,#50,"                                    ",#01,#52,#8D
	db	#8C,#01,#57,"                                    ",#01,#53,#8D
	db	#8C,#01,#57,"                                    ",#01,#53,#8D
	db	#8C,#01,#57,"                                    ",#01,#53,#8D
	db	#8C,#01,#57,"                                    ",#01,#53,#8D
	db	#8C,#01,#57,"                                    ",#01,#53,#8D
	db	#8C,#01,#57,"                                    ",#01,#53,#8D
	db	#8C,#01,#57,"                                    ",#01,#53,#8D
	db	#8C,#01,#57,"                                    ",#01,#53,#8D
	db	#8C,#01,#57,"                                    ",#01,#53,#8D
	db	#8C,#01,#57,"                                    ",#01,#53,#8D
	db	#8C,#01,#57,"                                    ",#01,#53,#8D
	db	#8C,#01,#57,"                                    ",#01,#53,#8D
	db	#8C,#01,#57,"                                    ",#01,#53,#8D
	db	#8C,#01,#57,"                                    ",#01,#53,#8D
	db	#8C,#01,#56,"                                    ",#01,#54,#8D
	db	#8E,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#89
	db	0

helpmsg:
	db	#01,#58,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59
	db	#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#5A
  if CV=2
	db	#01,#5B,"  Carnivore2 Cartridge's Help Screen  ",#01,#5F
  else
	db	#01,#5B,"  Carnivore Cartridge's Help Screen   ",#01,#5F
  endif
	db	#01,#5B,"                                      ",#01,#5F
	db	#01,#5B," Menu Navigation and Action Keys:     ",#01,#5F
	db	#01,#5B,"                                      ",#01,#5F
	db	#01,#5B,#20,#01,#50,"[ESC] - boot MSX using the default  ",#01,#5F
  if CV=2
	db	#01,#5B,#20,#01,#57,"        configuration: all enabled  ",#01,#5F
  else
	db	#01,#5B,#20,#01,#57,"        configuration               ",#01,#5F
  endif
	db	#01,#5B,#20,#01,#57,"                                    ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[LEFT],[RIGHT] - previous/next page ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[UP],[DOWN] - select ROM/CFG entry  ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[SPACE]     - start entry normally  ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[SHIFT]+[G] - start entry directly  ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[SHIFT]+[R] - reset and start entry ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[SHIFT]+[A] - entry's autostart ON  ",#01,#5F
	db	#01,#5B,#20,#01,#56,"[SHIFT]+[D] - entry's autostart OFF ",#01,#5F
	db	#01,#5B,"                                      ",#01,#5F
	db	#01,#5B," Startup Option Keys:                 ",#01,#5F
	db	#01,#5B,"                                      ",#01,#5F
	db	#01,#5B,#20,#01,#50,"[TAB] - disable autostart option    ",#01,#5F
	db	#01,#5B,#20,#01,#56,"[F5]  - disable startup menu        ",#01,#5F
	db	#01,#5B,"                                      ",#01,#5F
	db	#01,#5B," Press any key to return...           ",#01,#5F		
	db	#01,#5E,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D
	db	#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5C
	db	0

Spaces:	db	"  ",0

ResetMSG:
	db	"Rebooting MSX...",0
PageNum:
	db	" Page: [  ] ",0

B2ON:	db	#F0,#70,#01,#15,#7F,#80

fontdat:db	0

	include	"font.inc"
