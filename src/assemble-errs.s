; ============================
; assemble-time error handling

!if bzp_low_end > $0024 {
	!error "Backed-up-zero-page variables, lower part exceeds $0024 by ", bzp_low_end - $0024, " bytes! (",bzp_low_end - 1,")"
}

!if bzp_lowmid_end > $0050 {
	!error "Backed-up-zero-page variables, lower middle part exceeds $0050 by ", bzp_lowmid_end - $0050, " bytes! (",bzp_lowmid_end - 1,")"
}

!if bzp_upmid_end > $0059 {
		!error "Backed-up-zero-page variables, upper middle part exceeds $0059 by ", bzp_upmid_end - $0059, " bytes! (",bzp_upmid_end - 1,")"
}

!if bzp_top_end > $00f7 {
	!error "Backed-up-zero-page variables, top part exceeds $00f7 by ", bzp_top_end - $00f7, " bytes! (",bzp_top_end - 1,")"
}

!ifndef c128 {
	!if lma_cur_end > $0400 {
		!error "Low memory area exceeds overlaps `multablo` by ", lma_cur_end - $0400, " bytes! (",lma_cur_end - 1,")"
	}
} else {
	!if lma_cur_end > $02a2 {
		!error "Low memory area overlaps C128 indirect routines by ", lma_cur_end - $02a2, " bytes! (",lma_cur_end - 1,")"
	}
}

!if mv_end > $1000 {
	!error "Main variables zone exceeds $1000 by ", mv_end - $1000, " bytes! (",mv_end - 1,")"
}

!if LOAD_BUFFER_PAGES * 256 < header31_seek_to_pat_data {
	!error "Load buffer is too small for a 31-sample MOD header by ", header31_seek_to_pat_data - LOAD_BUFFER_PAGES * 256, " bytes!"
}

!if LOAD_BUFFER_PAGES < 4 {
	!error "Load buffer must be at least 4 pages (one pattern, and the four caches in striding mode)!"
}

!ifndef turbo_available {
	.mr_buffer_needed = MULTIRATE_VARS_OFFSET + 8 * MULTIRATE_TABLE_LEN + MULTIRATE_MISC_SIZE

	; the audio drivers' transient images are fetched over the start of the same buffer
	; whenever playback starts or stops, so the tables can't be in the way of them.

	!if MULTIRATE_VARS_OFFSET < AUDIO_TRANSIENT_MAX {
		!error "The multirate tables overlap the audio driver's transient image by ", AUDIO_TRANSIENT_MAX - MULTIRATE_VARS_OFFSET, " bytes!"
	}

	!if MULTIRATE_WINDOW * 4 > 256 {
		!error "The four tracks' caches don't fit in one page at this MULTIRATE_WINDOW!"
	}

	!if .mr_buffer_needed > LOAD_BUFFER_PAGES * 256 {
		!error "Multirate tables overflow the sample data buffer by ", .mr_buffer_needed - LOAD_BUFFER_PAGES * 256, " bytes!"
	}

	; unrolled loops are at least LOAD_BUFFER_PAGES pages long, and the guard copy at the
	; end of a decimated loop is a single copy of the head, so it has to fit in one loop
	!if (LOAD_BUFFER_PAGES * 256) >> MULTIRATE_LEVELS < MULTIRATE_GUARD {
		!error "Decimated loops can be shorter than MULTIRATE_GUARD!"
	}
}

!if load_buffer != program_start {
	!error "The load buffer isn't at the start of the program!"
}

!if loader_slot != program_start + LOAD_BUFFER_PAGES * 256 {
	!error "The loader slot doesn't follow the load buffer!"
}

!if start != program_entry {
	!error "The program's entry point isn't program_entry, so the booters would jump to the wrong place!  (", start, " vs. ", program_entry, ")"
}

!ifdef c128 {
	!if load_buffer + LOAD_BUFFER_PAGES * 256 > $c000 {
		!error "The load buffer extends above $c000, where the ROM hides it, by ", load_buffer + LOAD_BUFFER_PAGES * 256 - $c000, " bytes! (", load_buffer + LOAD_BUFFER_PAGES * 256 - 1, ")"
	}

	!if ascii_to_petscii_table + 256 > $c000 {
		!error "The ASCII table extends above $c000, where the ROM hides it, by ", ascii_to_petscii_table + 256 - $c000, " bytes! (", ascii_to_petscii_table + 255, ")"
	}
}

!if end_of_mid_mem_tables > main_mem_free_end {
	!error "Mid-memory tables overlap high memory area by ", end_of_mid_mem_tables - main_mem_free_end, " bytes! (",end_of_mid_mem_tables - 1,")"
}

!if under_kernal_code_end > audio_resident_page {
	!error "Under-KERNAL code overlaps the audio driver page (", audio_resident_page, ") by ", under_kernal_code_end - audio_resident_page, " bytes! (",under_kernal_code_end - 1,")"
}

; the tables under the KERNAL and the code that follows them are placed by hand in
; constants-io-and-kernal.h, one right after another.  make sure that they stay clear
; of each other if any of them is resized.

!if <viz_note_number_lookup_table != 0 {
	!error "The note number lookup table isn't page-aligned, which the row data visualizer needs it to be!"
}

!if viz_note_number_lookup_table + 7 * 256 > steprate_lookup_table {
	!error "The note number lookup table overlaps the steprate table by ", viz_note_number_lookup_table + 7 * 256 - steprate_lookup_table, " bytes!"
}

!if <steprate_lookup_table != 0 {
	!error "The steprate table isn't page-aligned, which steprate_lookup needs it to be!"
}

!if steprate_lookup_table + 14 * 256 > and_f0_table {
	!error "The steprate table overlaps the AND $F0 table by ", steprate_lookup_table + 14 * 256 - and_f0_table, " bytes!"
}

!if and_f0_table + 256 > under_kernal_code {
	!error "The AND $F0 table overlaps the under-KERNAL code by ", and_f0_table + 256 - under_kernal_code, " bytes!"
}

!if mixer_standard_end > audio_resident_page {
	!error "Standard mixer overlaps audio_resident_page by ", mixer_standard_end - audio_resident_page, " bytes!"
}

!if nnt_end > $fffa {
	!error "note_names_table overlaps CPU hardware vectors at $fffa by ", nnt_end - $fffa, " bytes! (",nnt_end - 1,")"
}

; each audio driver is two images:  the resident one is assembled to run from the
; reserved page under the KERNAL, and the transient one from the start of the load
; buffer.  the resident image (with its two entry jumps) has to fit in the page, and
; the transient image (with its three entry jumps) in the bytes that are fetched.  and the images have to fit in the pages
; that the booter reserves for them in expansion memory, with room to spare for the
; last fetch to run past the end of the last image.

!if sid_4bit_resident_end - audio_resident_page > AUDIO_RESIDENT_MAX {
	!error "Resident image of the SID 4-bit audio driver exceeds AUDIO_RESIDENT_MAX by ", sid_4bit_resident_end - audio_resident_page - AUDIO_RESIDENT_MAX, " bytes!"
}

!if sid_4bit_transient_end - audio_transient_base > AUDIO_TRANSIENT_MAX {
	!error "Transient image of the SID 4-bit audio driver exceeds ", AUDIO_TRANSIENT_MAX, " bytes by ", sid_4bit_transient_end - audio_transient_base - AUDIO_TRANSIENT_MAX, " bytes!"
}

!if sid_4bit_dithered_resident_end - audio_resident_page > AUDIO_RESIDENT_MAX {
	!error "Resident image of the SID 4-bit dithered audio driver exceeds AUDIO_RESIDENT_MAX by ", sid_4bit_dithered_resident_end - audio_resident_page - AUDIO_RESIDENT_MAX, " bytes!"
}

!if sid_4bit_dithered_transient_end - audio_transient_base > AUDIO_TRANSIENT_MAX {
	!error "Transient image of the SID 4-bit dithered audio driver exceeds ", AUDIO_TRANSIENT_MAX, " bytes by ", sid_4bit_dithered_transient_end - audio_transient_base - AUDIO_TRANSIENT_MAX, " bytes!"
}

!if sid_mahoney_resident_end - audio_resident_page > AUDIO_RESIDENT_MAX {
	!error "Resident image of the SID Mahoney audio driver exceeds AUDIO_RESIDENT_MAX by ", sid_mahoney_resident_end - audio_resident_page - AUDIO_RESIDENT_MAX, " bytes!"
}

!if sid_mahoney_transient_end - audio_transient_base > AUDIO_TRANSIENT_MAX {
	!error "Transient image of the SID Mahoney audio driver exceeds ", AUDIO_TRANSIENT_MAX, " bytes by ", sid_mahoney_transient_end - audio_transient_base - AUDIO_TRANSIENT_MAX, " bytes!"
}

!if dac_resident_end - audio_resident_page > AUDIO_RESIDENT_MAX {
	!error "Resident image of the DAC audio driver exceeds AUDIO_RESIDENT_MAX by ", dac_resident_end - audio_resident_page - AUDIO_RESIDENT_MAX, " bytes!"
}

!if dac_transient_end - audio_transient_base > AUDIO_TRANSIENT_MAX {
	!error "Transient image of the DAC audio driver exceeds ", AUDIO_TRANSIENT_MAX, " bytes by ", dac_transient_end - audio_transient_base - AUDIO_TRANSIENT_MAX, " bytes!"
}

!if digimax_mk1_resident_end - audio_resident_page > AUDIO_RESIDENT_MAX {
	!error "Resident image of the DigiMAX Mk1 audio driver exceeds AUDIO_RESIDENT_MAX by ", digimax_mk1_resident_end - audio_resident_page - AUDIO_RESIDENT_MAX, " bytes!"
}

!if digimax_mk1_transient_end - audio_transient_base > AUDIO_TRANSIENT_MAX {
	!error "Transient image of the DigiMAX Mk1 audio driver exceeds ", AUDIO_TRANSIENT_MAX, " bytes by ", digimax_mk1_transient_end - audio_transient_base - AUDIO_TRANSIENT_MAX, " bytes!"
}

!if digimax_mk2_resident_end - audio_resident_page > AUDIO_RESIDENT_MAX {
	!error "Resident image of the DigiMAX Mk2 audio driver exceeds AUDIO_RESIDENT_MAX by ", digimax_mk2_resident_end - audio_resident_page - AUDIO_RESIDENT_MAX, " bytes!"
}

!if digimax_mk2_transient_end - audio_transient_base > AUDIO_TRANSIENT_MAX {
	!error "Transient image of the DigiMAX Mk2 audio driver exceeds ", AUDIO_TRANSIENT_MAX, " bytes by ", digimax_mk2_transient_end - audio_transient_base - AUDIO_TRANSIENT_MAX, " bytes!"
}

!if AUDIO_TRANSIENT_MAX > LOAD_BUFFER_PAGES * 256 {
	!error "Load buffer is too small for an audio driver's transient image!"
}

; the loader images have to fit in the slot, and in the pages that the booter reserves
; for them in expansion memory, again with room to spare for the last fetch to run past
; the end of the last image.

!if loader_standard_end - loader_slot > LOADER_SLOT_SIZE {
	!error "The KERNAL loader image exceeds the loader slot by ", loader_standard_end - loader_slot - LOADER_SLOT_SIZE, " bytes!"
}

!ifdef uci_loader_available {
	!if loader_uci_end - loader_slot > LOADER_SLOT_SIZE {
		!error "The UCI loader image exceeds the loader slot by ", loader_uci_end - loader_slot - LOADER_SLOT_SIZE, " bytes!"
	}
}

!ifdef c128 {
	!if loader_burst_end - loader_slot > LOADER_SLOT_SIZE {
		!error "The burst loader image exceeds the loader slot by ", loader_burst_end - loader_slot - LOADER_SLOT_SIZE, " bytes!"
	}
}

!if loader_eload_end - loader_slot > LOADER_SLOT_SIZE {
	!error "The ELoad loader image exceeds the loader slot by ", loader_eload_end - loader_slot - LOADER_SLOT_SIZE, " bytes!"
}

!ifndef c128 {
	!if loader_bitops_end - loader_slot > LOADER_SLOT_SIZE {
		!error "The Bitops loader image exceeds the loader slot by ", loader_bitops_end - loader_slot - LOADER_SLOT_SIZE, " bytes!"
	}
}

!if loader_hdstream_end - loader_slot > LOADER_SLOT_SIZE {
	!error "The HD streamer loader image exceeds the loader slot by ", loader_hdstream_end - loader_slot - LOADER_SLOT_SIZE, " bytes!"
}
!if loader_hd_install_end - loader_hd_install > LOAD_BUFFER_PAGES * 256 {
	!error "The HD streamer's install part doesn't fit in the load buffer by ", loader_hd_install_end - loader_hd_install - LOAD_BUFFER_PAGES * 256, " bytes!"
}

; the ELoad blob is assembled by DASM (see src/bitops/bitops-eload.s) to run from
; where the loader slot is, so that has to stay where it is, or the blob has to be
; assembled for the new place.

!if loader_slot != $1d00 {
	!error "The ELoad blob is built for a loader slot at $1d00, but it is at ", loader_slot, "!"
}

; the Bitops drive code, which is built the same way (see src/bitops/bitops-drive.s),
; has the install part run from the load buffer, and receives its sectors in the
; page of the right audio buffer.

!ifndef c128 {
	!if load_buffer != $1800 {
		!error "The Bitops install part is built for a load buffer at $1800, but it is at ", load_buffer, "!"
	}
	!if audio_buffer_right != $1200 {
		!error "The Bitops runtime is built for a sector buffer at $1200, but the right audio buffer is at ", audio_buffer_right, "!"
	}
	!if BITOPS_INSTALL_SIZE > LOAD_BUFFER_PAGES * 256 {
		!error "The Bitops install part doesn't fit in the load buffer by ", BITOPS_INSTALL_SIZE - LOAD_BUFFER_PAGES * 256, " bytes!"
	}
}

!if loader_images_end - loader_images_start + LOADER_SLOT_SIZE > EXP_LOADER_PAGES * 256 {
	!error "Loader images don't fit in the expansion memory pages that are reserved for them by ", loader_images_end - loader_images_start + LOADER_SLOT_SIZE - EXP_LOADER_PAGES * 256, " bytes!"
}

!if strings_images_end - strings_images_start > EXP_STRING_PAGES * 256 {
	!error "The strings don't fit in the expansion memory pages that are reserved for them by ", strings_images_end - strings_images_start - EXP_STRING_PAGES * 256, " bytes!"
}

; the strings go in the init code's part of the transient area, which is overwritten
; when the volume table is generated.  init has stashed them by then, but they have
; to be inside the area, or they'd be in the way of the tables that come after it.

!if strings_images_end > volume_table + 64 * 256 {
	!error "The init code, the images and the strings overflow the volume table by ", strings_images_end - volume_table - 64 * 256, " bytes!"
}

!if audio_images_end - audio_images_start + AUDIO_TRANSIENT_MAX > EXP_AUDIO_DRIVER_PAGES * 256 {
	!error "Audio driver images don't fit in the expansion memory pages that are reserved for them by ", audio_images_end - audio_images_start + AUDIO_TRANSIENT_MAX - EXP_AUDIO_DRIVER_PAGES * 256, " bytes!"
}
