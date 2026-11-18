`ifndef SPI_IF_SV
`define SPI_IF_SV

// ----------------------------------------------------------------------------
// Interface fisica do barramento SPI (Mode 0: CPOL=0, CPHA=0).
//
// CAMINHO DE DADOS:
//   O driver do agente SPI (TB = mestre) escreve nos sinais sclk/cs_n/mosi
//   desta interface. O DUT (escravo) responde pelo miso.
//   O monitor apenas OBSERVA os 4 fios para reconstruir os frames.
// ----------------------------------------------------------------------------
interface spi_if;
    timeunit 1ps;
    timeprecision 1ps;

    logic sclk = 1'b0; // clock serial gerado pelo driver (TB e o mestre)
    logic cs_n = 1'b1; // chip select ativo baixo; 1 = barramento ocioso
    logic mosi = 1'b0; // mestre -> escravo (comandos do TB para o DUT)
    logic miso;        // escravo -> mestre (dado lido vindo do DUT)

endinterface : spi_if

`endif
