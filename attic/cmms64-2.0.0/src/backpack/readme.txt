Backpack for CC65
-----------------

Backpack consists of:

  * a small LZSS decompression library for CC65
  * commandline utilities to pack and unpack files
  * sample code that shows you how to use it


Compression API
---------------

The library consists of a single function, back_unpack, that can be
called from both C and assembler.

C interface:

  unsigned int __fastcall__ back_unpack(unsigned char *dest, unsigned
					char *src);

Assembler interface:

	.import back_unpack
	.importzp src, dest
	.import destlen

	; set source pointer
	lda #<sourcedata
	sta src
	lda #>sourcedata
	sta src + 1

	; set destination pointer
	lda #<destbuffer
	sta dest
	lda #>destbuffer
	sta dest + 1

	jsr back_unpack

	; length of output is returned in destlen


Packed stream format
--------------------

The stream consists of command bytes, and data bytes. The following
command bytes are used:

  Cmdbyte    Argbyte    Description
  0          none       End of file
  1-127      offset     Back reference, 3-129 bytes long, offset in
                        2's complement (i.e. * - 256 + offset)
  128-255    none       Literal run, 1-128 bytes long

As an example, here's how backpack would pack the string "spam, spam,
spam, and eggs":

  $85, "spam, "

    First there's a literal run of 6 bytes.

  $0a, $fa

    A match is found for "spam, ", and a back reference with length 12
    and offset -6 is generated. ...12? Instead of two back references
    with length 6, it's possible to do one long back reference. When
    the unpacker starts writing, there are only 6 bytes in the back
    buffer. After it has written the first 6 bytes, it starts reading
    its own data - which is another match for "spam, ". Implementation
    note: forward copying must be used!

  $87, "and eggs"

    Another literal run, with 8 bytes.

  $00

    And finally an End of file marker.


Commandline tools
-----------------

NAME
	backpack, backunpack

SYNOPSIS
	backpack [-s number] infile outfile
	backunpack [-s number] infile outfile

DESCRIPTION
	backpack compresses files using an LZSS based algorithm.
	backunpack unpacks files compressed with backpack.

OPTIONS
	-s number
		Skips the specified number of bytes, copying them
		verbatim to the output file, compressing the remainder
		of the file.

EXAMPLES
	To compress a PRG while preserving the load address, use -s 2:

		backpack -s 2 original.prg compressed.prg


Sample code
-----------

  loadimage.prg

Loads a packed koala image and displays it. Thanks, again, to TMR for
the image.


License
-------

Backpack is released under a slightly modified BSD license:

Copyright (c) 2005, Per Olofsson
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
