// ----------------------------------------------------------------------------
// Agente MEMORY DATA: agrupa sequencer + driver + monitor.
//
// CAMINHO DE DADOS dentro do agente:
//   sequence --(sqr)--> driver --> pinos da mem_if --> DUT (SRAM)
//   pinos da mem_if --> monitor --> ap --> listener/scoreboard
// ----------------------------------------------------------------------------
class mem_agent extends uvm_agent;
    `uvm_component_utils(mem_agent)

    mem_cfg       cfg;
    mem_sequencer sqr;
    mem_driver    drv;
    mem_monitor   mon;
    uvm_analysis_port #(mem_seq_item) ap;

    function new(string name = "mem_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(mem_cfg)::get(this, "", "cfg", cfg))
            `uvm_fatal("MEM_AGT", "Nao foi possivel obter mem_cfg do config.db")

        // Repassa o cfg para driver e monitor
        uvm_config_db#(mem_cfg)::set(this, "*", "cfg", cfg);

        mon = mem_monitor::type_id::create("mon", this);

        if (cfg.is_active == UVM_ACTIVE) begin
            sqr = mem_sequencer::type_id::create("sqr", this);
            drv = mem_driver::type_id::create("drv", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap = mon.ap;
        if (cfg.is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass : mem_agent
