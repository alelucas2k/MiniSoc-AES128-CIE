// Arquivo: verif/tb/tests/rst_smoke_test.sv
`ifndef RST_SMOKE_TEST_SV
`define RST_SMOKE_TEST_SV

`include "rst_smoke_seq.sv"

// Listener de Reset: recebe o pacote enviado pelo rst_monitor
class rst_listener extends uvm_subscriber #(rst_seq_item);
    `uvm_component_utils(rst_listener)

    int count = 0;

    function new(string name = "rst_listener", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void write(rst_seq_item t);
        count++;
        `uvm_info("RST_LISTENER", $sformatf("Monitor capturou reset #%0d. Item:", count), UVM_LOW)
        t.print();
    endfunction
endclass : rst_listener

// Listener de Clock: recebe o pacote enviado pelo clk_pll_monitor
class clk_listener extends uvm_subscriber #(clk_pll_seq_item);
    `uvm_component_utils(clk_listener)

    int count = 0;

    function new(string name = "clk_listener", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void write(clk_pll_seq_item t);
        count++;
        `uvm_info("CLK_LISTENER", $sformatf("Monitor capturou clock #%0d. Item:", count), UVM_LOW)
        t.print();
    endfunction
endclass : clk_listener


// Smoke Test Inicial (Fases P0/P1: Baseline + VIPs de Clock e Reset)
class rst_smoke_test extends uvm_test;
    `uvm_component_utils(rst_smoke_test)

    // Componentes do VIP de Reset
    rst_cfg       r_cfg;
    rst_agent     r_agt;
    rst_listener  r_list;

    // Componentes do VIP de Clock/PLL
    clk_cfg       c_cfg;
    clk_pll_agent c_agt;
    clk_listener  c_list;

    function new(string name = "rst_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Configura o Agente de Reset
        r_cfg = rst_cfg::type_id::create("r_cfg");
        if (!uvm_config_db#(virtual rst_if)::get(this, "", "rst_vif", r_cfg.vif))
            `uvm_fatal("TEST", "Nao encontrou rst_vif no uvm_config_db")
        r_cfg.is_active = UVM_ACTIVE;
        uvm_config_db#(rst_cfg)::set(this, "r_agt", "cfg", r_cfg);

        // Configura o Agente de Clock/PLL
        c_cfg = clk_cfg::type_id::create("c_cfg");
        if (!uvm_config_db#(virtual clk_pll_if)::get(this, "", "clk_vif", c_cfg.vif))
            `uvm_fatal("TEST", "Nao encontrou clk_vif no uvm_config_db")
        c_cfg.is_active = UVM_ACTIVE;
        uvm_config_db#(clk_cfg)::set(this, "c_agt", "cfg", c_cfg);

        // Instancia os Agentes e Listeners
        r_agt  = rst_agent::type_id::create("r_agt", this);
        r_list = rst_listener::type_id::create("r_list", this);

        c_agt  = clk_pll_agent::type_id::create("c_agt", this);
        c_list = clk_listener::type_id::create("c_list", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        r_agt.ap.connect(r_list.analysis_export);
        c_agt.ap.connect(c_list.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
        rst_smoke_seq seq;
        phase.raise_objection(this);

        // Executa a sequence de Reset (1 sincrono + 1 assincrono)
        seq = rst_smoke_seq::type_id::create("seq");
        seq.start(r_agt.sqr);

        #20ns;
        if (r_list.count == 2 && c_list.count == 1)
            `uvm_info("TEST_PASS", "SUCESSO! VIPs de Reset (2) e Clock (1) validados no Smoke Test!", UVM_NONE)
        else
            `uvm_error("TEST_FAIL", $sformatf("Contagem inesperada: resets=%0d, clocks=%0d",
                       r_list.count, c_list.count))

        phase.drop_objection(this);
    endtask

endclass : rst_smoke_test

`endif