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

SRC_DIR = ../src/rtl
TB_SRC_DIR = ../src/tb

M_SELECT_SRC = $(SRC_DIR)/blake2_m_select.v
G_SRC = $(SRC_DIR)/blake2_G.v
CORE_SRC = $(SRC_DIR)/blake2_core.v $(SRC_DIR)/blake2_m_select.v $(SRC_DIR)/blake2_G.v
TOP_SRC = $(SRC_DIR)/blake2.v $(CORE_SRC)

TB_TOP_SRC = $(TB_SRC_DIR)/tb_blake2.v
TB_CORE_SRC = $(TB_SRC_DIR)/tb_blake2_core.v
TB_G_SRC = $(TB_SRC_DIR)/tb_blake2_G.v
TB_M_SELECT_SRC = $(TB_SRC_DIR)/tb_blake2_m_select.v

CC = iverilog
CC_FLAGS = -Wall

LINT= verilator
LINT_FLAGS = +1364-2001ext+ --lint-only  -Wall -Wno-fatal -Wno-DECLFILENAME

TARGETS = top.sim core.sim g.sim m_select.sim


all: $(TARGETS)


top.sim: $(TB_TOP_SRC) $(TOP_SRC)
	$(CC) $(CC_FLAGS) -o top.sim $(TB_TOP_SRC) $(TOP_SRC)


core.sim:  $(TB_CORE_SRC) $(CORE_SRC)
	$(CC) $(CC_FLAGS) -o core.sim $(TB_CORE_SRC) $(CORE_SRC)


g.sim:  $(TB_G_SRC) $(G_SRC)
	$(CC) $(CC_FLAGS) -o g.sim $(TB_G_SRC) $(G_SRC)


m_select.sim:  $(TB_M_SELECT_SRC) $(M_SELECT_SRC)
	$(CC) $(CC_FLAGS) -o m_select.sim $(TB_M_SELECT_SRC) $(M_SELECT_SRC)


lint: $(TOP_SRC)
	$(LINT) $(LINT_FLAGS) $(TOP_SRC)


clean:
	rm -f *.sim


help:
	@echo "Supported targets:"
	@echo "------------------"
	@echo "all:          Build all simulation targets."
	@echo "lint:         Run the linter on the source."
	@echo "clean:        Remove build results."

#===================================================================
# EOF Makefile
#===================================================================
