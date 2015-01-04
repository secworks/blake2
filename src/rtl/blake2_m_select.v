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
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter R0_0 = 5'b00000;
  parameter R0_1 = 5'b00001;
  parameter R1_0 = 5'b00010;
  parameter R1_1 = 5'b00011;
  parameter R2_0 = 5'b00100;
  parameter R2_1 = 5'b00101;
  parameter R3_0 = 5'b00110;
  parameter R3_1 = 5'b00111;
  parameter R4_0 = 5'b01000;
  parameter R4_1 = 5'b01001;
  parameter R5_0 = 5'b01010;
  parameter R5_1 = 5'b01011;
  parameter R6_0 = 5'b01100;
  parameter R6_1 = 5'b01101;
  parameter R7_0 = 5'b01110;
  parameter R7_1 = 5'b01111;
  parameter R8_0 = 5'b10000;
  parameter R8_1 = 5'b10001;
  parameter R9_0 = 5'b10010;
  parameter R9_1 = 5'b10011;
  parameter RA_0 = 5'b10100;
  parameter RA_1 = 5'b10101;
  parameter RB_0 = 5'b10110;
  parameter RB_1 = 5'b10111;
  parameter RC_0 = 5'b11000;
  parameter RC_1 = 5'b11001;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [3 : 0] G0_m0_i;
  reg [3 : 0] G0_m1_i;
  reg [3 : 0] G1_m0_i;
  reg [3 : 0] G1_m1_i;
  reg [3 : 0] G2_m0_i;
  reg [3 : 0] G2_m1_i;
  reg [3 : 0] G3_m0_i;
  reg [3 : 0] G3_m1_i;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports.
  //----------------------------------------------------------------
  assign G0_m0 = m[G0_m0_i];
  assign G0_m1 = m[G0_m1_i];

  assign G1_m0 = m[G1_m0_i];
  assign G1_m1 = m[G1_m1_i];

  assign G2_m0 = m[G2_m0_i];
  assign G2_m1 = m[G2_m1_i];

  assign G3_m0 = m[G3_m0_i];
  assign G3_m1 = m[G3_m1_i];


  //----------------------------------------------------------------
  // get_indices
  //
  // Get the indices from the permutation table given the
  // round and the G function state.
  //----------------------------------------------------------------
  always @*
    begin : get_indices

      case ({r, state})
        R0_0:
          begin
            G0_m0_i = 0;
            G0_m1_i = 1;
            G1_m0_i = 2;
            G1_m1_i = 3;
            G2_m0_i = 4;
            G2_m1_i = 5;
            G3_m0_i = 6;
            G3_m1_i = 7;
          end

        R0_1:
          begin
            G0_m0_i = 8;
            G0_m1_i = 9;
            G1_m0_i = 10;
            G1_m1_i = 11;
            G2_m0_i = 12;
            G2_m1_i = 13;
            G3_m0_i = 14;
            G3_m1_i = 15;
          end

        R1_0:
          begin
            G0_m0_i = 14;
            G0_m1_i = 10;
            G1_m0_i = 4;
            G1_m1_i = 8;
            G2_m0_i = 9;
            G2_m1_i = 15;
            G3_m0_i = 13;
            G3_m1_i = 6;
          end

        R1_1:
          begin
            G0_m0_i = 1;
            G0_m1_i = 12;
            G1_m0_i = 0;
            G1_m1_i = 2;
            G2_m0_i = 11;
            G2_m1_i = 7;
            G3_m0_i = 5;
            G3_m1_i = 3;
          end

        R2_0:
          begin
          end

        R2_1:
          begin
          end

        R3_0:
          begin
          end

        R3_1:
          begin
          end

        R4_0:
          begin
          end

        R4_1:
          begin
          end

        R5_0:
          begin
          end

        R5_1:
          begin
          end

        R6_0:
          begin
          end

        R6_1:
          begin
          end

        R7_0:
          begin
          end

        R7_1:
          begin
          end

        R8_0:
          begin
          end

        R8_1:
          begin
          end

        R9_0:
          begin
          end

        R9_1:
          begin
          end

        RA_0:
          begin
          end

        RA_1:
          begin
          end

        RB_0:
          begin
          end

        RB_1:
          begin
          end

        RC_0:
          begin
          end

        RC_1:
          begin
          end

        default:
          begin
            G0_m0_i = 4'h00;
            G0_m1_i = 4'h00;
            G1_m0_i = 4'h00;
            G1_m1_i = 4'h00;
            G2_m0_i = 4'h00;
            G2_m1_i = 4'h00;
            G3_m0_i = 4'h00;
            G3_m1_i = 4'h00;
          end
      endcase // case ({r, state})

    end
endmodule // blake2_m_select

//======================================================================
// EOF blake2_m_select.v
//======================================================================
