`ifndef RST_SMOKE_SEQ_SV
`define RST_SMOKE_SEQ_SV

class rst_smoke_seq extends uvm_sequence #(rst_seq_item);
    `uvm_object_utils(rst_smoke_seq)

    function new(string name = "rst_smoke_seq");
        super.new(name);
    endfunction

    
    virtual task body();
        rst_seq_item req;


        //reset sincrono 20 ciclos de 500 ps
        `uvm_info("RST_SEQ", "---> disparando reset sincrono", UVM_LOW)
        req = rst_seq_item::type_id::create("req_sync");
        start_item(req);
        if(!req.randomize()with{
            sync_to_clk == 1'b1;
            cycles_before_assert == 2;
            assert_duration_cycles == 20;
            cycles_after_deassert == 5;
        }) `uvm_fatal("RST_SEQ", "Falha na randomizacao do reset 1")
        finish_item(req);


        //reset em runtime assincrono
        `uvm_info("RST_SEQ", "---> disparando reset assincrono", UVM_LOW)
        req = rst_seq_item::type_id::create("req_async");
        start_item(req);
        if(!req.randomize()with{
            sync_to_clk == 1'b0;
        }) `uvm_fatal("RST_SEQ", "Falha na randomizacao do reset 2")
        finish_item(req);
    endtask

endclass : rst_smoke_seq

`endif
