!macro SEQ_PROFILER_A {
	lda VIC_RASTER_LOW
	sta profiler_temp
}

!macro SEQ_PROFILER_B .line {

	.addr	= $cc02 + .line * 40
	.color	= $d802 + .line * 40

	lda VIC_RASTER_LOW

	cmp profiler_temp
	bcc .no_prof

	ldy seq_current_track
	ldx seq_commands,y
	sbc profiler_temp
	sta .addr,x
	cmp .addr+40,x
	bcc .no_prof

	sta .addr+40,x
	lda #1
	sta .color,x
	sta .color+40,x
.no_prof
}

!macro FETCH_PROFILER_A {
	lda VIC_RASTER_LOW
	sta profiler_temp
}

!macro FETCH_PROFILER_B .line, .chan {
	.addr	= $cc02 + .line * 40 + .chan
	.color	= $d802 + .line * 40 + .chan

	lda VIC_RASTER_LOW

	cmp profiler_temp
	bcc .no_prof

	sbc profiler_temp
	sta .addr
	cmp .addr+40
	bcc .no_prof

	sta .addr+40
	lda #1
	sta .color
	sta .color+40
.no_prof
}

profiler_draw_popup
	lda #0
	ldx #<profiler_msgs_a
	ldy #>profiler_msgs_a
	sec
	jsr print_msg

	lda #0
	ldx #<profiler_msgs_b
	ldy #>profiler_msgs_b
	jsr print_msg

	lda #0
	ldx #<profiler_msgs_c
	ldy #>profiler_msgs_c
	jsr print_msg

	lda #0
	ldx #<profiler_msgs_d
	ldy #>profiler_msgs_d
	jsr print_msg

	ldx #15
	lda #0
-	sta $cc2a,x
	sta $cc52,x
	sta $cc7a,x
	sta $cca2,x
	sta $ccca,x
	sta $ccf2,x
	sta $cd1a,x
	sta $cd42,x
	dex
	bpl -

	ldx #15
	lda #0
-	sta $d82a,x
	sta $d852,x
	sta $d87a,x
	sta $d8a2,x
	sta $d8ca,x
	sta $d8f2,x
	sta $d91a,x
	sta $d942,x
	dex
	bpl -
rts

profiler_msgs_a
	!byte HOME,WHT
	!byte RIGHT,$ec
	!fill 36, $60
	!byte $bb,RETURN,0

profiler_msgs_b
	!text WHT,RIGHT,$7d,BLK
	!fill 17," "
	!text YEL,"_ current cmd start",DGRY,$7d,RETURN
	!text WHT,RIGHT,$7d,BLK
	!fill 17," "
	!text YEL,"_ max cmd start    ",DGRY,$7d,RETURN
	!text WHT,RIGHT,$7d,BLK
	!fill 17," "
	!text YEL,"_ current pre-tick ",DGRY,$7d,RETURN ; Underscore is 🠜 char
	!text WHT,RIGHT,$7d,BLK
	!fill 17," "
	!text YEL,"_ max pre-tick     ",DGRY,$7d,RETURN
	!byte 0

profiler_msgs_c
	!text WHT,RIGHT,$7d,BLK
	!fill 17," "
	!text YEL,"_ current post-tick",DGRY,$7d,RETURN
	!text WHT,RIGHT,$7d,BLK
	!fill 17," "
	!text YEL,"_ max post-tick    ",DGRY,$7d,RETURN
	!text WHT,RIGHT,$7d,BLK
	!fill 17," "
	!text YEL,"_ current fetch    ",DGRY,$7d,RETURN
	!text WHT,RIGHT,$7d,BLK
	!fill 17," "
	!text YEL,"_ max fetch        ",DGRY,$7d,RETURN
	!byte 0

profiler_msgs_d
	!byte RIGHT,$bc
	!fill 36, $60
	!byte $be,0
