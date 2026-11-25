//configuracao basica do aes pelo spi
// programar registradores e depois ler cada registrador de volta 
//bit start em 0 -> configura e n dispara o aes
// como os enderecos de 0x00 até 0x0b sao consecutivos da pra usar array e percorrer dentro

class spi_aes_cfg_seq extends spi_base_seq;
    `uvm_object_utils(spi_aes_cfg_seq)

    //configs
    rand bit [127:0] key; //chave
    rand bit [127:0] iv;    //vetor de inicializacao
    rand bit [63:0] counter; //counter do modo ctr
    rand bit [8:0] num_blocks; //quantos blocos de 128 o aes vai processar
    rand bit [2:0] mode;
    rand bit decrypt;

    //num_blocks de 1 a 256 e mode de 000(ECB) até 101(CTR)
    constraint c_valid_cfg{
        num_blocks inside {[1:256]};
        mode       inside {[3'b000:3'b101]};
    }

    function new(string name = "spi_aes_cfg_seq");
        super.new(name);
    endfunction

    virtual task body();

        //array com 12 posicoes de 32 bits
        bit [31:0] reg_values [12]; 

        `uvm_info("AES_CFG_SEQ", $sformatf(
            "programando AES: mode = %0x3b decrypt=%0b num_blocks=%0d key=0x%032h",
            mode, decrypt, num_blocks, key), UVM_LOW)

        //valor de cada reg na ordem dos enderecos
        //key0, iv0, counterhi recebem parte mais significativa
        //aes_control = {mode, decrypt, start=0}
        reg_values = '{
            key[127:96], key[95:64], key[63:32], key[31:0],
            iv[127:96], iv[95:64], iv[63:32], iv[31:0],
            counter[63:32], counter[31:0],
            {23'b0, num_blocks},
            {27'b0, mode, decrypt, 1'b0}
        };


        // escrever os 12 registradores
        for (int i = 0; i < 12; i++)
            write_reg(i[5:0], reg_values[i]);

        // le os 12 de volta e compara
        for (int i = 0; i < 12; i++)
            check_reg(i[5:0], reg_values[i]);
    
    endtask
endclass : spi_aes_cfg_seq
