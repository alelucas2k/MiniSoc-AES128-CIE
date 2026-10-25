class rst_driver extends uvm_driver #(rst_seq_item);
    `uvm_component_utils(rst_driver)

    virtual rst_if vif;
    rst_cfg        cfg;

    function new(string name = "rst_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(rst_cfg)::get(this, "", "cfg", cfg))
            `uvm_fatal("RST_DRV", "Não foi possível obter rst_cfg do config.db")
        vif = cfg.vif;
    endfunction


    virtual task run_phase(uvm_phase phase);
        //estado inicial no tempo 0
        vif.rst_n <= 1'b1;

        forever begin
            seq_item_port.get_next_item(req);
            drive_reset(req);
            seq_item_port.item_done();
        end
    endtask


    virtual task drive_reset(rst_seq_item item);

        //espera alguns ciclos antes de ativar o reset
        repeat(item.cycles_before_assert) @(posedge vif.clk);


        //deslocar a borda ativa do clock 
        //para teste de reset assíncrono
        if(!item.sync_to_clk)begin
            #(item.async_delay_ps * 1ps);
        end

        //ativar o reset
        `uvm_info("RST_DRV", $sformatf("Ativando rst_n=0 por %0d ciclos (sync=%0b)", 
                                        item.assert_duration_cycles, item.sync_to_clk), UVM_MEDIUM)
        vif.rst_n <= 1'b0;


        //manter rst_n = 0 por x tempo
        repeat(item. assert_duration_cycles) @(posedge vif.clk);


        //liberar o reset na borda do clock
        vif.rst_n <= 1'b1;
        `uvm_info("RST_DRV", "Reset liberado!", UVM_MEDIUM);


        //tempo de estabilização dps de reset
        repeat(item.cycles_after_deassert) @(posedge vif.clk);
    endtask

endclass : rst_driver