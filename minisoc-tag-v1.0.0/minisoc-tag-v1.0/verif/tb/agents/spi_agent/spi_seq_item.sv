// CAMINHO DE DADOS (estimulo):
//   1. A SEQUENCE cria este objeto e randomiza rwb/addr/wdata.
//   2. O objeto viaja: sequence -> sequencer -> driver.
//   3. O DRIVER serializa os campos em um frame de 40 bits no pino mosi.
//   4. Em uma leitura (rwb=1), o driver captura o miso do segundo frame e
//    preenche rdata NO MESMO OBJETO. Como start_item/finish_item nao
//      clonam o objeto, a sequence enxerga rdata depois do finish_item.

class spi_seq_item extends uvm_sequence_item;

    // Campos de estimulo (randomizados pela sequence, usados pelo driver)
    rand bit        rwb;    // 0 = write, 1 = read (bit 39 do frame)
    rand bit [5:0]  addr;   // endereco do registrador (bits 38:33)
    rand bit [31:0] wdata;  // payload de escrita (bits 31:0)

    // Campo de resposta (preenchido pelo driver na leitura, ou pelo monitor
    // com os bits [31:0] capturados no miso)
    bit [31:0] rdata;

    // Por padrao, fica dentro do mapa de registradores implementado
    constraint c_valid_addr { addr inside {[6'h00:6'h0F]}; }

    `uvm_object_utils_begin(spi_seq_item)
        `uvm_field_int(rwb,   UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(addr,  UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(wdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(rdata, UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "spi_seq_item");
        super.new(name);
    endfunction

endclass : spi_seq_item
