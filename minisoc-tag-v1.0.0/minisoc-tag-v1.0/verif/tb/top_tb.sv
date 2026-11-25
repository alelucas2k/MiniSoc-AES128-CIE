`timescale 1ps/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import rst_agent_pkg::*;
import clk_pll_agent_pkg::*;
import spi_agent_pkg::*;
import mem_agent_pkg::*;

`include "spi_smoke_test.sv"
`include "rst_smoke_test.sv"
`include "mem_smoke_test.sv"
`include "dut_cfg_test.sv"

module top_tb;

    //interfaces fisicas: cada interface do DUT tem a sua
    clk_pll_if u_clk_pll_if ();
    rst_if     u_rst_if (.clk(u_clk_pll_if.clk));
    spi_if     u_spi_if ();
    mem_if     u_mem_if ();

    //conectando o dut ao clk_pll_if
    assign u_clk_pll_if.rst_n       = u_rst_if.rst_n;
    assign u_clk_pll_if.pll_enable  = dut.spi_cfg_pll_enable;
    assign u_clk_pll_if.pll_div_sel = dut.spi_cfg_pll_div_sel;
    assign u_clk_pll_if.pll_locked  = dut.pll_locked;
    assign u_clk_pll_if.sys_clk     = dut.sys_clk;
    assign u_clk_pll_if.sys_rst_n   = dut.sys_rst_n;

    //instacia do dut
    // CAMINHO DE DADOS: os drivers dos agentes escrevem nos sinais das
    // interfaces (u_spi_if, u_mem_if, u_rst_if) e eles chegam ao DUT por
    // estas conexoes de porta. Os monitores olham os mesmos fios.
    minisoc_top dut(
        .clk(u_clk_pll_if.clk),
        .rst_n(u_rst_if.rst_n),

        // SPI: TB e o mestre, DUT e o escravo
        .spi_sclk(u_spi_if.sclk),
        .spi_cs_n(u_spi_if.cs_n),
        .spi_mosi(u_spi_if.mosi),
        .spi_miso(u_spi_if.miso),

        // MEMORY DATA: TB e o mestre externo da SRAM
        .mem_clk(u_mem_if.mem_clk),
        .mem_i_data(u_mem_if.wdata),
        .mem_i_wr_en(u_mem_if.wr_en),
        .mem_i_addr(u_mem_if.addr),
        .mem_o_data(u_mem_if.rdata)
    );


    initial begin

        string wave;
        if (!$value$plusargs("WAVE=%s", wave)) wave = "minisoc_waves";
        $fsdbDumpfile({wave, ".fsdb"});
        $fsdbDumpvars(0, top_tb, "+all"); // "+all" permite ver structs, arrays e enums da FSM!

        // 2. Geração de ondas no formato VPD (nativo do VCS / DVE)
        $vcdplusfile("minisoc_waves.vpd");
        $vcdpluson(0, top_tb);
        $vcdplusmemon(); // Habilita visualização de arrays de memória

        //registra as interfaces no config.db para os testes buscarem
        uvm_config_db#(virtual rst_if)::set(null, "uvm_test_top", "rst_vif", u_rst_if);
        uvm_config_db#(virtual clk_pll_if)::set(null, "uvm_test_top", "clk_vif", u_clk_pll_if);
        uvm_config_db#(virtual spi_if)::set(null, "uvm_test_top", "spi_vif", u_spi_if);
        uvm_config_db#(virtual mem_if)::set(null, "uvm_test_top", "mem_vif", u_mem_if);

        run_test("rst_smoke_test");

    end



endmodule: top_tb


//source /Tools/synopsys-scripts/snps.sh
