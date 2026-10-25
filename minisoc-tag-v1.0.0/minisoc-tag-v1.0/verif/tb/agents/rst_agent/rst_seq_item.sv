class rst_seq_item extends uvm_sequence_item;

  // Parâmetros de estímulo (usados pelo Driver)
  rand int unsigned cycles_before_assert;   // Atraso antes de baixar rst_n
  rand int unsigned assert_duration_cycles; // Quantos ciclos de 2GHz rst_n fica em 0
  rand int unsigned cycles_after_deassert;  // Tempo de guarda após subir rst_n
  rand bit          sync_to_clk;            // 1 = síncrono ao clk, 0 = assíncrono (delay em ps)
  rand int unsigned async_delay_ps;         // Offset em picosegundos para testar reset assíncrono

  // Campos preenchidos pelo Monitor para o Scoreboard/Coverage
  time start_time_ps;
  time end_time_ps;
  time duration_ps;

  // Constraints padrão razoáveis (podem ser sobrescritas ou desligadas nos testes)
  constraint c_default_timing {
    cycles_before_assert   inside {[0:20]};
    assert_duration_cycles inside {[4:50]};  // 4 ciclos de 2GHz = 2ns; 20 ciclos = 10ns
    cycles_after_deassert  inside {[2:20]};
    async_delay_ps         inside {[10:490]}; // Cai fora da borda de subida de 500ps
  }


  //macros da factory
  `uvm_object_utils_begin(rst_seq_item)
    `uvm_field_int(cycles_before_assert,   UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(assert_duration_cycles, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(cycles_after_deassert,  UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(sync_to_clk,            UVM_ALL_ON | UVM_BIN)
    `uvm_field_int(async_delay_ps,         UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(duration_ps,            UVM_ALL_ON | UVM_TIME)
  `uvm_object_utils_end

  function new(string name = "rst_seq_item");
    super.new(name);
  endfunction

endclass : rst_seq_item


