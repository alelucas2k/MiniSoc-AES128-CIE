class clk_cfg extends uvm_object;
    `uvm_object_utils(clk_cfg)

    virtual clk_pll_if vif;
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    time default_half_period_ps = 250ps; //-> 2ghz nominal

    function new(string name = "clk_cfg");
        super.new(name);
    endfunction

endclass: clk_cfg