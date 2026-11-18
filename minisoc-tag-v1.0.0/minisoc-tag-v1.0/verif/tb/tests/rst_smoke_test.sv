`ifndef RST_SMOKE_TEST_SV
`define RST_SMOKE_TEST_SV

`include "rst_smoke_seq.sv"
`include "rst_smoke_seq.sv"
import minisoc_env_pkg::*; 

class rst_smoke_test extends uvm_test;
    `uvm_component_utils(rst_smoke_test)

    // Instância do Ambiente e Objetos de Configuração
    minisoc_environment env;
    rst_cfg             r_cfg;
    clk_cfg             c_cfg;

    function new(string name = "rst_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Configura o Agente de Reset e envia para env.r_agt
        r_cfg = rst_cfg::type_id::create("r_cfg");
        if (!uvm_config_db#(virtual rst_if)::get(this, "", "rst_vif", r_cfg.vif))
            `uvm_fatal("TEST", "Nao encontrou rst_vif no uvm_config_db")
        r_cfg.is_active = UVM_ACTIVE;
        uvm_config_db#(rst_cfg)::set(this, "env.r_agt", "cfg", r_cfg);

        // Configura o Agente de Clock/PLL e envia para env.c_agt
        c_cfg = clk_cfg::type_id::create("c_cfg");
        if (!uvm_config_db#(virtual clk_pll_if)::get(this, "", "clk_vif", c_cfg.vif))
            `uvm_fatal("TEST", "Nao encontrou clk_vif no uvm_config_db")
        c_cfg.is_active = UVM_ACTIVE;
        uvm_config_db#(clk_cfg)::set(this, "env.c_agt", "cfg", c_cfg);

        // Instancia o Ambiente
        env = minisoc_environment::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        rst_smoke_seq seq;
        phase.raise_objection(this);

        // Executa a sequence de Reset no sequencer do agente dentro do env
        seq = rst_smoke_seq::type_id::create("seq");
        seq.start(env.r_agt.sqr);

        #20ns;
        if (env.r_list.count == 2 && env.c_list.count != 0)
            `uvm_info("TEST_PASS", "SUCESSO! VIPs de Reset (2) e Clock (1) validados no Smoke Test!", UVM_NONE)
        else
            `uvm_error("TEST_FAIL", $sformatf("Contagem inesperada: resets=%0d, clocks=%0d",
                       env.r_list.count, env.c_list.count))

        phase.drop_objection(this);
    endtask

endclass : rst_smoke_test

`endif