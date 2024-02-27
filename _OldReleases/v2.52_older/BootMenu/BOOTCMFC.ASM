;
; Carnivore/Carnivore2 Cartridge's Boot Menu
; Copyright (c) 2015-2022 RBSC
; Portions (c) Grauw
; Portions (c) Spark/SDM
; Portions (c) Jordon aka KOD/SDM 
 
; Version 2.52
;

; !COMPILATION OPTIONS!
SPC	equ	0		; 1 = only basic characters are used for UI (for Arabic and Korean computers)
				; 0 = all characters are used for UI

; Variables
GETPNT	equ	#F3FA
PUTPNT	equ	#F3F8
CSRY	equ	#F3DC
CSRX	equ	#F3DD
CSRSW	equ	#FCA9
CSSTYL	equ	#FCAA
CSSYM	equ	#FBCC
SL0EXP	equ	#FCC1
SL1EXP	equ	#FCC2
SL2EXP	equ	#FCC3
SL3EXP	equ	#FCC4
KEYCLK	equ	#F3DB
FORCLR 	equ	#F3E9
BAKCLR 	equ	#F3EA
BDRCLR 	equ	#F3EB
CHSETA	equ	#F920
CHSETS	equ	#F91F
SCR0WID	equ	#F3AE
SCRWID	equ	#F3B0
SCRHIGH	equ	#F3B1
SCRMOD	equ	#FCAF

; Boot Menu variable storage
SCRNUM	equ	#F560
SLASLTN	equ	#F561
SCRINFO	equ	#F562	; 2 bytes!
DIRCNT	equ	#F564	; 2 bytes!
DIRPAG	equ	#F566	; 2 bytes!
CURPAG	equ	#F568	; 2 bytes!
VDPVER	equ	#F56A
MASSLAV	equ	#F56B
PALNTSC	equ	#F56C
MASSLTN	equ	#F56D
XYPOS	equ	#F56E	; 2 bytes!
AUTOST	equ	#F570
MASSEXP	equ	#F571
PSGCFG	equ	#F572
SLASEXP	equ	#F573
ORGVR10	equ	#F574
WARMBT	equ	#F575
MSXTYPE	equ     #F576
ERMSLT	equ	#F577
TURBOM	equ	#F578
MASSLTS	equ	#F579
SLASLTS	equ	#F57A
DUOSLCF	equ	#F57B
SLOTFAD	equ	#F57C
SPECRB	equ	#F57D
ARKOR	equ	#F57E
LASTU	equ	#F57F

; Variables for UI setup
SKIPFD	equ	#F580	; 1 byte
SELITEM	equ	#F581	; 1 byte
SORT	equ	#F582	; 1 byte
EFF	equ	#F583	; 1 byte
FMMON	equ	#F584	; 1 byte
SPD	equ	#F585	; 1 byte
FREQ	equ	#F586	; 1 byte
DUALRST	equ	#F587	; 1 byte
ASDELAY	equ	#F588	; 1 byte
SLOT3R	equ	#F589	; 1 byte
IOPORT	equ	#F58A	; 1 byte

; Colors for main menu screen -------------
; First value - foreground color
; Second value - foreground color palette
; Third value - background color
; Fourth value - background color palette

C2FCOLM	equ	15
C2FPALM	equ	#F58B	; 2 bytes!
C2BCOLM	equ	13
C2BPALM	equ	#F58D	; 2 bytes!

; Colors for help screen -------------
C2FCOLH	equ	15
C2FPALH	equ	#F58F	; 2 bytes!
C2BCOLH	equ	4
C2BPALH	equ	#F591	; 2 bytes!

; Colors for volume screen -------------
C2FCOLV	equ	15
C2FPALV	equ	#F593	; 2 bytes!
C2BCOLV	equ	12
C2BPALV	equ	#F595	; 2 bytes!

; Colors for PSG setup screen -------------
C2FCOLP	equ	15
C2FPALP	equ	#F597	; 2 bytes!
C2BCOLP	equ	6
C2BPALP	equ	#F599	; 2 bytes!

SETXY	equ	#F59B	; 2 bytes!
MUSSTAT	equ	#F59D
MYHOOK	equ	#F59E	; 6 bytes!
ORGHOOK	equ	#F5A4	; 6 bytes!
DIRPOS	equ	#F5AA	; 2 bytes!
BLINK	equ	#F5AC
SCROLL	equ	#F5AD
SCRTXT	equ	#F5AE	; 2 bytes!
SCRFDAT	equ	#F5B0	; 2 bytes!
SPECRBS	equ	#F5B2
SCRSEM	equ	#F5B3
SYMSEM	equ	#F5B4
SCOLORS	equ	#F5B5	; 3 bytes!
SORTBUF	equ	#F5B8	; will use 64 characters for sorting!

VDPR10	equ	#FFE8
KEYBUF	equ	#FBF0

; Card configuration registers
CardMDR equ	#4F80

; Delays for fading and scroll effects
FDelay	equ	#0800
EDelay	equ	#0400

; Scroller semaphore value
SCRSEMV	equ	#4

; Delay for autostart, title and boot menu skip
ADelay	equ	3
TDelay	equ	1
SDelay	equ	10

; Cursor (2 bytes)
CURS1	equ	#94
CURS2	equ	#95

; Delay for joystick (video frame based: assuming 60Hz for NTSC, 50Hz for PAL)
NTSC_dl	equ	6
PAL_dl	equ	5

R_Base	equ	#C010
L_STR	equ	16

; Variables for music player
MUSINIT	equ	#C000
MUSPLAY	equ	#C005
MUSSTOP	equ	#C008
REGLORG	equ	MUSINIT+#05AB

;------------------------------------------

	org	#4000
	db	"AB"	; ROM Identeficator
	dw	Boot	; Start INIT
	dw	0	; STATEMENT
	dw	0	; DEVICE
	dw	0	; TEXT
	db	0,0,0,0,0,0
Label	db	"CMFCCFRC"
	db	0
BBVers	db	"v2.52"  ; Version | also update it in the header!
	db	0


Boot:
	ld	a,(#FBEC)
	and	%00000010	; F5 - don't start boot menu
	ret	z

	ld	a,(CardMDR)
	cp	#38		; Check for DefConfig
	jr	nz,Boot0

	ld	a,#85
	ld	(CardMDR+#09),a	; set 16kb for boot menu

	ld	hl,CardMDR+6	; Current registers
	ld	de,DefCfg	; DefConfig values
	ld	bc,24
BootL:
	ex	hl,de
	ld	a,(hl)		; Compare DefConfig to current registers
	ex	hl,de
	cpi
	jr	nz,Boot0
	inc	de
	ld	a,c
	or	a		; All 24 bytes match?
	jr	nz,BootL
	ret	z

Boot0:
	call	SltDet		; detect current slot
	ld	(ERMSLT),a	; save current slot
	ld	h,#80
	call	ENASLT		; Set slot 8000-BFFF the same on 4000-3FFF

	ld	hl,B2ON
	ld	de,CardMDR+#0C	; set Bank2
	ld	bc,6
	ldir			; set cart, registers

	call	LocDetect	; detect Arabic or Korean MSX

        call	SetEnv		; set environment (screen, colors, fonts)

	ld	a,%10000111	; check slot 3.1
	call	NetDetect	; detect network modules in Russian MSXs
	jr	z,NetHalt
	ld	a,%10001111	; check slot 3.3
	call	NetDetect	; detect network modules in Russian MSXs
	jr	nz,Boot00
NetHalt:
	ld	hl,#0309
	call    POSIT
	ld	hl,Netmsg
	call	print_sp	; print halt msg
Halt:	jr	Halt

Boot00:
	call	DualReset	; check for dual reset
	ld	hl,#060B
	ld	(WARMBT),a	; 1 = cold boot
	or	a
	jr	z,SltCheck

Title:
	ld	hl,TitleScr
	ld	b,6
	ld	de,#0A09
Titlel1:
	ex	hl,de
	call    POSIT
	inc	l
	ex	hl,de
	call	print_sp	; print title lines
	djnz	Titlel1

	ld	hl,#180C
	call    POSIT
	ld	hl,BBVers
	call	print_sp	; print boot menu version

	call	InitTitle	; initialize title

	ld	hl,CardMDR+#2C
	ld	de,#190D
	ld	b,3
FirmVl:
	ld	a,(hl)		; get version
	cp	"0"
	jr	c,FirmVn	; smaller than 0?
	cp	"9"+1
	jr	nc,FirmVn
	jr	FirmVo
FirmVn:
	ld	a,"#"		; print unknown verison of firmware
FirmVo:
	push	af
	ex	hl,de
	ld	a,h
	cp	#1A
	jr	nz,FirmVs
	inc	h
FirmVs:
	call	POSIT
	inc	h
	ex	hl,de
	inc	hl
	pop	af
	call	CHPUT_VDP	; firmware version digit
	djnz	FirmVl

	call	AnimTitle	; animate title

	ld	hl,#0000
	ld	bc,TDelay*50	; set delay for title
	call	AutoWait	; wait a few seconds

SltCheck:
	ld	a,#20
	call	EERD		; read slot 3 enable flag
	ld	(SLOT3R),a

	ld	a,(ERMSLT)
	and	%00000011
	or	a		; Won't work in slot 0! Unlikely to happen anyway...
	jr	z,NoSlt
	cp	3		; Won't work in slot 3!
	jr	nz,DrCheck
	ld	a,(SLOT3R)
	or	a		; disabled?
	jr	nz,DrCheck

	ld	hl,#0000
	ld	a,(hl)
	cp	'C'		; subrom MSX2/2+?
	jr	z,NoSlt
	inc	hl
	ld	a,(hl)
	cp	'D'		; subrom MSX2/2+?
	jr	z,NoSlt
	ld	hl,#4010
	cp	'C'		; carnivore id?
	jr	nz,NoSlt
	inc	hl
	ld	a,(hl)
	cp	'M'		; carnivore id?
	jr	nz,NoSlt
	ld	hl,SL3EXP	; slot expansion table
	ld	a,(hl)		; slot expanded?
	cp	#80
	jr	z,DrCheck	; unusable

NoSlt:
	call	CLS
	ld	hl,#0611
	call    POSIT
	ld	hl,Haltmsg
	call	print_sp	; print halt msg
Halt1:	jr	Halt1

DrCheck:
	ld	a,#18
	call	EERD		; read double reset flag
	ld	(DUALRST),a
	cp	1
	jr	nz,Boot1	; disabled?
	ld	a,(WARMBT)	; check for cold boot
	or	a
	jp	nz,#0000	; reboot

Boot1:
  if SPC=0
	ld	a,(ARKOR)	; Arabic or Korean?
	or	a
	jr	z,Boot2
	call	CLS
	ld	hl,#0309
	call    POSIT
	ld	hl,AltKormsg
	call	print_sp	; print incorrect Boot Menu message
	call	KILBUF
	ld	hl,#0000
	ld	bc,SDelay*50	; set delay for boot menu skip
	call	AutoWait	; wait a few seconds
	xor	a
	call	RestEnv		; restore environment (font, colors, screen)

	ld	a,#38
	ld	(CardMDR),a	; set CardMDR for Defconfig
	ld	hl,DefCfg	; DefConfig values
	ld	de,CardMDR+6	; current registers
	ld	bc,24
	ldir
	ret			; skip boot menu
  endif

Boot2:
; set cart, register
	ld	hl,B2ON
	ld	de,CardMDR+#0C	; set Bank2
	ld	bc,6
	ldir

	ld	a,#FF
	ld	(MASSLTS),a	; nothing selected for master slot
	ld	(SLASLTS),a	; nothing selected for slave slot
	ld	(MASSLAV),a	; slave slot not used as master's subslot
	xor	a
	ld	(MASSEXP),a	; master slot not expanded by default
	ld	(SLASEXP),a	; slave slot not expanded by default
	ld	(MUSSTAT),a	; music not playing
	ld	(LASTU),a	; last used entry
	ld	(SPECRB),a	; special reboot cfg
	ld	(SPECRBS),a	; special reboot subslot cfg
	ld	(SCROLL),a	; no scroller
	ld	(SCRSEM),a	; scroller semaphore
	ld	(SYMSEM),a	; symbol semaphore
	ld	a,%00010001
	ld	(DUOSLCF),a	; default master/slave slots configuration (subslots 32103210, first 4 bits - master)
	ld	a,(CardMDR+#29)
	and	%01111111	; disable second cartridge
	ld	(CardMDR+#29),a
	call	SlotFilter	; identify usable slots
	ld	a,(SLASLTN)
	cp	#FF		; slave slot usable?
	jr	nz,Boot3
	xor	a
	ld	(MASSLAV),a	; enable slave slot emulation if no real slave slots are usable
	ld	a,#FF
	ld	(MASSEXP),a	; expand master slot by default
	ld	a,(DUOSLCF)
	or	%11110000	; enable all devices of master slot
	ld	(DUOSLCF),a

Boot3:
; Load data (FMPAC/SCC/SCC+/PSG audio volume and other settings) from small EEPROM
	ld	a,1
	call	EERD		; read volume setting from EEPROM
	ld	b,a
	and	%11000000
	cp	%10000000	; volume was set from boot menu? (bit 7 = 1, bit 6 = 0)
	jr	nz,TA_0A
	ld	a,b
	ld	(CardMDR+#22),a	; set the previously stored FMPAC/SCC/SCC+ volume

; Read 50/60Hz status from EEPROM
TA_0A:
	call	CLS

	ld	a,(VDPR10)	; read vdp register 10
	ld	(ORGVR10),a	; save original value
	ld	(PALNTSC),a	; save current mode
	ld	(FREQ),a	; save current mode
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
	ld	a,2
	call	EERD		; read PAL/NTSC setting from EEPROM
	ld	(FREQ),a	; save current mode
	cp	#FF		; ignore frequency?
	jr	z,TA_0AA
	ld	(PALNTSC),a     ; save the value
TA_0AA:
	ld	b,a
	ld	a,9
	ld	c,a
	call	WRITVDP		; write to VDP register (set 50 or 60 HZ mode)
TA_0B:
	ld	a,DefFCol
	ld	(FORCLR),a
	ld	a,DefBCol
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set screen colors (foreground=background)

	ld	a,3
	call	EERD		; read volume setting from EEPROM
	ld	(CardMDR+#24),a	; set the previously stored PSG volume
	ld 	(PSGCFG),a

	ld	a,#1E
	call	EERD		; read Dual-PSG setting from EEPROM
	cp	#FF
	jr	nz,TA_0BA
	xor	a		; fix initial value (only 0 and 1 allowed)
TA_0BA:
	ld	(CardMDR+#30),a

	ld	hl,SORTD
	ld	de,SORT
	ld	bc,25
	ldir			; reset all UI settings to defaults

	ld	a,#21
	call	EERD		; read port setting
	cp	#FF
	jr	nz,TA_0BAA
	ld	a,(ERMSLT)
	and	%00000011
	ld	b,a		; main slot number
	ld	a,#EF
	add	b		; autoset ID port based on slot
TA_0BAA:
	cp	#F0
	jr	z,TA_0BB
	cp	#F1
	jr	z,TA_0BB
	cp	#F2
	jr	z,TA_0BB
	ld	a,#F0
TA_0BB:
	ld	(IOPORT),a
	ld	(CardMDR+#35),a	; set new control port

	ld	a,#20
	call	EERD		; read slot 3 enable flag
	ld	(SLOT3R),a

	ld	a,#18
	call	EERD		; read double reset flag
	ld	(DUALRST),a

	ld	a,(#FBEB)
	and	%10000000	; F3 - don't load UI settings
	jr	z,TA_0B3

	ld	a, (CardMDR+#22)
	and	%01111111
	ld	(CardMDR+#22),a	; enable FMPAC stereo by default
	ld	a,#19
	call	EERD		; read FMPAC mono flag
	ld	(FMMON),a
	cp	1
	jr	nz,TA_0B0
	ld	a, (CardMDR+#22)
	or	%10000000
	ld	(CardMDR+#22),a	; enable FMPAC mono

TA_0B0:
	ld	a,#17
	call	EERD		; read custom flag from EEPROM
	cp	#42		; custom settings?
	jr	nz,TA_0B3

	ld	a,2
	call	EERD		; read PAL/NTSC setting from EEPROM
	ld	(FREQ),a	; save current mode
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
	ld	a,(VDPVER)
	or	a
	jr	z,TA_0B3	; pallete operations for MSX1
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

; Count all directory enrties and pages
DirCnt:
	ld	hl,0
	ld	(DIRCNT),hl	; zero dir entry count
	ld	d,0		; first entry
	ld	a,1
	ld	(DIRPAG),a	; one page by default
	ld	(CURPAG),a	; 1st page to output first
DirC0:
	call 	CalcDirPos	; calc dir entry point
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

DSort:
	call	DirSort		; sort directory

Check_AS:
	ld	a,#FF
	ld	(AUTOST),a	; no autostart
	ld	a,#1F
	call	EERD		; read autostart delay
	cp	10
	jr	c,Check_AS1
	ld	a,ADelay	; default value
Check_AS1:
	ld	(ASDELAY),a

	ld	a,#1C
	call	EERD		; check for autostart
	ld	(AUTOST),a	; save entry
	ld	d,a
	cp	#FF
	jr	z,Menu		; deselected autostart

	call 	CalcDirPos
	jr	z,Menu		; empty record, go to menu

	ld	a,(#FBEC)
	and	%00001101	; ESC, F4 no autostart
	cp	%00001101
	jr	nz,Menu

	ld	a,(ASDELAY)
	or	a
	jr	z,AutoWA22
	ld	b,a
	add	"0"
	ld	c,a
	push	bc
	push	bc

	call	CLS
	ld	hl,#030A
	call    POSIT
	ld	hl,AutoMSG
	call	print_sp	; print autostart message
	ld	hl,#150A
	call    POSIT
	pop	bc
	ld	a,c
	call	CHPUT_VDP	; output initial counter

	call	KILBUF
	ld	hl,#0000
	pop	bc
AutoWA2:
	ld	de,60		; set delay for autostart in NTSC
	ld	a,(PALNTSC)
	bit	1,a
	jr	z,AutoWA21
	ld	de,50		; set delay for autostart for PAL
AutoWA21:
	push	hl
	push	de
	push	bc
	push	de
	pop	bc
	call	AutoWait	; wait a few seconds
	jr	nz,AutoWA3
	ld	hl,#150A
	call    POSIT
	pop	bc
	dec	c
	ld	a,c
	push	bc
	call	CHPUT_VDP	; output counter symbol	
	pop	bc
	pop	de
	pop	hl
	djnz	AutoWA2

AutoWA22:
	call	CLS

	jp	RUN_CT		; not empty record, do autostart

AutoWA3:
	pop	bc
	pop	de
	pop	hl
	ld	a,#FF
	ld	(AUTOST),a	; no autostart

; Main Menu
; Search records (64b) max - 256
Menu:
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
	ld	de,#0000
	ld	(DIRPOS),de	; positions (d=entry number, e=position on page)

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

	ld	hl,(C2BPALM)
	ex	de,hl

	ld	hl,#0000
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeIn		; fade in background
	ld	a,C2FCOLM
	ld	hl,(C2BPALM)
	call	PALETTE
	ld	hl,#0707
	ld	(XYPOS),hl	; default position for cursor

MusicScroll:	
	push	hl
	pop	ix		; fix for music player
	call	MusicInit	; init music
	call	ScrollInit	; initialize data for scroller
	call	HookOn		; set hook and start music

	ld	a,#1B
	call	EERD		; read music status
	ld	(MUSSTAT),a

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
	ld	(SCRHIGH),a
	ld	hl,MainScr	; print main screen messages
	call	print_sp
	ld	a,#18
	ld	(SCRHIGH),a
  else
	ld	hl,MainScr	; print main screen messages
	call	print_sp
  endif

	call	PrintInf	; print page number
	call	PrintFrq	; print frequency of the display (50/60)
	call	PrintVol	; print volumes
        call    PrintTur        ; print turbo/r800/z80 mode

	ld	a,#1D
	call	EERD		; read scroller status
	or	a
	jr	z,Pagep0a
	ld	hl,#0104
	call    POSIT
	ld	hl,DynamicS
	call	print_sp	; print scroller placeholder
	ld	a,1

; Print autostarted entry
Pagep0a:
	ld	(SCROLL),a
	ld	hl,#1005
	call    POSIT
	ld	a,#1C
	call	EERD		; get autostart entry
	cp	#FF		; skip printing #FF
	jr	z,Pagep000
	call	hexout		; print autostart entry number

Pagep000:
	ld	a,(MASSLTS)	; selection for master slot
	cp	#FF
	jr	z,Pagep00
	or	a
	jr	nz,Pagep0000
	ld	hl,#2105
	call	POSIT
	ld	hl,Sccplsel
	call	print		; print ++ for SCC+ selection
	jr	Pagep00
Pagep0000:
	push	af
	ld	hl,#2105
	call	POSIT
	pop	af
	call	hexout		; print selection
Pagep00:
	ld	a,(SLASLTS)	; selection for slave slot
	cp	#FF
	jr	z,Pagep1
	push	af
	ld	hl,#2405
	call	POSIT
	pop	af
	call	hexout		; print selection

Pagep1:
	ld	de,(DIRPOS)	; positions (d=entry number, e=position on page)
	ld	e,0		; set first string
	ld	(DIRPOS),de	; save new position

; print page ( 16 record )
sPrr1:	call 	CalcDirPos	; calc dir entry point
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

; set hl-point
	push 	ix
	pop	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl

; mapper symbols
	ld	a,(hl)
	cp	'K'
	jr	nz,sMap1
	ld	a,#B8
	call	CHPUT_VDP	; output Konami5 mapper symbol
	ld	a,#BE
	jr	sCur
sMap1:
	cp	'k'
	jr	nz,sMap2
	ld	a,#B8
	call	CHPUT_VDP	; output Konami4 mapper symbol
	ld	a,#B3
	jr	sCur
sMap2:
	cp	'A'
	jr	nz,sMap3
	ld	a,#B4
	call	CHPUT_VDP	; output ASCII16 mapper symbol
	ld	a,#BA
	jr	sCur
sMap3:
	cp	'a'
	jr	nz,sMap4
	ld	a,#BB
	call	CHPUT_VDP	; output ASCII8 mapper symbol
	ld	a,#B9
	jr	sCur
sMap4:
	cp	'C'
	jr	nz,sMap5
	ld	a,#BC
	call	CHPUT_VDP	; output configuration symbol
	ld	a,#BD
	jr	sCur
sMap5:
	cp	'U'
	jr	nz,sMap6
	ld	a,#BF
	call	CHPUT_VDP	; output unknown mapper symbol
	ld	a,#B7
	jr	sCur
sMap6:
	cp	'M'
	jr	nz,sMap7
	ld	a,#B5
	call	CHPUT_VDP	; output multirom mapper symbol
	ld	a,#B6
	jr	sCur
sMap7:
	ld	a,#B1
	call	CHPUT_VDP	; output unknown entry symbol
	ld	a,#B2
sCur:
	call	CHPUT_VDP
	inc	hl

; clear cursor area
	ld	a,' '
	call	CHPUT_VDP	; output space for cursor
	ld	a,' '
	call	CHPUT_VDP	; output space for cursor

; print record name
	ld	b,30
sPr:	ld	a,(hl)
	call	CHPUT_VDP	; output record name
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
	ld	de,(DIRPOS)	; positions (d=entry number, e=position on page)
	ld	e,0		; cursor at 0
	ld	(DIRPOS),de	; save new position
	push	af
	ld	a,(SKIPFD)
	or	a		; skip fade on page flip?
	jr	nz,dRec1
	push	de
	ld	hl,(C2FPALM)
	ex	de,hl
	ld	hl,(C2BPALM)
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
	ld	a,(LASTU)	; last used entry
	ld	d,a
	call	CalcDirPos
	ld	hl,(XYPOS)	; cursor position
	ld	a,l
	sub	7
	ld	e,a		; actual position

	call	POSIT
	ld	a,CURS1		; print cursor symbol 1
	call	CHPUT_VDP
	ld	a,CURS2		; print cursor symbol 2
	call	CHPUT_VDP
	ld	hl,#2705
	call	POSIT		; move cursor to edge of screen

CH01:
	call	ENADISP		; enable display

	ld	bc,#0000	; no autostart - effects enabled
	call	KILBUF
	call	KILJOY

Wait0:
	call	KeyJoyDelay	; delay for interface
	call	CHSNS		; wait for key and avoid displaying cursor
	jr	nz,GetKey

	call	JoyCheck	; check joystick action
	or	a
	jr	nz,GetKey1	; action detected?
	jr	Wait0

GetKey:
	call	CHFKEY
	call	CHGET
GetKey1:
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
        cp      "C"
        jp      z,UISetup	; configuration
        cp      "c"
        jp      z,UISetup	; configuration
        cp      "O"
        jp      z,SlotSetup	; slot setup
        cp      "o"
        jp      z,SlotSetup	; slot setup
	cp	13		; ENTER
	jp	z,SlotSetup	; run selected record
	cp	"1"
	jp	z,SetCart1	; Select entry for master slot
	cp	"2"
	jp	z,SetCart2	; Select entry for slave slot
        cp      "L"
        jp      z,LastUsed	; last used entry
        cp      "l"
        jp      z,LastUsed	; last used entry
        cp      "M"
        jp      z,Aurora	; toggle music
        cp      "m"
        jp      z,Aurora	; toggle music
        cp      "S"
        jp      z,Scroller	; toggle scroller
        cp      "s"
        jp      z,Scroller	; toggle scroller
	jp	CH01


; Cursor up (previous str select)
C_UP:
	ld	a,e
	or	a
	jp	z,CH01		; 1-st string?
	ld	hl,(XYPOS)
	call	POSIT
	ld	a,' '
	call	CHPUT_VDP	; clear cursor
	ld	a,' '
	call	CHPUT_VDP	; clear cursor
C_U00:	dec	e                           
C_U01:	dec	d
	ld	a,#FF
	cp	d
	jp	z,C_D00
	call	CalcDirPos
	jr	z,C_U01
	ld	hl,(XYPOS)
	ld	a,e
	add	7
	ld	l,a
	ld	(XYPOS),hl
	ld	a,d
	ld	(LASTU),a	; last used entry
	jp	CH00


; Cursor down (next str select)
C_DOWN:
	ld	a,e
	cp	L_STR-1
	jp	nc,CH01		; last str
	ld	hl,(XYPOS)
	call	POSIT
	ld	a,' '	
	call	CHPUT_VDP	; clear cursor
	ld	a,' '
	call	CHPUT_VDP	; clear cursor
C_D00:	inc	e
C_D01:	inc	d
	ld	a,#FF
	cp	d
	jp	z,C_U00
	call	CalcDirPos
	jr	z,C_D01
	ld	hl,(XYPOS)
	ld	a,e
	add	7
	ld	l,a
	ld	(XYPOS),hl
	ld	a,d
	ld	(LASTU),a	; last used entry
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
	push	hl
	ld	hl,(C2BPALM)
	ex	de,hl
	pop	hl
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text
	pop	de

PF00:
	ld	de,(DIRPOS)	; positions (d=entry number, e=position on page)
	ld	e,L_STR
PF01:	inc	d
	ld	a,#FF
	cp	d
	jp	z,Pagep		; out of dir?
	call	CalcDirPos
	jr	z,PF01		; empty/deleted?
	dec	e
	jr	nz,PF01
	ld	(DIRPOS),de	; save new position
	ld	a,d
	ld	(LASTU),a	; last used entry
	ld	hl,#0707
	ld	(XYPOS),hl
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
	push	hl
	ld	hl,(C2BPALM)
	ex	de,hl
	pop	hl
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text
	pop	de

PB00:
	ld	de,(DIRPOS)	; positions (d=entry number, e=position on page)
	ld	e,L_STR
PB01:	dec	d
	ld	a,#FF
	cp	d
	jr	z,PB02		; out of dir?
	call	CalcDirPos
	jr	z,PB01
	dec	e
	jr	nz,PB01
PB03:
	ld	(DIRPOS),de	; positions (d=entry number, e=position on page)
	ld	a,d
	ld	(LASTU),a	; last used entry
	ld	hl,#0707
	ld	(XYPOS),hl
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
	jr	nz,RUN_CT2	; skip effects

RUN_CT1:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
;	ld	ix,#0707
	call	MUSSTOP		; stop music
	call	HookOff		; disable hook
	call	PSGINI		; init PSG
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	xor	a
	ld      (MUSSTAT),a	; stop music

	ld	a,%01100000	; write enable
	call	EEWEN
	ld	a,(ix)
	ld	e,a             ; data
	ld	a,#1A		; address
	call	EEWR		; save last used entry to EEPROM

	ld	hl,(C2FPALM)
	push	hl
	ld	hl,(C2BPALM)
	ex	de,hl
	pop	hl
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#0000
	ld	hl,(C2BPALM)
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeOut		; fade out background

	xor	a
	call	RestEnv		; restore environment (font, colors, screen)

RUN_CT2:
	ld	a,%00101100
	ld	(CardMDR),a	; set delayed configuration triggered by JP #4000

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
	jr	nz,RUN_CR2	; skip effects

; Effects
RUN_CR1:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
;	ld	ix,#0707
	call	MUSSTOP		; stop music
	call	HookOff		; disable hook
	call	PSGINI		; init PSG
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	xor	a
	ld      (MUSSTAT),a	; stop music

	ld	a,%01100000	; write enable
	call	EEWEN
	ld	a,(ix)
	ld	e,a             ; data
	ld	a,#1A		; address
	call	EEWR		; save last used entry to EEPROM

	ld	hl,(C2FPALM)
	push	hl
	ld	hl,(C2BPALM)
	ex	de,hl
	pop	hl
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#0000
	ld	hl,(C2BPALM)
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeOut		; fade out background

	ld	a,1
	call	RestEnv		; restore environment (colors, screen) except font

; Configure cart register and restart
; ix - directory entry pointer
RUN_CR2:
	ld	a,(SPECRB)	; special reboot?
	or	a
	jp	nz,RUN_CR22
	ld	a,(VDPVER)
	or	a
	jp	z,RUN_CR22	; no frequency switch for v9918 and v9928, just reset
	ld	a,(ix+#04)	; entry type
	or	%00100000
	cp	'c'       
	jp	z,RUN_CR22	; skip pre-started code

	ld	a,(FREQ)
	cp	#FF		; ignore?
	jr	z,RUN_CR2a
	ld	(PALNTSC),a	; set selected VDP frequency
RUN_CR2a:
	ld	a,(ORGVR10)	; original value of VDP frequency
	ld	b,a
	ld	a,(PALNTSC)	; read current VDP frequency
	cp	b
	jp	nz,MakePCode
	ld	a,(TURBOM)	; Turbo/R800 mode enabled?
	or	a
	jp	z,RUN_CR22	; skip pre-started code

MakePCode:
	ld	a,#20		; %00100000
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
	ld	a,%00101000
	ld	(CardMDR),a	; set delayed configuration triggered by JP #0000
	ld	de,#C300
	jr	RUN_CR23

RUN_CR22:
	ld	a,%00111000
	ld	(CardMDR),a	; set delayed configuration triggered by JP #0000 + SCC
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
	ld	a,(SPECRB)	; special reboot?
	or	a
	jr	z,Reset11
	dec	de
	ld	(de),a		; update device configuration for special reboot
	inc	de
Reset11:
	ld	a,(hl)		; CardMDR+#1F - copy
	and	%11111011	; set reconfig after JP #0000
	ld	(de),a		; save CardMDR copy

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
	ld	a,(SPECRB)	; special reboot?
	or	a
	jp	nz,#0000
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
	ld	a,%00100000
	ld	(CardMDR),a	; set immediate configuration changes

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

	jp	#0000		; reset to apply changed configuration!


; Run selected record directly (using the ROM's start adddress
RUN_CJ:
	ld	a,(AUTOST)	; autostart found?
	cp	#FF
	jr	nz,RUN_CJ2	; skip effects

RUN_CJ1:
	ld	a,(ix+#04)	; mapper type
	cp	'C'
	jp	z,CH01		; ignore direct start for configuration entries
	cp	'c'
	jp	z,CH01		; ignore direct start for configuration entries

	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
;	ld	ix,#0707
	call	MUSSTOP		; stop music
	call	HookOff		; disable hook
	call	PSGINI		; init PSG
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	xor	a
	ld      (MUSSTAT),a	; stop music

	ld	a,%01100000	; write enable
	call	EEWEN
	ld	a,(ix)
	ld	e,a             ; data
	ld	a,#1A		; address
	call	EEWR		; save last used entry to EEPROM

	ld	hl,(C2FPALM)
	push	hl
	ld	hl,(C2BPALM)
	ex	de,hl
	pop	hl
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	de,#0000
	ld	hl,(C2BPALM)
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeOut		; fade out background

	xor	a
	call	RestEnv		; restore environment (font, colors, screen)


; Configure cart register and start ROM
; ix - directory entry pointer
RUN_CJ2:
	ld	a,%00101100
	ld	(CardMDR),a	; set delayed configuration triggered by JP #4000

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


; Disable autostart and selections
DAUTO_R:
	ld	a,#FF
	ld	(MASSLTS),a	; nothing selected for master slot
	ld	(SLASLTS),a	; nothing selected for slave slot
	ld	(AUTOST),a	; no autostart

	ld	a,%01100000	; write enable
	call	EEWEN
	ld	e,#FF		; no autostart
	ld	a,#1C		; address
	call	EEWR		; save autostart

	ld	hl,#2105
	call	POSIT
	ld	hl,Spaces	; clear selection area
	call	print	
	ld	hl,#2405
	call	POSIT
	ld	hl,Spaces	; clear selection area
	call	print	
	ld	hl,#1005
	call	POSIT
	ld	hl,Spaces	; clear autostart record area
	call	print	
	jp	CH00


; Set current record (d) for autostart
AUTO_R:
	ld	(DIRPOS),de	; save position
	call 	CalcDirPos
	jp	z,CH00		; empty record, go to menu

	ld	a,%01100000	; write enable
	call	EEWEN
	ld	a,d
	ld	e,a
	ld	a,#1C		; address
	call	EEWR		; save autostart

	ld	hl,#1005
	call	POSIT
	ld	de,(DIRPOS)	; positions (d=entry number, e=position on page)
	ld	a,d
	call	hexout		; print autostart record number
	jp	CH00


; Exit from boot menu
Exit:
;	ld	ix,#0707
	call	MUSSTOP		; stop music
	call	HookOff		; disable hook
	call	PSGINI		; init PSG
	xor	a
	ld      (MUSSTAT),a	; stop music

	ld	hl,(C2BPALM)
	ex	de,hl
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

	xor	a
	call	RestEnv		; restore environment (font, colors, screen)

	ret


; Print	string
; Inp reg hl - point start string
; (hl) = 0 -> end
print_sp:
	ld	a,h
	cp	#80
	jr	c,print
	ld 	a,(CardMDR+#0E)
	push	af
	ld	a,3
	ld	(CardMDR+#0E),a	; set 2nd bank to screen data
	ld 	a,(CardMDR+#0F)
	push	af
	and	%11011111
	ld	(CardMDR+#0F),a	; set Flash instead of RAM
	call	print
	pop	af
	ld	(CardMDR+#0F),a	; restore value
	pop	af
	ld	(CardMDR+#0E),a	; restore value
	ret

print:
	ld	a,(hl)
	inc	hl
	or	a
	ei
	ret	z
	di
	cp	#A7		; inverse start
	jr	z,prinverse
	cp	#FF		; same characters (single byte)?
	jr	z,prsingle
print0:
	cp	10
	jr	nz,print1
	inc	hl
	ld	a,(CSRY)
	inc	a		; next line
	ld	(CSRY),a
	ld	a,1
	ld	(CSRX),a	; start of the line
	ld	a,(hl)
	inc	hl
	jr	print0
print1:
	cp	1
	jr	nz,printch
	ld	a,(hl)
	inc	hl
	sub	#40
printch:
	call	CHPUT_VDP
	jr	print

prinverse:
	di
	call	CHPUT_VDP
	ld	a,(hl)
	inc	hl
	or	a
	ei
	ret	z
	cp	#0F		; inverse stop
	jr	nz,prinver0
	call	CHPUT_VDP
	jr	print
prinver0:
	cp	' '
	jr	z,prinversp
	cp	'1'
	jr	c,prinverp
	cp	'6'
	jr	nc,prinverp
	add	#AA		; for numbers 1-5
	jr	prinverse

; Add more characters if needed

prinverp:
	add	#80
	jr	prinverse
prinversp:
	ld	a,#97
	jr	prinverse

prsingle:
	di
	push	bc
	ld	a,(hl)		; get counter
	ld	b,a
	inc	hl
	ld	a,(hl)		; get value
printl:
	or	a
	jr	z,print
	call	CHPUT_VDP
	djnz 	printl
	pop	bc
	inc	hl
	jr	print


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


; Output character using the direct VDP access
;
CHPUT_VDP:
	di
	push	af
	push	hl
	push	de
	push	bc
	push	af
	ld	hl,#0000
	ld	de,40		; screen width
	ld	a,(CSRY)
	dec	a
	or	a
	jr	z,CHVDP_1
	ld	b,a
CHVDP_Loop:
	add	hl,de
	djnz	CHVDP_Loop
CHVDP_1:
	ld	a,(CSRX)
	dec	a
	ld	e,a
	add	hl,de		; address in VRAM
	ld	a,l
	out	(#99),a	        
	ld	a,h
	or	#40
	nop
	nop
	out	(#99),a	
	nop
	nop
	pop	af
	out	(#98),a		; print character
	ld	a,(CSRX)
	inc	a		; next character
	ld	(CSRX),a
	cp	41
	jr	c,CHVDP_E
	ld	a,1
	ld	(CSRX),a
	ld	a,(CSRY)
	inc	a		; next line
	ld	(CSRY),a
CHVDP_E:
	pop	bc
	pop	de
	pop	hl
	pop	af
	ei
	ret


; Enable hook for interrupt routine
HookOn:
	di
	push	hl
	push	de
	push	bc
	ld	hl,#FD9F
	ld	de,ORGHOOK
	ld	bc,5
	ldir			; copy original hook
	ld	a,#F7
	ld	(MYHOOK),a	; RST #30
	ld	a,(ERMSLT)
	ld	(MYHOOK+1),a	; slot
	ld	hl,IntCode
	ld	(MYHOOK+2),hl	; address
	ld	a,#C9
	ld	(MYHOOK+4),a	; return
	ld	hl,MYHOOK
	ld	de,#FD9F
	ld	bc,5
	ldir			; set my hook
	pop	bc
	pop	de
	pop	hl
	ei
	ret


HookOff:
	di
	push	hl
	push	de
	push	bc
	ld	hl,ORGHOOK
	ld	a,(hl)
	cp	#C9		; safe empty handler
	jr	z,HookOE
	cp	#F7		; valid handler
	jr	z,HookOE
	ld	a,#C9
	ld	(ORGHOOK),a	; set safe handler
HookOE:
	ld	de,#FD9F
	ld	bc,5
	ldir			; restore original hook
	pop	bc
	pop	de
	pop	hl
	ei
	ret


; Interrupt handler (works on timer interrupt!)
IntCode:
	di
	push	af
	push	hl
	push	de
	push	bc
	push	ix
	push	iy
	call	ORGHOOK		; call original hook code (if any)
	di
	in	a,(#99)		; read status port to sync
	ld	a,(SCROLL)
	or	a		; scroller enabled?
	call	nz,DoScroll	; do scroller
	ld      a,(MUSSTAT)
	or	a
	call	nz,MUSPLAY	; play music
	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	pop	af
	ei
	reti


; Play sound with PSG
; hl - data to play
; bc - size
PlaySnd:
	push	hl
	push	bc
	ld	a,13
	push	af
SndLoop:
	pop	af
	di
	out	(#A0),a
	push	af
	ld	a,(hl)
	out	(#A1),a	
	ei
	pop	af
	sub	1
	push	af
	inc	hl
	dec	bc
	ld	a,b
	or	c
	jr	nz,SndLoop
	pop	af
	pop	bc
	pop	hl
	ret


; Print help information page
Help:
	xor	a
	ld	(SCROLL),a	; temporarily disable scroller
	ld	(SCRSEM),a	; reset counter
	ld	a,(VDPVER)	; detect if 9938 or later used, don't disable the screen
	or	a
	jr	nz,Help1
	call	DISDISP		; disable display

Help1:
	ld	hl,(C2BPALM)
	ex	de,hl
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
	ld	(SCRHIGH),a
	ld	hl,HelpScr1	; print help screen
	call	print_sp
	ld	a,#18
	ld	(SCRHIGH),a
  else
	ld	hl,HelpScr1	; print help screen
	call	print_sp
  endif

	ld	hl,(C2FPALH)
	ex	de,hl
	ld	hl,(C2BPALH)
	ld	b,C2FCOLH
	ld	c,#0D
	call	FadeIn		; fade in text

	call	ENADISP		; enable display

	call	KILBUF
	call	KILJOY

Wait1:
	call	KeyJoyDelay	; delay for interface
	call	CHSNS		; wait for key and avoid displaying cursor
	jr	nz,Wait1a

	call	JoyCheck	; check joystick action
	or	a
	jr	nz,Wait1b	; action not detected?
	jr	Wait1
Wait1a:
	call	CHFKEY
	call	CHGET		; wait for a key
Wait1b:
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
	ld	(SCRHIGH),a
	ld	hl,HelpScr2	; print help screen
	call	print_sp
	ld	a,#18
	ld	(SCRHIGH),a
  else
	ld	hl,HelpScr2	; print help screen
	call	print_sp
  endif

	ld	hl,(C2FPALH)
	ex	de,hl
	ld	hl,(C2BPALH)
	ld	b,C2FCOLH
	ld	c,#0D
	call	FadeIn		; fade in text

	call	ENADISP		; enable display

	call	KILBUF
	call	KILJOY

Wait11:
	call	KeyJoyDelay	; delay for interface
	call	CHSNS		; wait for key and avoid displaying cursor
	jr	nz,Wait11a

	call	JoyCheck	; check joystick action
	or	a
	jr	nz,Wait11b	; action not detected?
	jr	Wait11
Wait11a:
	call	CHFKEY
	call	CHGET		; wait for a key
Wait11b:
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


; 24 bytes of DefConfig to compare (must be in first 8kb!)
DefCfg
	db	#F8,#50,#00,#85,#3F,#40
	db	#F8,#70,#01,#8C,#3F,#60		
	db      #F8,#90,#02,#8C,#3F,#80		
	db	#F8,#B0,#03,#8C,#3F,#A0	


;------------------------------------------------------------
;
; CARTRIDGE REGISTERS AREA, DON'T USE!
;	

	org	#4F80

REGS:	ds	128

;------------------------------------------------------------


;
; EXTRA CODE AND DATA AREA
; The extra code and data area must start above the control registers (#4F80-#4FFF)!
;	

	org	#5000


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


; Initialize title for scroller
InitTitle:
	ld	hl,#0800+#97*8	; point to inverted space
	ld	de,SORTBUF
	ld	bc,8
	call	LDIRMV		; copy data for 8 symbols from VRAM

	ld	de,#0800+#E0*8
	ld	b,11
InitTitleL:	
	ld	hl,SORTBUF	; point to space
	push	de
	push	bc
	ld	bc,8
	call	LDIRVM		; redefine scroller symbols
	pop	bc
	pop	hl
	ld	de,8
	add	hl,de
	ex	hl,de
	djnz	InitTitleL

	ld	hl,#0F0A
	call    POSIT
	ld	hl,TitleRepl
	call	print_sp	; print scroller placeholder
	ret


; Animate title default and special
AnimTitle:
	ld 	a,(CardMDR+#0E)
	push	af
	ld	a,3
	ld	(CardMDR+#0E),a	; set 2nd bank to screen data
	ld 	a,(CardMDR+#0F)
	push	af
	and	%11011111
	ld	(CardMDR+#0F),a	; set Flash instead of RAM
	ld	bc,EDelay*2
	call	Delay		; delay
  if SPC=0
	ld	hl,TitleScrl
	ld	de,SORTBUF
	ld	b,10
	exx
	ld	hl,SORTBUF+7
	ld	de,#0800+#E0*8	; point to symbols E0
	ld	b,8
	exx
AnimLoop:
	ld	a,(hl)		; symbol from scroller text
	push	bc
	push	hl
	push	de
	ld	h,0
	ld	l,a
	add	hl,hl
	add	hl,hl
	add	hl,hl		; a * 8
	ld	de,#0800
	add	hl,de		; address of symbol's data in VRAM
	pop	de
	ld	bc,7
	call	LDIRMV		; copy data for 8 symbols from VRAM
	ld	hl,InvSpace
	ld	de,SORTBUF+7
	ld	bc,7
	ldir			; create empty inverted space character
	exx
AnimLoop1:
	push	bc
	push	hl
	push	de
	ld	bc,7
	call	LDIRVM		; redefine scroller symbol
	ld	bc,EDelay
	call	Delay		; delay
	pop	de
	pop	hl
	dec	hl
	pop	bc
	djnz	AnimLoop1
	ld	hl,8
	add	hl,de
	ex	hl,de
	ld	hl,SORTBUF+7
	ld	b,8
	exx
	ld	de,SORTBUF
	pop	hl
	inc	hl
	pop	bc
	djnz	AnimLoop
  else
	ld	hl,TitleScrl
	ld	de,SORTBUF+8
	ld	b,10
	exx
	ld	hl,SORTBUF
	ld	de,#0800+#E0*8	; point to symbols E0
	ld	b,8
	exx
AnimLoop:
	push	hl
	push	bc
	ld	hl,InvSpace
	ld	de,SORTBUF
	ld	bc,7
	ldir			; create empty inverted space character
	pop	bc
	pop	hl
	ld	a,(hl)		; symbol from scroller text
	push	bc
	push	hl
	push	de
	ld	h,0
	ld	l,a
	add	hl,hl
	add	hl,hl
	add	hl,hl		; a * 8
	ld	de,#0800
	add	hl,de		; address of symbol's data in VRAM
	pop	de
	ld	bc,7
	call	LDIRMV		; copy data for 8 symbols from VRAM
	exx
AnimLoop1:
	push	bc
	push	hl
	push	de
	ld	bc,7
	call	LDIRVM		; redefine scroller symbol
	ld	bc,EDelay
	call	Delay		; delay
	pop	de
	pop	hl
	inc	hl
	pop	bc
	djnz	AnimLoop1
	ld	hl,8
	add	hl,de
	ex	hl,de
	ld	hl,SORTBUF
	ld	b,8
	exx
	ld	de,SORTBUF
	pop	hl
	inc	hl
	pop	bc
	djnz	AnimLoop
  endif
	pop	af
	ld	(CardMDR+#0F),a	; restore value
	pop	af
	ld	(CardMDR+#0E),a	; restore value
	ret


; Scroller routine (works on timer interrupt!)
DoScroll:
	ld	a,(SCRSEM)	; counter for calling scroll
	inc	a
	ld	(SCRSEM),a
	cp	SCRSEMV
	ret	c
	xor	a
	ld	(SCRSEM),a	; reset counter
	ld	hl,(SCRFDAT)	; address of the symbol for scroller
	push	hl
	push	hl
	pop	de
	dec	de
	dec	de
	dec	de
	dec	de
	dec	de
	dec	de
	dec	de
	dec	de		; de = hl-8
	ld	b,31*8
DoScrLoop:
	sla	(hl)		; shift left with carry
	jr	nc,DoScrL1
	ex	hl,de
	set	2,(hl)		; move bit to previous character
	ex	hl,de
DoScrL1:
	inc	hl
	inc	de
	djnz	DoScrLoop
	pop	hl
	ld	de,#0800+#E0*8	; point to symbols E0
	ld	b,30*8
	ld	c,#98
	ld	a,e
	out	(#99),a	        
	ld	a,d
	or	#40		; write
	nop
	nop
	out	(#99),a	
	nop
	nop
;	otir			; output 240 bytes to VRAM
OutiVRAM:
	outi			; output byte to VRAM
	jr	nz,OutiVRAM

	ld	a,(SYMSEM)
	inc	a		; next line (8 max)
	ld	(SYMSEM),a
	cp	6		; time to change symbol?
	ret	c
	xor	a
	ld	(SYMSEM),a	; reset symbol semaphore
	ld	hl,(SCRTXT)	; address of the text for scroller
	ld	a,(hl)
	inc	hl
	or	a		; end of scroller?
	jr	nz,DoScroll1
	ld	de,ScrollerE-ScrollerS-9
	sbc	hl,de		; start of the scroller text	
	ld	a,(hl)
DoScroll1:
	ld	(SCRTXT),hl	; next character's address
	ld	h,0
	ld	l,a
	add	hl,hl
	add	hl,hl
	add	hl,hl		; a * 8
	ld	de,#0800
	add	hl,de		; address of symbol's data in VRAM
	push	hl
	ld	hl,(SCRFDAT)	; address of the symbol for scroller
	ld	de,30*8
	add	hl,de		; hl=address of hidden symbol
	pop	de
	ld	b,8
	ld	c,#98
	ld	a,e
	out	(#99),a	        
	ld	a,d
	nop
	nop
	out	(#99),a	
	nop
	nop
;	inir			; read 8 bytes from VRAM
ReadVRAM:
	ini			; read byte from VRAM
	jr	nz,ReadVRAM
	ret


; Toggle scroller
Scroller:
	push	hl
	push	de
	push	bc
	push	ix
	ld	a,(SCROLL)
	or	a
	jr	z,Scrol1

	ld	a,%01100000	; write enable
	call	EEWEN
	xor	a
	ld	(SCROLL),a	; disable scroller
	ld	(SYMSEM),a	; reset symbol semaphore
	ld	e,a             ; data
	ld	a,#1D		; address
	call	EEWR		; save scroller status

	ld	hl,#0104
	call    POSIT
	ld	hl,StaticS
	call	print_sp	; print default help screen line

	ld	hl,fontdat+#E0*8
	ld	de,#0800+#E0*8	; point to symbols E0
	ld	bc,31*8
	call	LDIRVM		; restore scroller symbols
	pop	ix
	pop	bc
	pop	de
	pop	hl
	jp	CH01
Scrol1:
	ld	a,%01100000	; write enable
	call	EEWEN
	ld	e,1		; data = enabled
	ld	a,#1D		; address
	call	EEWR		; save scroller status

	xor	a
	ld	(SYMSEM),a	; reset symbol semaphore
	ld	hl,#0800+#E0*8	; point to symbols E0
	ld	bc,31*8
	call	FILVRM		; clear the scroller symbols

	ld	hl,#0104
	call    POSIT
	ld	hl,DynamicS
	call	print_sp	; print scroller placeholder
	call	ScrollInit	; initialize data for scroller
	ld	a,1
	ld	(SCROLL),a	; enable scroller
	pop	ix
	pop	bc
	pop	de
	pop	hl
	jp	CH01


; Create font data for scroller
ScrollInit:
	ld	de,#C000
	ld	hl,MusicDataEnd-MusicData	; size of music
	add	hl,de
	ld	a,h
	cp	#E8		; must be below #E800
	jr	c,ScrollI1
	xor	a
	ld	(SCROLL),a	; disable scroller
	ld	(SYMSEM),a	; reset symbol semaphore
	ret
ScrollI1:
	ld 	a,(CardMDR+#0E)
	push	af
	ld	a,3
	ld	(CardMDR+#0E),a	; set 2nd bank to screen data
	ld 	a,(CardMDR+#0F)
	push	af
	and	%11011111
	ld	(CardMDR+#0F),a	; set Flash instead of RAM

	push	hl
	ld	de,31
	add	hl,de
	ld	(SCRTXT),hl	; address of the text for scroller + 31 symbol
	pop	hl
	ld	de,ScrollerS
	ex	hl,de
	ld	bc,ScrollerE-ScrollerS
	ldir			; copy scroller text to RAM
	ld	hl,ScrollerS
	ld	(SCRFDAT),de	; address of the symbol for scroller
	ld	bc,31
ScrollLoop:
	ld	a,(hl)		; symbol from scroller text
	push	bc
	push	hl
	push	de
	push	de
	ld	h,0
	ld	l,a
	add	hl,hl
	add	hl,hl
	add	hl,hl		; a * 8
	ld	de,#0800
	add	hl,de		; address of symbol's data in VRAM
	pop	de
	ld	bc,8
	call	LDIRMV		; copy data for 8 symbols from VRAM
	pop	de
	ld	hl,8
	ex	hl,de
	add	hl,de		; next symbol's address
	ex	hl,de
	pop	hl
	inc	hl
	pop	bc
	dec	bc
	ld	a,b
	or	c
	jr	nz,ScrollLoop
	xor	a
	ld	b,9
ScrollLoop1:
	ld	(de),a		; fill with zeroes
	inc	de
	djnz	ScrollLoop1
	pop	af
	ld	(CardMDR+#0F),a	; restore value
	pop	af
	ld	(CardMDR+#0E),a	; restore value
	ret


; Toggle music
Aurora:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	ld	a,%01100000	; write enable
	call	EEWEN
	ld      a,(MUSSTAT)
	cp	1
	jr	z,Aurora1
	ld	a,1
	ld      (MUSSTAT),a	; play music
	jr	Aurora2
Aurora1:
;	ld	ix,#0707
	call	MUSSTOP		; stop music
	xor	a
	ld      (MUSSTAT),a	; stop music
Aurora2:
	ld	e,a             ; data
	ld	a,#1B		; address
	call	EEWR		; save music status
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	jp	CH01


; Initialize music module
;
MusicInit:
	ld 	a,(CardMDR+#0E)
	push	af
	ld	a,3
	ld	(CardMDR+#0E),a	; set 2nd bank to music data
	ld 	a,(CardMDR+#0F)
	push	af
	and	%11011111
	ld	(CardMDR+#0F),a	; set Flash instead of RAM

	di 
	ld	hl,MusicData
	ld	de,#C000
	ld	bc,MusicDataEnd-MusicData	; size of music
	ldir			; move music player + data

	ld	hl,PlayPatch
	ld	bc,PlayPatchE-PlayPatch
	ldir			; copy patch after music

	ld	bc,PlayPatch
	ld	hl,REGLORG
	ld	a,#C3
	ld	(hl),a
	inc	hl
	ld	(hl),c
	inc	hl
	ld	(hl),b		; Redirect PLAY to patcher

	call	MUSINIT		; init music module

	pop	af
	ld	(CardMDR+#0F),a	; restore value
	pop	af
	ld	(CardMDR+#0E),a	; restore value
	ret


; Filter/patcher for original player
PlayPatch:
	ld	c,#A1		; ports A0-A1
	ld	hl,#C6AE
PatchLoop:
	cp	#07		; reg 7?
	jr	nz,NoPatchData
	res	6,(hl)
	set	7,(hl)
NoPatchData:
	dec	c
	out	(c),a		; C=A0
	inc	c		; C=A1
	outi
	inc	a
	cp	#0D
	jr	nz,PatchLoop
	dec	c
	out	(c),a		; C=A0
	ld	a,(hl)
	and	a
	ret	m
	inc	c		; C=A1
	out	(c),a
	ret
	nop
PlayPatchE:


; Jump to the last used entry
;
LastUsed:
	ld	a,#1A
	call	EERD		; read last used entry
	cp	#FF
	jp	z,CH01
	push	af
	ld	a,(EFF)
	or	a		; effects enabled?
	jr	z,LastU00
	push	de
	ld	hl,(C2FPALM)
	push	hl
	ld	hl,(C2BPALM)
	ex	de,hl
	pop	hl
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text
	pop	de
LastU00:
	pop	af
	or	a
	jr	nz,LastU1
LastU0:
	ld	de,(DIRPOS)	; positions (d=entry number, e=position on page)
	ld	d,0
	ld	a,1
	ld	(CURPAG),a	; set 1 page
	ld	hl,#0707
	ld	(XYPOS),hl	; default position for cursor
	xor	a
	ld	(LASTU),a	; last used entry
	jp	LastUE
LastU1:
	ld	e,a		; save last used entry
	ld	hl,#0001	; dircount+page
	ld	d,0		; first entry
	ld	b,0		; page's first entry
LastU2:
	push	bc
	call 	CalcDirPos	; calc dir entry point
	pop	bc
	jr	nz,LastU3	; normal entry?
	inc	d
	ld	a,d
	or	a		; 255+1 limit
	jr	z,LastU0
	jr	LastU2
LastU3:
	ld	a,(ix)
	cp	e		; last used entry
	jr	z,LastU4
	inc	d
	ld	a,d
	or	a		; 255+1 limit
	jr	z,LastU0
	inc	h		; number of entries
	ld	a,h
	cp	L_STR		; number of strings on page
	jr	c,LastU2
	ld	h,0
	inc	l		; next page
	ld	b,d		; first entry on the page
	jr	LastU2
LastU4:
	ld	a,d
	ld	(LASTU),a	; last used entry
	ld	a,l		; page of the last entry
	ld	(CURPAG),a	; set page
	ld	a,b
	ld	d,a		; first entry on page
	ld	(DIRPOS),de	; positions (d=entry number, e=position on page)
	ld	a,h		; line number on the page
	ld	hl,#0707	; default coordinates
	add	l
	ld	l,a
	ld	(XYPOS),hl	; new position for cursor
LastUE:
	ld	a,(EFF)
	or	a		; effects enabled?
	jp	nz,Pagep
	ld	a,#FF
	ld	(SKIPFD),a	; skip fade enabled
	call	PrintInf	; print page number
	jp	Pagep1


; Sort directory
;
DirSort:
	ld	a,(SORT)
	or	a
	ret	z

	ld	a,#20		; %00100000
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
	ld	hl,DIRCNT	; read directory count
	ld	a,(hl)
	dec	a		; exclude first entry
	or	a
	ret	z
	cp	1
	ret	z	

	di
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


; Check for functional keys input and kill it
;
CHFKEY:
	push	af
	push	bc
	ld	a,(GETPNT)
	ld	b,a
	ld	a,(PUTPNT)
	sub	b
	cp	2
	jr	c,CHFKEY_E
	call	KILBUF
	ld	bc,(GETPNT)
	ld	a,'/'		; this character will not be used anywhere
	ld	(bc),a
	inc	bc
	ld	(PUTPNT),bc
CHFKEY_E:
	pop	bc
	pop	af
	ret


; Wait until the joystick keys are released
;
KILJOY:
	ld	a,1
	call	GTTRIGG		; joystick 1 button A
	cp	#FF
	jr	z,KILJOY
	ld	a,2
	call	GTTRIGG		; joystick 2 button A
	cp	#FF
	jr	z,KILJOY
	ld	a,3
	call	GTTRIGG		; joystick 1 button B
	cp	#FF
	jr	z,KILJOY
	ld	a,4
	call	GTTRIGG		; joystick 2 button B
	cp	#FF
	jr	z,KILJOY
	ret


; Check joystick buttons and directions, transform into keypresses
;
JoyCheck:
	xor	a
	call	GTTRIGG	 	; space/built-in buttons
	or	a
	jr	z,JC1
JC0:
	ld	a,32		; Space
	ret
JC1:
	ld	a,1
	call	GTTRIGG		; joystick 1 button A
	or	a
	jr	nz,JC0
	ld	a,2
	call	GTTRIGG		; joystick 2 button A
	or	a
	jr	nz,JC0
	ld	a,3
	call	GTTRIGG		; joystick 1 button B
	or	a
	jr	z,JC3
JC2:
	ld	a,27		; ESC
	ret
JC3:
	ld	a,4
	call	GTTRIGG		; joystick 2 button B
	or	a
	jr	nz,JC2

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
	ret	z

GetJD:
	cp	1		; up
	jr	z,JC4
	cp	5		; down
	jr	z,JC5
	cp	3		; right
	jr	z,JC6
	cp	7		; left
	jr	z,JC7
	xor	a		; no action
	ret

JC4:	ld	a,30		; up
	ret
JC5:	ld	a,31		; down
	ret
JC6:	ld	a,28		; right
	ret
JC7:	ld	a,29		; left
	ret


; Restore palette, font address and colors
;
RestEnv:
	push	hl
	push	de
	push	bc
	push	af

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

	pop	af
	or	a		; keep screen and font?
	jr	nz,RestEnv1

	ld	a,(SCRINFO)	; get screen width
	ld	(SCRWID),a
	ld	a,(SCRINFO+1)	; get screen height
	ld	(SCRHIGH),a
	ld	a,(SCRNUM)	; get screen mode
	call	SSCREEN

	ld	a,(SCOLORS)
	ld	(FORCLR),a	; restore screen colors
	ld	a,(SCOLORS+1)
	ld	(BAKCLR),a	; restore screen colors
	ld	a,(SCOLORS+2)
	ld	(BDRCLR),a	; restore screen colors
	call	CHCOLOR		; set colors

RestEnv1:
	call	CLS

	pop	bc
	pop	de
	pop	hl
	ret


; Set font
;
SetFont:
	ld 	a,(CardMDR+#0E)
	push	af
	ld	a,3
	ld	(CardMDR+#0E),a	; set 2nd bank to music data
	ld 	a,(CardMDR+#0F)
	push	af
	and	%11011111
	ld	(CardMDR+#0F),a	; set Flash instead of RAM

	di 
	ld	hl,fontdat+2
	ld	de,#0800	; point to font data in VRAM
	ld	bc,2048
	call	LDIRVM		; copy data for all symbols to VRAM
	ei

	pop	af
	ld	(CardMDR+#0F),a	; restore value
	pop	af
	ld	(CardMDR+#0E),a	; restore value
	ret


; Set new font address and screen
;
SetEnv:	push	af
	push	hl
	push	de
	push	bc

	ld	a,(SCRMOD)
	ld	(SCRNUM),a	; save screen mode
	ld	a,(SCRWID)
	ld	(SCRINFO),a	; save screen width
	ld	a,(SCRHIGH)
	ld	(SCRINFO+1),a	; save screen height
	ld	a,(FORCLR)
	ld	(SCOLORS),a	; save screen colors
	ld	a,(BAKCLR)
	ld	(SCOLORS+1),a	; save screen colors
	ld	a,(BDRCLR)
	ld	(SCOLORS+2),a	; save screen colors

	ld	a,40
	ld	(SCR0WID),a	; set default width of screen0

	xor	a
	ld	(KEYCLK),a	; disable click on keypress
	call	SSCREEN		; set screen 0
	call	MODE40		; set 40x25 mode
	call	SetFont		; set font
	call	DISKEYS		; no functional key display
	call	CLS

	pop	bc
	pop	de
	pop	hl
	pop	af
	ret


; Artificial delay
; In: bc (number of loops)
Delay:
	dec	bc
	ld	a,b
	or	c
	jr	nz,Delay
	ret


; Detect Russian network modules
; in: A = slot/subslot number
;
NetDetect:
	ld	hl,#4000
	ld	b,8
	ld	de,SORTBUF
NetDetectL:
	push	af
	push	hl
	push	de
	push	bc
	call	RDSLT		; read value
	pop	bc
	pop	de
	pop	hl
	ld	(de),a		; save value
	inc	hl
	inc	de
	pop	af
	djnz	NetDetectL

	ld	hl,Net1ID
	ld	de,SORTBUF
	ld	bc,8
NetDetectA:
	ex	hl,de
	ld	a,(hl)		; Compare KYBT1 pattern
	ex	hl,de
	cpi
	jr	nz,NetDetectB
	inc	de
	ld	a,c
	or	a		; All 8 bytes match?
	jr	nz,NetDetectA
	jr	NetDetectE

NetDetectB:	
	ld	hl,Net2ID
	ld	de,SORTBUF
	ld	bc,8
NetDetectC:
	ex	hl,de
	ld	a,(hl)		; Compare KYBT2 pattern
	ex	hl,de
	cpi
	ret	nz
	inc	de
	ld	a,c
	or	a		; All 8 bytes match?
	jr	nz,NetDetectC

NetDetectE:
	xor	a
	or	a
	ret


; Detect Korean or Arabic MSX font usage
;
LocDetect:
	xor	a
	ld	(ARKOR),a	; no special case for fonts
	ld	hl,(CHSETA)	; BIOS font address
	ld	de,#C0*8
	add	hl,de		; Address of symbol #C0
	ld	b,16
	ld	de,SORTBUF
LocDetectL:
	ld	a,(CHSETS)	; BIOS font slot
	push	hl
	push	de
	push	bc
	call	RDSLT		; read value
	pop	bc
	pop	de
	pop	hl
	ld	(de),a		; save value
	inc	hl
	inc	de
	djnz	LocDetectL

	ld	hl,Arabic
	ld	de,SORTBUF
	ld	bc,16
LocDetectA:
	ex	hl,de
	ld	a,(hl)		; Compare Arabic pattern to font
	ex	hl,de
	cpi
	jr	nz,LocDetectB
	inc	de
	ld	a,c
	or	a		; All 16 bytes match?
	jr	nz,LocDetectA
	ld	a,1		; Arabic
	jr	LocDetectE

LocDetectB:	
	ld	hl,Korean
	ld	de,SORTBUF
	ld	bc,16
LocDetectC:
	ex	hl,de
	ld	a,(hl)		; Compare Korean pattern to font
	ex	hl,de
	cpi
	ret	nz
	inc	de
	ld	a,c
	or	a		; All 16 bytes match?
	jr	nz,LocDetectC
	ld	a,2		; Korean

LocDetectE:
	ld	(ARKOR),a	; special case for fonts set
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


; Set palette for a color
; In: a - color
; In: hl = palette in BRG format
PALETTE:
	push	af
	ld	a,(VDPVER)	; detect if 9918 is used, skip palette operations then
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
	ei
	ret


; Find position of the entry in the directory (unsorted)
; input d - dir index num
; outut	ix - dir entry pointer
; output Z - last/empty/deleted entry
;
CalcDirPos:
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


; Select entries for slots configuration screen
;
SetCart1:
	ld	a,(MASSLTN)	; master slot number
	cp	#FF		; usable?
	jp	z,CH00
	ld	a,(ix+#04)
	cp	"C"		; configuration entry?
	jr	z,SetCart2
	ld	a,d
	ld	(MASSLTS),a	; select record for master slot
	or	a
	jr	nz,SetCart11
	ld	hl,#2105
	call	POSIT
	ld	hl,Sccplsel
	call	print		; print ++ for SCC+ selection
	jp	CH00
SetCart11:
	push	af
	ld	hl,#2105
	call	POSIT
	pop	af
	call	hexout		; print selection
	jp	CH00

SetCart2:
	ld	a,(MASSLTN)	; master slot number
	cp	#FF		; usable?
	jp	z,CH00
	ld	a,(ix+#04)
	cp	"C"		; configuration entry?
	jp	z,CH00
	cp	"A"		; ASCII16? (unsupported)
	jp	z,CH00
	cp	"a"		; ASCII8? (unsupported)
	jp	z,CH00
	ld	a,d
	ld	(SLASLTS),a	; select record for for slave slot
	push	af
	ld	hl,#2405
	call	POSIT
	pop	af
	call	hexout		; print selection
	jp	CH00


; Wait a few seconds
; in: bc=counter
;
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

	ld	a,(#FBED)
	and	%00000001	; SPACE - skip waiting
	jr	z,AutoWEO

	ld	a,(#FBEC)
	and	%00001101	; TAB, ESC, F4 no autostart
	cp	%00001101
	jr	nz,AutoWEA	; Abort

	dec	bc
	inc	l
	ld	a,l
	cp	50
	jr	nz,AutoWait2

	xor	a
	call	GTTRIGG		; space/built-in buttons
	or	a
	jr	nz,AutoWEA	; Abort
	ld	a,1
	call	GTTRIGG		; joystick 1 button A
	or	a
	jr	nz,AutoWEO	; Skip
	ld	a,2
	call	GTTRIGG		; joystick 2 button A
	or	a
	jr	nz,AutoWEO	; Skip
	ld	a,3
	call	GTTRIGG		; joystick 1 button B
	or	a
	jr	nz,AutoWEA	; Abort
	ld	a,4
	call	GTTRIGG		; joystick 2 button B
	or	a
	jr	nz,AutoWEA	; Abort

	xor	a
	ld	l,a

AutoWait2:
	ld	a,b
	or	a
	jr	nz,AutoWait
	ld	a,c
	or	a
	jr	nz,AutoWait

AutoWEO:
	xor	a
	or	a
	ret

AutoWEA:
	ld	a,1
	or	a
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
he1:	call	CHPUT_VDP
	pop	af
	and 	#0F
	add	a,48
	cp	58
	jr	c,he2
	add	a,7
he2:	call	CHPUT_VDP
	ret

; Clear screen
CLS:	push	af
	push	de
	push	bc
	xor	a
	call	CLEARS
	pop	bc
	pop	de
	pop	af
	ret

; Print Turbo/R800 indicator
PrintTur:
	push	hl
	push	de
	push	bc

  if SPC=1
	ld	a,#20
	ld	(SCRHIGH),a
  endif

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

  if SPC=1
	ld	a,#18
	ld	(SCRHIGH),a
  endif

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
	call	CHPUT_VDP	; output empty record
	djnz	PrintERC
	pop	de
	ret


; Print page number and max pages
PrintInf:
	push	hl
	push	de
	push	bc

  if SPC=1
	ld	a,#20
	ld	(SCRHIGH),a
  endif

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

  if SPC=1
	ld	a,#18
	ld	(SCRHIGH),a
  endif

	pop	bc
	pop	de
	pop	hl
	ret


; Print current frequency display
PrintFrq:
	push	hl
	push	de
	push	bc

  if SPC=1
	ld	a,#20
	ld	(SCRHIGH),a
  endif

	ld	hl,#218
	call    POSIT
	ld	hl,PALmsg	; print PAL
	ld	a,(PALNTSC)
	bit	1,a
	jr	nz,PrintHZ
	ld	hl,NTSCmsg	; print NTSC
PrintHZ:
	call	print		; print current mode

  if SPC=1
	ld	a,#18
	ld	(SCRHIGH),a
  endif

	pop	bc
	pop	de
	pop	hl
	ret


; Print current volumes
PrintVol:
	push	hl
	push	de
	push	bc

  if SPC=1
	ld	a,#20
	ld	(SCRHIGH),a
  endif

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
	call	CHPUT_VDP	; print fmpac volume

	ld	hl,#1818
	call    POSIT
	ld	a,(CardMDR+#22)
	and	7
	inc	a
	add	#30
	call	CHPUT_VDP	; print scc volume

	ld	hl,#1E18
	call    POSIT
	ld	a,(CardMDR+#24)
	rra
	rra
	rra
	and	7
	inc	a
	add	#30
	call	CHPUT_VDP	; print PSG volume

  if SPC=1
	ld	a,#18
	ld	(SCRHIGH),a
  endif

	pop	bc
	pop	de
	pop	hl
	ret

; Check slot for presence or another device, RAM or expansion
; in: a = slot
; out: nz = usable, z = unusable
;
CheckSlot:
	ld	b,a		; save slot
	ld	e,a
	ld	hl,SL0EXP	; slot expansion table
CheckS0:
	inc	hl
	djnz	CheckS0
	ld	a,(hl)		; slot expanded?
	cp	#80
	ret	z		; unusable
	ld	a,e
	and	%00000011	; read from non-expanded slot
	ld	b,a
	ld	hl,#0000
	push	bc
	call	RDSLT
	pop	bc
	call	FindByte	; find data/code
	ret	z		; not suitable = occupied
	ld	a,b
	ld	e,#42
	push	bc
	call	WRSLT		; write value
	pop	bc
	ld	a,b
	push	bc
	call	RDSLT		; read value
	pop	bc
	cp	#42
	ret	z		; not suitable = RAM
	ld	a,b
	ld	hl,#4000
	push	bc
	call	RDSLT
	pop	bc
	call	FindByte	; find data/code
	ret	z		; not suitable = occupied
	ld	a,b
	ld	e,#42
	push	bc
	call	WRSLT		; write value
	pop	bc
	ld	a,b
	push	bc
	call	RDSLT		; read value
	pop	bc
	cp	#42
	ret	z		; not suitable = RAM
	ld	a,b
	ld	hl,#8000
	push	bc
	call	RDSLT
	pop	bc
	call	FindByte	; find data/code
	ret	z		; not suitable = occupied
	ld	a,b
	ld	e,#42
	push	bc
	call	WRSLT		; write value
	pop	bc
	ld	a,b
	push	bc
	call	RDSLT		; read value
	pop	bc
	cp	#42
	ret			; return z or nz
FindByte:
	cp	#F3		; BIOS?
	ret	z
	cp	#C3		; FS-CA1/MSX Audio?
	ret	z
	cp	#00		; Font? (Kanji)
	ret	z
	cp	#40		; Yamaha YRW/Wozblaster?
	ret	z
	cp	"A"		; ROM 'AB'?
	ret	z
	cp	"C"		; SUBROM 'CD'?
	ret	z
	xor	a
	cp	1		; return non-zero if nothing found
	ret

; Identify usable slots
;
SlotFilter:
	ld	a,(ERMSLT)
	and	%00000011
	or	a		; won't work with dual slots in slot 0! Unlikely to happen anyway...
	jr	z,SlotSet2
	push	af
	ld	a,(SLOT3R)	; allowed slot 3?
	or	a
	jr	nz,SlotSet0
	pop	af
	cp	3		; with slot 3 no expansion will be possible
	jr	z,SlotSet2
	push	af
;	jr	nz,SlotSet0
;	ld	(MASSLTN),a	; save master slot
;	ld	a,#FF
;	ld	(MASSEXP),a	; master slot non expandable (limited)
;	ld	a,1
;	ld	(SLASLTN),a	; save slave slot
;	call	CheckSlot
;	jr	z,SlotSet0
;	ld	a,2
;	ld	(SLASLTN),a	; save slave slot
;	call	CheckSlot
;	jr	z,SlotSet2
;	ld	a,#FF
;	ld	(SLASEXP),a	; slave slot not usable
;	jr	SlotSet2
SlotSet0:
	pop	af
	cp	1
	jr	nz,SlotSet1
	ld	(MASSLTN),a	; save master slot
	ld	a,2
	ld	(SLASLTN),a	; save slave slot
	call	CheckSlot
	jr	nz,SlotSet2
	ld	a,3
	ld	(SLASLTN),a	; save slave slot
	call	CheckSlot
	jr	nz,SlotSet2
	ld	a,#FF
	ld	(SLASLTN),a	; slave slot not usable
	jr	SlotSet2
SlotSet1:
	cp	2
	jr	nz,SlotSet15	
	ld	(MASSLTN),a	; save master slot
	ld	a,1
	ld	(SLASLTN),a	; save slave slot
	call	CheckSlot
	jr	nz,SlotSet2
	ld	a,3
	ld	(SLASLTN),a	; save slave slot
	call	CheckSlot
	jr	nz,SlotSet2
	ld	a,#FF
	ld	(SLASLTN),a	; slave slot not usable
SlotSet15:
	cp	3
	jr	nz,SlotSet2
	ld	(MASSLTN),a	; save master slot
	ld	a,1
	ld	(SLASLTN),a	; save slave slot
	call	CheckSlot
	jr	nz,SlotSet2
	ld	a,2
	ld	(SLASLTN),a	; save slave slot
	call	CheckSlot
	jr	nz,SlotSet2
	ld	a,#FF
	ld	(SLASLTN),a	; slave slot not usable
SlotSet2:
	ret


; Slot setup screen
;
SlotSetup:
	xor	a
	ld	(SPECRB),a	; special reboot cfg
	ld	(SPECRBS),a	; special reboot subslot cfg
	ld	(SCROLL),a	; temporarily disable scroller

	call	SlotFilter	; identify usable slots
	ld	a,(VDPVER)	; detect if 9938 or later used, don't disable the screen
	or	a
	jr	nz,SSetup1
	call	DISDISP		; disable display

SSetup1:
	ld	hl,(C2BPALM)
	ex	de,hl
	ld	hl,(C2FPALM)
	ld	b,C2FCOLM
	ld	c,#0D
	call	FadeOut		; fade out text

SSetup2:
	call	CLS
	ld	de,#0000
	ld	hl,(C2BPALM)
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
	ld	(SCRHIGH),a
	ld	hl,SlotScr	; print setup screen
	call	print_sp
	ld	a,#18
	ld	(SCRHIGH),a
  else
	ld	hl,SlotScr	; print setup screen
	call	print_sp
  endif

	ld	a,#38		; %00111000
	ld	(CardMDR),a	; set delayed config with SCC enabled
	xor	a
	ld	(CardMDR+#05),a	; no entry for master slot
	ld	(CardMDR+#29),a	; no second slot registers
	ld	(CardMDR+#2A),a	; no second slot registers
	ld	(CardMDR+#2B),a	; no entry for slave slot
	ld	(CardMDR+#2F),a	; no second slot registers

	xor	a
	ld	(SLOTFAD),a	; slot setup screen redraw
	ld	a,1
	ld	(SELITEM),a	; set default selected value
	ld	hl,#130B
	ld	(SETXY),hl

SSetupPr:
	call	HideCur

	ld	hl,#030C
	call    POSIT
	ld	a,(MASSLTN)	; master slot number
	add	'0'
	call	CHPUT_VDP	; print master slot number
	ld	hl,#0311
	call    POSIT
	ld	a,#20
	call	CHPUT_VDP	; clear values for slave slot
	ld	hl,#0312
	call    POSIT
	ld	a,#20
	call	CHPUT_VDP	; clear values for slave slot
	ld	hl,#0313
	call    POSIT
	ld	a,#20
	call	CHPUT_VDP	; clear values for slave slot
	ld	a,(MASSLAV)
	cp	#FF		; slave slot as master's subslot allowed?
	jr	z,SSetup201
	ld	a,4
	ld	(SLASLTN),a	; slave slot enabled in subslot mode
	ld	hl,#0311
	call    POSIT
	ld	a,(MASSLTN)	; master slot number
	add	'0'
	call	CHPUT_VDP	; print master slot number for slave slot
	ld	hl,#0312
	call    POSIT
	ld	a,#1A
	call	CHPUT_VDP	; print dot
	ld	a,(MASSLAV)
	or	a
	jr	nz,SSetup200
	ld	hl,#0313
	call    POSIT
	ld	a,#19
	call	CHPUT_VDP	; print undefined slot number (empty square)
	jr	SSetup21
SSetup200:
	ld	hl,#0313
	call    POSIT
	ld	a,(MASSLAV)
	cp	4
	jr	nz,SSetup200a
	dec	a
SSetup200a:
	add	'0'
	call	CHPUT_VDP	; print slave subslot number
	jr	SSetup21
SSetup201:
	ld	hl,#0312
	call    POSIT
	ld	a,(SLASLTN)	; slave slot number
	cp	#FF		; disabled?
	jr	z,SSetup21
	ld	a,(SLASLTN)
	add	'0'
	call	CHPUT_VDP	; print slave slot number

SSetup21:
	ld	a,(MASSEXP)
	or	a		; master slot expanded?
	jr	nz,SSLoop00
	ld	hl,#060B
	call    POSIT
	ld	hl,Prislot
	call	print		; print master slot message
	ld	b,3
	ld	de,#060C
SSLoop0:
	ex	hl,de
	call    POSIT
	inc	l
	ex	hl,de
	ld	hl,Subempt
	call	print		; print empty lines of master slot
	djnz	SSLoop0

SSLoop00:
	ld	hl,#250A
	call    POSIT
	ld	a,'N'
	call	CHPUT_VDP	; non-expanded flag for master slot

	ld	a,(MASSEXP)
	or	a		; master slot expanded?
	jp	z,SSetup3
	ld	hl,#250A
	call    POSIT
	ld	a,'Y'
	call	CHPUT_VDP	; expanded flag for master slot

	ld	b,4
	ld	de,#060B
SSLoop1:
	ex	hl,de
	call    POSIT
	inc	l
	ex	hl,de
	ld	hl,Subslot
	call	print		; print subslots of master slot
	djnz	SSLoop1

	ld	hl,CardMDR+#28	; module allocation in master slots
	ld	a,(hl)
	push	af
	push	af
	push	af
	push	af

	ld	hl,#0F0B
	call    POSIT
	pop	af
	and	%00000011
	add	'0'
	call	CHPUT_VDP	; print slot number for SCC

	ld	hl,#0F0C
	call    POSIT
	pop	af
	rra
	rra
	and	%00000011
	add	'0'
	call	CHPUT_VDP	; print slot number for IDE
	ld	hl,#130C
	call    POSIT
        ld      hl,Select2
	ld	a,(DUOSLCF)
	bit	5,a		; IDE enabled?
	jr	nz,SSetupPr1
        ld      hl,Select0
SSetupPr1:
	ld	a,(MASSLAV)
	cp	#FF		; subslot for slave slot enabled?
	jr	z,SSetupPr11
	bit	0,a		; subslot assignment enabled?
	jr	z,SSetupPr11
        ld      hl,Select5
SSetupPr11:
	call	print		; print IDE device name

	ld	hl,#0F0D
	call    POSIT
	pop	af
	rra
	rra
	rra
	rra
	and	%00000011
	add	'0'
	call	CHPUT_VDP	; print slot number for RAM
	ld	hl,#130D
	call    POSIT
        ld      hl,Select3
	ld	a,(DUOSLCF)
	bit	6,a		; RAM enabled?
	jr	nz,SSetupPr2
        ld      hl,Select0
SSetupPr2:
	ld	a,(MASSLAV)
	cp	#FF		; subslot for slave slot enabled?
	jr	z,SSetupPr22
	bit	1,a		; subslot assignment enabled?
	jr	z,SSetupPr22
        ld      hl,Select5
SSetupPr22:
	call	print		; print RAM device name

	ld	hl,#0F0E
	call    POSIT
	pop	af
	rra
	rra
	rra
	rra
	rra
	rra
	and	%00000011
	add	'0'
	call	CHPUT_VDP	; print slot number for FMPAC
	ld	hl,#130E
	call    POSIT
        ld      hl,Select4
	ld	a,(DUOSLCF)
	bit	7,a		; FMPAC enabled?
	jr	nz,SSetupPr3
        ld      hl,Select0
SSetupPr3:
	ld	a,(MASSLAV)
	cp	#FF		; subslot for slave slot enabled?
	jr	z,SSetupPr33
	bit	2,a		; subslot assignment enabled?
	jr	z,SSetupPr33
        ld      hl,Select5
SSetupPr33:
	call	print		; print FMPAC device name

SSetup3:
	ld	a,(MASSLTS)	; record for master slot
	cp	#FF
	jr	nz,SSetup31
	ld	hl,#130B
	call    POSIT
        ld      hl,Select0
	call	print		; print empty for SCC device name

SSetup31:
	ld	a,(SLASLTN)
	cp	#FF		; slave slot usable?
	jr	z,SSetup4
	ld	a,(SLASEXP)
	or	a		; slave slot expansion disabled?
	jr	nz,SSLoop33
	ld	hl,#0611
	call    POSIT
	ld	hl,Prislot
	call	print		; print primary slot of the slave slot

	ld	b,3
	ld	de,#0612
SSLoop3:
	ex	hl,de
	call    POSIT
	inc	l
	ex	hl,de
	ld	hl,Subempt
	call	print		; print empty lines of slave slot
	djnz	SSLoop3

	ld	a,(SLASLTS)	; record for slave slot
	cp	#FF		; empty?
	jr	nz,SSLoop33
	ld	hl,#1311
	call    POSIT
        ld      hl,Select0
	call	print		; print select for slave slot

SSLoop33:
	ld	hl,#2510
	call    POSIT
	ld	a,'N'
	call	CHPUT_VDP	; non-expanded flag for slave slot

	ld	a,(SLASEXP)
	or	a		; slave slot expanded?
	jp	z,SSetup4
	ld	hl,#2510
	call    POSIT
	ld	a,'Y'
	call	CHPUT_VDP	; print expanded flag for slave slot

	ld	bc,#0430
	ld	de,#0611
SSLoop2:
	ex	hl,de
	call    POSIT
	ex	hl,de
	ld	hl,Subslot
	call	print		; print subslots of slave slot
	ex	hl,de
	ld	h,#0f
	call    POSIT
	inc	l
	ex	hl,de
	ld	a,c
	call	CHPUT_VDP
	inc	c
	ld	d,#06
	djnz	SSLoop2

SSetup4:
	ld	hl,#2316
	call    POSIT
	ld	a,'N'
	call	CHPUT_VDP	; slave slot not used as master's subslot
	ld	a,#9D
	call	CHPUT_VDP
	ld	hl,#FFFF
	ld	(CSRY),hl
	ld	a,(MASSLAV)
	cp	#FF		; slave slot as master's subslot enabled?
	jr	z,SSetup5
	ld	hl,#2316
	call    POSIT
	ld	a,'Y'
	call	CHPUT_VDP	; slave used as master's subslot
	ld	a,#9D
	call	CHPUT_VDP
	ld	hl,#FFFF
	ld	(CSRY),hl

SSetup5:
	ld	a,(MASSLTS)	; selection for master slot
	or	a		; scc+?
	jr	nz,SSetup51
	ld	hl,#130B
	call    POSIT		; put cursor on first device
	ld	hl,Select1
	call	print		; print device name
	ld	hl,#FFFF
	ld	(CSRY),hl
	jr	SSetup7
SSetup51:
	ld	d,a
	call 	CalcDirPos
	jr	z,SSetup7	; empty record?
	push	ix
	pop	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	de,SORTBUF
	ld	bc,20
	ldir
	xor	a
	ld	(de),a		; copy record name to selected aread
	ld	hl,#130B
	call    POSIT		; put cursor on first <-empty->
	ld	hl,SORTBUF
	call	print		; copy record name
	ld	hl,#FFFF
	ld	(CSRY),hl

SSetup7:
	ld	a,(SLASLTN)
	cp	#FF		; slave slot disabled?
	jr	z,SSetup8
	ld	a,(SLASLTS)	; record for slave slot
	cp	#FF
	jr	nz,SSetup75
	ld	hl,#1311
	call    POSIT		; put cursor on second <-empty->
	ld	hl,Select0
	call	print		; print device name
	ld	hl,#FFFF
	ld	(CSRY),hl
	jr	SSetup8
SSetup75:
	ld	d,a
	call 	CalcDirPos
	jr	z,SSetup8	; empty record?
	push	ix
	pop	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	de,SORTBUF
	ld	bc,20
	ldir
	xor	a
	ld	(de),a		; copy record name to selected area
	ld	hl,#1311
	call    POSIT		; put cursor on first <-empty->
	ld	hl,SORTBUF
	call	print		; copy record name
	ld	hl,#FFFF
	ld	(CSRY),hl

SSetup8:
	call	ShowCur

	ld	a,(SLOTFAD)
	or	a
	jr	nz,SltLoop
	ld	hl,#130B
	ld	(SETXY),hl
	call    POSIT		; put cursor on first <-empty->
	ld	hl,(C2FPALS)
	ex	de,hl
	ld	hl,(C2BPALS)
	ld	b,C2FCOLS
	ld	c,#0D
	call	FadeIn		; fade in text
	ld	a,1
	ld	(SLOTFAD),a	; no more fading
	ld	(SELITEM),a	; first item of master slot selected

	call	ENADISP		; enable display

	call	ShowCur
	
SltLoop:
  if SPC=1
	call	BlinkSym
  endif
	call	KILBUF
	call	KILJOY
	call	KeyJoyDelay	; delay for interface
	call	CHSNS		; wait for key and avoid displaying cursor
	jr	nz,SltL2

	call	JoyCheck	; check joystick action
	or	a
	jr	nz,SltL3	; action detected?
	jr	SltLoop
SltL2:
	call	CHFKEY
	call	CHGET		; wait for a key
SltL3:
  if SPC=1
	push	af
	call	StopBlink
	pop	af
  endif
	cp	27		; ESC
	jp	z,SltEnd
	cp	30		; UP
	jp	z,SltPrevItem
	cp	31		; DOWN
	jp	z,SltNextItem
	cp	32		; SPACE
	jr	z,Slt_Val
	cp	13		; ENTER
	jp	z,SltReset
	cp	28		; RIGHT
	jp	z,SltReset
	cp	29		; LEFT
	jp	z,SltReset
	jp	SltLoop

Slt_Val:
	ld	a,(SELITEM)
	or	a
	jr	nz,Slt_Val1
	ld	a,(MASSEXP)
	or	a		; master slot expanded?
	jr	z,Slt_Val01
	xor	a		; not expanded
	ld	(MASSEXP),a
	ld	a,(DUOSLCF)
	and	%00001111
	or	%00010000
	ld	(DUOSLCF),a	; save slots configuration
	jp	Slt_Val40
Slt_Val01:
	ld	a,#FF		; expanded
	ld	(MASSEXP),a
	ld	a,(DUOSLCF)
	and	%00001111
	or	%11110000	
	ld	(DUOSLCF),a	; slots configuration
	ld	a,(MASSLAV)
	cp	#FF
	jp	z,SSetupPr
	xor	a
	ld	(MASSLAV),a	; enable slave slot as master's subslot
	jp	SSetupPr

Slt_Val1:
	cp	5
	jp	nc,Slt_Val2
	cp	1
	jp	nz,Slt_Val100
	ld	a,(MASSLTS)	; master slot assigment
	cp	#FF		; empty
	jr	z,Slt_Val0F
	or	a		; SCC+?
	jr	nz,Slt_Val030
	ld	ix,#8000	; start from first entry
	ld	d,0
	jr	Slt_Val031
Slt_Val030:
	ld	d,a
	call 	CalcDirPos	; calc dir entry point
Slt_Val031:
	push	ix
	pop	hl
	ld	a,h
	cp	#BF		; 0xBFxx
	jr	nz,Slt_Val0N
	ld	a,l
	cp	#C0		; last entry?
	jr	nc,Slt_Val0E
Slt_Val0N:
	push	de
	ld	de,#40
	add	hl,de		; next entry
	push	hl
	pop	ix
	pop	de
	inc	d
	ld	a,(ix+#01)	; record type
	cp	#FF		; active?
	jr	nz,Slt_Val031
	ld	a,(ix)		; record number
	cp	#FF		; unused/last?
	jr	z,Slt_Val031
	ld	a,(ix+#04)
	and	%11011111
	cp	"C"		; Config entry?
       	jr	z,Slt_Val031
Slt_Val032:
	ld	a,d		; record number
	ld	(MASSLTS),a	; master slot save
	call	HideCur
	jp	SSetup5
Slt_Val0F:
	xor	a
	ld	(MASSLTS),a	; scc+ for master slot
	call	HideCur
	ld	hl,#130B
	call    POSIT
        ld      hl,Select1
	call	print		; print SCC+ device name
	ld	hl,#FFFF
	ld	(CSRY),hl
	jp	SSetup5
Slt_Val0E:
	ld	a,#FF
	ld	(MASSLTS),a	; slave slot empty
	call	HideCur
	ld	hl,#130B
	call    POSIT
        ld      hl,Select0
	call	print		; print select for slave slot
	ld	hl,#FFFF
	ld	(CSRY),hl
	jp	SSetup5

Slt_Val100:
	cp	2
	jr	nz,Slt_Val11
	call	HideCur
	ld	hl,#130C
	call    POSIT
        ld      hl,Select0
	ld	a,(DUOSLCF)
	bit	5,a		; IDE enabled?
	jr	z,Slt_Val102
	push	af
	ld	a,(MASSLAV)
	cp	#FF		; slave slot used as subslot of master?
	jr	z,Slt_Val101
        ld      hl,Select5	; enable slot substitution
	bit	0,a		; assignment enabled?
	jr	nz,Slt_Val1001
	ld	a,%00000001	; enable slot substitution for IDE
	ld	(MASSLAV),a
	call	print		; print substitution
	pop	af
	ld	hl,#FFFF
	ld	(CSRY),hl
	jp	SSetupPr
Slt_Val1001:
	and	%11111110	; disable slot substitution
	ld	(MASSLAV),a
Slt_Val101:
	call	print		; erase the device
	pop	af
	res	5,a		; disable IDE
	ld	(DUOSLCF),a
	ld	hl,#FFFF
	ld	(CSRY),hl
	jp	SSetupPr
Slt_Val102:
	push	af
	call	HideCur
        ld      hl,Select2
	call	print		; erase the device
	pop	af
	set	5,a		; enable IDE
	ld	(DUOSLCF),a
	ld	hl,#FFFF
	ld	(CSRY),hl
	jp	SSetupPr

Slt_Val11:
	cp	3
	jr	nz,Slt_Val13
	call	HideCur
	ld	hl,#130D
	call    POSIT
        ld      hl,Select0
	ld	a,(DUOSLCF)
	bit	6,a		; RAM enabled?
	jr	z,Slt_Val112
	push	af
	ld	a,(MASSLAV)
	cp	#FF		; slave slot used as subslot of master?
	jr	z,Slt_Val111
        ld      hl,Select5	; enable slot substitution
	bit	1,a		; assignment enabled?
	jr	nz,Slt_Val110
	ld	a,%00000010	; enable slot substitution for RAM
	ld	(MASSLAV),a
	call	print		; print substitution
	pop	af
	ld	hl,#FFFF
	ld	(CSRY),hl
	jp	SSetupPr
Slt_Val110:
	and	%11111101	; disable slot substitution
	ld	(MASSLAV),a
Slt_Val111:
	call	print		; erase the device
	pop	af
	res	6,a		; disable RAM
	ld	(DUOSLCF),a
	ld	hl,#FFFF
	ld	(CSRY),hl
	jp	SSetupPr
Slt_Val112:
	push	af
	call	HideCur
        ld      hl,Select3
	call	print		; erase the device
	pop	af
	set	6,a		; enable RAM
	ld	(DUOSLCF),a
	ld	hl,#FFFF
	ld	(CSRY),hl
	jp	SSetupPr

Slt_Val13:
	cp	4
	jr	nz,Slt_Val2
	call	HideCur
	ld	hl,#130E
	call    POSIT
        ld      hl,Select0
	ld	a,(DUOSLCF)
	bit	7,a		; FMPAC enabled?
	jr	z,Slt_Val14
	push	af
	ld	a,(MASSLAV)
	cp	#FF		; slave slot used as subslot of master?
	jr	z,Slt_Val131
        ld      hl,Select5	; enable slot substitution
	bit	2,a		; assignment enabled?
	jr	nz,Slt_Val130
	ld	a,%00000100	; enable slot substitution for FMPAC
	ld	(MASSLAV),a
	call	print		; print substitution
	pop	af
	ld	hl,#FFFF
	ld	(CSRY),hl
	jp	SSetupPr
Slt_Val130:
	and	%11111011	; disable slot substitution
	ld	(MASSLAV),a
Slt_Val131:
	call	print		; erase the device
	pop	af
	res	7,a		; disable FMPAC
	ld	(DUOSLCF),a
	ld	hl,#FFFF
	ld	(CSRY),hl
	jp	SSetupPr
Slt_Val14:
	push	af
	call	HideCur
        ld      hl,Select4
	call	print		; erase the device
	pop	af
	set	7,a		; enable FMPAC
	ld	(DUOSLCF),a
	ld	hl,#FFFF
	ld	(CSRY),hl
	jp	SSetupPr

Slt_Val2:
	cp	5
	jr	nz,Slt_Val3
	ld	a,(MASSLAV)
	cp	#FF		; slave slot used as subslot of master?
	jp	nz,SSetupPr
	ld	a,(SLASEXP)
	or	a		; slave slot expanded?
	jr	z,Slt_Val21
	xor	a		; not expanded
	ld	(SLASEXP),a
	jp	SSetupPr
Slt_Val21:
	ld	a,#FF		; expanded
	ld	(SLASEXP),a
	jp	SSetupPr

Slt_Val3:
	cp	10
	jr	nc,Slt_Val4
	cp	6
	jp	nz,SltLoop
	ld	a,(SLASLTN)
	cp	#FF		; slave slot disabled?
	jp	z,SltLoop
	ld	a,(SLASLTS)	; slave slot assigment
	cp	#FF		; empty?
	jr	nz,Slt_Val30
	ld	ix,#8000	; start from first entry
	ld	d,0
	jr	Slt_Val31
Slt_Val30:
	ld	d,a
	call 	CalcDirPos	; calc dir entry point
Slt_Val31:
	push	ix
	pop	hl
	ld	a,h
	cp	#BF		; 0xBFxx
	jr	nz,Slt_ValN
	ld	a,l
	cp	#C0		; last entry?
	jr	nc,Slt_ValE
Slt_ValN:
	push	de
	ld	de,#40
	add	hl,de		; next entry
	push	hl
	pop	ix
	pop	de
	inc	d
	ld	a,(ix+#01)	; record type
	cp	#FF		; active?
	jr	nz,Slt_Val31
	ld	a,(ix)		; record number
	cp	#FF		; unused/last?
	jr	z,Slt_Val31
	ld	a,(ix+#04)
	and	%11011111
	cp	"K"		; Komani mapper?
       	jr	z,Slt_Val32
	cp	"M"		; MiniROM?
	jr	nz,Slt_Val31
Slt_Val32:
	ld	a,d		; record number
	ld	(SLASLTS),a	; slave slot empty
	call	HideCur
	jp	SSetup7
Slt_ValE:
	ld	a,#FF
	ld	(SLASLTS),a	; slave slot empty
	call	HideCur
	ld	hl,#1311
	call    POSIT
        ld      hl,Select0
	call	print		; print select for slave slot
	ld	hl,#FFFF
	ld	(CSRY),hl
	jp	SSetup7

; move to a different slot (new feature?)

Slt_Val4:
	cp	10
	jp	nz,SltLoop
	ld	a,(MASSLAV)
	cp	#FF		; slave slot enabled as master's subslot?
	jr	nz,Slt_Val40
	xor	a
	ld	(MASSLAV),a	; slave as master's subslot allowed, but empty
	ld	(SLASEXP),a	; slave slot expansion disabled
	ld	a,4
	ld	(SLASLTN),a	; slave slot enabled in subslot mode
	ld	a,#FF
	ld	(MASSEXP),a	; master slot expansion enabled
	ld	a,(DUOSLCF)
	or	%11110000	; enable all devices of master slot
	ld	(DUOSLCF),a
	jp	SSetupPr
Slt_Val40:
	ld	a,#FF
	ld	(MASSLAV),a	; slave as master's subslot not allowed
	xor	a
	ld	(SLASEXP),a	; slave slot expansion disabled
	call	SlotFilter	; identify usable slots to check if secondary slot is found
	call	HideCur
	ld	b,4
	ld	de,#0611
SSLoop4:
	ex	hl,de
	call    POSIT
	inc	l
	ex	hl,de
	ld	hl,Subempt
	call	print		; print empty lines of slave slot
	djnz	SSLoop4
	ld	hl,#2510
	call    POSIT
	ld	a,' '
	call	CHPUT_VDP	; clear expanded flag for slave slot
	jp	SSetupPr

SltPrevItem:
	ld	hl,(SETXY)
	ld	a,(SELITEM)
	ld	b,a
	dec	l		; previous line
SltPrev1:
	or	a		; first item?
	jp	z,SltLoop
	cp	1
	jr	nz,SltPrev11
        ld	h,#25		; point to master slot expansion flag
	jr	SltPrevE
SltPrev11:
	cp	5
	jr	c,SltPrevE
	cp	5		; slave slot expansion flag?
	jr	nz,SltPrev13
	ld	h,#13
	ld	a,(MASSEXP)
	or	a
	jr	z,SltPrev12
	ld	a,b
	dec	l
	jr	SltPrevE
SltPrev12:
	ld	a,2		; point to unexpanded master slot selection device
	ld	l,#0B
	jr	SltPrevE
SltPrev13:
	cp	6		; slave device?
	jr	nz,SltPrev14
	ld	h,#25		; point to slave expansion flag
	jr	SltPrevE
SltPrev14:
	cp	10
	jr	c,SltPrevE
	cp	10		; slave slot expansion flag?
	jp	nz,SltLoop
	ld	h,#13
	ld	a,(SLASLTN)
	cp	#FF		; slave slot disabled?
	jr	z,SltPrev15
	ld	a,(SLASEXP)
	cp	1
	jr	nz,SltPrev145
	ld	a,b
	dec	hl
	jr	SltPrevE
SltPrev145:
	ld	a,7
	ld	l,#11
	jr	SltPrevE
SltPrev15:
	ld	a,(MASSEXP)
	or	a
	jr	nz,SltPrev16
	ld	a,2		; point to unexpanded master slot first selection device
	ld	l,#0B
	jr	SltPrevE
SltPrev16:
	ld	a,5		; point to expanded master slot last selection device
	ld	l,#0E
SltPrevE:
	dec	a		; previous item
	ld	(SETXY),hl
	ld	(SELITEM),a
	call    POSIT		; set cursor to the prevoius position
	jp	SltLoop


SltNextItem:
	ld	hl,(SETXY)
	ld	a,(SELITEM)
	ld	b,a
	inc	l		; next line
SltNext1:
	cp	10		; last item?
	jp	z,SltLoop
	or	a		; first line?
	jr	nz,SltNext2
	ld	h,#13
	jr	SltNextE
SltNext2:
	cp	5
	jr	nc,SltNext5
	ld	a,(MASSEXP)
	or	a		; master slot expanded?
	jr	nz,SltNext3
	ld	a,(SLASEXP)
	or	a		; slave slot disabled?
	jr	nz,SltNext35
	ld	a,(SLASLTN)
	cp	#FF		; slave slot disabled?
	jr	z,SltNext7
	ld	hl,#2510	; point to expanded flag of slave slot
	ld	a,4
	jr	SltNextE
SltNext3:
	ld	a,b
	cp	4		; last device in master slot?
	jr	nz,SltNextE
	ld	a,(SLASLTN)
	cp	#FF		; slave slot disabled?
	jr	nz,SltNext4
SltNext35:
	ld	hl,#2316	; point to slave slot as master's subslot
	ld	a,9
	jr	SltNextE
SltNext4:
	inc	hl
	ld	h,#25		; point to expanded flag of slave slot
	ld	a,b
	jr	SltNextE
SltNext5:
	cp	5		; expansion flag of slave slot?
	jr	nz,SltNext6
	ld	h,#13
	jr	SltNextE
SltNext6:
	cp	10		; last item?
	jp	nc,SltLoop
	ld	a,(SLASEXP)
	cp	1		; slave slot expanded?
	jr	nz,SltNext7
	ld	a,b
	cp	9		; last device on slave slot
	jr	nz,SltNextE
SltNext7:
	ld	hl,#2316	; point to slave slot as master's subslot
	ld	a,9
SltNextE:
	inc	a		; next item
	ld	(SETXY),hl
	ld	(SELITEM),a
	call    POSIT		; set cursor to the next position
	jp	SltLoop

SltReset:
	ld	a,(SLASLTN)	; secondary slot usable?
	cp	#FF
	jr	nz,SltReset00
	ld	a,(MASSLTS)	; master slot selection
	cp	#FF
	jp	z,SltLoop	
SltReset00:
	ld	a,(SLASLTS)	; slave slot selection
	cp	#FF
	jr	nz,SltReset0
	ld	a,(MASSLTS)	; master slot selection
	cp	#FF
	jp	z,SltLoop
SltReset0:
	ld	a,(MASSLAV)	; slave as master's subslot
	or	a		; undefined selection?
	jp	z,SltLoop

	ld	a,%00111000
	ld	(CardMDR),a	; set delayed configuration triggered by JP #0000 + SCC enabled

	call	HideCur
	xor	a
	ld	b,a
	ld	a,(MASSLTN)	; master slot number
	rla
	rla
	rla
	rla
	and	%00110000
	or	b
	ld	b,a
	ld	a,(SLASLTN)	; secondary slot enabled?
	cp	#FF
	jp	z,SltReset6
	ld	a,(SLASLTN)	; slave slot number
	or	b
	ld	b,a
	ld	a,(SLASEXP)	; secondary slot expanded?
	or	a
	jr	z,SltReset1
	ld	a,(DUOSLCF)	; device configuration
	and	%00001111	; remove master slot data
	bit	0,a
	jr	z,SltReset01
	and	%00000000	; zero subslot set
SltReset01:

; Correct subslot number in next version!	

	or	b
	ld	b,a		; b = slots configuration
SltReset1:
	ld	a,(SLASLTS)	; selection for slave slot
	cp	#FF
	jr	z,SltReset6
	or	a
	jr	z,SltReset6
	ld	d,a		; d = slave slot assignment
	push	bc
	call	CalcDirPos	; locate directory record
	pop	bc
	jp	z,SltEnd
	ld	a,(ix+#02)	; starting block
	ld	(CardMDR+#2B),a	; set AddrFr for the slave slot
	xor	a
	ld	(CardMDR+#2F),a	; default shift for mini-ROM in the 64kb block
	ld	a,(ix+#04)	; mapper type

SltReset2:
	cp	"k"		; K4 mapper?
	jr	nz,SltReset3
	ld	a,%01000000
	jr	SltReset5
SltReset3:
	cp	"K"		; K5 mapper?
	jr	nz,SltReset4
	ld	a,%10000000
	jr	SltReset5
SltReset4:
	cp	"M"		; mini-ROM?
	jp	nz,SltEnd
	ld	a,(ix+#3D)	; mini-ROM configuration (shift in block)
	rra
	rra
	rra
	rra
	and	%00000111	; number in block
	push	af
	or	a		; first position in block?
	jr	z,SltReset43
	ld	a,(ix+#3D)	; mini-ROM configuration  (size of ROM)
	and	%000000111
	cp	%000000100	; 8kb
	jr	nz,SltReset41
	pop	af
	jr	SltReset44
SltReset41:	
	cp	%000000101	; 16kb
	jr	nz,SltReset42
	pop	af
	add	a,a
	jr	SltReset44
SltReset42:
	cp	%000000110	; 32kb
	jr	nz,SltReset43
	pop	af
	add	a,a
	add	a,a
	jr	SltReset44
SltReset43:
	pop	af
	xor	a
SltReset44:
	ld	(CardMDR+#2F),a	; shift for mini-ROM in the 64kb block (8kb step)
	xor	a
SltReset5:
	or	b		; merge slot configuration to slave mapper
	ld	b,a		; b = slot configuration + slave mapper
SltReset6:
	ld	a,b
	ld	(CardMDR+#2A),a	; set SCART_SLT for the devices on boot

	ld	a,(DUOSLCF)	; device configuration
	rra
	rra
	rra
	rra
	and	%00001111	; set configuration devices
	ld	b,a
	ld	a,(MASSEXP)
	and	%10000000
	or	b		; set master expansion slot
	bit	2,a
	jr	z,SltReset7
	set	6,a		; enable MMM mapper reading with RAM
	set	4,a		; enable port 3C
SltReset7:
	bit	3,a
	jr	z,SltReset8
	set	5,a		; enable YM2413 with FMPAC
SltReset8:
	ld	(CardMDR+#1E),a	; set MCONF for the devices

	xor	a
	ld	b,a
	ld	a,(SLASLTN)	; secondary slot enabled?
	cp	#FF
	jr	z,SltReset9
	ld	a,(SLASLTS)	; selection for slave slot
	cp	#FF
	jr	z,SltReset9
	set	7,b		; enable second cartridge
	set	6,b		; second cartidge in arbitrary slot
	ld	a,(SLASEXP)	; secondary slot expanded?
	or	a
	jr	z,SltReset9
	set	5,b		; second slot expanded
	set	2,b		; allow to read from #FFFF
SltReset9:
	ld	a,b
	res	4,a		; main cartridge slot untouched!
	ld	(CardMDR+#29),a	; set dual slot config

	ld	a,(SLASLTN)	; secondary slot enabled?
	cp	#FF
	jr	z,SltReset90
	ld	a,(MASSLAV)
	cp	#FF		; slave slot used as subslot of master?
	jr	z,SltReset90
	or	a		; no subslot selected?
	jr	z,SltReset90
	ld	b,a
	ld	c,a
	ld	a,(CardMDR+#29)
	res	6,a		; slave used as subslot of master
	res	5,a		; slave not expanded
	ld	(CardMDR+#29),a
	ld	a,(CardMDR+#2A)
	and	%11110000	; clear bits for slave slot and subslot
	push	af
	ld	a,b
	and	%00000111
	cp	4		; %00000100=4 for FMPAC?
	jr	nz,SltReset9z
	dec	a		; subslot 3
SltReset9z:
	rla			; a = substituted slot
	rla
	ld	b,a		; slave subslot in bits 2,3
	pop	af
	or	b		; adjust subslot number (bits 2,3 = slave subslot in master's slot)
	push	af
	ld	a,(MASSLTN)
	and	%00000011
	ld	b,a		; master slot in bits 0,1
	pop	af
	and	%11111100
	or	b		; set slave slot the same as master
	ld	(CardMDR+#2A),a
	ld	a,c
	bit	2,a		; slave instead of FMPAC enabled?
	jr	z,SltReset9a
	ld	a,(CardMDR+#1E)
	res	3,a
	res	5,a		; disable FMPAC
	ld	(CardMDR+#1E),a	; set MCONF for the devices
	jr	SltReset90
SltReset9a:
	bit	1,a		; slave instead of RAM enabled?
	jr	z,SltReset9b
	ld	a,(CardMDR+#1E)
	res	2,a		; disable RAM
	res	4,a		; disable RAM port 3C
	res	6,a		; disable RAM ports
	ld	(CardMDR+#1E),a	; set MCONF for the devices
	jr	SltReset90
SltReset9b:
	bit	0,a		; slave instead of IDE enabled?
	jr	z,SltReset90
	ld	a,(CardMDR+#1E)
	res	1,a		; disable IDE
	ld	(CardMDR+#1E),a	; set MCONF for the devices

SltReset90:
;	ld	a,(CardMDR+#2A)
;	and	%11000000
;	or	a		; mini ROM?
;	jr	z,SltReset91
;	cp	%01000000	; K4?
;	jr	z,SltReset91
;	ld	a,(CardMDR+#2A)
;	or	%11000000
;	and	%10111111	; set K4/K5 no SCC in slave slot by default (remains in master slot)
;	ld	(CardMDR+#2A),a	; set SCART_SLT for the devices on boot
;SltReset91:
	ld	a,(MASSLTS)	; selection for master slot
	cp	#FF		; empty?
	jr	z,SltReset10
	ld	a,(SLASLTS)	; selection for slave slot
	cp	#FF		; empty?
	jr	z,SltReset10
	ld	d,a
	call	CalcDirPos	; locate directory record for master slot
	jr	z,SltReset94
	ld	a,(ix+#04)	; mapper
	cp	"K"		; K5?
	jr	nz,SltReset94
	ld	a,(CardMDR+#2A)
	or	%11000000	; set K5 with SCC in slave slot
	ld	(CardMDR+#2A),a	; set SCART_SLT for the devices on boot
SltReset94:
	ld	a,(MASSLTS)	; selection for master slot
	or	a		; SCC+?
	jr	nz,SltReset95
;	ld	a,(CardMDR+#2A)
;	and	%11000000
;	or	a		; mini ROM?
;	jr	z,SltReset945
;	cp	%01000000	; K4?
;	jr	z,SltReset945
;	ld	a,(CardMDR+#2A)
;	or	%11000000
;	and	%10111111	; set no SCC in slave slot by default (remains in master slot)
;	ld	(CardMDR+#2A),a	; set SCART_SLT for the devices on boot
;SltReset945:
	ld	hl,SCCplus	; point to SCC Plus configuration entry
	push	hl
	pop	ix
	ld	a,1
	ld	(CardMDR+#1E),a	; save configuration for SCC+
	ld	a,(SLASLTN)	; secondary slot usable?
	cp	#FF
	jr	z,SltReset10
	ld	a,(MASSLAV)
	cp	#FF		; slave slot used as subslot of master?
	jr	z,SltReset10
	ld	a,(CardMDR+#29)
	and	%01111111	; deactivate slave slot if used as subslot of master when SCC+ is set
	ld	(CardMDR+#29),a
	jr	SltReset10

SltReset95:
	ld	d,a
	call	CalcDirPos	; locate directory record
	jr	z,SltEnd
	ld	a,(ix+#02)	; starting block
	ld	(CardMDR+#05),a	; set AddrFr for the master slot

SltReset10:
	ld	hl,(C2BPALS)
	ex	de,hl
	ld	hl,(C2FPALS)
	ld	b,C2FCOLS
	ld	c,#0D
	call	FadeOut		; fade out text

	call	CLS

	ld	a,1
	call	RestEnv		; restore environment (colors, screen) except font

	ld	a,(CardMDR+#1E)	; device configuration
	ld	(SPECRB),a	; special reboot
	ld	a,(CardMDR+#29)	; subslot configuration
	ld	(SPECRBS),a	; special reboot

	push	af
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
;	ld	ix,#0707
	call	MUSSTOP		; stop music
	call	HookOff		; disable hook
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	pop	af
	xor	a
	ld      (MUSSTAT),a	; stop music

	jp	RUN_CR2		; run game from main slot

SltEnd:
	call	HideCur
	ld	a,C2FCOLS
	ld	hl,(C2FPALS)
	call	PALETTE		; set default slot setup palette
	ld	a,C2BCOLS
	ld	hl,(C2BPALS)
	call	PALETTE		; set default slot setup palette
	ld	a,C2FCOLS
	ld	(FORCLR),a
	ld	a,C2BCOLS
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	CHCOLOR		; set default slot setup color
	
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

	ld	hl,(C2BPALM)
	ex	de,hl
	ld	hl,#0000
	ld	b,C2BCOLM
	ld	c,#0D
	call	FadeIn		; fade in background

	ld	a,C2FCOLM
	ld	hl,(C2BPALM)
	call	PALETTE

	ld	a,(CardMDR+#29)
	and	%01111111	; disable second cartridge
	ld	(CardMDR+#29),a

	ld	a,#20		; %00100000
	ld	(CardMDR),a	; set default config

	jp	Pagep


; Show cursor for non-Arabic/non-Korean MSXs
;
ShowCur:
  if SPC=0
	ld	a,1
	ld	(CSRSW),a	; display cursor
	ld	hl,(SETXY)
	call	POSIT		; set cursor to new position
  endif
	ret


HideCur:
	xor	a
	ld	(CSRSW),a	; hide cursor
	ld	hl,(SETXY)
	call	POSIT		; set cursor to new position
	ret


; Stop blinking for Arabic and Korean MSXs
;
StopBlink:
  if SPC=1
	push	hl
	push	de
	push	bc
	ld	hl,#0000
	ld	de,40		; screen width
	ld	a,(SETXY)
	dec	a
	or	a
	jr	z,StopBlink0
	ld	b,a
SB_Loop:
	add	hl,de
	djnz	SB_Loop
StopBlink0:
	ld	a,(SETXY+1)
	dec	a
	ld	e,a
	add	hl,de		; address in VRAM
	ld	a,(CSSYM)	; get symbol under cursor
	call	WRTVRM
	pop	bc	
	pop	de
	pop	hl
	ret
  endif


; Blink symbol under cursor on Arabic and Korean MSXs
;
BlinkSym:
  if SPC=1
	push	hl
	push	de
	push	bc
	ld	hl,#0000
	ld	de,40		; screen width
	ld	a,(SETXY)
	dec	a
	or	a
	jr	z,BlinkSym0
	ld	b,a
BS_Loop:
	add	hl,de
	djnz	BS_Loop
BlinkSym0:
	ld	a,(SETXY+1)
	dec	a
	ld	e,a
	add	hl,de		; address in VRAM
	call	RDVRM
	cp	'_'
	jr	z,BlinkSym1
	ld	(CSSYM),a	; save symbol under cursor
BlinkSym1:
	ld	a,(BLINK)
	ld	b,a
	ld	a,(CSSYM)
	cp 	b
	jr	z,BlinkSym2
	ld	(BLINK),a
	call	WRTVRM
	jr	BlinkSym3
BlinkSym2:	
	ld	a,'_'
	ld	(BLINK),a
	call	WRTVRM
BlinkSym3:
	pop	bc	
	pop	de
	pop	hl
	ret
  endif


; UI setup screen
;
UISetup:
	xor	a
	ld	(SCROLL),a	; temporarily disable scroller
	ld	a,(VDPVER)	; detect if 9938 or later used, don't disable the screen
	or	a
	jr	nz,UISetup1
	call	DISDISP		; disable display

UISetup1:
	ld	hl,(C2BPALM)
	ex	de,hl
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

	ld	a,#21
	call	EERD		; read port setting
	ld	(IOPORT),a

UISetup2:
	ld	hl,#0101
	ld	(SETXY),hl
	call	HideCur
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
	ld	(SCRHIGH),a
	ld	hl,SetupScr	; print setup screen
	call	print_sp
	ld	a,#18
	ld	(SCRHIGH),a
  else
	ld	hl,SetupScr	; print setup screen
	call	print_sp
  endif

        xor	a
	ld	(SELITEM),a

	ld	hl,#1F09
	call    POSIT
	ld	a,' '
	call	CHPUT_VDP	; erase automatic port number
	ld	a,' '
	call	CHPUT_VDP	; erase automatic port number
	ld	a,' '
	call	CHPUT_VDP	; erase automatic port number
	ld	hl,#2409
	call    POSIT
	ld	a,'F'
	call	CHPUT_VDP	; erase automatic port number
	ld	a,(IOPORT)
	cp	#FF
	jr	nz,Set01
	ld	hl,#2409
	call    POSIT
	ld	a,'-'
	call	CHPUT_VDP	; erase port number for auto-set
	ld	a,'-'
	call	CHPUT_VDP	; erase port number for auto-set
	ld	hl,#1F09
	call    POSIT
	ld	a,'#'
	call	CHPUT_VDP	; print hash symbol
	ld	a,'F'
	call	CHPUT_VDP	; print current automatic port number
	ld	a,(ERMSLT)
	and	%00000011
	ld	b,a		; main slot number
	ld	a,#EF
	add	b		; autoset ID port based on slot
	jr	Set011
Set01:
	ld	a,(IOPORT)
Set011:
	sub	#F0
	add	'0'
	call	CHPUT_VDP	; print used port number

	ld	hl,#250A
	call    POSIT
	ld	a,(DUALRST)
	cp	1
	jr	nz,Set0
	ld	a,"Y"
	jr	Set00
Set0:
	ld	a,"N"
Set00:
	call	CHPUT_VDP	; dual-reset Y/N

	ld	hl,#250B
	call    POSIT
	ld	a,(SORT)
	or	a
	jr	z,Set1
	ld	a,"Y"
	jr	Set2
Set1:
	ld	a,"N"
Set2:
	call	CHPUT_VDP	; sorting Y/N

	ld	hl,#250C
	call    POSIT
	ld	a,(EFF)
	or	a
	jr	z,Set3
	ld	a,"Y"
	jr	Set4
Set3:
	ld	a,"N"
Set4:
	call	CHPUT_VDP	; fmpac mono

	ld	hl,#250D
	call    POSIT
	ld	a,(FMMON)
	cp	1
	jr	z,Set3a
	ld	a,"N"
	jr	Set3aa
Set3a:
	ld	a,"Y"
Set3aa:
	call	CHPUT_VDP	; effects Y/N

	ld	hl,#250E
	call    POSIT
	ld	a,(SPD)
	add	'0'
	call	CHPUT_VDP	; speed value

	ld	hl,#250F
	call    POSIT
	ld	a,'0'
	call	CHPUT_VDP	; zero of frequency value
	ld	hl,#240F
	call    POSIT
	ld	a,(FREQ)
	cp	#FF		; ignore?
	jr	nz,Set3aaa
	ld	a,'-'
	call	CHPUT_VDP	; frequency value
	ld	a,'-'
	jr	Set4b
Set3aaa:
	bit	1,a
	jr	nz,Set4a
	ld	a,'6'
	jr	Set4b
Set4a:
	ld	a,'5'
Set4b:
	call	CHPUT_VDP	; frequency value

	ld	hl,#2510
	call    POSIT
	ld	a,(ASDELAY)
	add	"0"
	call	CHPUT_VDP	; autostart delay
	ld	hl,#2511
	call    POSIT
	ld	a,(SLOT3R)
	or	a
	jr	z,Set5
	ld	a,"Y"
	jr	Set6
Set5:
	ld	a,"N"
Set6:
	call	CHPUT_VDP	; slot 3 enable

	ld	hl,#1213
	call    POSIT
	ld	a,(C2FPALM+1)	; menu foreground
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT_VDP	; R value
	ld	hl,#1313
	call    POSIT
	ld	a,(C2FPALM)
	add	'0'
	call	CHPUT_VDP	; G value
	ld	hl,#1413
	call    POSIT
	ld	a,(C2FPALM+1)
	and	%00000111
	add	'0'
	call	CHPUT_VDP	; B value

	ld	hl,#1813
	call    POSIT
	ld	a,(C2BPALM+1)	; menu background
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT_VDP	; R value
	ld	hl,#1913
	call    POSIT
	ld	a,(C2BPALM)
	add	'0'
	call	CHPUT_VDP	; G value
	ld	hl,#1A13
	call    POSIT
	ld	a,(C2BPALM+1)
	and	%00000111
	add	'0'
	call	CHPUT_VDP	; B value

	ld	hl,#1214
	call    POSIT
	ld	a,(C2FPALH+1)	; help foreground
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT_VDP	; R value
	ld	hl,#1314
	call    POSIT
	ld	a,(C2FPALH)
	add	'0'
	call	CHPUT_VDP	; G value
	ld	hl,#1414
	call    POSIT
	ld	a,(C2FPALH+1)
	and	%00000111
	add	'0'
	call	CHPUT_VDP	; B value

	ld	hl,#1814
	call    POSIT
	ld	a,(C2BPALH+1)	; help background
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT_VDP	; R value
	ld	hl,#1914
	call    POSIT
	ld	a,(C2BPALH)
	add	'0'
	call	CHPUT_VDP	; G value
	ld	hl,#1A14
	call    POSIT
	ld	a,(C2BPALH+1)
	and	%00000111
	add	'0'
	call	CHPUT_VDP	; B value

	ld	hl,#1215
	call    POSIT
	ld	a,(C2FPALV+1)	; volume foreground
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT_VDP	; R value
	ld	hl,#1315
	call    POSIT
	ld	a,(C2FPALV)
	add	'0'
	call	CHPUT_VDP	; G value
	ld	hl,#1415
	call    POSIT
	ld	a,(C2FPALV+1)
	and	%00000111
	add	'0'
	call	CHPUT_VDP	; B value

	ld	hl,#1815
	call    POSIT
	ld	a,(C2BPALV+1)	; volume background
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT_VDP	; R value
	ld	hl,#1915
	call    POSIT
	ld	a,(C2BPALV)
	add	'0'
	call	CHPUT_VDP	; G value
	ld	hl,#1A15
	call    POSIT
	ld	a,(C2BPALV+1)
	and	%00000111
	add	'0'
	call	CHPUT_VDP	; B value

	ld	hl,#1216
	call    POSIT
	ld	a,(C2FPALP+1)	; psg foreground
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT_VDP	; R value
	ld	hl,#1316
	call    POSIT
	ld	a,(C2FPALP)
	add	'0'
	call	CHPUT_VDP	; G value
	ld	hl,#1416
	call    POSIT
	ld	a,(C2FPALP+1)
	and	%00000111
	add	'0'
	call	CHPUT_VDP	; B value

	ld	hl,#1816
	call    POSIT
	ld	a,(C2BPALP+1)	; psg background
	and	%11110000
	rra
	rra
	rra
	rra
	add	'0'
	call	CHPUT_VDP	; R value
	ld	hl,#1916
	call    POSIT
	ld	a,(C2BPALP)
	add	'0'
	call	CHPUT_VDP	; G value
	ld	hl,#1A16
	call    POSIT
	ld	a,(C2BPALP+1)
	and	%00000111
	add	'0'
	call	CHPUT_VDP	; B value
	ld	a,#9D
	call	CHPUT_VDP
	ld	hl,#FFFF
	ld	(CSRY),hl

	call	ShowCur

	ld	hl,#2509
	ld	(SETXY),hl	; cursor coordinates
	call    POSIT

	ld	hl,(C2FPALS)
	ex	de,hl
	ld	hl,(C2BPALS)
	ld	b,C2FCOLS
	ld	c,#0D
	call	FadeIn		; fade in text

SetLoop:
	call	ENADISP		; enable display

	call	ShowCur

	ld	hl,(SETXY)
	ld	h,#25
	ld	a,(SELITEM)
	cp	9
	jp	c,SetLoop1
	ld	h,#12
	ld	(SETXY),hl
	call    POSIT

SetColor:
	ld	a,(SELITEM)
	cp	9
	jr	z,SetColorM
	cp	10
	jr	z,SetColorH
	cp	11
	jr	z,SetColorV

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

	call	ShowCur

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
  if SPC=1
	call	BlinkSym
  endif
	call	KILBUF
	call	KILJOY
	call	KeyJoyDelay	; delay for interface
	call	CHSNS		; wait for key and avoid displaying cursor
	jr	nz,CfgL1

	call	JoyCheck	; check joystick action
	or	a
	jr	nz,CfgL2	; action detected?
	jr	SetLoop2
CfgL1:
	call	CHFKEY
	call	CHGET		; wait for a key
CfgL2:
  if SPC=1
	push	af
	call	StopBlink
	pop	af
  endif
	cp	27		; ESC
	jp	z,SetEnd
	cp	30		; UP
	jp	z,PrevItem
	cp	31		; DOWN
	jp	z,NextItem
	cp	32		; SPACE
	jr	z,Set_Val
	cp	29		; LEFT
	jp	z,SetLeft
	cp	28		; RIGHT
	jp	z,SetRight
	cp	11		; HOME
	jp	z,SetReset
	jp	SetLoop2

Set_Val:
	ld	a,(SELITEM)
	or	a
	jr	z,Set_V000
	cp	1
	jp	z,Set_V00
	cp	2
	jp	z,Set_V0
	cp	3
	jp	z,Set_V1
	cp	4
	jp	z,Set_V15
	cp	5
	jp	z,Set_V2
	cp	6
	jp	z,Set_V3
	cp	7
	jp	z,Set_V3A
	cp	8
	jp	z,Set_V3B
	jp	Set_V4


Set_V000:
	ld	hl,#1F09
	call    POSIT
	ld	a,' '
	call	CHPUT_VDP	; erase automatic port number
	ld	a,' '
	call	CHPUT_VDP	; erase automatic port number
	ld	a,' '
	call	CHPUT_VDP	; erase automatic port number
	ld	hl,#FFFF
	ld	(CSRY),hl
	ld	hl,#2409
	call    POSIT
	ld	a,'F'
	call	CHPUT_VDP	; erase automatic port number
	ld	hl,#2509
	call    POSIT
	ld	a,(IOPORT)
	cp	#F2		; F0-F1?
	jr	c,Set_V0A2
	jr	z,Set_V0001
	ld	a,#F0		; next value after auto
	jr	Set_V0A1
Set_V0001:
	ld	a,#FF
	ld	(IOPORT),a	; IO port set to auto
	ld	hl,#1F09
	call    POSIT
	ld	a,'#'
	call	CHPUT_VDP	; print hash symbol
	ld	a,'F'
	call	CHPUT_VDP	; print current automatic port number
	ld	a,(ERMSLT)
	and	%00000011
	ld	b,a		; main slot number
	ld	a,#EF
	add	b		; autoset ID port based on slot
	sub	#F0
	add	'0'
	call	CHPUT_VDP	; print current automatic port number
	ld	hl,#FFFF
	ld	(CSRY),hl
	ld	hl,#2509
	call    POSIT
	ld	a,'-'
	call	CHPUT_VDP	; erase port number
	ld	hl,#FFFF
	ld	(CSRY),hl
	ld	a,'-'
	jp	Set_V30E
Set_V0A1:
	ld	(IOPORT),a	; IO port
	sub	#F0
	add	'0'
	jp	Set_VE
Set_V0A2:
	inc	a		; increase port number
	jr	Set_V0A1

Set_V00:
	ld	a,(DUALRST)
	cp	1
	jr	nz,Set_V001
	xor	a
	ld	(DUALRST),a	; no dual reset
	ld	a,"N"
	jp	Set_VE
Set_V001:
	ld	a,1	
	ld	(DUALRST),a	; dual reset
	ld	a,"Y"
	jp	Set_VE

Set_V0:
	ld	a,(SORT)
	or	a
	jr	z,Set_V01
	xor	a
	ld	(SORT),a	; no sorting
	ld	a,"N"
	jp	Set_VE
Set_V01:
	ld	a,1	
	ld	(SORT),a	; sorting on
	ld	a,"Y"
	jp	Set_VE

Set_V1:
	ld	a,(EFF)
	or	a
	jr	z,Set_V11
	xor	a
	ld	(EFF),a		; no effects
	ld	a,"N"
	jp	Set_VE
Set_V11:
	ld	a,1	
	ld	(EFF),a		; with effects
	ld	a,"Y"
	jp	Set_VE

Set_V15:
	ld	a,(FMMON)
	cp	1
	jr	z,Set_V115
	ld	a,1
	ld	(FMMON),a	; fmpac mono
	ld	a,"Y"
	jp	Set_VE
Set_V115:
	xor	a
	ld	(FMMON),a	; fmpac stereo
	ld	a,"N"
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
	ld	a,(FREQ)
	cp	#FF		; ignore
	jr	nz,Set_V31
	ld	a,(ORGVR10)	; get original value
	set	1,a
	ld	(FREQ),a	; set PAL
	ld	hl,#250F
	call    POSIT
	ld	a,'0'
	call	CHPUT_VDP	; zero of frequency value
	ld	hl,#FFFF
	ld	(CSRY),hl
	ld	a,'5'
	jr	Set_V30E
Set_V31:
	bit	1,a
	jr	nz,Set_V30
	ld	a,#FF
	ld	(FREQ),a	; set ignore
	ld	hl,#250F
	call    POSIT
	ld	a,'-'
	call	CHPUT_VDP	; zero of frequency value
	ld	hl,#FFFF
	ld	(CSRY),hl
	ld	a,'-'
	jr	Set_V30E
Set_V30:
	ld	a,(ORGVR10)	; get original value
	res	1,a
	ld	(FREQ),a	; set NTSC
	ld	hl,#250F
	call    POSIT
	ld	a,'0'
	call	CHPUT_VDP	; zero of frequency value
	ld	hl,#FFFF
	ld	(CSRY),hl
	ld	a,'6'
Set_V30E:
	push	af
	ld	hl,(SETXY)
	dec	h
	call    POSIT
	pop	af
	call	CHPUT_VDP	; put new setting
	ld	hl,#FFFF
	ld	(CSRY),hl
	ld	hl,(SETXY)
	call    POSIT
	jp	SetLoop2

Set_V3A:
	ld	a,(ASDELAY)
	cp	9		; max?
	jr	c,Set_V3A2
	xor	a		; reset autostart delay
Set_V3A1:
	ld	(ASDELAY),a
	add	'0'
	jp	Set_VE
Set_V3A2:
	inc	a		; increase autostart delay
	jr	Set_V3A1

Set_V3B:
	ld	a,(SLOT3R)
	or	a
	jr	z,Set_V3B1
	xor	a
	ld	(SLOT3R),a	; slot 3 not alowed
	ld	a,"N"
	jp	Set_VE
Set_V3B1:
	ld	a,1	
	ld	(SLOT3R),a	; slot 3 allowed
	ld	a,"Y"
	jp	Set_VE

Set_V4:
	ld	hl,C2FPALM-4
	ld	a,(SELITEM)
	sub	8
	ld	b,a
Set_V4A:
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	djnz	Set_V4A		; find appropriate color area
	ex	de,hl
	ld	hl,(SETXY)
	ld	a,h
	cp	#12		; R
	jr	z,Set_V41
	cp	#13		; G
	jr	z,Set_V40
	cp	#14		; B
	jr	z,Set_V42
	inc	de
	inc	de		; point to background
	cp	#18		; R
	jr	z,Set_V41
	cp	#1A		; B
	jr	z,Set_V42

Set_V40:
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
	call	CHPUT_VDP	; print G value
	ld	hl,#FFFF
	ld	(CSRY),hl
	ld	hl,(SETXY)
	call    POSIT
	jp	SetColor

Set_V41:
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
	call	CHPUT_VDP	; print R value
	ld	hl,#FFFF
	ld	(CSRY),hl
	ld	hl,(SETXY)
	call    POSIT
	jp	SetColor

Set_V42:
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
	call	CHPUT_VDP	; print B value
	ld	hl,#FFFF
	ld	(CSRY),hl
	ld	hl,(SETXY)
	call    POSIT
	jp	SetColor

Set_VE:
	push	af
	ld	hl,(SETXY)
	call    POSIT
	pop	af
	call	CHPUT_VDP	; put new setting
	ld	hl,#FFFF
	ld	(CSRY),hl
	ld	hl,(SETXY)
	call    POSIT
	jp	SetLoop2

SetLeft:
	ld	a,(SELITEM)
	cp	9
	jp	c,SetLoop2
	ld	hl,(SETXY)
	ld	a,h
	cp	#12
	jr	z,SetLeft1
	dec	a
	cp	#17
	jr	nz,SetLeft0
	sub	3
SetLeft0:
	ld	h,a
	ld	(SETXY),hl
	call    POSIT
	jp	SetLoop2
SetLeft1:
	ld	h,#1A
	ld	(SETXY),hl
	call    POSIT
	jp	SetLoop2

SetRight:
	ld	a,(SELITEM)
	cp	9
	jp	c,SetLoop2
	ld	hl,(SETXY)
	ld	a,h
	cp	#1A
	jr	z,SetRight1
	inc	a
	cp	#15
	jr	nz,SetRight0
	add	3
SetRight0:
	ld	h,a
	ld	(SETXY),hl
	call    POSIT
	jp	SetLoop2
SetRight1:
	ld	h,#12
	ld	(SETXY),hl
	call    POSIT
	jp	SetLoop2

NextItem:
	ld	hl,(SETXY)
	ld	a,(SELITEM)
	ld	a,(VDPVER)	; detect if 9918 is used, skip palette operations then
	or	a
	jr	nz,NextItem0
	ld	a,(SELITEM)
	cp	8		; last non-color item?
	jr	z,NextItem2
NextItem0:
	ld	a,(SELITEM)
	cp	#0C		; max item?
	jr	z,NextItem2
NextItem1:
	inc	a
	inc	l
	ld	(SELITEM),a
	cp	9
	jr	nz,NextItem1a
	inc	l
NextItem1a:
	ld	(SETXY),hl
NextItem2:
	jp	SetLoop

PrevItem:
	ld	hl,(SETXY)
	ld	a,(SELITEM)
	or	a		; min item?
	jp	z,PrevItem2
PrevItem1:
	dec	a
	dec	l
	ld	(SELITEM),a
	cp	8
	jr	nz,PrevItem1a
	dec	l
PrevItem1a:
	ld	(SETXY),hl
PrevItem2:
	jp	SetLoop

SetReset:
	call	HideCur
	ld	hl,#2509
	call    POSIT
	ld	hl,SORTD
	ld	de,SORT
	ld	bc,25
	ldir			; reset all settings to defaults
	ld	a,#FF
	ld	(IOPORT),a	; default setting
	call	CLS
	ld	a,(VDPVER)	; detect if 9938 or later used, don't disable the screen
	or	a
	jp	nz,UISetup2
	call	DISDISP		; disable display
	jp	UISetup2

SetEnd:
	call	HideCur
	ld	a,%01100000	; write enable
	call	EEWEN

	ld	a,4
	call	EERD		; read original sorting flag
	ld	b,a
	ld	a,(SORT)
	cp	b		; sorting status changed?
	jp	z,SetEnd0

	ld	a,#FF
	ld	(MASSLTS),a	; nothing selected for master slot
	ld	(SLASLTS),a	; nothing selected for slave slot
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
	ld	a,#FF
	ld	(AUTOST),a	; no autostart
	ld	e,a             ; data
	ld	a,#1C		; address
	call	EEWR		; save autostart
	ld	a,#FF
	ld	(LASTU),a	; erase last used
	ld	e,a             ; data
	ld	a,#1A		; address
	call	EEWR		; save last used entry to EEPROM

SetEndHm:
	ld	de,#0000
	ld	(DIRPOS),de	; positions (d=entry number, e=position on page)
	ld	hl,#0001
	ld	(CURPAG),hl	; set page 1 after sorting mode change

SetEnd0:
	ld	a,(FREQ)
	ld	e,a             ; data
	ld	a,#2		; address
	call	EEWR		; save frequency to EEPROM
	ld	a,(SORT)
	ld	e,a             ; data
	ld	a,#4		; address
	call	EEWR		; save sort to EEPROM
	ld	a,(EFF)
	ld	e,a             ; data
	ld	a,#5		; address
	call	EEWR		; save effects to EEPROM
	ld	a,(SPD)
	ld	e,a             ; data
	ld	a,#6		; address
	call	EEWR		; save speed to EEPROM
	ld	a,(DUALRST)
	ld	e,a             ; data
	ld	a,#18		; address
	call	EEWR		; save dual-reset to EEPROM
	ld	a,(ASDELAY)
	ld	e,a             ; data
	ld	a,#1F		; address
	call	EEWR		; save autostart delay
	ld	a,(SLOT3R)
	ld	e,a             ; data
	ld	a,#20		; address
	call	EEWR		; save slot 3 enable flag

	ld	a,(IOPORT)
	ld	e,a             ; data
	ld	a,#21		; address
	call	EEWR		; save IO port number
	ld	a,(IOPORT)
	cp	#FF
	jr	nz,SetEnd000
	ld	a,(ERMSLT)
	and	%00000011
	ld	b,a		; main slot number
	ld	a,#EF
	add	b		; autoset ID port based on slot
	ld	(IOPORT),a
SetEnd000:
	ld	(CardMDR+#35),a	; set new control port

	ld	a,(FMMON)
	push	af
	ld	e,a             ; data
	ld	a,#19		; address
	call	EEWR		; save FMPAC mono status
	pop	af
	cp	1
	jr	z,SetEnd00a
	ld	a, (CardMDR+#22)
	and	%01111111
	ld	(CardMDR+#22),a	; enable FMPAC mono
	jr	SetEnd00b
SetEnd00a:
	ld	a, (CardMDR+#22)
	or	%10000000
	ld	(CardMDR+#22),a	; disable FMPAC mono

SetEnd00b:
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
	ei
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
	ei
	ret


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
	ld	b,a
	ld	a,(SCROLL)
	push	af
	xor	a
	ld	(SCROLL),a	; stop scroller
	ld	(SCRSEM),a	; reset semaphore
	ld	(SYMSEM),a	; reset symbol semaphore
	ld	a,b
	ld	(PALNTSC),a
	push	af

; Fade out font and background
	ld	hl,(C2BPALM)
	ex	de,hl
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

	pop	af
	ld	b,a
	ld	a,9
	ld	c,a
	call	WRITVDP		; write to VDP register (set 50 or 60 HZ mode)

; Set screen after change of frequency
	ld	a,40
	ld	(SCR0WID),a	; set default width of screen0
	xor	a
	call	SSCREEN
	call	MODE40A
	call	CLS
	call	SetFont		; set font

	call	ScrollInit	; initialize data for scroller
	pop	af
	ld	(SCROLL),a	; restore scroller status

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


; Set FMPAC/SCC/SCC+ volume screen
;
SetVolume:
	xor	a
	ld	(SCROLL),a	; temporarily disable scroller

	ld	a,(VDPVER)	; detect if 9938 or later used, don't disable the screen
	or	a
	jr	nz,SetVol1
	call	DISDISP		; disable display

SetVol1:
	ld	hl,(C2BPALM)
	ex	de,hl
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
	ld	(SCRHIGH),a
	ld	hl,VolumeScr	; print volume control screen
	call	print_sp
	ld	a,#18
	ld	(SCRHIGH),a
  else
	ld	hl,VolumeScr	; print volume control screen
	call	print_sp
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

Wait2:
	call	KILBUF
	call	KILJOY
	call	KeyJoyDelay	; delay for interface
	call	CHSNS		; wait for key and avoid displaying cursor
	jr	nz,Wait2a

	call	JoyCheck	; check joystick action
	or	a
	jr	nz,Wait2b	; action detected?
	jr	Wait2
Wait2a:
	call	CHFKEY
	call	CHGET		; wait for a key
Wait2b:
	cp	27		; ESC
	jp	z,VolEnd
	cp	32		; SPACE
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


; Set PSG volume screen
;
PSGVolume:
	xor	a
	ld	(SCROLL),a	; temporarily disable scroller

	ld	a,(VDPVER)	; detect if 9938 or later used, don't disable the screen
	or	a
	jr	nz,SetPSG1
	call	DISDISP		; disable display

SetPSG1:
	ld	hl,(C2BPALM)
	ex	de,hl
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
	ld	(SCRHIGH),a
	ld	hl,PSGScr	; print PSG control screen
	call	print_sp
	ld	a,#18
	ld	(SCRHIGH),a
  else
	ld	hl,PSGScr	; print PSG control screen
	call	print_sp
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
	ld	hl,#0904
	call    POSIT	
	ld	a,OffSym
	call	CHPUT_VDP	; mark device as disabled
	ld	a,(CardMDR+#24)
	bit	7,a
	jr	z,PSGPrn3
	ld	hl,#0904
	call    POSIT	
	ld	a,OnSym
	call	CHPUT_VDP	; mark device as enabled
PSGPrn3:
	ld	hl,#1604
	call    POSIT	
	ld	a,OffSym
	call	CHPUT_VDP	; mark device as disabled
	ld	a,(CardMDR+#24)
	bit	6,a
	jr	z,PSGPrn4
	ld	hl,#1604
	call    POSIT	
	ld	a,OnSym
	call	CHPUT_VDP	; mark device as enabled
PSGPrn4:
	ld	hl,#2404
	call    POSIT	
	ld	a,OffSym
	call	CHPUT_VDP	; mark dual option as disabled
	ld	a,(CardMDR+#30)
	bit	0,a
	jr	z,PSGLoop
	ld	hl,#2404
	call    POSIT	
	ld	a,OnSym
	call	CHPUT_VDP	; mark dual option as enabled

PSGLoop:
	call	ENADISP		; enable display

Wait3:
	call	KILBUF
	call	KILJOY
	call	KeyJoyDelay	; delay for interface
	call	CHSNS		; wait for key and avoid displaying cursor
	jr	nz,Wait3a

	call	JoyCheck	; check joystick action
	or	a
	jr	nz,Wait3b	; action detected?
	jr	Wait3
Wait3a:
	call	CHFKEY
	call	CHGET		; wait for a key
Wait3b:
	cp	27		; ESC
	jp	z,PSGEnd
	cp	30		; UP
	jp	z,PSG_UP
	cp	31		; DOWN
	jp	z,PSG_DOWN
	cp	28		; RIGHT
	jp	z,CLKR_UP
	cp	29		; LEFT
	jp	z,CLKR_DOWN
	cp	9		; LEFT
	jr	z,DualPSG
	cp	11		; HOME
	jp	z,PSGReset
	cp	32		; Space
	jr	z,PSG_ED
	cp	13		; Enter
	jr	z,CLKR_ED
	jr	PSGLoop

PSG_ED:
	ld	a,(MUSSTAT)
	or	a
	jr	z,PSG_ED0
;	ld	ix,#0707
	call	MUSSTOP		; stop music
	xor	a
	ld      (MUSSTAT),a	; stop music
PSG_ED0:
	ld	a,(CardMDR+#24)
	bit	7,a
	jr	z,PSG_ED1
	res	7,a
	push	af
	ld	a,(CardMDR+#30)
	res	0,a		; disable dual PSG
	ld	(CardMDR+#30),a
	pop	af
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

DualPSG:
	ld	a,(CardMDR+#24)
	bit	7,a			; PSG enabled?
	jp	z,PSGStPr
	ld	a,(CardMDR+#30)
	bit	0,a			; Dual PSG enabled?
	jr	z,DualPSG1
	res	0,a			; disable Dual PSG
	jr	DualPSG2
DualPSG1:
	set	0,a			; enable Dual PSG
DualPSG2:
	push	af
	ld	a,(MUSSTAT)
	or	a
	jr	z,DualPSG3
;	ld	ix,#0707
	call	MUSSTOP		; stop music
	xor	a
	ld      (MUSSTAT),a	; stop music
DualPSG3:
	pop	af
	ld	(CardMDR+#30),a		; enable/disable dual psg
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
	ld	a,(MUSSTAT)
	or	a
	jr	z,PSGReset1
;	ld	ix,#0707
	call	MUSSTOP		; stop music
	xor	a
	ld      (MUSSTAT),a	; stop music
PSGReset1:
        ld	hl,DefPSG	; default volume and configuration for PSG and Clicker
	ld	a,(hl)
	ld	(CardMDR+#24),a
	ld	a,(CardMDR+#30)
	res	0,a		; dual PSG off by default
	ld	(CardMDR+#30),a

	jp      PSGPrint


PSGEnd:
	ld	a,%01100000	; write enable
	call	EEWEN

	ld	a,(CardMDR+#30)
	ld	e,a             ; data
	ld	a,#1E		; address
	call	EEWR		; save Dual-PSG flag to EEPROM

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


; Delay subroutine for joystick
;
KeyJoyDelay:
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


; Check for and enable double reset on cold boot
;
DualReset:
        ld      a,(ERMSLT)
        ld      h,#40
        call    ENASLT

	xor	a
	ld	(CardMDR+#0E),a	; R2Reg
	ld	(CardMDR+#05),a	; AddrFr
	ld	a,(CardMDR+#0F)	; R2Mult
	push	af
	ld	a,#34		; RAM instead of ROM, Bank write enabled, 8kb pages, control off
	ld	(CardMDR+#0F),a	; R2Mult

        ld      a,(ERMSLT)
        ld      h,#80
        call    ENASLT 

	ld	hl,#8010	; RAM
	ld	de,Label	; boot menu label
	ld	bc,8
DualRL:
	ex	hl,de
	ld	a,(hl)		; Compare RAM to C2's label
	ex	hl,de
	cpi
	jr	nz,DualRR
	inc	de
	ld	a,c
	or	a		; All 8 bytes match?
	jr	nz,DualRL

DualNR:
	pop	af
	ld	(CardMDR+#0F),a	; R2Mult
	xor	a		; do not reset
	ret	

DualRR:
	ld	de,#8010	; RAM
	ld	hl,Label	; boot menu label
	ld	bc,8
	ldir			; Save label to RAM for warm reset
	pop	af
	ld	(CardMDR+#0F),a	; R2Mult
	ld	a,1		; reset
	ret	

;
; Various screens
;

; Default variables for colors and settings
SORTD	db	0		; sorting disabled
EFFD	db	0		; effects off
FMMOND	db	0		; FMPAC mode = stereo
SPDD	db	1		; default delay = 1
FRQD	db	#FF		; frequency forcing off
DUALRD	db	1		; dual reset enabled
ADELAYD	db	3		; default autostart delay
SLOT3RD	db	0		; allow to run in slot 3
IOPORTD	db	#FF		; default setting = based on slot

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

OnSym	equ	#9C
OffSym	equ	#9E

Spaces:
	db	"  ",0
PALmsg:
	db	#9F,"50Hz",#96,"Z80",#9D,0
NTSCmsg:
	db	#9F,"60Hz",#96,"Z80",#9D,0

CRLF:	db	10,13,10,13,0

AutoDot:
	db	".",0
ResetCMSG:
	db	"New configuration applied.",10,13,"Rebooting MSX...",0
ResetMSG:
	db	"Necessary changes applied.",10,13,"Rebooting MSX...",0

PageNum:
	db	#9F,"  ",#96,"  ",#9D,0

DefMode:
	db	"Z80",0
T2PMode:
	db	"T2+",0
RTRMode:
	db	"R8x",0

Select0	db	"<- Empty ->        ",0
Select1	db	"Konami SCC+        ",0
Select2	db	"IDE (CF card)      ",0
Select3	db	"RAM 1024Kb         ",0
Select4	db	"FMPAC + SRAM       ",0
Select5	db	"<- Slave Slot ->   ",0

Subslot	db	"SubSlot ",#9F,#20,#9D,":",0
Prislot	db	"PriSlot ",#9B,#9C,#9D,":",0

Subempt	db	#FF,33,#20,0

Sccplsel
	db	"++",0

VolumeL:
  if SPC=0
	db	#9F,"FMP",#A5,"1",#96,"SCC",#A5,"1",#96,"PSG",#A5,"1",#9D,0
  else
	db	#9F,"FMP:1",#96,"SCC:1",#96,"PSG:1",#9D,0
  endif

VolumeInd:
	db	#FF,4,#98,0,0
IndEmpty1:
  if SPC=0
	db	#FF,32,#A6,0
  else
	db	#FF,32,#1B,0
  endif
IndEmpty2:
	db	#FF,32,#5E,0

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


; SCC+ configuration
SCCplus
	db	#35,#ff,#00,#00,#43,#53,#43,#43,#20,#50,#6c,#75,#73,#20,#20,#20
	db	#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20,#20
	db	#20,#20,#20,#f8,#50,#00,#b4,#ff,#40,#f8,#70,#01,#b4,#ff,#60,#f8
	db	#90,#02,#b4,#ff,#80,#f8,#b0,#03,#b1,#01,#a0,#01,#b8,#00,#01,#ff
;	db	#f8,#50,#00,#b4,#ff,#40
;	db	#f8,#70,#01,#b4,#ff,#60
;	db	#f8,#90,#02,#b4,#ff,#80
;	db	#f8,#b0,#03,#b1,#01,#a0
;	db	#01,#b8,#00,#01,#ff

; Patterns for detecting Arabit and Korean MSXs
Arabic
	db	#00,#00,#0F,#06,#FB,#00,#00,#00
	db	#00,#00,#3C,#18,#2F,#40,#3E,#00

Korean
	db	#7C,#04,#7C,#40,#7C,#10,#FE,#00
	db	#7C,#04,#7C,#40,#7C,#28,#FE,#00

; Patterns for detecting Russian network modules
Net1ID
	db	#41,#42,#e9,#51,#50,#41,#fc,#41
Net2ID
	db	#41,#42,#53,#41,#e1,#45,#00,#00

  if SPC=1
; BIOS envelope routines for Korean and Arabic MSXs
GTSTCK_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#00D5
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

GTTRIG_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#00D8
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

RDBTST_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#017A
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

CHGCPU_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#0180
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

GETCPU_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#0183
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

CHSNS_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#009C
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

DISDISP_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#0041
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

ENADISP_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#0044
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

WRITVDP_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#0047
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

KILBUF_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#0156
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

DISKEYS_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#00CC
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

ENAKEYS_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#00CF
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

CHCOLOR_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#0062
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

MODE40A_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#006C
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

MODE40_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#0078
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

SSCREEN_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#005F
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

CHGET_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#009F
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

CLEARS_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#00C3
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

;CHPUT_E:
;	push	hl
;	push	de
;	push	bc
;	push	ix
;;	push	iy
;	call	#00A2
;;	pop	iy
;	pop	ix
;	pop	bc
;	pop	de
;	pop	hl
;	ret

RDSLT_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#000C
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

WRSLT_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#0014
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

ENASLT_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#0024
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

POSIT_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#00C6
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret
  endif


GTTRIGG:
	push	hl
	push	de
	push	bc
	call	GTTRIG		; joystick 1 button A
	pop	bc
	pop	de
	pop	hl
	ret

RDVRM_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#004A		; read VRAM
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

WRTVRM_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#004D		; write VRAM
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

FILVRM_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#0056		; fill VRAM
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

LDIRVM_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#005C		; block copy to VRAM
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

LDIRMV_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#0059		; block copy from VRAM
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret

PSGINI_E:
	push	hl
	push	de
	push	bc
	push	ix
;	push	iy
	call	#0090		; PSG init
;	pop	iy
	pop	ix
	pop	bc
	pop	de
	pop	hl
	ret


; BIOS call envelope for Korean and Arabic machines (shadow registers get corrupted on BIOS calls!
; Bios Calls
  if SPC=0
RDSLT	equ	#000C
WRSLT	equ	#0014
ENASLT	equ	#0024
;CHPUT	equ	#00A2
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
WRTVRM	equ	#004D
RDVRM	equ	#004A
FILVRM	equ	#0056
LDIRVM	equ	#005C
LDIRMV	equ	#0059
PSGINI	equ	#0090

  else
WRSLT	equ	WRSLT_E
RDSLT	equ	RDSLT_E
ENASLT	equ	ENASLT_E
;CHPUT	equ	CHPUT_E
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
WRTVRM	equ	WRTVRM_E
RDVRM	equ	RDVRM_E
FILVRM	equ	FILVRM_E
LDIRVM	equ	LDIRVM_E
LDIRMV	equ	LDIRMV_E
PSGINI	equ	PSGINI_E

  endif


;
; EXTRA DATA AREA for one-time use, will be loaded from 7th 8kb block from FlashROM
;	

	org	#8000

; Title screen
;
TitleScr:
; Thick frame
;	db	#80,#FF,19,#85,#81,0
;	db	#86," ",#A7,"  CARNIVORE 2  ",#0F," ",#87,0	; inverse name
;;	db	#86,"    CARNIVORE 2    ",#87,0
;	db	#86," ",#FF,17,#9A," ",#87,0
;	db	#86," Boot Menu : v .   ",#87,0
;	db	#86,"  Firmware : v .   ",#87,0
;	db	#82,#FF,19,#84,#83,0

; Thin frame
	db	#88,#FF,19,#8A,#8F,0
	db	#8C,"   ",#A7,"           ",#0F,"   ",#8D,0	; inverse name for animation
;	db	#8C,"   ",#A7,"CARNIVORE 2",#0F,"   ",#8D,0	; inverse name
;	db	#8C,"    CARNIVORE 2    ",#8D,0
	db	#8C," ",#FF,17,#9A," ",#8D,0
	db	#8C," Boot Menu : v .   ",#8D,0
	db	#8C,"  Firmware : v .   ",#8D,0
	db	#8E,#FF,19,#8B,#89,0

TitleScrl
	db 	"C"+#80,"A"+#80,"R"+#80,"N"+#80,"I"+#80,"V"+#80,"O"+#80,"R"+#80,"E"+#80,#DC
TitleRepl
	db	#E0,#E1,#E2,#E3,#E4,#E5,#E6,#E7,#E8,#97,#E9,0
InvSpace
	db	#FF,#FF,#FF,#FF,#FF,#FF,#FF

Haltmsg:
	db	"Unusable slot! System Halted!",0

AutoMSG:
	db	"    Auto-Start in   seconds...",10,13,10,13
	db	"    Press ",#A7,"ESC",#0F,", ",#A7,"TAB",#0F,", ",#A7,"F4",#0F," or hold ",10,13
	db	"  any joystick button for Boot Menu..."
	db	0

  if SPC=0
AltKormsg:
	db	"   Korean or Arabic MSX detected!",10,13,10,13
	db	"    The current Boot Menu version is",10,13
	db	"   incompatible and will be bypassed.",10,13,10,13
	db	"  Resuming booting in a few seconds..."
	db	0
  endif

Netmsg:
	db	"  KYBT/KYBT2 network module found!",10,13,10,13
	db	"    Remove network module to prevent",10,13
	db	"  conflicts with Carnivore2 cartridge.",10,13,10,13
	db	"             System halted!"
	db	0

MainScr:
	db	#88,#FF,38,#8A,#8F
	db	#8C,"  Carnivore 2 MFC ",#96," ",#A8,#A9," RBSC ",#96," Help",#A5,#92,#91,#20,#8D
	db	#8C,"  ",#FF,34,#9A,"  ",#8D
	db	#8C,"  Slots",#A5,#90,#91," Config",#A5,#A8,#91," Volume",#A5,#93,#91," PSG",#A5,#99,#91," ",#8D
	db	#8C,"  Auto-Start:",#9F,#20,#20,#9D," ",#96," Dual-Slot:",#9F,"  ",#96,"  ",#9D," ",#8D
	db	#8C,"  ",#FF,34,#9A,"  ",#8D
  if SPC=0
	db	#8C,#AA,#FF,36,#20,#AF,#8D
  else
	db	#8C,#10,#FF,36,#20,#12,#8D
  endif
	db	#8C,#7E,#FF,36,#20,#B0,#8D
	db	#8C,#7E,#FF,36,#20,#B0,#8D
	db	#8C,#7E,#FF,36,#20,#B0,#8D
	db	#8C,#7E,#FF,36,#20,#B0,#8D
	db	#8C,#7E,#FF,36,#20,#B0,#8D
	db	#8C,#7E,#FF,36,#20,#B0,#8D
	db	#8C,#7E,#FF,36,#20,#B0,#8D
	db	#8C,#7E,#FF,36,#20,#B0,#8D
	db	#8C,#7E,#FF,36,#20,#B0,#8D
	db	#8C,#7E,#FF,36,#20,#B0,#8D
	db	#8C,#7E,#FF,36,#20,#B0,#8D
	db	#8C,#7E,#FF,36,#20,#B0,#8D
	db	#8C,#7E,#FF,36,#20,#B0,#8D
	db	#8C,#7E,#FF,36,#20,#B0,#8D
  if SPC=0
	db	#8C,#AE,#FF,36,#20,#AB,#8D
  else
	db	#8C,#16,#FF,36,#20,#14,#8D
  endif
	db	#8E,#FF,38,#8B,#89
	db	0

SlotScr:
	db	#88,#FF,38,#8A,#8F
	db	#8C,"  Carnivore 2 MFC ",#96," Dual-Slot Setup   ",#8D
	db	#8C,"  ",#FF,34,#9A,"  ",#8D
	db	#8C," Use cursor keys. Action Keys:",#FF,8,#20,#8D
	db	#8C,#20,#AA,#A7,"ESC",#0F," - cancel & exit to main menu  ",#8D
	db	#8C,#20,#7E,#A7,"SPACE",#0F," - change or toggle setting  ",#8D
	db	#8C,#20,#7E,#FF,10,#20,"select ROM or SCC+ mode   ",#8D
	db	#8C,#20,#AE,#A7,"ENTER",#0F," - apply changes and restart ",#8D
	db	#8C,#FF,38,#20,#8D
	db	#8C,#88,#8A,"  Master Slot",#FF,12,#20,"Expand ",#9F,#20,#9D,#20,#8D
  if SPC=0
       	db	#8C,#8C,#20,#20,#AA,#FF,33,#20,#AF,#8D
  else
       	db	#8C,#8C,#20,#20,#10,#FF,33,#20,#12,#8D
  endif
	db	#8C,#8C,#20,#20,#7E,#FF,33,#20,#B0,#8D
	db	#8C,#8C,#20,#20,#7E,#FF,33,#20,#B0,#8D
  if SPC=0
	db	#8C,#8E,#8B,#20,#AE,#FF,33,#20,#AB,#8D
  else
	db	#8C,#8E,#8B,#20,#16,#FF,33,#20,#14,#8D
  endif
	db	#8C,#FF,38,#20,#8D
	db	#8C,#88,#8A,"  Slave Slot",#FF,13,#20,"Expand ",#9F,#20,#9D,#20,#8D
  if SPC=0
	db	#8C,#8C,#20,#20,#AA,#FF,33,#20,#AF,#8D
  else
	db	#8C,#8C,#20,#20,#10,#FF,33,#20,#12,#8D
  endif
	db	#8C,#8C,#20,#20,#7E,#FF,33,#20,#B0,#8D
	db	#8C,#8C,#20,#20,#7E,#FF,33,#20,#B0,#8D
  if SPC=0
	db	#8C,#8E,#8B,#20,#AE,#FF,33,#20,#AB,#8D
  else
	db	#8C,#8E,#8B,#20,#16,#FF,33,#20,#14,#8D
  endif
	db	#8C,#FF,38,#20,#8D
	db	#8C," Slave Slot as Master's Subslot ",#9F,#20,#9D,#FF,#03,#20,#8D
	db	#8E,#FF,38,#8B,#89
Slotll	db	#FF,6,#20,"Set desired slot configuration..."
	db	0

VolumeScr:
	db	#88,#FF,38,#8A,#8F
	db	#8C,"   Carnivore 2 MFC  ",#96,"  Volume Setup   ",#8D
	db	#8C,"  ",#FF,34,#9A,"  ",#8D
	db	#8C," Action Keys:",#FF,25,#20,#8D
	db	#8C,#FF,38,#20,#8D
	db	#8C,#20,#AA,#A7,"ESC",#0F,"   - save & exit to main menu  ",#8D
	db	#8C,#20,#7E,#A7,"UP",#0F,"    - increase FMPAC volume",#FF,5,#20,#8D
	db	#8C,#20,#7E,#A7,"DOWN",#0F,"  - decrease FMPAC volume",#FF,5,#20,#8D
	db	#8C,#20,#7E,#A7,"RIGHT",#0F," - increase SCC",#96,"SCC+ volume  ",#8D
	db	#8C,#20,#7E,#A7,"LEFT",#0F,"  - decrease SCC",#96,"SCC+ volume  ",#8D
	db	#8C,#20,#AE,#A7,"HOME",#0F,"  - reset to default values   ",#8D
	db	#8C,#FF,38,#20,#8D                        
	db	#8C," FMPAC Volume:",#FF,24,#20,#8D
	db	#8C,#FF,38,#20,#8D
  if SPC=0
	db	#8C,#20,#20,#A0,#FF,32,#A6,#A2,#20,#20,#8D
	db	#8C,#20,#20,#A1,#FF,32,#5E,#A3,#20,#20,#8D
  else
	db	#8C,#20,#20,#1C,#FF,32,#1B,#1D,#20,#20,#8D
	db	#8C,#20,#20,#1E,#FF,32,#5E,#1F,#20,#20,#8D
  endif
	db	#8C,#FF,38,#20,#8D
	db	#8C," SCC",#96,"SCC+ Volume:",#FF,21,#20,#8D
	db	#8C,#FF,38,#20,#8D
  if SPC=0
	db	#8C,#20,#20,#A0,#FF,32,#A6,#A2,#20,#20,#8D
	db	#8C,#20,#20,#A1,#FF,32,#5E,#A3,#20,#20,#8D
  else
	db	#8C,#20,#20,#1C,#FF,32,#1B,#1D,#20,#20,#8D
	db	#8C,#20,#20,#1E,#FF,32,#5E,#1F,#20,#20,#8D
  endif
	db	#8C,#FF,38,#20,#8D
	db	#8E,#FF,38,#8B,#89
Volll	db	#FF,8,#20,"Set desired FMPAC/SCC volume..."
	db	0

PSGScr:
	db	#88,#FF,38,#8A,#8F
	db	#8C,"    Carnivore 2 MFC  ",#96,"  PSG Setup",#FF,5,#20,#8D
	db	#8C,"  ",#FF,34,#9A,"  ",#8D
	db	#8C,"  PSG ",#9B,#9E,#9D,"  Clicker ",#9B,#9E,#9D,"  Dual-PSG ",#9B,#9E,#9D,"  ",#8D
	db	#8C,#FF,38,#20,#8D
	db	#8C," Action Keys:",#FF,25,#20,#8D
	db	#8C,#20,#AA,#A7,"ESC",#0F,"   - save & exit to main menu  ",#8D
	db	#8C,#20,#7E,#A7,"SPACE",#0F," - enable/disable PSG",#FF,8,#20,#8D
	db	#8C,#20,#7E,#A7,"ENTER",#0F," - enable/disable Clicker    ",#8D
	db	#8C,#20,#7E,#A7,"TAB",#0F,"   - enable/disable Dual-PSG   ",#8D
	db	#8C,#20,#7E,#A7,"UP",#0F," or ",#A7,"DOWN",#0F,"    - PSG volume",#FF,6,#20,#8D
	db	#8C,#20,#7E,#A7,"RIGHT",#0F," or ",#A7,"LEFT",#0F," - Clicker volume  ",#8D
	db	#8C,#20,#AE,#A7,"HOME",#0F,"  - reset to default values   ",#8D
	db	#8C,#FF,38,#20,#8D
	db	#8C,#FF,38,#20,#8D
	db	#8C," PSG Volume:",#FF,26,#20,#8D
  if SPC=0
	db	#8C,#20,#20,#A0,#FF,32,#A6,#A2,#20,#20,#8D
	db	#8C,#20,#20,#A1,#FF,32,#5E,#A3,#20,#20,#8D
  else
	db	#8C,#20,#20,#1C,#FF,32,#1B,#1D,#20,#20,#8D
	db	#8C,#20,#20,#1E,#FF,32,#5E,#1F,#20,#20,#8D
  endif
	db	#8C,#FF,38,#20,#8D
	db	#8C," PPI Clicker Volume:",#FF,18,#20,#8D
  if SPC=0
	db	#8C,#20,#20,#A0,#FF,32,#A6,#A2,#20,#20,#8D
	db	#8C,#20,#20,#A1,#FF,32,#5E,#A3,#20,#20,#8D
  else
	db	#8C,#20,#20,#1C,#FF,32,#1B,#1D,#20,#20,#8D
	db	#8C,#20,#20,#1E,#FF,32,#5E,#1F,#20,#20,#8D
  endif
	db	#8E,#FF,38,#8B,#89
PSGll	db	#FF,7,#20,"Set up PSG and desired volume..."
	db	0

SetupScr:
	db	#88,#FF,38,#8A,#8F
	db	#8C,"  Carnivore 2 MFC  ",#96,"  Configuration   ",#8D
	db	#8C,"  ",#FF,34,#9A,"  ",#8D
	db	#8C," Use cursor keys. Action Keys:",#FF,8,#20,#8D
	db	#8C,#20,#AA,#A7,"ESC",#0F,"   - save & exit to main menu  ",#8D
	db	#8C,#20,#7E,#A7,"SPACE",#0F," - change selected value     ",#8D
	db	#8C,#20,#AE,#A7,"HOME",#0F,"  - reset to default values   ",#8D
	db	#8C,#FF,38,#20,#8D
	db	#8C,#20,#AA,"I/O port for ID & control:     ",#9F,"F ",#9D," ",#8D
	db	#8C,#20,#7E,"Dual-Reset on cold boot:",#FF,8,#20,#9F,#9E,#9D," ",#8D
	db	#8C,#20,#7E,"Entry sorting in Boot Menu:     ",#9F,#9E,#9D," ",#8D
	db	#8C,#20,#7E,"Fade in/out effects:",#FF,12,#20,#9F,#9E,#9D," ",#8D
	db	#8C,#20,#7E,"FMPAC mono enabled:",#FF,13,#20,#9F,#9E,#9D," ",#8D
	db	#8C,#20,#7E,"Keyboard/joystick delay:",#FF,8,#20,#9F,#20,#9D," ",#8D
	db	#8C,#20,#7E,"Frequency at startup (Hz):     ",#9F," 0",#9D," ",#8D
	db	#8C,#20,#7E,"Autostart delay (0-no delay):   ",#9F,#20,#9D," ",#8D
	db	#8C,#20,#7E,"Allow to work in Slot 3:",#FF,8,#20,#9F,#9E,#9D," ",#8D
	db	#8C,#20,#7E,#FF,36,#20,#8D
;	db	#8C,#20,#7E,"                                    ",#8D
;	db	#8C,#20,#7E,#FF,8,#20,"Font> RGB   RGB <Background ",#8D
;	db	#8C,#20,#7E,"Main menu:   ",#9F,#20,#20,#20,#9D," ",#9F,#20,#20,#20,#9D,#FF,12,#20,#8D
	db	#8C,#20,#7E,"Main menu:   ",#9F,#20,#20,#20,#9D," ",#9F,#20,#20,#20,#9D,"   Colors:  ",#8D
	db	#8C,#20,#7E,"Help screens:",#9F,#20,#20,#20,#9D," ",#9F,#20,#20,#20,#9D,#20,#20,#FF,9,#9A,#20,#8D
	db	#8C,#20,#7E,"SCC/FM setup:",#9F,#20,#20,#20,#9D," ",#9F,#20,#20,#20,#9D," [RGB] [RGB]",#8D
	db	#8C,#20,#AE,"PSG setup:   ",#9F,#20,#20,#20,#9D," ",#9F,#20,#20,#20,#9D,"  FNT   BKG ",#8D
	db	#8E,#FF,38,#8B,#89
Setupll	db	#FF,8,#20,"Configure colors and options..."   
	db	0

                                                                                                          
; Help screens
HelpScr1:
	db	#88,#FF,38,#8A,#8F
	db	#8C,"  Carnivore 2 MFC ",#96," Help Page 1 of 2  ",#8D
	db	#8C,"  ",#FF,34,#9A,"  ",#8D
	db	#8C," Menu Navigation and Action Keys:",#FF,5,#20,#8D
	db	#8C,#20,#AA,#A7,"ESC",#0F," - boot MSX using the default  ",#8D
	db	#8C,#20,#7E,#FF,8,#20,"configuration: all enabled  ",#8D
	db	#8C,#20,#7E,#A7,"LEFT",#0F,",",#A7,"RIGHT",#0F," - previous/next page ",#8D
	db	#8C,#20,#7E,#A7,"UP",#0F,",",#A7,"DOWN",#0F," - select ROM/CFG entry  ",#8D
	db	#8C,#20,#7E,#A7,"SPACE",#0F," - start selected entry",#FF,6,#20,#8D
	db	#8C,#20,#7E,#A7,"G",#0F," - start an entry directly",#FF,7,#20,#8D
	db	#8C,#20,#7E,#A7,"R",#0F," - reset MSX and start an entry  ",#8D
	db	#8C,#20,#7E,#A7,"ENTER",#0F,",",#A7,"O",#0F," - Dual-Slot setup page  ",#8D
	db	#8C,#20,#7E,#A7,"1",#0F," - select entry for master slot  ",#8D
	db	#8C,#20,#7E,#A7,"2",#0F," - select entry for slave slot   ",#8D
	db	#8C,#20,#7E,#A7,"A",#0F," - select entry for Auto-Start   ",#8D
	db	#8C,#20,#7E,#A7,"D",#0F," - clear Auto-Start & Dual-Slot  ",#8D
	db	#8C,#20,#7E,#A7,"F",#0F," - select 50Hz or 60Hz frequency ",#8D
	db	#8C,#20,#7E,#A7,"T",#0F," - toggle Turbo or R800 mode     ",#8D
	db	#8C,#20,#7E,#A7,"C",#0F," - customize configuration",#FF,7,#20,#8D
	db	#8C,#20,#7E,#A7,"L",#0F," - jump to the last used entry   ",#8D
	db	#8C,#20,#7E,#A7,"M",#0F," - toggle background music",#FF,7,#20,#8D
	db	#8C,#20,#AE,#A7,"S",#0F," - toggle help scroller",#FF,10,#20,#8D
	db	#8E,#FF,38,#8B,#89
helpll	db	#FF,11,#20,"Press any key to continue..."
	db	0

HelpScr2:
	db	#88,#FF,38,#8A,#8F
	db	#8C,"  Carnivore 2 MFC ",#96," Help Page 2 of 2  ",#8D
	db	#8C,"  ",#FF,34,#9A,"  ",#8D
	db	#8C," Boot Option Keys:",#FF,20,#20,#8D
	db	#8C,#20,#AA,#A7,"F3",#0F," - use default UI settings",#FF,6,#20,#8D
	db	#8C,#20,#7E,#A7,"F4",#0F," - cancel Auto-Start",#FF,12,#20,#8D
	db	#8C,#20,#AE,#A7,"F5",#0F," - skip Boot Menu",#FF,15,#20,#8D
	db	#8C,#FF,38,#20,#8D
	db	#8C," Joystick Directional Controls:",#FF,7,#20,#8D
	db	#8C,#20,#AA,#A7,"LEFT",#0F,",",#A7,"RIGHT",#0F," - same as cursor keys",#8D
	db	#8C,#20,#AE,#A7,"UP",#0F,",",#A7,"DOWN",#0F,"    - same as cursor keys",#8D
	db	#8C," NOTE: Other directions are ignored   ",#8D
	db	#8C,#FF,38,#20,#8D
	db	#8C," Joystick Button Controls:",#FF,12,#20,#8D
	db	#8C,#20,#AA,#A7,"BUTTON A",#0F," - toggle (same as SPACE) ",#8D
	db	#8C,#20,#AE,#A7,"BUTTON B",#0F," - cancel (same as ESC)   ",#8D
	db	#8C,#FF,38,#20,#8D
	db	#8C," Joystick Action on Auto-Start:",#FF,7,#20,#8D
	db	#8C,#20,#AA,#A7,"BUTTON A",#0F," - skip countdown",#FF,9,#20,#8D
	db	#8C,#20,#AE,#A7,"BUTTON B",#0F," - cancel Auto-Start",#FF,6,#20,#8D
	db	#8C," NOTE: Hold button for over 1 second  ",#8D
	db	#8C,#FF,38,#20,#8D
	db	#8E,#FF,38,#8B,#89
helplll	db	#FF,13,#20,"Press any key to return..."
	db	0


; Default line
StaticS
	db	#8C,"  Slots",#A5,#90,#91," Config",#A5,#A8,#91," Volume",#A5,#93,#91," PSG",#A5,#99,#91," ",#8D,0

; 30 changeable characters + 6 spaces
DynamicS
	db	#8C,"    "
	db	#E0,#E1,#E2,#E3,#E4,#E5,#E6,#E7,#E8,#E9,#EA,#EB,#EC,#ED,#EE,#EF
	db	#F0,#F1,#F2,#F3,#F4,#F5,#F6,#F7,#F8,#F9,#FA,#FB,#FC,#FD
	db	"    ",#8D,0

; Scroller text
ScrollerS
	db	"                               "
	db	#A7,"S"+#80,#0F," toggles this help scroller ",#1A," "
	db	#A7,"H"+#80,#0F," shows help screens ",#1A," "
	db	#A7,"E"+#80,"S"+#80,"C"+#80,#0F," exits and boots with default configuration ",#1A," "
	db	#A7,"L"+#80,"E"+#80,"F"+#80,"T"+#80,#0F," or ",#A7,"R"+#80,"I"+#80,"G"+#80,"H"+#80,"T"+#80,#0F," flips directory pages ",#1A," "
	db	#A7,"U"+#80,"P"+#80,#0F," or ",#A7,"D"+#80,"O"+#80,"W"+#80,"N"+#80,#0F," selects ROM or CFG entry ",#1A," "
	db	#A7,"S"+#80,"P"+#80,"A"+#80,"C"+#80,"E"+#80,#0F," starts selected entry (single slot) ",#1A," "
	db	#A7,"G"+#80,#0F," starts selected entry directly ",#1A," "
	db	#A7,"R"+#80,#0F," resets MSX and starts selected entry ",#1A," "
	db	#A7,"E"+#80,"N"+#80,"T"+#80,"E"+#80,"R"+#80,#0F," or ",#A7,"O"+#80,#0F," opens Dual-Slot setup page ",#1A," "
	db	#A7,#DB,#0F," selects entry for master slot ",#1A," "	; 1
	db	#A7,#DC,#0F," selects entry for slave slot ",#1A," "	; 2
	db	#A7,"A"+#80,#0F," selects entry for Auto-Start ",#1A," "
	db	#A7,"D"+#80,#0F," clears Auto-Start and Dual-Slot settings ",#1A," "
	db	#A7,"F"+#80,#0F," sets 50Hz or 60Hz frequency ",#1A," "
	db	#A7,"T"+#80,#0F," toggles Turbo or R800 mode ",#1A," "
	db	#A7,"C"+#80,#0F," opens cartridge's configuration page ",#1A," "
	db	#A7,"L"+#80,#0F," jumps to the last used entry ",#1A," "
	db	#A7,"M"+#80,#0F," toggles background music "
	db	0,0,0,0,0,0,0,0,0
ScrollerE


; Music player + music data
; Must be moved to #C000, initialized at #C000
; Play: call #C005 in loop
; Stop: call #C008
;
MusicData:

	include	"aurora.inc"

MusicDataEnd:

; Font data 2048 bytes
fontdat:
	dw	0

	include	"font.inc"


; End of Boot Menu

	org	#C000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Frames ASCII codes
;	
;	Thick
;	#80,#85,#85,#81
;	#86,#20,#20,#87
;	#82,#84,#84,#83
;
;	Thin
;	#AA,#AC,#AC,#AF
;	#7E,#20,#20,#B0
;	#AE,#AD,#AD,#AB
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
;	#A8,#A9
;
;	Inverse fonts
;
;	#A7 - start symbol
;	#0F - stop symbol
;
