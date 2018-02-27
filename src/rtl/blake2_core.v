//======================================================================
//
// blake2_core.v
// --------------
// Verilog 2001 implementation of the hash function Blake2.
// This is the internal core with wide interfaces. The implementation
// follows RFC 7693
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
                   input wire            next_block,
                   input wire            final_block,

                   input wire [7 : 0]    key_len,
                   input wire [7 : 0]    digest_len,

                   input wire [1023 : 0] block,

                   output wire           ready,
                   output wire [511 : 0] digest,
                   output wire           digest_valid
                  );


  //----------------------------------------------------------------
  // Configuration parameters.
  //----------------------------------------------------------------
  // Default number of rounds
  localparam NUM_ROUNDS = 4'hc;

  // Block size in bytes.
  localparam BLOCK_SIZE = 128;


  //----------------------------------------------------------------
  // Internal constant definitions.
  //----------------------------------------------------------------
  // G function data select states.
  localparam G_COLUMN   = 0;
  localparam G_DIAGONAL = 1;

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
  localparam CTRL_NEXT     = 3'h2;
  localparam CTRL_ROUNDS   = 3'h3;
  localparam CTRL_FINALIZE = 3'h4;
  localparam CTRL_DONE     = 3'h5;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [63 : 0] h_reg [0 : 7];
  reg [63 : 0] h_new [0 : 7];
  reg          h_we;

  reg [63 : 0] v_reg [0 : 15];
  reg [63 : 0] v_new [0 : 15];
  reg          v_we;

  reg [63 : 0] t0_reg;
  reg [63 : 0] t0_new;
  reg          t0_we;
  reg [63 : 0] t1_reg;
  reg [63 : 0] t1_new;
  reg          t1_we;
  reg          t_ctr_rst;
  reg          t_ctr_inc;

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

  reg [3 : 0] round_ctr_reg;
  reg [3 : 0] round_ctr_new;
  reg         round_ctr_we;
  reg         round_ctr_inc;
  reg         round_ctr_rst;

  reg [2 : 0] blake2_ctrl_reg;
  reg [2 : 0] blake2_ctrl_new;
  reg         blake2_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg init_state;
  reg update_state;
  reg init_f;
  reg update_f;

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
                          .r(round_ctr_reg),
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
  assign digest = {h_reg[0][7:0],   h_reg[0][15:8],  h_reg[0][23:16], h_reg[0][31:24],
                   h_reg[0][39:32], h_reg[0][47:40], h_reg[0][55:48], h_reg[0][63:56],
                   h_reg[1][7:0],   h_reg[1][15:8],  h_reg[1][23:16], h_reg[1][31:24],
                   h_reg[1][39:32], h_reg[1][47:40], h_reg[1][55:48], h_reg[1][63:56],
                   h_reg[2][7:0],   h_reg[2][15:8],  h_reg[2][23:16], h_reg[2][31:24],
                   h_reg[2][39:32], h_reg[2][47:40], h_reg[2][55:48], h_reg[2][63:56],
                   h_reg[3][7:0],   h_reg[3][15:8],  h_reg[3][23:16], h_reg[3][31:24],
                   h_reg[3][39:32], h_reg[3][47:40], h_reg[3][55:48], h_reg[3][63:56],
                   h_reg[4][7:0],   h_reg[4][15:8],  h_reg[4][23:16], h_reg[4][31:24],
                   h_reg[4][39:32], h_reg[4][47:40], h_reg[4][55:48], h_reg[4][63:56],
                   h_reg[5][7:0],   h_reg[5][15:8],  h_reg[5][23:16], h_reg[5][31:24],
                   h_reg[5][39:32], h_reg[5][47:40], h_reg[5][55:48], h_reg[5][63:56],
                   h_reg[6][7:0],   h_reg[6][15:8],  h_reg[6][23:16], h_reg[6][31:24],
                   h_reg[6][39:32], h_reg[6][47:40], h_reg[6][55:48], h_reg[6][63:56],
                   h_reg[7][7:0],   h_reg[7][15:8],  h_reg[7][23:16], h_reg[7][31:24],
                   h_reg[7][39:32], h_reg[7][47:40], h_reg[7][55:48], h_reg[7][63:56]};

  assign digest_valid = digest_valid_reg;

  assign ready = ready_reg;


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with asynchronous
  // active low reset. All registers have write enable.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin : reg_update
      integer i;

      if (!reset_n)
        begin
          for (i = 0; i < 8; i = i + 1)
            h_reg[i] <= 64'h0;

          for (i = 0; i < 16; i = i + 1)
            v_reg[i] <= 64'h0;

          t0_reg           <= 64'h0;
          t1_reg           <= 64'h0;
          ready_reg        <= 1;
          digest_valid_reg <= 0;
          G_ctr_reg        <= G_COLUMN;
          round_ctr_reg    <= 0;
          blake2_ctrl_reg  <= CTRL_IDLE;
        end
      else
        begin
          if (h_we)
            begin
              for (i = 0; i < 8; i = i + 1)
                h_reg[i] <= h_new[i];
            end

          if (v_we)
            begin
              for (i = 0; i < 8; i = i + 1)
                v_reg[i] <= v_new[i];
            end

          if (ready_we)
            ready_reg <= ready_new;

          if (digest_valid_we)
            digest_valid_reg <= digest_valid_new;

          if (G_ctr_we)
            G_ctr_reg <= G_ctr_new;

          if (round_ctr_we)
            round_ctr_reg <= round_ctr_new;

          if (t0_we)
            t0_reg <= t0_new;

          if (t1_we)
            t1_reg <= t1_new;

          if (blake2_ctrl_we)
            begin
              blake2_ctrl_reg <= blake2_ctrl_new;
            end
        end
    end // reg_update


  //----------------------------------------------------------------
  // state_logic
  // Logic for initializing and updating state registers h.
  //----------------------------------------------------------------
  always @*
    begin : state_logic
      reg [63 : 0] blake2_param;
      integer i;

      for (i = 0; i < 8; i = i + 1)
        h_new[i] = 64'h0;
      h_we   = 0;

      // Assemble the blake2 parameter block.
      blake2_param = {8'h01, 8'h01, key_len, digest_len, 32'h0};

      if (init_state)
        begin
          h_new[0]  = IV0 ^ blake2_param;
          h_new[1]  = IV1;
          h_new[2]  = IV2;
          h_new[3]  = IV3;
          h_new[4]  = IV4;
          h_new[5]  = IV5;
          h_new[6]  = IV6;
          h_new[7]  = IV7;
          h_we = 1;
        end

      if (update_state)
        begin
          h_new[0] = h_reg[0] ^ v_reg[0] ^ v_reg[8];
          h_new[1] = h_reg[1] ^ v_reg[1] ^ v_reg[9];
          h_new[2] = h_reg[2] ^ v_reg[2] ^ v_reg[10];
          h_new[3] = h_reg[3] ^ v_reg[3] ^ v_reg[11];
          h_new[4] = h_reg[4] ^ v_reg[4] ^ v_reg[12];
          h_new[5] = h_reg[5] ^ v_reg[5] ^ v_reg[13];
          h_new[6] = h_reg[6] ^ v_reg[6] ^ v_reg[14];
          h_new[7] = h_reg[7] ^ v_reg[7] ^ v_reg[15];
          h_we = 1;
        end
    end // chain_logic


  //----------------------------------------------------------------
  // F_compression
  //
  // The compression function F.
  //----------------------------------------------------------------
  always @*
    begin : F_compression
      integer i;

      for (i = 0; i < 16; i = i + 1)
        v_new[i] = 64'h0;
      v_we = 0;

      G0_a = 64'h0;
      G0_b = 64'h0;
      G0_c = 64'h0;
      G0_d = 64'h0;
      G1_a = 64'h0;
      G1_b = 64'h0;
      G1_c = 64'h0;
      G1_d = 64'h0;
      G2_a = 64'h0;
      G2_b = 64'h0;
      G2_c = 64'h0;
      G2_d = 64'h0;
      G3_a = 64'h0;
      G3_b = 64'h0;
      G3_c = 64'h0;
      G3_d = 64'h0;

      if (init_f)
        begin
          v_new[0]  = h_reg[0];
          v_new[1]  = h_reg[1];
          v_new[2]  = h_reg[2];
          v_new[3]  = h_reg[3];
          v_new[4]  = h_reg[4];
          v_new[5]  = h_reg[5];
          v_new[6]  = h_reg[6];
          v_new[7]  = h_reg[7];
          v_new[8]  = IV0;
          v_new[9]  = IV1;
          v_new[10] = IV2;
          v_new[11] = IV3;
          v_new[12] = IV4 ^ t0_reg;
          v_new[13] = IV5 ^ t1_reg;
          v_new[14] = IV6 ^ {64{final_block}};
          v_new[15] = IV7;
          v_we = 1;
        end

      else if (update_f)
        begin
          v_we    = 1;

          case (G_ctr_reg)
            G_COLUMN:
              begin
                G0_a      = v_reg[0];
                G0_b      = v_reg[4];
                G0_c      = v_reg[8];
                G0_d      = v_reg[12];
                v_new[0]  = G0_a_prim;
                v_new[4]  = G0_b_prim;
                v_new[8]  = G0_c_prim;
                v_new[12] = G0_d_prim;

                G1_a      = v_reg[1];
                G1_b      = v_reg[5];
                G1_c      = v_reg[9];
                G1_d      = v_reg[13];
                v_new[1]  = G1_a_prim;
                v_new[5]  = G1_b_prim;
                v_new[9]  = G1_c_prim;
                v_new[13] = G1_d_prim;

                G2_a      = v_reg[2];
                G2_b      = v_reg[6];
                G2_c      = v_reg[10];
                G2_d      = v_reg[14];
                v_new[2]  = G2_a_prim;
                v_new[6]  = G2_b_prim;
                v_new[10] = G2_c_prim;
                v_new[14] = G2_d_prim;

                G3_a      = v_reg[3];
                G3_b      = v_reg[7];
                G3_c      = v_reg[11];
                G3_d      = v_reg[15];
                v_new[3]  = G3_a_prim;
                v_new[7]  = G3_b_prim;
                v_new[11] = G3_c_prim;
                v_new[15] = G3_d_prim;
                v_we = 1;
              end

            G_DIAGONAL:
              begin
                G0_a      = v_reg[0];
                G0_b      = v_reg[5];
                G0_c      = v_reg[10];
                G0_d      = v_reg[15];
                v_new[0]  = G0_a_prim;
                v_new[5]  = G0_b_prim;
                v_new[10] = G0_c_prim;
                v_new[15] = G0_d_prim;

                G1_a      = v_reg[1];
                G1_b      = v_reg[6];
                G1_c      = v_reg[11];
                G1_d      = v_reg[12];
                v_new[1]  = G1_a_prim;
                v_new[6]  = G1_b_prim;
                v_new[11] = G1_c_prim;
                v_new[12] = G1_d_prim;

                G2_a      = v_reg[2];
                G2_b      = v_reg[7];
                G2_c      = v_reg[8];
                G2_d      = v_reg[13];
                v_new[2]  = G2_a_prim;
                v_new[7]  = G2_b_prim;
                v_new[8]  = G2_c_prim;
                v_new[13] = G2_d_prim;

                G3_a      = v_reg[3];
                G3_b      = v_reg[4];
                G3_c      = v_reg[9];
                G3_d      = v_reg[14];
                v_new[3]  = G3_a_prim;
                v_new[4]  = G3_b_prim;
                v_new[9]  = G3_c_prim;
                v_new[14] = G3_d_prim;
              end

            default:
              begin
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
      G_ctr_new = G_COLUMN;
      G_ctr_we  = 0;

      if (G_ctr_rst)
        begin
          G_ctr_new = G_COLUMN;
          G_ctr_we  = 1;
        end

      if (G_ctr_inc)
        begin
          G_ctr_new = ~G_ctr_reg;
          G_ctr_we  = 1;
        end
    end // G_ctr


  //----------------------------------------------------------------
  // round_ctr
  // Update logic for the round counter, a monotonically
  // increasing counter with reset.
  //----------------------------------------------------------------
  always @*
    begin : round_ctr
      round_ctr_new = 0;
      round_ctr_we  = 0;

      if (round_ctr_rst)
        begin
          round_ctr_we  = 1;
        end

      if (round_ctr_inc)
        begin
          round_ctr_new = round_ctr_reg + 1'b1;
          round_ctr_we  = 1;
        end
    end // round_ctr


  //----------------------------------------------------------------
  // t_ctr
  // Update logic for the byte offset counter t spanning two
  // words - t0_reg and t1_reg.
  //----------------------------------------------------------------
  always @*
    begin : t_ctr
      t0_new = 64'h0;
      t0_we  = 0;

      t1_new = 64'h0;
      t1_we  = 0;

      if (t_ctr_rst)
        begin
          t0_we = 1;
          t1_we = 1;
        end

      if (t_ctr_inc)
        begin
          t0_new = t0_reg + BLOCK_SIZE;
          t0_we  = 1;

          if (t0_new < t0_reg)
            begin
              t1_new = t1_reg + 1'b1;
              t1_we  = 1;
            end
        end
    end // t_ctr


  //----------------------------------------------------------------
  // blake2_ctrl_fsm
  // Logic for the state machine controlling the core behaviour.
  //----------------------------------------------------------------
  always @*
    begin : blake2_ctrl_fsm
      init_state         = 0;
      update_state       = 0;

      init_f             = 0;
      update_f           = 0;

      load_m             = 0;

      G_ctr_inc          = 0;
      G_ctr_rst          = 0;

      round_ctr_inc      = 0;
      round_ctr_rst      = 0;

      t_ctr_rst          = 0;
      t_ctr_inc          = 0;

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
                blake2_ctrl_new = CTRL_INIT;
                blake2_ctrl_we  = 1;
              end

            if (next_block)
              begin
                ready_new       = 0;
                ready_we        = 1;
                load_m          = 1;
                blake2_ctrl_new = CTRL_ROUNDS;
                blake2_ctrl_we  = 1;
              end
          end


        CTRL_INIT:
          begin
            init_state      = 1;
            G_ctr_rst       = 1;
            round_ctr_rst      = 1;
            t_ctr_rst       = 1;
            blake2_ctrl_new = CTRL_IDLE;
            blake2_ctrl_we  = 1;
          end


        CTRL_ROUNDS:
          begin
            update_state = 1;
            G_ctr_inc   = 1;
            if (G_ctr_reg == G_DIAGONAL)
              begin
                round_ctr_inc = 1;
                if (round_ctr_reg < NUM_ROUNDS)
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
            else if (next_block)
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
