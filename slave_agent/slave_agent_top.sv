



class slave_agent_top extends uvm_env;

  `uvm_component_utils(slave_agent_top)

  function new(string name = "slave_agent_top", uvm_component parent);

    super.new(name, parent);

  endfunction

  env_config   cfg;
  slave_config scfg[];

  slave_agent  agnt[];

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db#(env_config)::get(this, "", "env_config", cfg))
      `uvm_fatal(get_type_name(), "FATAL IN MASTER AGENT TOP")

    agnt = new[cfg.no_of_slave_agents];
    scfg = new[cfg.no_of_slave_agents];

    foreach (agnt[i]) begin

      agnt[i] = slave_agent::type_id::create($sformatf("agnt[%0d]", i), this);

      uvm_config_db#(slave_config)::set(this, $sformatf("agnt[%0d]*", i), "slave_config",
                                        cfg.scfg[i]);

    end
  endfunction

endclass