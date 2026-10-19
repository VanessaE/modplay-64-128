; multirate-related code -- POST-LOAD version
;
; Runs once, at the very end of the loader (after unroll_mod_sample_loops), and
; builds decimated copies (1/2, 1/4, 1/8, 1/16 rate = levels 1..4) of every
; sample from the finished, unrolled data already sitting in the REU.
; Level 0 is the original data and is never touched.
;
; Table index for level L (1..4), sample S (0..31) is (L-1)*32 + S.
;
; Entry:   jsr/jmp multirate_generate_all
; Returns: .C clear = done, tables valid, multirate_valid = $80
;          .C set   = not enough REU for all four levels; nothing was written to
;                     the REU, multirate_valid = 0 and the tables must be ignored.
;
; On success highest_exp_addresss_used is raised past the multirate area.

MULTIRATE_GUARD = 32		; bytes of loop-head / silence placed after every end addr

; ---------------------------------------------------------------------------
; Variables and the multirate tables live in RAM at the top of the sample data
; buffer area instead of in the code, because they must survive into playback
; but the load buffer is free by then.  Define MULTIRATE_VARS_END in constants.h
; as the first address AFTER this block (it should be 128-byte aligned so no
; table access ever crosses a page).  The block is MULTIRATE_VARS_SIZE bytes
; and is fully (re)initialised by multirate_generate_all.

MULTIRATE_VARS_BASE = sample_data_buffer + 256

; 11 tables of 32*4 entries, indexed (level-1)*32 + sample

multirate_sample_start_addresses_mids			= MULTIRATE_VARS_BASE + 0*128
multirate_sample_start_addresses_highs			= MULTIRATE_VARS_BASE + 1*128
multirate_sample_end_addresses_lows				= MULTIRATE_VARS_BASE + 2*128
multirate_sample_end_addresses_mids				= MULTIRATE_VARS_BASE + 3*128
multirate_sample_end_addresses_highs			= MULTIRATE_VARS_BASE + 4*128
multirate_sample_loop_start_addresses_lows		= MULTIRATE_VARS_BASE + 5*128
multirate_sample_loop_start_addresses_mids		= MULTIRATE_VARS_BASE + 6*128
multirate_sample_loop_start_addresses_highs		= MULTIRATE_VARS_BASE + 7*128
multirate_sample_loop_end_addresses_lows		= MULTIRATE_VARS_BASE + 8*128
multirate_sample_loop_end_addresses_mids		= MULTIRATE_VARS_BASE + 9*128
multirate_sample_loop_end_addresses_highs		= MULTIRATE_VARS_BASE + 10*128

; everything else, after the tables

MULTIRATE_MISC = MULTIRATE_VARS_BASE + 11*128

multirate_src_pages_lo							= MULTIRATE_MISC + 0		; 32 bytes
multirate_src_pages_hi							= MULTIRATE_MISC + 32		; 32 bytes
multirate_wptr_lows								= MULTIRATE_MISC + 64		; 4 bytes each: per-level
multirate_wptr_mids								= MULTIRATE_MISC + 68		; running write pointers
multirate_wptr_highs							= MULTIRATE_MISC + 72
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

!zone multirate_ops {

multirate_generate_all
	jsr multirate_count_source_pages
	jsr calculate_multirate_addrs
	bcc .no_room

	jsr multirate_convert_all
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

	ldx #1
	jsr calc_addrs
	ldx #2
	jsr calc_addrs
	ldx #3
	jsr calc_addrs
	ldx #4
	jsr calc_addrs

	lda reu_highest_bank
	cmp multirate_exp_target_pointer+2
rts

; enter with .X = decimation level (1= 256->128, 2=128->64, ...)

calc_addrs
	stx multirate_level_temp ; original decimation level 

	dex
	txa
	asl
	asl
	asl
	asl
	asl
	sta multirate_index_temp ; (decimation level - 1) * 32

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
	sta multirate_sample_loop_end_addresses_lows,x
	sta multirate_sample_loop_end_addresses_mids,x
	sta multirate_sample_loop_end_addresses_highs,x

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
	sta multirate_sample_loop_end_addresses_lows,x
	sta multirate_sample_loop_end_addresses_mids,x
	sta multirate_sample_loop_end_addresses_highs,x

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
	; new loop end   = new loop start    + shifted length

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
	sta multirate_sample_loop_end_addresses_lows,x
	lda multirate_sample_loop_start_addresses_mids,x
	adc utility_pointer_b+1
	sta multirate_sample_loop_end_addresses_mids,x
	lda multirate_sample_loop_start_addresses_highs,x
	adc utility_pointer_b+2
	sta multirate_sample_loop_end_addresses_highs,x

	; for a looped sample the end addr is the loop end addr

	lda multirate_sample_loop_end_addresses_lows,x
	sta multirate_sample_end_addresses_lows,x
	lda multirate_sample_loop_end_addresses_mids,x
	sta multirate_sample_end_addresses_mids,x
	lda multirate_sample_loop_end_addresses_highs,x
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

	inc multirate_exp_source_pointer+1
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
; the start of that sample's decimated data.

multirate_begin_sample
	sty multirate_y_temp2

	ldx #0
-	lda multirate_sample_start_addresses_mids,y
	sta multirate_wptr_mids,x
	lda multirate_sample_start_addresses_highs,y
	sta multirate_wptr_highs,x
	lda #0
	sta multirate_wptr_lows,x

	tya
	clc
	adc #32
	tay
	inx
	cpx #4
	bne -

	ldy multirate_y_temp2
rts


; load_buffer holds one 256-byte page of unsigned sample data.  decimate it
; level by level, pairwise-averaging in place, and stash each result at that
; level's running write pointer.  DESTROYS load_buffer.

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

	ldy #0						; dest
	ldx #0						; source = dest*2
-	lda load_buffer,x
	clc
	adc load_buffer+1,x
	ror
	sta load_buffer,y
	inx
	inx
	iny
	cpy multirate_count
	bne -

	ldx multirate_level_temp
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
	cmp #4
	beq +
	jmp multirate_next_level
+
rts


; put MULTIRATE_GUARD bytes after each level's end so the fetcher can run off
; the end: looped samples get a copy of the first MULTIRATE_GUARD bytes of the
; loop after the loop end addr; everything else gets silence after the end addr.
;
; (a decimated loop is never shorter than 128 bytes, because the level-0 loop
; was already unrolled to at least 2 kB, so a single copy of the head is enough.)

multirate_finish_samples
	lda #<load_buffer
	sta expansion_transfer_local_addr
	lda #>load_buffer
	sta expansion_transfer_local_addr+1

	lda #0
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
	lda multirate_sample_loop_end_addresses_lows,x
	sta expansion_memory_target_pointer
	lda multirate_sample_loop_end_addresses_mids,x
	sta expansion_memory_target_pointer+1
	lda multirate_sample_loop_end_addresses_highs,x
	sta expansion_memory_target_pointer+2

	lda #MULTIRATE_GUARD
	sta stash_size
	lda #0
	sta stash_size+1

	+JSR_INDIRECT (stash_block_vec)

multirate_finish_skip
	inc multirate_index_temp
	lda multirate_index_temp
	cmp #128
	beq +
	jmp multirate_finish_next
+
rts

; constant lookup tables (read-only, stay in the code)

multirate_half_counts							!byte 128,64,32,16
multirate_alloc_adds							!byte 0,3,7,15,31	; (2<<level)-1, by level 1..4
multirate_round_adds							!byte 0,1,2,4,8		; 1<<(level-1), by level 1..4
}

; ###############
; LOADER HOOK (loader-common.s), at file_size_okay: the last two lines
;
;        jsr load_sample_data
;        jmp unroll_mod_sample_loops
;
; become
;
;        jsr load_sample_data
;        jsr unroll_mod_sample_loops
;        jmp multirate_generate_all
;
; (unroll_mod_sample_loops ends in an rts, so jsr is fine; .C comes back
; set if there wasn't enough REU for the multirate data.)
;
; ###############
; DATA LAYOUT (for checking dumps)
;
; Region for (level L, sample S) starts at multirate_sample_start_addresses_*
; [(L-1)*32+S], page aligned, never crossing a 512k boundary.  Contents = the
; final level-0 data from the sample start, passed L times through pairwise
; averaging, (a+b)>>1, per 256-byte page.  Looped samples: loop start/end =
; start + (offset >> L), start + offset' + ((loop length + half a step) >> L),
; and the end addr equals the loop end addr.  After the end addr (loop end for
; looped samples) there are MULTIRATE_GUARD bytes: the first MULTIRATE_GUARD
; bytes of the decimated loop, or $80s for unlooped samples.
