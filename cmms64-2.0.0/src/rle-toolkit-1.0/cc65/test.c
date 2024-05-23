/*

Pack data to a buffer, unpack and compare with original. If source and
destination are identical, everything works. Simple.

*/

#include <stdio.h>
#include <string.h>
#include "rle.h"


// number of bytes to pack
#define DATASIZE 1000
// source
#define SRC 0x0400
// destination
#define DEST 0x4400
// buffer, worst case should be DATASIZE * 1.5 + 2
#define BUFFER 0xc000
#define BUFSIZE 0x1000


void main(void) {
  unsigned int packlen, unpacklen, diffcount, i;
  unsigned char *src, *dest, *buffer;

  src = (unsigned char *) SRC;
  dest = (unsigned char *) DEST;
  buffer = (unsigned char *) BUFFER;

  // fill with 0x55 to see what gets written
  memset(buffer, 0x55, BUFSIZE);
  memset(dest, 0x55, DATASIZE);

  // pack src to buffer
  packlen = rle_pack(buffer, src, DATASIZE);
  // unpack buffer to dest
  unpacklen = rle_unpack(dest, buffer);

  // check differences
  diffcount = 0;
  for (i = 0; i < DATASIZE; ++i) {
    if (*src++ != *dest++) {
      ++diffcount;
    }
  }

  // print statistics
  printf("Packed %d bytes to %d bytes\n", DATASIZE, packlen);
  printf("Unpacked to %d bytes\n", unpacklen);
  printf("%d bytes differ\n", diffcount);
}
