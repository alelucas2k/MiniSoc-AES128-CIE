class rst_cfg extends uvm_objetc;
    `uvm_object_utils(rst_cfg)

    virtual rst_if vif;
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name = "rst_cfg");
        super.new(name);
    endfunction //new()

endclass //rst_cfg