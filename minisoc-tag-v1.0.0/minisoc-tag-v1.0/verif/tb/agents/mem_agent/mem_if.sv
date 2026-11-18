`ifndef MEM_IF_SV
`define MEM_IF_SV

interface mem_if;
    timeunit 1ps;
    timeprecision 1ps;

    // Clock externo da memoria: 200 MHz (maximo da spec) -> semiperiodo 2500 ps
    logic mem_clk        = 1'b0;
    bit   clk_en         = 1'b1;
    time  half_period_ps = 2500ps;

    always begin
        #(half_period_ps);
        if (clk_en) mem_clk = ~mem_clk;
        else        mem_clk = 1'b0;
    end

    // Sinais que vao para o DUT
    logic [31:0] wdata = '0;   // mem_i_data
    logic        wr_en = 1'b0; // mem_i_wr_en (1 = write, 0 = read)
    logic [9:0]  addr  = '0;   // mem_i_addr
    logic [31:0] rdata;        // mem_o_data (vem do DUT)

    // Sinal lateral so do TB: driver -> monitor (marca o ciclo da transacao)
    logic tb_valid = 1'b0;

endinterface : mem_if

`endif
