//configurar o pll pelo spi

//system_control = {div_sel, pllenable=0, mem_sele=0}
//system_control = {div_sel, pllenable=1, mem_sele=0}

class spi_pll_cfg_seq extends spi_base_seq;
    `uvm_object_utils(spi_pll_cfg_seq)

    //divisoe
    rand bit [1:0] div_sel;

    //limitar a 10 leituras sem lockp n travar simulacao
    int max_polls = 10;

    function new(string name = "spi_pll_cfg_seq");
        super.new(name);
    endfunction

    virtual task body();
        
        bit [31:0] status;
        bit locked = 1'b0;

        `uvm_info("PLL_CFG_SEQ", $sformatf(
            "configurando pll com PLL-DIV_SELL=%02b (divisor /%0d)",
            div_sel, (1 << div_sel)
        ), UVM_LOW)

        //pll desligado, divisor programado
        write_reg(REG_SYSTEM_CONTROL, {28'b0, div_sel, 1'b0, 1'b0});

        //liga pll mantendo o divisor
        write_reg(REG_SYSTEM_CONTROL, {28'b0, div_sel, 1'b1, 1'b0});

        //polling do pll_locked (bit 0 de system-status)
        for (int i =0; i < max_polls && !locked; i++)begin
            read_reg(REG_SYSTEM_STATUS, status);
            locked = status[0];
        end

        if(!locked)
            `uvm_error("PLL_CFG_SEQ", $sformatf(
                "PLL n travou apos %0d leituras de System_status",
                max_polls))
        else 
            `uvm_info("PLL_CFG_SEQ", "PLL_LOCKED = 1 visto por SPI", UVM_LOW
            )
        
        //readback de system control
        check_reg(REG_SYSTEM_CONTROL, {28'b0, div_sel, 1'b1, 1'b0});
    endtask

endclass : spi_pll_cfg_seq