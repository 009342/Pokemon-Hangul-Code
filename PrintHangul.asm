vHangulCounter EQU $9600
vHangulDest EQU $9602
vHangulSrc EQU $9604
vUploadedTile EQU $9610
FontInfoTile EQU 8
MaxFontLimit EQU $36
PrintHangul:
	
	;hl(TileMap) bc(Script Bytes), return a : FontBank
	push hl
	push bc
	ld bc,-20
	add hl,bc
	pop bc
	call FindUploadedTile
	cp a,$FF
	jr nz,.AlreadyExist
	jr .NotFound
.AlreadyExist
	sla a
	add a,$80
	ld [hl],a
	inc a
	pop hl
	ld [hli],a
	ret
.NotFound ;based on http://cafe.naver.com/hansicgu/66
	call FindAvailableTiles
	sla a
		push hl
		ld hl,vUploadedTile

		push af
		
		add a,l
		ld l,a
		
		ld a,b
		call WriteVRAM
		inc hl
		ld a,c
		call WriteVRAM
		pop af
		pop hl
	add a,$80
	ld [hl],a
	pop hl
	inc a
	ld [hli],a
	dec a
	push bc
	ld b,$08
	ld c,a
	ld a,$04
.loop
	sla c
	rl b
	dec a
	jr nz,.loop

		push hl
		ld hl,vHangulDest
		ld a,b
		call WriteVRAM
		inc hl
		ld a,c
		call WriteVRAM
		pop hl
	
	pop bc
	
		push hl
		ld hl,vHangulCounter
		call ReadVRAM
		pop hl
	
	inc a
	cp a,MaxFontLimit
	jr c,.Pass
	ld a,$00
.Pass
	push hl
	ld hl,vHangulCounter
	call WriteVRAM

	ld a,b
	and a,$0C
	rrca
	rrca
	add a,$30
	push af ; bank

	
	ld a,b
	and a,$03
	add a,$04
	ld b,a
	ld a,$04
.loop2
	sla c
	rl b
	dec a
	jr nz,.loop2
		push bc
		
			push hl
			ld hl,vHangulDest
			call ReadVRAM
			ld b,a
			inc hl
			call ReadVRAM
			ld c,a
			pop hl
				push bc
				pop hl ; hl : Dest
		
		pop de ;de : Src
	pop af ;bank
	
	ld b,a
	ld c,$2
	call HBlankCopyDouble
	pop hl
	ret
	
FindUploadedTile: ;VRAM : 8DC0~8DFF, bc : Hangul 2bytes, return a : TileNumber
	push hl
	ld hl,vUploadedTile
.loop
	ld a,l
	cp a,$10 * FontInfoTile
	jr z,.NotFound
	
	call ReadVRAM
	cp a,b
	jr nz,.PrepareLoop
	inc hl
	call ReadVRAM
	cp a,c
	jr z,.Found
	dec hl
.PrepareLoop
	inc hl
	inc hl
	jr .loop
.Found
	push bc
	ld bc,$FFFF-vUploadedTile+1
	add hl,bc
	pop bc
	ld a,l
	sra a
	
	pop hl
	ret
.NotFound
	pop hl
	ld a,$FF
	ret
	
FindAvailableTiles:
	push hl
	ld hl,vHangulCounter
	call ReadVRAM
	pop hl
.loop
	push af
	sla a
	add a,$80
	call FindTileMap
	and a
	jr z,.Done
	pop af
	inc a
	cp a,MaxFontLimit
	jr c,.Pass
	ld a,$00
.Pass
	jr .loop
.Done
	pop af
	ret
	
FindTileMap:
	push bc
	push hl
	ld hl,wTileMap
	ld c,SCREEN_HEIGHT
.loop
	ld b,SCREEN_WIDTH
.loop2
	cp a,[hl]
	jr z,.Found
	inc hl
	dec b
	jr nz,.loop2
	dec c
	jr nz,.loop
	pop hl
	pop bc
.NotFound
	ld a,$00
	ret
.Found
	pop hl
	pop bc
	ld a,$01
	ret
	
ReadVRAM:
	;if LCD is off
	ld a,[rLCDC]
	bit rLCDC_ENABLE,a
	jr z,.ReadMemoryDirectly
.CheckHBlank
	ld a,[rSTAT]
	and a,%00000011
	cp a,$00
	jr nz,.CheckHBlank
.ReadMemory
	ld a,[hl]
.DoubleCheckHBlank
	push af
	ld a,[rSTAT]
	and a,%00000011
	cp a,$00
	jr nz,.ReRead
	pop af
	ret
.ReRead
	pop af
	jr .CheckHBlank
.ReadMemoryDirectly
	ld a,[hl]
	ret
	
WriteVRAM:
	;if LCD is off
	push af
	ld a,[rLCDC]
	bit rLCDC_ENABLE,a
	jr z,.WriteMemoryDirectly
.CheckHBlank
	ld a,[rSTAT]
	and a,%00000011
	cp a,$00
	jr nz,.CheckHBlank
.WriteMemory
	pop af
	ld [hl],a
	push af
.DoubleCheckHBlank
	ld a,[rSTAT]
	and a,%00000011
	cp a,$00
	jr nz,.ReWrite
	pop af
	ret
.ReWrite
	jr .CheckHBlank
.WriteMemoryDirectly
	pop af
	ld [hl],a
	ret