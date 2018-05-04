#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#=======================================================================
#
# blake2.py
# ---------
# Simple, pure Python model of the Blake2 (Blake2b) hash function.
# The model is used as a functional reference for the HW implementation.
#
# See Blake2 paper and RFC 7693 for blake2b definition.
# - https://blake2.net/blake2.pdf
# - https://tools.ietf.org/html/rfc7693
#
#
# Author: Joachim Strömbergson
# Copyright (c) 2018 Assured AB
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#=======================================================================

#-------------------------------------------------------------------
# Python module imports.
#-------------------------------------------------------------------
import sys


#-------------------------------------------------------------------
# Constants.
#-------------------------------------------------------------------
VERBOSE = False
UINT64 = 2**64


#-------------------------------------------------------------------
# Blake2b()
#-------------------------------------------------------------------
class Blake2b():
    NUM_ROUNDS = 12

    SIGMA = (( 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15),
             (14, 10,  4,  8,  9, 15, 13,  6,  1, 12,  0,  2, 11,  7,  5,  3),
             (11,  8, 12,  0,  5,  2, 15, 13, 10, 14,  3,  6,  7,  1,  9,  4),
             ( 7,  9,  3,  1, 13, 12, 11, 14,  2,  6,  5, 10,  4,  0, 15,  8),
             ( 9,  0,  5,  7,  2,  4, 10, 15, 14,  1, 11, 12,  6,  8,  3, 13),
             ( 2, 12,  6, 10,  0, 11,  8,  3,  4, 13,  7,  5, 15, 14,  1,  9),
             (12,  5,  1, 15, 14, 13,  4, 10,  0,  7,  6,  3,  9,  2,  8, 11),
             (13, 11,  7, 14, 12,  1,  3,  9,  5,  0, 15,  4,  8,  6,  2, 10),
             ( 6, 15, 14,  9, 11,  3,  0,  8, 12,  2, 13,  7,  1,  4, 10,  5),
             (10,  2,  8,  4,  7,  6,  1,  5, 15, 11,  9, 14,  3, 12, 13,  0),
             ( 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15),
             (14, 10,  4,  8,  9, 15, 13,  6,  1, 12,  0,  2, 11,  7,  5,  3))

    IV = (0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
          0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179)


    def __init__(self, verbose = 0):
        self.verbose = verbose
        self.m = [0] * 16
        self.h = [0] * 8
        self.v = [0] * 16
        self.t = [0] * 2


    def hash_message(m,  param_block = None):
        self.init(param_block)
        return self.get_digest(n)


    def init(self, param_block = None):
        for i in range(8):
            self.h[i] = self.IV[i]

    def next(self, block):
        pass


    def finalize(self, block, blocklen):
        pass


    def get_digest(self, n):
        return self.H


    def _F(self, m, final_block):
        self.m = m

        # Initialize the work vector v based on the current hash state.
        for i in range(8):
            self.v[i] = self.h[i]
            self.v[(i + 8)] = self.IV[i]

        self.v[12] = self.v[12] ^ self.t[0]
        self.v[13] = self.v[13] ^ self.t[1]

        if final_block:
            print("Is final block")
            self.v[14] = self.v[14] ^ (UINT64 - 1)

        # Process the m in NUM_ROUNDS, updating the work vector v.
        self._mix(self.NUM_ROUNDS)

        # Update the hash state with the result from the v processing.
        for i in range(8):
            self.h[i] = self.h[i] ^ self.v[i] ^ self.v[(i + 8)]


    def _mix(self, r):
        self._dump_m()
        print("State of v before cryptographic mixing:")
        self._dump_v()

        for i in range(r):
           (self.v[0], self.v[4], self.v[8], self.v[12]) =\
            self._G(self.v[0], self.v[4], self.v[8], self.v[12],
            self.m[self.SIGMA[i][0]], self.m[self.SIGMA[i][1]])

           (self.v[1], self.v[5], self.v[9], self.v[13]) =\
            self._G(self.v[1], self.v[5], self.v[9], self.v[13],
            self.m[self.SIGMA[i][2]], self.m[self.SIGMA[i][3]])

           (self.v[2], self.v[6], self.v[10], self.v[14]) =\
            self._G(self.v[2], self.v[6], self.v[10], self.v[14],
            self.m[self.SIGMA[i][4]], self.m[self.SIGMA[i][5]])

           (self.v[3], self.v[7], self.v[11], self.v[15]) =\
            self._G(self.v[3], self.v[7], self.v[11], self.v[15],
            self.m[self.SIGMA[i][6]], self.m[self.SIGMA[i][7]])


           (self.v[0], self.v[5], self.v[10], self.v[15]) =\
            self._G(self.v[0], self.v[5], self.v[10], self.v[15],
            self.m[self.SIGMA[i][8]], self.m[self.SIGMA[i][9]])

           (self.v[1], self.v[6], self.v[11], self.v[12]) =\
            self._G(self.v[1], self.v[6], self.v[11], self.v[12],
            self.m[self.SIGMA[i][10]], self.m[self.SIGMA[i][11]])

           (self.v[2], self.v[7], self.v[8], self.v[13]) =\
            self._G(self.v[2], self.v[7], self.v[8], self.v[13],
            self.m[self.SIGMA[i][12]], self.m[self.SIGMA[i][13]])

           (self.v[3], self.v[4], self.v[9], self.v[14]) =\
            self._G(self.v[3], self.v[4], self.v[9], self.v[14],
            self.m[self.SIGMA[i][14]], self.m[self.SIGMA[i][15]])

        print("State of v after cryptographic mixing:")
        self._dump_v()
        print()


    def _G(self, a, b, c, d, m0, m1):
        if VERBOSE:
            print("G Inputs:")
            print("a = 0x%016x, b = 0x%016x, c = 0x%016x, d = 0x%016x, m0 = 0x%016x, m1 = 0x%016x" %\
                      (a, b, c, d, m0, m1))

        self.a1 = (a + b + m0) % UINT64
        self.d1 = d ^ self.a1
        self.d2 = self._rotr(self.d1, 32)
        self.c1 = (c + self.d2) % UINT64
        self.b1 = b ^ self.c1
        self.b2 = self._rotr(self.b1, 24)
        self.a2 = (self.a1 + self.b2 + m1) % UINT64
        self.d3 = self.d2 ^ self.a2
        self.d4 = self._rotr(self.d3, 16)
        self.c2 = (self.c1 + self.d4) % UINT64
        self.b3 = self.b2 ^ self.c2
        self.b4 = self._rotr(self.b3, 63)

        if VERBOSE:
            print("a1 = 0x%016x, a2 = 0x%016x" % (self.a1, self.a2))
            print("b1 = 0x%016x, b2 = 0x%016x, b3 = 0x%016x, b4 = 0x%016x" %\
                      (self.b1, self.b2, self.b3, self.b4))
            print("c1 = 0x%016x, c2 = 0x%016x" % (self.c1, self.c2))
            print("d1 = 0x%016x, d2 = 0x%016x, d3 = 0x%016x, d4 = 0x%016x" %\
                      (self.d1, self.d2, self.d3, self.d4))

        return (self.a2, self.b4, self.c2, self.d4)


    def _rotr(self, x, n):
        return  (((x) >> (n)) ^ ((x) << (64 - (n)))) % UINT64


    def _print_state(self):
        print("")


    def _dump_v(self):
        print("v00 - 07: 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x" %\
                  (self.v[0], self.v[1], self.v[2], self.v[3], self.v[4], self.v[5], self.v[6], self.v[7]))
        print("v08 - 15: 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x" %\
                  (self.v[8], self.v[9], self.v[10], self.v[11], self.v[12], self.v[13], self.v[14], self.v[15]))


    def _dump_m(self):
        print("m00 - 07: 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x" %\
                  (self.m[0], self.m[1], self.m[2], self.m[3], self.m[4], self.m[5], self.m[6], self.m[7]))
        print("m08 - 15: 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x 0x%016x" %\
                  (self.m[8], self.m[9], self.m[10], self.m[11], self.m[12], self.m[13], self.m[14], self.m[15]))



#-------------------------------------------------------------------
# F_test
# Perform single block F function processing as specified in
# Appendix A of RFC 7539.
#-------------------------------------------------------------------
def F_test():
    my_m = [0x0000000000636261, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]
    my_blake2b = Blake2b()
    my_blake2b.init()
    my_blake2b._F(my_m, True)


#-------------------------------------------------------------------
#-------------------------------------------------------------------
def test_G(indata, expected):
    errors = 0

    my_blake2b = Blake2b()
    (a, b, c, d) = my_blake2b._G(indata[0], indata[1], indata[2],
                                 indata[3], indata[4], indata[5])
    if VERBOSE:
        print("Result from G: 0x%016x  0x%016x  0x%016x  0x%016x" % (a, b, c, d))

    if a != expected[0]:
        print("Error: Expected 0x%016x, got 0x%016x for a_prim" % (expected[0], a))
        errors += 1

    if a != expected[0]:
        print("Error: Expected 0x%016x, got 0x%016x for b_prim" % (expected[1], b))
        errors += 1

    if a != expected[0]:
        print("Error: Expected 0x%016x, got 0x%016x for c_prim" % (expected[2], c))
        errors += 1

    if a != expected[0]:
        print("Error: Expected 0x%016x, got 0x%016x for d_prim" % (expected[3], d))
        errors += 1

    if not errors:
        print("G test ok.")
    else:
        print("G test NOT ok. %d errors." % (errors))
    print("")


#-------------------------------------------------------------------
# G_tests()
# Testing of the G function with test vectors captured from the
# C reference model.
#-------------------------------------------------------------------
def G_tests():
    gtest1_in  = [0x6a09e667f2bdc948, 0x510e527fade682d1, 0x6a09e667f3bcc908,
                  0x510e527fade68251, 0x0000000000000000, 0x0000000000000000]
    gtest1_ref = [0xf0c9aa0de38b1b89, 0xbbdf863401fde49b,
                  0xe85eb23c42183d3d, 0x7111fd8b6445099d]
    test_G(gtest1_in, gtest1_ref)


    gtest2_in  = [0x6a09e667f2bd8948, 0x510e527fade682d1, 0x6a09e667f3bcc908,
                  0x510e527fade68251, 0x0706050403020100, 0x0f0e0d0c0b0a0908]
    gtest2_ref = [0xfce69820f2d7e54c, 0x51324affb424aa90,
                  0x032368569e359a63, 0x8ad8f2a6176861c7]
    test_G(gtest2_in, gtest2_ref)


    gtest3_in  = [0x107e94c998ced482, 0x28e4a60d02068f18, 0x7650e70ef0a7f8cd,
                  0x86570b736731f92d, 0x2f2e2d2c2b2a2928, 0x1f1e1d1c1b1a1918]
    gtest3_ref = [0xf082ab50dd1499b7, 0xf66d12f48baec79a,
                  0x13e5af4bbe2d9010, 0xfac6524cdebf33d2]
    test_G(gtest3_in, gtest3_ref)


#-------------------------------------------------------------------
# test_code()
#
# Small test routines used during development.
#-------------------------------------------------------------------
def test_code():
    G_tests()
    F_test()


#-------------------------------------------------------------------
# main()
#
# If executed tests the ChaCha class using known test vectors.
#-------------------------------------------------------------------
def main():
    print("Testing the Blake2b Python model")
    print("--------------------------------")
    test_code()



#-------------------------------------------------------------------
# __name__
# Python thingy which allows the file to be run standalone as
# well as parsed from within a Python interpreter.
#-------------------------------------------------------------------
if __name__=="__main__":
    # Run the main function.
    sys.exit(main())

#=======================================================================
# EOF blake2.py
#=======================================================================
