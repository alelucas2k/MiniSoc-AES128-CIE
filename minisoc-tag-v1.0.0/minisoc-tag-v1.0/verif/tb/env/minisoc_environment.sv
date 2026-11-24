// Arquivo: verif/tb/env/minisoc_environment.sv
`ifndef MINISOC_ENVIRONMENT_SV
`define MINISOC_ENVIRONMENT_SV

// ----------------------------------------------------------------------------
// Environment do MiniSoC AES.
//
// Monta os agents e os listeners (camada de analise) e liga os analysis
// ports. O teste nao instancia agent nenhum: ele so cria os objetos de
// configuracao, publica no uvm_config_db no caminho "env.<agente>" e
// instancia este environment.
//
// CHAVES DE HABILITACAO (use_*)
//   Nem todo teste precisa dos quatro agents, e um agent criado sem o seu
//   cfg correspondente morre com uvm_fatal no build_phase. Por isso cada
//   agent tem uma chave.
//
//   O reset e o clock vem LIGADOS por padrao: sao a base minima de qualquer
//   teste (sem reset o banco SPI fica em X, sem clock nada anda). O SPI e a
//   memoria vem DESLIGADOS e o teste liga o que for usar.
//
//   Como ligar, no build_phase do teste, LOGO APOS o create do env:
//
//       env = minisoc_environment::type_id::create("env", this);
//       env.use_spi = 1;
//
//   Isso funciona porque o build_phase e top-down: o build_phase do teste
//   roda inteiro antes do build_phase do environment.
// ----------------------------------------------------------------------------
class minisoc_environment extends uvm_env;
    `uvm_component_utils(minisoc_environment)

    // --- chaves de habilitacao ---
    bit use_rst = 1'b1;
    bit use_clk = 1'b1;
    bit use_spi = 1'b0;
    bit use_mem = 1'b0;

    // --- agents ---
    rst_agent     r_agt;
    clk_pll_agent c_agt;
    spi_agent     s_agt;
    mem_agent     m_agt;

    // --- listeners (camada de analise) ---
    rst_listener  r_list;
    clk_listener  c_list;
    spi_listener  s_list;
    mem_listener  m_list;

    function new(string name = "minisoc_environment", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (use_rst) begin
            r_agt  = rst_agent::type_id::create("r_agt", this);
            r_list = rst_listener::type_id::create("r_list", this);
        end

        if (use_clk) begin
            c_agt  = clk_pll_agent::type_id::create("c_agt", this);
            c_list = clk_listener::type_id::create("c_list", this);
        end

        if (use_spi) begin
            s_agt  = spi_agent::type_id::create("s_agt", this);
            s_list = spi_listener::type_id::create("s_list", this);
        end

        if (use_mem) begin
            m_agt  = mem_agent::type_id::create("m_agt", this);
            m_list = mem_listener::type_id::create("m_list", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Cada monitor publica no seu listener. Quando o scoreboard entrar,
        // ele assina estes mesmos analysis ports, em paralelo com os
        // listeners -- nao em serie depois deles.
        if (use_rst) r_agt.ap.connect(r_list.analysis_export);
        if (use_clk) c_agt.ap.connect(c_list.analysis_export);
        if (use_spi) s_agt.ap.connect(s_list.analysis_export);
        if (use_mem) m_agt.ap.connect(m_list.analysis_export);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

endclass : minisoc_environment

`endif
