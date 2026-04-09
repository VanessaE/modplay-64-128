; SET VOLUME

; sets a sample's volume, either by way of an effect command, or by a new
; sample being started, or by unmuting a track.  sets the address targets in
; the mixer also.

; enter run_effect_set_volume with .Y = track, the latter set_volume needs
; that along with .A = new volume level.

run_effect_set_volume
	lda seq_command_arguments,y

set_volume
	ldx current_track_gate_flags,y
	bmi set_volume_skip_gate_check
	rts

set_volume_skip_gate_check
	sta current_sample_volume_levels,y
	ldx track_current_enable_flags,y
	bmi +
	rts

+	cmp #64
	bcc +
	lda #63
	bne voltab_use_upper

+	cmp #38
	bcs voltab_use_upper

	adc #>volume_table_lower
	jmp set_vol_addrs_only

voltab_use_upper
	clc
	adc #(>volume_table_upper)-38

set_vol_addrs_only
	bit filter_setting
	bmi +
	jmp mixer_standard_set_vol_addrs
+	jmp mixer_lowpass_set_vol_addrs

