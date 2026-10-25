`ifndef RST_SMOKE_TEST_SV
`define RST_SMOKE_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import rst_agent_pkg::*;
`include "rst_smoke_seq.sv"


// testando o se o monitor pegou a transacao do ap
class rst_listener extends uvm_subscriber #(rst_seq_item);
    `uvm_component_utils(rst_listener)

    int count = 0;

    function new(string name = "rst_listener", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void write(rst_seq_item t);
        count++;
        `uvm_info("RST_LISTENER", $sformatf("monitor capturou reset #%0d. Item:", count), UVM_LOW)
        t.print();
    endfunction
endclass : rst_listener

//teste de bringup
class rst_smoke_test extends uvm_test;
    `uvm_component_utils(rst_smoke_test)

    rst_cfg cfg;
    rst_agent agt;
    rst_listener listener;

    function new(string name = "rst_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cfg = rst_cfg::type_id::create("cfg");
        if(!uvm_config_db#(virtual rst_if)::get(this, "", "rst_vif", cfg.vif))
            `uvm_fatal("TEST", "nao encontrou rst_vif no config.db")
        
        cfg.is_active = UVM_ACTIVE;
        uvm_config_db#(rst_cfg)::set(this, "agt", "cfg", cfg);

        agt = rst_agent::type_id::create("agt", this);
        listener = rst_listener::type_id::create("listener", this);
    endfunction


    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.ap.connect(listener.analysis_export);
    endfunction


    virtual task run_phase(uvm_phase phase);
        rst_smoke_seq seq;
        phase.raise_objection(this);

        seq = rst_smoke_seq::type_id::create("seq");
        seq.start(agt.sqr);


        #20ns;
        if(listener.count == 2)
            `uvm_info("TEST_PASS", "os 2 resets foram gerados pelo driver e medidos no monitor", UVM_NONE)
        else
            `uvm_error("TEST_FAIL", $sformatf("esperava 2 resets mas capturou %0d", listener.count))

        phase.drop_objection(this);
    endtask

endclass : rst_smoke_test

`endif
