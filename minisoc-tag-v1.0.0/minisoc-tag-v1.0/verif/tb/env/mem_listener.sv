`ifndef MEM_LISTENER_SV
`define MEM_LISTENER_SV

// ----------------------------------------------------------------------------
// Listener do agente de MEMORY DATA.
//
// CAMINHO DE DADOS:
//   pinos da mem_if -> mem_monitor -> analysis port -> ESTE listener
//
// O monitor publica UM ITEM POR ACESSO (uma escrita ou uma leitura de uma
// palavra de 32 bits), qualificado pelo sinal lateral tb_valid. Aqui a
// relacao e um para um: N acessos na sequence geram N itens.
//
// ----------------------------------------------------------------------------
class mem_listener extends uvm_subscriber #(mem_seq_item);
    `uvm_component_utils(mem_listener)

    int count = 0; // quantidade de acessos observados ate agora

    function new(string name = "mem_listener", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Chamada automaticamente a cada ap.write() do monitor
    virtual function void write(mem_seq_item t);
        count++;
        `uvm_info("MEM_LISTENER", $sformatf(
            "Monitor capturou acesso de memoria #%0d. Item:", count), UVM_LOW)
        t.print();
    endfunction

endclass : mem_listener

`endif