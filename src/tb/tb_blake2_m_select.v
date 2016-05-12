//======================================================================
//
// tb_blake2_m_select.v
// --------------------
// Testbench for the Blake2 m word select module.
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

module tb_blake2_m_select();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG = 0;


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

  reg            tb_load;
  reg [1023 : 0] tb_m;
  reg            tb_state;
  reg [3 : 0]    tb_r;
  wire [63 : 0]  tb_G0_m0;
  wire [63 : 0]  tb_G0_m1;
  wire [63 : 0]  tb_G1_m0;
  wire [63 : 0]  tb_G1_m1;
  wire [63 : 0]  tb_G2_m0;
  wire [63 : 0]  tb_G2_m1;
  wire [63 : 0]  tb_G3_m0;
  wire [63 : 0]  tb_G3_m1;

  reg            display_cycle_ctr;


  //----------------------------------------------------------------
  // blake2_m_select device under test.
  //----------------------------------------------------------------
  blake2_m_select dut(
                      .clk(tb_clk),
                      .reset_n(tb_reset_n),
                      .load(tb_load),
                      .m(tb_m),
                      .r(tb_r),
                      .state(tb_state),
                      .G0_m0(tb_G0_m0),
                      .G0_m1(tb_G0_m1),
                      .G1_m0(tb_G1_m0),
                      .G1_m1(tb_G1_m1),
                      .G2_m0(tb_G2_m0),
                      .G2_m1(tb_G2_m1),
                      .G3_m0(tb_G3_m0),
                      .G3_m1(tb_G3_m1)
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
  // dump_dut_state
  //
  // Dump the internal state of the dut to std out.
  //----------------------------------------------------------------
  task dump_dut_state;
    begin
      $display("");
      $display("DUT internal state");
      $display("------------------");
      $display("Inputs:");
      $display("load = 0x%01x, r = 0x%02x, state = 0x%01x",
               dut.load, dut.r, dut.state);
      $display("m[1023 : 0768] = 0x%064x", dut.m[1023 : 0768]);
      $display("m[0767 : 0512] = 0x%064x", dut.m[0767 : 0512]);
      $display("m[0511 : 0256] = 0x%064x", dut.m[0511 : 0256]);
      $display("m[0255 : 0000] = 0x%064x", dut.m[0255 : 0000]);
      $display("");

      $display("M memory:");
      $display("m_mem[00] = 0x%016x", dut.m_mem[00]);
      $display("m_mem[01] = 0x%016x", dut.m_mem[01]);
      $display("m_mem[02] = 0x%016x", dut.m_mem[02]);
      $display("m_mem[03] = 0x%016x", dut.m_mem[03]);
      $display("m_mem[04] = 0x%016x", dut.m_mem[04]);
      $display("m_mem[05] = 0x%016x", dut.m_mem[05]);
      $display("m_mem[06] = 0x%016x", dut.m_mem[06]);
      $display("m_mem[07] = 0x%016x", dut.m_mem[07]);
      $display("m_mem[08] = 0x%016x", dut.m_mem[08]);
      $display("m_mem[09] = 0x%016x", dut.m_mem[09]);
      $display("m_mem[10] = 0x%016x", dut.m_mem[10]);
      $display("m_mem[11] = 0x%016x", dut.m_mem[11]);
      $display("m_mem[12] = 0x%016x", dut.m_mem[12]);
      $display("m_mem[13] = 0x%016x", dut.m_mem[13]);
      $display("m_mem[14] = 0x%016x", dut.m_mem[14]);
      $display("m_mem[15] = 0x%016x", dut.m_mem[15]);
      $display("");

      $display("Outputs:");
      $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x",
               dut.G0_m0, dut.G0_m1);
      $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x",
               dut.G1_m0, dut.G1_m1);
      $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x",
               dut.G2_m0, dut.G2_m1);
      $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x",
               dut.G3_m0, dut.G3_m1);
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
      cycle_ctr  = 0;
      error_ctr  = 0;
      tc_ctr     = 0;
      tb_clk     = 0;
      tb_reset_n = 0;
      tb_load    = 0;
      tb_m       = {64'h000000000f0f0f0f, 64'h000000000e0e0e0e, 64'h000000000d0d0d0d, 64'h000000000c0c0c0c,
                    64'h000000000b0b0b0b, 64'h000000000a0a0a0a, 64'h0000000009090909, 64'h0000000008080808,
                    64'h0000000007070707, 64'h0000000006060606, 64'h0000000005050505, 64'h0000000004040404,
                    64'h0000000003030303, 64'h0000000002020202, 64'h0000000001010101, 64'h0000000000000000};
      tb_state   = 0;
      tb_r       = 4'h0;
    end
  endtask // init_dut


  //----------------------------------------------------------------
  // blake2_m_select
  //
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : blake2_m_select_test
      $display("   -- Testbench for blake2 m select module started --");

      $display("State before reset:");
      dump_dut_state();

      init_dut();
      reset_dut();

      $display("State at init after reset:");
      dump_dut_state();

      tb_load = 1;
      #(CLK_PERIOD);
      tb_load = 0;

      $display("State after load:");
      dump_dut_state();

      tb_r = 00; tb_state = 0;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0f0f0f0f00000000 && dut.G0_m1 == 64'h0e0e0e0e00000000 |
          dut.G1_m0 == 64'h0d0d0d0d00000000 && dut.G1_m1 == 64'h0c0c0c0c00000000 |
          dut.G2_m0 == 64'h0b0b0b0b00000000 && dut.G2_m1 == 64'h0a0a0a0a00000000 |
          dut.G3_m0 == 64'h0909090900000000 && dut.G3_m1 == 64'h0808080800000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 00; tb_state = 1;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0707070700000000 && dut.G0_m1 == 64'h0606060600000000 |
          dut.G1_m0 == 64'h0505050500000000 && dut.G1_m1 == 64'h0404040400000000 |
          dut.G2_m0 == 64'h0303030300000000 && dut.G2_m1 == 64'h0202020200000000 |
          dut.G3_m0 == 64'h0101010100000000 && dut.G3_m1 == 64'h0000000000000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 01; tb_state = 0;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0101010100000000 && dut.G0_m1 == 64'h0505050500000000 |
          dut.G1_m0 == 64'h0b0b0b0b00000000 && dut.G1_m1 == 64'h0707070700000000 |
          dut.G2_m0 == 64'h0606060600000000 && dut.G2_m1 == 64'h0000000000000000 |
          dut.G3_m0 == 64'h0202020200000000 && dut.G3_m1 == 64'h0909090900000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 01; tb_state = 1;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0e0e0e0e00000000 && dut.G0_m1 == 64'h0303030300000000 |
          dut.G1_m0 == 64'h0f0f0f0f00000000 && dut.G1_m1 == 64'h0d0d0d0d00000000 |
          dut.G2_m0 == 64'h0404040400000000 && dut.G2_m1 == 64'h0808080800000000 |
          dut.G3_m0 == 64'h0a0a0a0a00000000 && dut.G3_m1 == 64'h0c0c0c0c00000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 02; tb_state = 0;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0404040400000000 && dut.G0_m1 == 64'h0707070700000000 |
          dut.G1_m0 == 64'h0303030300000000 && dut.G1_m1 == 64'h0f0f0f0f00000000 |
          dut.G2_m0 == 64'h0a0a0a0a00000000 && dut.G2_m1 == 64'h0d0d0d0d00000000 |
          dut.G3_m0 == 64'h0000000000000000 && dut.G3_m1 == 64'h0202020200000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 02; tb_state = 1;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0505050500000000 && dut.G0_m1 == 64'h0101010100000000 |
          dut.G1_m0 == 64'h0c0c0c0c00000000 && dut.G1_m1 == 64'h0909090900000000 |
          dut.G2_m0 == 64'h0808080800000000 && dut.G2_m1 == 64'h0e0e0e0e00000000 |
          dut.G3_m0 == 64'h0606060600000000 && dut.G3_m1 == 64'h0b0b0b0b00000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 03; tb_state = 0;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0808080800000000 && dut.G0_m1 == 64'h0606060600000000 |
          dut.G1_m0 == 64'h0c0c0c0c00000000 && dut.G1_m1 == 64'h0e0e0e0e00000000 |
          dut.G2_m0 == 64'h0202020200000000 && dut.G2_m1 == 64'h0303030300000000 |
          dut.G3_m0 == 64'h0404040400000000 && dut.G3_m1 == 64'h0101010100000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 03; tb_state = 1;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0d0d0d0d00000000 && dut.G0_m1 == 64'h0909090900000000 |
          dut.G1_m0 == 64'h0a0a0a0a00000000 && dut.G1_m1 == 64'h0505050500000000 |
          dut.G2_m0 == 64'h0b0b0b0b00000000 && dut.G2_m1 == 64'h0f0f0f0f00000000 |
          dut.G3_m0 == 64'h0000000000000000 && dut.G3_m1 == 64'h0707070700000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 04; tb_state = 0;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0606060600000000 && dut.G0_m1 == 64'h0f0f0f0f00000000 |
          dut.G1_m0 == 64'h0a0a0a0a00000000 && dut.G1_m1 == 64'h0808080800000000 |
          dut.G2_m0 == 64'h0d0d0d0d00000000 && dut.G2_m1 == 64'h0b0b0b0b00000000 |
          dut.G3_m0 == 64'h0505050500000000 && dut.G3_m1 == 64'h0000000000000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 04; tb_state = 1;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0101010100000000 && dut.G0_m1 == 64'h0e0e0e0e00000000 |
          dut.G1_m0 == 64'h0404040400000000 && dut.G1_m1 == 64'h0303030300000000 |
          dut.G2_m0 == 64'h0909090900000000 && dut.G2_m1 == 64'h0707070700000000 |
          dut.G3_m0 == 64'h0c0c0c0c00000000 && dut.G3_m1 == 64'h0202020200000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 05; tb_state = 0;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0d0d0d0d00000000 && dut.G0_m1 == 64'h0303030300000000 |
          dut.G1_m0 == 64'h0909090900000000 && dut.G1_m1 == 64'h0505050500000000 |
          dut.G2_m0 == 64'h0f0f0f0f00000000 && dut.G2_m1 == 64'h0404040400000000 |
          dut.G3_m0 == 64'h0707070700000000 && dut.G3_m1 == 64'h0c0c0c0c00000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 05; tb_state = 1;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0b0b0b0b00000000 && dut.G0_m1 == 64'h0202020200000000 |
          dut.G1_m0 == 64'h0808080800000000 && dut.G1_m1 == 64'h0a0a0a0a00000000 |
          dut.G2_m0 == 64'h0000000000000000 && dut.G2_m1 == 64'h0101010100000000 |
          dut.G3_m0 == 64'h0e0e0e0e00000000 && dut.G3_m1 == 64'h0606060600000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 06; tb_state = 0;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0303030300000000 && dut.G0_m1 == 64'h0a0a0a0a00000000 |
          dut.G1_m0 == 64'h0e0e0e0e00000000 && dut.G1_m1 == 64'h0000000000000000 |
          dut.G2_m0 == 64'h0101010100000000 && dut.G2_m1 == 64'h0202020200000000 |
          dut.G3_m0 == 64'h0b0b0b0b00000000 && dut.G3_m1 == 64'h0505050500000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 06; tb_state = 1;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0f0f0f0f00000000 && dut.G0_m1 == 64'h0808080800000000 |
          dut.G1_m0 == 64'h0909090900000000 && dut.G1_m1 == 64'h0c0c0c0c00000000 |
          dut.G2_m0 == 64'h0606060600000000 && dut.G2_m1 == 64'h0d0d0d0d00000000 |
          dut.G3_m0 == 64'h0707070700000000 && dut.G3_m1 == 64'h0404040400000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 07; tb_state = 0;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0202020200000000 && dut.G0_m1 == 64'h0404040400000000 |
          dut.G1_m0 == 64'h0808080800000000 && dut.G1_m1 == 64'h0101010100000000 |
          dut.G2_m0 == 64'h0303030300000000 && dut.G2_m1 == 64'h0e0e0e0e00000000 |
          dut.G3_m0 == 64'h0c0c0c0c00000000 && dut.G3_m1 == 64'h0606060600000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 07; tb_state = 1;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0a0a0a0a00000000 && dut.G0_m1 == 64'h0f0f0f0f00000000 |
          dut.G1_m0 == 64'h0000000000000000 && dut.G1_m1 == 64'h0b0b0b0b00000000 |
          dut.G2_m0 == 64'h0707070700000000 && dut.G2_m1 == 64'h0909090900000000 |
          dut.G3_m0 == 64'h0d0d0d0d00000000 && dut.G3_m1 == 64'h0505050500000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 08; tb_state = 0;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0909090900000000 && dut.G0_m1 == 64'h0000000000000000 |
          dut.G1_m0 == 64'h0101010100000000 && dut.G1_m1 == 64'h0606060600000000 |
          dut.G2_m0 == 64'h0404040400000000 && dut.G2_m1 == 64'h0c0c0c0c00000000 |
          dut.G3_m0 == 64'h0f0f0f0f00000000 && dut.G3_m1 == 64'h0707070700000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 08; tb_state = 1;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0303030300000000 && dut.G0_m1 == 64'h0d0d0d0d00000000 |
          dut.G1_m0 == 64'h0202020200000000 && dut.G1_m1 == 64'h0808080800000000 |
          dut.G2_m0 == 64'h0e0e0e0e00000000 && dut.G2_m1 == 64'h0b0b0b0b00000000 |
          dut.G3_m0 == 64'h0505050500000000 && dut.G3_m1 == 64'h0a0a0a0a00000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 09; tb_state = 0;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0505050500000000 && dut.G0_m1 == 64'h0d0d0d0d00000000 |
          dut.G1_m0 == 64'h0707070700000000 && dut.G1_m1 == 64'h0b0b0b0b00000000 |
          dut.G2_m0 == 64'h0808080800000000 && dut.G2_m1 == 64'h0909090900000000 |
          dut.G3_m0 == 64'h0e0e0e0e00000000 && dut.G3_m1 == 64'h0a0a0a0a00000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 09; tb_state = 1;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0000000000000000 && dut.G0_m1 == 64'h0404040400000000 |
          dut.G1_m0 == 64'h0606060600000000 && dut.G1_m1 == 64'h0101010100000000 |
          dut.G2_m0 == 64'h0c0c0c0c00000000 && dut.G2_m1 == 64'h0303030300000000 |
          dut.G3_m0 == 64'h0202020200000000 && dut.G3_m1 == 64'h0f0f0f0f00000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 10; tb_state = 0;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0f0f0f0f00000000 && dut.G0_m1 == 64'h0e0e0e0e00000000 |
          dut.G1_m0 == 64'h0d0d0d0d00000000 && dut.G1_m1 == 64'h0c0c0c0c00000000 |
          dut.G2_m0 == 64'h0b0b0b0b00000000 && dut.G2_m1 == 64'h0a0a0a0a00000000 |
          dut.G3_m0 == 64'h0909090900000000 && dut.G3_m1 == 64'h0808080800000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 10; tb_state = 1;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0707070700000000 && dut.G0_m1 == 64'h0606060600000000 |
          dut.G1_m0 == 64'h0505050500000000 && dut.G1_m1 == 64'h0404040400000000 |
          dut.G2_m0 == 64'h0303030300000000 && dut.G2_m1 == 64'h0202020200000000 |
          dut.G3_m0 == 64'h0101010100000000 && dut.G3_m1 == 64'h0000000000000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 11; tb_state = 0;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0101010100000000 && dut.G0_m1 == 64'h0505050500000000 |
          dut.G1_m0 == 64'h0b0b0b0b00000000 && dut.G1_m1 == 64'h0707070700000000 |
          dut.G2_m0 == 64'h0606060600000000 && dut.G2_m1 == 64'h0000000000000000 |
          dut.G3_m0 == 64'h0202020200000000 && dut.G3_m1 == 64'h0909090900000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      tb_r = 11; tb_state = 1;
      #(CLK_PERIOD);
      if (dut.G0_m0 == 64'h0e0e0e0e00000000 && dut.G0_m1 == 64'h0303030300000000 |
          dut.G1_m0 == 64'h0f0f0f0f00000000 && dut.G1_m1 == 64'h0d0d0d0d00000000 |
          dut.G2_m0 == 64'h0404040400000000 && dut.G2_m1 == 64'h0808080800000000 |
          dut.G3_m0 == 64'h0a0a0a0a00000000 && dut.G3_m1 == 64'h0c0c0c0c00000000)
        tc_ctr = tc_ctr + 1;
      else
        begin
          error_ctr = error_ctr + 1;
          $display("Failed test: tb_r = %02d, tb_state = %d", tb_r, tb_state);
          $display("G0_m0 = 0x%016x, G0_m1 = 0x%016x", dut.G0_m0, dut.G0_m1);
          $display("G1_m0 = 0x%016x, G1_m1 = 0x%016x", dut.G1_m0, dut.G1_m1);
          $display("G2_m0 = 0x%016x, G2_m1 = 0x%016x", dut.G2_m0, dut.G2_m1);
          $display("G3_m0 = 0x%016x, G3_m1 = 0x%016x", dut.G3_m0, dut.G3_m1);
        end

      display_test_result();
      $display("*** blake2 m select simulation done.");
      $finish_and_return(error_ctr);
    end // blake2_m_select_test
endmodule // tb_blake2_m_select

//======================================================================
// EOF tb_blake2_m_select.v
//======================================================================
