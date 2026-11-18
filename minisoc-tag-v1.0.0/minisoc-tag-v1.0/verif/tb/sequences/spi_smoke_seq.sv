`ifndef SPI_SMOKE_SEQ_SV
`define SPI_SMOKE_SEQ_SV

// ----------------------------------------------------------------------------
// Smoke sequence do SPI: exercita o caminho basico de escrita e leitura
// do banco de registradores.
//
//   1. WRITE KEY0 = 0xDEADBEEF  (registrador R/W qualquer)
//   2. READ  KEY0               -> tem que voltar 0xDEADBEEF
//   3. READ  VERSION (0x0D)     -> tem que voltar 0x0001_0100 (valor fixo
//                                  no RTL, otimo para validar o caminho
//                                  de leitura sem depender de escrita)
//
// Os checks ficam aqui mesmo na sequence (nivel basico): o driver devolve
// o dado lido dentro do proprio req (req.rdata) apos o finish_item.
// ----------------------------------------------------------------------------
class spi_smoke_seq extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_smoke_seq)

    localparam bit [5:0]  REG_KEY0        = 6'h00;
    localparam bit [5:0]  REG_VERSION     = 6'h0D;
    localparam bit [31:0] KEY0_TEST_VALUE = 32'hDEAD_BEEF;
    localparam bit [31:0] VERSION_VALUE   = 32'h0001_0100;

    function new(string name = "spi_smoke_seq");
        super.new(name);
    endfunction

    virtual task body();
        spi_seq_item req;

        // 1. Escreve um valor conhecido em KEY0
        `uvm_info("SPI_SEQ", "---> WRITE KEY0", UVM_LOW)
        req = spi_seq_item::type_id::create("req_wr_key0");
        start_item(req);
        if (!req.randomize() with {
            rwb   == 1'b0;
            addr  == REG_KEY0;
            wdata == KEY0_TEST_VALUE;
        }) `uvm_fatal("SPI_SEQ", "Falha na randomizacao do write KEY0")
        finish_item(req);

        // 2. Le KEY0 de volta e compara
        `uvm_info("SPI_SEQ", "---> READ KEY0", UVM_LOW)
        req = spi_seq_item::type_id::create("req_rd_key0");
        start_item(req);
        if (!req.randomize() with {
            rwb  == 1'b1;
            addr == REG_KEY0;
        }) `uvm_fatal("SPI_SEQ", "Falha na randomizacao do read KEY0")
        finish_item(req);
        // o driver preencheu req.rdata durante o finish_item
        if (req.rdata !== KEY0_TEST_VALUE)
            `uvm_error("SPI_SEQ", $sformatf(
                "Readback de KEY0 errado: esperado 0x%08h, lido 0x%08h",
                KEY0_TEST_VALUE, req.rdata))
        else
            `uvm_info("SPI_SEQ", "Readback de KEY0 OK", UVM_LOW)

        // 3. Le o registrador VERSION (valor fixo em RTL)
        `uvm_info("SPI_SEQ", "---> READ VERSION", UVM_LOW)
        req = spi_seq_item::type_id::create("req_rd_version");
        start_item(req);
        if (!req.randomize() with {
            rwb  == 1'b1;
            addr == REG_VERSION;
        }) `uvm_fatal("SPI_SEQ", "Falha na randomizacao do read VERSION")
        finish_item(req);
        if (req.rdata !== VERSION_VALUE)
            `uvm_error("SPI_SEQ", $sformatf(
                "VERSION errado: esperado 0x%08h, lido 0x%08h",
                VERSION_VALUE, req.rdata))
        else
            `uvm_info("SPI_SEQ", "Leitura de VERSION OK", UVM_LOW)
    endtask

endclass : spi_smoke_seq

`endif