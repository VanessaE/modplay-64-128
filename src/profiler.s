; This file contains a primitive profiler for the player

; if the build isn't for SCPU or C64U/U64, we don't need to use timers.

!ifdef scpu {
	profiler_use_timers = 1
} else ifdef c64u {
	profiler_use_timers = 1
}


!macro SEQ_PROFILER_A {
	; start timer B, one-shot mode, counting ....
	!ifdef c64u {			; on C64U, count Phi2 clock cycles
		lda #$11
		sta CIA1_CRB
	} else ifdef scpu {		; on SCPU, count timer A underflows (Phi2 * 10)
		lda #$59
		sta CIA1_CRB
	} else {
		lda VIC_RASTER_LOW
		sta profiler_temp
	}
}

!macro SEQ_PROFILER_B .line {
	.addr	= VIC_SCREEN + 2 + .line * 40
	.color	= VIC_COLOR_RAM + 2 + .line * 40

	!ifdef profiler_use_timers {
		lda #0
		sta CIA1_CRB
		sec
		lda #255
		sbc CIA1_TIMER_B_LOW
	} else {
		sec
		lda VIC_RASTER_LOW
		sbc profiler_temp
		bcc .no_prof
	}

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
	!ifdef c64u {
		lda #$11
		sta CIA1_CRB
	} else ifdef scpu {
		lda #$59
		sta CIA1_CRB
	} else {
		lda VIC_RASTER_LOW
		sta profiler_temp
	}
}

!macro FETCH_PROFILER_B .line, .chan {
	.addr	= VIC_SCREEN + 2 + .line * 40 + .chan
	.color	= VIC_COLOR_RAM + 2 + .line * 40 + .chan

	!ifdef profiler_use_timers {
		lda #0
		sta CIA1_CRB
		sec
		lda #255
		sbc CIA1_TIMER_B_LOW
	} else {
		sec
		lda VIC_RASTER_LOW
		sbc profiler_temp
		bcc .no_prof
	}

	sta prof_trk_time_buf_cur + .chan
	cmp prof_trk_time_buf_max + .chan
	bcc +
	sta prof_trk_time_buf_max + .chan

+	cmp #10
	bcc +

	adc #101
+	adc #48

	sta .addr
	cmp .addr+40
	bcc .pf_sums

	sta .addr+40
	lda #1
	sta .color
	sta .color+40

	; these print the sums of the fetch times
.pf_sums
	clc
	lda prof_trk_time_buf_cur
	adc prof_trk_time_buf_cur + 1
	adc prof_trk_time_buf_cur + 2
	adc prof_trk_time_buf_cur + 3

	cmp #10
	bcc +

	adc #101
+	adc #48

	sta .addr + 7

	lda prof_trk_time_buf_max
	adc prof_trk_time_buf_max + 1
	adc prof_trk_time_buf_max + 2
	adc prof_trk_time_buf_max + 3

	cmp #10
	bcc +

	adc #101
+	adc #48

	sta .addr+40 + 7
.no_prof
}

profiler_setup
	ldx #16
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

	ldx #16
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

	ldx #7
	lda #0
-	sta prof_trk_time_buf_cur,x
	sta prof_trk_time_buf_max,x
	dex
	bpl -

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


	lda #0
	ldx #<profiler_count_type
	ldy #>profiler_count_type
	jsr print_msg

	!ifdef profiler_use_timers {
		lda #$7f					; Disable CIA and VIC IRQs, if any
		sta CIA1_ICR
		lda #0
		sta VIC_IRQ_MASK

		lda #0						; and stop both CIA #1 timers
		sta CIA1_CRA
		sta CIA1_CRB

		!ifdef scpu {
			lda #9					; on SCPU, we'll count in intervals of
			sta CIA1_TIMER_A_LOW	; 10 Phi2 cycles
			lda #0
			sta CIA1_TIMER_A_HIGH
		}

		lda #255					; We;ll set timer B to count down at most
		sta CIA1_TIMER_B_LOW		; 256 cycles or underflows (so that we can
		lda #0						; subtract just one byte for the compare)
		sta CIA1_TIMER_B_HIGH

		lda #$11					; start timer A, continuous mode, counting
		sta CIA1_CRA				; Phi2
	}
rts

profiler_msgs_a
	!byte HOME,WHT
	!byte RIGHT,$ec
	!fill 36, $60
	!byte $bb,RETURN,0

profiler_msgs_b
	!text WHT,RIGHT,$7d,BLK
	!fill 17,RIGHT
	!text YEL,"_ current cmd start",DGRY,$7d,RETURN
	!text WHT,RIGHT,$7d,BLK
	!fill 17,RIGHT
	!text YEL,"_ max cmd start    ",DGRY,$7d,RETURN
	!text WHT,RIGHT,$7d,BLK
	!fill 17,RIGHT
	!text YEL,"_ current pre-tick ",DGRY,$7d,RETURN ; Underscore is 🠜 char
	!text WHT,RIGHT,$7d,BLK
	!fill 17,RIGHT
	!text YEL,"_ max pre-tick     ",DGRY,$7d,RETURN
	!byte 0

profiler_msgs_c
	!text WHT,RIGHT,$7d,BLK
	!fill 17,RIGHT
	!text YEL,"_ current post-tick",DGRY,$7d,RETURN
	!text WHT,RIGHT,$7d,BLK
	!fill 17,RIGHT
	!text YEL,"_ max post-tick    ",DGRY,$7d,RETURN
	!text WHT,RIGHT,$7d,BLK
	!fill 5,RIGHT
	!text LGRY,"=",RIGHT,WHT," ",BLK
	!fill 9,RIGHT
	!text YEL,"_ current fetch    ",DGRY,$7d,RETURN
	!text WHT,RIGHT,$7d,BLK
	!fill 5,RIGHT
	!text LGRY,"=",RIGHT,WHT," ",BLK
	!fill 9,RIGHT
	!text YEL,"_ max fetch        ",DGRY,$7d,RETURN
	!byte 0

profiler_msgs_d
	!byte RIGHT,$bc
	!fill 36, $60
	!byte $be,0

profiler_count_type
	!byte HOME
	!fill 9,DOWN
	!fill 3,RIGHT
	!ifdef c64u {
		!text RIGHT,MGRY,"[Phi2 cycles]",0
	} else ifdef scpu {
		!text MGRY, "[x10 Phi2 cycles]",0
	} else {
		!text MGRY, "[raster lines]",0
	}

prof_trk_time_buf_cur
	!fill 8,0
prof_trk_time_buf_max
	!fill 8,0
