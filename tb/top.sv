import uvm_pkg::*;
`include "uvm_macros.svh"

module top;

  bit clk;

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns period
  end

  // Instantiate AXI Interface
  axi_vif axi_if(.clk(clk));

  // Initial block for UVM test execution
  initial begin
    // Set virtual interface for master and slave configurations
    uvm_config_db#(virtual axi_vif)::set(null, "*.magnt*", "vif", axi_if);
    uvm_config_db#(virtual axi_vif)::set(null, "*.sagnt*", "vif", axi_if);

    // Run the UVM test
    run_test();
  end

endmodule