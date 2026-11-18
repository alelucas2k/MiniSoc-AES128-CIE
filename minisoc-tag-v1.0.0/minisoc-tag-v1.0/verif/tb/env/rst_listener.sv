`ifndef RST_LISTENER_SV
`define RST_LISTENER_SV

class rst_listener extends uvm_subscriber #(rst_seq_item);
    `uvm_component_utils(rst_listener)

    int count = 0;

    function new(string name = "rst_listener", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void write(rst_seq_item t);
        count++;
        `uvm_info("RST_LISTENER", $sformatf("Monitor capturou reset #%0d. Item:", count), UVM_LOW)
        t.print();
    endfunction
endclass : rst_listener

`endif