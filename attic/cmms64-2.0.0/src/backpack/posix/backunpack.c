#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>


// global variables for the input stream
static unsigned char inbuf[1024];
static unsigned char *inptr = inbuf;
static unsigned int inlen = 0;
static unsigned int incount = 0;
static FILE *infile;

// global variables for the output stream
static unsigned char outbuf[1024];
static unsigned char *outptr = outbuf;
static unsigned int outlen = 0;
static unsigned int outcount = 0;
static FILE *outfile;

// backpack buffer
static unsigned char backpack[256];
static unsigned char backptr = 0;

// commandline options
static signed int opt_skip = 0;
static signed int opt_verbosity = 1;


// read a byte from the input stream
signed int readdata(void) {
  if (inlen == 0) {
    inlen = fread(inbuf, 1, sizeof(inbuf), infile);
    inptr = inbuf;
  }
  if (inlen) {
    ++incount;
    --inlen;
    return(*inptr++);
  } else {
    return(EOF);
  }
}


// flush the output buffer to disk
unsigned int flushdata(void) {
  unsigned int l;

  if (outlen) {
    l = fwrite(outbuf, 1, outlen, outfile);
    outlen = 0;
    outptr = outbuf;
    return(l);
  } else {
    return(0);
  }
}


// write a byte to the output stream
unsigned int writedata(unsigned char byte) {
  backpack[backptr++] = byte;
  ++outcount;
  if (outlen >= sizeof(outbuf)) {
    if (flushdata() == 0) {
      return(0);
    }
  }
  *outptr++ = byte;
  ++outlen;
  return(1);
}


// write data from backpack buffer
void writefrombackpack(unsigned char len, unsigned char offset) {
  unsigned char p;

  p = backptr + offset;
  do {
    writedata(backpack[p++]);
  } while (--len != 0);
}


void usage(void) {
  puts("Usage: backunpack [-s number] [-q] infile outfile\r\n");
}


int main(int argc, char **argv) {
  signed int c;
  char *inname, *outname;
  int l, i;
  int opt;

  // parse args
  while ((opt = getopt(argc, argv, "s:qh")) != -1) {
    switch (opt) {
    case 's':
      opt_skip = strtol(optarg, (char **)NULL, 10);
      if (opt_skip < 1) {
	usage();
	return(1);
      }
      break;
    case 'q':
      opt_verbosity = 0;
      break;
    case 'h':
      usage();
      return(0);
      break;
    default:
      usage();
      return(1);
    }
  }
  argc -= optind;
  argv += optind;

  if (argc < 2) {
    usage();
    return(1);
  }

  inname = argv[0];
  outname = argv[1];

  // open files
  if ((infile = fopen(inname, "rb")) == NULL) {
    printf("%s: ", inname);
    perror("couldn't open for reading");
    return(1);
  }

  if ((outfile = fopen(outname, "wb")) == NULL) {
    fclose(infile);
    printf("%s: ", inname);
    perror("couldn't open for writing");
    return(1);
  }

  // skip bytes
  while (opt_skip) {
    if ((c = readdata()) < 0) {
      perror("couldn't read data");
      goto error;
    }
    writedata(c);
    --opt_skip;
  }

  while ((c = readdata()) >= 0) {

    // 0 means EOF
    if (c == 0) break;

    // msb set means literal run
    if (c & 0x80) {
      l = c - 127;
      for (i = 0; i < l; ++i) {
	if ((c = readdata()) < 0) {
	  perror("couldn't read data");
	  goto error;
	}
	writedata(c);
      }

    // msb clear means back reference
    } else {
      l = c + 2;
      if ((c = readdata()) < 0) {
	perror("couldn't read data");
	goto error;
      }
      writefrombackpack(l, c);
    }
  }

  // flush remaining bytes
  if (outlen) {
    if (flushdata() == 0) {
      perror("Write error");
      goto error;
    }
  }

  // print terse statistics
  if (opt_verbosity >= 1) {
    printf("Input %d bytes, output %d bytes, ratio %.1f%%\r\n", incount, outcount, (double) ((100.0 * (double) outcount) / (double) incount));
  }

  // close and exit
  fclose(infile);
  fclose(outfile);
  return(0);

 error:
  fclose(infile);
  fclose(outfile);
  return(2);
}
