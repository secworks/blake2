//======================================================================
//
// blake2b.c
// ---------
// A simple BLAKE2b Reference Implementation. Source is from RFC 7693:
// https://tools.ietf.org/html/rfc7693
//
//
// Reference code by M-J. Saarinen, J-P. Aumasson.
// Copyright (c) 2015 IETF Trust and the persons identified as the
// document authors.  All rights reserved.
//
//
// State dumping routines and code for additional test cases by
// Joachim Strömbergson. For these contributions the license is:
//
// Copyright (c) 2018, Assured AB
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

#include <stdio.h>
#include "blake2b.h"

// Cyclic right rotation.

#ifndef ROTR64
#define ROTR64(x, y)  (((x) >> (y)) ^ ((x) << (64 - (y))))
#endif


// Little-endian byte access.
#define B2B_GET64(p)                               \
  (((uint64_t) ((uint8_t *) (p))[0]) ^             \
   (((uint64_t) ((uint8_t *) (p))[1]) << 8) ^      \
   (((uint64_t) ((uint8_t *) (p))[2]) << 16) ^     \
   (((uint64_t) ((uint8_t *) (p))[3]) << 24) ^     \
   (((uint64_t) ((uint8_t *) (p))[4]) << 32) ^     \
   (((uint64_t) ((uint8_t *) (p))[5]) << 40) ^     \
   (((uint64_t) ((uint8_t *) (p))[6]) << 48) ^     \
   (((uint64_t) ((uint8_t *) (p))[7]) << 56))


// G Mixing function.
#define B2B_G(a, b, c, d, x, y) {      \
    v[a] = v[a] + v[b] + x;            \
    v[d] = ROTR64(v[d] ^ v[a], 32);    \
    v[c] = v[c] + v[d];                \
    v[b] = ROTR64(v[b] ^ v[c], 24);    \
    v[a] = v[a] + v[b] + y;            \
    v[d] = ROTR64(v[d] ^ v[a], 16);    \
    v[c] = v[c] + v[d];                \
    v[b] = ROTR64(v[b] ^ v[c], 63); }


// Initialization Vector.
static const uint64_t blake2b_iv[8] = {
  0x6a09e667f3bcc908, 0xbb67ae8584caa73b,
  0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
  0x510e527fade682d1, 0x9b05688c2b3e6c1f,
  0x1f83d9abfb41bd6b, 0x5be0cd19137e2179
};


// Sigma table.
const uint8_t sigma[12][16] = {
  { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
  { 14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3 },
  { 11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4 },
  { 7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8 },
  { 9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13 },
  { 2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9 },
  { 12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11 },
  { 13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10 },
  { 6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5 },
  { 10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0 },
  { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
  { 14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3 }
};


//------------------------------------------------------------------
// Helper function to dump the blake2b context at interesting
// points during processing.
//------------------------------------------------------------------
static void dump_context(blake2b_ctx *ctx)
{
  uint8_t i;

  printf("Block:\n");
  for (i = 0 ; i < 128 ; i++) {
    if ((i > 0) && (i % 8 == 0))
      printf("\n");
    printf("0x%02x ", ctx->b[i]);
  }
  printf("\n\n");

  printf("Chained state:\n");
  printf("h[0] = 0x%016llx  h[1] = 0x%016llx  h[2] = 0x%016llx  h[3] = 0x%016llx\n",
         ctx->h[0], ctx->h[1], ctx->h[2], ctx->h[3]);
  printf("h[4] = 0x%016llx  h[5] = 0x%016llx  h[6] = 0x%016llx  h[7] = 0x%016llx\n",
         ctx->h[4], ctx->h[5], ctx->h[6], ctx->h[7]);
  printf("\n");

  printf("Byte counter:\n");
  printf("t[0] = 0x%016llx  t[1] = 0x%016llx\n",
         ctx->t[0], ctx->t[1]);
  printf("\n");

  printf("\n");
}


//------------------------------------------------------------------
//------------------------------------------------------------------
static void dump_v(uint64_t *v)
{
  printf("v[00] = 0x%016llx  v[01] = 0x%016llx  v[02] = 0x%016llx  v[03] = 0x%016llx\n",
         v[0], v[1], v[2], v[3]);
  printf("v[04] = 0x%016llx  v[05] = 0x%016llx  v[06] = 0x%016llx  v[07] = 0x%016llx\n",
         v[4], v[5], v[6], v[7]);
  printf("v[08] = 0x%016llx  v[09] = 0x%016llx  v[10] = 0x%016llx  v[11] = 0x%016llx\n",
         v[8], v[9], v[10], v[11]);
  printf("v[12] = 0x%016llx  v[13] = 0x%016llx  v[14] = 0x%016llx  v[15] = 0x%016llx\n",
         v[12], v[13], v[14], v[15]);
  printf("\n");
}


//------------------------------------------------------------------
// Compression function. "last" flag indicates last block.
//------------------------------------------------------------------
static void blake2b_compress(blake2b_ctx *ctx, int last)
{

  int i;
  uint64_t v[16], m[16];

  for (i = 0; i < 8; i++) {           // init work variables
    v[i] = ctx->h[i];
    v[i + 8] = blake2b_iv[i];
  }
  v[12] ^= ctx->t[0];                 // low 64 bits of offset
  v[13] ^= ctx->t[1];                 // high 64 bits
  if (last)                           // last block flag set ?
    v[14] = ~v[14];

  for (i = 0; i < 16; i++)            // get little-endian words
    m[i] = B2B_GET64(&ctx->b[8 * i]);

  if (last)
    printf("This is the last block\n");

  printf("State before G funcions:\n");
  dump_context(ctx);

  printf("State of v before G functions:\n");
  dump_v(&v[0]);

  for (i = 0; i < 12; i++) {          // twelve rounds
    B2B_G( 0, 4,  8, 12, m[sigma[i][ 0]], m[sigma[i][ 1]]);
    B2B_G( 1, 5,  9, 13, m[sigma[i][ 2]], m[sigma[i][ 3]]);
    B2B_G( 2, 6, 10, 14, m[sigma[i][ 4]], m[sigma[i][ 5]]);
    B2B_G( 3, 7, 11, 15, m[sigma[i][ 6]], m[sigma[i][ 7]]);
    B2B_G( 0, 5, 10, 15, m[sigma[i][ 8]], m[sigma[i][ 9]]);
    B2B_G( 1, 6, 11, 12, m[sigma[i][10]], m[sigma[i][11]]);
    B2B_G( 2, 7,  8, 13, m[sigma[i][12]], m[sigma[i][13]]);
    B2B_G( 3, 4,  9, 14, m[sigma[i][14]], m[sigma[i][15]]);
  }

  printf("State of v after G functions:\n");
  dump_v(&v[0]);

  for( i = 0; i < 8; ++i )
    ctx->h[i] ^= v[i] ^ v[i + 8];
}


//------------------------------------------------------------------
// Initialize the hashing context "ctx" with optional key "key".
//      1 <= outlen <= 64 gives the digest size in bytes.
//      Secret key (also <= 64 bytes) is optional (keylen = 0).
//------------------------------------------------------------------
int blake2b_init(blake2b_ctx *ctx, size_t outlen,
                 const void *key, size_t keylen)        // (keylen=0: no key)
{
  size_t i;

  if (outlen == 0 || outlen > 64 || keylen > 64)
    return -1;                      // illegal parameters

  for (i = 0; i < 8; i++)             // state, "param block"
    ctx->h[i] = blake2b_iv[i];
  ctx->h[0] ^= 0x01010000 ^ (keylen << 8) ^ outlen;

  ctx->t[0] = 0;                      // input count low word
  ctx->t[1] = 0;                      // input count high word
  ctx->c = 0;                         // pointer within buffer
  ctx->outlen = outlen;

  for (i = keylen; i < 128; i++)      // zero input block
    ctx->b[i] = 0;
  if (keylen > 0) {
    blake2b_update(ctx, key, keylen);
    ctx->c = 128;                   // at the end
  }

  printf("State after blake2b_init:\n");
  dump_context(ctx);

  return 0;
}


//------------------------------------------------------------------
// Add "inlen" bytes from "in" into the hash.
//------------------------------------------------------------------
void blake2b_update(blake2b_ctx *ctx,
                    const void *in, size_t inlen)       // data bytes
{
  size_t i;

  for (i = 0; i < inlen; i++) {
    if (ctx->c == 128) {            // buffer full ?
      ctx->t[0] += ctx->c;        // add counters
      if (ctx->t[0] < ctx->c)     // carry overflow ?
        ctx->t[1]++;            // high word
      blake2b_compress(ctx, 0);   // compress (not last)
      ctx->c = 0;                 // counter to zero
    }
    ctx->b[ctx->c++] = ((const uint8_t *) in)[i];
  }
}


//------------------------------------------------------------------
// Generate the message digest (size given in init).
// Result placed in "out".
//------------------------------------------------------------------
void blake2b_final(blake2b_ctx *ctx, void *out)
{
  size_t i;

  ctx->t[0] += ctx->c;                // mark last block offset
  if (ctx->t[0] < ctx->c)             // carry overflow
    ctx->t[1]++;                    // high word

  while (ctx->c < 128)                // fill up with zeros
    ctx->b[ctx->c++] = 0;
  blake2b_compress(ctx, 1);           // final block flag = 1

  // little endian convert and store
  for (i = 0; i < ctx->outlen; i++) {
    ((uint8_t *) out)[i] =
      (ctx->h[i >> 3] >> (8 * (i & 7))) & 0xFF;
  }
}


//------------------------------------------------------------------
// blake2b
// Convenience function for all-in-one computation.
//------------------------------------------------------------------
int blake2b(void *out, size_t outlen,
            const void *key, size_t keylen,
            const void *in, size_t inlen)
{
  blake2b_ctx ctx;

  if (blake2b_init(&ctx, outlen, key, keylen))
    return -1;
  blake2b_update(&ctx, in, inlen);
  blake2b_final(&ctx, out);

  return 0;
}

//======================================================================
// EOF blake2b.c
//======================================================================
