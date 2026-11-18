package mem_agent_pkg;
    timeunit 1ps;
    timeprecision 1ps;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "mem_cfg.sv"
    `include "mem_seq_item.sv"
    `include "mem_sequencer.sv"
    `include "mem_driver.sv"
    `include "mem_monitor.sv"
    `include "mem_agent.sv"

endpackage : mem_agent_pkg
