// Arquivo: verif/tb/env/spi_listener.sv
`ifndef SPI_LISTENER_SV
`define SPI_LISTENER_SV

// ----------------------------------------------------------------------------
// Listener do agente de SPI.
//
// CAMINHO DE DADOS:
//   fios da spi_if -> spi_monitor -> analysis port -> ESTE listener
//
// O uvm_subscriber ja traz um analysis_export pronto e obriga a implementar
// a funcao write(), que e chamada uma vez por item publicado pelo monitor.
//
// ----------------------------------------------------------------------------
class spi_listener extends uvm_subscriber #(spi_seq_item);
    `uvm_component_utils(spi_listener)

    int count = 0; // quantidade de frames observados ate agora

    function new(string name = "spi_listener", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Chamada automaticamente a cada ap.write() do monitor
    virtual function void write(spi_seq_item t);
        count++;
        `uvm_info("SPI_LISTENER", $sformatf(
            "Monitor capturou frame SPI #%0d. Item:", count), UVM_LOW)
        t.print();
    endfunction

endclass : spi_listener

`endif