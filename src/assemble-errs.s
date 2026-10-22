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

!if end_of_mid_mem_tables > main_mem_free_end {
	!error "Mid-memory tables overlap high memory area by ", main_mem_free_end - end_of_mid_mem_tables, " bytes! (",end_of_mid_mem_tables,")"
}

!if under_kernal_code_end > and_f0_table {
	!error "Under-KERNAL code overlaps and_f0_table by ", under_kernal_code_end - and_f0_table, " bytes! (",under_kernal_code_end,")"
}

!if nnt_end > $fff9 {
	!error "note_names_table overlaps CPU hardware vectors at $fffa by ", nnt_end - $fff9, " bytes! (",nnt_end,")"
}
