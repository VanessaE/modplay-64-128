; this stub links-in all of the code that
; needs to be tucked under the KERNAL ROM

!zone under_kernal {

under_kernal_code_copy
	.copysrc
-	lda under_kernal_code_origin
	.copytarget
	sta under_kernal_code
	inc .copysrc+1
	bne +
	inc .copysrc+2

+	inc .copytarget+1
	bne +
	inc .copytarget+2

+	lda .copytarget+1
	cmp #<under_kernal_code_end
	lda .copytarget+2
	sbc #>under_kernal_code_end
	bcc -
rts

under_kernal_code_origin
	!pseudopc under_kernal_code {
		!source "src/sequencer.s"
		!source "src/sequencer-aux.s"

		!source "src/mixer-standard.s"

		!source "src/drv-reu-musicops.s"

		!source "src/drv-sid-4b.s"
		!source "src/drv-sid-d4b.s"
		!source "src/drv-sid-mah.s"
		!source "src/drv-dac.s"
		!source "src/drv-digimax-mk1.s"
		!source "src/drv-digimax-mk2.s"

		!source "src/fxcmd-arpeggio.s"
		!source "src/fxcmd-pitch-sliding.s"
		!source "src/fxcmd-volume-sliding.s"
		!source "src/fxcmd-patbreak-posjump.s"
		!source "src/fxcmd-set-speed.s"
		!source "src/fxcmd-vibrato.s"
		!source "src/fxcmd-set-volume.s"
		!source "src/fxcmd-set-sample-offset.s"
		!source "src/fxcmd-extended-misc.s"

		under_kernal_code_end = *
	}

}
