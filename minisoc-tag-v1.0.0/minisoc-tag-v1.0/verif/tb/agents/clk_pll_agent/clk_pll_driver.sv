class clk_pll_driver extends uvm_driver #(clk_pll_seq_item);
    `uvm_component_utils(clk_pll_driver)

    virtual clk_pll_if vif;
    clk_cfg cfg;

    function new(string name = "clk_pll_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(clk_cfg)::get(this, "", "cfg", cfg))
            `uvm_fatal("CLK_DRV", "Nao achou clk-cgf no configdb")
        vif = cfg.vif;
    endfunction

    virtual task run_phase(uvm_phase phase);
        //iniciar o clk de 2ghz
        vif.half_period_ps = cfg.default_half_period_ps;
        vif.clk_en = 1'b1;

        forever begin
            seq_item_port.get_next_item(req);
            vif.half_period_ps = req.ref_half_period_ps;
            vif.clk_en         = req.clk_en;
            `uvm_info("CLK_DRV", $sformatf("clk ref atualizado: en=%0b, half_period=%0t ps",
                        req.clk_en, req.ref_half_period_ps), UVM_MEDIUM)
            seq_item_port.item_done();
        end
    endtask

endclass: clk_pll_driver