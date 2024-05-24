; RAM driver for standard REU

reu_fetch_byte
	; code here
	rts

reu_stash_byte
	; code here
	rts

reu_fetch_row
	; code here
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
	lda #>track_data_targets
	sta DMA_ADH
	ldx #REUCOMMAND_FETCH
	lda current_file_tracks
	cmp #4
	bne +
	lda #<mix_4_tracks
	sta .pnt+1
	lda #>mix_4_tracks
	sta .pnt+2
	jmp reu_gen_sample_loop

+	cmp #6
	bne +
	lda #<mix_6_tracks
	sta .pnt+1
	lda #>mix_6_tracks
	sta .pnt+2
	jmp reu_gen_sample_loop

+	lda #$ea
	sta .pnt
	sta .pnt+1
	sta .pnt+2

reu_gen_sample_loop
	lda #<track_data_targets							; 2
	sta DMA_ADL											; 4

.pnt jmp $0000											; 6

	!for track, 7, 0 {
		!zone reu_mixloop {

			!if track = 5 {
				mix_6_tracks
			}

			!if track = 3 {
				mix_4_tracks
			}

			clc											; 2
			lda sample_pointers_fract+7-track			; 3
			adc current_steprates_fract+7-track			; 3
			sta sample_pointers_fract+7-track			; 3

			lda sample_pointers_lows+7-track			; 3
			adc current_steprates_lows+7-track			; 3
			sta sample_pointers_lows+7-track			; 3
			sta DMA_LO									; 4
			bcc .reu_fix_top_two_bytes					; 3/2

			lda sample_pointers_mids+7-track			; 3
			adc #0										; 2
			sta sample_pointers_mids+7-track			; 3
			sta DMA_HI									; 4
			bcc .reu_fix_just_bank_addr					; 3/2

			lda sample_pointers_highs+7-track			; 3
			adc #0										; 2
			sta sample_pointers_highs+7-track			; 3
			sta DMA_BANK								; 4
			beq .reu_check_end							; 3/2

		.reu_fix_top_two_bytes
			lda sample_pointers_mids+7-track			; 3
			sta DMA_HI									; 4

		.reu_fix_just_bank_addr
			lda sample_pointers_highs+7-track			; 3
			sta DMA_BANK								; 4

		.reu_check_end
			sec
			lda sample_pointers_lows+7-track			; 3
			cmp current_sample_end_addr_lows+7-track	; 3
			lda sample_pointers_mids+7-track			; 3
			cmp current_sample_end_addr_mids+7-track	; 3
			lda sample_pointers_highs					; 3
			cmp current_sample_end_addr_highs+7-track	; 3
			bcc .reu_fetch_sample_data					; 3/2

			lda track_loop_flags+7-track				; 3
			bne .reu_sample_has_loop					; 3/2
			sta current_steprates_fract+7-track			; 3
			sta current_steprates_lows+7-track			; 3
			beq .reu_next_track							; 3/2

		.reu_sample_has_loop
			lda #0										; 2
			sta sample_pointers_fract+7-track			; 3
			ldy current_sample_number+7-track			; 3
			lda sample_loop_start_addresses_lows,y		; 5
			sta sample_pointers_lows+7-track			; 4
			sta DMA_LO									; 4
			lda sample_loop_start_addresses_mids,y		; 5
			sta sample_pointers_mids+7-track			; 4
			sta DMA_HI									; 4
			lda sample_loop_start_addresses_highs,y		; 5
			sta sample_pointers_highs+7-track			; 4
			sta DMA_BANK								; 4
			lda sample_loop_end_addresses_lows,y		; 5
			sta current_sample_end_addr_lows+7-track	; 3
			lda sample_loop_end_addresses_mids,y		; 5
			sta current_sample_end_addr_mids+7-track	; 3
			lda sample_loop_end_addresses_highs,y		; 5
			sta current_sample_end_addr_highs+7-track	; 3

		.reu_fetch_sample_data
			stx DMA_CMD									; 4
			ldy track_data_targets+7-track				; 3
			lda (volume_table_vectors+7-track*2),y		; 5
			sta track_byte_to_mix+7-track				; 3

		.reu_next_track
	}
}

; 2+4+6 = 12 cycles to start the loop

; main pointer updates: 2+3+3+3 + 3+3+3+4+3 + 3+4 + 3+4 = 41 cycles per byte, per track
; add 3+2+3+4+3 and subtract 3+4 = 8s cycles every 256 bytes, per track
; add 3+2+3+4 and subtract 3+4 = 5 cycles evert 64k, per track

; loop/end checks add 3+3+3+3+3+3+3 = 21 cycles per track when end not reached

; fetch adds 4+3+5+3 = 15 cycles

; grand total: 320 cycles for four tracks, plus the mixer+buffer code below.

reu_mix_samples
	; fill the rest in later.  this part just needs to downmix the various
	; tracks' sample bytes, stuff them into the audio buffer, decrement the
	; number-of-samples countdown, and then either loop or exit back to the
	; sequencer.

