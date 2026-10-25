# Arquivo: verif/tb/Makefile
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
	+incdir+./agents/rst_agent \
	+incdir+./sequences        \
	+incdir+./tests

TB_FILES = \
	./agents/rst_agent/rst_if.sv        \
	./agents/rst_agent/rst_agent_pkg.sv \
	./top_tb.sv

VCS_FLAGS = -full64 -sverilog -ntb_opts uvm-1.2 -kdb -debug_access+all \
            +ntb_random_seed=random -timescale=1ps/1ps -l vcs_uvm.log

vcs_comp:
	vcs $(VCS_FLAGS) $(INCDIRS) $(MINISOC_RTL) $(TB_FILES)

vcs_run:
	./simv +UVM_VERBOSITY=UVM_MEDIUM

# Abre a simulação de forma interativa na GUI (Verdi ou DVE)
vcs_gui:
	./simv -gui &

# Abre o arquivo de ondas salvo diretamente no Verdi usando a base KDB compilada
verdi:
	verdi -dbdir ./simv.daidir -ssf minisoc_waves.fsdb &

# Abre o arquivo de ondas VPD no DVE
dve:
	dve -vpd minisoc_waves.vpd &

clean:
	rm -rf csrc simv.daidir *.log
	rm -rf simv ucli.key *.vpd verdiLog *.fsdb novas.*