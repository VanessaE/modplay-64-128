; the strings that have to be in main memory, because something besides the print
; routines reads them (the DOS command and the error to look for, and the names
; that get copied into the file list), and the tables of addresses of the RLE-encoded
; lines of the main menu.
; everything else is in strings-128.s, and is kept in expansion memory (see modplay.s).

dir_check_string
	!text "cd:blahdeblah",0

syntax_err_string
	!text "syntax error",0

up_to_parent_dir_string
	!text "[Up, parent dir]",0

item_is_directory_msg
	!scr "      [Dir]"
	!byte 0

mm_lo
	!byte <line_2
	!byte <line_3
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_18_and_20
	!byte <line_19
	!byte <lines_18_and_20
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <line_23
	!byte <line_24

mm_hi
	!byte >line_2
	!byte >line_3
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_18_and_20
	!byte >line_19
	!byte >lines_18_and_20
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >line_23
	!byte >line_24
