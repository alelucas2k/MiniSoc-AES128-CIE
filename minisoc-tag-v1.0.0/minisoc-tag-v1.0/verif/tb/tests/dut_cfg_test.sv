`include "rst_init_seq.sv"
`include "spi_base_seq.sv"
`include "spi_aes_cfg_seq.sv"
`include "spi_pll_cfg_seq.sv"

import minisoc_env_pkg::*;

//teste de config do basica do dut
//monta agents de clk, rst, spi e  seus listeners

//verificar:
// readback dos 12 regs de config spi (spi_aes_cfg_seq)
//Para cada um dos 4 divisores, a sequence confirma pelo SPI que o PLL travou e 
//guardou a configuração, e o monitor de clock confirma nos fios que ele travou a tempo e gerou a frequência certa

class dut_cfg_test extends uvm_test; 
    `uvm_component_utils(dut_cfg_test)

    minisoc_environment env;
    rst_cfg             r_cfg;
    clk_cfg             c_cfg;
    spi_cfg             s_cfg;

    function new(string name = "dut_cfg_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Reset -> env.r_agt
        r_cfg = rst_cfg::type_id::create("r_cfg");
        if (!uvm_config_db#(virtual rst_if)::get(this, "", "rst_vif", r_cfg.vif))
            `uvm_fatal("TEST", "Nao encontrou rst_vif no config_db")
        r_cfg.is_active = UVM_ACTIVE;
        uvm_config_db#(rst_cfg)::set(this, "env.r_agt", "cfg", r_cfg);

        // Clock/PLL -> env.c_agt
        c_cfg = clk_cfg::type_id::create("c_cfg");
        if (!uvm_config_db#(virtual clk_pll_if)::get(this, "", "clk_vif", c_cfg.vif))
            `uvm_fatal("TEST", "Nao encontrou clk_vif no config_db")
        c_cfg.is_active = UVM_ACTIVE;
        uvm_config_db#(clk_cfg)::set(this, "env.c_agt", "cfg", c_cfg);

        // SPI -> env.s_agt
        s_cfg = spi_cfg::type_id::create("s_cfg");
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", s_cfg.vif))
            `uvm_fatal("TEST", "Nao encontrou spi_vif no config_db")
        s_cfg.is_active = UVM_ACTIVE;
        uvm_config_db#(spi_cfg)::set(this, "env.s_agt", "cfg", s_cfg);

        // Environment: reset e clock ja vem ligados, o SPI e ligado aqui
        env = minisoc_environment::type_id::create("env", this);
        env.use_spi = 1'b1;
    endfunction

    virtual task run_phase(uvm_phase phase);

        rst_init_seq rst_seq;
        spi_aes_cfg_seq aes_seq;
        spi_pll_cfg_seq pll_seq;
        phase.raise_objection(this);

        //reset para colocar o banco spi em valores conhecidos
        rst_seq = rst_init_seq::type_id::create("rst_seq");
        rst_seq.start(env.r_agt.sqr);

        //configurar o aes com valores aleatorios valids
        aes_seq = spi_aes_cfg_seq::type_id::create("aes_seq");
        if(!aes_seq.randomize())
            `uvm_fatal("TEST", "falha na randomizacao do aes_cfg_seq")
        aes_seq.start(env.s_agt.sqr);

        //passar nos 4 divisores do pll
        for(int d = 0; d < 4; d++)begin
            pll_seq = spi_pll_cfg_seq::type_id::create($sformatf("pll_seq_%0d", d));

            if(!pll_seq.randomize()with{div_sel == d;})
                `uvm_fatal("TEST", "falha na randomizacao do spi_pll_cfg_seq")
                pll_seq.start(env.s_agt.sqr);
        end

        #100ns //esperar os monitores publicarem os ultimos itens 

        //monitor de clock deve ter publicado pelo menos 5 itens
        // 1 do clk de referencia + 1 por lock do pll nos 4 divisores
        if(env.c_list.count < 5)
            `uvm_error("TEST_FAIL", $sformatf("monitor de clock publicou %0d itens, espeador >= 5", env.c_list.count))
        
        phase.drop_objection(this);
    endtask

    //function de report a partr do contador de erros do uvm
    virtual function void report_phase(uvm_phase phase);
        uvm_report_server svr = uvm_report_server::get_server();

        super.report_phase(phase);
        if(svr.get_severity_count(UVM_ERROR) == 0 &&
            svr.get_severity_count(UVM_FATAL) == 0)

            `uvm_info("TEST_PASS", "dut configurado por spi e pll validado nos 4 divisores", UVM_NONE)
        else
            `uvm_info("TEST_FAIL", "FALHOU, checar logs de uvm_error", UVM_NONE)

    endfunction

endclass : dut_cfg_test




//verdi -dbdir ./simv.daidir -ssf dut_cfg.fsdb &