//======================================================================
//
// blake2_m_select.v
// -----------
// Verilog 2001 implementation of the message word selection in the
// blake2 hash function core. Based on the given round we extract
// the indices for the four different sets of m words to select.
// The words are then selected and returned. This is basically a
// mux based implementation of the permutation table in combination
// with the actual word selection.
//
//
// Note that we use the state to signal which indices to select
// for a given round. This is because we don't do 8 G functions
// in a single cycle.
//
//
// Author: Joachim Strömbergson
// Copyright (c) 2014, Secworks Sweden AB
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

module blake2_m_select(
                       input wire [1023 : 0] m,
                       input wire [3 : 0]    r,
                       input wire            state,
                       output wire [63 : 0]  G0_m0,
                       output wire [63 : 0]  G0_m1,
                       output wire [63 : 0]  G1_m0,
                       output wire [63 : 0]  G1_m1,
                       output wire [63 : 0]  G2_m0,
                       output wire [63 : 0]  G2_m1,
                       output wire [63 : 0]  G3_m0,
                       output wire [63 : 0]  G3_m1
                      );


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------


  //----------------------------------------------------------------
  // Concurrent connectivity for ports.
  //----------------------------------------------------------------
  assign G0_m0 = 64'h0000000000000000;
  assign G0_m1 = 64'h0000000000000000;

  assign G1_m0 = 64'h0000000000000000;
  assign G1_m1 = 64'h0000000000000000;

  assign G2_m0 = 64'h0000000000000000;
  assign G2_m1 = 64'h0000000000000000;

  assign G3_m0 = 64'h0000000000000000;
  assign G3_m1 = 64'h0000000000000000;


  always @*
    begin : m_select

    end

endmodule // blake2_m_select

//======================================================================
// EOF blake2_m_select.v
//======================================================================
