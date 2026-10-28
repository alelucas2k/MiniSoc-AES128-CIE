`timescale 1ps/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import rst_agent_pkg::*;
import clk_pll_agent_pkg::*;
`include "rst_smoke_test.sv"

module top_tb;

    //clock de referencia 2GHz
    // logic clk = 1'b0;
    // always #250ps clk = ~clk;

    //interface do reset e clk_pll
    clk_pll_if u_clk_pll_if ();
    rst_if u_rst_if (.clk(u_clk_pll_if.clk));

    //conectando o dut ao clk_pll_if
    assign u_clk_pll_if.rst_n       = u_rst_if.rst_n;
    assign u_clk_pll_if.pll_enable  = dut.spi_cfg_pll_enable;
    assign u_clk_pll_if.pll_div_sel = dut.spi_cfg_pll_div_sel;
    assign u_clk_pll_if.pll_locked  = dut.pll_locked;
    assign u_clk_pll_if.sys_clk     = dut.sys_clk;
    assign u_clk_pll_if.sys_rst_n   = dut.sys_rst_n;


    //sinais básicos para interfaces sem agentes
    logic        spi_sclk    = 1'b0;
    logic        spi_cs_n    = 1'b1;
    logic        spi_mosi    = 1'b0;
    logic        spi_miso;
    logic        mem_clk     = 1'b0;
    logic [31:0] mem_i_data  = 32'b0;
    logic        mem_i_wr_en = 1'b0;
    logic [9:0]  mem_i_addr  = 10'b0;
    logic [31:0] mem_o_data;

    //instacia do dut
    minisoc_top dut(
        .clk(u_clk_pll_if.clk),
        .rst_n(u_rst_if.rst_n),
        .spi_sclk(spi_sclk),
        .spi_cs_n(spi_cs_n),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .mem_clk(mem_clk),
        .mem_i_data(mem_i_data),
        .mem_i_wr_en(mem_i_wr_en),
        .mem_i_addr(mem_i_addr),
        .mem_o_data(mem_o_data)

    );

    
    initial begin

        // 1. Geração de ondas no formato FSDB (para o Synopsys Verdi)
        $fsdbDumpfile("minisoc_waves.fsdb");
        $fsdbDumpvars(0, top_tb, "+all"); // "+all" permite ver structs, arrays e enums da FSM!

        // 2. Geração de ondas no formato VPD (nativo do VCS / DVE)
        $vcdplusfile("minisoc_waves.vpd");
        $vcdpluson(0, top_tb);
        $vcdplusmemon(); // Habilita visualização de arrays de memória

        //registra a if no config.db
        uvm_config_db#(virtual rst_if)::set(null, "uvm_test_top", "rst_vif", u_rst_if);
        uvm_config_db#(virtual clk_pll_if)::set(null, "uvm_test_top", "clk_vif", u_clk_pll_if);

        //inicia o teste
        run_test("rst_smoke_test");
    
    end



endmodule: top_tb


//source /Tools/synopsys-scripts/snps.sh
