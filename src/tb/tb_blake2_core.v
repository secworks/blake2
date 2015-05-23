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
  parameter DISPLAY_STATE = 1;

  parameter CLK_HALF_PERIOD = 2;
  parameter CLK_PERIOD      = 2 * CLK_HALF_PERIOD;

  parameter TEST_DIGEST = 512'h865939e120e6805438478841afb739ae4250cf372653078a065cdcfffca4caf798e6d462b65d658fc165782640eded70963449ae1500fb0f24981d7727e22c41;

  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [63 : 0]   cycle_ctr;
  reg [31 : 0]   error_ctr;
  reg [31 : 0]   tc_ctr;

  reg            tb_clk;
  reg            tb_reset_n;

  reg            tb_init;
  reg            tb_next;
  reg [1023 : 0] tb_block;
  wire           tb_ready;
  wire [511 : 0] tb_digest;
  wire           tb_digest_valid;

  reg            error_found;
  reg [31 : 0]   read_data;

  reg [511 : 0]  extracted_data;

  reg            display_cycle_ctr;


  //----------------------------------------------------------------
  // blake2_core device under test.
  //----------------------------------------------------------------
  blake2_core dut(
                  .clk(tb_clk),
                  .reset_n(tb_reset_n),
                  .init(tb_init),
                  .next(tb_next),
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


  //--------------------------------------------------------------------
  // dut_monitor
  //
  // Monitor displaying information every cycle.
  // Includes the cycle counter.
  //--------------------------------------------------------------------
  always @ (posedge tb_clk)
    begin : dut_monitor
      cycle_ctr = cycle_ctr + 1;

      if (display_cycle_ctr)
        begin
          $display("cycle = %016x:", cycle_ctr);
        end

      if (DISPLAY_STATE)
        begin
          dump_dut_state();
        end

    end // dut_monitor


  //----------------------------------------------------------------
  // reset_dut
  //----------------------------------------------------------------
  task reset_dut();
    begin
      tb_reset_n = 0;
      #(2 * CLK_PERIOD);
      tb_reset_n = 1;
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // dump_dut_state
  //
  // Dump the internal state of the dut to std out.
  //----------------------------------------------------------------
  task dump_dut_state();
    begin
      $display("DUT internal state");
      $display("------------------");
      $display("Inputs and outputs:");
      $display("init  = 0x%01x, next  = 0x%01x", dut.init, dut.next);
      $display("ready = 0x%01x, valid = 0x%01x", dut.ready, dut.digest_valid);
      $display("block[1023 : 0768] = 0x%064x", dut.block[1023 : 0768]);
      $display("block[0767 : 0512] = 0x%064x", dut.block[0767 : 0512]);
      $display("block[0511 : 0256] = 0x%064x", dut.block[0511 : 0256]);
      $display("block[0255 : 0000] = 0x%064x", dut.block[0255 : 0000]);
      $display("digest[511 : 256]  = 0x%064x", dut.digest[0511 : 0256]);
      $display("digest[255 : 000]  = 0x%064x", dut.digest[0255 : 0000]);
      $display("");

      $display("State and control:");
      $display("blake2_ctrl_reg = 0x%02x", dut.blake2_ctrl_reg);
      $display("G_ctr_reg       = 0x%01x, dr_ctr_reg = 0x%04x", dut.G_ctr_reg,
               dut.dr_ctr_reg);
      $display("");
    end
  endtask // dump_top_state


  //----------------------------------------------------------------
  // display_test_result()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_result();
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
  // init_dut()
  //
  // Set the input to the DUT to defined values.
  //----------------------------------------------------------------
  task init_dut();
    begin
      cycle_ctr  = 0;
      error_ctr  = 0;
      tc_ctr     = 0;
      tb_clk     = 0;
      tb_reset_n = 0;
      tb_init    = 0;
      tb_next    = 0;
      tb_block   = {16{64'h0000000000000000}};
    end
  endtask // init_dut


  //----------------------------------------------------------------
  // blake2_core
  //
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : blake2_core_test
      $display("   -- Testbench for blake2_core started --");
      init_dut();
      reset_dut();

      $display("State at init after reset:");
      dump_dut_state();

      tb_init = 1;
      #(2 * CLK_PERIOD);
      tb_init = 0;

      #(100 * CLK_PERIOD);

      $display("tb_digest:   %0128x", tb_digest);
      $display("TEST_DIGEST: %0128x", TEST_DIGEST);

      if (tb_digest == TEST_DIGEST)
        tc_ctr = tc_ctr + 1;
      else
        error_ctr = error_ctr + 1;

      display_test_result();
      $display("*** blake2_core simulation done.");
      $finish_and_return(error_ctr);
    end // blake2_core_test
endmodule // tb_blake2_core

//======================================================================
// EOF tb_blake2_core.v
//======================================================================
