/*

RLE packed koala viewer

Loads a packed image to 0x7000, unpacks to 0x4000, then displays it.

*/


#include <cbm.h>
#include <string.h>
#include <stdio.h>
#include <peekpoke.h>
#include "../cc65/rle.h"


static unsigned char *rlebuf = (unsigned char *) 0x7000;
static unsigned char *loadbuf = (unsigned char *) 0x4000;


unsigned char loadtoram(unsigned char *dest, unsigned int length) {
  memcpy(dest, loadbuf, length);
  loadbuf += length;
  return(0);
}


unsigned char *filename = "cyberwing.rle";

//unsigned int cbm_load (const char* name, unsigned char device, void* data);

int main(void) {
  unsigned char dev;
  unsigned int l;

  /* dev = PEEK(0xba); get current device number */
  dev = 8; /* doesn't work for some reason, so we'll go with 8 */

  if (cbm_load(filename, dev, rlebuf) == 0) {
    perror("load error");
    return(1);
  }

  if ((l = rle_unpack(loadbuf, rlebuf)) != 10001) {
    printf("%d != 10001 bytes\n", l);
    return(1);
  }

  /* load bitmap data */
  loadtoram((unsigned char *)0x2000, 8000);

  /* load screen data */
  loadtoram((unsigned char *)0x0400, 1000);

  /* load colour ram */
  loadtoram((unsigned char *)0xd800, 1000);

  /* load background colour into $d021 */
  loadtoram((unsigned char *)0xd021, 1);

  POKE(0xd011, 0x3b); /* enable bitmap mode */
  POKE(0xd016, 0x18); /* enable multicolour */
  POKE(0xd018, 0x1f); /* screen at $0400 bitmap at $2000 */
  POKE(0xd020, 0x00); /* black border */

  while (PEEK(0xc6) == 0) { ; } /* wait for key */

  POKE(0xd011, 0x1b);
  POKE(0xd016, 0x08);
  POKE(0xd018, 0x17);
  POKE(0xd020, 0x0e);
  POKE(0xd021, 0x06);

  putchar(147);
  POKE(198,0); /* clear keyboard queue */
}
