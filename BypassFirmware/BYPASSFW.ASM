;
; Carnivore/Carnivore2 Firmware Disabler ROM v1.0
; Copyright (c) 2022 RBSC
; Thanks to gdx for the idea of using H.STKE hook
; Thanks to acet for the idea of using H.RUNC hook
;


	org	#4000

	db	"AB"		; ROM signature
	dw	FWBypass	; FW bypass code
	dw	0		; STATEMENT
	dw	0		; DEVICE
	dw	0		; TEXT
	db	0,0,0,0,0,0


;--- System calls and variables

ENASLT	equ	#0024		; BIOS Enable Slot
WRTSLT	equ	#0014		; BIOS Write to Slot
CardMDR equ	#4F80

;
; Bypass firmware
;
FWBypass:
 	ld	a,#23
	ld	(#CBD8),a		; To bypass the FS-A1 firmare
	ld	(#C3CE),a		; To bypass the FS-A1F firmare
	ld	(#C3D2),a		; To bypass the FS-A1mk2 firmare

; Routine to Bypass the Mitsubishi ML-G1, National FS-4000, FS-4500, FS-4600, FS-4700, Toshiba HX-21I, HX-22I, HX-23I, Sony HB-55P,
; HB-75D, HB-75P, HB-101, HB-101P, HB-201, HB-201P, HB-F1, HB-F1II, HB-F9P/S and similar firmware

	ld	hl,#FECB
	ld	de,#C108
	ld	bc,5
	ldir				; Copy the current hook in case another ROM uses it
	ld	hl,NewHook
	ld	de,#FECB
	ld	bc,5
	ldir				; Set the new hook
	ld	hl,HookAddon
	ld	de,#C100
	ld	bc,8
	ldir				; Addon to disable the H.STKE hook

	ld	hl,SetC2
	ld	de,#C180
	ld	bc,NewHook-SetC2
	ldir				; Copy C2 init code to RAM
	
	jp	#C180


; Find Carnivore2 by port
SetC2:
	call	FindCart
	or	a			; Carnivore2 present?
	ret	z

; Enable boot menu in slot x.0 and set Defconfig
C2BB_Enable:
	sub	#31
	add	#F0
	ld	c,a			; Carnivore2's port
	ld	a,"R"
	out	(c),a			; show registers
	nop
	ld	a,"1"
	out	(c),a			; show registers at #4F80
	nop

	ld	a,c
	sub	#70
	inc	a			; A = Carnivore2's expanded slot
	ld	e,#20
	ld	hl,CardMDR
	push	af
	call	WRTSLT			; Configure CardMDR for immediate changes
	pop	af

	ld	e,#00
	ld	hl,CardMDR+5
	push	af
	call	WRTSLT			; Show Boot Menu in slot x.0
	pop	af

	ld	e,#FF
	ld	hl,CardMDR+#1E
	push	af
	call	WRTSLT			; Enable all devices in C2
	pop	af

	ld	de,DefCfgRam		; DefConfig values
	ld	hl,CardMDR+6		; Current registers
	ld	b,24

C2BB_Loop:
	push	hl
	push	de
	push	bc
	push	af
	push	af
	ex	hl,de
	ld	a,(hl)
	ex	hl,de
	ld	e,a
	pop	af
	call	WRTSLT			; write value to C2's register area
	pop	af
	pop	bc
	pop	de
	pop	hl
	inc	hl
	inc	de
	djnz	C2BB_Loop

	ld	e,#38
	ld	hl,CardMDR
	call	WRTSLT			; Finalize DefConfig setup

	ret

;
; Detect cartridges
;
FindCart:
	ld	a,"C"
	out	(#F0),a			; check port F0
	nop
	in	a,(#F0)
	cp	"2"
	jr	nz,FindCart1
	ld	a,"S"
	out	(#F0),a			; check port F0
	nop
	in	a,(#F0)
	ret
FindCart1:
	ld	a,"C"
	out	(#F1),a			; check port F1
	nop
	in	a,(#F1)
	cp	"2"
	jr	nz,FindCart2
	ld	a,"S"
	out	(#F1),a			; check port F1
	nop
	in	a,(#F1)
	ret
FindCart2:
	ld	a,"C"
	out	(#F2),a			; check port F2
	nop
	in	a,(#F2)
	cp	"2"
	jr	nz,FindCart3
	ld	a,"S"
	out	(#F2),a			; check port F2
	nop
	in	a,(#F2)
	ret
FindCart3:
	xor	a
	ret


; 24 bytes of DefConfig to compare (must be in first 8kb!)
DefCfgRam:
	db	#F8,#50,#00,#85,#3F,#40
	db	#F8,#70,#01,#8C,#3F,#60		
	db      #F8,#90,#02,#8C,#3F,#80		
	db	#F8,#B0,#03,#8C,#3F,#A0	

NewHook:
	call	#C100			; Call hook handler
	ret
	ret

HookAddon:
	ld	a,#C9
	ld	(#FEDA),a		; Disable the H.STKE hook set by firmware
	nop
	nop
	nop

	db	0,0,0
	db	"RBSC:PTERO/WIERZBOWSKY/DJS3000/PYHESTY/GREYWOLF/SUPERMAX:2022"
	db	0,0,0

Filler:
	ds	#C000-(Filler-FWBypass)-#10
