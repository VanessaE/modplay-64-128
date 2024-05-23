RLE Toolkit for CC65
--------------------

RLE Toolkit consists of:

  * a small RLE compression library for CC65
  * commandline utilities to pack and unpack files
  * sample code that shows you how to use it


Compression API
---------------

There are two functions, rle_pack and rle_unpack, that can be called
from both C and assembler.

C interface:

  unsigned int __fastcall__ rle_pack(unsigned char *dest, unsigned char
				     *src, unsigned int length);

  unsigned int __fastcall__ rle_unpack(unsigned char *dest, unsigned
				       char *src);

Assembler interface:

	.import rle_pack
	.importzp src, dest
	.import srclen, destlen

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

	; set length of source data when packing
	; parameter is ignored when unpacking
	lda #<datalen
	sta srclen
	lda #>datalen
	sta srclen + 1

	jsr rle_pack
	  or
	jsr rle_unpack

	; length of output is returned in destlen


Packed stream format
--------------------

When two or more consecutive bytes are identical, they are replaced by
<BYTE> <BYTE> <COUNT>. A COUNT of 0 indicates End Of Stream. A COUNT
of 1 indicates that two bytes should be written, a COUNT of 2
indicates three bytes, and so on.


Commandline tools
-----------------

  rlepack infile outfile
  rleunpack infile outfile

Self explanatory. Right?


Sample code
-----------

  loadimage.prg

Loads a packed koala image and displays it. Thanks, again, to TMR for
the image.


License
-------

The RLE Toolkit is released under a slightly modified BSD license:

Copyright (c) 2004, Per Olofsson
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
