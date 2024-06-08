; Windowing functions, used only on the C128

; breaking out of a window just requires printing a couple of HOMEs.
;
; To set a new window requires breaking out of the old one, if
; any, storing new coordinates, printing SOMEthing first other than
; HOME (RVSOFF is a good choice), and THEN printing a HOME after that
; to lock-in the new coordinates.

; these dimensions are all the CONTENT of the windows, excluding their frames

!text "windowing",0

!ifndef c128 {
	mini_popup_left_column			= 10
	mini_popup_width				= 18
	mini_popup_height				= 5

	medium_popup_left_column		= 4
	medium_popup_width				= 30
	medium_popup_height				= 13

	tall_popup_left_column			= 4
	tall_popup_width				= 30
	tall_popup_height				= 20

	text_input_popup_left_column	= 4
	text_input_popup_width			= 30
	text_input_popup_height			= 2
} else {
	mini_popup_left_column			= 0
	mini_popup_width				= 30
	mini_popup_height				= 5

	medium_popup_left_column		= 0
	medium_popup_width				= 30
	medium_popup_height				= 10

	tall_popup_left_column			= 0
	tall_popup_width				= 30
	tall_popup_height				= 20

	text_input_popup_left_column	= 0
	text_input_popup_width			= 40
	text_input_popup_height			= 2
}

mini_popup_top_row					= (24 - mini_popup_height) / 2
mini_popup_bottom_row				= (24 + mini_popup_height) / 2
mini_popup_right_column				= mini_popup_left_column + mini_popup_width - 1

medium_popup_top_row				= (24 - medium_popup_height) / 2
medium_popup_bottom_row				= (24 + medium_popup_height) / 2
medium_popup_right_column			= medium_popup_left_column + medium_popup_width - 1

tall_popup_top_row					= (24 - tall_popup_height) / 2 - 1
tall_popup_bottom_row				= (24 + tall_popup_height) / 2 + 1

text_input_popup_top_row			= (24 - text_input_popup_height) / 2 + 1
text_input_popup_bottom_row			= (24 + text_input_popup_height) / 2 - 1
; this one is 1 char wider than normal, so it won't scroll if quote at end of line
text_input_popup_right_column		= text_input_popup_left_column + text_input_popup_width + 2 


!ifdef c128 {
	set_window_full_screen
		lda #HOME
		jsr CHROUT
		jsr CHROUT
		lda #0
		sta SCTOP
		lda #24
		sta SCBOT
		lda #0
		sta SCLF
		lda #79
		sta SCRT
		jmp commit_window_dimensions

	commit_window_dimensions
		lda #UP
		jsr CHROUT
		lda #HOME
		jsr CHROUT
	rts

	set_window_playlist_pane
		jsr set_window_full_screen
		lda #3
		sta SCTOP
		lda #21
		sta SCBOT
		lda #5
		sta SCLF
		lda #30
		sta SCRT
		jmp commit_window_dimensions

	set_window_menu_pane
		jsr set_window_full_screen
		lda #2
		sta SCTOP
		lda #16
		sta SCBOT
		lda #34
		sta SCLF
		lda #74
		sta SCRT
		jmp commit_window_dimensions

	set_window_infobox
		jsr set_window_full_screen
		lda #20
		sta SCTOP
		lda #22
		sta SCBOT
		lda #34
		sta SCLF
		lda #74
		sta SCRT
		jmp commit_window_dimensions
}

; enter with .X/.Y = rows/columns of the INTERIOR (analogous to the PLOT call)
; window will be centered.

calculate_corners
	stx num_rows
	sty num_columns

	sec					; calculate top/bottom row positions
	lda #25
	sbc num_rows
	lsr
	sta top_row_pos
	clc
	adc num_rows
	sta bottom_row_pos

	sec					; calculate left/right column positions
	lda #screen_width
	sbc num_columns
	lsr
	sta left_column_pos
	clc
	adc num_columns
	sec
	sbc #1
	sta right_column_pos
rts

; all this bullshit here :-) decides how to actually call the print function
; On C128, we just use lda #immediate's and call CHROUT like normal, because
; there's no need to separate PETSCII and ASCII.
;
; On C64, use lda absolute,x to get the char values from the tables, and route
; the print calls through either the ASCII print or CHROUT, via a vector

!ifndef c128 {
	window_edge_tables
		!byte $ac ; top-left corner
		!byte $bb ; top-right corner
		!byte $bc ; bottom-left corner
		!byte $be ; bottom-right corner
		!byte $60 ; top edge
		!byte $60 ; bottom edge
		!byte $7d ; left edge
		!byte $7d ; right edge

		!byte $08 ; same symbols, but using the ASCII font
		!byte $09
		!byte $0a
		!byte $0b
		!byte $02
		!byte $02
		!byte $01
		!byte $01

	char_table_select		!byte 0

	fill_char					= " "
	screen_width				= 40

	!macro PRINT_CHAR		{ +JSR_INDIRECT (print_vec) }

	!macro LDA_TL_CORNER	{ ldx char_table_select
							  lda window_edge_tables,x }
	!macro LDA_TR_CORNER	{ ldx char_table_select
							  lda window_edge_tables+1,x }
	!macro LDA_BL_CORNER	{ ldx char_table_select
							  lda window_edge_tables+2,x }
	!macro LDA_BR_CORNER	{ ldx char_table_select
							  lda window_edge_tables+3,x }
	!macro LDA_TOP_EDGE		{ ldx char_table_select
							  lda window_edge_tables+4,x }
	!macro LDA_BOT_EDGE		{ ldx char_table_select
							  lda window_edge_tables+5,x }
	!macro LDA_LEFT_EDGE	{ ldx char_table_select
							  lda window_edge_tables+6,x }
	!macro LDA_RIGHT_EDGE	{ ldx char_table_select
							  lda window_edge_tables+6,x }

} else {

	corner_tl_char				= $ac
	corner_tr_char				= $bb
	corner_bl_char				= $bc
	corner_br_char				= $be
	top_edge_char				= $60
	bottom_edge_char			= $60
	left_edge_char				= $a1
	right_edge_char				= $a1

	fill_char					= RIGHT
	screen_width				= 80

	!macro PRINT_CHAR     { jsr CHROUT }
	!macro LDA_TL_CORNER  { lda #corner_tl_char }
	!macro LDA_TR_CORNER  { lda #corner_tr_char }
	!macro LDA_BL_CORNER  { lda #corner_bl_char }
	!macro LDA_BR_CORNER  { lda #corner_br_char }
	!macro LDA_TOP_EDGE   { lda #top_edge_char }
	!macro LDA_BOT_EDGE   { lda #bottom_edge_char }
	!macro LDA_LEFT_EDGE  { lda #left_edge_char }
	!macro LDA_RIGHT_EDGE { lda #right_edge_char }
}

!text "draw"
; draw a window/popup, centered on the screen
; enter with .X/.Y = the window dimensions,
; and with carry set to use ASCII (only on C64 C128 doesn't need it)

draw_window
	php
	jsr calculate_corners
	plp

	!ifndef c128 {
		bcc +
		lda #<chrout_ascii
		sta print_vec
		lda #>chrout_ascii
		sta print_vec+1
		lda #8
		sta char_table_select

		jmp ++

	+	lda #<CHROUT
		sta print_vec
		lda #>CHROUT
		sta print_vec+1
		lda #0
		sta char_table_select
	}

++	lda num_rows
	sta tempzp_c

	!ifdef c128 {
		jsr erase_popup
	}

	ldx top_row_pos
	dex
	ldy left_column_pos
	dey
	clc					; seek to top-left corner
	jsr PLOT

	lda #WHT			; print top-left corner
	jsr CHROUT
	+LDA_TL_CORNER
	+PRINT_CHAR

	ldy num_columns		; print top edge
	+LDA_TOP_EDGE
-	+PRINT_CHAR
	dey
	bne -

	+LDA_TR_CORNER		; and follow it with the top-right corner
	+PRINT_CHAR

.nl
	lda #RETURN			; next line
	jsr CHROUT

	lda #WHT			; position and print the left edge
	jsr CHROUT
	jsr draw_win_seek_to_left_edge
	+LDA_LEFT_EDGE
	+PRINT_CHAR

	ldy num_columns		; fill the body of the window
	lda #fill_char
-	+PRINT_CHAR
	dey
	bne -

	lda #DGRY			; and follow it with the right edge
	jsr CHROUT
	!ifdef c128 {		; on the C128 it'll always be a reverse $a1 anyway.
		lda #RVSON
		jsr CHROUT
	}
	+LDA_RIGHT_EDGE
	+PRINT_CHAR
	!ifdef c128 {
		lda #RVSOFF
		jsr CHROUT
	}

	dec tempzp_c		; continue down the height
	bpl .nl

	lda #RETURN			; position and print bottom-left corner
	jsr CHROUT
	lda #WHT
	jsr CHROUT
	jsr draw_win_seek_to_left_edge
	+LDA_BL_CORNER
	+PRINT_CHAR

	lda #DGRY			; print bottom edge
	jsr CHROUT
	ldy num_columns
	+LDA_BOT_EDGE
-	+PRINT_CHAR
	dey
	bne -
	+LDA_BR_CORNER		; and follow it with the bottom-right corner
	+PRINT_CHAR

	!ifdef c128 {
		jsr set_window_full_screen
		lda top_row_pos
		sta SCTOP
		lda bottom_row_pos
		sta SCBOT
		lda left_column_pos
		sta SCLF
		lda right_column_pos
		sta SCRT
		jmp commit_window_dimensions
	} else {
		clc
		ldx top_row_pos
		ldy left_column_pos
		jsr PLOT
	}
rts

draw_win_seek_to_left_edge
	ldy left_column_pos
	dey
	lda #RIGHT
-	jsr CHROUT
	dey
	bne -
rts

!ifdef c128 {
	erase_popup
		jsr set_window_full_screen
		ldx top_row_pos
		dex
		stx SCTOP
		ldx bottom_row_pos
		inx
		stx SCBOT
		ldx left_column_pos
		dex
		dex
		stx SCLF
		ldx right_column_pos
		inx
		inx
		stx SCRT
		jsr commit_window_dimensions
		lda #CLR
		jsr CHROUT
		jsr set_window_full_screen
	rts
}

draw_mini_popup
	ldx #mini_popup_height
	ldy #mini_popup_width
	jsr draw_window
rts

draw_medium_popup
	ldx #medium_popup_height
	ldy #medium_popup_width
	jsr draw_window
rts

draw_tall_popup
	ldx #tall_popup_height
	ldy #medium_popup_width
	jsr draw_window
rts

draw_text_input_popup
	ldx #text_input_popup_height
	ldy #text_input_popup_width
	jsr draw_window
rts

top_row_pos			!byte 0
bottom_row_pos		!byte 0
left_column_pos		!byte 0
right_column_pos	!byte 0
num_rows			!byte 0
num_columns			!byte 0
