//======================================================================
//
// blake2b_test.c
// --------------
// Test runner for the Blake2b reference model.
//
//
// Built with:
// clang -Wextra -O2 -o test blake2b_test.c blake2b.c -I blake2b.h
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


// Deterministic sequences (Fibonacci generator).

static void selftest_seq(uint8_t *out, size_t len, uint32_t seed)
{
  size_t i;
  uint32_t t, a , b;

  a = 0xDEAD4BAD * seed;              // prime
  b = 1;

  for (i = 0; i < len; i++) {         // fill the buf
    t = a + b;
    a = b;
    b = t;
    out[i] = (t >> 24) & 0xFF;
  }
}


// BLAKE2b self-test validation. Return 0 when OK.
int blake2b_selftest()
{
  // grand hash of hash results
  const uint8_t blake2b_res[32] = {
    0xC2, 0x3A, 0x78, 0x00, 0xD9, 0x81, 0x23, 0xBD,
    0x10, 0xF5, 0x06, 0xC6, 0x1E, 0x29, 0xDA, 0x56,
    0x03, 0xD7, 0x63, 0xB8, 0xBB, 0xAD, 0x2E, 0x73,
    0x7F, 0x5E, 0x76, 0x5A, 0x7B, 0xCC, 0xD4, 0x75
  };

  // parameter sets
  const size_t b2b_md_len[4] = { 20, 32, 48, 64 };
  const size_t b2b_in_len[6] = { 0, 3, 128, 129, 255, 1024 };

  size_t i, j, outlen, inlen;
  uint8_t in[1024], md[64], key[64];
  blake2b_ctx ctx;

  // 256-bit hash for testing
  if (blake2b_init(&ctx, 32, NULL, 0))
    return -1;

  for (i = 0; i < 4; i++) {
    outlen = b2b_md_len[i];
    for (j = 0; j < 6; j++) {
      inlen = b2b_in_len[j];

      selftest_seq(in, inlen, inlen);     // unkeyed hash
      blake2b(md, outlen, NULL, 0, in, inlen);
      blake2b_update(&ctx, md, outlen);   // hash the hash

      selftest_seq(key, outlen, outlen);  // keyed hash
      blake2b(md, outlen, key, outlen, in, inlen);
      blake2b_update(&ctx, md, outlen);   // hash the hash
    }
  }

  // compute and compare the hash of hashes
  blake2b_final(&ctx, md);
  for (i = 0; i < 32; i++) {
    if (md[i] != blake2b_res[i])
      return -1;
  }

  return 0;
}


//------------------------------------------------------------------
//------------------------------------------------------------------
static void self_test()
{
  printf("blake2b_selftest() = %s\n",
         blake2b_selftest() ? "FAIL" : "OK");
}



//------------------------------------------------------------------
//------------------------------------------------------------------
static void check_digest(uint8_t *digest, uint8_t *expected)
{
  uint8_t i;
  uint8_t errors = 0;

  for (i = 0 ; i < 64 ; i++)
    if (digest[i] != expected[i])
      errors += 1;

  if (errors == 0) {
    printf("Correct digest generated.\n");
  }

  else {
    printf("%d errors generated.\n", errors);
    printf("Expected:\n");
    for (i = 0; i < 64 ; i++) {
      if ((i > 0) && (i % 16 == 0))
        printf("\n");
      printf("0x%02x ", expected[i]);
    }
    printf("\n");

    printf("Generated:\n");
    for (i = 0; i < 64 ; i++) {
      if ((i > 0) && (i % 16 == 0))
        printf("\n");
      printf("0x%02x ", digest[i]);
    }
    printf("\n");
  }
}


//------------------------------------------------------------------
// rfc_test
// Test case from Appendix A in RFC7693.
//------------------------------------------------------------------
static void rfc_test()
{
  uint8_t expected[64] = {0xba, 0x80, 0xa5, 0x3f, 0x98, 0x1c, 0x4d, 0x0d,
                          0x6a, 0x27, 0x97, 0xb6, 0x9f, 0x12, 0xf6, 0xe9,
                          0x4c, 0x21, 0x2f, 0x14, 0x68, 0x5a, 0xc4, 0xb7,
                          0x4b, 0x12, 0xbb, 0x6f, 0xdb, 0xff, 0xa2, 0xd1,
                          0x7d, 0x87, 0xc5, 0x39, 0x2a, 0xab, 0x79, 0x2d,
                          0xc2, 0x52, 0xd5, 0xde, 0x45, 0x33, 0xcc, 0x95,
                          0x18, 0xd3, 0x8a, 0xa8, 0xdb, 0xf1, 0x92, 0x5a,
                          0xb9, 0x23, 0x86, 0xed, 0xd4, 0x00, 0x99, 0x23};

  uint8_t digest[64];
  uint8_t message[3] = "abc";

  printf("Running the blake2b-512 test case from Appendix A\n");
  blake2b(&digest[0], 64, 0, 0, &message[0], 3);
  check_digest(&digest[0], &expected[0]);
}


//------------------------------------------------------------------
// wiki_test
// Test case from Wikipedia.
// https://en.wikipedia.org/wiki/BLAKE_(hash_function)
//------------------------------------------------------------------
static void wiki_test()
{
  uint8_t expected[64] = {0xa8, 0xad, 0xd4, 0xbd, 0xdd, 0xfd, 0x93, 0xe4,
                          0x87, 0x7d, 0x27, 0x46, 0xe6, 0x28, 0x17, 0xb1,
                          0x16, 0x36, 0x4a, 0x1f, 0xa7, 0xbc, 0x14, 0x8d,
                          0x95, 0x09, 0x0b, 0xc7, 0x33, 0x3b, 0x36, 0x73,
                          0xf8, 0x24, 0x01, 0xcf, 0x7a, 0xa2, 0xe4, 0xcb,
                          0x1e, 0xcd, 0x90, 0x29, 0x6e, 0x3f, 0x14, 0xcb,
                          0x54, 0x13, 0xf8, 0xed, 0x77, 0xbe, 0x73, 0x04,
                          0x5b, 0x13, 0x91, 0x4c, 0xdc, 0xd6, 0xa9, 0x18};

  uint8_t digest[64];
  uint8_t message[43] = "The quick brown fox jumps over the lazy dog";

  printf("Running the blake2b-512 test case from Wikipedia.\n");
  blake2b(&digest[0], 64, 0, 0, &message[0], 43);
  check_digest(&digest[0], &expected[0]);
}


//------------------------------------------------------------------
//------------------------------------------------------------------
int main(void)
{
  //  self_test();
  rfc_test();
  //  wiki_test();

  return 0;
}

//======================================================================
// blake2b_test.c
//======================================================================
