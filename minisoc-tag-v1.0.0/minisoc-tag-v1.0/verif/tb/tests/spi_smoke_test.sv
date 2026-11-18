`ifndef SPI_SMOKE_TEST_SV
`define SPI_SMOKE_TEST_SV

`include "rst_init_seq.sv"
`include "spi_smoke_seq.sv"

import minisoc_env_pkg::*; 

// ----------------------------------------------------------------------------
// Smoke Test do SPI.
//
// O que ele monta:
//   - rst_agent (ativo): para tirar o DUT do reset antes de usar o SPI.
//   - spi_agent (ativo): driver mestre + monitor.
//   - spi_listener: pendurado no analysis port do monitor.
//
// O que ele verifica:
//   - Readback: write KEY0 + read KEY0 + read VERSION (checks na sequence).
//   - Contagem de frames no monitor: 1 (write) + 2 (read) + 2 (read) = 5.
// ----------------------------------------------------------------------------
class spi_smoke_test extends uvm_test;
    `uvm_component_utils(spi_smoke_test)

    // VIP de Reset (necessario para inicializar o DUT)
    rst_cfg      r_cfg;
    rst_agent    r_agt;

    // VIP de SPI
    spi_cfg      s_cfg;
    spi_agent    s_agt;
    spi_listener s_list;

    function new(string name = "spi_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Configura o Agente de Reset
        r_cfg = rst_cfg::type_id::create("r_cfg");
        if (!uvm_config_db#(virtual rst_if)::get(this, "", "rst_vif", r_cfg.vif))
            `uvm_fatal("TEST", "Nao encontrou rst_vif no uvm_config_db")
        r_cfg.is_active = UVM_ACTIVE;
        uvm_config_db#(rst_cfg)::set(this, "r_agt", "cfg", r_cfg);

        // Configura o Agente de SPI
        s_cfg = spi_cfg::type_id::create("s_cfg");
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", s_cfg.vif))
            `uvm_fatal("TEST", "Nao encontrou spi_vif no uvm_config_db")
        s_cfg.is_active = UVM_ACTIVE;
        uvm_config_db#(spi_cfg)::set(this, "s_agt", "cfg", s_cfg);

        // Instancia os agentes e o listener
        r_agt  = rst_agent::type_id::create("r_agt", this);
        s_agt  = spi_agent::type_id::create("s_agt", this);
        s_list = spi_listener::type_id::create("s_list", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Liga o analysis port do monitor SPI no listener
        s_agt.ap.connect(s_list.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
        rst_init_seq  rst_seq;
        spi_smoke_seq spi_seq;
        phase.raise_objection(this);

        // 1. Reset inicial (sem ele, registradores do DUT ficam em X)
        rst_seq = rst_init_seq::type_id::create("rst_seq");
        rst_seq.start(r_agt.sqr);

        // 2. Trafego SPI: write + readback + version
        spi_seq = spi_smoke_seq::type_id::create("spi_seq");
        spi_seq.start(s_agt.sqr);

        #100ns; // folga para o monitor publicar o ultimo frame

        // 3. Checagem do caminho de observacao:
        //    1 frame do write + 2 frames por leitura (x2 leituras) = 5
        if (s_list.count == 5)
            `uvm_info("TEST_PASS", "SUCESSO! agent de SPI validado: 5 frames observados e readback OK!", UVM_NONE)
        else
            `uvm_error("TEST_FAIL", $sformatf(
                "Contagem inesperada de frames SPI: esperado 5, visto %0d", s_list.count))

        phase.drop_objection(this);
    endtask

endclass : spi_smoke_test

`endif
