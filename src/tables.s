; generate volume scaler tables
; these tables scale the amplitude of the sample data according to the volume
; the mod asks for, converts the signed samples to unsigned, and downscales
; the resolution of the final numbers according to the needs of the audio
; driver.

; enter with .A = desired output resolution

generate_volume_tables
	lda #<volume_table_lower
	sta fill_copy_target
	lda #>volume_table_lower
	sta fill_copy_target+1

	lda #0
	sta bval_cnt			; byte value counter
	sta vol_cnt				; volume counter

-	lda bval_cnt

	ldx vol_cnt			; for the highest volume, don't bother applying any
	cpx #63				; scaling.
	beq noscale

	jsr multiply_8x8 	; returns 14 bit value in 'product', MSB is in .A

	asl product			; multiply by 4 and use the result in .A. This is
	rol					; identical to dividing by 64, but it's faster.
	asl product
	rol
	sta product+1

; re-center the amplitude range to keep the middle sample value at $7f/80.

	sec
	lda #64
	sbc vol_cnt
	asl
	adc product+1

noscale

; divide the final value down to the resolution the audio driver needs

; the output of the table will be 3 or 7 bits in order to avoid excessive
; ROR's and CLC's in the mixer and ISRs, at a cost of one or two steps of
; the output range (e.g. 0-14 instead of 0-15, 0-254 vs. 0-255, etc).

; anything other than 3, 6, or 7 selects 2-bit mode

	ldx volume_tables_resolution
	cpx #3
	beq use3bit
	cpx #6
	beq use6bit
	cpx #7
	beq use7bit

	lsr

use3bit
	lsr
	lsr
	lsr

use6bit
	lsr

use7bit
	lsr
	ldy bval_cnt
	sta (fill_copy_target),y
	inc bval_cnt
	bne -

	inc fill_copy_target+1
	inc vol_cnt
	lda vol_cnt
	cmp #38		; the first 38 pages go in the lower part of the table
	bne +

	lda #>volume_table_upper	; ...while the rest goes under the KERNAL.
	sta fill_copy_target+1
	bne -

+	cmp #64
	bne -
rts

generate_tempo_table
	lda #0
	ldy #31
-	sta tempo_table_fracts,y
	sta tempo_table_lows,y
	dey
	bpl -

	ldx #32 ; entries 0-31 are unused.

	lda isr_trigger_interval
	sta multiplicand_a
	lda isr_trigger_interval+1
	sta multiplicand_a+1

-	stx temp_abs_x
	stx multiplicand_b
	lda #0
	sta multiplicand_b+1

	sec
	jsr multiply_16x16

	lda #0
	sta dividend
	lda #<tempo_fine_adjust_constant
	sta dividend+1
	lda #>tempo_fine_adjust_constant
	sta dividend+2
	lda #^tempo_fine_adjust_constant ; "^" means "bank" e.g. bits 16-23
	sta dividend+3

	lda product
	sta divisor
	lda product+1
	sta divisor+1
	lda product+2
	sta divisor+2

	jsr divide_32by24

	ldx temp_abs_x
	lda quotient
	sta tempo_table_fracts,x
	lda quotient+1
	sta tempo_table_lows,x
	inx
	bne -
rts

generate_period_table
	sei
	jsr disable_roms

	lda #pitch_fine_adjust_constant
	sta multiplicand_a
	lda #0
	sta multiplicand_a+1

	lda isr_trigger_interval
	sta multiplicand_b
	lda isr_trigger_interval+1
	sta multiplicand_b+1

	sec
	jsr multiply_16x16		; we'll run this once and keep reusing the product

	ldy #57 * 2 + 1
	lda #0
-	dey
	sta steprate_lookup_table,y
	bne -

	lda #57					; will step through the entire period range.  the
	sta utility_counter		; highest note in octave 4 has a period of 57, so
	lda #0					; just ignore the rest.  technically the lowest
	sta utility_counter+1	; note should be 1712 but it's easier to fill the page.

	clc
	lda #<steprate_lookup_table
	adc #57 * 2
	sta fill_copy_target

	lda #>steprate_lookup_table
	adc #0
	sta fill_copy_target+1

-	lda #0
	sta dividend
	sta divisor+2

	lda product
	sta dividend+1
	lda product+1
	sta dividend+2
	lda product+2
	sta dividend+3

	lda utility_counter
	sta divisor
	lda utility_counter+1
	sta divisor+1

	jsr divide_32by24

	ldy #0
	lda quotient
	sta (fill_copy_target),y
	iny
	lda quotient+1
	sta (fill_copy_target),y

	clc							; for every step of the period value in
	lda fill_copy_target		; utility_counter, store two bytes in a row at
	adc #2						; (fill_copy_target), LSB first.
	sta fill_copy_target
	bcc +
	inc fill_copy_target+1

+	inc utility_counter
	bne +
	inc utility_counter+1

+	lda utility_counter+1
	cmp #7
	bne -

	jsr enable_kernal_only
	cli
rts

generate_note_number_lookup_table
	sei
	jsr disable_roms

	ldy #0
	lda #0
-	sta viz_note_number_lookup_table,y
	sta viz_note_number_lookup_table+$0600,y
	dey
	bne -

	lda #57
	sta utility_counter
	lda #0
	sta utility_counter+1

	clc
	lda #<viz_note_number_lookup_table
	adc #57
	sta fill_copy_target
	lda #>viz_note_number_lookup_table
	adc #0
	sta fill_copy_target+1

-	lda #<binsearch_note_period_table
	sta binsearch_low
	lda #>binsearch_note_period_table
	sta binsearch_low+1

	lda #<(binsearch_note_period_table + 118)
	sta binsearch_high
	lda #>(binsearch_note_period_table + 118)
	sta binsearch_high+1

	lda utility_counter
	sta binsearch_value
	lda utility_counter+1
	sta binsearch_value+1

	jsr binary_search

	; returns the address in memory of the exact match in binsearch_mid if
	;.C = 1, or the address of the closest match in binsearch_low if .C = 0 

	bcc +

	lda binsearch_mid			; the table uses 16-bit entries, so this will
	sbc #<binsearch_note_period_table ; return a value 0 to 118 in steps of 2.
	jmp ++

+	sec
	lda binsearch_low
	sbc #<binsearch_note_period_table
 
++	lsr							; divide by 2 and add 1 and now it's a note
	clc							; number 1-60
	adc #1

	ldy #0
	sta (fill_copy_target),y

	inc fill_copy_target
	bne +
	inc fill_copy_target+1

+	inc utility_counter
	bne +
	inc utility_counter+1

+	lda utility_counter
	cmp #<1712
	lda utility_counter+1
	sbc #>1712
	bcc -

	jsr enable_kernal_only
	cli
rts

regen_all_tables
	lda isr_trigger_interval
	cmp last_isr_trigger_interval
	bne +
	lda isr_trigger_interval+1
	cmp last_isr_trigger_interval+1
	bne +

	lda volume_tables_resolution
	cmp last_volume_tables_resolution 
	bne +
	rts

+	!ifndef scpu {
		bit allow_regen_msg
		bpl no_msgs1

		!ifndef c128 {
			bit enable_screen_on_playback	; because if it's enabled, the display will
			bmi +							; have switched to the alt charset by this point.

			jsr gray_out
			jsr draw_short_popup
			lda #0
			ldx #<main_player_regen_tables_msg
			ldy #>main_player_regen_tables_msg
			sec
			jsr print_msg
			jmp ++

		+	lda #0
			ldx #<main_player_regen_tables_msg
			ldy #>main_player_regen_tables_msg
			sec
			jsr print_msg
		 ++
		} else {
			lda #0
			ldx #<main_player_regen_tables_msg
			ldy #>main_player_regen_tables_msg
			sec
			jsr print_msg
		}
	}

no_msgs1
	lda volume_tables_resolution
	cmp last_volume_tables_resolution
	beq +
	sta last_volume_tables_resolution

	jsr generate_volume_tables

+	lda isr_trigger_interval
	cmp last_isr_trigger_interval
	bne +
	lda isr_trigger_interval+1
	cmp last_isr_trigger_interval+1
	beq ++

+	lda isr_trigger_interval
	sta last_isr_trigger_interval
	lda isr_trigger_interval+1
	sta last_isr_trigger_interval+1

	jsr generate_tempo_table
	jsr generate_period_table

++	!ifndef scpu {
		bit allow_regen_msg
		bpl no_msgs2

		!ifndef c128 {
			bit enable_screen_on_playback
			bpl no_msgs2

			lda #0
			ldx #<main_player_regen_erase_tables_msg
			ldy #>main_player_regen_erase_tables_msg
			sec
			jsr print_msg_rle
		} else {
			lda #0
			ldx #<main_player_regen_erase_tables_msg
			ldy #>main_player_regen_erase_tables_msg
			sec
			jsr print_msg
		}
	}

  no_msgs2
rts
