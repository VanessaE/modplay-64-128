; SET VOLUME

; sets a sample's volume, either by way of an effect command, or by a new
; sample being started, or by unmuting a track.  sets the address targets in
; the mixer also.

; enter run_effect_set_volume with .Y = track, the latter set_volume needs
; that along with .A = new volume level.

run_effect_set_volume
	lda seq_command_arguments,y

set_volume
	cmp #64
	bcc +
	lda #63
	clc
+	sta current_sample_volume_levels,y
	adc #>volume_table

	ldx track_current_enable_flags,y	; consider track-muted state (if the
	bmi set_vol_addrs_only				; user pressed 1-4 while playing)
	rts

set_vol_addrs_only
	ldx current_track_gate_flags,y
	bmi +
	rts

+	jmp mixer_standard_set_vol_addrs

