//======================================================================
//
// blake2_core.v
// --------------
// Verilog 2001 implementation of the hash function Blake2.
// This is the internal core with wide interfaces.
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

module blake2_core(
                   input wire            clk,
                   input wire            reset_n,

                   input wire            init,
                   input wire            next,

                   input wire [1023 : 0] block_in,

                   output wire           ready,

                   output wire [511 : 0] digest_out,
                   output wire           digest_out_valid
                  );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  // Datapath quartterround states names.
  parameter STATE_G0 = 1'b0;
  parameter STATE_G1 = 1'b1;

  parameter NUM_ROUNDS = 4'hc;

  parameter IV0 = 64'h6a09e667f3bcc908;
  parameter IV1 = 64'hbb67ae8584caa73b;
  parameter IV2 = 64'h3c6ef372fe94f82b;
  parameter IV3 = 64'ha54ff53a5f1d36f1;
  parameter IV4 = 64'h510e527fade682d1;
  parameter IV5 = 64'h9b05688c2b3e6c1f;
  parameter IV6 = 64'h9b05688c2b3e6c1f;
  parameter IV7 = 64'h5be0cd19137e2179;

  parameter CTRL_IDLE     = 3'h0;
  parameter CTRL_INIT     = 3'h1;
  parameter CTRL_ROUNDS   = 3'h2;
  parameter CTRL_FINALIZE = 3'h3;
  parameter CTRL_DONE     = 3'h4;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [63 : 0] h0_reg;
  reg [63 : 0] h0_new;
  reg [63 : 0] h1_reg;
  reg [63 : 0] h1_new;
  reg [63 : 0] h2_reg;
  reg [63 : 0] h2_new;
  reg [63 : 0] h3_reg;
  reg [63 : 0] h3_new;
  reg [63 : 0] h4_reg;
  reg [63 : 0] h4_new;
  reg [63 : 0] h5_reg;
  reg [63 : 0] h5_new;
  reg [63 : 0] h6_reg;
  reg [63 : 0] h6_new;
  reg [63 : 0] h7_reg;
  reg [63 : 0] h7_new;
  reg          update_chain_value;
  reg          h_we;

  reg [63 : 0] v0_reg;
  reg [63 : 0] v0_new;
  reg [63 : 0] v1_reg;
  reg [63 : 0] v1_new;
  reg [63 : 0] v2_reg;
  reg [63 : 0] v2_new;
  reg [63 : 0] v3_reg;
  reg [63 : 0] v3_new;
  reg [63 : 0] v4_reg;
  reg [63 : 0] v4_new;
  reg [63 : 0] v5_reg;
  reg [63 : 0] v5_new;
  reg [63 : 0] v6_reg;
  reg [63 : 0] v6_new;
  reg [63 : 0] v7_reg;
  reg [63 : 0] v7_new;
  reg [63 : 0] v8_reg;
  reg [63 : 0] v8_new;
  reg [63 : 0] v9_reg;
  reg [63 : 0] v9_new;
  reg [63 : 0] v10_reg;
  reg [63 : 0] v10_new;
  reg [63 : 0] v11_reg;
  reg [63 : 0] v11_new;
  reg [63 : 0] v12_reg;
  reg [63 : 0] v12_new;
  reg [63 : 0] v13_reg;
  reg [63 : 0] v13_new;
  reg [63 : 0] v14_reg;
  reg [63 : 0] v14_new;
  reg [63 : 0] v15_reg;
  reg [63 : 0] v15_new;
  reg          v_we;

  reg [63 : 0] t0_reg;
  reg [63 : 0] t0_new;
  reg          t0_we;

  reg [63 : 0] t1_reg;
  reg [63 : 0] t1_new;
  reg          t1_we;

  reg [63 : 0] f0_reg;
  reg [63 : 0] f0_new;
  reg          f0_we;

  reg [63 : 0] f1_reg;
  reg [63 : 0] f1_new;
  reg          f1_we;

  reg [3 : 0] rounds_reg;
  reg [3 : 0] rounds_new;

  reg [511 : 0] data_in_reg;
  reg           data_in_we;

  reg [511 : 0] data_out_reg;
  reg [511 : 0] data_out_new;
  reg           data_out_we;

  reg  data_out_valid_reg;
  reg  data_out_valid_new;
  reg  data_out_valid_we;

  reg  ready_reg;
  reg  ready_new;
  reg  ready_we;

  reg         G_ctr_reg;
  reg         G_ctr_new;
  reg         G_ctr_we;
  reg         G_ctr_inc;
  reg         G_ctr_rst;

  reg [3 : 0] dr_ctr_reg;
  reg [3 : 0] dr_ctr_new;
  reg         dr_ctr_we;
  reg         dr_ctr_inc;
  reg         dr_ctr_rst;

  reg [31 : 0] block0_ctr_reg;
  reg [31 : 0] block0_ctr_new;
  reg          block0_ctr_we;
  reg [31 : 0] block1_ctr_reg;
  reg [31 : 0] block1_ctr_new;
  reg          block1_ctr_we;
  reg          block_ctr_inc;
  reg          block_ctr_rst;

  reg [2 : 0] blake2_ctrl_reg;
  reg [2 : 0] blake2_ctrl_new;
  reg         blake2_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg sample_params;
  reg init_state;
  reg update_state;
  reg update_output;

  reg [63 : 0]  G0_a;
  reg [63 : 0]  G0_b;
  reg [63 : 0]  G0_c;
  reg [63 : 0]  G0_d;
  reg [63 : 0]  G0_m0;
  reg [63 : 0]  G0_m1;
  wire [63 : 0] G0_a_prim;
  wire [63 : 0] G0_b_prim;
  wire [63 : 0] G0_c_prim;
  wire [63 : 0] G0_d_prim;

  reg [63 : 0]  G1_a;
  reg [63 : 0]  G1_b;
  reg [63 : 0]  G1_c;
  reg [63 : 0]  G1_d;
  reg [63 : 0]  G1_m0;
  reg [63 : 0]  G1_m1;
  wire [63 : 0] G1_a_prim;
  wire [63 : 0] G1_b_prim;
  wire [63 : 0] G1_c_prim;
  wire [63 : 0] G1_d_prim;

  reg [63 : 0]  G2_a;
  reg [63 : 0]  G2_b;
  reg [63 : 0]  G2_c;
  reg [63 : 0]  G2_d;
  reg [63 : 0]  G2_m0;
  reg [63 : 0]  G2_m1;
  wire [63 : 0] G2_a_prim;
  wire [63 : 0] G2_b_prim;
  wire [63 : 0] G2_c_prim;
  wire [63 : 0] G2_d_prim;

  reg [63 : 0]  G3_a;
  reg [63 : 0]  G3_b;
  reg [63 : 0]  G3_c;
  reg [63 : 0]  G3_d;
  reg [63 : 0]  G3_m0;
  reg [63 : 0]  G3_m1;
  wire [63 : 0] G3_a_prim;
  wire [63 : 0] G3_b_prim;
  wire [63 : 0] G3_c_prim;
  wire [63 : 0] G3_d_prim;


  //----------------------------------------------------------------
  // Instantiation of the compression modules.
  //----------------------------------------------------------------
  blake2_G G0(
              .a(G0_a),
              .b(G0_b),
              .c(G0_c),
              .d(G0_d),
              .d(G0_m0),
              .d(G0_m1),

              .a_prim(G0_a_prim),
              .b_prim(G0_b_prim),
              .c_prim(G0_c_prim),
              .d_prim(G0_d_prim)
             );


  blake2_G G1(
              .a(G1_a),
              .b(G1_b),
              .c(G1_c),
              .d(G1_d),
              .d(G1_m0),
              .d(G1_m1),

              .a_prim(G1_a_prim),
              .b_prim(G1_b_prim),
              .c_prim(G1_c_prim),
              .d_prim(G1_d_prim)
             );


  blake2_G G2(
              .a(G2_a),
              .b(G2_b),
              .c(G2_c),
              .d(G2_d),
              .d(G2_m0),
              .d(G2_m1),

              .a_prim(G2_a_prim),
              .b_prim(G2_b_prim),
              .c_prim(G2_c_prim),
              .d_prim(G2_d_prim)
             );


  blake2_G G3(
              .a(G3_a),
              .b(G3_b),
              .c(G3_c),
              .d(G3_d),
              .d(G3_m0),
              .d(G3_m1),

              .a_prim(G3_a_prim),
              .b_prim(G3_b_prim),
              .c_prim(G3_c_prim),
              .d_prim(G3_d_prim)
             );


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign digest_out = {h0_reg, h1_reg, h2_reg, h3_reg,
                     h4_reg, h5_reg, h6_reg, h7_reg};

  assign digest_out_valid = digest_out_valid_reg;

  assign ready = ready_reg;



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
          t0_reg             <= 64'h0000000000000000;
          t1_reg             <= 64'h0000000000000000;
          f0_reg             <= 64'h0000000000000000;
          f1_reg             <= 64'h0000000000000000;
          h0_reg             <= 64'h0000000000000000;
          h1_reg             <= 64'h0000000000000000;
          h2_reg             <= 64'h0000000000000000;
          h3_reg             <= 64'h0000000000000000;
          h4_reg             <= 64'h0000000000000000;
          h5_reg             <= 64'h0000000000000000;
          h6_reg             <= 64'h0000000000000000;
          h7_reg             <= 64'h0000000000000000;
          v0_reg             <= 64'h0000000000000000;
          v1_reg             <= 64'h0000000000000000;
          v2_reg             <= 64'h0000000000000000;
          v3_reg             <= 64'h0000000000000000;
          v4_reg             <= 64'h0000000000000000;
          v5_reg             <= 64'h0000000000000000;
          v6_reg             <= 64'h0000000000000000;
          v7_reg             <= 64'h0000000000000000;
          v8_reg             <= 64'h0000000000000000;
          v9_reg             <= 64'h0000000000000000;
          v10_reg            <= 64'h0000000000000000;
          v11_reg            <= 64'h0000000000000000;
          v12_reg            <= 64'h0000000000000000;
          v13_reg            <= 64'h0000000000000000;
          v14_reg            <= 64'h0000000000000000;
          v15_reg            <= 64'h0000000000000000;
          data_in_reg        <= 512'h00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
          data_out_reg       <= 512'h00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
          rounds_reg         <= 4'h0;
          ready_reg          <= 1;
          data_out_valid_reg <= 0;
          G_ctr_reg          <= STATE_G0;
          dr_ctr_reg         <= 0;
          block0_ctr_reg     <= 32'h00000000;
          block1_ctr_reg     <= 32'h00000000;
          blake2_ctrl_reg    <= CTRL_IDLE;
        end
      else
        begin
          if (data_in_we)
            begin
              data_in_reg <= data_in;
            end

          if (h_we)
            begin
              h0_reg  <= h0_new;
              h1_reg  <= h1_new;
              h2_reg  <= h2_new;
              h3_reg  <= h3_new;
              h4_reg  <= h4_new;
              h5_reg  <= h5_new;
              h6_reg  <= h6_new;
              h7_reg  <= h7_new;
            end

          if (v_we)
            begin
              v0_reg  <= v0_new;
              v1_reg  <= v1_new;
              v2_reg  <= v2_new;
              v3_reg  <= v3_new;
              v4_reg  <= v4_new;
              v5_reg  <= v5_new;
              v6_reg  <= v6_new;
              v7_reg  <= v7_new;
              v8_reg  <= v8_new;
              v9_reg  <= v9_new;
              v10_reg <= v10_new;
              v11_reg <= v11_new;
              v12_reg <= v12_new;
              v13_reg <= v13_new;
              v14_reg <= v14_new;
              v15_reg <= v15_new;
            end

          if (data_out_we)
            begin
              data_out_reg <= data_out_new;
            end

          if (ready_we)
            begin
              ready_reg <= ready_new;
            end

          if (data_out_valid_we)
            begin
              data_out_valid_reg <= data_out_valid_new;
            end

          if (G_ctr_we)
            begin
              G_ctr_reg <= G_ctr_new;
            end

          if (dr_ctr_we)
            begin
              dr_ctr_reg <= dr_ctr_new;
            end

          if (block0_ctr_we)
            begin
              block0_ctr_reg <= block0_ctr_new;
            end

          if (block1_ctr_we)
            begin
              block1_ctr_reg <= block1_ctr_new;
            end

          if (blake2_ctrl_we)
            begin
              blake2_ctrl_reg <= blake2_ctrl_new;
            end
        end
    end // reg_update


  //----------------------------------------------------------------
  // data_out_logic
  // Final output logic that combines the result from procceing
  // with the input word. This adds a final layer of VOR gates.
  //
  // Note that we also remap all the words into LSB format.
  //----------------------------------------------------------------
  always @*
    begin : data_out_logic
      reg [31 : 0]  msb_block_state0;
      reg [31 : 0]  msb_block_state1;
      reg [31 : 0]  msb_block_state2;
      reg [31 : 0]  msb_block_state3;
      reg [31 : 0]  msb_block_state4;
      reg [31 : 0]  msb_block_state5;
      reg [31 : 0]  msb_block_state6;
      reg [31 : 0]  msb_block_state7;
      reg [31 : 0]  msb_block_state8;
      reg [31 : 0]  msb_block_state9;
      reg [31 : 0]  msb_block_state10;
      reg [31 : 0]  msb_block_state11;
      reg [31 : 0]  msb_block_state12;
      reg [31 : 0]  msb_block_state13;
      reg [31 : 0]  msb_block_state14;
      reg [31 : 0]  msb_block_state15;

      reg [31 : 0]  lsb_block_state0;
      reg [31 : 0]  lsb_block_state1;
      reg [31 : 0]  lsb_block_state2;
      reg [31 : 0]  lsb_block_state3;
      reg [31 : 0]  lsb_block_state4;
      reg [31 : 0]  lsb_block_state5;
      reg [31 : 0]  lsb_block_state6;
      reg [31 : 0]  lsb_block_state7;
      reg [31 : 0]  lsb_block_state8;
      reg [31 : 0]  lsb_block_state9;
      reg [31 : 0]  lsb_block_state10;
      reg [31 : 0]  lsb_block_state11;
      reg [31 : 0]  lsb_block_state12;
      reg [31 : 0]  lsb_block_state13;
      reg [31 : 0]  lsb_block_state14;
      reg [31 : 0]  lsb_block_state15;

      reg [511 : 0] lsb_block_state;

      lsb_block_state = 512'h00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;

      data_out_new = 512'h00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
      data_out_we = 0;

      if (update_output)
        begin
          msb_block_state0  = state0_reg  + v0_reg;
          msb_block_state1  = state1_reg  + v1_reg;
          msb_block_state2  = state2_reg  + v2_reg;
          msb_block_state3  = state3_reg  + v3_reg;
          msb_block_state4  = state4_reg  + v4_reg;
          msb_block_state5  = state5_reg  + v5_reg;
          msb_block_state6  = state6_reg  + v6_reg;
          msb_block_state7  = state7_reg  + v7_reg;
          msb_block_state8  = state8_reg  + v8_reg;
          msb_block_state9  = state9_reg  + v9_reg;
          msb_block_state10 = state10_reg + v10_reg;
          msb_block_state11 = state11_reg + v11_reg;
          msb_block_state12 = state12_reg + v12_reg;
          msb_block_state13 = state13_reg + v13_reg;
          msb_block_state14 = state14_reg + v14_reg;
          msb_block_state15 = state15_reg + v15_reg;

          lsb_block_state0 = {msb_block_state0[7  :  0],
                              msb_block_state0[15 :  8],
                              msb_block_state0[23 : 16],
                              msb_block_state0[31 : 24]};

          lsb_block_state1 = {msb_block_state1[7  :  0],
                              msb_block_state1[15 :  8],
                              msb_block_state1[23 : 16],
                              msb_block_state1[31 : 24]};

          lsb_block_state2 = {msb_block_state2[7  :  0],
                              msb_block_state2[15 :  8],
                              msb_block_state2[23 : 16],
                              msb_block_state2[31 : 24]};

          lsb_block_state3 = {msb_block_state3[7  :  0],
                              msb_block_state3[15 :  8],
                              msb_block_state3[23 : 16],
                              msb_block_state3[31 : 24]};

          lsb_block_state4 = {msb_block_state4[7  :  0],
                              msb_block_state4[15 :  8],
                              msb_block_state4[23 : 16],
                              msb_block_state4[31 : 24]};

          lsb_block_state5 = {msb_block_state5[7  :  0],
                              msb_block_state5[15 :  8],
                              msb_block_state5[23 : 16],
                              msb_block_state5[31 : 24]};

          lsb_block_state6 = {msb_block_state6[7  :  0],
                              msb_block_state6[15 :  8],
                              msb_block_state6[23 : 16],
                              msb_block_state6[31 : 24]};

          lsb_block_state7 = {msb_block_state7[7  :  0],
                              msb_block_state7[15 :  8],
                              msb_block_state7[23 : 16],
                              msb_block_state7[31 : 24]};

          lsb_block_state8 = {msb_block_state8[7  :  0],
                              msb_block_state8[15 :  8],
                              msb_block_state8[23 : 16],
                              msb_block_state8[31 : 24]};

          lsb_block_state9 = {msb_block_state9[7  :  0],
                              msb_block_state9[15 :  8],
                              msb_block_state9[23 : 16],
                              msb_block_state9[31 : 24]};

          lsb_block_state10 = {msb_block_state10[7  :  0],
                               msb_block_state10[15 :  8],
                               msb_block_state10[23 : 16],
                               msb_block_state10[31 : 24]};

          lsb_block_state11 = {msb_block_state11[7  :  0],
                               msb_block_state11[15 :  8],
                               msb_block_state11[23 : 16],
                               msb_block_state11[31 : 24]};

          lsb_block_state12 = {msb_block_state12[7  :  0],
                               msb_block_state12[15 :  8],
                               msb_block_state12[23 : 16],
                               msb_block_state12[31 : 24]};

          lsb_block_state13 = {msb_block_state13[7  :  0],
                               msb_block_state13[15 :  8],
                               msb_block_state13[23 : 16],
                               msb_block_state13[31 : 24]};

          lsb_block_state14 = {msb_block_state14[7  :  0],
                               msb_block_state14[15 :  8],
                               msb_block_state14[23 : 16],
                               msb_block_state14[31 : 24]};

          lsb_block_state15 = {msb_block_state15[7  :  0],
                               msb_block_state15[15 :  8],
                               msb_block_state15[23 : 16],
                               msb_block_state15[31 : 24]};

          lsb_block_state = {lsb_block_state0,  lsb_block_state1,
                             lsb_block_state2,  lsb_block_state3,
                             lsb_block_state4,  lsb_block_state5,
                             lsb_block_state6,  lsb_block_state7,
                             lsb_block_state8,  lsb_block_state9,
                             lsb_block_state10, lsb_block_state11,
                             lsb_block_state12, lsb_block_state13,
                             lsb_block_state14, lsb_block_state15};

          data_out_new = data_in_reg ^ lsb_block_state;
          data_out_we   = 1;
        end // if (update_output)
    end // data_out_logic


  //----------------------------------------------------------------
  // sample_parameters
  // Logic (wires) that convert parameter input to appropriate
  // format for processing.
  //----------------------------------------------------------------
  always @*
    begin : sample_parameters
      key0_new   = 32'h00000000;
      key1_new   = 32'h00000000;
      key2_new   = 32'h00000000;
      key3_new   = 32'h00000000;
      key4_new   = 32'h00000000;
      key5_new   = 32'h00000000;
      key6_new   = 32'h00000000;
      key7_new   = 32'h00000000;
      iv0_new    = 32'h00000000;
      iv1_new    = 32'h00000000;
      rounds_new = 4'h0;
      keylen_new = 1'b0;

      if (sample_params)
        begin
          key0_new = {key[231 : 224], key[239 : 232],
                      key[247 : 240], key[255 : 248]};
          key1_new = {key[199 : 192], key[207 : 200],
                      key[215 : 208], key[223 : 216]};
          key2_new = {key[167 : 160], key[175 : 168],
                      key[183 : 176], key[191 : 184]};
          key3_new = {key[135 : 128], key[143 : 136],
                      key[151 : 144], key[159 : 152]};
          key4_new = {key[103 :  96], key[111 : 104],
                      key[119 : 112], key[127 : 120]};
          key5_new = {key[71  :  64], key[79  :  72],
                      key[87  :  80], key[95  :  88]};
          key6_new = {key[39  :  32], key[47  :  40],
                      key[55  :  48], key[63  :  56]};
          key7_new = {key[7   :   0], key[15  :   8],
                      key[23  :  16], key[31  :  24]};

          iv0_new = {iv[39  :  32], iv[47  :  40],
                     iv[55  :  48], iv[63  :  56]};
          iv1_new = {iv[7   :   0], iv[15  :   8],
                     iv[23  :  16], iv[31  :  24]};

          // Div by two since we count double rounds.
          rounds_new = rounds[4 : 1];

          keylen_new = keylen;
        end
    end

  //----------------------------------------------------------------
  // chain_logic
  //
  // Logic for updating the chain registers.
  //----------------------------------------------------------------
  always @*
    begin : chain_logic
      h0_new = 64'h0000000000000000;
      h1_new = 64'h0000000000000000;
      h2_new = 64'h0000000000000000;
      h3_new = 64'h0000000000000000;
      h4_new = 64'h0000000000000000;
      h5_new = 64'h0000000000000000;
      h6_new = 64'h0000000000000000;
      h7_new = 64'h0000000000000000;
      h_we   = 0;

      if (update_chain_value)
        begin
          h0_new = h0_reg ^ v0_reg ^ v8_reg;
          h1_new = h1_reg ^ v1_reg ^ v9_reg;
          h2_new = h2_reg ^ v2_reg ^ v10_reg;
          h3_new = h3_reg ^ v3_reg ^ v11_reg;
          h4_new = h4_reg ^ v4_reg ^ v12_reg;
          h5_new = h5_reg ^ v5_reg ^ v13_reg;
          h6_new = h6_reg ^ v6_reg ^ v14_reg;
          h7_new = h7_reg ^ v7_reg ^ v15_reg;
          h_we   = 1;
        end
    end // chain_logic


  //----------------------------------------------------------------
  // state_logic
  //
  // Logic to init and update the internal state.
  //----------------------------------------------------------------
  always @*
    begin : state_logic
      v0_new  = 64'h0000000000000000;
      v1_new  = 64'h0000000000000000;
      v2_new  = 64'h0000000000000000;
      v3_new  = 64'h0000000000000000;
      v4_new  = 64'h0000000000000000;
      v5_new  = 64'h0000000000000000;
      v6_new  = 64'h0000000000000000;
      v7_new  = 64'h0000000000000000;
      v8_new  = 64'h0000000000000000;
      v9_new  = 64'h0000000000000000;
      v10_new = 64'h0000000000000000;
      v11_new = 64'h0000000000000000;
      v12_new = 64'h0000000000000000;
      v13_new = 64'h0000000000000000;
      v14_new = 64'h0000000000000000;
      v15_new = 64'h0000000000000000;
      v_we    = 0;

      if (init_state)
        begin
          v0_new  = h0_reg;
          v1_new  = h1_reg;
          v2_new  = h2_reg;
          v3_new  = h3_reg;
          v4_new  = h4_reg;
          v5_new  = h5_reg;
          v6_new  = h6_reg;
          v7_new  = h7_reg;
          v8_new  = IV0;
          v9_new  = IV1;
          v10_new = IV2;
          v11_new = IV3;
          v12_new = t0_reg ^ IV4;
          v13_new = t1_reg ^ IV5;
          v14_new = f0_reg ^ IV6;
          v15_new = f1_reg ^ IV7;
          v_we    = 1;
        end

      if (update_state)
        begin
          case (G_ctr_reg)
            // Column updates.
            STATE_G0:
              begin
                G0_a    = v0_reg;
                G0_b    = v4_reg;
                G0_c    = v8_reg;
                G0_d    = v12_reg;
                v0_new  = G0_a_prim;
                v4_new  = G0_b_prim;
                v8_new  = G0_c_prim;
                v12_new = G0_d_prim;

                G1_a    = v1_reg;
                G1_b    = v5_reg;
                G1_c    = v9_reg;
                G1_d    = v13_reg;
                v1_new  = G1_a_prim;
                v5_new  = G1_b_prim;
                v9_new  = G1_c_prim;
                v13_new = G1_d_prim;

                G2_a    = v2_reg;
                G2_b    = v6_reg;
                G2_c    = v10_reg;
                G2_d    = v14_reg;
                v2_new  = G2_a_prim;
                v6_new  = G2_b_prim;
                v10_new = G2_c_prim;
                v14_new = G2_d_prim;

                G3_a    = v3_reg;
                G3_b    = v7_reg;
                G3_c    = v11_reg;
                G3_d    = v15_reg;
                v3_new  = G3_a_prim;
                v7_new  = G3_b_prim;
                v11_new = G3_c_prim;
                v15_new = G3_d_prim;

                v_we    = 1;
              end

            // Diagonal updates.
            STATE_G1:
              begin
                G0_a    = v0_reg;
                G0_b    = v5_reg;
                G0_c    = v10_reg;
                G0_d    = v15_reg;
                v0_new  = G0_a_prim;
                v5_new  = G0_b_prim;
                v10_new = G0_c_prim;
                v15_new = G0_d_prim;

                G1_a    = v1_reg;
                G1_b    = v6_reg;
                G1_c    = v11_reg;
                G1_d    = v12_reg;
                v1_new  = G1_a_prim;
                v6_new  = G1_b_prim;
                v11_new = G1_c_prim;
                v12_new = G1_d_prim;

                G2_a    = v2_reg;
                G2_b    = v7_reg;
                G2_c    = v8_reg;
                G2_d    = v13_reg;
                v2_new  = G2_a_prim;
                v7_new  = G2_b_prim;
                v8_new  = G2_c_prim;
                v13_new = G2_d_prim;

                G3_a    = v3_reg;
                G3_b    = v4_reg;
                G3_c    = v9_reg;
                G3_d    = v14_reg;
                v3_new  = G3_a_prim;
                v4_new  = G3_b_prim;
                v9_new  = G3_c_prim;
                v14_new = G3_d_prim;

                v_we    = 1;
              end
          endcase // case (G_ctr_reg)
        end // if (update_state)
    end // state_logic


  //----------------------------------------------------------------
  // G_ctr
  // Update logic for the G function counter. Basically a one bit
  // counter that selects if we column of diaginal updates.
  // increasing counter with reset.
  //----------------------------------------------------------------
  always @*
    begin : G_ctr
      G_ctr_new = 0;
      G_ctr_we  = 0;

      if (G_ctr_rst)
        begin
          G_ctr_new = 0;
          G_ctr_we  = 1;
        end

      if (G_ctr_inc)
        begin
          G_ctr_new = G_ctr_reg + 1'b1;
          G_ctr_we  = 1;
        end
    end // G_ctr


  //----------------------------------------------------------------
  // dr_ctr
  // Update logic for the round counter, a monotonically
  // increasing counter with reset.
  //----------------------------------------------------------------
  always @*
    begin : dr_ctr
      dr_ctr_new = 0;
      dr_ctr_we  = 0;

      if (dr_ctr_rst)
        begin
          dr_ctr_new = 0;
          dr_ctr_we  = 1;
        end

      if (dr_ctr_inc)
        begin
          dr_ctr_new = dr_ctr_reg + 1'b1;
          dr_ctr_we  = 1;
        end
    end // dr_ctr


  //----------------------------------------------------------------
  // block_ctr
  // Update logic for the 64-bit block counter, a monotonically
  // increasing counter with reset.
  //----------------------------------------------------------------
  always @*
    begin : block_ctr
      // Defult assignments
      block0_ctr_new = 32'h00000000;
      block1_ctr_new = 32'h00000000;
      block0_ctr_we = 0;
      block1_ctr_we = 0;

      if (block_ctr_rst)
        begin
          block0_ctr_new = ctr[31 : 00];
          block1_ctr_new = ctr[63 : 32];
          block0_ctr_we = 1;
          block1_ctr_we = 1;
        end

      if (block_ctr_inc)
        begin
          block0_ctr_new = block0_ctr_reg + 1;
          block0_ctr_we = 1;

          // Avoid chaining the 32-bit adders.
          if (block0_ctr_reg == 32'hffffffff)
            begin
              block1_ctr_new = block1_ctr_reg + 1;
              block1_ctr_we = 1;
            end
        end
    end // block_ctr


  //----------------------------------------------------------------
  // blake2_ctrl_fsm
  // Logic for the state machine controlling the core behaviour.
  //----------------------------------------------------------------
  always @*
    begin : blake2_ctrl_fsm
      init_state         = 0;
      update_state       = 0;
      sample_params      = 0;
      update_output      = 0;

      G_ctr_inc         = 0;
      G_ctr_rst         = 0;

      dr_ctr_inc         = 0;
      dr_ctr_rst         = 0;

      block_ctr_inc      = 0;
      block_ctr_rst      = 0;

      update_chain_value = 0;

      data_in_we         = 0;

      ready_new          = 0;
      ready_we           = 0;

      data_out_valid_new = 0;
      data_out_valid_we  = 0;

      blake2_ctrl_new    = CTRL_IDLE;
      blake2_ctrl_we     = 0;


      case (blake2_ctrl_reg)
        CTRL_IDLE:
          begin
            if (init)
              begin
                ready_new       = 0;
                ready_we        = 1;
                data_in_we      = 1;
                sample_params   = 1;
                block_ctr_rst   = 1;
                blake2_ctrl_new = CTRL_INIT;
                blake2_ctrl_we  = 1;
              end
          end


        CTRL_INIT:
          begin
            init_state      = 1;
            G_ctr_rst      = 1;
            dr_ctr_rst      = 1;
            blake2_ctrl_new = CTRL_ROUNDS;
            blake2_ctrl_we  = 1;
          end


        CTRL_ROUNDS:
          begin
            update_state = 1;
            G_ctr_inc   = 1;
            if (G_ctr_reg == STATE_G1)
              begin
                dr_ctr_inc = 1;
                if (dr_ctr_reg == (rounds_reg - 1))
                  begin
                    blake2_ctrl_new = CTRL_FINALIZE;
                    blake2_ctrl_we  = 1;
                  end
              end
          end


        CTRL_FINALIZE:
          begin
            update_chain_value = 1;
            ready_new          = 1;
            ready_we           = 1;
            update_output      = 1;
            data_out_valid_new = 1;
            data_out_valid_we  = 1;
            blake2_ctrl_new    = CTRL_DONE;
            blake2_ctrl_we     = 1;
          end


        CTRL_DONE:
          begin
            if (init)
              begin
                ready_new          = 0;
                ready_we           = 1;
                data_out_valid_new = 0;
                data_out_valid_we  = 1;
                data_in_we         = 1;
                sample_params      = 1;
                block_ctr_rst      = 1;
                blake2_ctrl_new    = CTRL_INIT;
                blake2_ctrl_we     = 1;
              end
            else if (next)
              begin
                ready_new          = 0;
                ready_we           = 1;
                data_out_valid_new = 0;
                data_out_valid_we  = 1;
                data_in_we         = 1;
                block_ctr_inc      = 1;
                blake2_ctrl_new    = CTRL_INIT;
                blake2_ctrl_we     = 1;
              end
          end


        default:
          begin

          end
      endcase // case (blake2_ctrl_reg)
    end // blake2_ctrl_fsm
endmodule // blake2_core

//======================================================================
// EOF blake2_core.v
//======================================================================
