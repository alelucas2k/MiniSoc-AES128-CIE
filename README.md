# 🔐 MiniSoC AES — System-on-Chip & UVM Verification Environment

> Complete **System-on-Chip (SoC)** integration and **Universal Verification Methodology (UVM)** testbench environment for a hardware-accelerated **AES-128 cryptographic system** with shared SRAM, SPI control, and multi-domain clock generation.

---

## 📌 Overview

The **MiniSoC AES** is an integrated System-on-Chip designed for hardware cryptography and advanced digital design verification. It features an **AES-128 core**, a **1024x32-bit shared physical SRAM**, a **40-bit SPI control front-end**, and a **Mock PLL** with runtime clock division.

This repository contains both the **RTL hardware design** (`minisoc_top.sv`) and a complete, production-grade **UVM Verification Environment** built to validate the chip's functional correctness, corner cases, register access protocols, and crypto operations across all operating modes.

---


### Key Sub-modules

1. **SPI Front-End (`minisoc_spi.sv`)**:
   - **Protocol**: SPI Mode 0 (CPOL=0, CPHA=0), MSB-first, up to 25 MHz.
   - **Frame Size**: 40 bits (1-bit `R/Wb` + 6-bit `ADDR` + 1-bit `RSV` + 32-bit `DATA`).
   - **Register Map**: Addresses `0x00`–`0x0F` (Keys, IVs, Counter, Control/Status, PLL Config).
2. **PLL Mock (`minisoc_pll_mock.sv`)**:
   - Divides external reference clock (`clk` = 2 GHz) into selectable system clocks: **2 GHz** (`/1`), **1 GHz** (`/2`), **500 MHz** (`/4`), and **250 MHz** (`/8`).
   - Asserts `PLL_LOCKED = 1` when system clock (`sys_clk`) stabilizes.
3. **AES-128 Engine (`minisoc_aes/`)**:
   - Hardware implementation of 10-round AES-128 encryption/decryption.
   - Supports **6 modes of operation**: `ECB` (000), `CBC` (001), `PCBC` (010), `CFB` (011), `OFB` (100), `CTR` (101).
   - Processes **1 to 256 blocks** of 128 bits *in-place* directly in memory.
4. **Shared SRAM Memory (`minisoc_memory.sv`)**:
   - 1024 words of 32 bits (4 KB total), storing up to 256 AES blocks (4x32-bit words per block).
   - Single-port SRAM arbitrated via `SYSTEM_CONTROL.MEM_SEL_AES`.

---

## ⚡ Architectural Rules & Execution Flow

### Critical Design Rules

* **SPI Bootstrap Rule**: The SPI Front-End runs directly on the always-on 2 GHz reference clock (`clk`), allowing full configuration and PLL activation even when `sys_clk` is stopped.
* **Memory Mutual Exclusion**: Memory ownership is controlled by `MEM_SEL_AES`:
  * `0`: External `MEMORY DATA` interface controls SRAM.
  * `1`: AES Engine controls SRAM.
  * *Switching ownership requires AES to be idle (`BUSY = 0`).*

### Execution Sequence (End-to-End Flow)

```
1. Reset         2. Data Load       3. SPI Config      4. PLL Lock        5. Memory Handover  6. Crypto Exec    7. Read Results
[rst_n = 0->1] -> [Load Data via] -> [Program Key,  ] -> [Enable PLL &] -> [Set MEM_SEL_  ] -> [Write START] -> [Set MEM_SEL_  ]
                  [MEMORY DATA  ]    [IV, Mode, Blks]    [wait LOCKED ]    [AES = 1      ]    [wait DONE  ]    [AES = 0 & Read ]
```

---

## 📜 Register Map (SPI Address 0x00 – 0x0F)

| Address | Name | Access | Description |
| :---: | :--- | :---: | :--- |
| `0x00`–`0x03` | **KEY0–KEY3** | R/W | 128-bit AES cryptographic key (`KEY0` = MSB, `KEY3` = LSB) |
| `0x04`–`0x07` | **IV0–IV3** | R/W | 128-bit Initial Vector for CBC/PCBC/CFB/OFB/CTR |
| `0x08`–`0x09` | **COUNTER_HI/LO** | R/W | 64-bit initial counter value for CTR mode |
| `0x0A` | **NUM_BLOCKS** | R/W | Number of 128-bit blocks to process (**1 to 256**) |
| `0x0B` | **AES_CONTROL** | R/W | `[0]` START, `[1]` DECRYPT, `[4:2]` MODE (`000`=ECB, `001`=CBC, etc.) |
| `0x0C` | **AES_STATUS** | R | `[0]` BUSY, `[1]` DONE, `[2]` ERROR, `[11:3]` BLOCKS_DONE |
| `0x0D` | **VERSION** | R | SPI front-end version hardware ID |
| `0x0E` | **SYSTEM_CONTROL**| R/W | `[0]` MEM_SEL_AES, `[1]` PLL_ENABLE, `[3:2]` PLL_DIV_SEL |
| `0x0F` | **SYSTEM_STATUS** | R | `[0]` PLL_LOCKED (`1` = clock stable) |

---


### Testbench Components

* **SPI Agent (Active/Passive)**: Drives 40-bit SPI frames (`spi_seq_item`) and monitors serial transactions.
* **Memory Agent (Active/Passive)**: Generates parallel SRAM access cycles via `MEMORY DATA` interface.
* **Clock/Reset Agent**: Controls reset assertion (`rst_n`) and reference clock generation (`clk`).
* **AES Predictor / Scoreboard**: Uses a C DPI-C / SystemVerilog reference model to predict expected ciphertext/plaintext and validates in-place SRAM contents.
* **Functional Coverage Group**: Cross-coverage between AES modes, block quantities (1, 2, 256, corner cases), clock division settings, and register access sequences.

---

