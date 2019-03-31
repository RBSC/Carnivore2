;
; Carnivore/Carnivore2 Cartridge's Boot Block
; Copyright (c) 2015-2019 RBSC
; Portions (c) Grauw
; Version 2.10
;

; !COMPILATION OPTIONS!
CV	equ	2		; 1 = Canivore
				; 2 = Canivore2
SPC	equ	0		; 1 = only basic characters are used for UI (for Arabic and Korean computers)
				; 0 = all characters are used for UI

; Variables
KEYCLK	equ	#F3DB
FORCLR 	equ	#F3E9
BAKCLR 	equ	#F3EA
BDRCLR 	equ	#F3EB
CHSETA	equ	#F920
CHSETS	equ	#F91F
SCR0WID	equ	#F3AE
BSLT	equ	#F560
BFNT	equ	#F562
DIRCNT	equ	#F564	; 2 bytes!
DIRPAG	equ	#F566	; 2 bytes!
CURPAG	equ	#F568	; 2 bytes!
VDPVER	equ	#F56A
PALNTSC	equ	#F56C
XYPOS	equ	#F56E	; 2 bytes!
AUTOST	equ	#F570
PSGCFG	equ	#F572
ORGVR10	equ	#F574
MSXTYPE	equ     #F576
TURBOM	equ	#F578

; Variables for UI setup
SKIPFD	equ	#F579	; 1 byte
SELITEM	equ	#F57A	; 1 byte
SORT	equ	#F580	; 1 byte
EFF	equ	#F581	; 1 byte
SPD	equ	#F582	; 1 byte

; Colors for main menu screen -------------
; First value - foreground color
; Second value - foreground color palette
; Third value - background color
; Fourth value - background color palette

C2FCOLM	equ	15
C2FPALM	equ	#F583	; 2 bytes!
C2BCOLM	equ	13
C2BPALM	equ	#F585	; 2 bytes!

; Colors for help screen -------------
C2FCOLH	equ	15
C2FPALH	equ	#F587	; 2 bytes!
C2BCOLH	equ	4
C2BPALH	equ	#F589	; 2 bytes!

; Colors for volume screen -------------
C2FCOLV	equ	15
C2FPALV	equ	#F58B	; 2 bytes!
C2BCOLV	equ	12
C2BPALV	equ	#F58D	; 2 bytes!

; Colors for PSG setup screen -------------
C2FCOLP	equ	15
C2FPALP	equ	#F58F	; 2 bytes!
C2BCOLP	equ	6
C2BPALP	equ	#F591	; 2 bytes!

SETXY	equ	#F593	; 2 bytes!
SORTBUF	equ	#F595	; will use 64 characters for sorting!

VDPR10	equ	#FFE8
KEYBUF	equ	#FBF0

; Card configuration registers
CardMDR equ	#4F80

; Delay for fading
FDelay	equ	#1000

; Delay for autostart
ADelay	equ	3

; Delay for joystick (video frame based: assuming 60Hz for NTSC, 50Hz for PAL)
NTSC_dl	equ	6
PAL_dl	equ	5

R_Base	equ	#C010
L_STR	equ	16


;------------------------------------------

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
	db	0
Vers	db	"v2.10"  ; Version | also update it in the header!
	db	0


Boot:
	ld	a,(#FBEC)
	and	%00000010	; F5 - don't start boot block
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


; Load data (FMPAC/SCC/SCC+/PSG audio volume and other settings) from small EEPROM
  if CV=2
	ld	a,1
	call	EERD		; read volume setting from EEPROM
	ld	b,a
	and	%11000000
	cp	%10000000	; volume was set from boot block? (bit 7 = 1, bit 6 = 0)
	jr	nz,TA_0A
	ld	a,b
	ld	(CardMDR+#22),a	; set the previously stored FMPAC/SCC/SCC+ volume

; Read 50/60Hz status from EEPROM
TA_0A:
	ld	a,(VDPR10)	; read vdp register 10
	ld	(ORGVR10),a	; save original value
	ld	(PALNTSC),a	; save current mode
	xor	a
	ld	(SKIPFD),a	; skip fade disabled
	ld	(VDPVER),a	; VDP is v9918 by default	
	call	DetVDP		; Detect actual VDP
	ld	(VDPVER),a	; save vdp verison (0=v9918, 1=v9938, 2=v9958)
	or	a
	jr	z,TA_0B		; don't use frequency change on MSX1

	ld	a,2
	call	EERD		; read PAL/NTSC setting from EEPROM
	and	%00000011
	cp	3		; illegal value?
	jr	z,TA_0B
	cp	1		; illegal value?
	jr	z,TA_0B
	ld	(PALNTSC),a     ; save the value
	ld	b,a
	ld	a,9
	ld	c,a
	call	WRITVDP		; write to VDP register (set 50 or 60 HZ mode)
TA_0B:
	ld	a,3
	call	EERD		; read volume setting from EEPROM
	ld	(CardMDR+#24),a	; set the previously stored PSG volume
	ld 	(PSGCFG),a

	ld	hl,SORTD
	ld	de,SORT
	ld	bc,19
	ldir			; reset all UI settings to defaults
	ld	a,(#FBEB)
	and	%10000000	; F3 - don't load UI settings
	jr	z,TA_0B3

	ld	a,#17		; address
	call	EERD		; read custom flag from EEPROM
	cp	#42		; custom settings?
	jr	nz,TA_0B3

	ld	a,4
	call	EERD		; read sorting flag
	ld	(SORT),a
	ld	a,5
	call	EERD		; read effects flag
	ld	(EFF),a
	ld	a,6
	call	EERD		; read key/joystick speed
	cp	10		; max value
	jr	nc,TA_0B1
	ld	(SPD),a

TA_0B1:
	ld	a,7
	ld	hl,C2FPALM
TA_0B2:
	push	af
	call	EERD		; read palette from EEPROM
	ld	(hl),a
	inc	hl
	pop	af
	inc	a
	cp	#17
	jr	nz,TA_0B2

TA_0B3:
	ld	a,(VDPVER)
	inc	a
	ld	(MSXTYPE),a	; save MSX type
  endif

        call	SetEnv		; set environment (screen, colors, fonts)

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
	jr	z,DSort		; last page?
	jr	c,DSort		; last page?
	inc	(hl)		; add one dir page
	sub	L_STR		; more dir pages?
	jr	DirC3


DSort:	call	DirSort		; sort directory


; Check for autostart
	xor	a
	ld	(AUTOST),a	; no autostart

	ld	d,#FF
	ld	a,2
	ld	(CardMDR+#0E),a ; set 2nd bank to autostart map
	ld	a,(SORT)
	or	a
	jr	z,TA_02
	ld	hl,B2ON+#03
	ld	a,(hl)
	ld	(CardMDR+#0F),a	; show flash instead of RAM for autostart

TA_02:
	ld	hl,#8000
TA_00:	ld	a,(hl)
	or	a
	jp	z,TA_01
	inc	hl
	ld	a,(hl)
	ld	d,a
	cp	#FF
	jp	z,Menu		; deselected autostart

; Autostart entry found!
	ld	a,1
	ld	(CardMDR+#0E),a ; set 2nd bank to directory map		
	ld	a,(SORT)
	or	a
	jr	z,TA_06
	ld	hl,RAM_SORT+#03
	ld	a,(hl)
	ld	(CardMDR+#0F),a	; show RAM instead of flash for directory

TA_06:
	call 	c_dir
	jp	z,Menu		; empty record, go to menu

	ld	a,(#FBEC)
	and	%00001101	; ESC, F4 no autostart
	cp	%00001101
	jp	nz,Menu

	ld	a,#FF
	ld	(AUTOST),a	; autostart found
	call	CLS
	ld	hl,AutoMSG
	call	print		; print autostart message

	ld	hl,#0000
	ld	bc,ADelay*60	; set delay for autostart in NTSC
	ld	a,(PALNTSC)
	bit	1,a
	jr	z,AutoWait
	ld	bc,ADelay*50	; set delay for autostart for PAL

AutoWait:
	ld	a,2
	call	VDP_VScan	; wait for VSYNC to start
	and	#40
	jr	nz,AutoWait

AutoWait1:
	ld	a,2
	inc	h
	call	VDP_VScan	; wait for VSYNC to end (1 frame to draw)
	and	#40
	jr	z,AutoWait1

	ld	a,(#FBEC)
	and	%00001101	; ESC, F4 no autostart
	cp	%00001101
	jr	nz,AutoWAb	; Abort

	dec	bc
	inc	l
	ld	a,l
	cp	50
	jr	nz,AutoWait2

	xor	a
	call	GTTRIGG		; space/built-in buttons
	or	a
	jp	nz,AutoWAb
	ld	a,1
	call	GTTRIGG		; joystick 1 button A
	or	a
	jp	nz,AutoWAb
	ld	a,2
	call	GTTRIGG		; joystick 2 button A
	or	a
	jp	nz,AutoWAb
	ld	a,3
	call	GTTRIGG		; joystick 1 button B
	or	a
	jp	nz,AutoWAb
	ld	a,4
	call	GTTRIGG		; joystick 2 button B
	or	a
	jp	nz,AutoWAb

	push	hl
	ld	hl,AutoDot
	call	print		; print a dot every 50 frames
	pop	hl
	xor	a
	ld	l,a

AutoWait2:
	ld	a,b
	or	a
	jr	nz,AutoWait
	ld	a,c
	or	a
	jr	nz,AutoWait

	ld	hl,CRLF
	call	print

	jp	RUN_CT		; not empty record, do autostart

AutoWAb:
	xor	a
	ld	(AUTOST),a	; no autostart
	jr	Menu

TA_01:	inc	hl		; next auto
	inc	hl
	ld	a,h
	cp	#A0		; 8kb limit?
	jp	c,TA_00		; next entry


; Main Menu
; Search records (64b) max - 256
Menu:
	ld	c,d
	exx
	ld	a,1
	ld	(CardMDR+#0E),a ; set 2nd bank to directory map
	ld	a,(SORT)
	or	a
	jr	z,TA_07
	push	hl
	ld	hl,RAM_SORT+#03
	ld	a,(hl)
	ld	(CardMDR+#0F),a	; show RAM instead of flash for directory
	pop	hl

TA_07:
	exx
	ld	d,0
	exx

; Set screen for menu
Menu1:
	ld	a,C2FCOLM
	ld	hl,#1701
	call	PALETTE
	ld	a,C2BCOLM
	ld	hl,#1701
	call	PALETTE
	ld	a,C2FCOLM
	ld	(FORCLR),a
	ld	a,C2BCOLM
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors (foreground=background)
	push	de
	ld	de,#1701
	ld	hl,#7707
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#0000
	ld	hl,#1701
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeOut		; fade out background
  if CV=2
	ld	hl,(C2BPALM)
	ex	de,hl
  else
	ld	de,#1304
  endif
	ld	hl,#0000
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeIn		; fade in background
	pop	de
	ld	a,C2FCOLM
  if CV=2
	ld	hl,(C2BPALM)
  else
	ld	hl,#1304
  endif
	call	PALETTE

Pagep:	
	ld	a,(VDPVER)	; detect if 9938 or later used, don't disable the screen
	or	a
	jr	nz,Pagep0
	call	DISDISP		; disable display

Pagep0:
	ld	a,C2FCOLM
	ld	(FORCLR),a
	ld	a,C2BCOLM
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors (foreground=background)

	call	CLS
	ld	hl,#0101
	call    POSIT

  if SPC=1
	ld	a,#20
	ld	(#F3B1),a
	ld	hl,MainScr	; print main screen messages
	call	print	
	ld	a,#18
	ld	(#F3B1),a
  else
	ld	hl,MainScr	; print main screen messages
	call	print	
  endif

	call	PrintInf	; print page number
	call	PrintFrq	; print frequency of the display (50/60)
	call	PrintVol	; print volumes
        call    PrintTur        ; print turbo/r800/z80 mode

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
	ld	a,d
	or	a
	jp	z,sPr0		; done, last record
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
	call	hexout		; print entry number in hex
  if SPC=1
	ld	a,' '
	call	CHPUT		; print space
  endif

; set hl-point
	push 	ix
	pop	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl

; mapper symbols
  if SPC=0
	ld	a,(hl)
	cp	'K'
	jr	nz,sMap1
	ld	a,#B8
	call	CHPUT		; output Konami5 mapper symbol
	ld	a,#BE
	jr	sCur
sMap1:
	cp	'k'
	jr	nz,sMap2
	ld	a,#B8
	call	CHPUT		; output Konami4 mapper symbol
	ld	a,#B3
	jr	sCur
sMap2:
	cp	'A'
	jr	nz,sMap3
	ld	a,#B4
	call	CHPUT		; output ASCII16 mapper symbol
	ld	a,#BA
	jr	sCur
sMap3:
	cp	'a'
	jr	nz,sMap4
	ld	a,#BB
	call	CHPUT		; output ASCII8 mapper symbol
	ld	a,#B9
	jr	sCur
sMap4:
	cp	'C'
	jr	nz,sMap5
	ld	a,#BC
	call	CHPUT		; output configuration symbol
	ld	a,#BD
	jr	sCur
sMap5:
	cp	'U'
	jr	nz,sMap6
	ld	a,#BF
	call	CHPUT		; output unknown mapper symbol
	ld	a,#B7
	jr	sCur
sMap6:
	cp	'M'
	jr	nz,sMap7
	ld	a,#B5
	call	CHPUT		; output multirom mapper symbol
	ld	a,#B6
	jr	sCur
sMap7:
	ld	a,#B1
	call	CHPUT		; output unknown entry symbol
	ld	a,#B2
  else
	ld	a,(hl)
	cp	'K'
	jr	z,sCur
	cp	'k'
	jr	z,sCur
	cp	'A'
	jr	z,sCur
	cp	'a'
	jr	z,sCur
	cp	'C'
	jr	z,sCur
	cp	'U'
	jr	z,sCur
	cp	'M'
	jr	z,sCur
	ld	a,'-'
  endif

sCur:
	call	CHPUT
	inc	hl

; clear cursor area
	ld	a,' '
	call	CHPUT		; output space for cursor
	ld	a,' '
	call	CHPUT		; output space for cursor

; print record name
	ld	b,30
sPr:	ld	a,(hl)
	call	CHPUT		; output record name
	inc	hl
	djnz	sPr

	inc	d
	ld	a,d
	or	a
	jr	nz,sPr1		; last found dir entry?
sPr0:
	call	PrintER		; print empty record
	inc	e
	ld	a,e		; last string on the page?
	cp	L_STR
	jr	c,sPr0
	jr	dRec
sPr1:
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

	push	af
	ld	a,(SKIPFD)
	or	a		; skip fade on page flip?
	jr	nz,dRec1

	push	de
	ld	hl,(C2FPALM)
	ex	de,hl
  if CV=2
	ld	hl,(C2BPALM)
  else
	ld	hl,#1304
  endif
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeIn		; fade in text
	pop	de

dRec1:
	xor	a
	ld	(SKIPFD),a	; skip fade disabled
	pop	af

; set cursor pos on first entry
CH00:
	call	c_dir
	ld	h,7
	ld	a,e
	add	a,7
	ld	l,a
	ld	(XYPOS),hl
	call	POSIT
	ld	a,CURS1		; print cursor symbol 1
	call	CHPUT
	ld	a,CURS2		; print cursor symbol 2
	call	CHPUT
	ld	hl,#2705
	call	POSIT		; move cursor to edge of screen

CH01:
	call	ENADISP		; enable display

	ld	bc,#0000	; no autostart - effects enabled
	call	KILBUF

Wait0:
	call	CHSNS		; wait for key and avoid displaying cursor
	jr	nz,GetKey

	xor	a
	call	GTTRIGG	 	; space/built-in buttons
	or	a
	jp	nz,RUN_CT
	ld	a,1
	call	GTTRIGG		; joystick 1 button A
	or	a
	jp	nz,RUN_CT
	ld	a,2
	call	GTTRIGG		; joystick 2 button A
	or	a
	jp	nz,RUN_CT
	ld	a,3
	call	GTTRIGG		; joystick 1 button B
	or	a
	jp	nz,RUN_CR
	ld	a,4
	call	GTTRIGG		; joystick 2 button B
	or	a
	jp	nz,RUN_CR

	xor	a
	push	de
	call	GTSTCK		; joystick direction = cursors
	pop	de
	or	a
	jr	nz,GetJD
	ld	a,1
	push	de
	call	GTSTCK		; joystick direction = port 1
	pop	de
	or	a
	jr	nz,GetJD
	ld	a,2
	push	de
	call	GTSTCK		; joystick direction = port 2
	pop	de
	or	a
	jr	z,Wait0

GetJD:
	call	JoyDelay	; delay for joystick

	cp	1		; up
	jp	z,C_UP
	cp	5		; down
	jp	z,C_DOWN
	cp	3		; right
	jp	z,P_F
	cp	7		; left
	jp	z,P_B
	jp	Wait0

GetKey:
	call	CHGET
	cp	27		; ESC
	jp	z,Exit
	cp	30		; UP
	jp	z,C_UP
	cp	31		; DOWN
	jp	z,C_DOWN
	cp	29		; LEFT
	jp	z,P_B
	cp	28		; RIGHT
	jp	z,P_F
	cp	32		; SPACE
	jp	z,RUN_CT	; run selected record
	cp	13		; ENTER
	jp	z,RUN_CT	; run selected record
	cp	"R"
	jp	z,RUN_CR	; run after reset
	cp	"r"
	jp	z,RUN_CR	; run after reset
	cp	"G"
	jp	z,RUN_CJ	; run directly
	cp	"g"
	jp	z,RUN_CJ	; run directly
	cp	"A"
	jp	z,AUTO_R	; set selected record for autorun
	cp	"a"
	jp	z,AUTO_R	; set selected record for autorun
	cp	"D"
	jp	z,DAUTO_R	; disable autorun record
	cp	"d"
	jp	z,DAUTO_R	; disable autorun record
	cp	"?"
	jp	z,Help		; show help
	cp	"h"
	jp	z,Help		; show help
	cp	"H"
	jp	z,Help		; show help
   if CV=2
	cp	"V"
	jp	z,SetVolume	; set volume
	cp	"v"
	jp	z,SetVolume	; set volume
	cp	"F"
	jp	z,ChangeFreq	; change frequency
	cp	"f"
	jp	z,ChangeFreq	; change frequency
	cp	"P"
	jp	z,PSGVolume	; set PSG volume
	cp	"p"
	jp	z,PSGVolume	; set PSG volume
        cp      "T"
        jp      z,TurboMode	; toggle Turbo modes
        cp      "t"
        jp      z,TurboMode	; toggle Turbo modes
        cp      "S"
        jp      z,UISetup	; UI setup
        cp      "s"
        jp      z,UISetup	; UI setup
   endif
	jp	CH01


; Cursor up (previous str select)
C_UP:
	ld	a,e
	or	a
	jp	z,CH01		; 1-st string?
	ld	hl,(XYPOS)
	call	POSIT
	ld	a,' '
	call	CHPUT		; clear cursor
	ld	a,' '
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
	ld	hl,(XYPOS)
	call	POSIT
	ld	a,' '	
	call	CHPUT		; clear cursor
	ld	a,' '
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

	ld	a,(EFF)
	or	a		; effects enabled?
	jr	z,PF00

	push	de
	ld	hl,(C2FPALM)
  if CV=2
	push	hl
	ld	hl,(C2BPALM)
	ex	de,hl
	pop	hl
  else
	ld	de,#1304
  endif
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text
	pop	de

PF00:
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

	ld	a,(EFF)
	or	a		; effects enabled?
	jp	nz,Pagep
	ld	a,#FF
	ld	(SKIPFD),a	; skip fade enabled
	call	PrintInf	; print page number
	jp	Pagep1


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

	ld	a,(EFF)
	or	a		; effects enabled?
	jr	z,PB00

	push	de
	ld	hl,(C2FPALM)
  if CV=2
	push	hl
	ld	hl,(C2BPALM)
	ex	de,hl
	pop	hl
  else
	ld	de,#1304
  endif
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text
	pop	de

PB00:
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

	ld	a,(EFF)
	or	a		; effects enabled?
	jp	nz,Pagep
	ld	a,#FF
	ld	(SKIPFD),a	; skip fade enabled
	call	PrintInf	; print page number
	jp	Pagep1

PB02:	ld	d,0
	ld	hl,CURPAG
	ld	a,1
	ld	(hl),a
	jp	PB03


; Run selected record
RUN_CT:
; Start and autostart
; ix - directory entry pointer

	ld	a,(ix+#3E)
	bit	0,a
	jp	nz,RUN_CR
	bit	1,a
	jp	nz,RUN_CJ

	ld	a,(AUTOST)	; autostart found?
	cp	#FF
	jr	z,RUN_CT2	; skip effects

RUN_CT1:
	ld	hl,(C2FPALM)
  if CV=2
	push	hl
	ld	hl,(C2BPALM)
	ex	de,hl
	pop	hl
  else
	ld	de,#1304
  endif
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#0000
  if CV=2
	ld	hl,(C2BPALM)
  else
	ld	hl,#1304
  endif
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeOut		; fade out background

	call	RestEnv		; restore environment (font, colors, screen)

RUN_CT2:
	ld	a,%00101100
	ld	(CardMDR),a
	ld	a,(ix+#02)
	ld	(CardMDR+#05),a	; set start block
	push	ix
	pop	hl
	ld	bc,#23
	add	hl,bc		; config data
	ld	de,CardMDR+#06
	ld	bc,26
	ldir

	ld	hl,RJP
	ld	de,R_Base
	ld	bc,RJPE-RJP
	ldir

	ld	a,#C9
	ld	(R_Base+3),a
	jp	R_Base
              

; Run selected record via reset
RUN_CR:
	ld	a,(AUTOST)	; autostart found?
	cp	#FF
	jr	z,RUN_CR2	; skip effects

; Effects
RUN_CR1:
	ld	hl,(C2FPALM)
  if CV=2
	push	hl
	ld	hl,(C2BPALM)
	ex	de,hl
	pop	hl
  else
	ld	de,#1304
  endif
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#0000
  if CV=2
	ld	hl,(C2BPALM)
  else
	ld	hl,#1304
  endif

	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeOut		; fade out background

	call	RestEnv		; restore environment (font, colors, screen)

; Configure cart register and restart
; ix - directory entry pointer
RUN_CR2:
  if CV=2
	ld	a,(VDPVER)
	or	a
	jp	z,RUN_CR22	; no frequency switch for v9918 and v9928, just reset

	ld	a,(ix+#04)	; entry type
	or	%00100000
	cp	'c'       
	jp	z,RUN_CR22	; skip pre-started code

	ld	a,(ORGVR10)	; original value of VDP frequency
	ld	b,a
	ld	a,(PALNTSC)	; read current VDP frequency
	cp	b
	jp	nz,MakePCode
	ld	a,(TURBOM)	; Turbo/R800 mode enabled?
	or	a
	jp	z,RUN_CR22	; skip pre-started code

MakePCode:
	ld	a,#20
	ld	(CardMDR),a	; set immediate configuration change flag, registers at #4F80

	ld	a,(ix+#02)	; start block for rom
	ld	(CardMDR+#03),a	; set AddrM2 address

	ld	a,(ix+#3D)	; size and position in block
	ld	b,a
	and	%00001000
	or	a		; 48kb ROM?
	jr	z,ChkRomS
	ld	a,#40
	ld	(CardMDR+#02),a	; offset in block AddrM1 for 48kb ROM
	jr	SetOffs1

ChkRomS:
	ld	a,b
	and	%01110000
	or	a		; no offset in block?
	jr	z,SetOffs
	ld	a,b
	and	%00000111
	or	a		; not mini-ROM?
	jr	z,SetOffs

	ld	a,b
	and	%01110000
	rrca
	rrca
	rrca
	rrca
	ld	c,a		; c = offset counter
	ld	a,b
	and	%00000111
	ld	d,#10
	cp	%00000011	; 4kb?
	jr	z,FindOffs
	ld	d,#20
	cp	%00000100	; 8kb?
	jr	z,FindOffs
	ld	d,#40
	cp	%00000101	; 16kb?
	jr	z,FindOffs
	ld	d,#80

FindOffs:
	ld	b,c
	ld	a,d
	xor	a
FindOffC:
	add	d
	djnz	FindOffC

	ld	(CardMDR+#02),a	; offset in block AddrM1
	jr	SetOffs1

SetOffs:
	xor	a
	ld	(CardMDR+#02),a	; offset in block AddrM1
SetOffs1:
	xor	a		; start from offset 0000 in block
	ld	hl,#C100	; address in RAM
	ld	b,10
	ld	c,a
RCopy:
	ld	a,c
	ld	(CardMDR+#01),a	
	ld	a,(CardMDR+#04)
	ld	(hl),a		; copy 10 bytes from ROM's start ("AB",Init,Statement,Device,Text vectors)
	inc 	hl
	inc	c
	djnz	RCopy

	ld	a,(ix+#3C)
	ld	(#C200),a	; save CardMDR register for ROM
	ld	a,(ix+#3D)
	ld	(#C201),a	; same rom's position and size in block
	ld	a,(ix+#02)
	cp	4		; non-user block?
	jr	nc,RCopy1
	xor	a
RCopy1:
	ld	(#C202),a	; save start block of ROM in the flash chip
	ld	a,(ix+#3E)
	ld	(#C203),a	; same rom's start method
	ld	a,(ix+#04)
	ld	(#C204),a 	; save entry/mapper type

	ld	de,#C300
	jr	RUN_CR23
  endif

RUN_CR22:
	ld	a,%00101000
	ld	(CardMDR),a	; set delayed configuration triggered by JP #0000
	ld	de,CardMDR+#06

	ld	a,(ix+#02)	; start block
	ld	(CardMDR+#05),a	; set start block

RUN_CR23:
	push	ix
	pop	hl
	ld	bc,#23
	add	hl,bc		; config data for registers
	ld	bc,25
	ldir
	ld	a,(hl)
	and	%11111011
	ld	(de),a		; set reconfig after JP #0000

; Disable "warm" start
RUN_CR4:
	in	a,(#F4)		; read from F4 port on MSX2+
	or	#80
	out	(#F4),a		; avoid "warm" reset on MSX2+

Reset:
	call	CLS
	ld	hl,ResetCMSG	; print rebooting message

	ld	a,(ix+#04)	; entry type
	or	%00100000
	cp	'c'       
	jp	z,Reset1	; configuration entry?

	ld	hl,ResetMSG	; print rebooting message with configuration

Reset1:
	call	print

  if CV=2
	ld	a,(VDPVER)
	or	a
	jp	z,#0000		; just reset if no need to set frequency after reboot

	ld	a,(ix+#04)	; entry type
	or	%00100000
	cp	'c'       
	jp	z,#0000		; just reset if no need to set frequency after reboot

	ld	a,(ORGVR10)	; original value of VDP frequency
	ld	b,a
	ld	a,(PALNTSC)	; read current VDP frequency
	cp	b
	jp	nz,Reset2
	ld	a,(TURBOM)	; Turbo/R800 mode enabled?
	or	a
	jp	z,#0000		; just reset if no need to set Turbo/R800 after reboot

Reset2:
	ld	a,#08
	ld	(CardMDR+#0F),a	; disable second bank
	ld	(CardMDR+#15),a	; disable third bank

	xor	a
	ld	(CardMDR+#05),a	; set start block for RAM

	ld	de,CardMDR+#18
	ld	hl,RAM_TS4B
	ld	bc,6
	ldir			; set forth bank to map RAM at #0000:#8000

	ld	a,%00101000
	ld	(CardMDR),a	; set delayed configuration triggered by JP #0000

	ld	hl,#C100
	ld	de,#8000
	ld	bc,10
	ldir			; copy ROM reader to pre-loader space
	xor	a
	ld	b,6
hdfill:
	ld	(de),a		; fill with zeroes
	inc	de
	djnz	hdfill

	ld	hl,#8000
	ld	a,"A"
	ld	(hl),a
	inc	a
	inc	hl
	ld	(hl),a		; form 'AB' header
	inc	hl
	ld	a,#10
	ld	(hl),a
	ld	a,#40		; set start base for pre-start code
	inc	hl
	ld	(hl),a		; set pre-start code's start address (#4010)

	ld	hl,PRE_ROM	; transder pre-start code
	ld	de,#8010
	ld	bc,PRE_ROME-PRE_ROM
	ldir			; copy the pre-start code

	ld	a,(PALNTSC)
	ld	(#8F00),a	; save frequency setting
	ld	a,(#C200)
	ld	(#8F01),a	; save CardMDR register for ROM
	ld	a,(#C201)
	ld	(#8F1C),a	; save rom's position and size in block
	ld	a,(#C202)
	ld	(#8F1D),a	; save start block of ROM in the flash chip
	ld	a,(#C203)
	ld	(#8F1E),a	; same rom's start method
	ld	a,(#C204)
	ld	(#8F1F),a 	; save entry/mapper type

	ld	hl,#C300
	ld	de,#8F02
	ld	bc,26
	ldir			; copy all registers to pre-loader

	ld	hl,#C102
	ld	de,#8F20
	ld	bc,2
	ldir			; copy rom's start address to preloader

	ld	a,(TURBOM)
	ld	(#8F22),a	; save turbo mode status
	ld	a,(MSXTYPE)
	ld	(#8F23),a	; save MSX type
	in	a,(#A8)
	and	%00001100
	rrca
	rrca
	ld	(#8F24),a	; save cartridge's slot number

	ld	de,CardMDR+#18
	ld	hl,RAM_TS4BR
	ld	bc,6
	ldir			; set forth bank to map empty RAM at #0000:#4000

	ld	a,(#8F1A)
	ld	(CardMDR+#1E),a	; rom's configuration register for reboot

	ld	a,#08
	ld	(CardMDR+#09),a	; disable first bank
  endif

	jp	#0000		; reset to apply changed configuration!


; Run selected record directly (using the ROM's start adddress
RUN_CJ:
	ld	a,(AUTOST)	; autostart found?
	cp	#FF
	jr	z,RUN_CJ2	; skip effects

RUN_CJ1:
	ld	a,(ix+#04)	; mapper type
	cp	'C'
	jp	z,CH01		; ignore direct start for configuration entries
	cp	'c'
	jp	z,CH01		; ignore direct start for configuration entries

	ld	hl,(C2FPALM)
  if CV=2
	push	hl
	ld	hl,(C2BPALM)
	ex	de,hl
	pop	hl
  else
	ld	de,#1304
  endif
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#0000
  if CV=2
	ld	hl,(C2BPALM)
  else
	ld	hl,#1304
  endif
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeOut		; fade out background

	call	RestEnv		; restore environment (font, colors, screen)


; Configure cart register and start ROM
; ix - directory entry pointer
RUN_CJ2:
	ld	a,%00101100
	ld	(CardMDR),a
	ld	a,(ix+#02)
	ld	(CardMDR+#05),a	; set start block
	push	ix
	pop	hl
	ld	bc,#23
	add	hl,bc		; config data
	ld	de,CardMDR+#06
	ld	bc,26
	ldir

	ld	hl,RJP
	ld	de,R_Base
	ld	bc,RJPE-RJP
	ldir

	ld	a,(ix+#3E)	; jump and reset options
	bit	0,a
	jr	z,RUN_CJ3
	xor	a		; start address from #0002
	ld	(R_Base+8),a
	jp	R_Base

RUN_CJ3:
	bit	2,a		; start address from #4000?
	jp	z,R_Base
	ld	a,#80		; start address from #8002
	ld	(R_Base+8),a
	jp	R_Base

RJP:
	ld	a,(#4000)
	nop
	nop	; wait for cartridge to enable the config
	nop
	ld	hl,(#4002)
	jp	(hl)
RJPE:	nop

;	ld	a,(ix+#3E)
;	bit	2,a
;	jp	z,R_Base
;	ld	a,#80
;	ld	(R_Base+5),a
;	jp	R_Base
;
;RJP:
;	ld	a,(#4000)
;	ld	hl,(#4002)
;	jp	(hl)
;RJPE:	nop


; Disable autostart
DAUTO_R:
	ld	a,2
	ld	(CardMDR+#0E),a	; set 2nd bank to autostart map
	ld	a,(SORT)
	or	a
	jr	z,DSA_00
	ld	hl,B2ON+#03
	ld	a,(hl)
	ld	(CardMDR+#0F),a	; show flash instead of RAM for autostart

DSA_00:
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
	ld	a,(SORT)
	or	a
	jr	z,ATR_000
	ld	hl,B2ON+#03
	ld	a,(hl)
	ld	(CardMDR+#0F),a	; show flash instead of RAM for autostart

ATR_000:
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
ATR_04:
	exx
	ld	c,a
	exx
	ld	a,1
	ld	(CardMDR+#0E),a	; set 2nd bank to directory map
	ld	a,(SORT)
	or	a
	jr	z,ATR_06
	ld	hl,RAM_SORT+#03
	ld	a,(hl)
	ld	(CardMDR+#0F),a	; show RAM instead of flash for directory

ATR_06:
; print new autostart record number
	ld	hl,35*256+05	; #23 position
	call	POSIT
	exx
	ld	a,c
	exx
	cp	#FF
	jr	nz,ATR_03

	ld	hl,Spaces	; clear autostart record area
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
	ld	a,(VDPVER)	; detect if 9938 or later used, don't disable the screen
	or	a
	jr	nz,Help1
	call	DISDISP		; disable display

Help1:
  if CV=2
	ld	hl,(C2BPALM)
	ex	de,hl
  else
	ld	de,#1304
  endif
	ld	hl,(C2FPALM)
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#0000
  if CV=2
	ld	hl,(C2BPALM)
  else
	ld	hl,#1304
  endif
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeOut		; fade out background

	ld	a,C2BCOLH
	ld	hl,#0000
	call	PALETTE
	ld	a,C2FCOLH
	ld	(FORCLR),a
	ld	a,C2BCOLH
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors (foreground=background)

	ld	a,C2FCOLH
	ld	hl,(C2BPALH)
	call	PALETTE

	ld	hl,(C2BPALH)
	ex	de,hl
	ld	hl,#0000
	ld	b,C2BCOLH
	ld	c,#0D
	call	FadeIn		; fade in background

  if SPC=1
	ld	a,#20
	ld	(#F3B1),a
	ld	hl,HelpScr1	; print help screen
	call	print	
	ld	a,#18
	ld	(#F3B1),a
  else
	ld	hl,HelpScr1	; print help screen
	call	print
  endif

  if SPC=1
	ld	hl,#0118
	call    POSIT
	ld	hl,helpll
	call	print		; print additional line
  endif

	ld	hl,#0218
	call    POSIT
	ld	hl,Vers
	call	print		; print boot block version

	ld	hl,(C2FPALH)
	ex	de,hl
	ld	hl,(C2BPALH)
	ld	b,C2FCOLH
	ld	c,#0D
	call	FadeIn		; fade in text

	call	ENADISP		; enable display

	call	KILBUF

Wait1:
	call	CHSNS		; wait for key and avoid displaying cursor
	jr	z,Wait1

	call	CHGET		; wait for a key

	ld	hl,(C2BPALH)
	ex	de,hl
	ld	hl,(C2FPALH)
	ld	b,C2FCOLH
	ld	c,#0D
	call	FadeOut		; fade out text

	ld	a,(VDPVER)	; detect if 9938 or later used, don't disable the screen
	or	a
	jr	nz,Help2
	call	DISDISP		; disable display

Help2:
	call	CLS

  if SPC=1
	ld	a,#20
	ld	(#F3B1),a
	ld	hl,HelpScr2	; print help screen
	call	print	
	ld	a,#18
	ld	(#F3B1),a
  else
	ld	hl,HelpScr2	; print help screen
	call	print
  endif

  if SPC=1
	ld	hl,#0118
	call    POSIT
	ld	hl,helplll
	call	print		; print additional line
  endif

	ld	hl,#0218
	call    POSIT
	ld	hl,Vers
	call	print		; print boot block version

	ld	hl,(C2FPALH)
	ex	de,hl
	ld	hl,(C2BPALH)
	ld	b,C2FCOLH
	ld	c,#0D
	call	FadeIn		; fade in text

	call	ENADISP		; enable display

	call	KILBUF

Wait11:
	call	CHSNS		; wait for key and avoid displaying cursor
	jr	z,Wait11

	call	CHGET		; wait for a key

	ld	hl,(C2BPALH)
	ex	de,hl
	ld	hl,(C2FPALH)
	ld	b,C2FCOLH
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#0000
	ld	hl,(C2BPALH)
	ld	b,C2BCOLH
	ld	c,#0D
	call	FadeOut		; fade out background

  if CV=2
	ld	hl,(C2BPALM)
	ex	de,hl
  else
	ld	de,#1304
  endif
	ld	hl,#0000
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeIn		; fade in background

	ld	a,C2FCOLM
  if CV=2
	ld	hl,(C2BPALM)
  else
	ld	hl,#1304
  endif
	call	PALETTE

	jp	Pagep


; Exit from boot block
Exit:
  if CV=2
	ld	hl,(C2BPALM)
	ex	de,hl
  else
	ld	de,#1304
  endif
	ld	hl,(C2FPALM)
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#0000
  if CV=2
	ld	hl,(C2BPALM)
  else
	ld	hl,#1304
  endif
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeOut		; fade out background

	call	RestEnv		; restore environment (font, colors, screen)

	ret


; Fade-in effect
; In: de (target palette)
; In: hl (current palette)
; In: bc (foreground/background colors)
FadeIn:
	ld	a,(EFF)
	or	a
	jr	nz,FadeL
	ld	a,b
	push	de
	pop	hl
	call	PALETTE		; set target palette without fade effect
	ret
FadeL:
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
	jr	c,FadeL0a
	dec	l
	jr	FadeL1
FadeL0a:
	inc	l
FadeL1:
	ld	a,h
	and	#0F
	push	de
	push	af
	ld	a,d
	and	#0F
	ld	d,a
	pop	af
	cp	d
	jr	z,FadeL2
	jr	c,FadeL1a
	dec	h
	jr	FadeL2
FadeL1a:
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
	jr	c,FadeL2a
	ld	a,h
	sub	#10
	ld	h,a
	jr	FadeL3
FadeL2a:
	ld	a,h
	add	#10
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
	ld	a,(EFF)
	or	a
	jr	nz,FadeLS
	ld	a,b
	push	de
	pop	hl
	call	PALETTE		; set target palette without fade effect
	ret
FadeLS:
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
	jr	c,FadeL4a
	dec	l
	jr	FadeL5
FadeL4a:
	inc	l
FadeL5:
	ld	a,h
	and	#0F
	push	de
	push	af
	ld	a,d
	and	#0F
	ld	d,a
	pop	af
	cp	d
	jr	z,FadeL6
	jr	c,FadeL5a
	dec	h
	jr	FadeL6
FadeL5a:
	inc	h
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
	jr	c,FadeL6a
	ld	a,h
	sub	#10
	ld	h,a
	jr	FadeL7
FadeL6a:
	ld	a,h
	add	#10
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


; Restore palette, font address and colors
RestEnv:
	push	af
	push	hl
	push	de
	push	bc

	ld	a,(BSLT)
        ld	(CHSETS),a	; restore bios font's slot
	ld	hl,(BFNT)
	ld	(CHSETA),hl	; restore bios font's address

	ld	a,C2FCOLM
	ld	hl,#0000
	call	PALETTE
	ld	a,C2BCOLM
	ld	hl,#0000
	call	PALETTE

	ld	a,DefFCol
	ld	hl,#0000
	call	PALETTE
	ld	a,DefBCol
	ld	hl,#0000
	call	PALETTE

	ld	a,DefFCol
	ld	(FORCLR),a
	ld	a,DefBCol
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors (foreground=background)

	ld	de,DefBlP
	ld	hl,#0000
	ld	b,DefBCol
	ld	c,#0D
	call	FadeIn		; fade in background

	xor	a
  	ld	hl,DefPal
RestPal:
	push	af
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	push	hl
	push	de
	pop	hl
	call	PALETTE		; restore default palette
	pop	hl
	pop	af
	inc	a
	cp	16
	jr	nz,RestPal

	ld	a,1
	ld	(KEYCLK),a	; enable click on keypress
	xor	a
	call	SSCREEN
	call	MODE40A
	call	CLS

	pop	bc
	pop	de
	pop	hl
	pop	af
	ret


; Set new font address and screen
SetEnv:	push	af
	push	hl
	push	de
	push	bc

	ld	a,(CHSETS)
	ld	(BSLT),a	; save bios font's slot
	ld	hl,(CHSETA)
	ld	(BFNT),hl	; save bios font's address
	call	SltDet

	ld	(CHSETS),a
	ld	hl,fontdat+2
	ld	(CHSETA),hl	; set new font address
	ld	a,40
	ld	(SCR0WID),a	; set default width of screen0

	xor	a
	ld	(KEYCLK),a	; disable click on keypress
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
	push	af
	ld	a,(VDPVER)	; detect if 9918 is used, skip pallette operations then
	or	a
	jr	z,PALEND
	di
	pop	af
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
	push	af
PALEND:
	ei
	pop	af
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
	add	ix,bc		; 8000h + b*64

	ld	a,(ix)
	cp	#FF		; last record?
	ret	z

	ld	a,(ix+1)
	or	a		; deleted/empty record?
	ret


  if CV=2
; Read 1 byte from EEPROM
; input A - address
; outut A - data
EERD:
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
; opcode "10"
	ld	a,%00001010
	ld	(hl),a
	ld	a,%00001110
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
EERDa1:
	ld	a,c
	and	%00001010
	or	%00001000
	ld	(hl),a
	or	%00001100
	ld	(hl),a
	rlc	c
	djnz	EERDa1
; 
	ld	a,%00001000
	ld	(hl),a
	ld	a,%00001100
	ld	(hl),a
; Read Data D7-D0
	ld	c,0
	ld	b,8
EERDd1:
	rlc	c
	ld	a,(hl)
	and	%00000001
	or	c
	ld	c,a
	ld	a,%00001000
	ld	(hl),a
	ld	a,%00001100
	ld	(hl),a
 	djnz	EERDd1
; and read data
	ld	a,%00001000
	ld	(hl),a
	ld	a,%00000000
	ld	(hl),a
; return data A	
	ld	a,c
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
  endif


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


; Sort directory
DirSort:
	ld	a,(SORT)
	or	a
	ret	z

	ld	a,#20
	ld	(CardMDR),a	; set immediate configuration change flag, registers at #4F80

	ld	hl,B2ON1
	ld	de,CardMDR+#0C	; set Bank2 to 8kb
	ld	bc,6
	ldir
	ld	de,CardMDR+#12
	ld	hl,RAM_SORT1
	ld	bc,6
	ldir			; set 8kb RAM at #A000

	di
	ld	hl,#8000
	ld	de,#A000
	ld	bc,#2000
	ldir			; copy directory
	ei

	ld	a,(CardMDR+#0E)
	inc	a
	ld	(CardMDR+#0E),a	; next directory page
	ld	de,CardMDR+#12
	ld	hl,RAM_SORT2
	ld	bc,6
	ldir			; set next 8kb RAM at #A000

	di
	ld	hl,#8000
	ld	de,#A000
	ld	bc,#2000
	ldir			; copy directory (2nd part)
	ei

	ld	de,CardMDR+#0C
	ld	hl,RAM_SORT   
	ld	bc,6
	ldir			; set second bank to map 16kb of RAM with directory at #8000

	xor	a
	ld	(CardMDR+#15),a	; disable third bank

; Sort directory
	di
	ld	hl,DIRCNT	; read directory count
	ld	a,(hl)
	dec	a		; exclude first entry
	or	a
	ret	z
	cp	1
	ret	z	

	ld	a,#ff		; max dir number
	ld	b,a		; number of sort attempts
	ld	c,a

DSortL1:
	ld	ix,#8040
	ld	iy,#8080
DSortL2:
	ld	a,(ix+5)
	cp	(iy+5)		; sort using 1st character in name
	jr	nz,DSortL3
	cp	#ff		; skip cycle if no data found
	jr	z,DSortE1
	ld	a,(ix+6)
	cp	(iy+6)		; sort using 2nd character in name
	jr	nz,DSortL3
	ld	a,(ix+7)
	cp	(iy+7)		; sort using 3rd character in name
	jr	nz,DSortL3
	ld	a,(ix+8)
	cp	(iy+8)		; sort using 4th character in name
	jr	nz,DSortL3
	ld	a,(ix+9)
	cp	(iy+9)		; sort using 5th character in name
	jr	z,DSortE

DSortL3:
	jr	c,DSortE
	push	bc
	push	ix
	pop	hl
	ld	de,SORTBUF
	ld	bc,#40
	ldir
	push	iy	
	pop	hl
	ld	de,ix
	ld	bc,#40
	ldir
	ld	hl,SORTBUF
	ld	de,iy
	ld	bc,#40
	ldir
	pop	bc

DSortE:
	ld	de,#40
	add	ix,de		; next entry
	add	iy,de		; next entry
	ld	a,#c0
	cp	iyh		; limit reached?
	jr	z,DSortE1
	djnz	DSortL2		; sort N*N times
DSortE1:
	ld	b,c
	dec	c
	djnz	DSortL1		; sort N times
	ei
	ret


; Print Turbo/R800 indicator
PrintTur:
	push	hl
	push	de
	push	bc

	ld	hl,#0818
	call    POSIT
	ld	a,(TURBOM)
	or	a
	jr	nz,PrintT1

PrintT0:
	ld	hl,DefMode
	jr	PrintTE

PrintT1:
	ld	a,(CHGCPU)
	cp	#C3		; Turbo-R machine?
	jr	z,PrintT2
	ld	a,(RDBTST)
	cp	#C3		; MSX2+ machine?
	jr	nz,PrintT0
	ld	a,8
	out	(#40),a		; prepare to get vendor ID
	nop
	in	a,(#40)		; get vendor ID
	cpl
	cp	8		; Panasonic machine?
	jr	nz,PrintT0
	ld	hl,T2PMode
	jr	PrintTE

PrintT2:
	ld	hl,RTRMode

PrintTE:
	call	print
	pop	bc
	pop	de
	pop	hl
	ret


PrintER:
	push	de
	ld	h,3
	ld	a,e
	add	a,7
	ld	l,a
	call	POSIT
	ld	b,36
PrintERC:
	ld	a,' '
	call	CHPUT		; output empty record
	djnz	PrintERC
	pop	de
	ret


;
; EXTRA CODE AND DATA AREA
; The extra code and data area must start above the control registers (#4F80-#4FFF)!
;	

	org	#5000


; Print page number and max pages
PrintInf:
	push	hl
	push	de
	push	bc

	ld	hl,#2118
	call    POSIT
	ld	hl,PageNum	; print page number string
	call	print	

	ld	hl,#2218
	call    POSIT
	ld	hl,CURPAG
	ld	a,(hl)
	call	hexout		; print current directory page

	ld	hl,#2518
	call    POSIT
	ld	hl,DIRPAG
	ld	a,(hl)
	call	hexout		; print max directory pages

	pop	bc
	pop	de
	pop	hl
	ret


; Print current frequency display
  if CV=2
PrintFrq:
	push	hl
	push	de
	push	bc
	ld	hl,#218
	call    POSIT
	ld	hl,PALmsg	; print PAL
	ld	a,(PALNTSC)
	bit	1,a
	jr	nz,PrintHZ
	ld	hl,NTSCmsg	; print NTSC
PrintHZ:
	call	print		; print current mode
	pop	bc
	pop	de
	pop	hl
	ret
  endif


; Print current volumes
  if CV=2
PrintVol:
	push	hl
	push	de
	push	bc

	ld	hl,#0D18
	call    POSIT
	ld	hl,VolumeL	; print volume
	call	print

	ld	hl,#1218
	call    POSIT
	ld	a,(CardMDR+#22)
	rra
	rra
	rra
	and	7
	inc	a
	add	#30
	call	CHPUT		; print fmpac volume

	ld	hl,#1818
	call    POSIT
	ld	a,(CardMDR+#22)
	and	7
	inc	a
	add	#30
	call	CHPUT		; print scc volume

	ld	hl,#1E18
	call    POSIT
	ld	a,(CardMDR+#24)
	rra
	rra
	rra
	and	7
	inc	a
	add	#30
	call	CHPUT		; print PSG volume

	pop	bc
	pop	de
	pop	hl
	ret
  endif


; UI setup screen
UISetup:
	ld	a,(VDPVER)	; detect if 9938 or later used, don't disable the screen
	or	a
	jr	nz,UISetup1
	call	DISDISP		; disable display

UISetup1:
  if CV=2
	ld	hl,(C2BPALM)
	ex	de,hl
  else
	ld	de,#1304
  endif
	ld	hl,(C2FPALM)
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text

UISetup2:
	call	CLS

	ld	de,#0000
  if CV=2
	ld	hl,(C2BPALM)
  else
	ld	hl,#1304
  endif
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeOut		; fade out background

	ld	a,C2BCOLS
	ld	hl,#0000
	call	PALETTE
	ld	a,C2FCOLS
	ld	(FORCLR),a
	ld	a,C2BCOLS
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors (foreground=background)

	ld	a,C2FCOLS
	ld	hl,(C2BPALS)
	call	PALETTE

	ld	hl,(C2BPALS)
	ex	de,hl
	ld	hl,#0000
	ld	b,C2BCOLS
	ld	c,#0D
	call	FadeIn		; fade in background

  if SPC=1
	ld	a,#20
	ld	(#F3B1),a
	ld	hl,SetupScr	; print setup screen
	call	print	
	ld	a,#18
	ld	(#F3B1),a
  else
	ld	hl,SetupScr	; print setup screen
	call	print
  endif

  if SPC=1
	ld	hl,#0118
	call    POSIT
	ld	hl,Setupll
	call	print		; print additional line
  endif

        xor	a
	ld	(SELITEM),a	
	ld	hl,#040b
	call    POSIT
	ld	a,OnSym
	call	CHPUT		; selected item indicator

	ld	hl,#250b
	call    POSIT
	ld	a,(SORT)
	or	a
	jr	z,Set1
	ld	a,'Y'
	jr	Set2
Set1:
	ld	a,'N'
Set2:
	call	CHPUT		; sorting Y/N
	ld	hl,#250c
	call    POSIT

	ld	a,(EFF)
	or	a
	jr	z,Set3
	ld	a,'Y'
	jr	Set4
Set3:
	ld	a,'N'
Set4:
	call	CHPUT		; effects Y/N
	ld	hl,#250d
	call    POSIT
	ld	a,(SPD)
	add	'0'
	call	CHPUT		; speed value

	ld	hl,#1b0e
	call    POSIT
	ld	a,(C2FPALM+1)	; menu foreground
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT		; R value
	ld	hl,#200e
	call    POSIT
	ld	a,(C2FPALM)
	add	'0'
	call	CHPUT		; G value
	ld	hl,#250e
	call    POSIT
	ld	a,(C2FPALM+1)
	and	%00000111
	add	'0'
	call	CHPUT		; B value

	ld	hl,#1b0f
	call    POSIT
	ld	a,(C2BPALM+1)	; menu background
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT		; R value
	ld	hl,#200f
	call    POSIT
	ld	a,(C2BPALM)
	add	'0'
	call	CHPUT		; G value
	ld	hl,#250f
	call    POSIT
	ld	a,(C2BPALM+1)
	and	%00000111
	add	'0'
	call	CHPUT		; B value

	ld	hl,#1b10
	call    POSIT
	ld	a,(C2FPALH+1)	; help foreground
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT		; R value
	ld	hl,#2010
	call    POSIT
	ld	a,(C2FPALH)
	add	'0'
	call	CHPUT		; G value
	ld	hl,#2510
	call    POSIT
	ld	a,(C2FPALH+1)
	and	%00000111
	add	'0'
	call	CHPUT		; B value

	ld	hl,#1b11
	call    POSIT
	ld	a,(C2BPALH+1)	; help background
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT		; R value
	ld	hl,#2011
	call    POSIT
	ld	a,(C2BPALH)
	add	'0'
	call	CHPUT		; G value
	ld	hl,#2511
	call    POSIT
	ld	a,(C2BPALH+1)
	and	%00000111
	add	'0'
	call	CHPUT		; B value

	ld	hl,#1b12
	call    POSIT
	ld	a,(C2FPALV+1)	; volume foreground
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT		; R value
	ld	hl,#2012
	call    POSIT
	ld	a,(C2FPALV)
	add	'0'
	call	CHPUT		; G value
	ld	hl,#2512
	call    POSIT
	ld	a,(C2FPALV+1)
	and	%00000111
	add	'0'
	call	CHPUT		; B value

	ld	hl,#1b13
	call    POSIT
	ld	a,(C2BPALV+1)	; volume background
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT		; R value
	ld	hl,#2013
	call    POSIT
	ld	a,(C2BPALV)
	add	'0'
	call	CHPUT		; G value
	ld	hl,#2513
	call    POSIT
	ld	a,(C2BPALV+1)
	and	%00000111
	add	'0'
	call	CHPUT		; B value

	ld	hl,#1b14
	call    POSIT
	ld	a,(C2FPALP+1)	; psg foreground
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT		; R value
	ld	hl,#2014
	call    POSIT
	ld	a,(C2FPALP)
	add	'0'
	call	CHPUT		; G value
	ld	hl,#2514
	call    POSIT
	ld	a,(C2FPALP+1)
	and	%00000111
	add	'0'
	call	CHPUT		; B value

	ld	hl,#1b15
	call    POSIT
	ld	a,(C2BPALP+1)	; psg background
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT		; R value
	ld	hl,#2015
	call    POSIT
	ld	a,(C2BPALP)
	add	'0'
	call	CHPUT		; G value
	ld	hl,#2515
	call    POSIT
	ld	a,(C2BPALP+1)
	and	%00000111
	add	'0'
	call	CHPUT		; B value

	ld	hl,#250b
	ld	(SETXY),hl	; cursor coordinates

	ld	hl,(C2FPALS)
	ex	de,hl
	ld	hl,(C2BPALS)
	ld	b,C2FCOLS
	ld	c,#0D
	call	FadeIn		; fade in text

SetLoop:
	call	ENADISP		; enable display

	call	KILBUF

	ld	hl,(SETXY)
	ld	h,#25
	ld	a,(SELITEM)
	cp	3
	jp	c,SetLoop1
	ld	h,#1b
	ld	(SETXY),hl
	call    POSIT

SetColor:
	ld	a,(SELITEM)
	cp	5
	jr	c,SetColorM
	cp	7
	jr	c,SetColorH
	cp	9
	jr	c,SetColorV

SetColorP:
	ld	a,C2FCOLP
	ld	hl,(C2FPALP)
	call	PALETTE		; set menu palette
	ld	a,C2BCOLP
	ld	hl,(C2BPALP)
	call	PALETTE		; set menu palette
	ld	a,C2FCOLP
	ld	(FORCLR),a
	ld	a,C2BCOLP
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set menu color
	jp	SetLoop2

SetColorM:
	ld	a,C2FCOLM
	ld	hl,(C2FPALM)
	call	PALETTE		; set menu palette
	ld	a,C2BCOLM
	ld	hl,(C2BPALM)
	call	PALETTE		; set menu palette
	ld	a,C2FCOLM
	ld	(FORCLR),a
	ld	a,C2BCOLM
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set menu color
	jp	SetLoop2

SetColorH:
	ld	a,C2FCOLH
	ld	hl,(C2FPALH)
	call	PALETTE		; set menu palette
	ld	a,C2BCOLH
	ld	hl,(C2BPALH)
	call	PALETTE		; set menu palette
	ld	a,C2FCOLH
	ld	(FORCLR),a
	ld	a,C2BCOLH
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set menu color
	jp	SetLoop2

SetColorV:
	ld	a,C2FCOLV
	ld	hl,(C2FPALV)
	call	PALETTE		; set menu palette
	ld	a,C2BCOLV
	ld	hl,(C2BPALV)
	call	PALETTE		; set menu palette
	ld	a,C2FCOLV
	ld	(FORCLR),a
	ld	a,C2BCOLV
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set menu color
	jp	SetLoop2

SetLoop1:
	ld	(SETXY),hl
	call    POSIT

	ld	a,C2FCOLS
	ld	hl,(C2FPALS)
	call	PALETTE		; set default UI setup palette
	ld	a,C2BCOLS
	ld	hl,(C2BPALS)
	call	PALETTE		; set default UI setup palette
	ld	a,C2FCOLS
	ld	(FORCLR),a
	ld	a,C2BCOLS
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set default UI setup color

SetLoop2:
	call	CHGET		; wait for a key
	cp	27		; ESC
	jp	z,SetEnd
	cp	9		; TAB
	jp	z,NextItem
	cp	32		; SPACE
	jr	z,Set_Val
	cp	29		; LEFT
	jp	z,SetLeft
	cp	28		; RIGHT
	jp	z,SetRight
	cp	11		; HOME
	jp	z,SetReset
	jp	SetLoop


Set_Val:
	ld	a,(SELITEM)
	or	a
	jr	z,Set_V0
	cp	1
	jr	z,Set_V1
	cp	2
	jr	z,Set_V2
	jp	Set_V3

Set_V0:
	ld	a,(SORT)
	or	a
	jr	z,Set_V01
	xor	a
	ld	(SORT),a
	ld	a,'N'
	jp	Set_VE
Set_V01:
	ld	a,1	
	ld	(SORT),a
	ld	a,'Y'
	jp	Set_VE

Set_V1:
	ld	a,(EFF)
	or	a
	jr	z,Set_V11
	xor	a
	ld	(EFF),a		; no effects
	ld	a,'N'
	jp	Set_VE
Set_V11:
	ld	a,1	
	ld	(EFF),a
	ld	a,'Y'		; with effects
	jp	Set_VE

Set_V2:
	ld	a,(SPD)
	cp	9		; max?
	jr	c,Set_V22
	xor	a
Set_V21:
	ld	(SPD),a
	add	'0'
	jp	Set_VE
Set_V22:
	inc	a
	jr	Set_V21

Set_V3:
	ld	hl,C2FPALM-2
	ld	a,(SELITEM)
	sub	2
	ld	b,a
Set_V30:
	inc	hl
	inc	hl
	djnz	Set_V30		; find appropriate color area
	ex	de,hl
	ld	hl,(SETXY)
	ld	a,h
	cp	#1b		; R
	jr	z,Set_V31
	cp	#25		; B
	jr	z,Set_V32

	ex	de,hl
	ld	a,(hl)		; point to G value
	and	%00000111
	inc	a
	and	%00000111
	ld	(hl),a
	push	af
	ex	de,hl
	call    POSIT
	pop	af
	add	'0'
	call	CHPUT		; print G value
	ld	hl,(SETXY)
	call    POSIT
	jp	SetColor

Set_V31:
	ex	de,hl
	inc	hl
	ld	a,(hl)		; point to R value
	and	%01110111
	add	#10
	and	%01110111
	ld	(hl),a
	push	af
	ex	de,hl
	call    POSIT
	pop	af
	and	%01110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT		; print R value
	ld	hl,(SETXY)
	call    POSIT
	jp	SetColor

Set_V32:
	ex	de,hl
	inc	hl
	ld	a,(hl)		; point to B value
	and	%01110111
	inc	a
	and	%01110111
	ld	(hl),a
	push	af
	ex	de,hl
	call    POSIT
	pop	af
	and	%00000111
	add	'0'
	call	CHPUT		; print B value
	ld	hl,(SETXY)
	call    POSIT
	jp	SetColor


Set_VE:
	push	af
	ld	hl,(SETXY)
	call    POSIT
	ld	a,' '
	call	CHPUT		; erase setting
	ld	hl,(SETXY)
	call    POSIT
	pop	af
	call	CHPUT		; put new setting
	ld	hl,(SETXY)
	call    POSIT
	jp	SetLoop2


SetLeft:
	ld	a,(SELITEM)
	cp	3
	jp	c,SetLoop2
	ld	hl,(SETXY)
	ld	a,h
	cp	#1b
	jr	z,SetLeft1
	sub	5
	ld	h,a
	ld	(SETXY),hl
	call    POSIT
	jp	SetLoop2
SetLeft1:
	ld	h,#25
	ld	(SETXY),hl
	call    POSIT
	jp	SetLoop2


SetRight:
	ld	a,(SELITEM)
	cp	3
	jp	c,SetLoop2
	ld	hl,(SETXY)
	ld	a,h
	cp	#25
	jr	z,SetRight1
	add	5
	ld	h,a
	ld	(SETXY),hl
	call    POSIT
	jp	SetLoop2
SetRight1:
	ld	h,#1b
	ld	(SETXY),hl
	call    POSIT
	jp	SetLoop2


NextItem:
	ld	hl,(SETXY)
	ld	a,(SELITEM)
	push	af
	push	hl
	ld	h,#04
	call    POSIT
	ld	a,' '
	call	CHPUT		; erase item indicator
	pop	hl
	pop	af

	ld	a,(VDPVER)	; detect if 9918 is used, skip pallette operations then
	or	a
	jr	nz,NextItem0
	ld	a,(SELITEM)
	cp	#02
	jr	nz,NextItem1
	ld	a,#ff
	ld	l,#0a
	jr	NextItem1

NextItem0:
	ld	a,(SELITEM)
	cp	#0a
	jr	nz,NextItem1
	ld	a,#ff
	ld	l,#0a

NextItem1:
	inc	a
	inc	l
	ld	(SELITEM),a
	ld	(SETXY),hl
	ld	h,#04
	call    POSIT
	ld	a,OnSym
	call	CHPUT		; selected item indicator
	jp	SetLoop


SetReset:
	ld	hl,SORTD
	ld	de,SORT
	ld	bc,19
	ldir			; reset all settings to defaults
	jp	UISetup2


SetEnd:
	ld	a,%01100000	; write enable
	call	EEWEN

	ld	a,4
	call	EERD		; read originalsorting flag
	ld	b,a
	ld	a,(SORT)
	cp	b		; sorting status changed?
	jp	z,SetEnd0
	ld	a,b		; sorting currently enabled?
	or	a
	jr	z,SetEnd00

	ld	hl,B2ON
	ld	de,CardMDR+#0C	; set Bank2 to Flash
	ld	bc,6
	ldir
	jr	SetEnd01

SetEnd00:
	call	DirSort		; sort directory and set RAM instead of flash

SetEnd01:
	ld	a,2
	ld	(CardMDR+#0E),a	; set 2nd bank to autostart map
	ld	a,(SORT)
	or	a
	jr	z,SetEndEr
	ld	hl,B2ON+#03
	ld	a,(hl)
	ld	(CardMDR+#0F),a	; show flash instead of RAM for autostart

SetEndEr:
	xor	a
	ld	(AUTOST),a	; no autostart
	exx
	dec	a
	ld	c,a		; erase autostart
	exx
	call	ATR_M_Erase	; erase all records

	ld	a,1
	ld	(CardMDR+#0E),a	; set 2nd bank to directory map
	ld	a,(SORT)
	or	a
	jr	z,SetEndHm
	ld	hl,RAM_SORT+#03
	ld	a,(hl)
	ld	(CardMDR+#0F),a	; show RAM instead of flash for directory

SetEndHm:
	exx
	xor	a
	ld	d,a
	ld	hl,#0001
	ld	(CURPAG),hl	; set page 1 after sorting mode change
	exx

SetEnd0:
	ld	a,(SORT)
	ld	e,a             ; data
	ld	a,4		; address
	call	EEWR		; save sort to EEPROM
	ld	a,(EFF)
	ld	e,a             ; data
	ld	a,5		; address
	call	EEWR		; save speed to EEPROM
	ld	a,(SPD)
	ld	e,a             ; data
	ld	a,6		; address
	call	EEWR		; save speed to EEPROM

	ld	a,7
	ld	hl,C2FPALM
SetEnd1:
	push	af
	push	af
	ld	a,(hl)
	ld	e,a
	pop	af
	call	EEWR		; save palette EEPROM
	inc	hl
	pop	af
	inc	a
	cp	#17
	jr	nz,SetEnd1

	ld	a,#42
	ld	e,a             ; data
	ld	a,#17		; address
	call	EEWR		; save custom flag to EEPROM

	ld	a,C2FCOLS
	ld	hl,(C2FPALS)
	call	PALETTE		; set default UI setup palette
	ld	a,C2BCOLS
	ld	hl,(C2BPALS)
	call	PALETTE		; set default UI setup palette
	ld	a,C2FCOLS
	ld	(FORCLR),a
	ld	a,C2BCOLS
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set default UI setup color
	
	ld	hl,(C2BPALS)
	ex	de,hl
	ld	hl,(C2FPALS)
	ld	b,C2FCOLS
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#0000
	ld	hl,(C2BPALS)
	ld	b,C2BCOLS
	ld	c,#0D
	call	FadeOut		; fade out background

  if CV=2
	ld	hl,(C2BPALM)
	ex	de,hl
  else
	ld	de,#1304
  endif
	ld	hl,#0000
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeIn		; fade in background

	ld	a,C2FCOLM
  if CV=2
	ld	hl,(C2BPALM)
  else
	ld	hl,#1304
  endif
	call	PALETTE

	jp	Pagep


; Test if the VDP is a TMS9918A
; Out A: 0=9918, 1=9938, 2=9958
;
DetVDP:
	in	a,(#99)		; read s#0, make sure interrupt flag is reset
	di
DetVDPW:
	in	a,(#99)		; read s#0
	and	a		; wait until interrupt flag is set
	jp	p,DetVDPW
	ld	a,2		; select s#2 on V9938
	out	(#99),a
	ld	a,15+128
	out	(#99),a
	nop
	nop
	in	a,(#99)		; read s#2 / s#0
	ex	af,af'
	xor	a		; select s#0 as required by BIOS
	out	(#99),a
	ld	a,15+128
	ei
	out	(#99),a
	ex	af,af'
	and	%01000000	; check if bit 6 was 0 (s#0 5S) or 1 (s#2 VR)
	or	a
	ret	z

	ld	a,1		; select s#1
	di
	out	(#99),a
	ld	a,15+128
	out	(#99),a
	nop
	nop
	in	a,(#99)		; read s#1
	and	%00111110	; get VDP ID
	rrca
	ex	af,af'
	xor	a		; select s#0 as required by BIOS
	out	(#99),a
	ld	a,15+128
	ei
	out	(#99),a
	ex	af,af'
	jr	z,DetVDPE	; VDP = 9938?
	inc	a
DetVDPE:
	inc	a
	ld	(VDPVER),a
	ret


  if CV=2
; Change frequency to 50 or 60 Hz
ChangeFreq:
	ld	a,(VDPVER)	; get vdp verison (0=9918, 1=9938, 2=9958)
	or	a
	jr	nz,Change0	; don't use frequency change on MSX1
	jp	CH01
Change0:
	ld	a,(PALNTSC)
	bit	1,a
	jr	nz,Change1
	set	1,a		; set to PAL
	jr	Change2
Change1:
	res	1,a		; set to NTSC
Change2:
	ld	(PALNTSC),a
	push	af
	push	af

; Fade out font and background
  if CV=2
	ld	hl,(C2BPALM)
	ex	de,hl
  else
	ld	de,#1304
  endif
	ld	hl,(C2FPALM)
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text
	call	CLS
	ld	de,#0000
  if CV=2
	ld	hl,(C2BPALM)
  else
	ld	hl,#1304
  endif
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeOut		; fade out background

	pop	af
	ld	b,a
	ld	a,9
	ld	c,a
	call	WRITVDP		; write to VDP register (set 50 or 60 HZ mode)

	ld	a,%01100000	; write enable
	call	EEWEN
	pop	af
	ld	e,a             ; data
	ld	a,2		; address
	call	EEWR		; save vdp register 10 value to EEPROM

; Set screen after change of frequency
	ld	a,40
	ld	(SCR0WID),a	; set default width of screen0
	xor	a
	call	SSCREEN
	call	MODE40A
	call	CLS

  if CV=2
	ld	hl,(C2BPALM)
	ex	de,hl
  else
	ld	de,#1304
  endif
	ld	hl,#0000
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeIn		; fade in background

	ld	a,C2FCOLM
  if CV=2
	ld	hl,(C2BPALM)
  else
	ld	hl,#1304
  endif
	call	PALETTE
	jp	Pagep
  endif


; Wait for vertical scan on VDP	
VDP_VScan:
	push	af
	ld	a,(VDPVER)
	or	a
	jr	nz,VDP_VSDO
	pop	af

	ld	a,h
	or	a		; first call?
	jr	nz,VDP_VS1
	ld	a,#BF		; simulate start of frame
	ret

VDP_VS1:
	di
	push	bc
	push	hl
	ld	bc,#FFFF
VDP_VS2:			; for 1/50 of 3.58Mhz CPU time = 71600 cycles,
				; so we need to repeat 280 cycles 256 times
	ld	hl,(0000)	; 20 cycles
	ld	hl,(0000)	; 20 cycles
	ld	hl,(0000)	; 20 cycles
	ld	hl,(0000)	; 20 cycles
	ld	hl,(0000)	; 20 cycles
	ld	hl,(0000)	; 20 cycles
	ld	hl,(0000)	; 20 cycles
	ld	hl,(0000)	; 20 cycles
	ld	hl,(0000)	; 20 cycles
	ld	hl,(0000)	; 20 cycles
	ld	hl,(0000)	; 20 cycles
	ld	hl,(0000)	; 20 cycles
	ld	hl,(0000)	; 20 cycles
	xor	#FF		; 7 cycles
	djnz	VDP_VS2		; 13 cycles

	ei
	pop	hl
	pop	bc
	dec	h		; reset the flag when called second time
	ld	a,#40		; simulate end of frame (1/50 second delay)
	ret

VDP_VSDO:
	pop	af
	di
	out	(#99),a
	ld	a,#8F
	out	(#99),a
	push	hl
	pop	hl
	in	a,(#99)
	push	af
	xor	a
	out	(#99),a
	ld	a,#8F
	out	(#99),a
	pop	af
	ei
	ret


; Toggle Turbo mode for Panasonic MSX2+ or R800 mode for Turbo-R
;
  if CV=2
TurboMode:
	ld	a,(VDPVER)
	or	a		; MSX1?
	jp	z,CH00

	ld	a,(CHGCPU)
	cp	#C3		; Turbo-R machine?
	jr	z,R800Mode

	ld	a,(RDBTST)
	cp	#C3		; MSX2+ machine?
	jp	nz,CH00

	ld	a,8
	out	(#40),a		; prepare to get vendor ID
	nop
	in	a,(#40)		; get vendor ID
	cpl
	cp	8		; Panasonic machine?
	jp	nz,CH00

	ld	a,4
	ld	(MSXTYPE),a	; save MSX type

	ld	a,(TURBOM)
	or	a
	jr	z,TurboM1
	ld	a,1
	out	(#41),a		; disable Turbo mode on MSX2+
	dec	a
	ld	(TURBOM),a
	call	PrintTur
	jp	CH00
	
TurboM1:
	xor	a
	out	(#41),a		; enable Turbo mode on MSX2+
	inc	a
	ld	(TURBOM),a
	call	PrintTur
	jp	CH00

R800Mode:
	ld	a,5
	ld	(MSXTYPE),a	; save MSX type

	ld	a,(GETCPU)
	cp	#C3		; verify that this is Turbo-R BIOS
	jp	nz,CH00
	call	GETCPU		; get processor mode
	cp	2
	jp	z,CH00		; return if R800 DRAM mode is on
	or	a
	jr	nz,Z80Mode
	ld	a,%10000001	; R800 mode and LED on
	call	CHGCPU		; set processor mode
	ld	a,1
	ld	(TURBOM),a
	call	PrintTur
	jp	CH00

Z80Mode:
	ld	a,%10000000	; z80 mode and LED off
	call	CHGCPU		; set processor mode
	xor	a
	ld	(TURBOM),a
	call	PrintTur
	jp	CH00
  endif


; Set FMPAC/SCC/SCC+ volume screen
;
  if CV=2
SetVolume:
	ld	a,(VDPVER)	; detect if 9938 or later used, don't disable the screen
	or	a
	jr	nz,SetVol1
	call	DISDISP		; disable display

SetVol1:
  if CV=2
	ld	hl,(C2BPALM)
	ex	de,hl
  else
	ld	de,#1304
  endif
	ld	hl,(C2FPALM)
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#0000
	ld	hl,(C2BPALM)
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeOut		; fade out background

	ld	a,C2BCOLV
	ld	hl,#0000
	call	PALETTE
	ld	a,C2FCOLV
	ld	(FORCLR),a
	ld	a,C2BCOLV
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors (foreground=background)

	ld	a,C2FCOLV
	ld	hl,(C2BPALV)
	call	PALETTE

	ld	hl,(C2BPALV)
	ex	de,hl
	ld	hl,#0000
	ld	b,C2BCOLV
	ld	c,#0D
	call	FadeIn		; fade in background

  if SPC=1
	ld	a,#20
	ld	(#F3B1),a
	ld	hl,VolumeScr	; print volume control screen
	call	print	
	ld	a,#18
	ld	(#F3B1),a
  else
	ld	hl,VolumeScr	; print volume control screen
	call	print
  endif

  if SPC=1
	ld	hl,#0118
	call    POSIT
	ld	hl,Volll
	call	print		; print additional line
  endif

	ld	hl,(C2FPALV)
	ex	de,hl
	ld	hl,(C2BPALV)
	ld	b,C2FCOLV
	ld	c,#0D
	call	FadeIn		; fade in text

VolPrint:
	ld	hl,#110D	; position cursor for FMPAC volume printing
	call    POSIT
	ld	a,(CardMDR+#22)
	rra
	rra
	rra
	and	7
	inc	a
	ld	b,a
	call	hexout

	ld	hl,#050F	; FMPAC indicator position 1
	call	POSIT
	ld	hl,IndEmpty1
	call	print
	ld	hl,#0510	; FMPAC indicator position 2
	call	POSIT
	ld	hl,IndEmpty2
	call	print
	ld	hl,#050F	; FMPAC indicator position 1
IndPrn1:
	call	POSIT
	push	hl
	push	hl
	ld	hl,VolumeInd	; output current volume
	call	print
	pop	hl
	inc	l
	call	POSIT
	ld	hl,VolumeInd	; output current volume
	call	print
	pop	hl
	inc	h
	inc	h
	inc	h
	inc	h
	djnz	IndPrn1

	ld	hl,#1412	; position cursor for SCC volume printing
	call	POSIT
	ld	a,(CardMDR+#22)
	and	7
	inc	a
	ld	b,a
	call	hexout

	ld	hl,#0514	; SCC indicator position 1
	call	POSIT
	ld	hl,IndEmpty1
	call	print
	ld	hl,#0515	; SCC indicator position 2
	call	POSIT
	ld	hl,IndEmpty2
	call	print
	ld	hl,#0514	; SCC indicator position 1
IndPrn2:
	call	POSIT
	push	hl
	push	hl
	ld	hl,VolumeInd	; output current volume
	call	print
	pop	hl
	inc	l
	call	POSIT
	ld	hl,VolumeInd	; output current volume
	call	print
	pop	hl
	inc	h
	inc	h
	inc	h
	inc	h
	djnz	IndPrn2

	ld	hl,#1804	; position cursor
	call    POSIT

VolLoop:
	call	ENADISP		; enable display

	call	KILBUF

Wait2:
	call	CHSNS		; wait for key and avoid displaying cursor
	jr	z,Wait2

	call	CHGET		; wait for a key
	cp	27		; ESC
	jp	z,VolEnd
	cp	30		; UP
	jr	z,VFM_UP
	cp	31		; DOWN
	jr	z,VFM_DOWN
	cp	28		; RIGHT
	jr	z,VSCC_UP
	cp	29		; LEFT
	jr	z,VSCC_DOWN
	cp	11		; HOME
	jr	z,VolReset
	jr	VolLoop

VFM_UP:
	ld	a,(CardMDR+#22)
	rra
	rra
	rra
	inc	a
	rla
	rla
	rla
	and	%00111000
	ld	b,a
	ld	a,(CardMDR+#22)
	and	%11000111
	or	b
	ld	(CardMDR+#22),a
	jp	VolPrint

VFM_DOWN:
	ld	a,(CardMDR+#22)
	rra
	rra
	rra
	dec	a
	rla
	rla
	rla
	and	%00111000
	ld	b,a
	ld	a,(CardMDR+#22)
	and	%11000111
	or	b
	ld	(CardMDR+#22),a
	jp	VolPrint

VSCC_UP:
	ld	a,(CardMDR+#22)
	inc	a
	and	%00000111
	ld	b,a
	ld	a,(CardMDR+#22)
	and	%11111000
	or	b
	ld	(CardMDR+#22),a
	jp	VolPrint

VSCC_DOWN:
	ld	a,(CardMDR+#22)
	dec	a
	and	%00000111
	ld	b,a
	ld	a,(CardMDR+#22)
	and	%11111000
	or	b
	ld	(CardMDR+#22),a
	jp	VolPrint

VolReset:
        ld	hl,DefVol	; default volume for FMPAC and SCC
	ld	a,(hl)
	ld	(CardMDR+#22),a
	jp      VolPrint


VolEnd:
	ld	a,%01100000	; write enable
	call	EEWEN
	ld	a,(CardMDR+#22)
	and	%10111111
	or	%10000000	; set flag for manually set volume (bit 7 = 1 while bit 6 = 0)
	ld	e,a             ; data
	ld	a,1		; address
	call	EEWR		; save volume data to EEPROM

	ld	hl,(C2BPALV)
	ex	de,hl
	ld	hl,(C2FPALV)
	ld	b,C2FCOLV
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#0000
	ld	hl,(C2BPALV)
	ld	b,C2BCOLV
	ld	c,#0D
	call	FadeOut		; fade out background

	ld	hl,(C2BPALM)
	ex	de,hl
	ld	hl,#0000
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeIn		; fade in background

	ld	a,C2FCOLM
	ld	hl,(C2BPALM)
	call	PALETTE

	jp	Pagep
  endif


; Set PSG volume screen
;
  if CV=2
PSGVolume:
	ld	a,(VDPVER)	; detect if 9938 or later used, don't disable the screen
	or	a
	jr	nz,SetPSG1
	call	DISDISP		; disable display

SetPSG1:
  if CV=2
	ld	hl,(C2BPALM)
	ex	de,hl
  else
	ld	de,#1304
  endif
	ld	hl,(C2FPALM)
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#0000
	ld	hl,(C2BPALM)
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeOut		; fade out background

	ld	a,C2BCOLP
	ld	hl,#0000
	call	PALETTE
	ld	a,C2FCOLP
	ld	(FORCLR),a
	ld	a,C2BCOLP
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors (foreground=background)

	ld	a,C2FCOLP
	ld	hl,(C2BPALP)
	call	PALETTE

	ld	hl,(C2BPALP)
	ex	de,hl
	ld	hl,#0000
	ld	b,C2BCOLP
	ld	c,#0D
	call	FadeIn		; fade in background

  if SPC=1
	ld	a,#20
	ld	(#F3B1),a
	ld	hl,PSGScr	; print PSG control screen
	call	print	
	ld	a,#18
	ld	(#F3B1),a
  else
	ld	hl,PSGScr	; print PSG control screen
	call	print
  endif

  if SPC=1
	ld	hl,#0118
	call    POSIT
	ld	hl,PSGll
	call	print		; print additional line
  endif

	ld	hl,(C2FPALP)
	ex	de,hl
	ld	hl,(C2BPALP)
	ld	b,C2FCOLP
	ld	c,#0D
	call	FadeIn		; fade in text

PSGPrint:
	ld	hl,#0F10	; position cursor for PSG volume printing
	call    POSIT
	ld	a,(CardMDR+#24)
	rra
	rra
	rra
	and	7
	inc	a
	ld	b,a
	call	hexout

	ld	hl,#0511	; PSG indicator position 1
	call	POSIT
	ld	hl,IndEmpty1
	call	print
	ld	hl,#0512	; PSG indicator position 2
	call	POSIT
	ld	hl,IndEmpty2
	call	print
	ld	hl,#0511	; PSG indicator position 1
PSGPrn1:
	call	POSIT
	push	hl
	push	hl
	ld	hl,VolumeInd	; output current volume
	call	print
	pop	hl
	inc	l
	call	POSIT
	ld	hl,VolumeInd	; output current volume
	call	print
	pop	hl
	inc	h
	inc	h
	inc	h
	inc	h
	djnz	PSGPrn1

	ld	hl,#1714	; position cursor for SCC volume printing
	call	POSIT
	ld	a,(CardMDR+#24)
	and	7
	inc	a
	ld	b,a
	call	hexout

	ld	hl,#0515	; Clicker indicator position 1
	call	POSIT
	ld	hl,IndEmpty1
	call	print
	ld	hl,#0516	; Clicker indicator position 2
	call	POSIT
	ld	hl,IndEmpty2
	call	print
	ld	hl,#0515	; Clicker indicator position 1
PSGPrn2:
	call	POSIT
	push	hl
	push	hl
	ld	hl,VolumeInd	; output current volume
	call	print
	pop	hl
	inc	l
	call	POSIT
	ld	hl,VolumeInd	; output current volume
	call	print
	pop	hl
	inc	h
	inc	h
	inc	h
	inc	h
	djnz	PSGPrn2

PSGStPr:
	ld	hl,#1004
	call    POSIT	
	ld	a,' '
	call	CHPUT		; mark device as disabled
	ld	a,(CardMDR+#24)
	bit	7,a
	jr	z,PSGPrn3
	ld	hl,#1004
	call    POSIT	
	ld	a,OnSym
	call	CHPUT		; mark device as enabled
PSGPrn3:
	ld	hl,#2504
	call    POSIT	
	ld	a,' '
	call	CHPUT		; mark device as disabled
	ld	a,(CardMDR+#24)
	bit	6,a
	jr	z,PSGLoop
	ld	hl,#2504
	call    POSIT	
	ld	a,OnSym
	call	CHPUT		; mark device as enabled


PSGLoop:
	call	ENADISP		; enable display

	call	KILBUF

Wait3:
	call	CHSNS		; wait for key and avoid displaying cursor
	jr	z,Wait3

	call	CHGET		; wait for a key
	cp	27		; ESC
	jp	z,PSGEnd
	cp	30		; UP
	jr	z,PSG_UP
	cp	31		; DOWN
	jr	z,PSG_DOWN
	cp	28		; RIGHT
	jr	z,CLKR_UP
	cp	29		; LEFT
	jr	z,CLKR_DOWN
	cp	11		; HOME
	jp	z,PSGReset
	cp	13		; Enter
	jr	z,PSG_ED
	cp	32		; Space
	jr	z,CLKR_ED
	jr	PSGLoop

PSG_ED:
	ld	a,(CardMDR+#24)
	bit	7,a
	jr	z,PSG_ED1
	res	7,a
	jr	PSG_ED2
PSG_ED1:
	set	7,a
PSG_ED2:
	ld	(CardMDR+#24),a
	jp	PSGStPr

	
CLKR_ED:
	ld	a,(CardMDR+#24)
	bit	6,a
	jr	z,CLKR_ED1
	res	6,a
	jr	CLKR_ED2
CLKR_ED1:
	set	6,a
CLKR_ED2:
	ld	(CardMDR+#24),a
	jp	PSGStPr


PSG_UP:
	ld	a,(CardMDR+#24)
	rra
	rra
	rra
	inc	a
	rla
	rla
	rla
	and	%00111000
	ld	b,a
	ld	a,(CardMDR+#24)
	and	%11000111
	or	b
	ld	(CardMDR+#24),a
	jp	PSGPrint

PSG_DOWN:
	ld	a,(CardMDR+#24)
	rra
	rra
	rra
	dec	a
	rla
	rla
	rla
	and	%00111000
	ld	b,a
	ld	a,(CardMDR+#24)
	and	%11000111
	or	b
	ld	(CardMDR+#24),a
	jp	PSGPrint

CLKR_UP:
	ld	a,(CardMDR+#24)
	inc	a
	and	%00000111
	ld	b,a
	ld	a,(CardMDR+#24)
	and	%11111000
	or	b
	ld	(CardMDR+#24),a
	jp	PSGPrint

CLKR_DOWN:
	ld	a,(CardMDR+#24)
	dec	a
	and	%00000111
	ld	b,a
	ld	a,(CardMDR+#24)
	and	%11111000
	or	b
	ld	(CardMDR+#24),a
	jp	PSGPrint

PSGReset:
        ld	hl,DefPSG	; default volume and configuration for PSG and Clicker
	ld	a,(hl)
	ld	(CardMDR+#24),a
	jp      PSGPrint


PSGEnd:
	ld	a,%01100000	; write enable
	call	EEWEN
	ld	a,(CardMDR+#24)
	ld	e,a             ; data
	ld	a,3		; address
	call	EEWR		; save PSG configuration data to EEPROM

	ld	hl,(C2BPALP)
	ex	de,hl
	ld	hl,(C2FPALP)
	ld	b,C2FCOLP
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#0000
	ld	hl,(C2BPALP)
	ld	b,C2BCOLP
	ld	c,#0D
	call	FadeOut		; fade out background

	ld	hl,(C2BPALM)
	ex	de,hl
	ld	hl,#0000
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeIn		; fade in background

	ld	a,C2FCOLM
	ld	hl,(C2BPALM)
	call	PALETTE

	jp	Pagep
  endif


; Delay subroutine for joystick

JoyDelay:
	push	af
	push	hl
	push	de
	push	bc

	ei
	ld	hl,#0000
	ld	bc,NTSC_dl	; set delay for joystick in NTSC
	ld	a,(SPD)
	add	a		; double the delay
	add	a,c
	ld	c,a		; add speed increment
	ld	a,(PALNTSC)
	bit	1,a
	jr	z,JoyWait
	ld	bc,PAL_dl	; set delay for joystick for PAL
	ld	a,(SPD)
	add	a,c
	ld	c,a		; add speed increment

JoyWait:
	ld	a,2
	call	VDP_VScan	; wait for VSYNC to start
	and	#40
	jr	nz,JoyWait
JoyWait1:
	ld	a,2
	inc	h
	call	VDP_VScan	; wait for VSYNC to end (1 frame to draw)
	and	#40
	jr	z,JoyWait1
	dec	bc
	inc	l
	ld	a,l
	cp	50
	jr	nz,JoyWait2
	xor	a
	ld	l,a
JoyWait2:
	ld	a,b
	or	a
	jr	nz,JoyWait
	ld	a,c
	or	a
	jr	nz,JoyWait

	pop	bc
	pop	de
	pop	hl
	pop	af
	ret


; Special RAM code for pre-startup arrangements (starts at #4000, code starts at #4010)
; #CF00 = frequency to set
; #CF01 = CardMDR register
; #CF02 = bank0 configuration
; #CF08 = bank1 configuration
; #CF0E = bank2 configuration
; #CF14 = bank3 configuration
; #CF1A = cartridge's slot configuration
; #CF1B = CardMDR register copy
; #CF1C = size and position of rom in block
; #CF1D = start block in flash for ROM
; #CF1E = start method for ROM
; #CF1F = mapper symbol
; #CF20 = rom's start address
; #CF22 = Turbo mode on/off (1=on)
; #CF23 = MSX type (4 = Panasonic MSX2+, 5=Turbo-R)
; #CF24 = cartridge's slot

  if CV=2
PRE_ROM:
	di
	ld	hl,#4020
	ld	de,#C020
	ld	bc,#0FE0
	ldir			; move pre-start block to RAM at #C000
	ei
	jp	#C020

; This code starts at #C020 after passing the control
; Set 60/50 Hz flag into R10
	nop
	nop
	ld	a,(WRITVDP)
	cp	#C3		; BIOS in page 0?
	jr	nz,SetTurbo

	ld	a,(#CF00)	; Reset options Bit 3 60/50 Hz
	ld      b,a
        ld      a,9
	ld      c,a
        call    WRITVDP		; write to VDP R10 register #9  (Bit 1 - PAL/NTSC)

SetTurbo:
	ld	a,(#CF22)
	or	a		; turbo/r800 mode on?
	jr	z,PRE_ROS

	ld	a,(#CF23)
	cp	4		; not Panasonic MSX2+ or Turbo-R?
	jr	c,PRE_ROS
	cp	5
	jr	z,SetR800
	xor	a
	out	(#41),a		; enable Turbo mode on MSX2+
	jr	PRE_ROS

SetR800:
	ld	a,(CHGCPU)
	cp	#C3		; Turbo-R machine with BIOS in page 0?
	jr	nz,PRE_ROS

	ld	a,%10000001	; R800 mode and LED on
	call	CHGCPU		; set processor mode

; Set Cartrige registers
PRE_ROS:
	ld	a,%00100000
	ld	(CardMDR),a	; set configuration with immediate trigger and registers at #4F80

	ld	a,(#CF1D)
	ld	(CardMDR+#05),a	; set start block for ROM

	ld	a,(#CF1E)	; read start address designation
	push	af
	ld	a,(#CF1F)	; read entry type before configuration change
	push	af
	ld	hl,(#CF20)
	push	hl		; ROM's start address

	ld	hl,#CF02
	ld	de,CardMDR+#06
	ld	bc,26
	ldir			; set correct configuration for ROM starting by copying registers for 4 pages

	ld	a,(#CF21)
	cp	#80		; ROM's start base address >#80?
	jr	c,PRE_ROS3

	ld	a,(#CF24)	; cartridge's slot number
	rlca
	rlca
	rlca
	rlca
	ld	b,a
	in	a,(#A8)
	and	%11000000	; enable BIOS and Basic for first 2 pages
	or	b		; select cartridge's slot for #8000 page
	out	(#A8),a
	ld	a,(#FFFF)
	cpl
	and	%11001111	; page at #8000 must be enabled for games that start above #8000
	ld	(#FFFF),a

	ld	a,(#CF24)	; cartridge's slot number
	ld	hl,#FCC1
	ld	c,a
	xor	a
	ld	b,a
	add	hl,bc
	ld	a,(hl)
	cp	#80		; cartridge's slot expanded?
	jr	nz,PRE_ROS2

PRE_ROS1:
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a,(#FFFF)
	cpl
	ld	(hl),a		; set correct subslot configuration for current expanded slot

PRE_ROS2:
	pop	hl
	pop	af
	pop	af
	jp	(hl)		; direct jump to ROM's startup code in page 3

PRE_ROS3:
	cp	#40		; ROM's start base address >#40?
	jr	nc,PRE_ROS2

	ld	a,(#CF24)	; cartridge's slot number
	ld	b,a
	in	a,(#A8)
	and	%11110000	; enable BIOS and Carnivore2 first 2 pages
	or	b		; select cartridge's slot for #8000 page
	out	(#A8),a

	ld	a,(#FFFF)
	cpl
	and	%11111100	; page at #0000 must be enabled for games that start below #4000
	ld	(#FFFF),a

	ld	a,(#CF24)	; cartridge's slot number
	ld	hl,#FCC1
	ld	c,a
	xor	a
	ld	b,a
	add	hl,bc
	ld	a,(hl)
	cp	#80		; cartridge's slot expanded?
	jr	nz,PRE_ROS2

	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a,(#FFFF)
	cpl
	ld	(hl),a		; set correct subslot configuration for current expanded slot
	jr	PRE_ROS2

PRE_ROME:
	nop
  endif


MainScr:
  if SPC=0
	db	#88,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8F
  if CV=2
	db	#8C," Carnivore2 MultiFunctional Cartridge ",#8D
	db	#8C,"  ",#90,#91," RBSC ",#96," Help",#A5,#92,#91," Volume",#A5,#93,#91," PSG",#A5,#99,#91,"  ",#8D
  else
	db	#8C,"  Carnivore MultiFlash SCC Cartridge  ",#8D
	db	#8C,"    ",#90,#91,"2019 RBSC. Press ",#93,#91," for Help    ",#8D
  endif
	db	#8C," ",#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A," ",#8D
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
  else
	db	#01,#58,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59
	db	#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#5A
	db	#01,#5B," Carnivore2 MultiFunctional Cartridge ",#01,#5F
	db	#01,#5B," (C) RBSC Help:'H' Volume:'V' PSG:'P' ",#01,#5F
	db	#01,#5B,"  ----------------------------------  ",#01,#5F
	db	#01,#5B,"  Entry selected for autostart: [  ]  ",#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B,#01,#50,9,9,9,9,"      ",#01,#52,#01,#5F
	db	#01,#5B,#01,#57,9,9,9,9,"      ",#01,#53,#01,#5F
	db	#01,#5B,#01,#57,9,9,9,9,"      ",#01,#53,#01,#5F
	db	#01,#5B,#01,#57,9,9,9,9,"      ",#01,#53,#01,#5F
	db	#01,#5B,#01,#57,9,9,9,9,"      ",#01,#53,#01,#5F
	db	#01,#5B,#01,#57,9,9,9,9,"      ",#01,#53,#01,#5F
	db	#01,#5B,#01,#57,9,9,9,9,"      ",#01,#53,#01,#5F
	db	#01,#5B,#01,#57,9,9,9,9,"      ",#01,#53,#01,#5F
	db	#01,#5B,#01,#57,9,9,9,9,"      ",#01,#53,#01,#5F
	db	#01,#5B,#01,#57,9,9,9,9,"      ",#01,#53,#01,#5F
	db	#01,#5B,#01,#57,9,9,9,9,"      ",#01,#53,#01,#5F
	db	#01,#5B,#01,#57,9,9,9,9,"      ",#01,#53,#01,#5F
	db	#01,#5B,#01,#57,9,9,9,9,"      ",#01,#53,#01,#5F
	db	#01,#5B,#01,#57,9,9,9,9,"      ",#01,#53,#01,#5F
	db	#01,#5B,#01,#57,9,9,9,9,"      ",#01,#53,#01,#5F
	db	#01,#5B,#01,#56,9,9,9,9,"      ",#01,#54,#01,#5F
	db	#01,#5E,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D
	db	#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5C
	db	0
  endif


  if CV=2
VolumeScr:
  if SPC=0
	db	#88,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8F
	db	#8C,"  Carnivore2 Cartridge's Sound Setup  ",#8D
	db	#8C,"  ",#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,"  ",#8D
	db	#8C," Control Keys:                        ",#8D
	db	#8C,"                                      ",#8D
	db	#8C,#20,#01,#50,"[ESC]   - save & exit to main menu  ",#8D
	db	#8C,#20,#01,#57,"[UP]    - increase FMPAC volume     ",#8D
	db	#8C,#20,#01,#57,"[DOWN]  - decrease FMPAC volume     ",#8D
	db	#8C,#20,#01,#57,"[RIGHT] - increase SCC",#96,"SCC+ volume  ",#8D
	db	#8C,#20,#01,#57,"[LEFT]  - decrease SCC",#96,"SCC+ volume  ",#8D
	db	#8C,#20,#01,#56,"[HOME]  - reset to default values   ",#8D
	db	#8C,"                                      ",#8D
	db	#8C," FMPAC Volume:                        ",#8D
	db	#8C,"                                      ",#8D
	db	#8C,#20,#20,#A0,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A2,#20,#20,#8D
	db	#8C,#20,#20,#A1,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#A3,#20,#20,#8D
	db	#8C,"                                      ",#8D
	db	#8C," SCC",#96,"SCC+ Volume:                     ",#8D
	db	#8C,"                                      ",#8D
	db	#8C,#20,#20,#A0,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A2,#20,#20,#8D
	db	#8C,#20,#20,#A1,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#A3,#20,#20,#8D
	db	#8C,"                                      ",#8D
	db	#8E,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#89
	db	"              Set the desired volume..."
	db	0
  else
	db	#01,#58,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59
	db	#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#5A
	db	#01,#5B,"  Carnivore2 Cartridge's Sound Setup  ",#01,#5F
	db	#01,#5B,"   --------------------------------   ",#01,#5F
	db	#01,#5B," Control Keys:                        ",#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B,#20,#01,#50,"[ESC]   - save & exit to main menu  ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[UP]    - increase FMPAC volume     ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[DOWN]  - decrease FMPAC volume     ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[RIGHT] - increase SCC/SCC+ volume  ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[LEFT]  - decrease SCC/SCC+ volume  ",#01,#5F
	db	#01,#5B,#20,#01,#56,"[HOME]  - reset to default values   ",#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B," FMPAC Volume:                        ",#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B,#20,#20,#01,#50,"--------------------------------",#01,#52,#20,#20,#01,#5F
	db	#01,#5B,#20,#20,#01,#56,"--------------------------------",#01,#54,#20,#20,#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B," SCC/SCC+ Volume:                     ",#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B,#20,#20,#01,#50,"--------------------------------",#01,#52,#20,#20,#01,#5F
	db	#01,#5B,#20,#20,#01,#56,"--------------------------------",#01,#54,#20,#20,#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5E,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D
	db	#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5C
	db	0
Volll	db	"              Set the desired volume...",0
  endif
  endif

  if CV=2
PSGScr:
  if SPC=0
	db	#88,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8F
	db	#8C,"   Carnivore2 Cartridge's PSG Setup   ",#8D
	db	#8C,"   ",#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,"   ",#8D
	db	#8C," PSG Enabled [ ]  Clicker Enabled [ ] ",#8D
	db	#8C,"                                      ",#8D
	db	#8C," Control Keys:                        ",#8D
	db	#8C,#20,#01,#50,"[ESC]   - save & exit to main menu  ",#8D
	db	#8C,#20,#01,#57,"[ENTER] - enable/disable PSG        ",#8D
	db	#8C,#20,#01,#57,"[SPACE] - enable/disable Clicker    ",#8D
	db	#8C,#20,#01,#57,"[UP]    - increase PSG volume       ",#8D
	db	#8C,#20,#01,#57,"[DOWN]  - decrease PSG volume       ",#8D
	db	#8C,#20,#01,#57,"[RIGHT] - increase Clicker volume   ",#8D
	db	#8C,#20,#01,#57,"[LEFT]  - decrease Clicker volume   ",#8D
	db	#8C,#20,#01,#56,"[HOME]  - reset to default values   ",#8D
	db	#8C,"                                      ",#8D
	db	#8C," PSG Volume:                          ",#8D
	db	#8C,#20,#20,#A0,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A2,#20,#20,#8D
	db	#8C,#20,#20,#A1,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#A3,#20,#20,#8D
	db	#8C,"                                      ",#8D
	db	#8C," PPI Clicker Volume:                  ",#8D
	db	#8C,#20,#20,#A0,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A2,#20,#20,#8D
	db	#8C,#20,#20,#A1,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#A3,#20,#20,#8D
	db	#8E,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#89
	db	"       Set up PSG and desired volume..."   
	db	0
  else
	db	#01,#58,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59
	db	#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#5A
	db	#01,#5B,"   Carnivore2 Cartridge's PSG Setup   ",#01,#5F
	db	#01,#5B,"    ------------------------------    ",#01,#5F
	db	#01,#5B," PSG Enabled [ ]  Clicker Enabled [ ] ",#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B," Control Keys:                        ",#01,#5F
	db	#01,#5B,#20,#01,#50,"[ESC]   - save & exit to main menu  ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[ENTER] - enable/disable PSG        ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[SPACE] - enable/disable Clicker    ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[UP]    - increase PSG volume       ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[DOWN]  - decrease PSG volume       ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[RIGHT] - increase Clicker volume   ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[LEFT]  - decrease Clicker volume   ",#01,#5F
	db	#01,#5B,#20,#01,#56,"[HOME]  - reset to default values   ",#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B," PSG Volume:                          ",#01,#5F
	db	#01,#5B,#20,#20,#01,#50,"--------------------------------",#01,#52,#20,#20,#01,#5F
	db	#01,#5B,#20,#20,#01,#56,"--------------------------------",#01,#54,#20,#20,#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B," PPI Clicker Volume:                  ",#01,#5F
	db	#01,#5B,#20,#20,#01,#50,"--------------------------------",#01,#52,#20,#20,#01,#5F
	db	#01,#5B,#20,#20,#01,#56,"--------------------------------",#01,#54,#20,#20,#01,#5F
	db	#01,#5E,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D
	db	#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5C
	db	0
PSGll	db	"       Set up PSG and desired volume...",0
  endif
  endif

HelpScr1:
  if SPC=0
	db	#88,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8F
  if CV=2
	db	#8C,"  Carnivore2 Cartridge's Help Screen  ",#8D
  else
	db	#8C,"  Carnivore Cartridge's Help Screen   ",#8D
  endif
	db	#8C,"  ",#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,"  ",#8D
	db	#8C," Menu Navigation and Action Keys:     ",#8D
	db	#8C,#20,#01,#50,"[ESC] - boot MSX using the default  ",#8D
  if CV=2
	db	#8C,#20,#01,#57,"        configuration: all enabled  ",#8D
	db	#8C,#20,#01,#57,"                                    ",#8D
  else
	db	#8C,#20,#01,#57,"        configuration               ",#8D
	db	#8C,#20,#01,#57,"                                    ",#8D
  endif
	db	#8C,#20,#01,#57,"[LEFT],[RIGHT] - previous/next page ",#8D
	db	#8C,#20,#01,#57,"[UP],[DOWN] - select ROM/CFG entry  ",#8D
	db	#8C,#20,#01,#57,"[SPACE],[ENTER] - start an entry    ",#8D
	db	#8C,#20,#01,#57,"[G] - start an entry directly       ",#8D
	db	#8C,#20,#01,#57,"[R] - reset MSX and start an entry  ",#8D
	db	#8C,#20,#01,#57,"[A] - select an entry for autostart ",#8D
	db	#8C,#20,#01,#57,"[D] - disable autostart option      ",#8D
	db	#8C,#20,#01,#57,"[F] - select 50Hz or 60Hz frequency ",#8D
	db	#8C,#20,#01,#57,"[T] - toggle Turbo or R800 mode     ",#8D
	db	#8C,#20,#01,#56,"[S] - customize boot block's UI     ",#8D
	db	#8C,"                                      ",#8D
	db	#8C," Boot Option Keys:                    ",#8D
	db	#8C,#20,#01,#50,"[F3] - disable custom UI settings   ",#8D
	db	#8C,#20,#01,#57,"[F4] - disable autostart option     ",#8D
	db	#8C,#20,#01,#56,"[F5] - disable startup menu         ",#8D
	db	#8E,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#89
helpll	db	" v2.00     Press any key to continue...",0
	db	0
  else
	db	#01,#58,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59
	db	#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#5A
	db	#01,#5B,"  Carnivore2 Cartridge's Help Screen  ",#01,#5F
	db	#01,#5B,"   --------------------------------   ",#01,#5F
	db	#01,#5B," Menu Navigation and Action Keys:     ",#01,#5F
	db	#01,#5B,#20,#01,#50,"[ESC] - boot MSX using the default  ",#01,#5F
	db	#01,#5B,#20,#01,#57,"        configuration: all enabled  ",#01,#5F
	db	#01,#5B,#20,#01,#57,"                                    ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[LEFT],[RIGHT] - previous/next page ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[UP],[DOWN] - select ROM/CFG entry  ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[SPACE],[ENTER] - start an entry    ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[G] - start an entry directly       ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[R] - reset MSX and start an entry  ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[A] - select an entry for autostart ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[D] - disable autostart option      ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[F] - select 50Hz or 60Hz frequency ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[T] - toggle Turbo or R800 mode     ",#01,#5F
	db	#01,#5B,#20,#01,#56,"[S] - customize boot block's UI     ",#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B," Boot Option Keys:                    ",#01,#5F
	db	#01,#5B,#20,#01,#50,"[F3] - disable custom UI settings   ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[F4] - disable autostart option     ",#01,#5F
	db	#01,#5B,#20,#01,#56,"[F5] - disable startup menu         ",#01,#5F
	db	#01,#5E,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D
	db	#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5C
helpll	db	" v2.00     Press any key to continue..."
	db	0
  endif

HelpScr2:
  if SPC=0
	db	#88,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8F
  if CV=2
	db	#8C,"  Carnivore2 Cartridge's Help Screen  ",#8D
  else
	db	#8C,"  Carnivore Cartridge's Help Screen   ",#8D
  endif
	db	#8C,"  ",#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,"  ",#8D
	db	#8C," Menu Navigation and Joystick Action: ",#8D
	db	#8C,"                                      ",#8D
	db	#8C,#20,#01,#50,"[LEFT],[RIGHT] - previous/next page ",#8D
	db	#8C,#20,#01,#56,"[UP],[DOWN] - select ROM/CFG entry  ",#8D
	db	#8C,"                                      ",#8D
	db	#8C,"  NOTE:                               ",#8D
	db	#8C,"  All other directions are ignored    ",#8D
	db	#8C,"                                      ",#8D
	db	#8C,#20,#01,#50,"[BUTTON A] - start selected entry   ",#8D
	db	#8C,#20,#01,#57,"[BUTTON B] - reset MSX and start    ",#8D
	db	#8C,#20,#01,#56,"             selected entry         ",#8D
	db	#8C,"                                      ",#8D
	db	#8C," Autostart Joystick Action:           ",#8D
	db	#8C,"                                      ",#8D
	db	#8C,#20,#01,#50,"[BUTTON A] - disable autostart      ",#8D
	db	#8C,#20,#01,#56,"[BUTTON B] - disable autostart      ",#8D
	db	#8C,"                                      ",#8D
	db	#8C,"  NOTE:                               ",#8D
	db	#8C,"  Please hold a button for 1 second   ",#8D
	db	#8E,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#89
helplll	db	" v2.00       Press any key to return..."
	db	0
  else
	db	#01,#58,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59
	db	#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#5A
	db	#01,#5B,"  Carnivore2 Cartridge's Help Screen  ",#01,#5F
	db	#01,#5B,"   --------------------------------   ",#01,#5F
	db	#01,#5B," Menu Navigation and Joystick Action: ",#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B,#20,#01,#50,"[LEFT],[RIGHT] - previous/next page ",#01,#5F
	db	#01,#5B,#20,#01,#56,"[UP],[DOWN] - select ROM/CFG entry  ",#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B,"  NOTE:                               ",#01,#5F
	db	#01,#5B,"  All other directions are ignored    ",#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B,#20,#01,#50,"[BUTTON A] - start selected entry   ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[BUTTON B] - reset MSX and start    ",#01,#5F
	db	#01,#5B,#20,#01,#56,"             selected entry         ",#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B," Autostart Joystick Action:           ",#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B,#20,#01,#50,"[BUTTON A] - disable autostart      ",#01,#5F
	db	#01,#5B,#20,#01,#56,"[BUTTON B] - disable autostart      ",#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B,"  NOTE:                               ",#01,#5F
	db	#01,#5B,"  Please hold a button for 1 second   ",#01,#5F
	db	#01,#5E,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D
	db	#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5C
helplll	db	" v2.00       Press any key to return..."
	db	0
  endif


  if CV=2
SetupScr:
  if SPC=0
	db	#88,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8A,#8F
	db	#8C,"   Carnivore2 Cartridge's UI Setup    ",#8D
	db	#8C,"   ",#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,#9A,"    ",#8D
	db	#8C," Control Keys:                        ",#8D
	db	#8C,#20,#01,#50,"[ESC]   - save & exit to main menu  ",#8D
	db	#8C,#20,#01,#57,"[TAB]   - select options to modify  ",#8D
	db	#8C,#20,#01,#57,"[SPACE] - change selected value     ",#8D
	db	#8C,#20,#01,#57,"[RIGHT],[LEFT] - select RGB options ",#8D
	db	#8C,#20,#01,#56,"[HOME]  - reset to default values   ",#8D
	db	#8C,"                                      ",#8D
	db	#8C," [ ] Entry sorting in main menu:  ( ) ",#8D
	db	#8C," [ ] Fade in/out effects:         ( ) ",#8D
	db	#8C," [ ] Keyboard/joystick speed:     ( ) ",#8D
	db	#8C," [ ] Menu font:        R( ) G( ) B( ) ",#8D
	db	#8C," [ ] Menu background:  R( ) G( ) B( ) ",#8D
	db	#8C," [ ] Help font:        R( ) G( ) B( ) ",#8D
	db	#8C," [ ] Help background:  R( ) G( ) B( ) ",#8D
	db	#8C," [ ] Volume font:      R( ) G( ) B( ) ",#8D
	db	#8C," [ ] Volume backg.:    R( ) G( ) B( ) ",#8D
	db	#8C," [ ] PSG setup font:   R( ) G( ) B( ) ",#8D
	db	#8C," [ ] PSG setup backg.: R( ) G( ) B( ) ",#8D
	db	#8E,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#8B,#89
	db	"        Set up UI colors and options..."   
	db	0
  else
	db	#01,#58,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59
	db	#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#59,#01,#5A
	db	#01,#5B,"   Carnivore2 Cartridge's UI Setup    ",#01,#5F
	db	#01,#5B,"    -----------------------------     ",#01,#5F
	db	#01,#5B," Control Keys:                        ",#01,#5F
	db	#01,#5B,#20,#01,#50,"[ESC]   - save & exit to main menu  ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[TAB]   - select options to modify  ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[SPACE] - change selected value     ",#01,#5F
	db	#01,#5B,#20,#01,#57,"[RIGHT],[LEFT] - select RGB options ",#01,#5F
	db	#01,#5B,#20,#01,#56,"[HOME]  - reset to default values   ",#01,#5F
	db	#01,#5B,9,9,9,9,"       ",#01,#5F
	db	#01,#5B," [ ] Entry sorting in main menu:  ( ) ",#01,#5F
	db	#01,#5B," [ ] Fade in/out effects:         ( ) ",#01,#5F
	db	#01,#5B," [ ] Keyboard/joystick speed:     ( ) ",#01,#5F
	db	#01,#5B," [ ] Menu font:        R( ) G( ) B( ) ",#01,#5F
	db	#01,#5B," [ ] Menu background:  R( ) G( ) B( ) ",#01,#5F
	db	#01,#5B," [ ] Help font:        R( ) G( ) B( ) ",#01,#5F
	db	#01,#5B," [ ] Help background:  R( ) G( ) B( ) ",#01,#5F
	db	#01,#5B," [ ] Volume font:      R( ) G( ) B( ) ",#01,#5F
	db	#01,#5B," [ ] Volume backg.:    R( ) G( ) B( ) ",#01,#5F
	db	#01,#5B," [ ] PSG setup font:   R( ) G( ) B( ) ",#01,#5F
	db	#01,#5B," [ ] PSG setup backg.: R( ) G( ) B( ) ",#01,#5F
	db	#01,#5E,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D
	db	#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5D,#01,#5C
	db	0
Setupll	db	"        Set up UI colors and options..."   
  endif
  endif


; Default variables for colors and settings
SORTD	db	0
EFFD	db	1
SPDD	db	2

C2FPALMD
	dw	#7707		; default
C2BPALMD
	dw	#4301		; default
C2FPALHD
	dw	#7707		; default
C2BPALHD
	dw	#1401		; default
C2FPALVD
	dw	#7707		; default
C2BPALVD
	dw	#1304		; default
C2FPALPD
	dw	#7707		; default
C2BPALPD
	dw	#4101		; default

; Colors for setup screen -------------
; First value - foreground color
; Second value - foreground color palette
; Third value - background color
; Fourth value - background color palette

C2FCOLS	equ	15
C2FPALS	dw	#7707		; default

C2BCOLS	equ	1
C2BPALS	dw	#0000		; default


; Default colors and palette on MSX startup

DefFCol	equ	15		; white
DefWhP	equ	#7707		; 15
DefBCol	equ	4		; blue
DefBlP	equ	#1701		; 4


; Default palette
DefPal:
	dw	#0000		; 0
	dw	#0000		; 1
	dw	#1106		; 2
	dw	#3307		; 3
	dw	#1701		; 4
	dw	#2703		; 5
	dw	#5101		; 6
	dw	#2706		; 7
	dw	#7101		; 8
	dw	#7303		; 9
	dw	#6106		; 10
	dw	#6406		; 11
	dw	#1104		; 12
	dw	#6502		; 13
	dw	#5505		; 14
	dw	#7707		; 15

; Various variables, text and data

  if SPC=0
OnSym	equ	#A4
  else
OnSym	equ	'*'
  endif

Spaces:
	db	"  ",0

PALmsg:
  if SPC=0
	db	"[50Hz",#96,"Z80]",0
  else
	db	"[50Hz/Z80]",0
  endif

NTSCmsg:
  if SPC=0
	db	"[60Hz",#96,"Z80]",0
  else
	db	"[60Hz/Z80]",0
  endif

AutoMSG:
	db	"Autostart in 3 seconds...  ",10,13,10,13
	db	"Press [ESC], [TAB], [F4] or",10,13
	db	"hold any joystick button to",10,13
	db	"abort autostart",0

CRLF:	db	10,13,10,13,0

AutoDot:
	db	".",0
ResetCMSG:
	db	"New configuration applied.",10,13,"Rebooting MSX...",0
ResetMSG:
	db	"Necessary changes applied.",10,13,"Rebooting MSX...",0

PageNum:
  if SPC=0
	db	"[  ",#96,"  ]",0
  else
	db	"[  /  ]",0
  endif

DefMode:
	db	"Z80",0
T2PMode:
	db	"T2+",0
RTRMode:
	db	"R8x",0

VolumeL:
  if SPC=0
	db	"[FMP",#A5,"1",#96,"SCC",#A5,"1",#96,"PSG",#A5,"1]",0
  else
	db	"[FMP:1/SCC:1/PSG:1]",0
  endif
  if SPC=0

VolumeInd:
	db	#98,#98,#98,#98,0,0
IndEmpty1:
	db	#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,#A6,0
IndEmpty2:
	db	#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,#5E,0
  else
VolumeInd:
	db	">>>>",0,0
IndEmpty1:
	db	"--------------------------------",0
IndEmpty2:
	db	"--------------------------------",0
  endif

DefVol:
	db	#1B		; 00011011
DefPSG:
	db	#1B		; 00011011
B2ON:
	db	#F0,#70,#01,#15,#7F,#80
B2ON1:
	db	#F0,#70,#02,#14,#7F,#80
RAM_TS4B:
	db	#F8,#80,#00,#35,#7F,#80
RAM_TS4BR:
	db	#F8,#80,#00,#25,#7F,#40
RAM_SORT1:
	db	#F8,#80,#02,#34,#7F,#A0
RAM_SORT2:
	db	#F8,#80,#03,#34,#7F,#A0
RAM_SORT:
	db	#F8,#80,#01,#35,#7F,#80



  if SPC=1
; BIOS envelope routines for Korean and Arabic MSXs
GTSTCK_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#00D5
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

GTTRIG_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#00D8
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

RDBTST_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#017A
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

CHGCPU_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#0180
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

GETCPU_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#0183
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

CHSNS_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#009C
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

DISDISP_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#0041
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

ENADISP_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#0044
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

WRITVDP_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#0047
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

KILBUF_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#0156
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

DISKEYS_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#00CC
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

ENAKEYS_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#00CF
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

CHCOLOR_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#0062
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

MODE40A_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#006C
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

MODE40_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#0078
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

SSCREEN_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#005F
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

CHGET_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#009F
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

CLEARS_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#00C3
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

CHPUT_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#00A2
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

ENASLT_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#0024
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret

POSIT_E:
	exx
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	exx
	call	#00C6
	exx
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	exx
	ret
  endif

GTTRIGG:
	push	hl
	push	bc
	push	de
	call	GTTRIG		; joystick 1 button A
	pop	de
	pop	bc
	pop	hl
	ret


; BIOS call envelope for Korean and Arabic machines (shadow registers get corrupted on BIOS calls!
; Bios Calls
  if SPC=0
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
WRITVDP	equ	#0047
ENADISP	equ	#0044
DISDISP	equ	#0041
CHSNS	equ	#009C
GETCPU  equ     #0183
CHGCPU  equ     #0180
RDBTST  equ     #017A
GTSTCK	equ	#00D5
GTTRIG	equ	#00D8
  else
ENASLT	equ	ENASLT_E
CHPUT	equ	CHPUT_E
CLEARS	equ	CLEARS_E
POSIT	equ	POSIT_E
CHGET	equ	CHGET_E
SSCREEN	equ	SSCREEN_E
MODE40	equ	MODE40_E
MODE40A	equ	MODE40A_E
CHCOLOR	equ	CHCOLOR_E
ENAKEYS	equ	ENAKEYS_E
DISKEYS	equ	DISKEYS_E
KILBUF	equ	KILBUF_E
WRITVDP	equ	WRITVDP_E
ENADISP	equ	ENADISP_E
DISDISP	equ	DISDISP_E
CHSNS	equ	CHSNS_E
GETCPU  equ     GETCPU_E
CHGCPU  equ     CHGCPU_E
RDBTST  equ     RDBTST_E
GTSTCK	equ	GTSTCK_E
GTTRIG	equ	GTTRIG_E
  endif

;	Cursor (2 bytes)
;
  if SPC=0
CURS1	equ	#94
CURS2	equ	#95
  else
CURS1	equ	'>'
CURS2	equ	'>'
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
;	Copyright sign
;
;	#90


; Font data
fontdat:
	dw	0

	include	"font.inc"

