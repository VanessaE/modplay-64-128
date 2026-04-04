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

* Have just ONE codebase for all supported platforms, since 99.9% of the code can be the same all around
* take advantage of things like conditional assembly, macros, split-up files, and so on -- things I just didn't do back in the old days.
* Give the C128 variant the more-filled-out sequencer like the C64 version had (though for this project, I was forced to rewrite that code).
* Give the C64 variant the nice Stereo-SID-Player-inspired user interface the C128 version had.
* Improve the audio quality by using interrupt-driven, buffered audio output.
* Improve the slow-as-molasses loader. 😛
* Make the program more "modular" so that it's easy to add support for other hardware beyond SIDs, DigiMAX, REU, SuperCPU, etc.
* Make it possible to load and play a few 6- and 8-channel MODs, and perhaps other audio formats.

This project is meant to be worked-on and built on Linux using common tools; you will need GNU make, ACME assembler, and cc1541 (not the "c1541" that comes with VICE).

**DOWNLOADS:**

Disk images can be found in the repository's **[Package Registry](https://gitlab.com/VanessaE/modplay-64-128/-/packages)** (or you can get there from the sidebar).

