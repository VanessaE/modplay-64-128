/*

Routines for packing and unpacking run length encoded byte streams

When two or more consecutive bytes are identical, they are replaced by
<BYTE> <BYTE> <COUNT>. A COUNT of 0 indicates End Of Stream. A COUNT
of 1 indicates that two bytes should be written, a COUNT of 2 indicates
three bytes, and so on.

*/


/* Pack data. Returns the number of bytes written to destination. */
unsigned int __fastcall__ rle_pack(unsigned char *dest, const unsigned char *src, unsigned int length);
/* Unpack data. Returns the number of unpacked bytes. */
unsigned int __fastcall__ rle_unpack(unsigned char *dest, const unsigned char *src);
