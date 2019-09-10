; tmss rom disassembly
; original code: copyright 1989 - whatever sega
; disassembly: copyfuck 2019 kelsey boey

; how to assemble (vasm users):
; "vasmm68k_mot -spaces -m68000 -no-opt tmss.asm -Fbin -o tmss.bin" (no quotes)

; for asm68k users: change dot-labels (e.g. .loop) to at-labels (e.g. @loop) before you assemble
; "asm68k /p tmss.asm, tmss.bin" (no quotes)

; 68k vector table
vectors:
	dc.l	$FFFF00
	dc.l	startup
	rept	62
	dc.l	cpufault
	endr

; mega drive cart header
cart:
	dc.b	"SEGA GENESIS    "
	dc.b	"(C)SEGA 1990.MAY"
	dc.b	"GENESIS OS                                      "
	dc.b	"GENESIS OS                                      "
	dc.b	"OS 00000000-00", $5B, $74
	dc.l	$20202020
	dc.l	$20202020
	dc.l	$20202020
	dc.l	$20202020
	dc.l	vectors
	dc.l	endrom-1
	dc.l	$FF0000
	dc.l	$FFFFFF
	dc.l	$20202020
	dc.l	$20202020
	dc.l	$20202020
	dc.b	"                                                    "
	dc.b	"U               "

cpufault:
	bra.s	*

startup:
	lea	setuptable(pc), a5
	movem.l	(a5)+, d5-a4
	move.b	-$10FF(a1), d0
	andi.b	#$F, d0
	beq.s	skiptmss	; a swift decision of fate
	move.l	#"SEGA", $2F00(a1)

skiptmss:
	move.w	(a4), d0
	moveq	#0, d0
	movea.l	d0, a6
	move.l	a6, usp
	moveq	#$17, d1

; set vdp registers
.loop:
	move.b	(a5)+, d5
	move.w	d5, (a4)
	add.w	d7, d5
	dbf	d1, .loop

clrvram:
	move.l	#$40000080, (a4)
	move.w	d0, (a3)

dmawait:
	move.w	(a4), d4	; get VDP status
	btst.l	#1, d4		; test DMA busy flag
	bne.s	dmawait

clrcram:
	move.l	#$81048F02, (a4)
	move.l	#$C0000000, (a4)
	moveq	#$1F, d3

.loop:
	move.l	d0, (a3)
	dbf	d3, .loop

clrvsram:
	move.l	#$40000010, (a4)
	moveq	#$13, d4

.loop:
	move.l	d0, (a3)
	dbf	d4, .loop

writepsg:
	moveq	#3, d5

.loop:
	move.b	(a5)+, $11(a3)	; silence psg channels
	dbf	d5, .loop
	bra.s	main

setuptable:
	dc.l	$00008000	; d5: vdp register base
	dc.l	$00003FFF	; d6: ???
	dc.l	$00000100	; d7: vdp register increment
	dc.l	$00A00000	; a0: z80 ram start addr
	dc.l	$00A11100	; a1: z80 bus request
	dc.l	$00A11200	; a2: z80 reset
	dc.l	$00C00000	; a3: vdp data
	dc.l	$00C00004	; a4: vdp control
	dc.b	$04		; vdp reg $80: hblank off, 512 colour mode
	dc.b	$14		; vdp reg $81: mode 5, dma enabled
	dc.b	$30		; vdp reg $82: plane a nametable @ $C000
	dc.b	$3C		; vdp reg $83: window nametable @ $F000
	dc.b	$07		; vdp reg $84: plane b nametable @ $E000
	dc.b	$6C		; vdp reg $85: sprite table @ $D800
	dc.b	$00		; vdp reg $86: 128k sprite table (unused)
	dc.b	$00		; vdp reg $87: background colour
	dc.b	$00		; vdp reg $88: unused
	dc.b	$00		; vdp reg $89: unused
	dc.b	$FF		; vdp reg $8A: hblank counter
	dc.b	$00		; vdp reg $8B: ext int off, full screen vscroll & hscroll
	dc.b	$81		; vdp reg $8C: 320 pixel wide display, no interlace, no shadow/highlight
	dc.b	$37		; vdp reg $8D: hscroll table @ $DC00
	dc.b	$00		; vdp reg $8E: only usable in 128k
	dc.b	$01		; vdp reg $8F: vdp addr increment
	dc.b	$01		; vdp reg $90: 64x32 cell plane size
	dc.b	$00		; vdp reg $91: window hpos
	dc.b	$00		; vdp reg $92: window vpos
	dc.b	$FF		; vdp reg $93: dma length low
	dc.b	$FF		; vdp reg $94: dma length high
	dc.b	$00		; vdp reg $95: dma source low
	dc.b	$00		; vdp reg $96: dma source mid
	dc.b	$80		; vdp reg $97: dma source high + dma type
	dc.b	$9F		; psg ch1 vol
	dc.b	$BF		; psg ch2 vol
	dc.b	$DF		; psg ch3 vol
	dc.b	$FF		; psg ch4 vol

main:
	lea	$FFFFC000.w, a0
	lea	ramtable(pc), a1
	movem.l	(a1)+, d4-d7/a2-a6
	move.w	#$3F, d0	; ram code size

; load code into ram
.loop:
	move.w	(a1)+, (a0)+
	dbf	d0, .loop

jumpram:
	jsr	$FFFFC000.w
	bra.s	*		; shouldn't get here (unless failed)

ramtable:
	dc.l	$20534547	; d4
	dc.l	$45940003	; d5
	dc.l	$000000F7	; d6
	dc.l	$53454741	; d7
	dc.l	$00A14000	; a2
	dc.l	$00A14101	; a3
	dc.l	$00C00004	; a4
	dc.l	$00C00000	; a5
	dc.l	$00A10001	; a6

; now we're running from ram
checkcart:
	bset.b	#0, (a3)	; TMSS disengage, cart back on bus
	cmp.l	$100.w, d7	; header = "SEGA"
	beq.s	.ok
	cmp.l	$100.w, d4	; header = " SEG"
	bne.s	.fail
	cmpi.b	#$41, $104.w	; "A"
	beq.s	.ok

.fail:
	bclr.b	#0, (a3)	; TMSS engage, cart off bus
	move.b	(a6), d0
	andi.b	#$F, d0		; is MD rev 0?
	beq.s	.return		; if so, branch
	move.l	#0, (a2)	; disable vdp (if newer rev)

.return:
	rts

; at this point, "SEGA" is present (in some form) on the cart rom
.ok:
	bclr.b	#0, (a3)	; TMSS engage, cart off bus
	jsr	loadcram.l
	move.l	#$4C200000, (a4)

.loop
	move.l	(a1)+, (a5)	; load TMSS graphics
	dbf	d6, .loop

cont:
	jsr	loadunseen.l	; load unused licence graphics
	move.w	#$8144, (a4)
	move.w	#$3C, d0
	bsr.s	.idle
	move.w	#$8104, (a4)
	move.b	(a6), d0
	andi.b	#$F, d0		; is MD rev 0?
	beq.s	.pass		; shouldn't get here, but whatever
	move.l	#0, (a2)	; else, disable vdp (games must reenable it, otherwise lockups will occur)

; security passed, now boot cart
.pass:
	bset.b	#0, (a3)	; TMSS disengage, cart back on bus
	moveq	#0, d0
	movea.l	d0, a0
	movea.l	(a0)+, a7	; update stack pointer from cart
	movea.l	(a0)+, a0	; update pc from cart
	jmp	(a0)		; run game

.idle:
	move.w	#$95CE, d1	; run idle loop before booting cart

.loop:
	dbf	d1, .loop
	dbf	d0, .idle
	rts

cramdata:
	dc.w	$1		; palette size
	dc.w	$EEE		; palette #0 colour #1 = white
	dc.w	$EE8		; palette #0 colour #2 = turquoise
	
vramdata:
	; A
	dc.l	$01111100
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11111110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	0
	; B
	dc.l	$11111100
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11111100
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11111100
	dc.l	0
	; C
	dc.l	$11111110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000000
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11111110
	dc.l	0
	; D
	dc.l	$11111100
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11111100
	dc.l	0
	; E
	dc.l	$11111110
	dc.l	$11000000
	dc.l	$11000000
	dc.l	$11111100
	dc.l	$11000000
	dc.l	$11000000
	dc.l	$11111110
	dc.l	0
	; F
	dc.l	$11111110
	dc.l	$11000000
	dc.l	$11000000
	dc.l	$11111100
	dc.l	$11000000
	dc.l	$11000000
	dc.l	$11000000
	dc.l	0
	; G
	dc.l	$11111110
	dc.l	$11000110
	dc.l	$11000000
	dc.l	$11001110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11111110
	dc.l	0
	; H
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11111110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	0
	; I
	dc.l	$00111000
	dc.l	$00111000
	dc.l	$00111000
	dc.l	$00111000
	dc.l	$00111000
	dc.l	$00111000
	dc.l	$00111000
	dc.l	0
	; J
	dc.l	$00000110
	dc.l	$00000110
	dc.l	$00000110
	dc.l	$00000110
	dc.l	$00000110
	dc.l	$01100110
	dc.l	$01111110
	dc.l	0
	; K
	dc.l	$11000110
	dc.l	$11001100
	dc.l	$11111000
	dc.l	$11111000
	dc.l	$11001100
	dc.l	$11000110
	dc.l	$11000110
	dc.l	0
	; L
	dc.l	$01100000
	dc.l	$01100000
	dc.l	$01100000
	dc.l	$01100000
	dc.l	$01100000
	dc.l	$01100000
	dc.l	$01111110
	dc.l	0
	; M
	dc.l	$11000110
	dc.l	$11101110
	dc.l	$11111110
	dc.l	$11010110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	0
	; N
	dc.l	$11000110
	dc.l	$11100110
	dc.l	$11110110
	dc.l	$11011110
	dc.l	$11001110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	0
	; O
	dc.l	$11111110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11111110
	dc.l	0
	; P
	dc.l	$11111110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11111110
	dc.l	$11000000
	dc.l	$11000000
	dc.l	$11000000
	dc.l	0
	; Q
	dc.l	$11111110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11001110
	dc.l	$11001110
	dc.l	$11111110
	dc.l	0
	; R
	dc.l	$11111110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11111100
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	0
	; S
	dc.l	$11111110
	dc.l	$11000110
	dc.l	$11000000
	dc.l	$11111110
	dc.l	$00000110
	dc.l	$11000110
	dc.l	$11111110
	dc.l	0
	; T
	dc.l	$11111110
	dc.l	$00111000
	dc.l	$00111000
	dc.l	$00111000
	dc.l	$00111000
	dc.l	$00111000
	dc.l	$00111000
	dc.l	0
	; U
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11111110
	dc.l	0
	; V
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$01101100
	dc.l	$00111000
	dc.l	$00010000
	dc.l	0
	; W
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11010110
	dc.l	$11111110
	dc.l	$11101110
	dc.l	$11000110
	dc.l	0
	; X
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11101110
	dc.l	$01111100
	dc.l	$11101110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	0
	; Y
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$01101100
	dc.l	$00111000
	dc.l	$00111000
	dc.l	$00111000
	dc.l	0
	; Z
	dc.l	$11111110
	dc.l	$00001110
	dc.l	$00011100
	dc.l	$00111000
	dc.l	$01110000
	dc.l	$11100000
	dc.l	$11111110
	dc.l	0
	; .
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$01100000
	dc.l	$01100000
	dc.l	0

; this sega logo graphic is unused (licence perhaps?)
segalogo:
	; S
	dc.l	$02222200
	dc.l	$22000220
	dc.l	$22000000
	dc.l	$02222200
	dc.l	$00000220
	dc.l	$22000220
	dc.l	$02222200
	dc.l	0
	; E
	dc.l	$02222220
	dc.l	$22000000
	dc.l	$22000000
	dc.l	$22222200
	dc.l	$22000000
	dc.l	$22000000
	dc.l	$02222220
	dc.l	0
	; G
	dc.l	$02222200
	dc.l	$22000220
	dc.l	$22000000
	dc.l	$22002220
	dc.l	$22000220
	dc.l	$22000220
	dc.l	$02222220
	dc.l	0
	; A
	dc.l	$00022000
	dc.l	$00222200
	dc.l	$00222200
	dc.l	$02200220
	dc.l	$02200220
	dc.l	$22000022
	dc.l	$22022222
	dc.l	0

str1	dc.b	"   produced by or"
	dc.b	$FF		; newline

str2	dc.b	" under license from"
	dc.b	$FF		; newline

str3	dc.b	"sega,enterprises ltd{"
	dc.b	$0		; end

loadcram:
	move.w	(a1)+, d0
	move.l	#$C0020000, (a4)

.loop:
	move.w	(a1)+, (a5)
	dbf	d0, .loop
	rts

; load unused sega graphic
loadunseen:
	move.l	d5, (a4)	; this licence is never shown on screen

.loop:
	moveq	#0, d1
	move.b	(a1)+, d1
	bmi.s	.null
	bne.s	.tovram
	rts

.tovram:
	move.w	d1, (a5)
	bra.s	.loop

.null:
	addi.l	#$1000000, d5
	bra.s	loadunseen

; after padding, rom should be exactly 2K (2048 bytes) in size
pad	rept	19
	dc.l	$FFFFFFFF
	endr

; end of rom
endrom	end
