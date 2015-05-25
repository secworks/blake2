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
                       input wire            clk,
                       input wire            reset_n,

                       input wire            load,

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
  parameter R10_0 = 5'b10100;
  parameter R10_1 = 5'b10101;
  parameter R11_0 = 5'b10110;
  parameter R11_1 = 5'b10111;


  //----------------------------------------------------------------
  // regs.
  //----------------------------------------------------------------
  reg [63 : 0] m_mem [0 : 15];


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
  assign G0_m0 = m_mem[G0_m0_i];
  assign G0_m1 = m_mem[G0_m1_i];

  assign G1_m0 = m_mem[G1_m0_i];
  assign G1_m1 = m_mem[G1_m1_i];

  assign G2_m0 = m_mem[G2_m0_i];
  assign G2_m1 = m_mem[G2_m1_i];

  assign G3_m0 = m_mem[G3_m0_i];
  assign G3_m1 = m_mem[G3_m1_i];


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with asynchronous
  // active low reset. All registers have write enable.
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin : reg_update
      if (!reset_n)
        begin
          m_mem[00] <= 64'h0000000000000000;
          m_mem[01] <= 64'h0000000000000000;
          m_mem[02] <= 64'h0000000000000000;
          m_mem[03] <= 64'h0000000000000000;
          m_mem[04] <= 64'h0000000000000000;
          m_mem[05] <= 64'h0000000000000000;
          m_mem[06] <= 64'h0000000000000000;
          m_mem[07] <= 64'h0000000000000000;
          m_mem[08] <= 64'h0000000000000000;
          m_mem[09] <= 64'h0000000000000000;
          m_mem[10] <= 64'h0000000000000000;
          m_mem[11] <= 64'h0000000000000000;
          m_mem[12] <= 64'h0000000000000000;
          m_mem[13] <= 64'h0000000000000000;
          m_mem[14] <= 64'h0000000000000000;
          m_mem[15] <= 64'h0000000000000000;
        end
      else
        begin
          if (load)
            begin
              m_mem[15] <= {m[0007 : 0000], m[0015 : 0008], m[0023 : 0016], m[0031 : 0024], m[0039 : 0032], m[0047 : 0040], m[0055 : 0048], m[0063 : 0056]};
              m_mem[14] <= {m[0071 : 0064], m[0079 : 0072], m[0087 : 0080], m[0095 : 0088], m[0103 : 0096], m[0111 : 0104], m[0119 : 0112], m[0127 : 0120]};
              m_mem[13] <= {m[0135 : 0128], m[0143 : 0136], m[0151 : 0144], m[0159 : 0152], m[0167 : 0160], m[0175 : 0168], m[0183 : 0176], m[0191 : 0184]};
              m_mem[12] <= {m[0199 : 0192], m[0207 : 0200], m[0215 : 0208], m[0223 : 0216], m[0231 : 0224], m[0239 : 0232], m[0247 : 0240], m[0255 : 0248]};
              m_mem[11] <= {m[0263 : 0256], m[0271 : 0264], m[0279 : 0272], m[0287 : 0280], m[0295 : 0288], m[0303 : 0296], m[0311 : 0304], m[0319 : 0312]};
              m_mem[10] <= {m[0327 : 0320], m[0335 : 0328], m[0343 : 0336], m[0351 : 0344], m[0359 : 0352], m[0367 : 0360], m[0375 : 0368], m[0383 : 0376]};
              m_mem[09] <= {m[0391 : 0384], m[0399 : 0392], m[0407 : 0400], m[0415 : 0408], m[0423 : 0416], m[0431 : 0424], m[0439 : 0432], m[0447 : 0440]};
              m_mem[08] <= {m[0455 : 0448], m[0463 : 0456], m[0471 : 0464], m[0479 : 0472], m[0487 : 0480], m[0495 : 0488], m[0503 : 0496], m[0511 : 0504]};
              m_mem[07] <= {m[0519 : 0512], m[0527 : 0520], m[0535 : 0528], m[0543 : 0536], m[0551 : 0544], m[0559 : 0552], m[0567 : 0560], m[0575 : 0568]};
              m_mem[06] <= {m[0583 : 0576], m[0591 : 0584], m[0599 : 0592], m[0607 : 0600], m[0615 : 0608], m[0623 : 0616], m[0631 : 0624], m[0639 : 0632]};
              m_mem[05] <= {m[0647 : 0640], m[0655 : 0648], m[0663 : 0656], m[0671 : 0664], m[0679 : 0672], m[0687 : 0680], m[0695 : 0688], m[0703 : 0696]};
              m_mem[04] <= {m[0711 : 0704], m[0719 : 0712], m[0727 : 0720], m[0735 : 0728], m[0743 : 0736], m[0751 : 0744], m[0759 : 0752], m[0767 : 0760]};
              m_mem[03] <= {m[0775 : 0768], m[0783 : 0776], m[0791 : 0784], m[0799 : 0792], m[0807 : 0800], m[0815 : 0808], m[0823 : 0816], m[0831 : 0824]};
              m_mem[02] <= {m[0839 : 0832], m[0847 : 0840], m[0855 : 0848], m[0863 : 0856], m[0871 : 0864], m[0879 : 0872], m[0887 : 0880], m[0895 : 0888]};
              m_mem[01] <= {m[0903 : 0896], m[0911 : 0904], m[0919 : 0912], m[0927 : 0920], m[0935 : 0928], m[0943 : 0936], m[0951 : 0944], m[0959 : 0952]};
              m_mem[00] <= {m[0967 : 0960], m[0975 : 0968], m[0983 : 0976], m[0991 : 0984], m[0999 : 0992], m[1007 : 1000], m[1015 : 1008], m[1023 : 1016]};
            end
        end
    end // reg_update


  //----------------------------------------------------------------
  // get_indices
  //
  // Get the indices from the permutation table given the
  // round and the G function state.
  //----------------------------------------------------------------
  always @*
    begin : get_indices

      case ({r, state})
        R0_0, R10_0:
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

        R0_1, R10_1:
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

        R1_0, R11_0:
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

        R1_1, R11_1:
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
            G0_m0_i = 11;
            G0_m1_i = 8;
            G1_m0_i = 12;
            G1_m1_i = 0;
            G2_m0_i = 5;
            G2_m1_i = 2;
            G3_m0_i = 15;
            G3_m1_i = 13;
          end

        R2_1:
          begin
            G0_m0_i = 10;
            G0_m1_i = 14;
            G1_m0_i = 3;
            G1_m1_i = 6;
            G2_m0_i = 7;
            G2_m1_i = 1;
            G3_m0_i = 9;
            G3_m1_i = 4;
          end

        R3_0:
          begin
            G0_m0_i = 7;
            G0_m1_i = 9;
            G1_m0_i = 3;
            G1_m1_i = 1;
            G2_m0_i = 13;
            G2_m1_i = 12;
            G3_m0_i = 11;
            G3_m1_i = 14;
          end

        R3_1:
          begin
            G0_m0_i = 2;
            G0_m1_i = 6;
            G1_m0_i = 5;
            G1_m1_i = 10;
            G2_m0_i = 4;
            G2_m1_i = 0;
            G3_m0_i = 15;
            G3_m1_i = 8;
          end

        R4_0:
          begin
            G0_m0_i = 9;
            G0_m1_i = 0;
            G1_m0_i = 5;
            G1_m1_i = 7;
            G2_m0_i = 2;
            G2_m1_i = 4;
            G3_m0_i = 10;
            G3_m1_i = 15;
          end

        R4_1:
          begin
            G0_m0_i = 14;
            G0_m1_i = 1;
            G1_m0_i = 11;
            G1_m1_i = 12;
            G2_m0_i = 6;
            G2_m1_i = 8;
            G3_m0_i = 3;
            G3_m1_i = 13;
          end

        R5_0:
          begin
            G0_m0_i = 2;
            G0_m1_i = 12;
            G1_m0_i = 6;
            G1_m1_i = 10;
            G2_m0_i = 0;
            G2_m1_i = 11;
            G3_m0_i = 8;
            G3_m1_i = 3;
          end

        R5_1:
          begin
            G0_m0_i = 4;
            G0_m1_i = 13;
            G1_m0_i = 7;
            G1_m1_i = 5;
            G2_m0_i = 15;
            G2_m1_i = 14;
            G3_m0_i = 1;
            G3_m1_i = 9;
          end

        R6_0:
          begin
            G0_m0_i = 12;
            G0_m1_i = 5;
            G1_m0_i = 1;
            G1_m1_i = 15;
            G2_m0_i = 14;
            G2_m1_i = 13;
            G3_m0_i = 4;
            G3_m1_i = 10;
          end

        R6_1:
          begin
            G0_m0_i = 0;
            G0_m1_i = 7;
            G1_m0_i = 6;
            G1_m1_i = 3;
            G2_m0_i = 9;
            G2_m1_i = 2;
            G3_m0_i = 8;
            G3_m1_i = 11;
          end

        R7_0:
          begin
            G0_m0_i = 13;
            G0_m1_i = 11;
            G1_m0_i = 7;
            G1_m1_i = 14;
            G2_m0_i = 12;
            G2_m1_i = 1;
            G3_m0_i = 3;
            G3_m1_i = 9;
          end

        R7_1:
          begin
            G0_m0_i = 5;
            G0_m1_i = 0;
            G1_m0_i = 15;
            G1_m1_i = 4;
            G2_m0_i = 8;
            G2_m1_i = 6;
            G3_m0_i = 2;
            G3_m1_i = 10;
          end

        R8_0:
          begin
            G0_m0_i = 6;
            G0_m1_i = 15;
            G1_m0_i = 14;
            G1_m1_i = 9;
            G2_m0_i = 11;
            G2_m1_i = 3;
            G3_m0_i = 0;
            G3_m1_i = 8;
          end

        R8_1:
          begin
            G0_m0_i = 12;
            G0_m1_i = 2;
            G1_m0_i = 13;
            G1_m1_i = 7;
            G2_m0_i = 1;
            G2_m1_i = 4;
            G3_m0_i = 10;
            G3_m1_i = 5;
          end

        R9_0:
          begin
            G0_m0_i = 10;
            G0_m1_i = 2;
            G1_m0_i = 8;
            G1_m1_i = 4;
            G2_m0_i = 7;
            G2_m1_i = 6;
            G3_m0_i = 1;
            G3_m1_i = 5;
          end

        R9_1:
          begin
            G0_m0_i = 15;
            G0_m1_i = 11;
            G1_m0_i = 9;
            G1_m1_i = 14;
            G2_m0_i = 3;
            G2_m1_i = 12;
            G3_m0_i = 13;
            G3_m1_i = 0;
          end

        default:
          begin
            G0_m0_i = 4'h0;
            G0_m1_i = 4'h0;
            G1_m0_i = 4'h0;
            G1_m1_i = 4'h0;
            G2_m0_i = 4'h0;
            G2_m1_i = 4'h0;
            G3_m0_i = 4'h0;
            G3_m1_i = 4'h0;
          end
      endcase // case ({r, state})
    end

endmodule // blake2_m_select

//======================================================================
// EOF blake2_m_select.v
//======================================================================
