



class master_agent extends uvm_agent;

  `uvm_component_utils(master_agent)

  function new(string name = "master_agent", uvm_component parent);

    super.new(name, parent);

  endfunction

  master_config cfg;

  master_driver drv;
  master_monitor mon;
  master_sequencer seqr;

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db#(master_config)::get(this, "", "master_config", cfg))
      `uvm_fatal(get_type_name(), "FATAL IN MASTER AGENT")

    mon = master_monitor::type_id::create("mon", this);

    if (cfg.is_active == UVM_ACTIVE) begin

      drv  = master_driver::type_id::create("drv", this);
      seqr = master_sequencer::type_id::create("seqr", this);

    end
  endfunction

  function void connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    if (cfg.is_active == UVM_ACTIVE) begin

      drv.seq_item_port.connect(seqr.seq_item_export);

    end

  endfunction

endclass