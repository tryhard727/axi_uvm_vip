



class slave_config extends uvm_object;

  `uvm_object_utils(slave_config)

  function new(string name = "slave_config");

    super.new(name);

  endfunction

  virtual axi_vif vif;
  uvm_active_passive_enum is_active;

endclass

class master_config extends uvm_object;

  `uvm_object_utils(master_config)

  function new(string name = "master_config");

    super.new(name);

  endfunction

  virtual axi_vif vif;

  uvm_active_passive_enum is_active;

endclass

class env_config extends uvm_object;

  `uvm_object_utils(env_config)

  function new(string name = "env_config");

    super.new(name);

  endfunction

  master_config mcfg[];
  slave_config scfg[];

  int no_of_master_agents;
  int no_of_slave_agents;


endclass