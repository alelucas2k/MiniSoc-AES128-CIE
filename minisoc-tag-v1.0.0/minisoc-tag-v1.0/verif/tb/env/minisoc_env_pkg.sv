`ifndef MINISOC_ENV_PKG_SV
`define MINISOC_ENV_PKG_SV

package minisoc_env_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    //pacotes dos agentes utilizados no ambiente
    import rst_agent_pkg::*;
    import clk_pll_agent_pkg::*;
    import spi_agent_pkg::*;
    import mem_agent_pkg::*;

    //componentes do ambiente
    `include "rst_listener.sv"
    `include "clk_listener.sv"
    `include "spi_listener.sv"
    `include "mem_listener.sv"
    `include "minisoc_environment.sv"

endpackage : minisoc_env_pkg

`endif