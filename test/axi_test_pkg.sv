package axi_test_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Include all necessary files in the correct order
  `include "../../rtl/axi_vif.sv"
  `include "../master_agent/axi_transaction.sv"
  `include "axi_configs.sv"

  `include "../master_agent/master_driver.sv"
  `include "../master_agent/master_monitor.sv"
  `include "../master_agent/master_sequencer.sv"
  `include "../master_agent/master_sequences.sv"
  `include "../master_agent/master_agent.sv"
  `include "../master_agent/master_agent_top.sv"

  `include "../slave_agent/slave_driver.sv"
  `include "../slave_agent/slave_monitor.sv"
  `include "../slave_agent/slave_sequencer.sv"
  `include "../slave_agent/slave_agent.sv"
  `include "../slave_agent/slave_agent_top.sv"

  `include "../tb/scoreboard.sv"
  `include "../tb/environment.sv"


  class test extends uvm_test;

    `uvm_component_utils(test)

    function new(string name = "test", uvm_component parent);

      super.new(name, parent);

    endfunction

    environment env;

    env_config cfg;
    master_config mcfg[];
    slave_config scfg[];

    int no_of_master_agents = 1;
    int no_of_slave_agents = 1;


    function void build_phase(uvm_phase phase);

      super.build_phase(phase);

      env = environment::type_id::create("env", this);

      cfg = env_config::type_id::create("cfg");

      cfg.no_of_master_agents = no_of_master_agents;
      cfg.no_of_slave_agents = no_of_slave_agents;

      mcfg = new[no_of_master_agents];
      scfg = new[no_of_slave_agents];

      foreach (mcfg[i]) begin
        mcfg[i] = master_config::type_id::create($sformatf("mcfg[%0d]", i));
        mcfg[i].is_active = UVM_ACTIVE;
        uvm_config_db#(master_config)::set(this, $sformatf("env.magnt.agnt[%0d]*", i), "master_config", mcfg[i]);
      end

      foreach (scfg[i]) begin
        scfg[i] = slave_config::type_id::create($sformatf("scfg[%0d]", i));
        scfg[i].is_active = UVM_ACTIVE;
        uvm_config_db#(slave_config)::set(this, $sformatf("env.sagnt.agnt[%0d]*", i), "slave_config", scfg[i]);
      end

      uvm_config_db#(env_config)::set(this, "env", "env_config", cfg);

    endfunction

    task run_phase(uvm_phase phase);
      master_seq m_seq;
      phase.raise_objection(this);
      m_seq = master_seq::type_id::create("m_seq");
      m_seq.start(env.magnt.agnt[0].seqr);
      #100;
      phase.drop_objection(this);
    endtask

  endclass

endpackage
