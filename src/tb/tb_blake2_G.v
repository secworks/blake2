//======================================================================
//
// tb_blake2_G.v
// -------------
// Testbench for the Blake2 G function.
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

module tb_blake2_G();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG = 0;

  parameter CLK_HALF_PERIOD = 2;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

  parameter [63 : 0]
    TEST_A_PRIME = 64'hf0c9aa0de38b1b89,
    TEST_B_PRIME = 64'hbbdf863401fde49b,
    TEST_C_PRIME = 64'he85eb23c42183d3d,
    TEST_D_PRIME = 64'h7111fd8b6445099d;

  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [63 : 0]  cycle_ctr;
  reg [31 : 0]  error_ctr;
  reg [31 : 0]  tc_ctr;

  reg           tb_clk;
  reg [63 : 0]  tb_a;
  reg [63 : 0]  tb_b;
  reg [63 : 0]  tb_c;
  reg [63 : 0]  tb_d;
  reg [63 : 0]  tb_m0;
  reg [63 : 0]  tb_m1;
  wire [63 : 0] tb_a_prim;
  wire [63 : 0] tb_b_prim;
  wire [63 : 0] tb_c_prim;
  wire [63 : 0] tb_d_prim;

  reg           display_cycle_ctr;


  //----------------------------------------------------------------
  // blake2_G device under test.
  //----------------------------------------------------------------
  blake2_G DUT(
               .a(tb_a),
               .b(tb_b),
               .c(tb_c),
               .d(tb_d),
               .m0(tb_m0),
               .m1(tb_m1),
               .a_prim(tb_a_prim),
               .b_prim(tb_b_prim),
               .c_prim(tb_c_prim),
               .d_prim(tb_d_prim)
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

    end // dut_monitor


  //----------------------------------------------------------------
  // dump_dut_state
  //
  // Dump the internal state of the dut to std out.
  //----------------------------------------------------------------
  task dump_dut_state;
    begin
      $display("");
      $display("DUT internal state");
      $display("------------------");
      $display("");
    end
  endtask // dump_dut_state


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
  // init_dut()
  //
  // Set the input to the DUT to defined values.
  //----------------------------------------------------------------
  task init_dut;
    begin
      cycle_ctr = 0;
      error_ctr = 0;
      tc_ctr    = 0;
      tb_clk    = 0;
      tb_a      = 64'h6a09e667f2bdc948;
      tb_b      = 64'h510e527fade682d1;
      tb_c      = 64'h6a09e667f3bcc908;
      tb_d      = 64'h510e527fade68251;
      tb_m0     = 64'h0000000000000000;
      tb_m1     = 64'h0000000000000000;
    end
  endtask // init_dut


  //----------------------------------------------------------------
  // blake2_core
  //
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : tb_blake2_G_test
      $display("   -- Testbench for Blake2 G function test started --");
      init_dut();

      #(CLK_PERIOD);

      if (tb_a_prim == TEST_A_PRIME)
        tc_ctr = tc_ctr + 1;
      else
        error_ctr = error_ctr + 1;

      if (tb_b_prim == TEST_B_PRIME)
        tc_ctr = tc_ctr + 1;
      else
        error_ctr = error_ctr + 1;

      if (tb_c_prim == TEST_C_PRIME)
        tc_ctr = tc_ctr + 1;
      else
        error_ctr = error_ctr + 1;

      if (tb_d_prim == TEST_D_PRIME)
        tc_ctr = tc_ctr + 1;
      else
        error_ctr = error_ctr + 1;

      if (error_ctr)
        begin
          $display("Errors found--dumping state:");
          $display("tb_a_prim: %016x", tb_a_prim);
          $display("tb_b_prim: %016x", tb_b_prim);
          $display("tb_c_prim: %016x", tb_c_prim);
          $display("tb_d_prim: %016x", tb_d_prim);
        end

      display_test_result();
      $display("*** Blake2 G functions simulation done.");
      $finish_and_return(error_ctr);
    end // tb_blake2_G_test
endmodule // tb_blake2_G

//======================================================================
// EOF tb_blake2_G.v
//======================================================================
