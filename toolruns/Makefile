#===================================================================
#
# Makefile
# --------
# Makefile for building blake2 core and top simulation.
#
#
# (c) 2013 Joachim Strombergson
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
	@echo "sim-g:        Run G function simulation."
	@echo "sim-m_select: Run m_select module simulation."
	@echo "debug:        Print the internal varibles."
	@echo "clan:         Remove build results."

#===================================================================
# EOF Makefile
#===================================================================
