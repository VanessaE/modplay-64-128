This is the repository for my Commodore 64/128 MOD Player v2.0 project.

This project is a nearly-from-scratch full re-write of the old players.

This originally started way back in the mid 1990's as a way to let my C128 play some of the simpler MOD music, at a time when I did not have a decent PC with decent audio capabilities (let alone something nice like an Amiga).

I figured, surely my C128 has enough juice to do it, right?  Well, some of the first code was mediocre... but it worked!

A few years later I "ported" the core code to the C64, upgrading the sequencer in the process, and adding support for the SuperCPU and a few more sound playback methods.

Sadly that version never got a good UI, just a simple menu.

Other folks came along later and made some improvements to the C64 version's codebase, but the C128 version kinda just....got forgotten.  My thanks goes out to Ian Coog for most of those improvements.

I did have another "version 2.0" nearly ready to release not too long after the original C64 v1.2 release, but I lost that code to a hard drive crash.  In retrospect, that wasn't much of a loss, because all that really consisted of was an all-assembly rewrite of the UI code, since that was in BASIC, while the actual player remained unchanged.

I tried a couple of times over the years to resurrect the project, but sadly I never got beyond doing some artwork and a few routines to handle that data.  I just couldn't seem to really get back into coding, and by that time, other interests kinda took over, so the project got shelved.

This repo exists as an attempt to remedy that.

My main goals, apart from not using BASIC anymore, are:

* Have just ONE codebase for all supported platforms, since 99% of the code can be the same all around.
* take advantage of things like conditional assembly, macros, split-up files, and so on -- things I just didn't do back in the old days.
* Give the C128 variant the more-filled-out sequencer like the C64 version had (though for this project, I was forced to rewrite that code).
* Give the C64 variant the nice Stereo-SID-Player-inspired user interface the C128 version had.
* Improve the audio quality by using interrupt-driven, buffered audio output.
* Improve the slow-as-molasses loader. 😛  If you have an "Ultimate" device (U64, C64U, 1541U), the Command Interface is supported for faster loading.
* Make the program more "modular" so that it's easy to add support for other audio and memory devices and other platforms/variants.
* Make it possible to load and play a few 6- and 8-channel MODs, and perhaps other audio formats.

**At the moment, as far as platforms go, this program supports oldskool C64's and C128's, with or without a SuperCPU (later version only), and it supports the C64 Ultimate and Ultimate64.  An REU of any size is required in all cases, which can be either the oldskool cartridge, or if your hardware has this feature built-in.**

Ultimate64 users:  If you have real SID chips installed, or their modern replacements such as ARM2SID, FPGASID, etc., you **must** have firmware v3.14e or higher, as it contains a critical feature fix.  Plus, you'll be able to use the Mahoney driver for clean, crisp almost-8-bit audio.  If you are not using the SID sockets at all, then older firmware versions should be fine (but you'll only have 4-bit audio).

C64 Ultimate users: sorry folks, Commodore's latest firmware (1.1.0, after the renumbering) will not suffice, it doesn't have the fix.  Unless you're willing to disable your SIDs and live with 4-bit audio, you'll have to wait for them to catch up, or you can run the Ultimate64 v3.14e or later firmware, which seems to work just fine (but be aware, you'll lose keyboard lighting on machines so-equipped, and the menus won't be as you're used to, and you'll have to source new ROM image files).

This project is meant to be worked-on and built on Linux using common tools.  You will need:

* GNU make (any recent version should be fine)
* ACME assembler (v0.97 or newer)
* exomizer (v3.1.1 or newer, just the cruncher tool, the decruncher is part of this source tree)
* cc1541 (v4.2 or later, and not the "c1541" that comes with VICE)

To build it, just cd into the top level directory and just run `make` (or you could `make -f Makefile-linux`).  Disk images and individual binaries will be left in directories so-named.

There is also a Makefile for Windows, if you're crazy enough to try to build on that platform. 😉  You'll need MinGW, but otherwise it should work more or less the same way as on Linux.  For further details, see [the specific README](README-windows.txt) for that OS.

**DOWNLOADS:**

Disk images can be found in the repository's **[Package Registry](https://gitlab.com/VanessaE/modplay-64-128/-/packages)** (or you can get there from the sidebar).

**AI/LLM DISCLOSURE:**

I would normally not be interested in (let alone advocate for) the use of AI tools for coding, but the simple fact of the matter is, they're getting pretty good these days, and I'm not getting any younger or any more energetic.  99% of the code in this project is hand-crafted by yours truly the old fashioned way (Steinway & Sons would be proud), less than 1% is third-party contributions, Codebase64, etc.

With that being the case, I've decided not to worry about some minuscule fraction being AI contributions.  As long as proper effort has been put into making the code work first before turning to AI to add some polish, and as long as said polish is high quality, I guess I can live with that.
