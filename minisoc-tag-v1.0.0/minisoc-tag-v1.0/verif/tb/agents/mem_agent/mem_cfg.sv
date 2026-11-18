// ----------------------------------------------------------------------------
// Objeto de configuracao do agente MEMORY DATA.
// Carrega a interface virtual e o modo ativo/passivo.
// ----------------------------------------------------------------------------
class mem_cfg extends uvm_object;
    `uvm_object_utils(mem_cfg)

    virtual mem_if vif;
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name = "mem_cfg");
        super.new(name);
    endfunction

endclass : mem_cfg
