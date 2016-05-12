//======================================================================
//
// tb_blake2_core.v
// ----------------
// Testbench for the Blake2 core.
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

//------------------------------------------------------------------
// Simulator directives.
//------------------------------------------------------------------
`timescale 1ns/100ps

module tb_blake2_core();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DISPLAY_STATE = 0;

  parameter CLK_HALF_PERIOD = 2;
  parameter CLK_PERIOD      = 2 * CLK_HALF_PERIOD;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [63 : 0]   cycle_ctr;
  reg [31 : 0]   error_ctr;
  reg [31 : 0]   tc_ctr;

  reg            tb_clk;
  reg            tb_reset_n;

  reg            tb_init_512, tb_init_256;
  reg            tb_next_512, tb_next_256;
  reg            tb_final_512, tb_final_256;
  reg [1023 : 0] tb_block_512, tb_block_256;
  reg [127 : 0]  tb_length_512, tb_length_256;
  wire           tb_ready_512, tb_ready_256;
  wire [511 : 0] tb_digest_512, tb_digest_256;
  wire           tb_digest_valid_512, tb_digest_valid_256;

  reg            error_found;
  reg [31 : 0]   read_data;

  reg [511 : 0]  extracted_data;

  reg            display_cycle_ctr;


  //----------------------------------------------------------------
  // blake2_core devices under test.
  //----------------------------------------------------------------

  // The BLAKE2b-512 core
  blake2_core #(
    .DIGEST_LENGTH(64)
  )
  dut_512 (
    .clk(tb_clk),
    .reset_n(tb_reset_n),
    .init(tb_init_512),
    .next(tb_next_512),
    .final_block(tb_final_512),
    .block(tb_block_512),
    .data_length(tb_length_512),
    .ready(tb_ready_512),
    .digest(tb_digest_512),
    .digest_valid(tb_digest_valid_512)
  );

  // The BLAKE2b-256 core
  blake2_core #(
    .DIGEST_LENGTH(32)
  )
  dut_256 (
    .clk(tb_clk),
    .reset_n(tb_reset_n),
    .init(tb_init_256),
    .next(tb_next_256),
    .final_block(tb_final_256),
    .block(tb_block_256),
    .data_length(tb_length_256),
    .ready(tb_ready_256),
    .digest(tb_digest_256),
    .digest_valid(tb_digest_valid_256)
  );


  //----------------------------------------------------------------
  // clk_gen
  //
  // Clock generator process.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF_PERIOD tb_clk = !tb_clk;
    end // clk_gen


  //----------------------------------------------------------------
  // reset_dut
  //----------------------------------------------------------------
  task reset_dut;
    begin
      tb_reset_n = 0;
      #(2 * CLK_PERIOD);
      tb_reset_n = 1;
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // display_test_result()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_result;
    begin
      if (error_ctr == 0)
        begin
          $display("*** All %02d test cases completed successfully", tc_ctr);
        end
      else
        begin
          $display("*** %02d test cases did not complete successfully.", error_ctr);
        end
    end
  endtask // display_test_result


  //----------------------------------------------------------------
  // init()
  //
  // Set the input to the DUT to defined values.
  //----------------------------------------------------------------
  task init;
    begin
      cycle_ctr  = 0;
      error_ctr  = 0;
      tc_ctr     = 0;
      tb_clk     = 0;
      tb_reset_n = 1;
    end
  endtask // init


  //----------------------------------------------------------------
  // test_512_core
  //
  // Test the 512-bit hashing core
  //----------------------------------------------------------------
  task test_512_core(
      input [1023 : 0] block,
      input [127 : 0]  data_length,
      input [511 : 0]  expected
    );
    begin
      tb_block_512 = block;
      tb_length_512 = data_length;

      reset_dut();

      tb_init_512 = 1;
      tb_final_512 = 1;
      #(2 * CLK_PERIOD);
      tb_final_512 = 0;
      tb_init_512 = 0;

      while (!tb_digest_valid_512)
        #(CLK_PERIOD);
      #(CLK_PERIOD);

      if (tb_digest_512 == expected)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test:");
          $display("block[1023:0768] = 0x%032x", block[1023:0768]);
          $display("block[0767:0512] = 0x%032x", block[0767:0512]);
          $display("block[0511:0256] = 0x%032x", block[0511:0256]);
          $display("block[0255:0000] = 0x%032x", block[0255:0000]);
          $display("tb_digest_512 = 0x%064x", tb_digest_512);
          $display("expected      = 0x%064x", expected);
          $display("");
        end
    end
  endtask // test_512_core


  //----------------------------------------------------------------
  // test_256_core
  //
  // Test the 256-bit hashing core
  //----------------------------------------------------------------
  task test_256_core(
      input [1023 : 0] block,
      input [127 : 0]  data_length,
      input [255 : 0]  expected
    );
    begin
      tb_block_256 = block;
      tb_length_256 = data_length;

      reset_dut();

      tb_init_256 = 1;
      tb_final_256 = 1;
      #(2 * CLK_PERIOD);
      tb_final_256 = 0;
      tb_init_256 = 0;

      while (!tb_digest_valid_256)
        #(CLK_PERIOD);
      #(CLK_PERIOD);

      if (tb_digest_256[511:256] == expected)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test:");
          $display("block[1023:0768] = 0x%032x", block[1023:0768]);
          $display("block[0767:0512] = 0x%032x", block[0767:0512]);
          $display("block[0511:0256] = 0x%032x", block[0511:0256]);
          $display("block[0255:0000] = 0x%032x", block[0255:0000]);
          $display("tb_digest_256[511:256] = 0x%032x", tb_digest_256[511:256]);
          $display("expected               = 0x%032x", expected);
          $display("");
        end
    end
  endtask // test_256_core


  //----------------------------------------------------------------
  // blake2_core
  //
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : blake2_core_test
      $display("   -- Testbench for blake2_core started --");
      init();

      test_512_core(
        {16{64'h0000000000000000}},
        128,
        512'h865939e120e6805438478841afb739ae4250cf372653078a065cdcfffca4caf798e6d462b65d658fc165782640eded70963449ae1500fb0f24981d7727e22c41
      );

      test_512_core(
        {8'h01, {30{8'h00}}, 8'h02, {8{8'h00}}, 8'h02, {30{8'h00}}, 8'h01, {56{8'h00}}},
        72,
        512'hcbeffcb224f964ea408d2742963e87171e18f267960774136e56091915a82917bf6780b39061dd1ad31e4e90ef371358d1917646b39ea46153e1cfc54ea50416
      );

      test_512_core(
        1024'h610a4485ad561f80716d7b0ccb7d876c3eaacdf75e934266d061eb7b9f68d093fc756d945b0bbf822d71f4e5e9b733e7acf870a4b6c0e610145781beca04e63f1b22e0a1b048797e53d94d732567e8fc77cb4f5fe7cce5be3f915d9520879e17e6f4016be0228692da17256a9ea7c12c502954e1fa50d8f32bd30d7abe487872,
        128,
        512'hae531a602a32d012e9fd2872b8bc5c854c0de37c64e4abe951d573ab097afe664f3c8f95c332346a8ebbd859281030e99fa05c59de5e08fc64a1dfbccd416cdf
      );

      test_256_core(
        {16{64'h0000000000000000}},
        128,
        256'h378d0caaaa3855f1b38693c1d6ef004fd118691c95c959d4efa950d6d6fcf7c1
      );

      test_256_core(
        {8'h01, {30{8'h00}}, 8'h02, {8{8'h00}}, 8'h02, {30{8'h00}}, 8'h01, {56{8'h00}}},
        72,
        256'h0b3f693476c351014a7f90472055f584b45d5652284b01c90be5d29765db0b2b
      );

      test_256_core(
        1024'h610a4485ad561f80716d7b0ccb7d876c3eaacdf75e934266d061eb7b9f68d093fc756d945b0bbf822d71f4e5e9b733e7acf870a4b6c0e610145781beca04e63f1b22e0a1b048797e53d94d732567e8fc77cb4f5fe7cce5be3f915d9520879e17e6f4016be0228692da17256a9ea7c12c502954e1fa50d8f32bd30d7abe487872,
        128,
        256'h9cd77f477b8c2a97860c4b5e64519a1be27dcefbbec5a42b73644895fb22d23d
      );

      display_test_result();
      $display("*** blake2_core simulation done.");
      $finish_and_return(error_ctr);
    end // blake2_core_test
endmodule // tb_blake2_core

//======================================================================
// EOF tb_blake2_core.v
//======================================================================
