// ----------------------------------------------------------------------------
// Driver SPI: o TB faz o papel de MESTRE SPI (Mode 0, MSB-first).
//
// LOGICA DE FUNCIONAMENTO:
//   - Recebe um spi_seq_item do sequencer (get_next_item).
//   - Monta o frame de 40 bits: {rwb, addr[5:0], rsv=0, data[31:0]}.
//   - WRITE (rwb=0): envia 1 frame e pronto.
//   - READ  (rwb=1): precisa de 2 frames (regra do minisoc_spi):
//       Frame A: rwb=1 + addr  -> o DUT guarda o valor lido em read_data_sys.
//       Frame B: rwb=1 + NOP   -> enquanto o TB desloca o frame B no mosi,
//                                 o DUT desloca read_data_sys no miso.
//       O dado lido fica nos bits [31:0] do que foi capturado no miso.
//
// TIMING (Mode 0):
//   - mosi e trocado enquanto sclk esta em 0 (o DUT amostra na SUBIDA).
//   - miso e trocado pelo DUT na DESCIDA, entao o mestre amostra na SUBIDA.
//   - Entre frames, cs_n sobe por cs_idle_time para o evento de frame
//     cruzar o CDC sclk -> clk de 2 GHz dentro do DUT.
// ----------------------------------------------------------------------------
class spi_driver extends uvm_driver #(spi_seq_item);
    `uvm_component_utils(spi_driver)

    localparam bit [5:0] REG_NOP = 6'h3F; // endereco usado na fase B da leitura

    virtual spi_if vif;
    spi_cfg        cfg;

    function new(string name = "spi_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(spi_cfg)::get(this, "", "cfg", cfg))
            `uvm_fatal("SPI_DRV", "Nao foi possivel obter spi_cfg do config.db")
        vif = cfg.vif;
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Estado ocioso do barramento no tempo 0
        vif.sclk <= 1'b0;
        vif.cs_n <= 1'b1;
        vif.mosi <= 1'b0;

        forever begin
            seq_item_port.get_next_item(req); // item vem da sequence via sequencer
            drive_transfer(req);              // serializa o item nos fios
            seq_item_port.item_done();        // avisa a sequence que terminou
        end
    endtask

    // Executa a transacao completa (1 frame para write, 2 frames para read)
    virtual task drive_transfer(spi_seq_item item);
        bit [39:0] rx_frame;

        if (item.rwb == 1'b0) begin
            // ---------------- WRITE: um unico frame ----------------
            `uvm_info("SPI_DRV", $sformatf("WRITE addr=0x%02h data=0x%08h",
                        item.addr, item.wdata), UVM_MEDIUM)
            drive_frame({1'b0, item.addr, 1'b0, item.wdata}, rx_frame);
        end
        else begin
            // ---------------- READ: dois frames ----------------
            // Frame A: pede a leitura do endereco (payload ignorado pelo DUT)
            drive_frame({1'b1, item.addr, 1'b0, 32'h0}, rx_frame);

            // Frame B: desloca o valor pedido para fora pelo miso
            drive_frame({1'b1, REG_NOP, 1'b0, 32'h0}, rx_frame);

            // O dado lido esta nos 32 bits baixos do frame de resposta
            item.rdata = rx_frame[31:0];
            `uvm_info("SPI_DRV", $sformatf("READ  addr=0x%02h data=0x%08h",
                        item.addr, item.rdata), UVM_MEDIUM)
        end
    endtask

    // Envia um frame de 40 bits e devolve o que foi amostrado no miso
    virtual task drive_frame(input bit [39:0] tx_frame, output bit [39:0] rx_frame);
        rx_frame = '0;

        // Inicio do frame: seleciona o escravo com sclk ainda em 0
        vif.sclk <= 1'b0;
        vif.cs_n <= 1'b0;
        #(cfg.sclk_half_period);

        // MSB-first: bit 39 primeiro
        for (int i = 39; i >= 0; i--) begin
            vif.mosi <= tx_frame[i];      // apresenta o bit com sclk em 0
            #(cfg.sclk_half_period);
            vif.sclk <= 1'b1;             // SUBIDA: DUT amostra o mosi
            rx_frame[i] = vif.miso;       // mestre amostra o miso (estavel
                                          // desde a descida anterior)
            #(cfg.sclk_half_period);
            vif.sclk <= 1'b0;             // DESCIDA: DUT avanca o miso
        end

        // Fim do frame: libera o chip select e espera o CDC do DUT
        #(cfg.sclk_half_period);
        vif.cs_n <= 1'b1;
        vif.mosi <= 1'b0;
        #(cfg.cs_idle_time);
    endtask

endclass : spi_driver
