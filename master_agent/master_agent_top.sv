



class master_agent_top extends uvm_env;

  `uvm_component_utils(master_agent_top)

  function new(string name = "master_agent_top", uvm_component parent);

    super.new(name, parent);

  endfunction

  env_config cfg;
  master_config mcfg[];

  master_agent agnt[];

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db#(env_config)::get(this, "", "env_config", cfg))
      `uvm_fatal(get_type_name(), "FATAL IN MASTER AGENT TOP")

    agnt = new[cfg.no_of_master_agents];
    mcfg = new[cfg.no_of_master_agents];

    foreach (agnt[i]) begin

      agnt[i] = master_agent::type_id::create($sformatf("agnt[%0d]", i), this);

      uvm_config_db#(master_config)::set(this, $sformatf("agnt[%0d]*", i), "master_config",
                                         cfg.mcfg[i]);
      //      $display("%p",cfg.mcfg[i]);

    end
  endfunction

endclass