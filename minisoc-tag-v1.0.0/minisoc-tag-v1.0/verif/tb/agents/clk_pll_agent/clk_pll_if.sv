interface clk_pll_if;
    timeunit 1ps;
    timeprecision 1ps;

    //clk de referencia
    //2ghz -> periodo de 500 ps -> semiperiodo de 250ps
    logic clk = 1'b0;
    bit clk_en = 1'b1;
    time half_period_ps = 250ps;

    //sinais do dut
    logic rst_n;
    logic pll_enable;
    logic [1:0] pll_div_sel;
    logic pll_locked;
    logic sys_clk;
    logic sys_rst_n;

    //gerador fisico do clk alwayson
    always begin
        #(half_period_ps);
        if(clk_en)
            clk = ~clk;
        else
            clk = 1'b0;
    end

    // ------------------------------------------------------------------------
    // A-02 do Verification Plan  --  REQ-PLL-01
    //
    // "O clock do sistema so e liberado apos PLL_LOCKED."
    //
    // Enquanto o PLL nao estiver locked, o sys_clk tem de permanecer em 0.
    // Se esta assertion falhar, o AES poderia estar operando com um clock
    // invalido, o que e exatamente o que o REQ-PLL-01 proibe.
    //
    // O disable usa "rst_n !== 1'b1" em vez de "!rst_n" porque antes do
    // primeiro reset o rst_n vale X: com !rst_n a expressao daria X e o
    // comportamento do disable ficaria ambiguo. Assim a checagem so vale
    // quando o reset esta comprovadamente liberado.
    // ------------------------------------------------------------------------
    property p_sys_clk_gated_until_lock;
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (!pll_locked) |-> (sys_clk === 1'b0);
    endproperty

    a_sys_clk_gated_until_lock: assert property (p_sys_clk_gated_until_lock)
        else $error("A-02: sys_clk ativo com PLL_LOCKED=0 -- viola o REQ-PLL-01");

    // Cover para provar que a janela "PLL desligado" foi de fato exercitada,
    // e nao que a assertion passou por vacuidade.
    c_pll_not_locked: cover property (
        @(posedge clk) disable iff (rst_n !== 1'b1) (!pll_locked)
    );

endinterface: clk_pll_if
