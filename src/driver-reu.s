; RAM driver for standard REU

; this bit tells other code how fast the RAM driver actually is
; and is the average number of 1 MHz cycles consumed by the RAM driver mixer
; per final sample byte pair, plus some fudge (so on C128 this will be a bit
; over half the number of cycles needed).

!text "reu driver",0,0,0

reu_set_mixer_speed_figures
	!ifndef c128 {
		lda #120
	} else {
		lda #65
	}
	sta ram_driver_cpu_usage

	; since the REU mixer generates 8 sample pairs per loop, the constants below
	; will result in calculated values 8x higher than are "correct",
	; but we do it this way for the sake of precision later.

	lda #135
	sta tempo_fine_adjust_constant

	lda #56
	sta pitch_fine_adjust_constant

	; this shifts value is used to divide that "overage" back down (referring
	; to the number of divide-by-two lsr/ror pairs needed)

	lda #3
	sta mixer_count_shifts

rts

reu_fetch_row
	lda current_file_type
	cmp #1
	bne +

	lda #<(header15_seek_to_pt+128)
	ldx #>(header15_seek_to_pt+128)
	jmp ++

+	lda #<(header31_seek_to_pt+132)
	ldx #>(header31_seek_to_pt+132)

++	sta DMA_LO
	stx tempzp_g

	ldx current_song_pos
	lda pattern_table,x
	asl
	asl
	adc tempzp_g
	sta DMA_HI
	lda #0
	rol
	sta DMA_BANK

	lda #<seq_current_row_data
	sta DMA_ADL
	lda #>seq_current_row_data
	sta DMA_ADH

	lda #8
	sta DMA_DAL
	lda #0
	sta DMA_DAH

	lda #$b1	; execute, enable auto-load, fetching
	sta DMA_CMD ; run it twice to get 16 bytes so that the ISQ won't get more
	sta DMA_CMD ; than an 8-cycle delay
rts

reu_stash_block
	!ifdef c128 {
		lda VIC+$30
		and #$01
		pha
		jsr c128_set_1mhz_mode
	}

	lda #<load_buffer
	sta DMA_ADL
	lda #>load_buffer
	sta DMA_ADH

	lda stash_pointer
	sta DMA_LO
	lda stash_pointer+1
	sta DMA_HI
	lda stash_pointer+2
	sta DMA_BANK

	lda stash_size
	sta DMA_DAL
	lda stash_size+1
	sta DMA_DAH

	lda #$90
	sta DMA_CMD

	!ifdef c128 {
		pla
		sta VIC+$30
	}
rts

; This came from Codebase, author unknown
; https://codebase64.org/doku.php?id=base:reu_detect

REUCOMMAND_STASH    = $90   ; immediately, no reload
REUCOMMAND_FETCH    = $91   ; immediately, no reload

reu_get_size
	ldx #0  ; pre-init
	; first write signatures to banks in *descending* order (banks 255..0):
.wrlp
	dex
	stx reu_banknum
	lda #<reu_signature_start
	ldx #>reu_signature_start
	ldy #REUCOMMAND_STASH
	jsr set_registers_AXY
	ldx reu_banknum
	bne .wrlp	; all banks written?

; now check signatures in *ascending* order:
; banknum just became zero so no need to init it
.rdlp
	lda #<reu_sig_candidate_start
	ldx #>reu_sig_candidate_start
	ldy #REUCOMMAND_FETCH
	jsr set_registers_AXY
	; compare data
	ldx #8 ; signature length, minus 1
-			lda reu_sig_candidate_start, x
		cmp reu_signature_start, x
		bne .failed
		dex
		bpl -
		; bank has correct signature
	inc reu_banknum ; next bank (== number of banks already found)
	bne .rdlp

	ldx reu_banknum
	jmp +

.failed
	clc
	ldx reu_banknum

+	dex
	stx reu_highest_bank		; if 0, REU not detected at all.

rts

set_registers_AXY ; setup REU registers (used for both reading and writing in size test only)
	; A/X: c64 address
	; Y: REU command
	sta DMA_ADL
	stx DMA_ADH
	ldx #0
	stx DMA_LO
	stx DMA_HI
	lda reu_banknum
	sta DMA_BANK
	lda #9 ; signature length
	sta DMA_DAL
	stx DMA_DAH
	sty DMA_CMD
rts

; rough draft mixer code

reu_mixer_entry
	lda #1
	sta DMA_DAL
	lda #0
	sta DMA_DAH
	lda #>sample_data_lookahead_cache
	sta DMA_ADH
	ldx #REUCOMMAND_FETCH

reu_gen_sample_loop
	lda #<sample_data_lookahead_cache					; 2
	sta DMA_ADL											; 4

	!for track, 0, 3 {
		!zone reu_mixloop {

			clc											; 2
			lda sample_pointers_fract+track				; 3
			adc current_steprates_fract+track			; 3
			sta sample_pointers_fract+track				; 3
			bcc .reu_fix_dma_low_byte					; 3/2

			lda sample_pointers_lows+track				; 3
			adc current_steprates_lows+track			; 3
			sta sample_pointers_lows+track				; 3
			sta DMA_LO									; 4
			bcc .reu_fix_dma_high_byte					; 3/2

			inc sample_pointers_mids+track				; 5
			lda sample_pointers_mids+track				; 3
			sta DMA_HI									; 4
			bne .reu_check_end							; 3/2

			inc sample_pointers_highs+track				; 5
			lda sample_pointers_highs+track				; 3
			sta DMA_BANK								; 4
			bne .reu_check_end							; 3

		.reu_fix_dma_low_byte
			lda sample_pointers_lows+track				; 3
			sta DMA_LO									; 4

		.reu_fix_dma_high_byte
			lda sample_pointers_mids+track				; 3
			sta DMA_HI									; 4

		.reu_check_end
			sec											; 2
			lda sample_pointers_lows+track				; 3
			cmp current_sample_end_addr_lows+track		; 3
			lda sample_pointers_mids+track				; 3
			cmp current_sample_end_addr_mids+track		; 3
			lda sample_pointers_highs					; 3
			cmp current_sample_end_addr_highs+track		; 3
			bcc .reu_fetch_sample_data					; 3/2

			lda track_current_loop_flags+track			; 3
			bne .reu_sample_has_loop					; 3/2
			sta current_steprates_fract+track			; 3
			sta current_steprates_lows+track			; 3
			sta track_lookahead_indexes+track*8			; 4
			sta track_lookahead_indexes+track*8+1		; 4
			sta track_lookahead_indexes+track*8+2		; 4
			sta track_lookahead_indexes+track*8+3		; 4
			sta track_lookahead_indexes+track*8+4		; 4
			sta track_lookahead_indexes+track*8+5		; 4
			sta track_lookahead_indexes+track*8+6		; 4
			sta track_lookahead_indexes+track*8+7		; 4
			beq .reu_fetch_sample_data					; 3

		.reu_sample_has_loop
			lda #0										; 2
			sta sample_pointers_fract+track				; 3
			ldy current_sample_numbers+track			; 3
			lda sample_loop_start_addresses_lows,y		; 5
			sta sample_pointers_lows+track				; 4
			sta DMA_LO									; 4
			lda sample_loop_start_addresses_mids,y		; 5
			sta sample_pointers_mids+track				; 4
			sta DMA_HI									; 4
			lda sample_loop_start_addresses_highs,y		; 5
			sta sample_pointers_highs+track				; 4
			sta DMA_BANK								; 4
			lda sample_loop_end_addresses_lows,y		; 5
			sta current_sample_end_addr_lows+track		; 3
			lda sample_loop_end_addresses_mids,y		; 5
			sta current_sample_end_addr_mids+track		; 3
			lda sample_loop_end_addresses_highs,y		; 5
			sta current_sample_end_addr_highs+track		; 3

		.reu_fetch_sample_data
			stx DMA_CMD									; 4
		}
	}

; loop start: 2+4 = 6 cycles
; add 2+3+3+3+3 +3+4 +3+4 +3+4 = 35 cycles if only fraction byte is updated.

; subtract 3+4 and add +3+3+3+4+3, total 41 cycles to update 2 bytes

; subtract 3+4 and add +5+3+4+3, total 52 cycles to update 3 bytes

; subtract 3+4 and add +5+3+4+3, total 60 cycles to update all 4 bytes

; then add 2+3+3+3+3+3+3+3 = 23 more cycles do to the end-of-sample check

; add 4 + 8 to actually fetch the data

; times 4 tracks:

; minimum (35 + 23 + 12) * 4 = 280 cycles if all four tracks are playing at very
;     low pitches

; most common will probably be (41 + 23 + 12) * 4 = 304 cycles if all four tracks
;     have a pitch somewhere in the middle of the range

; could be up to (60 + 32 + 12) * 4 = 416 cycles if literally every pointer
;     byte gets updated on every track -- rare, only once per 65k samples
;     so like, every 5-10 seconds or so probably

; next step is to downmix these four bytes with additional bytes from the
; lookahead cache. indexes into this cache will be generated by the sequencer
; any time a new note pitch/period is set, so that the mixer code doesn't have
; to do a bunch of maths on the sample pointers.

		ldx audio_in_buf_index						; 3

	!for .byte_index, 0, 7 {
	-	cpx audio_out_buf_index						; 3        /  wait for a free
		beq -										; 3/2      /  slot in the buffer

		clc											; 2
		ldy sample_data_lookahead_cache+.byte_index ; 4        / track 1
		lda (volume_table_vectors),y				; 5
		ldy sample_data_lookahead_cache+3*8 + .byte_index ; 4  / track 4
		adc (volume_table_vectors+3*2),y			; 5   
		lsr											; 2
		sta audio_buffer_left,x						; 5

		clc											; 2
		ldy sample_data_lookahead_cache+1*8 + .byte_index ; 4  / track 2
		lda (volume_table_vectors+1*2),y			; 5
		ldy sample_data_lookahead_cache+2*8 + .byte_index ; 4  / track 3
		adc (volume_table_vectors+2*2),y			; 5
		lsr											; 2
		sta audio_buffer_right,x					; 5

		inx											; 2
	}

	stx audio_in_buf_index							; 3

; so downmixing to the buffer costs 62 cycles per pair of output samples
; plus 3+3

	sec												; 2
	lda mixer_output_countdown						; 3
	sbc #1											; 2
	sta mixer_output_countdown						; 3
	bcc +											; 3/2
	jmp reu_gen_sample_loop							; 6

+	lda mixer_output_countdown+1					; 5
	sbc #0											; 2
	sta mixer_output_countdown+1					; 3
	beq +											; 3/2
	jmp reu_gen_sample_loop							; 6
+ rts												; 6

; add 2+3+2+3+2+6 = 18 cycles to decrement the mixer countdown and loop back

; add 1+5+2+3+2 = +11 cycles every 256th pass

; =====================

; timings to generate 8 output bytes across all four tracks (rounded up):

; Best case:
;
; (35 + 23 + 12) * 4 + 62 * 8 + 6 + 18 = 800 cycles
; 800 / 8 = 100 cycles per output sample pair

; Typical case should be roughly:
;
; (41 + 23 + 12) * 4 + 62 * 8 + 6 + 18 = 824 cycles
; 824 / 8 = 103 cycles per output sample pair

; Worst case:
;
; (60 + 32 + 12) * 4 + 62 * 8 + 6 + 18 + 11 + 21 + 8 = 976
; 976 / 8 = 122 cycles per output sample pair

; add like 30 cycles or so per sample pair for the ISR runtime
; stock C64 should be able to mix and output at about 5 kHz
