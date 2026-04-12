



class slave_agent extends uvm_agent;

  `uvm_component_utils(slave_agent)

  function new(string name = "slave_agent", uvm_component parent);

    super.new(name, parent);

  endfunction

  slave_config cfg;

  slave_driver drv;
  slave_monitor mon;
  slave_sequencer seqr;

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db#(slave_config)::get(this, "", "slave_config", cfg))
      `uvm_fatal(get_type_name(), "FATAL IN SLAVE AGENT")

    mon = slave_monitor::type_id::create("mon", this);

    if (cfg.is_active == UVM_ACTIVE) begin

      drv  = slave_driver::type_id::create("drv", this);
      seqr = slave_sequencer::type_id::create("seqr", this);

    end
  endfunction

  function void connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    if (cfg.is_active == UVM_ACTIVE) begin

      drv.seq_item_port.connect(seqr.seq_item_export);

    end

  endfunction

endclass