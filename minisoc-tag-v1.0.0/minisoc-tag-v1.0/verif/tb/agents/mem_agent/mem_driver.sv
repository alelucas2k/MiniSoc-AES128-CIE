// ----------------------------------------------------------------------------
// Driver MEMORY DATA: o TB faz o papel do mestre externo da memoria.
//
// LOGICA DE FUNCIONAMENTO (um item por vez):
//   borda N  : driver coloca addr/wdata/wr_en nos pinos e sobe tb_valid.
//   borda N+1: a MEMORIA captura o acesso (escreve, ou registra a leitura).
//              O driver ja baixa tb_valid e wr_en.
//   borda N+2: (so na leitura) o dado registrado esta estavel em rdata;
//              o driver copia para item.rdata e devolve para a sequence.
//
// Lembrete de sistema: este caminho so funciona quando MEM_SEL_AES = 0
// (interface externa dona da memoria), que e o valor apos o reset.
// ----------------------------------------------------------------------------
class mem_driver extends uvm_driver #(mem_seq_item);
    `uvm_component_utils(mem_driver)

    virtual mem_if vif;
    mem_cfg        cfg;

    function new(string name = "mem_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(mem_cfg)::get(this, "", "cfg", cfg))
            `uvm_fatal("MEM_DRV", "Nao foi possivel obter mem_cfg do config.db")
        vif = cfg.vif;
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Estado ocioso no tempo 0: nada de escrita, valid baixo
        vif.wr_en    <= 1'b0;
        vif.tb_valid <= 1'b0;

        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_transfer(mem_seq_item item);
        // borda N: apresenta o acesso nos pinos
        @(posedge vif.mem_clk);
        vif.addr     <= item.addr;
        vif.wdata    <= item.wdata;
        vif.wr_en    <= item.wr_en;
        vif.tb_valid <= 1'b1;

        // borda N+1: a memoria executa o acesso nesta borda
        @(posedge vif.mem_clk);
        vif.wr_en    <= 1'b0;
        vif.tb_valid <= 1'b0;

        if (item.wr_en) begin
            `uvm_info("MEM_DRV", $sformatf("WRITE mem[0x%03h] = 0x%08h",
                        item.addr, item.wdata), UVM_MEDIUM)
        end
        else begin
            // borda N+2: dado registrado disponivel em rdata
            @(posedge vif.mem_clk);
            item.rdata = vif.rdata;
            `uvm_info("MEM_DRV", $sformatf("READ  mem[0x%03h] = 0x%08h",
                        item.addr, item.rdata), UVM_MEDIUM)
        end
    endtask

endclass : mem_driver
