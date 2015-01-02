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

                   input wire [63 : 0]   iv,
                   input wire [63 : 0]   ctr,
                   input wire [4 : 0]    rounds,

                   input wire [511 : 0]  data_in,

                   output wire           ready,

                   output wire [511 : 0] data_out,
                   output wire           data_out_valid
                  );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  // Datapath quartterround states names.
  parameter STATE_QR0 = 1'b0;
  parameter STATE_QR1 = 1'b1;

  parameter NUM_ROUNDS = 4'ha;

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
  reg [31 : 0] key0_reg;
  reg [31 : 0] key0_new;
  reg [31 : 0] key1_reg;
  reg [31 : 0] key1_new;
  reg [31 : 0] key2_reg;
  reg [31 : 0] key2_new;
  reg [31 : 0] key3_reg;
  reg [31 : 0] key3_new;
  reg [31 : 0] key4_reg;
  reg [31 : 0] key4_new;
  reg [31 : 0] key5_reg;
  reg [31 : 0] key5_new;
  reg [31 : 0] key6_reg;
  reg [31 : 0] key6_new;
  reg [31 : 0] key7_reg;
  reg [31 : 0] key7_new;

  reg keylen_reg;
  reg keylen_new;

  reg [31 : 0] iv0_reg;
  reg [31 : 0] iv0_new;
  reg [31 : 0] iv1_reg;
  reg [31 : 0] iv1_new;

  reg [31 : 0] state0_reg;
  reg [31 : 0] state0_new;
  reg [31 : 0] state1_reg;
  reg [31 : 0] state1_new;
  reg [31 : 0] state2_reg;
  reg [31 : 0] state2_new;
  reg [31 : 0] state3_reg;
  reg [31 : 0] state3_new;
  reg [31 : 0] state4_reg;
  reg [31 : 0] state4_new;
  reg [31 : 0] state5_reg;
  reg [31 : 0] state5_new;
  reg [31 : 0] state6_reg;
  reg [31 : 0] state6_new;
  reg [31 : 0] state7_reg;
  reg [31 : 0] state7_new;
  reg [31 : 0] state8_reg;
  reg [31 : 0] state8_new;
  reg [31 : 0] state9_reg;
  reg [31 : 0] state9_new;
  reg [31 : 0] state10_reg;
  reg [31 : 0] state10_new;
  reg [31 : 0] state11_reg;
  reg [31 : 0] state11_new;
  reg [31 : 0] state12_reg;
  reg [31 : 0] state12_new;
  reg [31 : 0] state13_reg;
  reg [31 : 0] state13_new;
  reg [31 : 0] state14_reg;
  reg [31 : 0] state14_new;
  reg [31 : 0] state15_reg;
  reg [31 : 0] state15_new;
  reg state_we;

  reg [31 : 0] v0_reg;
  reg [31 : 0] v0_new;
  reg          v0_we;

  reg [31 : 0] v1_reg;
  reg [31 : 0] v1_new;
  reg          v1_we;

  reg [31 : 0] v2_reg;
  reg [31 : 0] v2_new;
  reg          v2_we;

  reg [31 : 0] v3_reg;
  reg [31 : 0] v3_new;
  reg          v3_we;

  reg [31 : 0] v4_reg;
  reg [31 : 0] v4_new;
  reg          v4_we;

  reg [31 : 0] v5_reg;
  reg [31 : 0] v5_new;
  reg          v5_we;

  reg [31 : 0] v6_reg;
  reg [31 : 0] v6_new;
  reg          v6_we;

  reg [31 : 0] v7_reg;
  reg [31 : 0] v7_new;
  reg          v7_we;

  reg [31 : 0] v8_reg;
  reg [31 : 0] v8_new;
  reg          v8_we;

  reg [31 : 0] v9_reg;
  reg [31 : 0] v9_new;
  reg          v9_we;

  reg [31 : 0] v10_reg;
  reg [31 : 0] v10_new;
  reg          v10_we;

  reg [31 : 0] v11_reg;
  reg [31 : 0] v11_new;
  reg          v11_we;

  reg [31 : 0] v12_reg;
  reg [31 : 0] v12_new;
  reg          v12_we;

  reg [31 : 0] v13_reg;
  reg [31 : 0] v13_new;
  reg          v13_we;

  reg [31 : 0] v14_reg;
  reg [31 : 0] v14_new;
  reg          v14_we;

  reg [31 : 0] v15_reg;
  reg [31 : 0] v15_new;
  reg          v15_we;

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

  reg         qr_ctr_reg;
  reg         qr_ctr_new;
  reg         qr_ctr_we;
  reg         qr_ctr_inc;
  reg         qr_ctr_rst;

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

  reg [31 : 0]  qr0_a;
  reg [31 : 0]  qr0_b;
  reg [31 : 0]  qr0_c;
  reg [31 : 0]  qr0_d;
  wire [31 : 0] qr0_a_prim;
  wire [31 : 0] qr0_b_prim;
  wire [31 : 0] qr0_c_prim;
  wire [31 : 0] qr0_d_prim;

  reg [31 : 0]  qr1_a;
  reg [31 : 0]  qr1_b;
  reg [31 : 0]  qr1_c;
  reg [31 : 0]  qr1_d;
  wire [31 : 0] qr1_a_prim;
  wire [31 : 0] qr1_b_prim;
  wire [31 : 0] qr1_c_prim;
  wire [31 : 0] qr1_d_prim;

  reg [31 : 0]  qr2_a;
  reg [31 : 0]  qr2_b;
  reg [31 : 0]  qr2_c;
  reg [31 : 0]  qr2_d;
  wire [31 : 0] qr2_a_prim;
  wire [31 : 0] qr2_b_prim;
  wire [31 : 0] qr2_c_prim;
  wire [31 : 0] qr2_d_prim;

  reg [31 : 0]  qr3_a;
  reg [31 : 0]  qr3_b;
  reg [31 : 0]  qr3_c;
  reg [31 : 0]  qr3_d;
  wire [31 : 0] qr3_a_prim;
  wire [31 : 0] qr3_b_prim;
  wire [31 : 0] qr3_c_prim;
  wire [31 : 0] qr3_d_prim;


  //----------------------------------------------------------------
  // Instantiation of the compression modules.
  //----------------------------------------------------------------
  blake2_G G0(
              .a(qr0_a),
              .b(qr0_b),
              .c(qr0_c),
              .d(qr0_d),

              .a_prim(qr0_a_prim),
              .b_prim(qr0_b_prim),
              .c_prim(qr0_c_prim),
              .d_prim(qr0_d_prim)
             );


  blake2_G G1(
              .a(qr1_a),
              .b(qr1_b),
              .c(qr1_c),
              .d(qr1_d),

              .a_prim(qr1_a_prim),
              .b_prim(qr1_b_prim),
              .c_prim(qr1_c_prim),
              .d_prim(qr1_d_prim)
             );


  blake2_G G2(
              .a(qr2_a),
              .b(qr2_b),
              .c(qr2_c),
              .d(qr2_d),

              .a_prim(qr2_a_prim),
              .b_prim(qr2_b_prim),
              .c_prim(qr2_c_prim),
              .d_prim(qr2_d_prim)
             );


  blake2_G G3(
              .a(qr3_a),
              .b(qr3_b),
              .c(qr3_c),
              .d(qr3_d),

              .a_prim(qr3_a_prim),
              .b_prim(qr3_b_prim),
              .c_prim(qr3_c_prim),
              .d_prim(qr3_d_prim)
             );


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign data_out = data_out_reg;

  assign data_out_valid = data_out_valid_reg;

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
          key0_reg           <= 32'h00000000;
          key1_reg           <= 32'h00000000;
          key2_reg           <= 32'h00000000;
          key3_reg           <= 32'h00000000;
          key4_reg           <= 32'h00000000;
          key5_reg           <= 32'h00000000;
          key6_reg           <= 32'h00000000;
          key7_reg           <= 32'h00000000;
          iv0_reg            <= 32'h00000000;
          iv1_reg            <= 32'h00000000;
          state0_reg         <= 32'h00000000;
          state1_reg         <= 32'h00000000;
          state2_reg         <= 32'h00000000;
          state3_reg         <= 32'h00000000;
          state4_reg         <= 32'h00000000;
          state5_reg         <= 32'h00000000;
          state6_reg         <= 32'h00000000;
          state7_reg         <= 32'h00000000;
          state8_reg         <= 32'h00000000;
          state9_reg         <= 32'h00000000;
          state10_reg        <= 32'h00000000;
          state11_reg        <= 32'h00000000;
          state12_reg        <= 32'h00000000;
          state13_reg        <= 32'h00000000;
          state14_reg        <= 32'h00000000;
          state15_reg        <= 32'h00000000;
          v0_reg             <= 32'h00000000;
          v1_reg             <= 32'h00000000;
          v2_reg             <= 32'h00000000;
          v3_reg             <= 32'h00000000;
          v4_reg             <= 32'h00000000;
          v5_reg             <= 32'h00000000;
          v6_reg             <= 32'h00000000;
          v7_reg             <= 32'h00000000;
          v8_reg             <= 32'h00000000;
          v9_reg             <= 32'h00000000;
          v10_reg            <= 32'h00000000;
          v11_reg            <= 32'h00000000;
          v12_reg            <= 32'h00000000;
          v13_reg            <= 32'h00000000;
          v14_reg            <= 32'h00000000;
          v15_reg            <= 32'h00000000;
          data_in_reg        <= 512'h00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
          data_out_reg       <= 512'h00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
          rounds_reg         <= 4'h0;
          ready_reg          <= 1;
          data_out_valid_reg <= 0;
          qr_ctr_reg         <= STATE_QR0;
          dr_ctr_reg         <= 0;
          block0_ctr_reg     <= 32'h00000000;
          block1_ctr_reg     <= 32'h00000000;
          blake2_ctrl_reg    <= CTRL_IDLE;
        end
      else
        begin
          if (sample_params)
            begin
              key0_reg   <= key0_new;
              key1_reg   <= key1_new;
              key2_reg   <= key2_new;
              key3_reg   <= key3_new;
              key4_reg   <= key4_new;
              key5_reg   <= key5_new;
              key6_reg   <= key6_new;
              key7_reg   <= key7_new;
              iv0_reg    <= iv0_new;
              iv1_reg    <= iv1_new;
              rounds_reg <= rounds_new;
              keylen_reg <= keylen_new;
            end

          if (data_in_we)
            begin
              data_in_reg <= data_in;
            end

          if (state_we)
            begin
              state0_reg  <= state0_new;
              state1_reg  <= state1_new;
              state2_reg  <= state2_new;
              state3_reg  <= state3_new;
              state4_reg  <= state4_new;
              state5_reg  <= state5_new;
              state6_reg  <= state6_new;
              state7_reg  <= state7_new;
              state8_reg  <= state8_new;
              state9_reg  <= state9_new;
              state10_reg <= state10_new;
              state11_reg <= state11_new;
              state12_reg <= state12_new;
              state13_reg <= state13_new;
              state14_reg <= state14_new;
              state15_reg <= state15_new;
            end

          if (v0_we)
            begin
              v0_reg <= v0_new;
            end

          if (v1_we)
            begin
              v1_reg <= v1_new;
            end

          if (v2_we)
            begin
              v2_reg <= v2_new;
            end

          if (v3_we)
            begin
              v3_reg <= v3_new;
            end

          if (v4_we)
            begin
              v4_reg <= v4_new;
            end

          if (v5_we)
            begin
              v5_reg <= v5_new;
            end

          if (v6_we)
            begin
              v6_reg <= v6_new;
            end

          if (v7_we)
            begin
              v7_reg <= v7_new;
            end

          if (v8_we)
            begin
              v8_reg <= v8_new;
            end

          if (v9_we)
            begin
              v9_reg <= v9_new;
            end

          if (v10_we)
            begin
              v10_reg <= v10_new;
            end

          if (v11_we)
            begin
              v11_reg <= v11_new;
            end

          if (v12_we)
            begin
              v12_reg <= v12_new;
            end

          if (v13_we)
            begin
              v13_reg <= v13_new;
            end

          if (v14_we)
            begin
              v14_reg <= v14_new;
            end

          if (v15_we)
            begin
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

          if (qr_ctr_we)
            begin
              qr_ctr_reg <= qr_ctr_new;
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
  // state_logic
  // Logic to init and update the internal state.
  //----------------------------------------------------------------
  always @*
    begin : state_logic
      reg [31 : 0] new_state_word0;
      reg [31 : 0] new_state_word1;
      reg [31 : 0] new_state_word2;
      reg [31 : 0] new_state_word3;
      reg [31 : 0] new_state_word4;
      reg [31 : 0] new_state_word5;
      reg [31 : 0] new_state_word6;
      reg [31 : 0] new_state_word7;
      reg [31 : 0] new_state_word8;
      reg [31 : 0] new_state_word9;
      reg [31 : 0] new_state_word10;
      reg [31 : 0] new_state_word11;
      reg [31 : 0] new_state_word12;
      reg [31 : 0] new_state_word13;
      reg [31 : 0] new_state_word14;
      reg [31 : 0] new_state_word15;

      new_state_word0  = 32'h00000000;
      new_state_word1  = 32'h00000000;
      new_state_word2  = 32'h00000000;
      new_state_word3  = 32'h00000000;
      new_state_word4  = 32'h00000000;
      new_state_word5  = 32'h00000000;
      new_state_word6  = 32'h00000000;
      new_state_word7  = 32'h00000000;
      new_state_word8  = 32'h00000000;
      new_state_word9  = 32'h00000000;
      new_state_word10 = 32'h00000000;
      new_state_word11 = 32'h00000000;
      new_state_word12 = 32'h00000000;
      new_state_word13 = 32'h00000000;
      new_state_word14 = 32'h00000000;
      new_state_word15 = 32'h00000000;

      v0_new  = 32'h00000000;
      v1_new  = 32'h00000000;
      v2_new  = 32'h00000000;
      v3_new  = 32'h00000000;
      v4_new  = 32'h00000000;
      v5_new  = 32'h00000000;
      v6_new  = 32'h00000000;
      v7_new  = 32'h00000000;
      v8_new  = 32'h00000000;
      v9_new  = 32'h00000000;
      v10_new = 32'h00000000;
      v11_new = 32'h00000000;
      v12_new = 32'h00000000;
      v13_new = 32'h00000000;
      v14_new = 32'h00000000;
      v15_new = 32'h00000000;
      v0_we   = 0;
      v1_we   = 0;
      v2_we   = 0;
      v3_we   = 0;
      v4_we   = 0;
      v5_we   = 0;
      v6_we   = 0;
      v7_we   = 0;
      v8_we   = 0;
      v9_we   = 0;
      v10_we  = 0;
      v11_we  = 0;
      v12_we  = 0;
      v13_we  = 0;
      v14_we  = 0;
      v15_we  = 0;

      state0_new  = 32'h00000000;
      state1_new  = 32'h00000000;
      state2_new  = 32'h00000000;
      state3_new  = 32'h00000000;
      state4_new  = 32'h00000000;
      state5_new  = 32'h00000000;
      state6_new  = 32'h00000000;
      state7_new  = 32'h00000000;
      state8_new  = 32'h00000000;
      state9_new  = 32'h00000000;
      state10_new = 32'h00000000;
      state11_new = 32'h00000000;
      state12_new = 32'h00000000;
      state13_new = 32'h00000000;
      state14_new = 32'h00000000;
      state15_new = 32'h00000000;
      state_we = 0;

      if (init_state)
        begin
          new_state_word4  = key0_reg;
          new_state_word5  = key1_reg;
          new_state_word6  = key2_reg;
          new_state_word7  = key3_reg;

          new_state_word12 = block0_ctr_reg;
          new_state_word13 = block1_ctr_reg;

          new_state_word14 = iv0_reg;
          new_state_word15 = iv1_reg;

          if (keylen_reg)
            begin
              // 256 bit key.
              new_state_word0  = SIGMA0;
              new_state_word1  = SIGMA1;
              new_state_word2  = SIGMA2;
              new_state_word3  = SIGMA3;
              new_state_word8  = key4_reg;
              new_state_word9  = key5_reg;
              new_state_word10 = key6_reg;
              new_state_word11 = key7_reg;
            end
          else
            begin
              // 128 bit key.
              new_state_word0  = TAU0;
              new_state_word1  = TAU1;
              new_state_word2  = TAU2;
              new_state_word3  = TAU3;
              new_state_word8  = key0_reg;
              new_state_word9  = key1_reg;
              new_state_word10 = key2_reg;
              new_state_word11 = key3_reg;
            end

          v0_new  = new_state_word0;
          v1_new  = new_state_word1;
          v2_new  = new_state_word2;
          v3_new  = new_state_word3;
          v4_new  = new_state_word4;
          v5_new  = new_state_word5;
          v6_new  = new_state_word6;
          v7_new  = new_state_word7;
          v8_new  = new_state_word8;
          v9_new  = new_state_word9;
          v10_new = new_state_word10;
          v11_new = new_state_word11;
          v12_new = new_state_word12;
          v13_new = new_state_word13;
          v14_new = new_state_word14;
          v15_new = new_state_word15;
          v0_we  = 1;
          v1_we  = 1;
          v2_we  = 1;
          v3_we  = 1;
          v4_we  = 1;
          v5_we  = 1;
          v6_we  = 1;
          v7_we  = 1;
          v8_we  = 1;
          v9_we  = 1;
          v10_we = 1;
          v11_we = 1;
          v12_we = 1;
          v13_we = 1;
          v14_we = 1;
          v15_we = 1;

          state0_new  = new_state_word0;
          state1_new  = new_state_word1;
          state2_new  = new_state_word2;
          state3_new  = new_state_word3;
          state4_new  = new_state_word4;
          state5_new  = new_state_word5;
          state6_new  = new_state_word6;
          state7_new  = new_state_word7;
          state8_new  = new_state_word8;
          state9_new  = new_state_word9;
          state10_new = new_state_word10;
          state11_new = new_state_word11;
          state12_new = new_state_word12;
          state13_new = new_state_word13;
          state14_new = new_state_word14;
          state15_new = new_state_word15;
          state_we = 1;
        end // if (init_state)

      else if (update_state)
        begin
          case (qr_ctr_reg)
            STATE_QR0:
              begin
                v0_new  = qr0_a_prim;
                v4_new  = qr0_b_prim;
                v8_new  = qr0_c_prim;
                v12_new = qr0_d_prim;
                v0_we   = 1;
                v4_we   = 1;
                v8_we   = 1;
                v12_we  = 1;

                v1_new  = qr1_a_prim;
                v5_new  = qr1_b_prim;
                v9_new  = qr1_c_prim;
                v13_new = qr1_d_prim;
                v1_we   = 1;
                v5_we   = 1;
                v9_we   = 1;
                v13_we  = 1;

                v2_new  = qr2_a_prim;
                v6_new  = qr2_b_prim;
                v10_new = qr2_c_prim;
                v14_new = qr2_d_prim;
                v2_we   = 1;
                v6_we   = 1;
                v10_we  = 1;
                v14_we  = 1;

                v3_new  = qr3_a_prim;
                v7_new  = qr3_b_prim;
                v11_new = qr3_c_prim;
                v15_new = qr3_d_prim;
                v3_we   = 1;
                v7_we   = 1;
                v11_we  = 1;
                v15_we  = 1;
              end

            STATE_QR1:
              begin
                v0_new  = qr0_a_prim;
                v5_new  = qr0_b_prim;
                v10_new = qr0_c_prim;
                v15_new = qr0_d_prim;
                v0_we   = 1;
                v5_we   = 1;
                v10_we  = 1;
                v15_we  = 1;

                v1_new  = qr1_a_prim;
                v6_new  = qr1_b_prim;
                v11_new = qr1_c_prim;
                v12_new = qr1_d_prim;
                v1_we   = 1;
                v6_we   = 1;
                v11_we  = 1;
                v12_we  = 1;

                v2_new  = qr2_a_prim;
                v7_new  = qr2_b_prim;
                v8_new  = qr2_c_prim;
                v13_new = qr2_d_prim;
                v2_we   = 1;
                v7_we   = 1;
                v8_we   = 1;
                v13_we  = 1;

                v3_new  = qr3_a_prim;
                v4_new  = qr3_b_prim;
                v9_new  = qr3_c_prim;
                v14_new = qr3_d_prim;
                v3_we   = 1;
                v4_we   = 1;
                v9_we   = 1;
                v14_we  = 1;
              end
          endcase // case (quarterround_select)
        end // if (update_state)
    end // state_logic


  //----------------------------------------------------------------
  // quarterround_muv
  // Quarterround muves that selects operands for quarterrounds.
  //----------------------------------------------------------------
  always @*
    begin : quarterround_muv
      case (qr_ctr_reg)
          STATE_QR0:
            begin
              qr0_a = v0_reg;
              qr0_b = v4_reg;
              qr0_c = v8_reg;
              qr0_d = v12_reg;

              qr1_a = v1_reg;
              qr1_b = v5_reg;
              qr1_c = v9_reg;
              qr1_d = v13_reg;

              qr2_a = v2_reg;
              qr2_b = v6_reg;
              qr2_c = v10_reg;
              qr2_d = v14_reg;

              qr3_a = v3_reg;
              qr3_b = v7_reg;
              qr3_c = v11_reg;
              qr3_d = v15_reg;
            end

          STATE_QR1:
            begin
              qr0_a = v0_reg;
              qr0_b = v5_reg;
              qr0_c = v10_reg;
              qr0_d = v15_reg;

              qr1_a = v1_reg;
              qr1_b = v6_reg;
              qr1_c = v11_reg;
              qr1_d = v12_reg;

              qr2_a = v2_reg;
              qr2_b = v7_reg;
              qr2_c = v8_reg;
              qr2_d = v13_reg;

              qr3_a = v3_reg;
              qr3_b = v4_reg;
              qr3_c = v9_reg;
              qr3_d = v14_reg;
            end
      endcase // case (quarterround_select)
    end // quarterround_muv


  //----------------------------------------------------------------
  // qr_ctr
  // Update logic for the quarterround counter, a monotonically
  // increasing counter with reset.
  //----------------------------------------------------------------
  always @*
    begin : qr_ctr
      qr_ctr_new = 0;
      qr_ctr_we  = 0;

      if (qr_ctr_rst)
        begin
          qr_ctr_new = 0;
          qr_ctr_we  = 1;
        end

      if (qr_ctr_inc)
        begin
          qr_ctr_new = qr_ctr_reg + 1'b1;
          qr_ctr_we  = 1;
        end
    end // qr_ctr


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

      qr_ctr_inc         = 0;
      qr_ctr_rst         = 0;

      dr_ctr_inc         = 0;
      dr_ctr_rst         = 0;

      block_ctr_inc      = 0;
      block_ctr_rst      = 0;

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
            qr_ctr_rst      = 1;
            dr_ctr_rst      = 1;
            blake2_ctrl_new = CTRL_ROUNDS;
            blake2_ctrl_we  = 1;
          end


        CTRL_ROUNDS:
          begin
            update_state = 1;
            qr_ctr_inc   = 1;
            if (qr_ctr_reg == STATE_QR1)
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
