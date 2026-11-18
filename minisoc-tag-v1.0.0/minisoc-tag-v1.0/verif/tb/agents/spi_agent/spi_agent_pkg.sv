package spi_agent_pkg;
    timeunit 1ps;
    timeprecision 1ps;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "spi_cfg.sv"
    `include "spi_seq_item.sv"
    `include "spi_sequencer.sv"
    `include "spi_driver.sv"
    `include "spi_monitor.sv"
    `include "spi_agent.sv"

endpackage : spi_agent_pkg
