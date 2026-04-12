



class scoreboard extends uvm_scoreboard;

  `uvm_component_utils(scoreboard)
  //for write channel
  uvm_tlm_analysis_fifo #(trans) mfifo1[];
  uvm_tlm_analysis_fifo #(trans) sfifo1[];
  //for read channel
  uvm_tlm_analysis_fifo #(trans) mfifo2[];
  uvm_tlm_analysis_fifo #(trans) sfifo2[];

  trans wm, ws, rm, rs;
  env_config cfg;

  covergroup cg;
    c1: coverpoint wm.AWADDR {
      bins b1 = {[32'h0000_0000 : 32'h00FF_FFFF]};
      bins b2 = {[32'h0100_0000 : 32'h01FF_FFFF]};
      bins b3 = {[32'h0200_0000 : 32'h02FF_FFFF]};
      bins b4 = {[32'h0300_0000 : 32'h03FF_FFFF]};
    }
    c2: coverpoint wm.ARADDR {
      bins b1 = {[32'h0000_0000 : 32'h00FF_FFFF]};
      bins b2 = {[32'h0100_0000 : 32'h01FF_FFFF]};
      bins b3 = {[32'h0200_0000 : 32'h02FF_FFFF]};
      bins b4 = {[32'h0300_0000 : 32'h03FF_FFFF]};
    }
    c3: coverpoint wm.AWLEN {bins b1 = {[0 : 15]};}
    c4: coverpoint wm.ARLEN {bins b1 = {[0 : 15]};}
    c5: coverpoint wm.AWSIZE {bins b1 = {[0 : 2]};}
    c6: coverpoint wm.ARSIZE {bins b1 = {[0 : 2]};}
    c7: coverpoint wm.AWBURST {bins b1 = {[0 : 2]};}
  endgroup

  covergroup cg1 with function sample (int i);

    c8: coverpoint wm.WDATA[i] {bins b1 = {[0 : 255]};}

  endgroup


  //      foreach(wm.WDATA[i])
  //      c8:coverpoint {foreach(wm.WDATA[i])
  //              {wm.WDATA[i] ={[0:255]};}}
  //
  function new(string name = "scoreboard", uvm_component parent);

    super.new(name, parent);
    // cg  = new();
    // cg1 = new();
  endfunction

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db#(env_config)::get(this, "", "env_config", cfg))
      `uvm_fatal(get_type_name, "ERROR IN SB")

    mfifo1 = new[cfg.no_of_master_agents];
    sfifo1 = new[cfg.no_of_slave_agents];
    mfifo2 = new[cfg.no_of_master_agents];
    sfifo2 = new[cfg.no_of_slave_agents];



    foreach (mfifo1[i]) mfifo1[i] = new($sformatf("mfifo1[%0d]", i), this);
    foreach (sfifo1[i]) sfifo1[i] = new($sformatf("sfifo1[%0d]", i), this);

    foreach (mfifo2[i]) mfifo2[i] = new($sformatf("mfifo2[%0d]", i), this);
    foreach (sfifo2[i]) sfifo2[i] = new($sformatf("sfifo2[%0d]", i), this);


  endfunction


  task run_phase(uvm_phase phase);

    super.run_phase(phase);
    fork
      forever begin
        foreach (mfifo1[i]) begin
          fork
            sfifo1[0].get(ws);
            // sfifo1[1].get(ws);
            // sfifo1[2].get(ws);
            // sfifo1[3].get(ws);


          join_any
          disable fork;
          mfifo1[i].get(wm);
          cg1.sample(i);

          compare_data(wm, ws);
          ws = null;
        end
      end

      forever begin
        foreach (mfifo2[i]) begin
          fork
            sfifo2[0].get(rs);
            // sfifo2[1].get(rs);
            // sfifo2[2].get(rs);
            // sfifo2[3].get(rs);


          join_any
          disable fork;
          mfifo2[i].get(rm);

          compare_data2(rm, rs);
          rs = null;
        end

      end
    join

  endtask


  task compare_data(trans wm, trans ws);
    cg.sample();

    if(wm.AWADDR == ws.AWADDR && wm.AWLEN == ws.AWLEN && wm.AWSIZE == ws.AWSIZE && wm.AWBURST == ws.AWBURST
                         && wm.WDATA == ws.WDATA && wm.WSTRB == ws.WSTRB && wm.WLAST == ws.WLAST && wm.BRESP == ws.BRESP)
                begin
      $display("///////////////////////////////////////");
      $display("****************SUCCESS****************");
      $display("**************WRITE CHANNEL************");
      $display("///////////////////////////////////////");
    end else begin
      $display("///////////////////////////////////////");
      $display("****************FAILURE****************");
      $display("**************WRITE CHANNEL************");
      $display("///////////////////////////////////////");
    end

  endtask

  task compare_data2(trans rm, trans rs);
    cg.sample();

    if(rm.ARADDR == rs.ARADDR && rm.ARLEN == rs.ARLEN && rm.ARSIZE == rs.ARSIZE && rm.ARBURST == rs.ARBURST
                 && rm.RDATA == rs.RDATA && rm.RLAST == rs.RLAST && rm.RRESP == rs.RRESP )
                begin
      $display("///////////////////////////////////////");
      $display("****************SUCCESS****************");
      $display("**************READ CHANNEL************");
      $display("///////////////////////////////////////");
    end else begin
      $display("///////////////////////////////////////");
      $display("****************FAILURE****************");
      $display("**************READ CHANNEL************");
      $display("///////////////////////////////////////");
    end

  endtask

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);

    $display("**********************************************************************");
    $display("**********************************************************************");
    $display();
    $display("CONGRATS YOU GOT %0d FUNCTIONAL COVERAGE .....!!!!", cg.get_coverage());
    $display();
    $display("**********************************************************************");
    $display("**********************************************************************");

  endfunction

endclass