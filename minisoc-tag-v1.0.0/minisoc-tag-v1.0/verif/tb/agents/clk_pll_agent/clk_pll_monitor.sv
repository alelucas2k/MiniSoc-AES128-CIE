// ============================================================================
// Monitor de Clock de Referência / PLL
// ============================================================================
//
// CAMINHO DE DADOS:
//   sondas da clk_pll_if --> monitor --> ap (analysis port) --> listener/scb
//
// Três threads em paralelo, com responsabilidades separadas:
//
//   THREAD 1 - Checagem contínua do clock de referência (REQ-CLK-01)
//       Mede período e tempo em nível alto a cada ciclo e compara com
//       500 ps ± 50 ps. Só PUBLICA quando o valor muda ou quando há
//       violação (ver nota sobre throttling abaixo).
//
//   THREAD 2 - Watchdog de perda de clock
//       Acusa se a referência ficar parada por mais que max_clk_loss_timeout.
//
//   THREAD 3 - Observação do PLL (REQ-PLL-01 e tabela 4.1 do Block Guide)
//       A cada vez que o software liga o PLL via SPI, mede a latência de
//       lock em ciclos de referência e o período do sys_clk, comparando
//       com o divisor latchado.
//
//
// POR QUE ESTE MONITOR SÓ OBSERVA O PLL (e não o dirige):
//   O PLL não tem pinos na fronteira do chip. O i_enable e o i_div_sel vêm
//   dos registradores SPI e as saídas o_clk/o_locked são internas; no top_tb
//   elas chegam nesta interface por sondas hierárquicas. O estímulo do PLL
//   é produzido pelo agente de SPI (spi_pll_enable_seq); aqui só se observa.
//
//
// NOTA SOBRE THROTTLING DA PUBLICAÇÃO:
//   A thread 1 mede a cada ciclo, mas publicar um item por ciclo geraria
//   dezenas de milhares de transações numa simulação de dezenas de µs (o
//   pll_div_test roda ~41 µs). A medição continua ciclo a ciclo — o que
//   importa para pegar glitch —, porém o item só vai para o analysis port
//   quando o período medido MUDA ou quando há violação. Numa corrida
//   saudável isso dá um único item de referência, mais um por ativação
//   do PLL vinda da thread 3.
// ============================================================================
class clk_pll_monitor extends uvm_monitor;
    `uvm_component_utils(clk_pll_monitor)

    virtual clk_pll_if vif;
    clk_cfg cfg;
    uvm_analysis_port #(clk_pll_seq_item) ap;

    // Parâmetros configuráveis de checagem
    realtime expected_period_ns   = 0.5;    // 500 ps = 0.5 ns -> referência de 2 GHz
    realtime period_tolerance_ns  = 0.05;   // tolerância de 50 ps
    time     max_clk_loss_timeout = 100ns;

    // Faixa de lock do minisoc_pll_mock (LOCK_MIN_CYCLES / LOCK_MAX_CYCLES).
    // A folga de +2 cobre o pipeline de detecção do enable: o RTL só percebe
    // a subida do i_enable na borda seguinte (via enable_d) e o monitor lê o
    // pll_locked na região ativa, enxergando o valor de antes da borda em que
    // o NBA do DUT o atualiza. Se o LFSR sorteou N, medimos N+2.
    localparam int LOCK_MIN_CYCLES = 8;
    localparam int LOCK_MAX_CYCLES = 31;
    localparam int LOCK_TOLERANCE  = 2;

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
        // ------------------------------------------------------------------
        // Aguarda a liberação do PRIMEIRO reset de verdade.
        //
        // CUIDADO: não basta "@(posedge vif.rst_n)". O rst_n nasce em X e o
        // rst_driver o leva a 1 no tempo zero; em SystemVerilog a transição
        // X->1 CONTA COMO POSEDGE, então aquele @ sozinho dispararia em t=0,
        // antes da sequence de reset rodar, e a mensagem abaixo seria falsa.
        // Esperar primeiro a BORDA DE DESCIDA garante que o reset começou.
        //
        // Efeito colateral útil: depois do reset o banco SPI já zerou o
        // cfg_pll_enable, então o pll_enable observado na thread 3 não vale
        // mais X e não gera um posedge falso de X->1.
        // ------------------------------------------------------------------
        @(negedge vif.rst_n);
        @(posedge vif.rst_n);
        `uvm_info("CLK_MON", $sformatf(
            "Reset liberado em %0t. Iniciando monitoramento do clock/PLL...", $time), UVM_LOW);

        fork
            // ================================================================
            // THREAD 1: checagem contínua do clock de referência
            // ================================================================
            begin
                realtime t_pos1, t_neg, t_pos2;
                realtime period, high_time;
                realtime period_ns;
                realtime last_published_ns = -1.0;  // -1 força a 1a publicação
                bit      violation;
                clk_pll_seq_item item;

                forever begin
                    @(posedge vif.clk);
                    t_pos1 = $realtime;

                    @(negedge vif.clk);
                    t_neg = $realtime;

                    @(posedge vif.clk);
                    t_pos2 = $realtime;

                    period    = t_pos2 - t_pos1;
                    high_time = t_neg - t_pos1;
                    period_ns = period / 1ns;

                    // Validação de tolerância do período (REQ-CLK-01)
                    violation = (period_ns < (expected_period_ns - period_tolerance_ns)) ||
                                (period_ns > (expected_period_ns + period_tolerance_ns));

                    if (violation)
                        `uvm_error("CLK_PERIOD_VIOLATION",
                            $sformatf("Periodo invalido! Esperado: %.3f ns, Detectado: %.3f ns (Tolerancia: %.3f ns)",
                                      expected_period_ns, period_ns, period_tolerance_ns))

                    // Publica só na mudança ou na violação (ver nota de throttling)
                    if (violation || (period_ns != last_published_ns)) begin
                        last_published_ns = period_ns;

                        item = clk_pll_seq_item::type_id::create("item_ref_clk", this);
                        item.clk_en             = vif.clk_en;
                        // high_time é o tempo em nível alto; com duty de 50%
                        // ele equivale ao semiperíodo da referência.
                        item.ref_half_period_ps = time'(high_time / 1ps);
                        item.pll_enable         = vif.pll_enable;
                        item.pll_div_sel        = vif.pll_div_sel;
                        item.pll_locked         = vif.pll_locked;
                        // Campos de PLL ficam zerados aqui: quem os preenche
                        // é a thread 3. Não gravamos o período da REFERÊNCIA
                        // num campo chamado measured_sys_clk_period_ps.
                        item.measured_sys_clk_period_ps = 0;
                        item.lock_latency_ref_cycles    = 0;

                        `uvm_info("CLK_MON", $sformatf(
                            "[REF] Clock de referencia: periodo = %.3f ns (%.0f MHz)",
                            period_ns, 1000.0/period_ns), UVM_LOW);

                        ap.write(item);
                    end
                end
            end

            // ================================================================
            // THREAD 2: detecção de travamento ou perda de clock
            // ================================================================
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

            // ================================================================
            // THREAD 3: observação do PLL
            //
            // SEQUÊNCIA ESPERADA NO DUT:
            //   1. O software escreve PLL_ENABLE=1 em SYSTEM_CONTROL via SPI.
            //      O mock LATCHA o PLL_DIV_SEL exatamente nessa borda.
            //   2. O mock espera de 8 a 31 ciclos de referência (LFSR) e
            //      levanta o pll_locked.
            //   3. SÓ APÓS O LOCK o sys_clk é liberado  -> REQ-PLL-01.
            //   4. O sys_clk corre na frequência do divisor latchado.
            //
            // A latência é medida com timestamps e não com um contador
            // amostrado a cada borda: marcar $realtime nas duas pontas e
            // dividir pelo período da referência dá o mesmo resultado sem
            // depender da ordem de avaliação entre o NBA do DUT e a leitura
            // do monitor.
            // ================================================================
            begin
                realtime  t_enable, t_locked;
                realtime  t_sys0, t_sys1;
                realtime  sys_period_ns, expected_sys_ns, sys_tolerance_ns;
                int       lock_cycles;
                bit [1:0] div_sel_sampled;
                clk_pll_seq_item item;

                forever begin
                    // --- 1. Espera o software ligar o PLL ------------------
                    @(posedge vif.pll_enable);
                    t_enable        = $realtime;
                    div_sel_sampled = vif.pll_div_sel;

                    `uvm_info("CLK_MON", $sformatf(
                        "[PLL] Habilitado em %0t com PLL_DIV_SEL=%02b (divisor /%0d)",
                        $time, div_sel_sampled, (1 << div_sel_sampled)), UVM_MEDIUM);

                    // --- 2. Espera o lock ---------------------------------
                    // A condição também olha o pll_enable: se o software
                    // desabilitar no meio da aquisição, saímos desta
                    // observação em vez de ficar presos para sempre.
                    while (!vif.pll_locked && vif.pll_enable)
                        @(posedge vif.clk);

                    if (!vif.pll_enable) begin
                        `uvm_info("CLK_MON",
                            "[PLL] Desabilitado antes do lock; observacao abortada", UVM_MEDIUM);
                        continue;
                    end

                    t_locked    = $realtime;
                    lock_cycles = int'(((t_locked - t_enable) / 1ns) / expected_period_ns);

                    // --- 3. Mede o período do sys_clk ---------------------
                    // A primeira borda é descartada de propósito: o gate do
                    // clock no RTL abre numa borda de descida da referência,
                    // então a primeira borda do sys_clk pode não representar
                    // um período em regime permanente.
                    @(posedge vif.sys_clk);
                    @(posedge vif.sys_clk); t_sys0 = $realtime;
                    @(posedge vif.sys_clk); t_sys1 = $realtime;
                    sys_period_ns = (t_sys1 - t_sys0) / 1ns;

                    // --- 4. Período esperado pela tabela 4.1 --------------
                    //   00 -> /1 -> 2.000 GHz     10 -> /4 -> 500 MHz
                    //   01 -> /2 -> 1.000 GHz     11 -> /8 -> 250 MHz
                    expected_sys_ns  = expected_period_ns * (1 << div_sel_sampled);
                    sys_tolerance_ns = period_tolerance_ns * (1 << div_sel_sampled);

                    // --- 5. Checagens --------------------------------------
                    // NOTA DE ARQUITETURA: checar dentro do monitor é
                    // pragmático enquanto não existe scoreboard. Quando ele
                    // entrar no env, estes dois ifs migram para lá e o
                    // monitor volta a apenas medir e publicar.
                    if ((sys_period_ns < (expected_sys_ns - sys_tolerance_ns)) ||
                        (sys_period_ns > (expected_sys_ns + sys_tolerance_ns)))
                        `uvm_error("SYS_CLK_PERIOD_VIOLATION", $sformatf(
                            "Periodo do sys_clk errado para PLL_DIV_SEL=%02b: esperado %.3f ns, medido %.3f ns",
                            div_sel_sampled, expected_sys_ns, sys_period_ns))
                    else
                        `uvm_info("CLK_MON", $sformatf(
                            "[PLL] sys_clk OK: %.3f ns (%.0f MHz) para PLL_DIV_SEL=%02b",
                            sys_period_ns, 1000.0/sys_period_ns, div_sel_sampled), UVM_LOW);

                    if (lock_cycles < LOCK_MIN_CYCLES ||
                        lock_cycles > (LOCK_MAX_CYCLES + LOCK_TOLERANCE))
                        `uvm_error("PLL_LOCK_LATENCY", $sformatf(
                            "Latencia de lock fora da faixa do mock: medido %0d ciclos, esperado entre %0d e %0d",
                            lock_cycles, LOCK_MIN_CYCLES, LOCK_MAX_CYCLES + LOCK_TOLERANCE))
                    else
                        `uvm_info("CLK_MON", $sformatf(
                            "[PLL] Lock em %0d ciclos de referencia", lock_cycles), UVM_LOW);

                    // --- 6. Monta e publica o item -------------------------
                    item = clk_pll_seq_item::type_id::create("item_pll_lock", this);
                    item.clk_en                     = vif.clk_en;
                    item.ref_half_period_ps         = time'((expected_period_ns/2.0) * 1000);
                    item.pll_enable                 = vif.pll_enable;
                    item.pll_div_sel                = div_sel_sampled;
                    item.pll_locked                 = vif.pll_locked;
                    item.measured_sys_clk_period_ps = time'(sys_period_ns * 1000); // ns -> ps
                    item.lock_latency_ref_cycles    = lock_cycles;

                    ap.write(item);
                end
            end
        join

    endtask

endclass: clk_pll_monitor