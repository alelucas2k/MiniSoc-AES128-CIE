`ifndef RST_IF_SV
`define RST_IF_SV

interface rst_if(input logic clk);
    timeunit 1ps;
    timeprecision 1ps;

    logic rst_n; //reset global em nível baixo
    
endinterface : rst_if

`endif