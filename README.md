# MiniSoC AES — Ambiente de Verificação UVM

Ambiente de verificação em **SystemVerilog/UVM 1.2** para o **MiniSoC AES**, um sistema de topo com um núcleo AES-128, memória compartilhada de 1024 × 32 bits, front-end SPI de configuração e um PLL mock com divisor de frequência.

Projeto Integrador de Design Verification da **Residência em Microeletrônica (CI Expert / Softex) — Polo UFCG**.

---

## Status

| Marco | Conteúdo | Status |
| --- | --- | --- |
| Out/2026 | VPLAN v1, arquitetura do TB, baseline compilando, VIPs de clock e reset, smoke test | ✅ Concluído |
| Nov/2026 | VIPs de SPI e MEMORY DATA, configuração básica do DUT, primeiros testes de interface | ✅ Concluído |
| Dez/2026 | Scoreboard com modelo de referência AES, fluxo end-to-end, primeira regressão | ⏳ Planejado |
| Jan/2027 | Suíte de testes ampliada, cobertura funcional, regressão automatizada | ⏳ Planejado |
| Fev/2027 | Fechamento de cobertura, Verification Guide e Verification Report | ⏳ Planejado |

---

## O DUT

O MiniSoC expõe quatro grupos de interface:

| Interface | Sinais | Descrição |
| --- | --- | --- |
| CLK | `clk` | Referência de 2 GHz, sempre ligada |
| RESET | `rst_n` | Reset global ativo em nível baixo |
| SPI | `spi_sclk`, `spi_cs_n`, `spi_mosi`, `spi_miso` | Mode 0, MSB-first, até 25 MHz, frame de 40 bits |
| MEMORY DATA | `mem_clk`, `mem_i_data`, `mem_i_wr_en`, `mem_i_addr`, `mem_o_data` | Porta externa da SRAM, até 200 MHz, leitura com 1 ciclo de latência |

**Blocos internos:**

- **SPI front-end:** banco de registradores 0x00–0x0F. Roda no clock de referência, então funciona mesmo com o PLL desligado.
- **PLL mock:** gera o `sys_clk` do AES com divisor /1, /2, /4 ou /8. Só libera o clock depois do `PLL_LOCKED`.
- **AES-128:** modos ECB, CBC, PCBC, CFB, OFB e CTR, cifra e decifra de 1 a 256 blocos, processando *in-place* na memória.
- **Memória:** 1024 palavras de 32 bits, com dono único definido por `MEM_SEL_AES`.

**Frame SPI (40 bits):**

```
 39    38:33   32     31:0
[RWb | ADDR  | RSV | DATA ]
```

Escrita usa 1 frame. Leitura usa 2: o frame A pede o endereço e o frame B traz o dado pelo `miso`, usando o endereço 0x3F (NOP).

**Mapa de registradores:**

| Endereço | Registrador | Acesso | Campos |
| --- | --- | --- | --- |
| 0x00–0x03 | KEY0–KEY3 | R/W | Chave de 128 bits (KEY0 = MSB) |
| 0x04–0x07 | IV0–IV3 | R/W | Vetor de inicialização de 128 bits |
| 0x08–0x09 | COUNTER_HI/LO | R/W | Contador de 64 bits (modo CTR) |
| 0x0A | NUM_BLOCKS | R/W | `[8:0]` número de blocos, 1 a 256 |
| 0x0B | AES_CONTROL | R/W | `[0]` START, `[1]` DECRYPT, `[4:2]` MODE |
| 0x0C | AES_STATUS | R | `[0]` BUSY, `[1]` DONE, `[2]` ERROR, `[11:3]` BLOCKS_DONE |
| 0x0D | VERSION | R | `0x0001_0100` |
| 0x0E | SYSTEM_CONTROL | R/W | `[0]` MEM_SEL_AES, `[1]` PLL_ENABLE, `[3:2]` PLL_DIV_SEL |
| 0x0F | SYSTEM_STATUS | R | `[0]` PLL_LOCKED |

---

## Arquitetura do testbench

```
top_tb
├── DUT (minisoc_top)
├── rst_if · clk_pll_if · spi_if · mem_if      (uma interface por grupo de pinos)
└── uvm_test
    └── minisoc_environment
        ├── rst_agent      ─► rst_listener
        ├── clk_pll_agent  ─► clk_listener
        ├── spi_agent      ─► spi_listener
        └── mem_agent      ─► mem_listener
```

- Cada agente tem **sequencer, driver e monitor** e recebe a interface virtual pelo seu objeto de configuração (`*_cfg`).
- O environment liga cada agente com uma chave (`use_rst`, `use_clk`, `use_spi`, `use_mem`). Reset e clock vêm ligados por padrão.
- Os monitores são passivos e publicam um item por transação num *analysis port*, assinado pelo listener correspondente.

**O caso do PLL:** o PLL não tem pinos na fronteira do chip. O enable e o divisor vêm do registrador SYSTEM_CONTROL e o `sys_clk` é interno. Por isso:

- o **estímulo** do PLL vem do **agente SPI** (escrita em 0x0E);
- a **observação** fica no **agente de clock**, que recebe `pll_enable`, `pll_div_sel`, `pll_locked` e `sys_clk` por sondas hierárquicas no `top_tb`.

---

## Estrutura do repositório

```
minisoc-tag-v1.0.0/minisoc-tag-v1.0/
├── frontend/
│   ├── rtl/                      RTL do MiniSoC (fornecido)
│   │   ├── minisoc_top.sv
│   │   ├── minisoc_spi/  minisoc_pll/  minisoc_aes/  minisoc_mem/
│   └── tb/                       testbenches dos blocos (fornecidos)
└── verif/tb/                     ambiente UVM
    ├── top_tb.sv
    ├── top_assertions.sv
    ├── Makefile
    ├── agents/
    │   ├── rst_agent/
    │   ├── clk_pll_agent/
    │   ├── spi_agent/
    │   └── mem_agent/
    ├── env/                      environment e listeners
    ├── sequences/
    ├── tests/
    └── refmod/                   modelo de referência AES em C++ (DPI), ainda não integrado
```

---

## Como executar

Requisitos: **Synopsys VCS** (testado com X-2025.06-SP2) com UVM 1.2 e **Verdi** para as formas de onda.

```bash
source /Tools/synopsys-scripts/snps.sh
cd minisoc-tag-v1.0.0/minisoc-tag-v1.0/verif/tb

make vcs_comp          # compila RTL + testbench
make run_rst_smoke     # roda um teste (veja a tabela abaixo)
```

| Alvo do Makefile | Teste |
| --- | --- |
| `run_rst_smoke` | `rst_smoke_test` |
| `run_spi_smoke` | `spi_smoke_test` |
| `run_mem_smoke` | `mem_smoke_test` |
| `run_dut_cfg` | `dut_cfg_test` (grava `dut_cfg.fsdb` e `dut_cfg_test.log`) |

Para rodar outro teste ou mudar a verbosidade:

```bash
./simv +UVM_TESTNAME=<nome_do_teste> +UVM_VERBOSITY=UVM_LOW
```

Formas de onda:

```bash
verdi -dbdir ./simv.daidir -ssf dut_cfg.fsdb &     # ondas do dut_cfg_test
make verdi                                         # ondas padrão (minisoc_waves.fsdb)
```

---

## Testes

| Teste | O que faz | Checagens |
| --- | --- | --- |
| `rst_smoke_test` | Um reset síncrono e um assíncrono; caracteriza o clock de referência | Contagem de resets e de itens do monitor de clock |
| `spi_smoke_test` | Escreve KEY0, relê KEY0 e lê VERSION | Readback e contagem de 5 frames |
| `mem_smoke_test` | Escreve e lê 4 palavras (um bloco AES) | Readback e contagem de 8 acessos |
| `dut_cfg_test` | Reset → configuração do AES por SPI → PLL nos 4 divisores | Readback dos 12 registradores do AES e do SYSTEM_CONTROL; lock e período do `sys_clk` no monitor de clock; ≥ 5 itens publicados pelo monitor |

### Sequences

| Sequence | Função |
| --- | --- |
| `rst_init_seq` | Reset inicial síncrono |
| `rst_smoke_seq` | Reset síncrono seguido de reset assíncrono |
| `spi_smoke_seq` | Escrita e leitura de KEY0, leitura de VERSION |
| `mem_smoke_seq` | Escrita e leitura de 4 palavras |
| `spi_base_seq` | Base de acesso a registrador: `write_reg`, `read_reg`, `check_reg` |
| `spi_aes_cfg_seq` | Sorteia uma configuração válida do AES, escreve os 12 registradores (0x00–0x0B) e relê todos |
| `spi_pll_cfg_seq` | Desliga o PLL, programa o divisor, liga, faz polling de PLL_LOCKED e relê SYSTEM_CONTROL |

### Checagens implementadas

- **Readback de registradores e memória**, nas sequences, com `uvm_error` em caso de divergência.
- **`clk_pll_monitor`**, com três threads:
  - período do clock de referência (500 ± 50 ps, REQ-CLK-01);
  - watchdog de clock parado (100 ns);
  - PLL: latência de lock e período do `sys_clk` para cada divisor (tabela 4.1 do Block Guide).
- **Assertion A-02** em `clk_pll_if`: `sys_clk` parado enquanto `PLL_LOCKED = 0` (REQ-PLL-01), com cover associado.

### Resultado do `dut_cfg_test`

| PLL_DIV_SEL | `sys_clk` esperado | Medido | Lock |
| --- | --- | --- | --- |
| 00 (/1) | 0,5 ns | 0,500 ns | 30 ciclos |
| 01 (/2) | 1,0 ns | 1,000 ns | 31 ciclos |
| 10 (/4) | 2,0 ns | 2,000 ns | 17 ciclos |
| 11 (/8) | 4,0 ns | 4,000 ns | 14 ciclos |

`UVM_ERROR: 0`, `UVM_FATAL: 0`, 16 readbacks SPI conferidos.

---

## Limitações e pontos em aberto

- **Checagens nas sequences e no monitor:** neste estágio não há scoreboard. As checagens de registrador e de memória migram para checkers no environment no marco de dezembro.
- **Faixa de lock do PLL:** a especificação só diz que o tempo de lock é pseudoaleatório. A faixa usada (8 a 31 ciclos, mais 2 de folga de amostragem) vem dos parâmetros do PLL mock.
- **Reset interno após religar o PLL:** o `sys_rst_n` não volta a 0 quando o PLL é desligado e religado; ele só é reaplicado pelo reset global. A confirmar se é o comportamento pretendido.
- **Monitor de memória:** a interface não tem sinal de enable (todo ciclo com `wr_en = 0` é uma leitura), então o monitor usa um sinal lateral do testbench (`tb_valid`) para identificar os acessos do driver.

---

## Próximos passos

- [ ] Sequences de memória para carregar e ler N blocos
- [ ] Troca de dono da memória (`MEM_SEL_AES`) e START com polling de `AES_STATUS`
- [ ] Integração do modelo de referência AES (C++ via DPI) e scoreboard com memória-sombra
- [ ] Teste end-to-end (T-AES-E2E) e primeira regressão
- [ ] Assertions restantes do VPLAN (A-01, A-03 a A-08) e cobertura funcional

---

## Referências

- *Block Guide — MiniSoC AES: System Architecture and RTL Specification*, v1.0.0
- *Verification Plan — Fase 2*, MiniSoC AES
- NIST FIPS 197 — Advanced Encryption Standard (AES)
- Accellera UVM 1.2 User Guide

---

**Autor:** Alessandro Lucas — Residência em Microeletrônica, Polo UFCG
