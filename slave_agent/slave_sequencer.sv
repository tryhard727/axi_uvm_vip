



class slave_sequencer extends uvm_sequencer #(trans);

  `uvm_component_utils(slave_sequencer)

  function new(string name = "slave_sequencer", uvm_component parent);

    super.new(name, parent);

  endfunction

endclass