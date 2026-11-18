`ifndef MEM_SMOKE_TEST_SV
`define MEM_SMOKE_TEST_SV

`include "rst_init_seq.sv"
`include "mem_smoke_seq.sv"

import minisoc_env_pkg::*; 


// ----------------------------------------------------------------------------
// Smoke Test da MEMORY DATA.
//
// O que ele monta:
//   - rst_agent (ativo): o reset deixa MEM_SEL_AES = 0, entao a interface
//     externa fica dona da memoria (condicao para este teste).
//   - mem_agent (ativo): driver mestre externo + monitor.
//   - mem_listener: pendurado no analysis port do monitor.
//
// O que ele verifica:
//   - Readback: escreve 4 palavras e le as mesmas 4 (checks na sequence).
//   - Contagem de acessos no monitor: 4 writes + 4 reads = 8.
// ----------------------------------------------------------------------------
class mem_smoke_test extends uvm_test;
    `uvm_component_utils(mem_smoke_test)

    // VIP de Reset
    rst_cfg      r_cfg;
    rst_agent    r_agt;

    // VIP de MEMORY DATA
    mem_cfg      m_cfg;
    mem_agent    m_agt;
    mem_listener m_list;

    function new(string name = "mem_smoke_test", uvm_component parent = null);
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

        // Configura o Agente de Memoria
        m_cfg = mem_cfg::type_id::create("m_cfg");
        if (!uvm_config_db#(virtual mem_if)::get(this, "", "mem_vif", m_cfg.vif))
            `uvm_fatal("TEST", "Nao encontrou mem_vif no uvm_config_db")
        m_cfg.is_active = UVM_ACTIVE;
        uvm_config_db#(mem_cfg)::set(this, "m_agt", "cfg", m_cfg);

        // Instancia os agentes e o listener
        r_agt  = rst_agent::type_id::create("r_agt", this);
        m_agt  = mem_agent::type_id::create("m_agt", this);
        m_list = mem_listener::type_id::create("m_list", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_agt.ap.connect(m_list.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
        rst_init_seq  rst_seq;
        mem_smoke_seq mem_seq;
        phase.raise_objection(this);

        // 1. Reset inicial: garante MEM_SEL_AES = 0 (dono = interface externa)
        rst_seq = rst_init_seq::type_id::create("rst_seq");
        rst_seq.start(r_agt.sqr);

        // 2. Trafego de memoria: 4 writes + 4 reads com comparacao
        mem_seq = mem_smoke_seq::type_id::create("mem_seq");
        mem_seq.start(m_agt.sqr);

        #100ns; // folga para o monitor publicar o ultimo acesso

        // 3. Checagem do caminho de observacao: 8 acessos no total
        if (m_list.count == 8)
            `uvm_info("TEST_PASS", "SUCESSO! VIP de Memoria validado: 8 acessos observados e readback OK!", UVM_NONE)
        else
            `uvm_error("TEST_FAIL", $sformatf(
                "Contagem inesperada de acessos: esperado 8, visto %0d", m_list.count))

        phase.drop_objection(this);
    endtask

endclass : mem_smoke_test

`endif
