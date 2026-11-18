// ----------------------------------------------------------------------------
// Agente SPI: agrupa sequencer + driver + monitor.
//
//   UVM_ACTIVE : cria sequencer e driver (gera estimulo) + monitor.
//   UVM_PASSIVE: cria somente o monitor (apenas observa).
//
// CAMINHO DE DADOS dentro do agente:
//   sequence --(sqr)--> driver --> fios da spi_if --> DUT
//   fios da spi_if --> monitor --> ap (analysis port) --> listener/scoreboard
// ----------------------------------------------------------------------------
class spi_agent extends uvm_agent;
    `uvm_component_utils(spi_agent)

    spi_cfg       cfg;
    spi_sequencer sqr;
    spi_driver    drv;
    spi_monitor   mon;
    uvm_analysis_port #(spi_seq_item) ap;

    function new(string name = "spi_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(spi_cfg)::get(this, "", "cfg", cfg))
            `uvm_fatal("SPI_AGT", "Nao foi possivel obter spi_cfg do config.db")

        // Repassa o cfg para o driver e o monitor (filhos deste agente)
        uvm_config_db#(spi_cfg)::set(this, "*", "cfg", cfg);

        mon = spi_monitor::type_id::create("mon", this);

        if (cfg.is_active == UVM_ACTIVE) begin
            sqr = spi_sequencer::type_id::create("sqr", this);
            drv = spi_driver::type_id::create("drv", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap = mon.ap; // expoe o analysis port do monitor como porta do agente
        if (cfg.is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass : spi_agent
