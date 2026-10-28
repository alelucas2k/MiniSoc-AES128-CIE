class clk_pll_seq_item extends uvm_sequence_item;

    //controles do driver
    rand bit clk_en;
    rand time ref_half_period_ps;

    //amostras pra scb e cov
    bit pll_enable;
    bit [1:0] pll_div_sel;
    bit pll_locked;
    time measured_sys_clk_period_ps;
    int lock_latency_ref_cycles;

    constraint c_nominal_2ghz{
        clk_en == 1'b1;
        ref_half_period_ps == 250ps;
    }


    // Regista o sequence_item na UVM Factory e automatiza os metods print(), copy(),
    // compare() e record() para tods os campos listados, definindo a formatação de
    // exibição no log (binário, tempo ou decimal).
    `uvm_object_utils_begin(clk_pll_seq_item)
        `uvm_field_int(clk_en,                     UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(ref_half_period_ps,         UVM_ALL_ON | UVM_TIME)
        `uvm_field_int(pll_enable,                 UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(pll_div_sel,                UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(pll_locked,                 UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(measured_sys_clk_period_ps, UVM_ALL_ON | UVM_TIME)
        `uvm_field_int(lock_latency_ref_cycles,    UVM_ALL_ON | UVM_DEC)
    `uvm_object_utils_end

    function new(string name = "clk_pll_seq_item");
        super.new(name);
        
    endfunction

endclass: clk_pll_seq_item