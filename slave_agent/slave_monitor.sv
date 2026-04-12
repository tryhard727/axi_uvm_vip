



class slave_monitor extends uvm_monitor;

  `uvm_component_utils(slave_monitor)

  uvm_analysis_port #(trans) sap1;
  uvm_analysis_port #(trans) sap2;

  function new(string name = "slave_monitor", uvm_component parent);

    super.new(name, parent);

    sap1 = new("sap1", this);
    sap2 = new("sap2", this);


  endfunction

  virtual axi_vif.SLV_MON vif;

  slave_config cfg;

  trans x, y;

  semaphore sem1 = new(1);
  semaphore sem2 = new(1);
  semaphore sem3 = new(1);
  semaphore sem4 = new(1);
  semaphore sem5 = new(1);

  semaphore sem6 = new();
  semaphore sem7 = new();
  semaphore sem8 = new();

  trans q1[$], q2[$], q3[$];


  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db#(slave_config)::get(this, "", "slave_config", cfg))
      `uvm_fatal(get_type_name(), "FATAL IN MASTER MONITOR")

    x = trans::type_id::create("x");
    y = trans::type_id::create("y");



  endfunction

  function void connect_phase(uvm_phase phase);

    super.connect_phase(phase);

    this.vif = cfg.vif;

  endfunction

  task run_phase(uvm_phase phase);

    forever begin

      collect_from_dut();

    end
  endtask

  task collect_from_dut();

    fork
      begin
        sem1.get(1);
        write_addr_channel();
        sem6.put(1);
        sem1.put(1);
      end
      begin
        sem2.get(1);
        sem6.get(1);
        write_data_channel(q1.pop_front());
        sem7.put(1);
        sem2.put(1);
      end
      begin
        sem3.get(1);
        sem7.get(1);
        write_response_channel(q2.pop_front());
        //      `uvm_info(get_type_name(),"DATA FROM SLAVE MONITOR X",UVM_LOW)
        //      x.print();
        sap1.write(x);
        sem3.put(1);
      end
      begin
        sem4.get(1);
        read_address_channel();
        sem8.put(1);
        sem4.put(1);
      end
      begin
        sem5.get(1);
        sem8.get(1);
        read_data_channel(q3.pop_front());
        //      `uvm_info(get_type_name(),"DATA FROM SLAVE MONITOR Y",UVM_LOW)
        //      y.print();
        sap2.write(y);
        sem5.put(1);
      end

    join_any

  endtask

  task write_addr_channel();


    @(vif.slv_mon_cb);

    wait (vif.slv_mon_cb.AWVALID && vif.slv_mon_cb.AWREADY) x.AWID = vif.slv_mon_cb.AWID;
    x.AWADDR  = vif.slv_mon_cb.AWADDR;
    x.AWLEN   = vif.slv_mon_cb.AWLEN;
    x.AWSIZE  = vif.slv_mon_cb.AWSIZE;
    x.AWBURST = vif.slv_mon_cb.AWBURST;
    x.AWVALID = vif.slv_mon_cb.AWVALID;
    x.AWREADY = vif.slv_mon_cb.AWREADY;
    q1.push_back(x);

    //      @(vif.slv_mon_cb);

  endtask

  task write_data_channel(trans x);

    trans x1;
    x1 = new("x1");
    x1 = x;
    x1.WDATA = new[x.AWLEN + 1];
    x1.WSTRB = new[x.AWLEN + 1];
    for (int i = 0; i < x.AWLEN + 1; i++) begin

      wait (vif.slv_mon_cb.WVALID && vif.slv_mon_cb.WREADY) x1.WID = vif.slv_mon_cb.WID;

      x1.WDATA[i] = vif.slv_mon_cb.WDATA;

      x1.WSTRB[i] = vif.slv_mon_cb.WSTRB;
      x1.WLAST = vif.slv_mon_cb.WLAST;
      x1.WVALID = vif.slv_mon_cb.WVALID;
      x1.WREADY = vif.slv_mon_cb.WREADY;
      @(vif.slv_mon_cb);

    end


    q2.push_back(x1);
  endtask

  task write_response_channel(trans x);

    trans x2;
    x2 = new("x2");
    x2 = x;

    wait (vif.slv_mon_cb.BVALID && vif.slv_mon_cb.BREADY) x.BID = vif.slv_mon_cb.BID;
    x.BRESP  = vif.slv_mon_cb.BRESP;
    x.BVALID = vif.slv_mon_cb.BVALID;
    x.BREADY = vif.slv_mon_cb.BREADY;
    @(vif.slv_mon_cb);

  endtask

  task read_address_channel();

    @(vif.slv_mon_cb);

    wait (vif.slv_mon_cb.ARVALID && vif.slv_mon_cb.ARREADY) y.ARID = vif.slv_mon_cb.ARID;
    y.ARADDR  = vif.slv_mon_cb.ARADDR;
    y.ARLEN   = vif.slv_mon_cb.ARLEN;
    y.ARSIZE  = vif.slv_mon_cb.ARSIZE;
    y.ARBURST = vif.slv_mon_cb.ARBURST;
    y.ARVALID = vif.slv_mon_cb.ARVALID;
    y.ARREADY = vif.slv_mon_cb.ARREADY;

    q3.push_back(y);

  endtask



  task read_data_channel(trans y);

    trans y1;
    y1 = new("y1");
    y1 = y;

    y1.RDATA = new[y1.ARLEN + 1];

    foreach (y1.RDATA[i]) begin

      wait (vif.slv_mon_cb.RVALID && vif.slv_mon_cb.RREADY) y1.RID = vif.slv_mon_cb.RID;
      y1.RDATA[i] = vif.slv_mon_cb.RDATA;
      y1.RRESP = vif.slv_mon_cb.RRESP;
      y1.RLAST = vif.slv_mon_cb.RLAST;
      y1.RVALID = vif.slv_mon_cb.RVALID;
      y1.RREADY = vif.slv_mon_cb.RREADY;

      @(vif.slv_mon_cb);
    end


  endtask


endclass