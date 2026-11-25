
class rst_init_seq extends uvm_sequence #(rst_seq_item);
    `uvm_object_utils(rst_init_seq)

    function new(string name = "rst_init_seq");
        super.new(name);
    endfunction

    virtual task body();
        rst_seq_item req;

        `uvm_info("RST_INIT_SEQ", "---> aplicando reset inicial", UVM_LOW)
        req = rst_seq_item::type_id::create("req_init");
        start_item(req);
        if (!req.randomize() with {
            sync_to_clk            == 1'b1;
            cycles_before_assert   == 2;
            assert_duration_cycles == 10;
            cycles_after_deassert  == 5;
        }) `uvm_fatal("RST_INIT_SEQ", "Falha na randomizacao do reset inicial")
        finish_item(req);
    endtask

endclass : rst_init_seq
