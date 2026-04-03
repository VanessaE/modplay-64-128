!macro SEQ_PROFILER_A {
	lda VIC_RASTER_LOW
	sta profiler_temp
}

!macro SEQ_PROFILER_B .line {
	.addr	= VIC_SCREEN + 2 + .line * 40
	.color	= VIC_COLOR_RAM + 2 + .line * 40

	sec
	lda VIC_RASTER_LOW
	sbc profiler_temp
	bcc .no_prof

	stx .prof_x+1

	ldy seq_current_track
	ldx seq_commands,y

	cmp #10
	bcc +

	adc #101		; if the carry is set it'll be +101+48+carry = +150
+	adc #48			; if the carry is clear it'll be +48

	sta .addr,x
	cmp .addr+40,x
	bcc .prof_exit

	sta .addr+40,x
	lda #1
	sta .color,x
	sta .color+40,x

.prof_exit

.prof_x	ldx #0

.no_prof
}

!macro FETCH_PROFILER_A {
	lda VIC_RASTER_LOW
	sta profiler_temp
}

!macro FETCH_PROFILER_B .line, .chan {
	.addr	= VIC_SCREEN + 2 + .line * 40 + .chan
	.color	= VIC_COLOR_RAM + 2 + .line * 40 + .chan

	sec
	lda VIC_RASTER_LOW
	sbc profiler_temp
	bcc .no_prof

	cmp #10
	bcc +

	adc #101
+	adc #48

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
-	sta VIC_SCREEN + 42,x
	sta VIC_SCREEN + 82,x
	sta VIC_SCREEN + 122,x
	sta VIC_SCREEN + 162,x
	sta VIC_SCREEN + 202,x
	sta VIC_SCREEN + 242,x
	sta VIC_SCREEN + 282,x
	sta VIC_SCREEN + 322,x
	dex
	bpl -

	ldx #15
	lda #0
-	sta VIC_COLOR_RAM + 42,x
	sta VIC_COLOR_RAM + 82,x
	sta VIC_COLOR_RAM + 122,x
	sta VIC_COLOR_RAM + 162,x
	sta VIC_COLOR_RAM + 202,x
	sta VIC_COLOR_RAM + 242,x
	sta VIC_COLOR_RAM + 282,x
	sta VIC_COLOR_RAM + 322,x
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
