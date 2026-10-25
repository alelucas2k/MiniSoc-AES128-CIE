class rst_agent extends uvm_agent;
    `uvm_component_utils(rst_agent)


    rst_cfg cfg;
    rst_sequencer sqr;
    rst_driver drv;
    rst_monitor mon;
    uvm_analysis_port #(rst_seq_item) ap;


    function new(string name = "rst_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(rst_cfg)::get(this, "", "cfg", cfg))
        `uvm_fatal("RST_AGT", "Nao foi possivel obter rst_cfg do config.db")

        //passar o cfg para o monitor e driver filhos
        uvm_config_db#(rst_cfg)::set(this, "*", "cfg", cfg);


        mon = rst_monitor::type_id::create("mon", this);


        if(cfg.is_active == UVM_ACTIVE) begin
            sqr = rst_sequencer::type_id::create("sqr", this);
            drv = rst_driver::type_id::create("drv", this);
        end
    endfunction


    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap = mon.ap; //analysis port do monitor
        if(cfg.is_active == UVM_ACTIVE)begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass: rst_agent