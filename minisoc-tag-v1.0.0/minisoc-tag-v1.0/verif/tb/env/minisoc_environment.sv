`ifndef MINISOC_ENVIRONMENT_SV
`define MINISOC_ENVIRONMENT_SV

class minisoc_environment extends uvm_env;
    `uvm_component_utils(minisoc_environment)

    rst_agent     r_agt;
    clk_pll_agent c_agt;

    rst_listener  r_list;
    clk_listener  c_list;

    function new(string name = "minisoc_environment", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        r_agt  = rst_agent::type_id::create("r_agt", this);
        c_agt  = clk_pll_agent::type_id::create("c_agt", this);

        r_list = rst_listener::type_id::create("r_list", this);
        c_list = clk_listener::type_id::create("c_list", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        r_agt.ap.connect(r_list.analysis_export);
        c_agt.ap.connect(c_list.analysis_export);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

endclass : minisoc_environment

`endif