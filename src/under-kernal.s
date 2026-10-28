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

		under_kernal_code_end = *
	}

; the audio drivers are not part of the code above.  each one is two images, which
; are assembled to run from the reserved page under the KERNAL and from the load
; buffer, but are stored here as plain data.  init stashes this whole block in
; expansion memory, and init_audio_driver fetches the images it needs.

audio_images_start

	!source "src/drv-sid-4b.s"
	!source "src/drv-sid-d4b.s"
	!source "src/drv-sid-mah.s"
	!source "src/drv-dac.s"
	!source "src/drv-digimax-mk1.s"
	!source "src/drv-digimax-mk2.s"

audio_images_end

}
