class mem_monitor extends uvm_monitor;
    `uvm_component_utils(mem_monitor)

    virtual mem_if                     vif;
    mem_cfg                            cfg;
    uvm_analysis_port #(mem_seq_item)  ap;

    function new(string name = "mem_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(mem_cfg)::get(this, "", "cfg", cfg))
            `uvm_fatal("MEM_MON", "Nao foi possivel obter mem_cfg do config.db")
        vif = cfg.vif;
    endfunction

    virtual task run_phase(uvm_phase phase);
        mem_seq_item item;

        forever begin
            @(posedge vif.mem_clk);
            if (vif.tb_valid === 1'b1) begin
                item       = mem_seq_item::type_id::create("item", this);
                item.wr_en = vif.wr_en;
                item.addr  = vif.addr;
                item.wdata = vif.wdata;

                if (!item.wr_en) begin
                    // leitura: o dado so aparece na proxima borda
                    @(posedge vif.mem_clk);
                    item.rdata = vif.rdata;
                end

                `uvm_info("MEM_MON", $sformatf(
                    "Acesso capturado: %s addr=0x%03h wdata=0x%08h rdata=0x%08h",
                    item.wr_en ? "WRITE" : "READ ",
                    item.addr, item.wdata, item.rdata), UVM_MEDIUM)

                ap.write(item);
            end
        end
    endtask

endclass : mem_monitor
