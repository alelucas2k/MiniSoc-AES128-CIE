// ----------------------------------------------------------------------------
// Monitor SPI: observador passivo dos 4 fios.
//
// LOGICA DE FUNCIONAMENTO:
//   1. Espera o cs_n descer (inicio de um frame).
//   2. A cada SUBIDA de sclk amostra mosi e miso (mesma borda em que o DUT
//      amostra o mosi), acumulando os 40 bits de cada lado.
//   3. Depois de 40 bits, decodifica o frame do mosi (rwb/addr/data) e
//      guarda os bits [31:0] do miso em rdata.
//   4. Publica UM item POR FRAME no analysis port.
// ----------------------------------------------------------------------------
class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)

    virtual spi_if                     vif;
    spi_cfg                            cfg;
    uvm_analysis_port #(spi_seq_item)  ap;

    function new(string name = "spi_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(spi_cfg)::get(this, "", "cfg", cfg))
            `uvm_fatal("SPI_MON", "Nao foi possivel obter spi_cfg do config.db")
        vif = cfg.vif;
    endfunction

    virtual task run_phase(uvm_phase phase);
        bit [39:0] mosi_frame;
        bit [39:0] miso_frame;
        spi_seq_item item;

        forever begin
            // 1. Espera o inicio do frame
            @(negedge vif.cs_n);
            mosi_frame = '0;
            miso_frame = '0;

            // 2. Captura os 40 bits, MSB primeiro
            repeat (40) @(posedge vif.sclk) begin
                mosi_frame = {mosi_frame[38:0], vif.mosi};
                miso_frame = {miso_frame[38:0], vif.miso};
            end

            // 3. Decodifica os campos do frame observado
            item       = spi_seq_item::type_id::create("item", this);
            item.rwb   = mosi_frame[39];
            item.addr  = mosi_frame[38:33];
            item.wdata = mosi_frame[31:0];
            item.rdata = miso_frame[31:0]; // so tem significado no frame B

            `uvm_info("SPI_MON", $sformatf(
                "Frame capturado: rwb=%0b addr=0x%02h wdata=0x%08h miso[31:0]=0x%08h",
                item.rwb, item.addr, item.wdata, item.rdata), UVM_MEDIUM)

            // 4. Publica para os componentes de analise
            ap.write(item);

            // Espera o fim do frame para nao recomecar no meio
            @(posedge vif.cs_n);
        end
    endtask

endclass : spi_monitor
