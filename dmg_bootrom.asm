SECTION "BootCode", ROM0[$0]
Start:
; Init stack pointer
    ld sp, $fffe

; Clear memory VRAM
    ld hl, $8000

.clearVRAMLoop
    ld a, 0
    ldi [hl], a
    bit 5, h
    jr z, .clearVRAMLoop

; Init Audio
    ld a, $80
    ldh [$ff26], a
    ldh [$ff11], a
    ld a, $f3
    ldh [$ff12], a
    ldh [$ff25], a
    ld a, $77
    ldh [$ff24], a

; Init BG palette
    ld a, $fc
    ldh [$FF47], a

; Load logo from ROM.
; A nibble represents a 4-pixels line, 2 bytes represent a 4x4 tile, scaled to 8x8.
; Tiles are ordered left to right, top to bottom.
    ld de, Logo
    ld hl, $8010 ; This is where we load the tiles in VRAM

.loadLogoLoop
    ld a, [de] ; Read 2 rows
    ld b, a
    call DoubleBitsAndWriteRow
    call DoubleBitsAndWriteRow
    inc de
    ld a, e
    cp $34 ; End of logo
    jr nz, .loadLogoLoop

; Set up tilemap
    ld a,$19
    ld [$9910], a ; ... put in the superscript position
    ld hl,$992f   ; Bottom right corner of the logo
    ld c,$c       ; Tiles in a logo row
.tilemapLoop
    dec a
    jr z, .tilemapDone
    ldd [hl], a
    dec c
    jr nz, .tilemapLoop
    ld l,$0f ; Jump to top row
    jr .tilemapLoop
.tilemapDone

    ld a, $64
    ldh [$FF43], a
	ld d, a	; Set loop count $64

    ; Turn on LCD
    ld a, $91
    ldh [$FF40], a

.animate
    call Wait
    call Wait

    dec d
    ld a, d
	ldh [$FF43], a ; Scroll logo right 1 col
	jr nz, .animate

.soundFrame
	ld a, $83
    call PlaySound

.endAnimation
    ld b, $a0
    call WaitB

; Set registers to match the original DMG boot
    ld hl, $01B0
    push hl
    pop af
    ld hl, $014D
    ld bc, $0013
    ld de, $00D8

; Boot the game
    jp BootGame

DoubleBitsAndWriteRow:
; Double the most significant 4 bits, b is shifted by 4
    ld a, 4
    ld c, 0
.doubleCurrentBit
    rl b
    push af
    rl c
    pop af
    rl c
    dec a
    jr nz, .doubleCurrentBit
    ld a, c
; Write as two rows
    ldi [hl], a
    inc hl
    ldi [hl], a
    inc hl
    ret

Wait:
    push bc
    ld b, $a
.wait1
    ld c, $ff
.wait2
    dec c
    jr nz, .wait2
    dec b
    jr nz, .wait1
    pop bc
    ret

WaitB:
    call Wait
    dec b
    jr nz, WaitB
    ret

PlaySound:
    ldh [$ff13], a
    ld a, $87
    ldh [$ff14], a
    ret

Logo:
db $ff,$ff,$ff,$00,$00,$00,$ff,$ff,$ff,$33,$00,$00,$33,$33,$ff,$cc,$cc,$00,$33,$33,$ff,$cc,$cc,$00,$ff,$ff,$ff,$00,$00,$00,$ff,$ff,$ff,$00,$cc,$cc,$33,$33,$ff,$ff,$00,$cc,$33,$33,$ff,$ff,$00,$cc,$00,$00,$00,$00,$00,$00,$00,$00,$21,$04,$01,$11,$a8,$00,$1a,$13,$be,$20,$01,$23,$7d,$fe,$34

SECTION "BootGame", ROM0[$fe]
BootGame:
    ldh [$FF50], a ; unmap boot ROM