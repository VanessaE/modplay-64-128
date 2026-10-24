; ============================
; assemble-time error handling

!if bzp_low_end > $0023 {
	!error "Backed-up-zero-page variables, lower part exceeds $0023 by ", * - $0023, " bytes! (",bzp_low_end,")"
}

!if bzp_lowmid_end > $0050 {
	!error "Backed-up-zero-page variables, lower middle part exceeds $0050 by ", * - $0050, " bytes! (",bzp_lowmid_end,")"
}

!if bzp_upmid_end > $0059 {
		!error "Backed-up-zero-page variables, upper middle part exceeds $0059 by ", * - $0059, " bytes! (",bzp_upmid_end,")"
}

!if bzp_top_end > $00f6 {
	!error "Backed-up-zero-page variables, top part exceeds $f6 by ", * - $00f6, " bytes! (",bzp_top_end,")"
}

!ifndef c128 {
	!if lma_cur_end > $03ff {
		!error "Low memory area exceeds overlaps `multablo` by ", * - $03ff, " bytes! (",lma_cur_end,")"
	}
} else {
	!if lma_cur_end > $02a1 {
		!error "Low memory area overlaps C128 indirect routines by ", * - $02a1, " bytes! (",lma_cur_end,")"
	}
}

!if mv_end > $0fff {
	!error "Main variables zone exceeds $0fff by ", * - $0fff, " bytes! (",mv_end,")"
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
	!error "Mid-memory tables overlap high memory area by ", main_mem_free_end - end_of_mid_mem_tables, " bytes! (",end_of_mid_mem_tables,")"
}

!if under_kernal_code_end > and_f0_table {
	!error "Under-KERNAL code overlaps and_f0_table by ", under_kernal_code_end - and_f0_table, " bytes! (",under_kernal_code_end,")"
}

!if nnt_end > $fff9 {
	!error "note_names_table overlaps CPU hardware vectors at $fffa by ", nnt_end - $fff9, " bytes! (",nnt_end,")"
}
