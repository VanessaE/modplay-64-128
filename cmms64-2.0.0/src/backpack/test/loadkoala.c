/*

Backpacked koala viewer

Loads a packed image to 0x7000, unpacks to 0x4000, then displays it.

*/


#include <cbm.h>
#include <string.h>
#include <stdio.h>
#include <peekpoke.h>
#include "../cc65/backpack.h"


static unsigned char *backbuf = (unsigned char *) 0x7000;
static unsigned char *loadbuf = (unsigned char *) 0x4000;
static unsigned char *filename = "cyberwing.bkp";


unsigned char loadtoram(unsigned char *dest, unsigned int length) {
  memcpy(dest, loadbuf, length);
  loadbuf += length;
  return(0);
}


int main(void) {
  unsigned char dev;
  unsigned int l;

  /* dev = PEEK(0xba); get current device number */
  dev = 8; /* doesn't work for some reason, so we'll go with 8 */

  if (cbm_load(filename, dev, backbuf) == 0) {
    perror("load error");
    return(1);
  }

  if ((l = back_unpack(loadbuf, backbuf)) != 10001) {
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

  POKE(198, 0);
  while (PEEK(198) == 0) { ; } /* wait for key */

  POKE(0xd011, 0x1b);
  POKE(0xd016, 0x08);
  POKE(0xd018, 0x17);
  POKE(0xd020, 0x0e);
  POKE(0xd021, 0x06);

  putchar(147);
  POKE(198, 0); /* clear keyboard queue */
}
