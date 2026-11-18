// ----------------------------------------------------------------------------
// Objeto de configuracao do agente SPI.
//
// Guarda o handle da interface virtual (que o teste pega do config_db e
// repassa para driver/monitor) e os tempos do protocolo.
// ----------------------------------------------------------------------------
class spi_cfg extends uvm_object;
    `uvm_object_utils(spi_cfg)

    virtual spi_if vif;
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    // SCLK de 25 MHz -> periodo de 40 ns -> semiperiodo de 20 ns
    time sclk_half_period = 20ns;

    // Tempo com cs_n = 1 entre dois frames. Precisa ser maior que alguns
    // ciclos do clock de 2 GHz para o evento de frame atravessar o CDC
    // (sclk -> clk always-on) dentro do minisoc_spi.
    time cs_idle_time = 80ns;

    function new(string name = "spi_cfg");
        super.new(name);
    endfunction

endclass : spi_cfg
