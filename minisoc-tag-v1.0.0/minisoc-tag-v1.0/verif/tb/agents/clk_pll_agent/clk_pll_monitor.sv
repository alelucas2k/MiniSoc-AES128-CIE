class clk_pll_monitor extends uvm_monitor;
    `uvm_component_utils(clk_pll_monitor)

    virtual clk_pll_if vif;
    clk_cfg cfg;
    uvm_analysis_port #(clk_pll_seq_item) ap;

    // Parâmetros configuráveis de checagem
    realtime expected_period_ns       = 0.5;   // 500 ps = 0.5 ns (Ex: referência de 2 GHz)
    realtime period_tolerance_ns      = 0.05;  // Tolerância de 50 ps
    time     max_clk_loss_timeout     = 100ns;

    function new(string name = "clk_pll_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(clk_cfg)::get(this, "", "cfg", cfg))
            `uvm_fatal("CLK_MON", "Nao foi possivel achar clk_cfg do config_db")
        vif = cfg.vif;
    endfunction

    virtual task run_phase(uvm_phase phase);
        // 1. Aguarda a liberacao do primeiro reset para comecar a observar o clock
        @(posedge vif.rst_n);
        `uvm_info("CLK_MON", "Reset liberado. Iniciando monitoramento do clock/PLL...", UVM_LOW);

        fork
            // Thread 1: Monitoramento contínuo e preenchimento do clk_pll_seq_item
            begin
                realtime t_pos1, t_neg, t_pos2;
                realtime period, high_time;
                realtime period_ns;
                clk_pll_seq_item item;

                forever begin
                    // Medição ciclo a ciclo (baseada na captura anterior)
                    @(posedge vif.clk);
                    t_pos1 = $realtime;

                    @(negedge vif.clk);
                    t_neg = $realtime;

                    @(posedge vif.clk);
                    t_pos2 = $realtime;

                    period    = t_pos2 - t_pos1;
                    high_time = t_neg - t_pos1;
                    period_ns = period / 1ns;

                    // Validação de tolerância do período
                    if ((period_ns < (expected_period_ns - period_tolerance_ns)) ||
                        (period_ns > (expected_period_ns + period_tolerance_ns))) begin
                        `uvm_error("CLK_PERIOD_VIOLATION",
                            $sformatf("Periodo invalido! Esperado: %.3f ns, Detectado: %.3f ns (Tolerancia: %.3f ns)",
                                      expected_period_ns, period_ns, period_tolerance_ns))
                    end

                    // Criação e preenchimento usando os campos da sua clk_pll_seq_item
                    item = clk_pll_seq_item::type_id::create("item", this);
                    
                    // Controles e estado amostrados da interface
                    item.clk_en                     = vif.clk_en;
                    item.ref_half_period_ps         = time'(high_time / 1ps); // Ou period / 2 conforme sua lógica
                    item.pll_enable                 = vif.pll_enable;
                    item.pll_div_sel                = vif.pll_div_sel;
                    item.pll_locked                 = vif.pll_locked;
                    item.measured_sys_clk_period_ps = time'(period / 1ps);
                    
                    // Nota: 'lock_latency_ref_cycles' geralmente é calculado numa lógica de máquina de estados 
                    // de lock do PLL separada, mas pode ser atribuído aqui se você rastrear a contagem.

                    `uvm_info("CLK_MON", $sformatf("Item coletado -> Período Medido: %0t ps | Lock: %0b | Div: %0d", 
                              item.measured_sys_clk_period_ps, item.pll_locked, item.pll_div_sel), UVM_HIGH);

                    ap.write(item);
                end
            end

            // Thread 2: Detecção de travamento ou perda de clock (Timeout)
            begin
                forever begin
                    fork : clk_timeout_block
                        begin
                            @(posedge vif.clk);
                        end
                        begin
                            #max_clk_loss_timeout;
                            `uvm_error("CLK_LOSS",
                                $sformatf("Clock travado ou inativo por mais de %0t!", max_clk_loss_timeout))
                        end
                    join_any
                    disable clk_timeout_block;
                end
            end
        join

    endtask

endclass: clk_pll_monitor