`ifndef CLK_LISTENER_SV
`define CLK_LISTENER_SV

class clk_listener extends uvm_subscriber #(clk_pll_seq_item);
    `uvm_component_utils(clk_listener)

    int count = 0;

    function new(string name = "clk_listener", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void write(clk_pll_seq_item t);
        count++;
        `uvm_info("CLK_LISTENER", $sformatf("Monitor capturou clock #%0d. Item:", count), UVM_LOW)
        t.print();
    endfunction
endclass : clk_listener

`endif