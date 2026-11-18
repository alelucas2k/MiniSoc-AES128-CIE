`ifndef MEM_SMOKE_SEQ_SV
`define MEM_SMOKE_SEQ_SV

// ----------------------------------------------------------------------------
// Smoke sequence da MEMORY DATA: escreve 4 palavras (o tamanho de um bloco
// AES) e le as mesmas 4 de volta, comparando.
//
// Pressupoe MEM_SEL_AES = 0 (valor padrao apos o reset), ou seja, a
// interface externa e dona da memoria. A memoria nao tem reset, entao o
// conteudo inicial e indefinido: por isso o teste sempre escreve antes
// de ler.
// ----------------------------------------------------------------------------
class mem_smoke_seq extends uvm_sequence #(mem_seq_item);
    `uvm_object_utils(mem_smoke_seq)

    // Padroes de teste faceis de reconhecer na forma de onda
    // (e o bloco de exemplo do Block Guide, secao 7.1)
    bit [31:0] test_pattern [4] = '{
        32'h0011_2233, 32'h4455_6677, 32'h8899_AABB, 32'hCCDD_EEFF
    };

    function new(string name = "mem_smoke_seq");
        super.new(name);
    endfunction

    virtual task body();
        mem_seq_item req;
        bit [9:0]  tgt_addr;  // copias locais para usar no randomize with
        bit [31:0] tgt_data;

        // 1. Escreve as 4 palavras nos enderecos 0..3
        for (int i = 0; i < 4; i++) begin
            tgt_addr = i[9:0];
            tgt_data = test_pattern[i];

            `uvm_info("MEM_SEQ", $sformatf("---> WRITE mem[%0d]", i), UVM_LOW)
            req = mem_seq_item::type_id::create($sformatf("req_wr_%0d", i));
            start_item(req);
            if (!req.randomize() with {
                wr_en == 1'b1;
                addr  == tgt_addr;
                wdata == tgt_data;
            }) `uvm_fatal("MEM_SEQ", "Falha na randomizacao do write")
            finish_item(req);
        end

        // 2. Le as 4 palavras de volta e compara com o que foi escrito
        for (int i = 0; i < 4; i++) begin
            tgt_addr = i[9:0];
            tgt_data = test_pattern[i];

            `uvm_info("MEM_SEQ", $sformatf("---> READ mem[%0d]", i), UVM_LOW)
            req = mem_seq_item::type_id::create($sformatf("req_rd_%0d", i));
            start_item(req);
            if (!req.randomize() with {
                wr_en == 1'b0;
                addr  == tgt_addr;
            }) `uvm_fatal("MEM_SEQ", "Falha na randomizacao do read")
            finish_item(req);
            // o driver preencheu req.rdata durante o finish_item
            if (req.rdata !== tgt_data)
                `uvm_error("MEM_SEQ", $sformatf(
                    "Readback de mem[%0d] errado: esperado 0x%08h, lido 0x%08h",
                    i, tgt_data, req.rdata))
            else
                `uvm_info("MEM_SEQ", $sformatf("Readback de mem[%0d] OK", i), UVM_LOW)
        end
    endtask

endclass : mem_smoke_seq

`endif