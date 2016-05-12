//======================================================================
//
// blake2.v
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

`include "blake2_core.v"

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
  localparam ADDR_NAME0       = 8'h00;
  localparam ADDR_NAME1       = 8'h01;
  localparam ADDR_VERSION     = 8'h02;

  localparam ADDR_CTRL        = 8'h08;
  localparam CTRL_INIT_BIT    = 0;
  localparam CTRL_NEXT_BIT    = 1;

  localparam ADDR_STATUS      = 8'h09;
  localparam STATUS_READY_BIT = 0;

  localparam ADDR_BLOCK_W00   = 8'h10;
  localparam ADDR_BLOCK_W31   = 8'h2f;

  localparam ADDR_DIGEST00    = 8'h80;
  localparam ADDR_DIGEST15    = 8'h8f;

  localparam CORE_NAME0   = 32'h626c616b; // "blak"
  localparam CORE_NAME1   = 32'h65322020; // "e2  "
  localparam CORE_VERSION = 32'h302e3130; // "0.10"


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

  assign core_block   = {block_mem[00], block_mem[01], block_mem[02], block_mem[03],
                         block_mem[04], block_mem[05], block_mem[06], block_mem[07],
                         block_mem[08], block_mem[09], block_mem[10], block_mem[11],
                         block_mem[12], block_mem[13], block_mem[14], block_mem[15],
                         block_mem[16], block_mem[17], block_mem[18], block_mem[19],
                         block_mem[20], block_mem[21], block_mem[22], block_mem[23],
                         block_mem[24], block_mem[25], block_mem[26], block_mem[27],
                         block_mem[28], block_mem[29], block_mem[30], block_mem[31]};

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
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin : reg_update
      reg [6 : 0] i;

      if (!reset_n)
        begin
          init_reg         <= 0;
          next_reg         <= 0;
          ready_reg        <= 0;
          digest_valid_reg <= 0;

          for (i = 0 ; i < 32 ; i = i + 1)
            begin
              block_mem[i] <= 32'h0;
            end

          for (i = 0 ; i < 16 ; i = i + 1)
            begin
              digest_mem[i] <= 32'h0;
            end
        end
      else
        begin
          ready_reg        <= core_ready;
          digest_valid_reg <= core_digest_valid;

          if (ctrl_we)
            init_reg <= write_data[CTRL_INIT_BIT];
          next_reg <= write_data[CTRL_NEXT_BIT];

          if (block_mem_we)
            block_mem[address[4 : 0]] <= write_data;
        end
    end // reg_update


  //----------------------------------------------------------------
  // Address decoder logic.
  //----------------------------------------------------------------
  always @*
    begin : addr_decoder
      block_mem_we  = 0;
      digest_mem_we = 0;
      tmp_read_data = 32'h0;
      tmp_error     = 0;

      if (cs)
        begin
          if (we)
            begin
              if ((address >= ADDR_BLOCK_W00) && (address <= ADDR_BLOCK_W31))
                begin
                  block_mem_we = 1;
                end

              case (address)
                ADDR_CTRL:
                  begin
                    ctrl_we  = 1;
                  end
              endcase // case (address)
            end // if (we)

          else
            begin
              case (address)
                ADDR_NAME0:
                  tmp_read_data = CORE_NAME0;

                ADDR_NAME1:
                  tmp_read_data = CORE_NAME1;

                ADDR_VERSION:
                  tmp_read_data = CORE_VERSION;

                ADDR_CTRL:
                  tmp_read_data = {28'h0, 2'b00, next_reg, init_reg};

                ADDR_STATUS:
                  tmp_read_data = {28'h0, 2'b00, {digest_valid_reg, ready_reg}};

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
