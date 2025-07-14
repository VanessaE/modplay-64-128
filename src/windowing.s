; Windowing functions, used only on the C128

; these dimensions are all the CONTENT of the windows, excluding their frames

corner_tl_char				= $ac
corner_tr_char				= $bb
corner_bl_char				= $bc
corner_br_char				= $be
top_edge_char				= $60
bottom_edge_char			= $60

!ifndef c128 {
	left_edge_char				= $7d
	right_edge_char				= $7d
	fill_char					= " "
} else {
	left_edge_char				= $a1
	right_edge_char				= $a1
	fill_char					= RIGHT
}

!ifndef c128 {
	mini_popup_left_column			= 10
	mini_popup_width				= 18
	mini_popup_height				= 6

	short_popup_left_column			= 4
	short_popup_width				= 30
	short_popup_height				= 5

	medium_popup_left_column		= 4
	medium_popup_width				= 36
	medium_popup_height				= 15

	tall_popup_left_column			= 4
	tall_popup_width				= 30
	tall_popup_height				= 20

	text_input_popup_left_column	= 4
	text_input_popup_width			= 30
	text_input_popup_height			= 2
} else {
	mini_popup_left_column			= 0
	mini_popup_width				= 30
	mini_popup_height				= 6

	short_popup_left_column			= 0
	short_popup_width				= 30
	short_popup_height				= 5

	medium_popup_left_column		= 0
	medium_popup_width				= 40
	medium_popup_height				= 15

	tall_popup_left_column			= 0
	tall_popup_width				= 30
	tall_popup_height				= 20

	text_input_popup_left_column	= 0
	text_input_popup_width			= 40
	text_input_popup_height			= 2
}

short_popup_top_row					= (24 - short_popup_height) / 2
short_popup_bottom_row				= (24 + short_popup_height) / 2
short_popup_right_column				= short_popup_left_column + short_popup_width - 1

mini_popup_top_row					= (24 - mini_popup_height) / 2
mini_popup_bottom_row				= (24 + mini_popup_height) / 2
mini_popup_right_column				= mini_popup_left_column + mini_popup_width - 1

!ifdef c128 {
	mini_popup_left_col_real		= 40 - (mini_popup_width / 2)
	mini_popup_right_col_real		= 40 + (mini_popup_width / 2)
}

medium_popup_top_row				= (24 - medium_popup_height) / 2
medium_popup_bottom_row				= (24 + medium_popup_height) / 2
medium_popup_right_column			= medium_popup_left_column + medium_popup_width - 1

!ifdef c128 {
	medium_popup_left_col_real		= 40 - (medium_popup_width / 2)
	medium_popup_right_col_real		= 40 + (medium_popup_width / 2)
}

tall_popup_top_row					= (24 - tall_popup_height) / 2 - 1
tall_popup_bottom_row				= (24 + tall_popup_height) / 2 + 1

text_input_popup_top_row			= (24 - text_input_popup_height) / 2 + 1
text_input_popup_bottom_row			= (24 + text_input_popup_height) / 2 - 1
; this one is 1 char wider than normal, so it won't scroll if quote at end of line
text_input_popup_right_column		= text_input_popup_left_column + text_input_popup_width + 2 

!ifdef c128 {
	set_window_playlist_pane
		jsr FULLW
		clc
		lda #3
		ldx #5
		jsr WINDOW
		sec
		lda #21
		ldx #30
		jsr WINDOW
	rts

	set_window_menu_pane
		jsr FULLW
		clc
		lda #2
		ldx #34
		jsr WINDOW
		sec
		lda #16
		ldx #74
		jsr WINDOW
	rts

	set_window_infobox
		jsr FULLW
		clc
		lda #20
		ldx #34
		jsr WINDOW
		sec
		lda #22
		ldx #74
		jsr WINDOW
	rts

	set_window_mini_popup
		jsr FULLW
		clc
		lda #mini_popup_top_row
		ldx #mini_popup_left_col_real
		jsr WINDOW
		sec
		lda #mini_popup_bottom_row
		ldx #mini_popup_right_col_real
		jsr WINDOW
	rts

	set_window_medium_popup
		jsr FULLW
		clc
		lda #medium_popup_top_row
		ldx #medium_popup_left_col_real
		jsr WINDOW
		sec
		lda #medium_popup_bottom_row
		ldx #medium_popup_right_col_real
		jsr WINDOW
	rts

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

!text "draw"
; draw a window/popup, centered on the screen
; enter with .X/.Y = the window dimensions

!ifndef c128 {
	bl_color = MGRY
} else {
	bl_color = LGRY
}

draw_window
	php
	jsr calculate_corners
	plp

	!ifdef c128 {
		jsr FULLW
		clc
		lda top_row_pos
		ldx left_column_pos
		jsr WINDOW
		sec
		lda bottom_row_pos
		ldx right_column_pos
		jsr WINDOW
		clc
		ldx #0
		ldy #0
		jsr PLOT
		lda #CLR
		jsr CHROUT
		jsr FULLW
	}

	lda #<CHROUT
	sta print_vec
	lda #>CHROUT
	sta print_vec+1

	lda num_rows
	sta temp_abs_a

	ldx top_row_pos
	dex
	ldy left_column_pos
	dey
	clc					; seek to top-left corner
	jsr PLOT

	lda #WHT			; print top-left corner
	jsr CHROUT
	lda #corner_tl_char
	jsr CHROUT

	ldy num_columns		; print top edge
	lda #top_edge_char
-	jsr CHROUT
	dey
	bne -

	lda #corner_tr_char		; and follow it with the top-right corner
	jsr CHROUT

.nl
	lda #RETURN			; next line
	jsr CHROUT

	lda #WHT			; position and print the left edge
	jsr CHROUT
	jsr draw_win_seek_to_left_edge
	lda #left_edge_char
	jsr CHROUT

	ldy num_columns		; fill the body of the window
	lda #fill_char
-	jsr CHROUT
	dey
	bne -

	lda #bl_color			; and follow it with the right edge
	jsr CHROUT

	!ifdef c128 {		; on the C128 it'll always be a reverse $a1 anyway.
		lda #RVSON
		jsr CHROUT
	}

	lda #right_edge_char
	jsr CHROUT

	!ifdef c128 {
		lda #RVSOFF
		jsr CHROUT
	}

	dec temp_abs_a		; continue down the height
	bpl .nl

	lda #RETURN			; position and print bottom-left corner
	jsr CHROUT
	lda #WHT
	jsr CHROUT
	jsr draw_win_seek_to_left_edge
	lda #corner_bl_char
	jsr CHROUT

	lda #bl_color			; print bottom edge
	jsr CHROUT
	ldy num_columns
	lda #bottom_edge_char
-	jsr CHROUT
	dey
	bne -
	lda #corner_br_char		; and follow it with the bottom-right corner
	jsr CHROUT

	!ifdef c128 {
		jsr FULLW
		clc
		lda top_row_pos
		ldx left_column_pos
		jsr WINDOW
		sec
		lda bottom_row_pos
		ldx right_column_pos
		jsr WINDOW
		clc
		ldx #0
		ldy #0
		jsr PLOT
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

draw_mini_popup
	ldx #mini_popup_height
	ldy #mini_popup_width
	jsr draw_window
rts

draw_short_popup
	ldx #short_popup_height
	ldy #short_popup_width
	jsr draw_window
rts

draw_medium_popup
	ldx #medium_popup_height
	ldy #medium_popup_width
	jsr draw_window
rts

draw_tall_popup
	ldx #tall_popup_height
	ldy #tall_popup_width
	jsr draw_window
rts

draw_text_input_popup
	ldx #text_input_popup_height
	ldy #text_input_popup_width
	jsr draw_window
rts
