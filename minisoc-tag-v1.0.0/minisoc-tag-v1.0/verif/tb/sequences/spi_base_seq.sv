// sequencia base do spi
// vai guardar mapa de registradores e gerenciar tarefas de acesso

// cira 1 spi_item -> sqr -> driver -> spi_if

// write gera 1 frame e read gera 2

class spi_base_seq extends uvm_sequence #(spi_seq_item);

    `uvm_object_utils(spi_base_seq)

    //mapa de registradores do 
    localparam bit [5:0] REG_KEY0            = 6'h00;
    localparam bit [5:0] REG_IV0             = 6'h04;
    localparam bit [5:0] REG_COUNTER_HI      = 6'h08;
    localparam bit [5:0] REG_COUNTER_LO      = 6'h09;
    localparam bit [5:0] REG_NUM_BLOCKS      = 6'h0A;
    localparam bit [5:0] REG_AES_CONTROL     = 6'h0B;
    localparam bit [5:0] REG_AES_STATUS      = 6'h0C;
    localparam bit [5:0] REG_REG_VERSION     = 6'h0D;
    localparam bit [5:0] REG_SYSTEM_CONTROL  = 6'h0E;
    localparam bit [5:0] REG_SYSTEM_STATUS   = 6'h0F;

    // construtor
    function new(string name = "spi_base_seq");
        super.new(name);
    endfunction

    //escreve um registrador (1 frame spi)
    virtual task write_reg(bit [5:0] reg_addr, bit [31:0] reg_data);
        spi_seq_item item;
        item = spi_seq_item::type_id::create("item_wr");
        start_item(item);
        if(!item.randomize()with{
            rwb == 1'b0;
            addr == reg_addr;
            wdata == reg_data;
        }) `uvm_fatal("SPI_BASE_SEQ", "falha na randomizacao do write")
        finish_item(item);
    endtask

    //le um registrdor com dois frames e devolver o valor em reg_data
    virtual task read_reg(bit [5:0] reg_addr, output bit [31:0] reg_data);
        spi_seq_item item;

        item = spi_seq_item::type_id::create("item_rd");
        start_item(item);
        if(!item.randomize()with{
            rwb == 1'b1;
            addr == reg_addr;
        }) `uvm_fatal("SPI_BASE_SEQ", "falha na randomizacao do read")
        finish_item(item);
        //driver preencheu item.rdata no finish item
        reg_data = item.rdata;
    endtask

    //checagem lendo o registrador e comparando com o esperado
    virtual task check_reg(bit [5:0] reg_addr, bit [31:0] expected);

        bit[31:0] read_value;
        read_reg(reg_addr, read_value);
        if (read_value !== expected)
            `uvm_error("SPI_CHECK", $sformatf("readback errado em 0x%02h: esperado 0x%08h, lido 0x%08h", 
            reg_addr, expected, read_value))
        else
            `uvm_info("SPI_CHECK", $sformatf(
                "readback ok em 0x%02h: 0x%08h", reg_addr, read_value
            ), UVM_LOW)
    endtask

endclass : spi_base_seq