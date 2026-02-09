# ========================
# QuestaSim Makefile
# ========================

VSIM = vsim
VLOG = vlog
VLIB = vlib
VMAP = vmap

WORK = work
TOP  = tb_processing_element

RTL_F = rtl.f
TB_SRC = $(TOP).sv

# Default target
run: compile simulate

# Create work library
$(WORK):
	$(VLIB) $(WORK)
	$(VMAP) $(WORK) $(WORK)

# Compile RTL + TB
compile: $(WORK)
	$(VLOG) -sv -f $(RTL_F) $(TB_SRC)

# Run simulation (batch mode)
simulate:
	$(VSIM) -c $(TOP) -do "run -all; quit"

# Run with GUI
gui:
	$(VSIM) $(TOP)

# Clean
clean:
	rm -rf $(WORK) transcript vsim.wlf *.log *.vcd

wave:
	$(VSIM) -voptargs=+acc $(TOP) -do "add wave -r sim:/tb_processing_element/*; run -all"
