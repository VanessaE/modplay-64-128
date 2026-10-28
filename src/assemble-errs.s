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

!if end_of_mid_mem_tables > main_mem_free_end {
	!error "Mid-memory tables overlap high memory area by ", end_of_mid_mem_tables - main_mem_free_end, " bytes! (",end_of_mid_mem_tables - 1,")"
}

!if under_kernal_code_end > $ff00 {
	!error "Under-KERNAL code overlaps MMU/REU ($ff00) by ", under_kernal_code_end - $ff00, " bytes! (",under_kernal_code_end - 1,")"
}

!if nnt_end > $fffa {
	!error "note_names_table overlaps CPU hardware vectors at $fffa by ", nnt_end - $fffa, " bytes! (",nnt_end - 1,")"
}

; each audio driver is split into a transient part and a resident part (see the
; comments in the drv-*.s files).  when the drivers get swapped in from under I/O,
; the resident part has to fit in one page along with its two entry jumps, and the
; transient part has to fit in two block copies of 255 bytes along with its three
; entry jumps.

AUDIO_RESIDENT_MAX	= 256 - 2 * 3
AUDIO_TRANSIENT_MAX	= 2 * 255 - 3 * 3

!if sid_4bit_resident_end - sid_4bit_resident > AUDIO_RESIDENT_MAX {
	!error "Resident part of the SID 4-bit audio driver exceeds one page by ", sid_4bit_resident_end - sid_4bit_resident - AUDIO_RESIDENT_MAX, " bytes!"
}

!if sid_4bit_transient_end - sid_4bit_driver_init > AUDIO_TRANSIENT_MAX {
	!error "Transient part of the SID 4-bit audio driver exceeds two copies by ", sid_4bit_transient_end - sid_4bit_driver_init - AUDIO_TRANSIENT_MAX, " bytes!"
}

!if sid_4bit_dithered_resident_end - sid_4bit_dithered_resident > AUDIO_RESIDENT_MAX {
	!error "Resident part of the SID 4-bit dithered audio driver exceeds one page by ", sid_4bit_dithered_resident_end - sid_4bit_dithered_resident - AUDIO_RESIDENT_MAX, " bytes!"
}

!if sid_4bit_dithered_transient_end - sid_4bit_dithered_driver_init > AUDIO_TRANSIENT_MAX {
	!error "Transient part of the SID 4-bit dithered audio driver exceeds two copies by ", sid_4bit_dithered_transient_end - sid_4bit_dithered_driver_init - AUDIO_TRANSIENT_MAX, " bytes!"
}

!if sid_mahoney_resident_end - sid_mahoney_resident > AUDIO_RESIDENT_MAX {
	!error "Resident part of the SID Mahoney audio driver exceeds one page by ", sid_mahoney_resident_end - sid_mahoney_resident - AUDIO_RESIDENT_MAX, " bytes!"
}

!if sid_mahoney_transient_end - sid_mahoney_driver_init > AUDIO_TRANSIENT_MAX {
	!error "Transient part of the SID Mahoney audio driver exceeds two copies by ", sid_mahoney_transient_end - sid_mahoney_driver_init - AUDIO_TRANSIENT_MAX, " bytes!"
}

!if dac_resident_end - dac_resident > AUDIO_RESIDENT_MAX {
	!error "Resident part of the DAC audio driver exceeds one page by ", dac_resident_end - dac_resident - AUDIO_RESIDENT_MAX, " bytes!"
}

!if dac_transient_end - dac_driver_init > AUDIO_TRANSIENT_MAX {
	!error "Transient part of the DAC audio driver exceeds two copies by ", dac_transient_end - dac_driver_init - AUDIO_TRANSIENT_MAX, " bytes!"
}

!if digimax_mk1_resident_end - digimax_mk1_resident > AUDIO_RESIDENT_MAX {
	!error "Resident part of the DigiMAX Mk1 audio driver exceeds one page by ", digimax_mk1_resident_end - digimax_mk1_resident - AUDIO_RESIDENT_MAX, " bytes!"
}

!if digimax_mk1_transient_end - digimax_mk1_driver_init > AUDIO_TRANSIENT_MAX {
	!error "Transient part of the DigiMAX Mk1 audio driver exceeds two copies by ", digimax_mk1_transient_end - digimax_mk1_driver_init - AUDIO_TRANSIENT_MAX, " bytes!"
}

!if digimax_mk2_resident_end - digimax_mk2_resident > AUDIO_RESIDENT_MAX {
	!error "Resident part of the DigiMAX Mk2 audio driver exceeds one page by ", digimax_mk2_resident_end - digimax_mk2_resident - AUDIO_RESIDENT_MAX, " bytes!"
}

!if digimax_mk2_transient_end - digimax_mk2_driver_init > AUDIO_TRANSIENT_MAX {
	!error "Transient part of the DigiMAX Mk2 audio driver exceeds two copies by ", digimax_mk2_transient_end - digimax_mk2_driver_init - AUDIO_TRANSIENT_MAX, " bytes!"
}
