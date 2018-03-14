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

  reg            tb_display_state;

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
  // inc_tc_ctr()
  //----------------------------------------------------------------
  task inc_tc_ctr;
    begin
      tc_ctr = tc_ctr + 1;
    end
  endtask // inc_tc_ctr


  //----------------------------------------------------------------
  // inc_error_ctr()
  //----------------------------------------------------------------
  task inc_error_ctr;
    begin
      error_ctr = error_ctr + 1;
    end
  endtask // inc_error_ctr


  //----------------------------------------------------------------
  // enable_display_state()
  //----------------------------------------------------------------
  task enable_display_state;
    begin
      tb_display_state = 1;
    end
  endtask // enable_display_state


  //----------------------------------------------------------------
  // disable_display_state()
  //----------------------------------------------------------------
  task disable_display_state;
    begin
      tb_display_state = 0;
    end
  endtask // disable_display_state


  //----------------------------------------------------------------
  // sys_monitor()
  //
  // An always running process that creates a cycle counter and
  // conditionally displays information about the DUT.
  //----------------------------------------------------------------
  always
    begin : sys_monitor
      cycle_ctr = cycle_ctr + 1;
      #(CLK_PERIOD);
      if (tb_display_state)
        begin
          dump_dut_state();
        end
    end


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
  // dump_dut_state()
  //----------------------------------------------------------------
  task dump_dut_state;
    begin
      $display("Counters and control state::");
      $display("blake2_ctrl_reg = 0x%02x  round_ctr_reg = 0x%02x  ready = 0x%01x  valid = 0x%01x",
               dut.blake2_ctrl_reg, dut.round_ctr_reg, tb_ready, tb_digest_valid);
      $display("");

      $display("Chaining value:");
      $display("h[0] = 0x%016x  h[1] = 0x%016x  h[2] = 0x%016x  h[3] = 0x%016x",
               dut.h_reg[0], dut.h_reg[1], dut.h_reg[2], dut.h_reg[3]);
      $display("h[4] = 0x%016x  h[5] = 0x%016x  h[6] = 0x%016x  h[7] = 0x%016x",
               dut.h_reg[4], dut.h_reg[5], dut.h_reg[6], dut.h_reg[7]);
      $display("");

      $display("Internal state:");
      $display("v[00] = 0x%016x  v[01] = 0x%016x  v[02] = 0x%016x  v[03] = 0x%016x",
               dut.v_reg[0], dut.v_reg[1], dut.v_reg[2], dut.v_reg[3]);
      $display("v[04] = 0x%016x  v[05] = 0x%016x  v[06] = 0x%016x  v[07] = 0x%016x",
               dut.v_reg[4], dut.v_reg[5], dut.v_reg[6], dut.v_reg[7]);
      $display("v[08] = 0x%016x  v[09] = 0x%016x  v[10] = 0x%016x  v[11] = 0x%016x",
               dut.v_reg[8], dut.v_reg[9], dut.v_reg[10], dut.v_reg[11]);
      $display("v[12] = 0x%016x  v[13] = 0x%016x  v[14] = 0x%016x  v[15] = 0x%016x",
               dut.v_reg[12], dut.v_reg[13], dut.v_reg[14], dut.v_reg[15]);
      $display("");

      $display("Message block:");
      $display("m[00] = 0x%016x  m[01] = 0x%016x  m[02] = 0x%016x  m[03] = 0x%016x",
               dut.mselect.m_reg[0], dut.mselect.m_reg[1],
               dut.mselect.m_reg[2], dut.mselect.m_reg[3]);
      $display("m[04] = 0x%016x  m[05] = 0x%016x  m[06] = 0x%016x  m[07] = 0x%016x",
               dut.mselect.m_reg[4], dut.mselect.m_reg[5],
               dut.mselect.m_reg[6], dut.mselect.m_reg[7]);
      $display("m[08] = 0x%016x  m[09] = 0x%016x  m[10] = 0x%016x  m[11] = 0x%016x",
               dut.mselect.m_reg[8], dut.mselect.m_reg[9],
               dut.mselect.m_reg[10], dut.mselect.m_reg[11]);
      $display("m[12] = 0x%016x  m[13] = 0x%016x  m[14] = 0x%016x  m[15] = 0x%016x",
               dut.mselect.m_reg[12], dut.mselect.m_reg[13],
               dut.mselect.m_reg[14], dut.mselect.m_reg[15]);
      $display("");
    end
  endtask // dump_state


  //----------------------------------------------------------------
  // init()
  //
  // Set the input to the DUT to defined values.
  //----------------------------------------------------------------
  task init;
    begin
      cycle_ctr        = 0;
      error_ctr        = 0;
      tc_ctr           = 0;
      tb_clk           = 0;
      tb_reset_n       = 1;
      tb_display_state = 0;
      tb_init          = 0;
      tb_next_block    = 0;
      tb_final_block   = 0;
      tb_key_len       = 8'h0;
      tb_digest_len    = 8'h0;
      tb_block         = 1024'h0;
    end
  endtask // init


  //----------------------------------------------------------------
  // test_rfc
  // Single block test with the message "abc" as described in
  // RFC 6793, Appendix A.
  //----------------------------------------------------------------
  task test_rfc;
    begin
      $display("*** TEST_RFC started.");
      inc_tc_ctr();
      enable_display_state();

      tb_key_len       = 8'h0;
      tb_digest_len    = 8'h40;
      tb_init          = 1;
      #(2 * CLK_PERIOD);
      tb_init          = 0;

      tb_block         = {24'h616263, 1000'h0};
      tb_next_block    = 1;
      tb_final_block   = 1;
      #(2 * CLK_PERIOD);
      tb_next_block    = 0;
      tb_final_block   = 0;

      #(100 * CLK_PERIOD);

      disable_display_state();
      $display("*** TEST_RFC done.");
    end
  endtask // test_wiki


  //----------------------------------------------------------------
  // test_core_init
  //
  // Verify that the chaining vector is correctly initialized
  // based on given key and digest sizes.
  //----------------------------------------------------------------
  task test_core_init;
    begin : test_init
      integer errors;
      errors = 0;

      $display("*** TEST_CORE_INIT started. This should initialize the h_regs.");
      inc_tc_ctr();
      enable_display_state();

      tb_key_len    = 8'h0;
      tb_digest_len = 8'h40;
      tb_display_state = 1;
      tb_init       = 1;

      #(2 * CLK_PERIOD);
      tb_init       = 0;

      #(2 * CLK_PERIOD);

      if (dut.h_reg[0] != 64'h6a09e667f2bdc948)
        errors = errors + 1;
      if (dut.h_reg[1] != 64'hbb67ae8584caa73b)
        errors = errors + 1;
      if (dut.h_reg[2] != 64'h3c6ef372fe94f82b)
        errors = errors + 1;
      if (dut.h_reg[3] != 64'ha54ff53a5f1d36f1)
        errors = errors + 1;
      if (dut.h_reg[4] != 64'h510e527fade682d1)
        errors = errors + 1;
      if (dut.h_reg[5] != 64'h9b05688c2b3e6c1f)
        errors = errors + 1;
      if (dut.h_reg[6] != 64'h1f83d9abfb41bd6b)
        errors = errors + 1;
      if (dut.h_reg[7] != 64'h5be0cd19137e2179)
        errors = errors + 1;

      if (errors > 0)
        begin
          inc_error_ctr();
          $display("*** TEST_CORE_INIT: ERROR. %01d values are wrong.", errors);
        end

      disable_display_state();
      $display("*** TEST_CORE_INIT done.");
    end
  endtask // test_core_init


  //----------------------------------------------------------------
  // blake2_core_test
  //----------------------------------------------------------------
  initial
    begin : blake2_core_test
      $display("*** Testbench for blake2_core started.");
      init();

      reset_dut();
//      test_core_init();
      test_rfc();

      display_test_result();
      $display("*** blake2_core simulation done.");
      $finish_and_return(error_ctr);
    end // blake2_core_test
endmodule // tb_blake2_core

//======================================================================
// EOF tb_blake2_core.v
//======================================================================
