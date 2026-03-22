; Mod file loader using standard CHRIN calls

!zone loader_standard {

loader_standard_get_mod_header ; and also the first pattern if it's a 15-sample mod
	lda #0
	sta utility_counter
	sta utility_counter+1
	sta utility_counter+2

	lda #<load_buffer
	sta load_pointer
	lda #>load_buffer
	sta load_pointer+1

	ldy #0
	sty header_loaded

-	jsr CHRIN
	sta (load_pointer),y
	inc load_pointer
	bne +
	inc load_pointer+1

+	inc utility_counter
	bne +
	inc utility_counter+1

+	lda utility_counter
	cmp #<header31_seek_to_pat_data
	lda utility_counter+1
	sbc #>header31_seek_to_pat_data
	bcc -

	lda #<header31_seek_to_pat_data
	sta loaded_bytes_count
	lda #>header31_seek_to_pat_data
	sta loaded_bytes_count+1
	lda #0
	sta loaded_bytes_count+2

	jsr decode_mod_header
	bcc +
	rts

+	lda #0
	sta pattern_conv_pat_counter
	lda current_file_type
	cmp #2
	sec
	beq .loaded_31			; if it's a 31-sample mod, then we're right at the
							; first byte of the first pattern.  otherwise, some
							; of the first pattern is loaded, so get the rest.
	lda #0
	sta utility_counter
	sta utility_counter+1

	ldy #0
-	jsr CHRIN
	sta (load_pointer),y
	inc load_pointer
	bne +
	inc load_pointer+1

+	inc utility_counter
	bne +
	inc utility_counter+1

+	lda utility_counter		; we got all but 540 bytes initially.
	cmp #<540
	lda utility_counter+1
	sbc #>540
	bcc -

	clc
	lda loaded_bytes_count
	adc #<540
	sta loaded_bytes_count
	lda loaded_bytes_count+1
	adc #>540
	sta loaded_bytes_count+1
	bcc +
	inc loaded_bytes_count+2

	; now that the header is no longer needed and the first pattern has been
	; loaded, move it down to the bottom of the load buffer

+	lda #<load_buffer
	sta load_pointer
	lda #>load_buffer
	sta load_pointer+1

	lda #<(load_buffer+header15_seek_to_pat_data)
	sta utility_pointer_b
	lda #>(load_buffer+header15_seek_to_pat_data)
	sta utility_pointer_b+1

	ldy #0
-	lda (utility_pointer_b),y
	sta (load_pointer),y
	iny
	bne -
	inc utility_pointer_b+1
	inc load_pointer+1
	lda load_pointer+1
	cmp #>(load_buffer+$0400)
	bne -
	clc
.loaded_31
	lda #$80
	sta header_loaded
rts

loader_standard_load_pattern_data
	lda num_samples_to_load ; if the file has 15 samples, the header loader
	cmp #15					; will have fetched the first pattern already.
	beq .is_15

.load_next_patt
	jsr loader_standard_get_1kb
	jsr loader_update_progress

.is_15
	jsr reformat_pattern_data

	+JSR_INDIRECT (stash_block_vec)

	clc
	lda expansion_memory_target_pointer+1
	adc #4
	sta expansion_memory_target_pointer+1
	bcc +
	inc expansion_memory_target_pointer+2

+	inc pattern_conv_pat_counter
	lda pattern_conv_pat_counter
	cmp number_of_patterns
	bcc .load_next_patt
rts

loader_standard_load_sample_data
	lda #1
	sta stash_size+1

	lda #0
	sta sample_number_count

.load_next_sample
	inc sample_number_count
	ldy sample_number_count

	lda sample_lengths_lows,y			; if the length is 0, it's an empty
	ora sample_lengths_mids,y			; sample slot (duh 🙂)
	ora sample_lengths_highs,y
	bne ++
	jsr CHRIN				; skip two bytes of the file if the
	jsr CHRIN				; sample is empty (mods always have this)

	clc
	lda loaded_bytes_count
	adc #2
	sta loaded_bytes_count
	bcc +
	inc loaded_bytes_count+1
	bne +
	inc loaded_bytes_count+2

+	jmp .load_next_sample

++	lda sample_start_addresses_mids,y
	sta expansion_memory_target_pointer+1
	lda sample_start_addresses_highs,y
	sta expansion_memory_target_pointer+2

	lda sample_lengths_lows,y			; okay, so it isn't empty 🙂
	sta utility_counter					; use the specified length
	lda sample_lengths_mids,y
	sta utility_counter+1
	lda sample_lengths_highs,y
	sta utility_counter+2

	ora sample_lengths_mids,y			; if the top two bytes of len are 0,
	beq .load_rest_of_sample			; the sample is less than one page, so
										; just use the load-remainder routine

.load_next_sample_block
	jsr loader_standard_get_block

	ldy #0
-	lda load_buffer,y
	clc
	adc #$80							; translate signed -> unsigned
	sta load_buffer,y
	iny
	bne -

	+JSR_INDIRECT (stash_block_vec)

	inc expansion_memory_target_pointer+1
	bne +
	inc expansion_memory_target_pointer+2

+	lda expansion_memory_target_pointer+1
	and #$03
	bne +
	jsr loader_update_progress

+	lda STATUS
	beq +
	jmp .ldr_done

+	sec
	lda utility_counter+1
	sbc #1
	sta utility_counter+1
	bcs +
	dec utility_counter+2

+	ora utility_counter+2				; are there less than 256 bytes left?
	bne .load_next_sample_block			; if not, keep loading...

	lda utility_counter					; is the remainder just 0?  (e.g. sample
	beq .chk_more_samples				; is a multiple of 256 bytes)

.load_rest_of_sample					; if neither, load the exact number of remaining bytes
	ldy #0
-	jsr CHRIN
	clc
	adc #$80							; translate signed -> unsigned
	sta load_buffer,y
	iny
	cpy utility_counter
	bne -

	clc
	tya
	adc loaded_bytes_count
	sta loaded_bytes_count
	bcc +
	inc loaded_bytes_count+1
	bne +
	inc loaded_bytes_count+2

+	lda #$80							; clear rest of load buf page
-	sta load_buffer,y
	iny
	bne -

	+JSR_INDIRECT (stash_block_vec)		; store the result

	inc expansion_memory_target_pointer+1
	bne +
	inc expansion_memory_target_pointer+2

+	lda #$80							; create an entirely blank page
	ldy #0
-	sta load_buffer,y
	iny
	bne -

	+JSR_INDIRECT (stash_block_vec)		; and tack it onto the end of the sample

	lda STATUS
	bne .ldr_done

.chk_more_samples
	ldy num_samples_to_load
	dey
	cpy sample_number_count
	bcc .ldr_done
	jmp .load_next_sample

.ldr_done
	jsr close_file
	lda file_size_in_kb
	sta current_file_size_in_kb
	lda file_size_in_kb+1
	sta current_file_size_in_kb+1

	ldy #0
-	lda string_buffer,y
	sta current_file_name,y
	beq .ldr_exit
	iny
	cpy #16
	bne -
  .ldr_exit
rts

loader_standard_get_block
	lda #<load_buffer
	sta load_pointer
	lda #>load_buffer
	sta load_pointer+1

loader_standard_get_block_keep_ptr
	ldy #0

-	jsr CHRIN
	sta (load_pointer),y
	iny
	bne -

	inc loaded_bytes_count+1
	bne +
	inc loaded_bytes_count+2
  +
rts

loader_standard_get_1kb
	jsr loader_standard_get_block
	inc load_pointer+1
	jsr loader_standard_get_block_keep_ptr
	inc load_pointer+1
	jsr loader_standard_get_block_keep_ptr
	inc load_pointer+1
	jsr loader_standard_get_block_keep_ptr
rts

}
