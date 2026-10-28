class clk_pll_monitor extends uvm_monitor;
    `uvm_component_utils(clk_pll_monitor)

    virtual clk_pll_if vif;
    clk_cfg cfg;
    uvm_analysis_port #(clk_pll_seq_item) ap;

    function new(string name = "clk_pll_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(clk_cfg)::get(this, "", "cfg", cfg))
            `uvm_fatal("CLK_MON", "Nao foi possivel achar clk_cfg do config,db")
        vif = cfg.vif;
    endfunction

    virtual task run_phase(uvm_phase phase);
        clk_pll_seq_item item;
        time t0, t1;

        // 1. Aguarda a liberacao do primeiro reset para comecar a observar o clock
        @(posedge vif.rst_n);

        // 2. Mede duas bordas de subida consecutivas do clock de referencia (2 GHz = 500 ps)
        @(posedge vif.clk);
        t0 = $time;
        @(posedge vif.clk);
        t1 = $time;

        // 3. Monta o pacote basico e envia pelo analysis_port para validar a conexao UVM
        item = clk_pll_seq_item::type_id::create("item", this);
        item.clk_en                     = vif.clk_en;
        item.ref_half_period_ps         = (t1 - t0) / 2;
        item.pll_enable                 = vif.pll_enable;
        item.pll_div_sel                = vif.pll_div_sel;
        item.pll_locked                 = vif.pll_locked;
        item.measured_sys_clk_period_ps = (t1 - t0);

        `uvm_info("CLK_MON", $sformatf("Clock de referencia ativo! Periodo medido = %0t ps", (t1 - t0)), UVM_LOW);
        ap.write(item);

    endtask

endclass: clk_pll_monitor