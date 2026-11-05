; The definitions for hd-host-install.s and hd-host-runtime.s, the C64's half of the
; HD streamer.  See hd-host-install.s for what it is.
;
; What the includer has to give:
;
;	hd_cmd_ptr	two bytes of zero page that are used while hd_start runs
;	hd_blk_buffer	256 bytes where a sector goes (the first two bytes are the
;			link of the sector, and then there are 254 of the file)
;	hd_image	where the bytes of hd-drive.s (the part that is the program
;			for the HD) are in the C64's memory, as they are uploaded
;
; and hd-drive.s has to come before hd-host-install.s (for the labels of its bytes).

; what hd_start returns in .X

HD_ERR_NO_RAMLINK	= 1
HD_ERR_NOT_HD		= 2
HD_ERR_NO_PARALLEL	= 3
HD_ERR_DEV_NOT_FOUND	= 4

; the C64's

hd_cpu_port	= $01
hd_k_status	= $90
hd_k_device	= $ba
hd_rasterline	= $d012
hd_cia2		= $dd00

hd_pa8255	= $df40			; (the RamLink's parallel port)
hd_pb8255	= $df41
hd_pc8255	= $df42
hd_cr8255	= $df43

hd_k_second	= $ff93
hd_k_tksa	= $ff96
hd_k_acptr	= $ffa5
hd_k_ciout	= $ffa8
hd_k_untalk	= $ffab
hd_k_unlsn	= $ffae
hd_k_listen	= $ffb1
hd_k_talk	= $ffb4

; in the C64, the RamLink's hardware is switched in and out with routines of the RamLink's
; KERNAL.  the C128 has no such KERNAL, so (in 128 mode) it is done with what they do,
; which is a write to $DF7E (in) or $DF7F (out), as CMD documented it.  the I/O has to be
; in for that, and the KERNAL for the calls that come before (it is all that is needed, so
; the 128 mode's memory configuration is left alone, as the burst loader leaves it).

hd_rl_on	= $e0a9			; (the C64)
hd_rl_off	= $fe0f
hd_rl_on_reg	= $df7e			; (the C128)
hd_rl_off_reg	= $df7f

hd_krnl_io_in	= $36
hd_CR		= 13

; the lines of the serial bus, in $DD00:  bits 4 and 5 are what is sent, with 1 for
; pulling the line down, and bits 6 and 7 are what comes in, with 1 for high.

