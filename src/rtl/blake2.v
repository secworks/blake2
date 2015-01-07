//======================================================================
//
// chacha.v
// --------
// Top level wrapper for the blake2 hash function core providing
// a simple memory like interface with 32 bit data access.
//
//
// Author: Joachim Strömbergson
// Copyright (c) 2014,  Secworks Sweden AB
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

module blake2(
              // Clock and reset.
              input wire           clk,
              input wire           reset_n,

              // Control.
              input wire           cs,
              input wire           we,

              // Data ports.
              input wire  [7 : 0]  address,
              input wire  [31 : 0] write_data,
              output wire [31 : 0] read_data,
              output wire          error
             );

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter ADDR_CTRL        = 8'h00;
  parameter CTRL_INIT_BIT    = 0;
  parameter CTRL_NEXT_BIT    = 1;

  parameter ADDR_STATUS      = 8'h01;
  parameter STATUS_READY_BIT = 0;

  parameter ADDR_BLOCK_W00   = 8'h10;
  parameter ADDR_BLOCK_W31   = 8'h2f;

  parameter ADDR_DIGEST00    = 8'h80;
  parameter ADDR_DIGEST15    = 8'h8f;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg init_reg;
  reg next_reg;
  reg ctrl_we;

  reg ready_reg;

  reg digest_valid_reg;

  reg [31 : 0] block_mem [0 : 31];
  reg          block_mem_we;

  reg [31 : 0] digest_mem [0 : 16];
  reg          digest_mem_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  wire            core_init;
  wire            core_next;
  wire            core_ready;
  wire [1023 : 0] core_block;
  wire [511 : 0]  core_digest;
  wire            core_digest_valid;

  reg [31 : 0]    tmp_read_data;
  reg             tmp_error;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign core_init    = init_reg;

  assign core_next    = next_reg;

  assign core_keylen  = keylen_reg;

  assign core_rounds  = rounds_reg;

  assign core_key     = {key0_reg, key1_reg, key2_reg, key3_reg,
                         key4_reg, key5_reg, key6_reg, key7_reg};

  assign core_iv      = {iv0_reg, iv1_reg};

  assign core_data_in = {data_in0_reg, data_in1_reg, data_in2_reg, data_in3_reg,
                         data_in4_reg, data_in5_reg, data_in6_reg, data_in7_reg,
                         data_in8_reg, data_in9_reg, data_in10_reg, data_in11_reg,
                         data_in12_reg, data_in13_reg, data_in14_reg, data_in15_reg};

  assign read_data = tmp_read_data;
  assign error     = tmp_error;


  //----------------------------------------------------------------
  // core instantiation.
  //----------------------------------------------------------------
  blake2_core core (
                    .clk(clk),
                    .reset_n(reset_n),

                    .init(core_init),
                    .next(core_next),

                    .block(core_block),

                    .ready(core_ready),

                    .digest(core_digest),
                    .digest_valid(core_digest_valid)
                   );


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with asynchronous
  // active low reset. All registers have write enable.
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin
      integer i;

      if (!reset_n)
        begin
          init_reg      <= 0;
          next_reg      <= 0;
          ready_reg     <= 0;

          for (i = 0 ; i < 32 ; i = i + 1)
            begin
              block_mem[i] <= 32'h00000000;
            end

          for (i = 0 ; i < 16 ; i = i + 1)
            begin
              digest_mem[i] <= 32'h00000000;
            end
        end
      else
        begin
          ready_reg          <= core_ready;
          data_out_valid_reg <= core_data_out_valid;

          if (ctrl_we)
            begin
              init_reg <= write_data[CTRL_INIT_BIT];
              next_reg <= write_data[CTRL_NEXT_BIT];
            end

          if (block_mem_we)
            begin
              block_mem[address[4 : 0]] <= write_data;
            end

        end
    end // reg_update


  //----------------------------------------------------------------
  // Address decoder logic.
  //----------------------------------------------------------------
  always @*
    begin : addr_decoder
      block_mem_we  = 0;
      digest_mem_we = 0;

      tmp_read_data = 32'h00000000;
      tmp_error     = 0;

      if (cs)
        begin
          if (we)
            begin
              if ((addr >= ADDR_BLOCK_W00) && (addr <= ADDR_BLOCK_W31))
                begin
                  block_mem_we = 1;
                end

              case (address)
                ADDR_CTRL:
                  begin
                    ctrl_we  = 1;
                  end

                ADDR_KEYLEN:
                  begin
                    keylen_we = 1;
                  end

                ADDR_ROUNDS:
                  begin
                    rounds_we  = 1;
                  end

                ADDR_KEY0:
                  begin
                    key0_we  = 1;
                  end

                ADDR_KEY1:
                  begin
                    key1_we  = 1;
                  end

                ADDR_KEY2:
                  begin
                    key2_we  = 1;
                  end

                ADDR_KEY3:
                  begin
                    key3_we  = 1;
                  end

                ADDR_KEY4:
                  begin
                    key4_we  = 1;
                  end

                ADDR_KEY5:
                  begin
                    key5_we  = 1;
                  end

                ADDR_KEY6:
                  begin
                    key6_we  = 1;
                  end

                ADDR_KEY7:
                  begin
                    key7_we  = 1;
                  end

                ADDR_IV0:
                  begin
                    iv0_we = 1;
                  end

                ADDR_IV1:
                  begin
                    iv1_we = 1;
                  end

                ADDR_DATA_IN0:
                  begin
                    data_in0_we = 1;
                  end

                ADDR_DATA_IN1:
                  begin
                    data_in1_we = 1;
                  end

                ADDR_DATA_IN2:
                  begin
                    data_in2_we = 1;
                  end

                ADDR_DATA_IN3:
                  begin
                    data_in3_we = 1;
                  end

                ADDR_DATA_IN4:
                  begin
                    data_in4_we = 1;
                  end

                ADDR_DATA_IN5:
                  begin
                    data_in5_we = 1;
                  end

                ADDR_DATA_IN6:
                  begin
                    data_in6_we = 1;
                  end

                ADDR_DATA_IN7:
                  begin
                    data_in7_we = 1;
                  end

                ADDR_DATA_IN8:
                  begin
                    data_in8_we = 1;
                  end

                ADDR_DATA_IN9:
                  begin
                    data_in9_we = 1;
                  end

                ADDR_DATA_IN10:
                  begin
                    data_in10_we = 1;
                  end

                ADDR_DATA_IN11:
                  begin
                    data_in11_we = 1;
                  end

                ADDR_DATA_IN12:
                  begin
                    data_in12_we = 1;
                  end

                ADDR_DATA_IN13:
                  begin
                    data_in13_we = 1;
                  end

                ADDR_DATA_IN14:
                  begin
                    data_in14_we = 1;
                  end

                ADDR_DATA_IN15:
                  begin
                    data_in15_we = 1;
                  end

                default:
                  begin
                    tmp_error = 1;
                  end
              endcase // case (address)
            end // if (we)

          else
            begin
              case (address)
                ADDR_CTRL:
                  begin
                    tmp_read_data = {28'h0000000, 2'b00, next_reg, init_reg};
                  end

                ADDR_STATUS:
                  begin
                    tmp_read_data = {28'h0000000, 2'b00,
                                    {data_out_valid_reg, ready_reg}};
                  end

                ADDR_KEYLEN:
                  begin
                    tmp_read_data = {28'h0000000, 3'b000, keylen_reg};
                  end

                ADDR_ROUNDS:
                  begin
                    tmp_read_data = {24'h000000, 3'b000, rounds_reg};
                  end

                ADDR_KEY0:
                  begin
                    tmp_read_data = key0_reg;
                  end

                ADDR_KEY1:
                  begin
                    tmp_read_data = key1_reg;
                  end

                ADDR_KEY2:
                  begin
                    tmp_read_data = key2_reg;
                  end

                ADDR_KEY3:
                  begin
                    tmp_read_data = key3_reg;
                  end

                ADDR_KEY4:
                  begin
                    tmp_read_data = key4_reg;
                  end

                ADDR_KEY5:
                  begin
                    tmp_read_data = key5_reg;
                  end

                ADDR_KEY6:
                  begin
                    tmp_read_data = key6_reg;
                  end

                ADDR_KEY7:
                  begin
                    tmp_read_data = key7_reg;
                  end

                ADDR_IV0:
                  begin
                    tmp_read_data = iv0_reg;
                  end

                ADDR_IV1:
                  begin
                    tmp_read_data = iv1_reg;
                  end

                ADDR_DATA_OUT0:
                  begin
                    tmp_read_data = data_out0_reg;
                  end

                ADDR_DATA_OUT1:
                  begin
                    tmp_read_data = data_out1_reg;
                  end

                ADDR_DATA_OUT2:
                  begin
                    tmp_read_data = data_out2_reg;
                  end

                ADDR_DATA_OUT3:
                  begin
                    tmp_read_data = data_out3_reg;
                  end

                ADDR_DATA_OUT4:
                  begin
                    tmp_read_data = data_out4_reg;
                  end

                ADDR_DATA_OUT5:
                  begin
                    tmp_read_data = data_out5_reg;
                  end

                ADDR_DATA_OUT6:
                  begin
                    tmp_read_data = data_out6_reg;
                  end

                ADDR_DATA_OUT7:
                  begin
                    tmp_read_data = data_out7_reg;
                  end

                ADDR_DATA_OUT8:
                  begin
                    tmp_read_data = data_out8_reg;
                  end

                ADDR_DATA_OUT9:
                  begin
                    tmp_read_data = data_out9_reg;
                  end

                ADDR_DATA_OUT10:
                  begin
                    tmp_read_data = data_out10_reg;
                  end

                ADDR_DATA_OUT11:
                  begin
                    tmp_read_data = data_out11_reg;
                  end

                ADDR_DATA_OUT12:
                  begin
                    tmp_read_data = data_out12_reg;
                  end

                ADDR_DATA_OUT13:
                  begin
                    tmp_read_data = data_out13_reg;
                  end

                ADDR_DATA_OUT14:
                  begin
                    tmp_read_data = data_out14_reg;
                  end

                ADDR_DATA_OUT15:
                  begin
                    tmp_read_data = data_out15_reg;
                  end

                default:
                  begin
                    tmp_error = 1;
                  end
              endcase // case (address)
            end
        end
    end // addr_decoder
endmodule // blake2

//======================================================================
// EOF blake2.v
//======================================================================
