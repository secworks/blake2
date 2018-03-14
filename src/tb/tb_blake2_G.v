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

module tb_blake2_G();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG = 0;

  parameter CLK_HALF_PERIOD = 2;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;


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
          $display("*** %02d test cases completes, %02d test cases did not complete successfully.",
                   tc_ctr, error_ctr);
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
      tb_a      = 64'h0;
      tb_b      = 64'h0;
      tb_c      = 64'h0;
      tb_d      = 64'h0;
      tb_m0     = 64'h0;
      tb_m1     = 64'h0;
    end
  endtask // init_dut


  //----------------------------------------------------------------
  //----------------------------------------------------------------
  task testrunner (input [63 : 0] a, input [63 : 0] b,
                   input [63 : 0] c, input [63 : 0] d,
                   input [63 : 0] m0, input [63 : 0] m1,

                   input [63 : 0] prim_a, input [63 : 0] prim_b,
                   input [63 : 0] prim_c, input [63 : 0] prim_d);

    begin : testrun
      integer tc_error;
      tc_error = 0;

      tb_a      = a;
      tb_b      = b;
      tb_c      = c;
      tb_d      = d;
      tb_m0     = m0;
      tb_m1     = m1;

      #(CLK_PERIOD);
      if (tb_a_prim != prim_a)
        tc_error = tc_error + 1;

      if (tb_b_prim != prim_b)
        tc_error = tc_error + 1;

      if (tb_c_prim != prim_c)
        tc_error = tc_error + 1;

      if (tb_d_prim != prim_d)
        tc_error = tc_error + 1;

      if (tc_error > 0)
        begin
          error_ctr = error_ctr + 1;

          $display("%d Errors in test case found - dumping state:", tc_error);
          $display("tb_a_prim: %016x, expected %016x", tb_a_prim, prim_a);
          $display("tb_b_prim: %016x, expected %016x", tb_b_prim, prim_b);
          $display("tb_c_prim: %016x, expected %016x", tb_c_prim, prim_c);
          $display("tb_d_prim: %016x, expected %016x", tb_d_prim, prim_d);
        end
    end
  endtask // testrunner

  //----------------------------------------------------------------
  //----------------------------------------------------------------
  task TC1;
    begin : test_case1
      tc_ctr = tc_ctr + 1;

      $display("Starting TC1");

      testrunner(64'h6a09e667f2bdc948, 64'h510e527fade682d1,
                 64'h6a09e667f3bcc908, 64'h510e527fade68251,
                 64'h0000000000000000, 64'h0000000000000000,

                 64'hf0c9aa0de38b1b89, 64'hbbdf863401fde49b,
                 64'he85eb23c42183d3d,  64'h7111fd8b6445099d);

      $display("Stopping TC1");
    end
  endtask // TC1

  //----------------------------------------------------------------
  //----------------------------------------------------------------
  task TC2;
    begin : test_case2
      tc_ctr = tc_ctr + 1;

      $display("Starting TC2");

      testrunner(64'h6a09e667f2bd8948, 64'h510e527fade682d1,
                 64'h6a09e667f3bcc908, 64'h510e527fade68251,
                 64'h0706050403020100, 64'h0f0e0d0c0b0a0908,

                 64'hfce69820f2d7e54c, 64'h51324affb424aa90,
                 64'h032368569e359a63, 64'h8ad8f2a6176861c7);

      $display("Stopping TC2");
    end
  endtask // TC2

  //----------------------------------------------------------------
  //----------------------------------------------------------------
  task TC3;
    begin : test_case3
      tc_ctr = tc_ctr + 1;

      $display("Starting TC3");

      testrunner(64'h107e94c998ced482, 64'h28e4a60d02068f18,
                 64'h7650e70ef0a7f8cd, 64'h86570b736731f92d,
                 64'h2f2e2d2c2b2a2928, 64'h1f1e1d1c1b1a1918,

                 64'hf082ab50dd1499b7, 64'hf66d12f48baec79a,
                 64'h13e5af4bbe2d9010, 64'hfac6524cdebf33d2);

      $display("Stopping TC3");
    end
  endtask // TC3


  //----------------------------------------------------------------
  // blake2_core
  //
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : tb_blake2_G_test
      $display("*** Testbench for Blake2 G function test started");
      init_dut();

      TC1();
      TC2();
      TC3();

      display_test_result();
      $display("*** Blake2 G functions simulation done.");
      $finish;

    end // tb_blake2_G_test
endmodule // tb_blake2_G

//======================================================================
// EOF tb_blake2_G.v
//======================================================================
