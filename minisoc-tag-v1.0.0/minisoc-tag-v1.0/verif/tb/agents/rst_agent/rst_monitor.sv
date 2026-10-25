class rst_monitor extends uvm_monitor;
    `uvm_component_utils(rst_monitor)

    virtual rst_if                    vif;
    rst_cfg                           cfg;
    uvm_analysis_port #(rst_seq_item)  ap;


    function new(string name = "rst_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(rst_cfg)::get(this, "", "cfg", cfg))
            `uvm_fatal("RST_MON", "Não foi possível obter rst_cfg do config.db")
        vif = cfg.vif;
    endfunction


    virtual task run_phase(uvm_phase phase);
        forever begin
            rst_seq_item item;


            //espera o rst_n baixar
            if(vif.rst_n !== 1'b0)
                @(negedge vif.rst_n);

            item = rst_seq_item::type_id::create("item", this);
            item.start_time_ps = $time;
            `uvm_info("RST_MON", $sformatf("Detectado inicio de rst_n em %0t ps",
                        item.start_time_ps), UVM_HIGH)


            //espera o fim do rst_n
            @(posedge vif.rst_n);
            item.end_time_ps = $time;
            item.duration_ps = item.end_time_ps - item.start_time_ps;


            `uvm_info("RST_MON", $sformatf("Fim de reset  em %0t ps (duracao=%0t ps)",
                        item.end_time_ps, item.duration_ps), UVM_MEDIUM)


            //manda o reset para o scb e cov
            ap.write(item);
        end
    endtask

endclass : rst_monitor

            

























    
            