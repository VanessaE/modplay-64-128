#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>


// global variables for the output buffer
static int bufsize;
static unsigned char buffer[128];
static unsigned char *bufptr;
static int byteswritten;

// global arrays for the compression statistics
static unsigned long stat_literal[128];
static unsigned long stat_backref[256*128];

// commandline options
static signed int opt_skip = 0;
static signed int opt_verbosity = 1;


// min() and max() really should be in the stdlib...
#define min(A, B) ((A) < (B) ? (A) : (B))


// write a byte to the output stream
void writebyte(FILE *outfh, unsigned char byte) {
  if (fputc(byte, outfh) == EOF) {
    perror("write error");
    exit(3);
  }
  ++byteswritten;
}


// initialize the output buffer
void initbuffer(void) {
  bufptr = buffer;
  bufsize = 0;
}


// put a byte in the output buffer
void bufferbyte(unsigned char byte) {
  *bufptr++ = byte;
  ++bufsize;
}


// flush the output buffer
void flushbuffer(FILE *outfh) {
  if (bufsize) {
    stat_literal[bufsize - 1]++;
    //printf("Writing %d bytes\n", bufsize);
    writebyte(outfh, 127 + bufsize);
    bufptr = buffer;
    while (bufsize) {
      writebyte(outfh, *bufptr++);
      --bufsize;
    }
  } else {
    //printf("Flushing empty buffer\n");
  }
  bufptr = buffer;
}


// find the longest matching back reference
int findlongestmatch(unsigned char *in, unsigned char *buf, int maxlen, int bufsize, int *retoffset) {
  int matchlen = 0;
  int matchoffset = 0;
  int len;
  int offset = bufsize;

  // printf("searching %d byte buffer at %08x data at %08x\n", bufsize, buf, in);
  while (bufsize) {
    if (*buf == *in) {
      len = 1;
      // while (len < maxlen && len < bufsize && buf[len] == in[len]) { // crazy _d!
      while (len < maxlen && buf[len] == in[len]) {
        ++len;
      }
      if (len > matchlen) {
	matchlen = len;
	matchoffset = offset;
      }
    }
    ++buf;
    --offset;
    --bufsize;
  }

  *retoffset = matchoffset & 255;
  return(matchlen);
}


// pack the data in memory
int backpack(unsigned char *data, int filesize, FILE *outfh) {
  unsigned char *inptr, *backptr;
  int bytesleft, bytesdone;
  int maxlen, backbufsize;
  int matchlen, matchoffset;

  inptr = data;
  bytesleft = filesize;
  bytesdone = 0;
  initbuffer();
  byteswritten = 0;

  // while there are still bytes left to compress
  while (bytesleft) {

    // find a match if there are written bytes, and some more input data
    if (bytesdone && bytesleft) {
      maxlen = min(bytesleft, 129);
      backbufsize = min(bytesdone, 256);
      backptr = inptr - backbufsize;
      matchlen = findlongestmatch(inptr, backptr, maxlen, backbufsize, &matchoffset);
    } else {
      matchlen = 0;
    }

    // if the match is at least 3 bytes, write a back reference
    if (matchlen >= 3) {
      flushbuffer(outfh);
      stat_backref[matchoffset*128 + (matchlen - 3)]++;
      writebyte(outfh, matchlen - 2);
      writebyte(outfh, 256 - matchoffset);
      bytesdone += matchlen;
      bytesleft -= matchlen;
      inptr += matchlen;
    } else {
      // otherwise we write literal bytes
      bufferbyte(*inptr);
      if (bufsize >= 128) {
	flushbuffer(outfh);
      }
      ++bytesdone;
      --bytesleft;
      ++inptr;
    }
  }

  // flush any leftover bytes
  flushbuffer(outfh);

  // write EOF marker
  writebyte(outfh, 0);

  return(byteswritten);
}


void usage(void) {
  puts("Usage: backpack [-s skip_bytes] [-q] [-v] infile outfile\r\n");
}


int main(int argc, char **argv) {
  char *inname, *outname;
  int insize, outsize;
  int bytesread = 0;
  FILE *infile, *outfile;
  unsigned char *rambuf;
  int l;
  int opt;
  int skipped = 0;
  unsigned char skipbuf[256];

  // reset the statistics
  memset(stat_literal, 0, sizeof(stat_literal));
  memset(stat_backref, 0, sizeof(stat_backref));

  // parse args
  while ((opt = getopt(argc, argv, "s:qvh")) != -1) {
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
    case 'v':
      opt_verbosity = 2;
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

  // open input and output files
  if ((infile = fopen(inname, "rb")) == NULL) {
    fprintf(stderr, "%s: ", inname);
    perror("couldn't open for reading");
    return(1);
  }

  if ((outfile = fopen(outname, "wb")) == NULL) {
    fclose(infile);
    fprintf(stderr, "%s: ", inname);
    perror("couldn't open for writing");
    return(1);
  }

  // determine input file length
  if (fseek(infile, 0, SEEK_END) != 0) {
    perror("Couldn't determine file size");
    goto error;
  }
  insize = ftell(infile);
  if (fseek(infile, 0, SEEK_SET) != 0) {
    perror("Seek failed");
    goto error;
  }

  // skip bytes
  if (opt_skip) {
    while (skipped < opt_skip) {
      if ((l = fread(skipbuf, 1, min(sizeof(skipbuf), opt_skip - skipped), infile)) == 0) {
	perror("Couldn't read data");
	goto error;
      }
      if (fwrite(skipbuf, 1, min(sizeof(skipbuf), opt_skip - skipped), outfile) != l) {
	perror("Couldn't write data");
	goto error;
      }
      skipped += l;
    }
    insize -= skipped;
  }

  // read input file into ram
  if ((rambuf = malloc(insize)) == NULL) {
    fprintf(stderr, "Out of memory (need %d bytes)\n", insize);
    goto error;
  }
  while (bytesread < insize) {
    if ((l = fread(rambuf + bytesread, 1, min(4096, insize - bytesread), infile)) == 0) {
      perror("Couldn't read data");
      free(rambuf);
      goto error;
    }
    bytesread += l;
  }

  // pack
  outsize = backpack(rambuf, insize, outfile);

  // we're done with the input file
  free(rambuf);

  // print html header
  if (opt_verbosity >= 2) {
    puts("<html>");
    puts("<header>");
    puts("<title>Backpack Output Statistics</title>");
    puts("<style type=\"text/css\">");
    puts("td {");
    puts("  min-width: 2em;");
    puts("  text-align: center;");
    puts("}");
    puts("th.offset {");
    puts("  min-width: 2em;");
    puts("}");
    puts("</style>");
    puts("</header>");
    puts("<body>");
    printf("<h1>%s</h1>", inname);
  }

  // print terse stats
  if (opt_verbosity >= 1) {
    printf("Input %d bytes, output %d bytes, ratio %.1f%%\r\n", insize, outsize, (double) ((100.0 * (double) outsize) / (double) insize));
  }

  // print verbose stats
  if (opt_verbosity >= 2) {
    int x, y;

    puts("<h2>Literal runs</h2>");
    puts("<table border=\"1\" cellspacing=\"0\" cellpadding=\"1\">");
    puts("<tr><th>Length</th><th>Count</th></tr>");
    for (l = 0; l < 128; ++l) {
      if (stat_literal[l]) {
	printf("<tr><td>%d</td><td>%ld</td></tr>\n", l + 1, stat_literal[l]);
      } else {
	printf("<tr><td>%d</td><td></td></tr>\n", l + 1);
      }
    }
    puts("</table>");

    puts("<h2>Back references</h2>");
    puts("<table border=\"1\" cellspacing=\"0\" cellpadding=\"1\">");
    printf("<tr><th class=\"offset\"></th>");
    for (x = 0; x < 127; ++x) {
      printf("<th>%d</th>", x + 3);
    }
    puts("</tr>");
    for (y = 255; y >= 0; --y) {
      printf("<tr><th>%d</th>", y - 256);
      for (x = 0; x < 127; ++x) {
	if (stat_backref[y*128 + x]) {
	  printf("<td>%ld</td>", stat_backref[y*128 + x]);
	} else {
	  printf("<td></td>");
	}
      }
      puts("</tr>");
    }
    puts("</table>");
  }

  // print html footer
  if (opt_verbosity >= 2) {
    puts("</body>");
    puts("</html>");
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
