`ifndef CLK_PLL_IF_SV
`define CLK_PLL_IF_SV

interface clk_pll_if;
    timeunit 1ps;
    timeprecision 1ps;

    //clk de referencia
    //2ghz -> periodo de 500 ps -> semiperiodo de 250ps
    logic clk = 1'b0;
    bit clk_en = 1'b1;
    time half_period_ps = 250ps;

    //sinais do dut
    logic rst_n;
    logic pll_enable;
    logic [1:0] pll_div_sel;
    logic pll_locked;
    logic sys_clk;
    logic sys_rst_n;

    //gerador fisico do clk alwayson
    always begin
        #(half_period_ps);
        if(clk_en)
            clk = ~clk;
        else
            clk = 1'b0;
    end

    
endinterface: clk_pll_if

`endif