`ifndef CLK_PLL_IF_SV
`define CLK_PLL_IF_SV

interface clk_pll_if;
    timeunit 1ps;
    timeprecision 1ps;

    //clk de referencia
    // 2ghz -> periodo de 500 ps -> semiperiodo de 250ps
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

    // ASSERTION A-02 (VPLAN Seção 6.1): SYS_CLK_GATED_UNTIL_LOCK
    // Enquanto PLL_LOCKED == 0, o clock do sistema (sys_clk) deve permanecer em 0
    // Violação indica falha em REQ-PLL-01.

    property p_sys_clk_until_lock;
        @(posedge clk) disable iff(!rst_n)
        (!pll_locked) |-> (sys_clk == 1'b0);
    endproperty

    // Instancia e ativa o monitoramento contínuo da propriedade na simulação com rótulo A-02,
    // dispara erro no log caso a condição seja violada em qualquer ciclo.
    A_02_SYS_CLK_GATED_UNTIL_LOCK: assert property (p_sys_clk_until_lock)
        else $error("[SVA A-02 FAIL] sysclk em 1 enquanto pll_locked==0");

    
endinterface: clk_pll_if

`endif