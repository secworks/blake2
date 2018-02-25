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

  reg            tb_init;
  reg            tb_next_block;
  reg            tb_final_block;
  reg [1023 : 0] tb_block;
  reg [7 : 0]    tb_key_len;
  reg [7 : 0]    tb_digest_len;
  wire           tb_ready;
  wire [511 : 0] tb_digest;
  wire           tb_digest_valid;


  //----------------------------------------------------------------
  // blake2_core devices under test.
  //----------------------------------------------------------------
  blake2_core dut (
                   .clk(tb_clk),
                   .reset_n(tb_reset_n),

                   .init(tb_init),
                   .next_block(tb_next_block),
                   .final_block(tb_final_block),

                   .key_len(tb_key_len),
                   .digest_len(tb_digest_len),

                   .block(tb_block),

                   .ready(tb_ready),
                   .digest(tb_digest),
                   .digest_valid(tb_digest_valid)
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
      cycle_ctr      = 0;
      error_ctr      = 0;
      tc_ctr         = 0;
      tb_clk         = 0;
      tb_reset_n     = 1;
      tb_init        = 0;
      tb_next_block  = 0;
      tb_final_block = 0;
      tb_key_len     = 8'h0;
      tb_digest_len  = 8'h0;
      tb_block       = 1024'h0;
    end
  endtask // init


  //----------------------------------------------------------------
  // blake2_core_test
  //----------------------------------------------------------------
  initial
    begin : blake2_core_test
      $display("   -- Testbench for blake2_core started --");
      init();

      display_test_result();
      $display("*** blake2_core simulation done.");
      $finish_and_return(error_ctr);
    end // blake2_core_test
endmodule // tb_blake2_core

//======================================================================
// EOF tb_blake2_core.v
//======================================================================
