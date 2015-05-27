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

`include "blake2_G.v"
`include "blake2_m_select.v"

module blake2_core(
                   input wire            clk,
                   input wire            reset_n,

                   input wire            init,
                   input wire            next,
                   input wire            final_block,

                   input wire [1023 : 0] block,
                   input wire [127 : 0]  data_length,

                   output wire           ready,

                   output wire [511 : 0] digest,
                   output wire           digest_valid
                  );


  //----------------------------------------------------------------
  // Configuration parameters.
  //----------------------------------------------------------------
  // Default number of rounds
  parameter NUM_ROUNDS = 4'hc;

  //----------------------------------------------------------------
  // Parameter block.
  //----------------------------------------------------------------
  // The digest length in bytes. Minimum: 1, Maximum: 64
  parameter [7:0] DIGEST_LENGTH = 8'd64;

  // The key length in bytes. Minimum: 0 (for no key used), Maximum: 64
  parameter [7:0] KEY_LENGTH = 8'd0;

  // Fanout
  parameter [7:0] FANOUT = 8'h01;

  // Depth (maximal)
  parameter [7:0] DEPTH = 8'h01;

  // 4-byte leaf length
  parameter [31:0] LEAF_LENGTH = 32'h00000000;

  // 8-byte node offset
  parameter [64:0] NODE_OFFSET = 64'h0000000000000000;

  // Node Depth
  parameter [7:0] NODE_DEPTH = 8'h00;

  // Inner hash length
  parameter [7:0] INNER_LENGTH = 8'h00;

  // Reserved for future use (14 bytes)
  parameter [111:0] RESERVED = 112'h0000000000000000000000000000;

  // 16-byte salt, little-endian byte order
  parameter [127:0] SALT = 128'h00000000000000000000000000000000;

  // 16-byte personalization, little-endian byte order
  parameter [127:0] PERSONALIZATION = 128'h00000000000000000000000000000000;

  wire [511:0] parameter_block = {PERSONALIZATION, SALT, RESERVED, INNER_LENGTH,
                                  NODE_DEPTH, NODE_OFFSET, LEAF_LENGTH, DEPTH,
                                  FANOUT, KEY_LENGTH, DIGEST_LENGTH};

  //----------------------------------------------------------------
  // Internal constant definitions.
  //----------------------------------------------------------------
  // Datapath quartterround states names.
  localparam STATE_G0 = 1'b0;
  localparam STATE_G1 = 1'b1;

  localparam IV0 = 64'h6a09e667f3bcc908;
  localparam IV1 = 64'hbb67ae8584caa73b;
  localparam IV2 = 64'h3c6ef372fe94f82b;
  localparam IV3 = 64'ha54ff53a5f1d36f1;
  localparam IV4 = 64'h510e527fade682d1;
  localparam IV5 = 64'h9b05688c2b3e6c1f;
  localparam IV6 = 64'h1f83d9abfb41bd6b;
  localparam IV7 = 64'h5be0cd19137e2179;

  localparam CTRL_IDLE     = 3'h0;
  localparam CTRL_INIT     = 3'h1;
  localparam CTRL_ROUNDS   = 3'h2;
  localparam CTRL_FINALIZE = 3'h3;
  localparam CTRL_DONE     = 3'h4;


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

  reg  digest_valid_reg;
  reg  digest_valid_new;
  reg  digest_valid_we;

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

  reg load_m;

  reg [63 : 0]  G0_a;
  reg [63 : 0]  G0_b;
  reg [63 : 0]  G0_c;
  reg [63 : 0]  G0_d;
  wire [63 : 0] G0_m0;
  wire [63 : 0] G0_m1;
  wire [63 : 0] G0_a_prim;
  wire [63 : 0] G0_b_prim;
  wire [63 : 0] G0_c_prim;
  wire [63 : 0] G0_d_prim;

  reg [63 : 0]  G1_a;
  reg [63 : 0]  G1_b;
  reg [63 : 0]  G1_c;
  reg [63 : 0]  G1_d;
  wire [63 : 0] G1_m0;
  wire [63 : 0] G1_m1;
  wire [63 : 0] G1_a_prim;
  wire [63 : 0] G1_b_prim;
  wire [63 : 0] G1_c_prim;
  wire [63 : 0] G1_d_prim;

  reg [63 : 0]  G2_a;
  reg [63 : 0]  G2_b;
  reg [63 : 0]  G2_c;
  reg [63 : 0]  G2_d;
  wire [63 : 0] G2_m0;
  wire [63 : 0] G2_m1;
  wire [63 : 0] G2_a_prim;
  wire [63 : 0] G2_b_prim;
  wire [63 : 0] G2_c_prim;
  wire [63 : 0] G2_d_prim;

  reg [63 : 0]  G3_a;
  reg [63 : 0]  G3_b;
  reg [63 : 0]  G3_c;
  reg [63 : 0]  G3_d;
  wire [63 : 0] G3_m0;
  wire [63 : 0] G3_m1;
  wire [63 : 0] G3_a_prim;
  wire [63 : 0] G3_b_prim;
  wire [63 : 0] G3_c_prim;
  wire [63 : 0] G3_d_prim;


  //----------------------------------------------------------------
  // Instantiation of the compression modules.
  //----------------------------------------------------------------
  blake2_m_select mselect(
                          .clk(clk),
                          .reset_n(reset_n),
                          .load(load_m),
                          .m(block),
                          .r(dr_ctr_reg),
                          .state(G_ctr_reg),
                          .G0_m0(G0_m0),
                          .G0_m1(G0_m1),
                          .G1_m0(G1_m0),
                          .G1_m1(G1_m1),
                          .G2_m0(G2_m0),
                          .G2_m1(G2_m1),
                          .G3_m0(G3_m0),
                          .G3_m1(G3_m1)
                         );


  blake2_G G0(
              .a(G0_a),
              .b(G0_b),
              .c(G0_c),
              .d(G0_d),
              .m0(G0_m0),
              .m1(G0_m1),

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
              .m0(G1_m0),
              .m1(G1_m1),

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
              .m0(G2_m0),
              .m1(G2_m1),

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
              .m0(G3_m0),
              .m1(G3_m1),

              .a_prim(G3_a_prim),
              .b_prim(G3_b_prim),
              .c_prim(G3_c_prim),
              .d_prim(G3_d_prim)
             );


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign digest = {h0_reg[7:0], h0_reg[15:8], h0_reg[23:16], h0_reg[31:24], h0_reg[39:32], h0_reg[47:40], h0_reg[55:48], h0_reg[63:56],
                   h1_reg[7:0], h1_reg[15:8], h1_reg[23:16], h1_reg[31:24], h1_reg[39:32], h1_reg[47:40], h1_reg[55:48], h1_reg[63:56],
                   h2_reg[7:0], h2_reg[15:8], h2_reg[23:16], h2_reg[31:24], h2_reg[39:32], h2_reg[47:40], h2_reg[55:48], h2_reg[63:56],
                   h3_reg[7:0], h3_reg[15:8], h3_reg[23:16], h3_reg[31:24], h3_reg[39:32], h3_reg[47:40], h3_reg[55:48], h3_reg[63:56],
                   h4_reg[7:0], h4_reg[15:8], h4_reg[23:16], h4_reg[31:24], h4_reg[39:32], h4_reg[47:40], h4_reg[55:48], h4_reg[63:56],
                   h5_reg[7:0], h5_reg[15:8], h5_reg[23:16], h5_reg[31:24], h5_reg[39:32], h5_reg[47:40], h5_reg[55:48], h5_reg[63:56],
                   h6_reg[7:0], h6_reg[15:8], h6_reg[23:16], h6_reg[31:24], h6_reg[39:32], h6_reg[47:40], h6_reg[55:48], h6_reg[63:56],
                   h7_reg[7:0], h7_reg[15:8], h7_reg[23:16], h7_reg[31:24], h7_reg[39:32], h7_reg[47:40], h7_reg[55:48], h7_reg[63:56]};

  assign digest_valid = digest_valid_reg;

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
          ready_reg          <= 1;
          digest_valid_reg   <= 0;
          G_ctr_reg          <= STATE_G0;
          dr_ctr_reg         <= 0;
          blake2_ctrl_reg    <= CTRL_IDLE;
        end
      else
        begin
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

          if (ready_we)
            begin
              ready_reg <= ready_new;
            end

          if (digest_valid_we)
            begin
              digest_valid_reg <= digest_valid_new;
            end

          if (G_ctr_we)
            begin
              G_ctr_reg <= G_ctr_new;
            end

          if (dr_ctr_we)
            begin
              dr_ctr_reg <= dr_ctr_new;
            end

          if (blake2_ctrl_we)
            begin
              blake2_ctrl_reg <= blake2_ctrl_new;
            end
        end
    end // reg_update


  //----------------------------------------------------------------
  // chain_logic
  //
  // Logic for updating the chain registers.
  //----------------------------------------------------------------
  always @*
    begin : chain_logic
      if (init_state)
        begin
          h0_new  = IV0 ^ parameter_block[63:0];
          h1_new  = IV1 ^ parameter_block[127:64];
          h2_new  = IV2 ^ parameter_block[191:128];
          h3_new  = IV3 ^ parameter_block[255:192];
          h4_new  = IV4 ^ parameter_block[319:256];
          h5_new  = IV5 ^ parameter_block[383:320];
          h6_new  = IV6 ^ parameter_block[447:384];
          h7_new  = IV7 ^ parameter_block[511:448];
          h_we    = 1;
        end
      else if (update_chain_value)
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
      else
        begin
          h0_new = 64'h0000000000000000;
          h1_new = 64'h0000000000000000;
          h2_new = 64'h0000000000000000;
          h3_new = 64'h0000000000000000;
          h4_new = 64'h0000000000000000;
          h5_new = 64'h0000000000000000;
          h6_new = 64'h0000000000000000;
          h7_new = 64'h0000000000000000;
          h_we   = 0;
        end
    end // chain_logic


  //----------------------------------------------------------------
  // state_logic
  //
  // Logic to init and update the internal state.
  //----------------------------------------------------------------
  always @*
    begin : state_logic
      if (init_state)
        begin
          v0_new  = IV0 ^ parameter_block[63:0];
          v1_new  = IV1 ^ parameter_block[127:64];
          v2_new  = IV2 ^ parameter_block[191:128];
          v3_new  = IV3 ^ parameter_block[255:192];
          v4_new  = IV4 ^ parameter_block[319:256];
          v5_new  = IV5 ^ parameter_block[383:320];
          v6_new  = IV6 ^ parameter_block[447:384];
          v7_new  = IV7 ^ parameter_block[511:448];
          v8_new  = IV0;
          v9_new  = IV1;
          v10_new = IV2;
          v11_new = IV3;
          v12_new = data_length[63:0] ^ IV4;
          v13_new = t1_reg ^ IV5;
          if (final_block)
            v14_new = 64'hffffffffffffffff ^ IV6;
          else
            v14_new = IV6;
          v15_new = f1_reg ^ IV7;
          v_we    = 1;
        end
      else if (update_state)
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

            default:
              begin
                G0_a = 0;
                G0_b = 0;
                G0_c = 0;
                G0_d = 0;

                G1_a = 0;
                G1_b = 0;
                G1_c = 0;
                G1_d = 0;

                G2_a = 0;
                G2_b = 0;
                G2_c = 0;
                G2_d = 0;

                G3_a = 0;
                G3_b = 0;
                G3_c = 0;
                G3_d = 0;
              end
          endcase // case (G_ctr_reg)
        end // if (update_state)
      else
        begin
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
        end
    end // state_logic


  //----------------------------------------------------------------
  // G_ctr
  // Update logic for the G function counter. Basically a one bit
  // counter that selects if we column of diaginal updates.
  // increasing counter with reset.
  //----------------------------------------------------------------
  always @*
    begin : G_ctr
      if (G_ctr_rst)
        begin
          G_ctr_new = 0;
          G_ctr_we  = 1;
        end
      else if (G_ctr_inc)
        begin
          G_ctr_new = G_ctr_reg + 1'b1;
          G_ctr_we  = 1;
        end
      else
        begin
          G_ctr_new = 0;
          G_ctr_we  = 0;
        end
    end // G_ctr


  //----------------------------------------------------------------
  // dr_ctr
  // Update logic for the round counter, a monotonically
  // increasing counter with reset.
  //----------------------------------------------------------------
  always @*
    begin : dr_ctr
      if (dr_ctr_rst)
        begin
          dr_ctr_new = 0;
          dr_ctr_we  = 1;
        end
      else if (dr_ctr_inc)
        begin
          dr_ctr_new = dr_ctr_reg + 1'b1;
          dr_ctr_we  = 1;
        end
      else
        begin
          dr_ctr_new = 0;
          dr_ctr_we  = 0;
        end
    end // dr_ctr


  //----------------------------------------------------------------
  // blake2_ctrl_fsm
  // Logic for the state machine controlling the core behaviour.
  //----------------------------------------------------------------
  always @*
    begin : blake2_ctrl_fsm
      init_state         = 0;
      update_state       = 0;

      load_m             = 0;

      G_ctr_inc          = 0;
      G_ctr_rst          = 0;

      dr_ctr_inc         = 0;
      dr_ctr_rst         = 0;

      update_chain_value = 0;

      ready_new          = 0;
      ready_we           = 0;

      digest_valid_new   = 0;
      digest_valid_we    = 0;

      blake2_ctrl_new    = CTRL_IDLE;
      blake2_ctrl_we     = 0;


      case (blake2_ctrl_reg)
        CTRL_IDLE:
          begin
            if (init)
              begin
                ready_new       = 0;
                ready_we        = 1;
                load_m          = 1;
                blake2_ctrl_new = CTRL_INIT;
                blake2_ctrl_we  = 1;
              end
          end


        CTRL_INIT:
          begin
            init_state      = 1;
            G_ctr_rst       = 1;
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
                if (dr_ctr_reg == (NUM_ROUNDS - 1))
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
            digest_valid_new   = 1;
            digest_valid_we    = 1;
            blake2_ctrl_new    = CTRL_DONE;
            blake2_ctrl_we     = 1;
          end


        CTRL_DONE:
          begin
            if (init)
              begin
                ready_new        = 0;
                ready_we         = 1;
                digest_valid_new = 0;
                digest_valid_we  = 1;
                load_m           = 1;
                blake2_ctrl_new  = CTRL_INIT;
                blake2_ctrl_we   = 1;
              end
            else if (next)
              begin
                ready_new        = 0;
                ready_we         = 1;
                digest_valid_new = 0;
                digest_valid_we  = 1;
                load_m           = 1;
                blake2_ctrl_new  = CTRL_INIT;
                blake2_ctrl_we   = 1;
              end
          end


        default:
          begin
            blake2_ctrl_new = CTRL_IDLE;
            blake2_ctrl_we  = 1;
          end
      endcase // case (blake2_ctrl_reg)
    end // blake2_ctrl_fsm
endmodule // blake2_core

//======================================================================
// EOF blake2_core.v
//======================================================================
