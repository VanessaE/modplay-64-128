; the strings that have to be in main memory, because something besides the print
; routines reads them (the DOS command and the error to look for, and the name
; that gets copied into the file list), the table that goes into the KERNAL's screen
; line links, and the tables of addresses of the RLE-encoded lines of the main menu.
; everything else is in strings-64.s, and is kept in expansion memory (see modplay.s).

screen_line_link_table
	!byte $84,$84,$84,$84,$84
	!byte $84,$84,$85,$85,$85
	!byte $85,$85,$85,$86,$86
	!byte $86,$86,$86,$86,$86
	!byte $87,$87,$87,$87,$87,$87

dir_check_string
	!text "cd:blahdeblah",0

syntax_err_string
	!text "syntax error",0

up_to_parent_dir_string
	!text "[Up, parent dir]",0

mm_lo
	!byte <line_2
	!byte <line_3
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_18_and_20
	!byte <line_19
	!byte <lines_18_and_20
	!byte <line_21
	!byte <lines_4_to_17_and_22
	!byte <line_23
	!byte <line_24

mm_hi
	!byte >line_2
	!byte >line_3
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_18_and_20
	!byte >line_19
	!byte >lines_18_and_20
	!byte >line_21
	!byte >lines_4_to_17_and_22
	!byte >line_23
	!byte >line_24
