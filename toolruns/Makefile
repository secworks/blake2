#===================================================================
#
# Makefile
# --------
# Makefile for building blake2 sub module, core and
# top simulations.
#
#
# Author: Joachim Strömbergson
# Copyright (c) 2014, Secworks Sweden AB
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#===================================================================

G_SRC=../src/rtl/blake2_G.v
G_TB_SRC=../src/tb/tb_blake2_G.v

M_SELECT_SRC=../src/rtl/blake2_m_select.v
M_SELECT_TB_SRC=../src/tb/tb_blake2_m_select.v

CORE_SRC=../src/rtl/blake2_core.v ../src/rtl/blake2_G.v ../src/rtl/blake2_m_select.v
CORE_TB_SRC=../src/tb/tb_blake2_core.v

TOP_SRC=../src/rtl/blake2.v $(CORE_SRC)
TOP_TB_SRC=../src/tb/tb_blake2.v

CC=iverilog


all: top core G m_select


top: $(TOP_TB_SRC) $(TOP_SRC)
	$(CC) -o top.sim $(TOP_TB_SRC) $(TOP_SRC)


core: $(CORE_TB_SRC) $(CORE_SRC)
	$(CC) -o core.sim $(CORE_SRC) $(CORE_TB_SRC)


G: $(G_TB_SRC) $(G_SRC)
	$(CC) -o G.sim $(G_SRC) $(G_TB_SRC)


m_select: $(M_SELECT_TB_SRC) $(M_SELECT_SRC)
	$(CC) -o m_select.sim $(M_SELECT_SRC) $(M_SELECT_TB_SRC)


sim-top: top.sim
	./top.sim


sim-core: core.sim
	./core.sim


sim-G: G.sim
	./G.sim


sim-m_select: m_select.sim
	./m_select.sim


debug:
	@echo "Variables:"
	@echo "----------"


clean:
	rm -f top.sim
	rm -f core.sim
	rm -f G.sim
	rm -f m_select.sim


help:
	@echo "Supported targets:"
	@echo "------------------"
	@echo "all:          Build all simulation targets."
	@echo "top:          Build the top simulation target."
	@echo "core:         Build the top simulation target."
	@echo "sim-top:      Run top level simulation."
	@echo "sim-core:     Run core level simulation."
	@echo "sim-G:        Run G function simulation."
	@echo "sim-m_select: Run m_select module simulation."
	@echo "debug:        Print the internal varibles."
	@echo "clean:        Remove build results."

#===================================================================
# EOF Makefile
#===================================================================
