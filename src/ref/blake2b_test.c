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
static void rfc_test()
{
  printf("Running the test case from Appendix A\n");
}


//------------------------------------------------------------------
//------------------------------------------------------------------
int main(void)
{
  self_test();
  rfc_test();

  return 0;
}

//======================================================================
// blake2b_test.c
//======================================================================
