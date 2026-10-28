class clk_pll_agent extends uvm_agent;
    `uvm_component_utils(clk_pll_agent)

    clk_cfg cfg;
    clk_pll_sequencer sqr;
    clk_pll_driver drv;
    clk_pll_monitor mon;
    uvm_analysis_port #(clk_pll_seq_item) ap;

    function new(string name = "clk_pll_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(clk_cfg)::get(this, "", "cfg", cfg))
            `uvm_fatal("CLK_AGT", "Nao foi possivel obter clk_cfg do config.db")

        uvm_config_db#(clk_cfg)::set(this, "*", "cfg", cfg);

        mon = clk_pll_monitor::type_id::create("mon", this);

        if(cfg.is_active == UVM_ACTIVE)begin
            sqr = clk_pll_sequencer::type_id::create("sqr", this);
            drv = clk_pll_driver::type_id::create("drv", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap = mon.ap;
        if(cfg.is_active == UVM_ACTIVE)begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass: clk_pll_agent