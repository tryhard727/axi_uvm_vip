



class environment extends uvm_env;

  `uvm_component_utils(environment)

  function new(string name = "environment", uvm_component parent);

    super.new(name, parent);

  endfunction

  master_agent_top magnt;
  slave_agent_top sagnt;

  scoreboard sb;

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    sb = scoreboard::type_id::create("sb", this);

    magnt = master_agent_top::type_id::create("magnt", this);
    sagnt = slave_agent_top::type_id::create("sagnt", this);

  endfunction

  function void connect_phase(uvm_phase phase);

    super.connect_phase(phase);
    foreach (magnt.agnt[i]) begin
      magnt.agnt[i].mon.map1.connect(sb.mfifo1[i].analysis_export);
      magnt.agnt[i].mon.map2.connect(sb.mfifo2[i].analysis_export);
    end
    foreach (sagnt.agnt[i]) begin
      sagnt.agnt[i].mon.sap1.connect(sb.sfifo1[i].analysis_export);
      sagnt.agnt[i].mon.sap2.connect(sb.sfifo2[i].analysis_export);

    end

  endfunction

endclass