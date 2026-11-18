// ----------------------------------------------------------------------------
// Transacao da interface MEMORY DATA: um acesso (read OU write) a uma
// palavra de 32 bits da SRAM.
//
// CAMINHO DE DADOS (estimulo):
//   sequence cria e randomiza -> sequencer -> driver -> pinos da mem_if -> DUT.
//   Na leitura, o driver espera a latencia de 1 ciclo da memoria e devolve
//   o dado em rdata (mesmo objeto, visivel na sequence apos finish_item).
//
// ----------------------------------------------------------------------------
class mem_seq_item extends uvm_sequence_item;

    // Estimulo
    rand bit        wr_en;  // 1 = write, 0 = read
    rand bit [9:0]  addr;   // endereco da palavra (0..1023)
    rand bit [31:0] wdata;  // dado de escrita (ignorado na leitura)

    // Resposta (preenchido pelo driver/monitor na leitura)
    bit [31:0] rdata;

    `uvm_object_utils_begin(mem_seq_item)
        `uvm_field_int(wr_en, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(addr,  UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(wdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(rdata, UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end

    function new(string name = "mem_seq_item");
        super.new(name);
    endfunction

endclass : mem_seq_item
