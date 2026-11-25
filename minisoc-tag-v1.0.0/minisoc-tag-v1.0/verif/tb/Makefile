RTL_DIR = ../../frontend/rtl

MINISOC_RTL = \
	$(RTL_DIR)/minisoc_aes/minisoc_aes_key_exp.sv \
	$(RTL_DIR)/minisoc_aes/minisoc_aes_dp.sv      \
	$(RTL_DIR)/minisoc_aes/minisoc_aes_top.sv     \
	$(RTL_DIR)/minisoc_mem/minisoc_memory.sv      \
	$(RTL_DIR)/minisoc_pll/minisoc_pll_mock.sv    \
	$(RTL_DIR)/minisoc_spi/minisoc_spi.sv         \
	$(RTL_DIR)/minisoc_top.sv

INCDIRS = \
	+incdir+./agents/rst_agent     \
	+incdir+./agents/clk_pll_agent \
	+incdir+./agents/spi_agent     \
	+incdir+./agents/mem_agent     \
	+incdir+./env 				\
	+incdir+./sequences            \
	+incdir+./tests

TB_FILES = \
	./agents/rst_agent/rst_if.sv                 \
	./agents/rst_agent/rst_agent_pkg.sv          \
	./agents/clk_pll_agent/clk_pll_if.sv         \
	./agents/clk_pll_agent/clk_pll_agent_pkg.sv  \
	./agents/spi_agent/spi_if.sv                 \
	./agents/spi_agent/spi_agent_pkg.sv          \
	./agents/mem_agent/mem_if.sv                 \
	./agents/mem_agent/mem_agent_pkg.sv          \
	./env/minisoc_env_pkg.sv 					\
	./top_tb.sv

VCS_FLAGS = -full64 -sverilog -ntb_opts uvm-1.2 -kdb -debug_access+all \
            +ntb_random_seed=random -xlrm floating_pnt_constraint -timescale=1ps/1ps -l vcs_uvm.log

comp:
	vcs $(VCS_FLAGS) $(INCDIRS) $(MINISOC_RTL) $(TB_FILES)

run:
	./simv +UVM_VERBOSITY=UVM_MEDIUM

# Smoke tests individuais (selecionados por +UVM_TESTNAME)
run_rst_smoke:
	./simv +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=rst_smoke_test

run_spi_smoke:
	./simv +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=spi_smoke_test

run_mem_smoke:
	./simv +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=mem_smoke_test

run_dut_cfg:
	./simv +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=dut_cfg_test +WAVE=dut_cfg -l dut_cfg_test.log
	
# Abre a simulação de forma interativa na GUI (Verdi ou DVE)
gui:
	./simv -gui -verdi_opts "-sswr signal.rc" &

# Abre o arquivo de ondas salvo diretamente no Verdi usando a base KDB compilada
verdi:
	verdi -dbdir ./simv.daidir -ssf minisoc_waves.fsdb -sswr signal.rc &

# Abre o arquivo de ondas VPD no DVE
dve:
	dve -vpd minisoc_waves.vpd &

clean:
	rm -rf csrc simv.daidir *.log
	rm -rf simv ucli.key *.vpd verdiLog *.fsdb novas.*
