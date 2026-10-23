; multirate-related code -- POST-LOAD version

; Entry:   jsr/jmp multirate_generate_all
; Returns: .C set   = completed -- the tables area is valid, REU has been
;                     populated with new data, and multirate_valid = $80
;          .C clear = not enough RAM for all four levels; nothing extra was
;                     written to the REU, multirate_valid = 0 and the tables
;                     must be ignored.
;
; On success, highest_exp_addresss_used is raised past the multirate area.

; ----------------------------------------------------------------------------
; the number of bytes fetched per track per mixer block (a power of two, so
; that the mixer's cache offsets can be made by shifting), and the number of
; decimated levels generated.  the window caps the per-pair step at
; MULTIRATE_WINDOW/16 bytes, and each level halves the step again.

; the C64's low output rate wants the larger window (decimated steps stay
; large, so the nearest-neighbor timing error stays small).  the C128's higher
; rate leaves less time per block for the REU, so it keeps a smaller window.

!ifndef c128 {
	MULTIRATE_WINDOW_SHIFT = 6
	MULTIRATE_LEVELS = 2
} else {
	MULTIRATE_WINDOW_SHIFT = 5
	MULTIRATE_LEVELS = 2
}

MULTIRATE_WINDOW = 1 << MULTIRATE_WINDOW_SHIFT

; ----------------------------------------------------------------------------
; number of bytes of loop-head, and length of silence after every sample.  the
; fetcher can run up to MULTIRATE_WINDOW bytes past the end.

MULTIRATE_GUARD = MULTIRATE_WINDOW

; ---------------------------------------------------------------------------
; The multirate routines tables and variables sit at the top of the sample
; data buffer area instead of in the code

MULTIRATE_VARS_BASE = sample_data_buffer + 256

; 8 tables of MULTIRATE_LEVELS*32 entries, indexed level*32 + sample, with
; level = 1..MULTIRATE_LEVELS.  each table's base is offset down by 32 so that
; index 32 is its first entry.  the level 0 slots don't exist, level 0 uses the
; loader's own tables.  there are no loop-end tables: for a looped sample the
; end addr IS the loop end addr.
;
; space used: 8 * MULTIRATE_TABLE_LEN bytes of tables + 101 bytes of misc,
; starting 256 bytes into the 2048-byte sample data buffer.

MULTIRATE_TABLE_LEN = MULTIRATE_LEVELS * 32

multirate_sample_start_addresses_mids			= MULTIRATE_VARS_BASE + 0*MULTIRATE_TABLE_LEN - 32
multirate_sample_start_addresses_highs			= MULTIRATE_VARS_BASE + 1*MULTIRATE_TABLE_LEN - 32
multirate_sample_end_addresses_lows				= MULTIRATE_VARS_BASE + 2*MULTIRATE_TABLE_LEN - 32
multirate_sample_end_addresses_mids				= MULTIRATE_VARS_BASE + 3*MULTIRATE_TABLE_LEN - 32
multirate_sample_end_addresses_highs			= MULTIRATE_VARS_BASE + 4*MULTIRATE_TABLE_LEN - 32
multirate_sample_loop_start_addresses_lows		= MULTIRATE_VARS_BASE + 5*MULTIRATE_TABLE_LEN - 32
multirate_sample_loop_start_addresses_mids		= MULTIRATE_VARS_BASE + 6*MULTIRATE_TABLE_LEN - 32
multirate_sample_loop_start_addresses_highs		= MULTIRATE_VARS_BASE + 7*MULTIRATE_TABLE_LEN - 32

; everything else, after the tables

MULTIRATE_MISC = MULTIRATE_VARS_BASE + 8*MULTIRATE_TABLE_LEN

multirate_src_pages_lo							= MULTIRATE_MISC + 0		; 32 bytes
multirate_src_pages_hi							= MULTIRATE_MISC + 32		; 32 bytes
multirate_wptr_lows								= MULTIRATE_MISC + 64		; 4 bytes each: per-level
multirate_wptr_mids								= MULTIRATE_MISC + 68		; running write pointers
multirate_wptr_highs							= MULTIRATE_MISC + 72		; (level 1..4 = index 0..3)
multirate_valid									= MULTIRATE_MISC + 76		; $80 = tables valid
multirate_count									= MULTIRATE_MISC + 77
multirate_pages									= MULTIRATE_MISC + 78		; 2 bytes
multirate_len									= MULTIRATE_MISC + 80		; 2 bytes
multirate_sample_num							= MULTIRATE_MISC + 82
multirate_level_temp							= MULTIRATE_MISC + 83
multirate_index_temp							= MULTIRATE_MISC + 84
multirate_x_temp								= MULTIRATE_MISC + 85
multirate_y_temp								= MULTIRATE_MISC + 86
multirate_y_temp2								= MULTIRATE_MISC + 87
multirate_exp_source_pointer					= MULTIRATE_MISC + 88		; 3 bytes
multirate_exp_target_pointer					= MULTIRATE_MISC + 91		; 3 bytes
multirate_progbar_page_count					= MULTIRATE_MISC + 94		; 2 bytes
multirate_iir_state								= MULTIRATE_MISC + 96		; 4 bytes: per-level boost filter state
multirate_iir_cur								= MULTIRATE_MISC + 100		; the running level's state

!ifndef c128 {
	resampling_msg_row = 11
	resampling_msg_col = 12
} else {
	resampling_msg_row = 11
	resampling_msg_col = 32
}

!zone multirate_ops {

multirate_generate_all
	jsr multirate_count_source_pages
	jsr calculate_multirate_addrs
	bcc .no_room

	jsr multirate_draw_progress_bar

	jsr multirate_convert_all
	jsr multirate_update_progress		; the last pages may not have hit the
										; once-per-kB update, so finish the bar
	jsr multirate_finish_samples

	lda multirate_exp_target_pointer
	sta highest_exp_addresss_used
	lda multirate_exp_target_pointer+1
	sta highest_exp_addresss_used+1
	lda multirate_exp_target_pointer+2
	sta highest_exp_addresss_used+2
	sec

.no_room
	lda #0
	ror
	sta multirate_valid
rts

; number of 256-byte source pages to decimate for each sample:
;   (end page - start page) + 1 if the end isn't page-aligned
;   + 1 more page for looped samples, so the head-after-tail zone beyond
;     the loop end is decimated too (the loop end addr gets rounded up).

multirate_count_source_pages
	ldy #0

-	lda sample_start_addresses_mids,y
	ora sample_start_addresses_highs,y
	bne +

	sta multirate_src_pages_lo,y				; empty slot (.A = 0)
	sta multirate_src_pages_hi,y
	beq multirate_src_next

+	sec
	lda sample_end_addresses_mids,y
	sbc sample_start_addresses_mids,y
	sta multirate_pages
	lda sample_end_addresses_highs,y
	sbc sample_start_addresses_highs,y
	sta multirate_pages+1

	lda sample_end_addresses_lows,y
	cmp #1										; carry set if not page-aligned
	lda multirate_pages
	adc #0
	sta multirate_pages
	bcc multirate_src_noinc
	inc multirate_pages+1

multirate_src_noinc
	lda sample_default_loop_flags,y
	bpl multirate_src_store
	inc multirate_pages
	bne multirate_src_store
	inc multirate_pages+1

multirate_src_store
	lda multirate_pages
	sta multirate_src_pages_lo,y
	lda multirate_pages+1
	sta multirate_src_pages_hi,y

multirate_src_next
	iny
	cpy #32
	bne -
rts


; lay out all four levels.  returns .C set if the REU is too small (same test
; the header check uses: top bank must be below reu_highest_bank).

calculate_multirate_addrs

	; the first multirate sample goes at the first page above the highest exp addr

	clc
	lda #0
	sta multirate_exp_target_pointer
	lda highest_exp_addresss_used+1
	adc #1
	sta multirate_exp_target_pointer+1
	lda highest_exp_addresss_used+2
	adc #0
	sta multirate_exp_target_pointer+2

	!for .lvl, 1, MULTIRATE_LEVELS {
		ldx #.lvl
		jsr calc_addrs
	}

	lda reu_highest_bank
	cmp multirate_exp_target_pointer+2
rts

; enter with .X = decimation level (1= 256->128, 2=128->64, ...)

calc_addrs
	stx multirate_level_temp ; decimation level

	txa
	asl
	asl
	asl
	asl
	asl
	sta multirate_index_temp ; decimation level * 32

	ldy #0

multirate_addrs_next_sample

	; first check if this sample slot is empty

	lda sample_start_addresses_mids,y
	ora sample_start_addresses_highs,y
	bne multirate_addrs_not_empty

	ldx multirate_index_temp

	sta multirate_sample_start_addresses_mids,x
	sta multirate_sample_start_addresses_highs,x
	sta multirate_sample_end_addresses_lows,x
	sta multirate_sample_end_addresses_highs,x

	sta multirate_sample_loop_start_addresses_lows,x
	sta multirate_sample_loop_start_addresses_mids,x
	sta multirate_sample_loop_start_addresses_highs,x

	lda #1
	sta multirate_sample_end_addresses_mids,x

	jmp multirate_empty_sample

multirate_addrs_not_empty

	; pages to reserve = ceil(source pages / 2^L) + 1.  that covers everything
	; the conversion writes (source pages * 256>>L bytes) plus the guard bytes
	; after the end address, so nothing ever reaches the next sample's region.
	;
	;   (pages + (2<<L) - 1) >> L

	ldx multirate_level_temp
	clc
	lda multirate_src_pages_lo,y
	adc multirate_alloc_adds,x
	sta multirate_pages
	lda multirate_src_pages_hi,y
	adc #0
	sta multirate_pages+1

-	lsr multirate_pages+1
	ror multirate_pages
	dex
	bne -

	; if that region would cross a 512k boundary (the 64k-bank number >> 3
	; differs between its first and last page), start it at the next boundary

	sec
	lda multirate_pages
	sbc #1
	sta multirate_len
	lda multirate_pages+1
	sbc #0
	sta multirate_len+1

	clc
	lda multirate_exp_target_pointer+1
	adc multirate_len
	lda multirate_exp_target_pointer+2
	adc multirate_len+1
	eor multirate_exp_target_pointer+2
	and #$f8
	beq multirate_no_512k_cross

	lda multirate_exp_target_pointer+2
	ora #7
	clc
	adc #1
	bcc multirate_512k_store
	lda #$ff								; ran off the end of the address space
multirate_512k_store
	sta multirate_exp_target_pointer+2
	lda #0
	sta multirate_exp_target_pointer+1

multirate_no_512k_cross
	ldx multirate_index_temp
	lda multirate_exp_target_pointer+1
	sta multirate_sample_start_addresses_mids,x
	lda multirate_exp_target_pointer+2
	sta multirate_sample_start_addresses_highs,x

	; sample length in bytes (end - start), divided by 2 for each count of the
	; decimation level we're on

	sec
	lda sample_end_addresses_lows,y
	sta temp_counter
	lda sample_end_addresses_mids,y
	sbc sample_start_addresses_mids,y
	sta temp_counter+1
	lda sample_end_addresses_highs,y
	sbc sample_start_addresses_highs,y
	sta temp_counter+2

	ldx multirate_level_temp
-	lsr temp_counter+2
	ror temp_counter+1
	ror temp_counter
	dex
	bne -

	ldx multirate_index_temp

	; new end addr = new start addr + decimated length

	clc
	lda temp_counter
	sta multirate_sample_end_addresses_lows,x
	lda multirate_sample_start_addresses_mids,x
	adc temp_counter+1
	sta multirate_sample_end_addresses_mids,x
	lda multirate_sample_start_addresses_highs,x
	adc temp_counter+2
	sta multirate_sample_end_addresses_highs,x

	; check if there's a loop

	lda sample_default_loop_flags,y
	bmi multirate_has_loop

	lda #0
	sta multirate_sample_loop_start_addresses_lows,x
	sta multirate_sample_loop_start_addresses_mids,x
	sta multirate_sample_loop_start_addresses_highs,x

	jmp multirate_advance

	; loop start offset from sample start -> utility_pointer_c
	; loop length                          -> utility_pointer_b

multirate_has_loop
	sec
	lda sample_loop_start_addresses_lows,y
	sta utility_pointer_c
	lda sample_loop_start_addresses_mids,y
	sbc sample_start_addresses_mids,y
	sta utility_pointer_c+1
	lda sample_loop_start_addresses_highs,y
	sbc sample_start_addresses_highs,y
	sta utility_pointer_c+2

	sec
	lda sample_loop_end_addresses_lows,y
	sbc sample_loop_start_addresses_lows,y
	sta utility_pointer_b
	lda sample_loop_end_addresses_mids,y
	sbc sample_loop_start_addresses_mids,y
	sta utility_pointer_b+1
	lda sample_loop_end_addresses_highs,y
	sbc sample_loop_start_addresses_highs,y
	sta utility_pointer_b+2

	; round the loop length to nearest (add half a decimated sample) so the
	; loop's pitch error is at most half a decimated sample per loop

	ldx multirate_level_temp
	clc
	lda utility_pointer_b
	adc multirate_round_adds,x
	sta utility_pointer_b
	bcc multirate_round_done
	inc utility_pointer_b+1
	bne multirate_round_done
	inc utility_pointer_b+2

multirate_round_done
-	lsr utility_pointer_b+2
	ror utility_pointer_b+1
	ror utility_pointer_b

	lsr utility_pointer_c+2
	ror utility_pointer_c+1
	ror utility_pointer_c

	dex
	bne -

	; new loop start = new sample start + shifted offset
	; new end addr   = new loop start    + shifted length
	; (for a looped sample the end addr is the loop end addr)

	ldx multirate_index_temp

	clc
	lda utility_pointer_c
	sta multirate_sample_loop_start_addresses_lows,x
	lda multirate_sample_start_addresses_mids,x
	adc utility_pointer_c+1
	sta multirate_sample_loop_start_addresses_mids,x
	lda multirate_sample_start_addresses_highs,x
	adc utility_pointer_c+2
	sta multirate_sample_loop_start_addresses_highs,x

	clc
	lda multirate_sample_loop_start_addresses_lows,x
	adc utility_pointer_b
	sta multirate_sample_end_addresses_lows,x
	lda multirate_sample_loop_start_addresses_mids,x
	adc utility_pointer_b+1
	sta multirate_sample_end_addresses_mids,x
	lda multirate_sample_loop_start_addresses_highs,x
	adc utility_pointer_b+2
	sta multirate_sample_end_addresses_highs,x

multirate_advance

	; the next region starts right after this one

	ldx multirate_index_temp

	clc
	lda #0
	sta multirate_exp_target_pointer
	lda multirate_sample_start_addresses_mids,x
	adc multirate_pages
	sta multirate_exp_target_pointer+1
	lda multirate_sample_start_addresses_highs,x
	adc multirate_pages+1
	sta multirate_exp_target_pointer+2

multirate_empty_sample
	inc multirate_index_temp
	iny
	cpy #32
	beq +
	jmp multirate_addrs_next_sample
+
rts


; fetch each source page from the REU, decimate it through all four levels and
; stash the results at each level's running write pointer.

multirate_convert_all
	ldy #1

multirate_convert_next
	lda sample_start_addresses_mids,y
	ora sample_start_addresses_highs,y
	bne +
	jmp multirate_convert_skip

+	sty multirate_sample_num
	jsr multirate_begin_sample

	lda #0
	sta multirate_exp_source_pointer
	lda sample_start_addresses_mids,y
	sta multirate_exp_source_pointer+1
	lda sample_start_addresses_highs,y
	sta multirate_exp_source_pointer+2

	lda multirate_src_pages_lo,y
	sta multirate_pages
	lda multirate_src_pages_hi,y
	sta multirate_pages+1

multirate_convert_page
	lda #<load_buffer
	sta expansion_transfer_local_addr
	lda #>load_buffer
	sta expansion_transfer_local_addr+1
	lda #0
	sta stash_size
	lda #1
	sta stash_size+1

	lda multirate_exp_source_pointer
	sta expansion_memory_target_pointer
	lda multirate_exp_source_pointer+1
	sta expansion_memory_target_pointer+1
	lda multirate_exp_source_pointer+2
	sta expansion_memory_target_pointer+2

	+JSR_INDIRECT (fetch_block_vec)
	jsr multirate_process_block

; update progess bar, if it's enabled.  to limit the CPU spent on it, check
; if bits 1,0 of the page count are zero, so we only update once per kB.

	inc multirate_progbar_page_count
	bne +
	inc multirate_progbar_page_count+1

+	lda multirate_progbar_page_count
	and #$03
	bne +

	jsr multirate_update_progress

+	inc multirate_exp_source_pointer+1
	bne +
	inc multirate_exp_source_pointer+2

+	lda multirate_pages
	bne +
	dec multirate_pages+1
+	dec multirate_pages

	lda multirate_pages
	ora multirate_pages+1
	bne multirate_convert_page

	ldy multirate_sample_num

multirate_convert_skip
	iny
	cpy #32
	beq +
	jmp multirate_convert_next
+
rts


; enter with .Y = sample number.  points each level's running write pointer at
; the start of that sample's decimated data.  (level 1 is at index 32 + sample,
; level 2 at 64 + sample, and so on; wptr arrays are indexed by level - 1.)

multirate_begin_sample
	sty multirate_y_temp2

	tya
	clc
	adc #32
	tay

	ldx #0
-	lda multirate_sample_start_addresses_mids,y
	sta multirate_wptr_mids,x
	lda multirate_sample_start_addresses_highs,y
	sta multirate_wptr_highs,x
	lda #0
	sta multirate_wptr_lows,x
	lda #$80								; (silence) start each level's boost
	sta multirate_iir_state,x				; filter from mid-scale

	tya
	clc
	adc #32
	tay
	inx
	cpx #MULTIRATE_LEVELS
	bne -

	ldy multirate_y_temp2
rts


; load_buffer holds one 256-byte page of unsigned sample data.  decimate it
; level by level, pairwise-averaging in place, and stash each result at that
; level's running write pointer.  DESTROYS load_buffer.
;
; each averaged byte m also goes through a one-pole high-frequency boost, to
; make up for the droop of the 2-tap average:
;
;   s = (s + m + 1) >> 1       ; running low-pass, carried from page to page
;   out = clamp(m + ((m - s) >> 1))
;
; |m - s| is never more than 128, so it fits in a signed byte.

multirate_process_block
	lda #<load_buffer
	sta expansion_transfer_local_addr
	lda #>load_buffer
	sta expansion_transfer_local_addr+1

	lda #0
	sta multirate_level_temp

multirate_next_level
	ldx multirate_level_temp
	lda multirate_half_counts,x
	sta multirate_count
	sta stash_size
	lda #0
	sta stash_size+1

	lda multirate_iir_state,x
	sta multirate_iir_cur

	ldy #0						; dest
	ldx #0						; source = dest*2
-	lda load_buffer,x
	clc
	adc load_buffer+1,x
	ror							; .A = m, the average
	sta multirate_x_temp

	sec							; s = (s + m + 1) >> 1
	adc multirate_iir_cur
	ror
	sta multirate_iir_cur

	lda multirate_x_temp		; .A = (m - s) >> 1, arithmetic shift
	sec
	sbc multirate_iir_cur
	cmp #$80
	ror
	bmi .mrb_neg

	clc							; boost up, clamp at 255
	adc multirate_x_temp
	bcc .mrb_store
	lda #$ff
	bne .mrb_store

.mrb_neg
	clc							; boost down, clamp at 0
	adc multirate_x_temp
	bcs .mrb_store
	lda #0

.mrb_store
	sta load_buffer,y
	inx
	inx
	iny
	cpy multirate_count
	bne -

	ldx multirate_level_temp
	lda multirate_iir_cur
	sta multirate_iir_state,x

	lda multirate_wptr_lows,x
	sta expansion_memory_target_pointer
	lda multirate_wptr_mids,x
	sta expansion_memory_target_pointer+1
	lda multirate_wptr_highs,x
	sta expansion_memory_target_pointer+2

	+JSR_INDIRECT (stash_block_vec)

	ldx multirate_level_temp
	clc
	lda multirate_wptr_lows,x
	adc multirate_count
	sta multirate_wptr_lows,x
	bcc +
	inc multirate_wptr_mids,x
	bne +
	inc multirate_wptr_highs,x

+	inc multirate_level_temp
	lda multirate_level_temp
	cmp #MULTIRATE_LEVELS
	beq +
	jmp multirate_next_level
+
rts


; put MULTIRATE_GUARD bytes after each level's end so the fetcher can run off
; the end: looped samples get a copy of the first MULTIRATE_GUARD bytes of the
; loop after the loop end addr (= the end addr); everything else gets silence
; after the end addr.  level 0 is skipped, the loader already did its own.
;
; (a decimated loop is never shorter than 128 bytes, because the level-0 loop
; was already unrolled to at least 2 kB, so a single copy of the head is enough.)

multirate_finish_samples
	lda #<load_buffer
	sta expansion_transfer_local_addr
	lda #>load_buffer
	sta expansion_transfer_local_addr+1

	lda #32
	sta multirate_index_temp

multirate_finish_next
	ldx multirate_index_temp

	lda multirate_sample_start_addresses_mids,x			; empty slot?
	ora multirate_sample_start_addresses_highs,x
	bne +
	jmp multirate_finish_skip

+	lda multirate_sample_loop_start_addresses_mids,x	; looped?
	ora multirate_sample_loop_start_addresses_highs,x
	bne multirate_finish_loop

	lda multirate_sample_end_addresses_lows,x
	sta expansion_memory_target_pointer
	lda multirate_sample_end_addresses_mids,x
	sta expansion_memory_target_pointer+1
	lda multirate_sample_end_addresses_highs,x
	sta expansion_memory_target_pointer+2

	lda #$80
	ldy #MULTIRATE_GUARD-1
-	sta load_buffer,y
	dey
	bpl -

	lda #MULTIRATE_GUARD
	sta stash_size
	lda #0
	sta stash_size+1

	+JSR_INDIRECT (stash_block_vec)
	jmp multirate_finish_skip

multirate_finish_loop
	lda #MULTIRATE_GUARD
	sta stash_size
	lda #0
	sta stash_size+1

	lda multirate_sample_loop_start_addresses_lows,x
	sta expansion_memory_target_pointer
	lda multirate_sample_loop_start_addresses_mids,x
	sta expansion_memory_target_pointer+1
	lda multirate_sample_loop_start_addresses_highs,x
	sta expansion_memory_target_pointer+2

	+JSR_INDIRECT (fetch_block_vec)

	ldx multirate_index_temp
	lda multirate_sample_end_addresses_lows,x
	sta expansion_memory_target_pointer
	lda multirate_sample_end_addresses_mids,x
	sta expansion_memory_target_pointer+1
	lda multirate_sample_end_addresses_highs,x
	sta expansion_memory_target_pointer+2

	lda #MULTIRATE_GUARD
	sta stash_size
	lda #0
	sta stash_size+1

	+JSR_INDIRECT (stash_block_vec)

multirate_finish_skip
	inc multirate_index_temp
	lda multirate_index_temp
	cmp #(MULTIRATE_TABLE_LEN + 32)
	beq +
	jmp multirate_finish_next
+
rts

multirate_draw_progress_bar
	ldx #resampling_msg_row
	ldy #resampling_msg_col
	clc
	jsr PLOT

	lda #0
	ldx #<resampling_msg
	ldy #>resampling_msg
	sec
	jsr print_msg

	ldx #resampling_msg_row
	ldy #resampling_msg_col
	clc
	jsr PLOT

	lda #DOWN
	jsr CHROUT
	jsr CHROUT
	jsr CHROUT
	jsr CHROUT

	lda #" "
	ldy #15
-	jsr CHROUT
	dey
	bne -

	lda #CYAN
	sta progress_bar_color

	lda #(loader_progbar_len * 8)
	ldx #loader_progbar_column
	ldy #loader_progbar_row
	jsr draw_empty_progress_bar

	lda #0
	sta multirate_progbar_page_count
	sta multirate_progbar_page_count+1
	sta dividend
	sta dividend+2

	; the total number of source pages that the decimation will work through
	; is the sum of what multirate_count_source_pages worked out for each
	; sample.

	lda #0
	sta dividend+1
	sta dividend+2

	ldy #31
-	clc
	lda dividend+1
	adc multirate_src_pages_lo,y
	sta dividend+1
	lda dividend+2
	adc multirate_src_pages_hi,y
	sta dividend+2
	dey
	bpl -

	; divide the result by the number of progress bar segments

	lda #(loader_progbar_len * 8)
	sta divisor
	lda #0
	sta divisor+1
	sta divisor+2
	jsr divide_24by24

	lda quotient
	sta progress_bar_bytes_per_segment
	lda quotient+1
	sta progress_bar_bytes_per_segment+1
	lda quotient+2
	sta progress_bar_bytes_per_segment+2
rts

multirate_update_progress
	lda #0
	sta dividend
	lda multirate_progbar_page_count
	sta dividend+1
	lda multirate_progbar_page_count+1
	sta dividend+2

	lda progress_bar_bytes_per_segment
	sta divisor
	lda progress_bar_bytes_per_segment+1
	sta divisor+1
	lda progress_bar_bytes_per_segment+2
	sta divisor+2
	jsr divide_24by24

	lda quotient+1						; never ask for more than the whole bar
	ora quotient+2
	bne .mpu_full
	lda quotient
	cmp #(loader_progbar_len * 8 + 1)
	bcc .mpu_ok

.mpu_full
	lda #(loader_progbar_len * 8)

.mpu_ok
jmp update_progress_bar

; constant lookup tables (read-only, stay in the code)

multirate_half_counts							!byte 128,64,32,16
multirate_alloc_adds							!byte 0,3,7,15,31	; (2<<level)-1, by level 1..4
multirate_round_adds							!byte 0,1,2,4,8		; 1<<(level-1), by level 1..4

resampling_msg
	!text CYAN,"  Resampling...",0
}

; ----------------------------------------------------------------------------
; PLAYER-SIDE ROUTINES
;
; these are called from the sequencer, only when a note starts (never from the
; ISR).  the level for a note is the smallest decimation level at which the
; fastest pitch the note can reach within its row steps by no more than
; MULTIRATE_WINDOW/16 bytes per output sample pair.  a block's step rate
; (fract, int) is 16 times the per-pair step, so the limit is MULTIRATE_WINDOW
; in those units (the integer part).
;
; variables and tables live here in the main image, in RAM, because the
; sequencer code that uses them has the ROMs banked out.

!zone multirate_player {

mrp_track										!byte 0
mrp_sample										!byte 0
mrp_tmp											!byte 0
mrp_period_lo									!byte 0
mrp_period_hi									!byte 0
mrp_step_fract									!byte 0
mrp_step_int									!byte 0
mrp_pr_track									!byte 0
mrp_pr_sample									!byte 0
mrp_pr_mid										!byte 0
mrp_pr_hi										!byte 0
mrp_pr_count									!byte 0

multirate_level_bases							!byte 0,32,64,96,128

; enter with .X = sample number and .Y = track number, right after
; start_sample has installed the level-0 pointers for the new note.  chooses
; the note's level and, if it isn't 0, swaps in that level's start pointer,
; end address and loop start.  .X and .Y are preserved.

multirate_apply_level
	stx mrp_sample
	sty mrp_track

	jsr multirate_choose_level			; returns .A = level, .Y = track
	sta current_multirate_levels,y
	tax
	beq .mral_done

	lda multirate_level_bases,x
	ora mrp_sample
	tax									; .X = level*32 + sample

	lda seq_commands,y
	cmp #9								; the set-sample-offset command sets
	beq +								; the pointer itself, so leave it

	lda multirate_sample_start_addresses_mids,x
	sta current_sample_pointers_mids,y
	lda multirate_sample_start_addresses_highs,x
	sta current_sample_pointers_highs,y

+	lda multirate_sample_end_addresses_lows,x
	sta current_sample_end_addr_lows,y
	lda multirate_sample_end_addresses_mids,x
	sta current_sample_end_addr_mids,y
	lda multirate_sample_end_addresses_highs,x
	sta current_sample_end_addr_highs,y

	lda multirate_sample_loop_start_addresses_lows,x
	sta current_loop_start_lows,y
	lda multirate_sample_loop_start_addresses_mids,x
	sta current_loop_start_mids,y
	lda multirate_sample_loop_start_addresses_highs,x
	sta current_loop_start_highs,y

.mral_done
	ldx mrp_sample
	ldy mrp_track
rts


; enter with .Y = track number, row data for the new note available.
; returns .A = level 0..4, .Y = track number.
;
; the fastest reachable pitch within the row is worked out for:
;   0xy  arpeggio             highest semitone offset in the argument
;   1xx  slide up             period minus rate * (ticks - 1), min 57
;   4xy/6xy vibrato           period minus 1/16 of itself (a bit more than
;                             the deepest vibrato goes)
;   E1x  fine slide up        period minus x
; anything beyond that (a slide continuing over several rows, fine tuning)
; is dealt with by promoting the note to a higher level mid-note, in
; multirate_shift_steprate (and multirate_arp_promote for arpeggios).

multirate_choose_level
	sty mrp_track

	ldx seq_cur_track_data_offset
	lda seq_current_row_data+2,x
	sta mrp_period_lo
	lda seq_current_row_data+1,x
	and #$0f
	sta mrp_period_hi

	lda seq_command_arguments,y			; .A = argument
	ldx seq_commands,y					; .X = command

	cpx #1
	beq .mrcl_slide_up
	cpx #4
	beq .mrcl_vibrato
	cpx #6
	beq .mrcl_vibrato
	cpx #14
	beq .mrcl_extended
	jmp .mrcl_lookup

.mrcl_slide_up
	sta mrp_tmp
	lda #0
	sta mrp_step_fract
	sta mrp_step_int

	ldx seq_ticks_per_division
	dex
	bne .mrcl_slide_sum
	jmp .mrcl_lookup

.mrcl_slide_sum
	clc
	lda mrp_step_fract
	adc mrp_tmp
	sta mrp_step_fract
	bcc +
	inc mrp_step_int
+	dex
	bne .mrcl_slide_sum
	jmp .mrcl_subtract

.mrcl_vibrato
	lda mrp_period_hi
	sta mrp_step_int
	lda mrp_period_lo
	sta mrp_step_fract
	ldx #4
-	lsr mrp_step_int
	ror mrp_step_fract
	dex
	bne -
	jmp .mrcl_subtract

.mrcl_extended
	sta mrp_tmp
	and #$f0
	cmp #$10							; only E1x (fine slide up) matters
	beq +
	jmp .mrcl_lookup

+	lda mrp_tmp
	and #$0f
	sta mrp_step_fract
	lda #0
	sta mrp_step_int

	; subtract the amount in mrp_step_int/fract from the period, but don't
	; let it go below 57

.mrcl_subtract
	sec
	lda mrp_period_lo
	sbc mrp_step_fract
	sta mrp_period_lo
	lda mrp_period_hi
	sbc mrp_step_int
	sta mrp_period_hi
	bcc .mrcl_force_min
	bne .mrcl_lookup					; (.Z is still from the SBC above)
	lda mrp_period_lo
	cmp #57
	bcs .mrcl_lookup

.mrcl_force_min
	lda #57
	sta mrp_period_lo
	lda #0
	sta mrp_period_hi

	; look up the step rate for that period

.mrcl_lookup
	lda mrp_period_lo
	sta utility_pointer
	lda mrp_period_hi
	asl utility_pointer
	rol
	sta utility_pointer+1

	clc
	lda utility_pointer
	adc #<steprate_lookup_table
	sta utility_pointer
	lda utility_pointer+1
	adc #>steprate_lookup_table
	sta utility_pointer+1

	ldy #0
	lda (utility_pointer),y
	sta mrp_step_fract
	iny
	lda (utility_pointer),y
	sta mrp_step_int

	ldy mrp_track
	lda seq_commands,y
	bne .mrcl_find_level
	lda seq_command_arguments,y			; arpeggio, but only if it has an
	beq .mrcl_find_level				; argument

	; scale by the larger of the two semitone offsets

	sta mrp_tmp
	lsr
	lsr
	lsr
	lsr
	tax									; .X = high nybble
	lda mrp_tmp
	and #$0f							; .A = low nybble
	stx mrp_tmp
	cmp mrp_tmp
	bcs +
	lda mrp_tmp
+	asl									; table entries are 16 bits
	tax
	lda semitones_table,x
	sta multiplicand_b
	lda semitones_table+1,x
	sta multiplicand_b+1
	lda mrp_step_fract
	sta multiplicand_a
	lda mrp_step_int
	sta multiplicand_a+1

	sec
	jsr multiply_16x16

	lda product+1
	sta mrp_step_fract
	lda product+2
	sta mrp_step_int

	; halve until it's at most MULTIRATE_WINDOW.0, up to MULTIRATE_LEVELS times

.mrcl_find_level
	ldx #0

.mrcl_level_loop
	lda mrp_step_int
	cmp #(MULTIRATE_WINDOW + 1)
	bcs .mrcl_shift
	cmp #MULTIRATE_WINDOW
	bcc .mrcl_level_done
	lda mrp_step_fract
	beq .mrcl_level_done

.mrcl_shift
	cpx #MULTIRATE_LEVELS
	beq .mrcl_level_done
	lsr mrp_step_int
	ror mrp_step_fract
	inx
	bne .mrcl_level_loop

.mrcl_level_done
	ldy mrp_track
	txa
rts


; enter with .X = track number, with the table-lookup step rate already in
; current_steprates_fracts/ints (not yet shifted).  if the rate, shifted by the
; track's level, would be more than MULTIRATE_WINDOW.0, the note is promoted to
; the next level (repeatedly, if need be) until it fits or the top level is
; reached.  then the rate is shifted by the final level, and clamped to
; MULTIRATE_WINDOW.0 so that a track never needs more than the MULTIRATE_WINDOW
; bytes of its cache (the clamp can only still bite at the top level).
; preserves .X, trashes .A and .Y.  (in striding mode, when multirate isn't in
; use for the file, it does nothing at all.)

multirate_shift_steprate
	bit multirate_enable
	bmi .mrss_check
	rts									; striding mode:  no levels, no clamp

.mrss_check
	ldy current_multirate_levels,x
	cpy #MULTIRATE_LEVELS
	bcs .mrss_shift

	lda current_steprates_ints,x
	sta mrp_step_int
	lda current_steprates_fracts,x
	sta mrp_step_fract
	cpy #0
	beq .mrss_test
-	lsr mrp_step_int
	ror mrp_step_fract
	dey
	bne -

.mrss_test
	lda mrp_step_int
	cmp #(MULTIRATE_WINDOW + 1)
	bcs .mrss_promote
	cmp #MULTIRATE_WINDOW
	bcc .mrss_shift
	lda mrp_step_fract
	beq .mrss_shift

.mrss_promote
	jsr multirate_promote_track
	jmp .mrss_check

.mrss_shift
	lda current_multirate_levels,x
	beq .mrss_clamp
	tay
-	lsr current_steprates_ints,x
	ror current_steprates_fracts,x
	dey
	bne -

.mrss_clamp
	lda current_steprates_ints,x
	cmp #(MULTIRATE_WINDOW + 1)
	bcs .mrss_set
	cmp #MULTIRATE_WINDOW
	bcc .mrss_done
	lda current_steprates_fracts,x
	beq .mrss_done

.mrss_set
	lda #MULTIRATE_WINDOW
	sta current_steprates_ints,x
	lda #0
	sta current_steprates_fracts,x

.mrss_done
rts


; enter with .X = track number whose level is below MULTIRATE_LEVELS.  moves
; the playing note up one decimation level, in place:  the position within the
; sample is halved (fraction included), and the end address and loop start
; are replaced by the next level's.  the level is incremented.  the caller must
; redo the track's step rate.  preserves .X, trashes .A and .Y.
;
; the instrument self-mod routine works on seq_current_track, which is the
; same as .X for every caller here (like the pitch self-mod that follows).

multirate_promote_track
	stx mrp_pr_track

	; start address of the current level's copy -> mrp_pr_mid/hi

	lda current_sample_numbers,x
	sta mrp_pr_sample
	lda current_multirate_levels,x
	bne .mrpt_old_level

	ldy mrp_pr_sample					; level 0 is the loader's own copy
	lda sample_start_addresses_mids,y
	sta mrp_pr_mid
	lda sample_start_addresses_highs,y
	sta mrp_pr_hi
	jmp .mrpt_have_old

.mrpt_old_level
	tay
	lda multirate_level_bases,y
	ora mrp_pr_sample
	tay
	lda multirate_sample_start_addresses_mids,y
	sta mrp_pr_mid
	lda multirate_sample_start_addresses_highs,y
	sta mrp_pr_hi

	; offset into the sample = pointer - start, as hi:mid:low.fract (the
	; start addresses are page-aligned), then halve all 32 bits of it

.mrpt_have_old
	sec
	lda current_sample_pointers_mids,x
	sbc mrp_pr_mid
	sta mrp_pr_mid
	lda current_sample_pointers_highs,x
	sbc mrp_pr_hi
	lsr
	sta mrp_pr_hi
	ror mrp_pr_mid
	ror current_sample_pointers_lows,x
	ror current_sample_pointers_fracts,x

	; next level, and its table index

	lda current_multirate_levels,x
	clc
	adc #1
	sta current_multirate_levels,x
	tay
	lda multirate_level_bases,y
	ora mrp_pr_sample
	tay									; .Y = (level+1)*32 + sample

	clc
	lda mrp_pr_mid
	adc multirate_sample_start_addresses_mids,y
	sta current_sample_pointers_mids,x
	lda mrp_pr_hi
	adc multirate_sample_start_addresses_highs,y
	sta current_sample_pointers_highs,x

	lda multirate_sample_end_addresses_lows,y
	sta current_sample_end_addr_lows,x
	lda multirate_sample_end_addresses_mids,y
	sta current_sample_end_addr_mids,x
	lda multirate_sample_end_addresses_highs,y
	sta current_sample_end_addr_highs,x

	lda multirate_sample_loop_start_addresses_lows,y
	sta current_loop_start_lows,x
	lda multirate_sample_loop_start_addresses_mids,y
	sta current_loop_start_mids,x
	lda multirate_sample_loop_start_addresses_highs,y
	sta current_loop_start_highs,x

	lsr current_fetch_loop_ofl_amounts,x	; (pending loop overshoot, in bytes)

	+JSR_INDIRECT (do_selfmod_instrument_vec)	; new end addr -> fetcher

	ldx mrp_pr_track
rts


; the arpeggio's two extra notes are made from the base step rate and bypass
; multirate_shift_steprate, so promote the note here, at the start of an
; arpeggio, far enough that the higher of the two still fits the window.
; enter with .X = track number (arpeggio argument non-zero).  preserves .X
; and .Y.  if the level changed, the base pitch is redone for the new level.

multirate_arp_promote
	bit multirate_enable
	bmi +
	jmp .mrap_none

+	lda current_track_gate_flags,x
	bmi +
	jmp .mrap_none

+	lda current_multirate_levels,x
	cmp #MULTIRATE_LEVELS
	bcc +
	jmp .mrap_none

+	stx mrp_track
	lda #0
	sta mrp_pr_count

	; unshifted base step rate for the note period -> multiplicand_a

	lda current_note_periods_lows,x
	sta utility_pointer
	lda current_note_periods_highs,x
	asl utility_pointer
	rol
	sta utility_pointer+1

	clc
	lda utility_pointer
	adc #<steprate_lookup_table
	sta utility_pointer
	lda utility_pointer+1
	adc #>steprate_lookup_table
	sta utility_pointer+1

	ldy #0
	lda (utility_pointer),y
	sta multiplicand_a
	iny
	lda (utility_pointer),y
	sta multiplicand_a+1

	; scale by the larger of the two semitone offsets

	lda seq_command_arguments,x
	sta mrp_tmp
	lsr
	lsr
	lsr
	lsr
	sta mrp_step_int
	lda mrp_tmp
	and #$0f
	cmp mrp_step_int
	bcs +
	lda mrp_step_int
+	asl
	tax
	lda semitones_table,x
	sta multiplicand_b
	lda semitones_table+1,x
	sta multiplicand_b+1

	sec
	jsr multiply_16x16

	lda product+1
	sta mrp_step_fract
	lda product+2
	sta mrp_step_int

	; shift by the note's current level, then promote until it fits

	ldx mrp_track
	ldy current_multirate_levels,x
	beq .mrap_check
-	lsr mrp_step_int
	ror mrp_step_fract
	dey
	bne -

.mrap_check
	lda mrp_step_int
	cmp #(MULTIRATE_WINDOW + 1)
	bcs .mrap_promote
	cmp #MULTIRATE_WINDOW
	bcc .mrap_finish
	lda mrp_step_fract
	beq .mrap_finish

.mrap_promote
	lsr mrp_step_int
	ror mrp_step_fract
	jsr multirate_promote_track
	inc mrp_pr_count
	lda current_multirate_levels,x
	cmp #MULTIRATE_LEVELS
	bcc .mrap_check

.mrap_finish
	lda mrp_pr_count
	beq .mrap_restore
	ldy mrp_track
	jsr set_pitch_by_table_lookup

.mrap_restore
	ldx mrp_track
	ldy mrp_track
.mrap_none
rts


; enter with .X = track number.  shifts the table-lookup step rate that the
; arpeggio start routine has put in multiplicand_a down by the track's level.
; trashes .A and .Y.

multirate_shift_multiplicand_a
	lda current_multirate_levels,x
	beq +
	tay
-	lsr multiplicand_a+1
	ror multiplicand_a
	dey
	bne -
+
rts


; the set-sample-offset command for a track that's using a decimated copy of
; its sample.  the offset is xx*256 bytes of the original, so here that's
; xx*256 >> level.  enter with .Y = track number.

multirate_set_sample_offset
	sty mrp_track

	lda current_multirate_levels,y
	sta mrp_tmp
	tax
	lda multirate_level_bases,x
	ora current_sample_numbers,y
	tax									; .X = level*32 + sample

	lda #0
	sta utility_pointer
	lda seq_command_arguments,y
	sta utility_pointer+1

	ldy mrp_tmp
-	lsr utility_pointer+1
	ror utility_pointer
	dey
	bne -

	ldy mrp_track
	lda utility_pointer
	sta current_sample_pointers_lows,y

	clc									; (the decimated copies' start
	lda multirate_sample_start_addresses_mids,x		; addresses are page-aligned)
	adc utility_pointer+1
	sta current_sample_pointers_mids,y
	lda multirate_sample_start_addresses_highs,x
	adc #0
	sta current_sample_pointers_highs,y

	lda #0
	sta current_sample_pointers_fracts,y
rts

}
