



class trans extends uvm_sequence_item;

  `uvm_object_utils(trans)

  function new(string name = "trans");

    super.new(name);

  endfunction

  rand bit [7:0] AWID;
  rand bit [31:0] AWADDR;
  rand bit [7:0] AWLEN;
  rand bit [2:0] AWSIZE;
  rand bit [1:0] AWBURST;
  bit AWVALID;
  bit AWREADY;


  //Write Data Channels Signals
  rand bit [7:0] WID;
  rand bit [31:0] WDATA[];
  rand bit [3:0] WSTRB[];
  bit WLAST;
  bit WVALID;
  bit WREADY;

  //Write Response Channel Signals
  rand bit [7:0] BID;
  bit [1:0] BRESP;
  bit BVALID;
  bit BREADY;

  // Read Address Channel Signals
  rand bit [7:0] ARID;
  rand bit [31:0] ARADDR;
  rand bit [7:0] ARLEN;
  rand bit [2:0] ARSIZE;
  rand bit [1:0] ARBURST;
  bit ARVALID;
  bit ARREADY;




  //Read Data Channel Signals
  rand bit [7:0] RID;
  bit [31:0] RDATA[];
  bit [1:0] RRESP;
  bit RLAST;
  bit RVALID;
  bit RREADY;



  //write addr id = write data id = resp id
  constraint c1 {
    AWID == WID;
    BID == WID;
  }
  //read addr id = read data id
  constraint c2 {ARID == RID;}
  //burst 00-fixed 01-increment 10-wrap 11-reserved
  constraint c3 {AWBURST inside {[0 : 2]};}
  constraint c4 {ARBURST inside {[0 : 2]};}
  //len refers to how many transfer per burst
  //for an AXI3 protocol max transfer per burst is 16
  constraint c5 {AWLEN inside {[0 : 15]};}
  constraint c6 {ARLEN inside {[0 : 15]};}
  //size refers to no of bits per transfer
  //wdata has [31:0] 32 bit => 4 byte
  //awsize represet in byte max 2^2 = 4
  // so 4byte=32 bit
  constraint c7 {AWSIZE inside {[0 : 2]};}
  constraint c8 {ARSIZE inside {[0 : 2]};}
  //adress allignment for fixed and wrap burst
  //for size = 0 2^0=1 so it no need allignment
  constraint c9 {if (AWBURST == 2'b00 || AWBURST == 2'b10) AWADDR % (2 ** AWSIZE) == 0;}

  constraint c10 {if (ARBURST == 2'b00 || ARBURST == 2'b10) ARADDR % (2 ** ARSIZE) == 0;}
  //FOR AN WRAP LENGTH SHOULD BE
  constraint c11 {
    if (AWBURST == 2'b10)
    AWLEN + 1 inside {2, 4, 8, 16};
  }
  constraint c12 {
    if (ARBURST == 2'b10)
    ARLEN + 1 inside {2, 4, 8, 16};
  }
  //wdata size = awlen+1
  //no of transfer in a single burst  that many dynamic size need
  constraint c13 {WDATA.size == AWLEN + 1;}
  constraint c14 {WSTRB.size == AWLEN + 1;}
  //      constraint c15{RDATA.size == ARLEN+1;}
  //before calculate wdata size we have to calculate awlen
  constraint c16 {solve AWLEN before WDATA.size;}
  //      constraint c17{solve ARLEN before RDATA.size;}

  ///for post randomize wstrb

  int starting_address;
  int alligned_address;
  int no_of_bytes;
  int burst_length;
  bit [31:0] addr[];

  ///for post randomize rstrb

  int rstarting_address;
  int ralligned_address;
  int rno_of_bytes;
  int rburst_length;
  bit [31:0] raddr[];


  function void waddr_calc();

    //wrap
    bit wb = 0;
    int wrap_boundary;
    int addr_n;
    //data allignment
    starting_address = AWADDR;
    no_of_bytes = 2 ** AWSIZE;
    burst_length = AWLEN + 1;
    alligned_address = ((int'(AWADDR / no_of_bytes)) * no_of_bytes);
    wrap_boundary = (int'(AWADDR / (no_of_bytes * burst_length))) * (no_of_bytes * burst_length);
    addr_n = wrap_boundary + (no_of_bytes * burst_length);

    $display("wrap  %0d", wrap_boundary);
    $display("addr_n        %0d", addr_n);


    addr = new[AWLEN + 1];
    addr[0] = AWADDR;
    $display("add[0] %0d", addr[0]);

    for (int i = 1; i < burst_length; i++) begin

      if (AWBURST == 2'b00) addr[i] = AWADDR;
      else if (AWBURST == 2'b01) addr[i] = alligned_address + (i * no_of_bytes);
      else begin
        if (wb == 0) begin

          addr[i] = alligned_address + (i * no_of_bytes);
          if (addr[i] == (wrap_boundary + (no_of_bytes * burst_length))) begin
            addr[i] = wrap_boundary;
            wb++;
          end
        end else begin
          addr[i] = starting_address + ((i * no_of_bytes) - (no_of_bytes * burst_length));
        end
      end
      $display($sformatf("addr[%0d]:", i));
      $display("%0d", addr[i]);
    end
  endfunction

  function void wstrb_calc();


    int data_bus_bytes = 4;
    int lower_byte_lane, upper_byte_lane;
    int lower_byte_lane_0 = starting_address-((int'(starting_address/data_bus_bytes))*data_bus_bytes);
    int upper_byte_lane_0 = (alligned_address+(no_of_bytes-1))-((int'(starting_address/data_bus_bytes))*data_bus_bytes);



    for (int j = lower_byte_lane_0; j <= upper_byte_lane_0; j++) begin
      WSTRB[0][j] = 1;
    end
    for (int i = 1; i < AWLEN + 1; i++) begin
      lower_byte_lane = addr[i] - (int'(addr[i] / data_bus_bytes)) * data_bus_bytes;
      upper_byte_lane = lower_byte_lane + no_of_bytes - 1;
      for (int j = lower_byte_lane; j <= upper_byte_lane; j++) begin
        WSTRB[i][j] = 1;
      end
    end

  endfunction

  function void raddr_calc();

    //wrap
    bit rwb;
    int rwrap_boundary = (int'(ARADDR/(rno_of_bytes*rburst_length)))*(rno_of_bytes*rburst_length);
    int raddr_n = rwrap_boundary + (rno_of_bytes * rburst_length);

    //data allignment
    rstarting_address = ARADDR;
    rno_of_bytes = 2 ** ARSIZE;
    rburst_length = ARLEN + 1;
    ralligned_address = ((int'(ARADDR / rno_of_bytes)) * rno_of_bytes);



    raddr = new[ARLEN + 1];
    raddr[0] = ARADDR;

    for (int i = 1; i < rburst_length; i++) begin

      if (ARBURST == 2'b00) raddr[i] = ARADDR;
      else if (ARBURST == 2'b01) raddr[i] = ralligned_address + (i * rno_of_bytes);
      else begin
        if (rwb == 0) begin

          raddr[i] = ralligned_address + (i * rno_of_bytes);
          if (raddr[i] == (rwrap_boundary + (rno_of_bytes * rburst_length))) begin
            raddr[i] = rwrap_boundary;
            rwb++;
          end
        end else begin
          raddr[i] = rstarting_address + ((i * rno_of_bytes) - (no_of_bytes * rburst_length));
        end
      end
    end
  endfunction




  function void post_randomize();

    waddr_calc();
    wstrb_calc();
    raddr_calc();

  endfunction

  function void do_print(uvm_printer printer);

    super.do_print(printer);

    printer.print_field("AWID", this.AWID, $bits(AWID), UVM_DEC);
    printer.print_field("AWLEN", this.AWLEN, $bits(AWLEN), UVM_DEC);
    printer.print_field("AWSIZE", this.AWSIZE, $bits(AWSIZE), UVM_DEC);
    printer.print_field("AWBURST", this.AWBURST, $bits(AWBURST), UVM_DEC);
    printer.print_field("AWADDR", this.AWADDR, $bits(AWADDR), UVM_DEC);
    printer.print_field("AWVALID", this.AWVALID, $bits(AWVALID), UVM_DEC);
    printer.print_field("AWREADY", this.AWREADY, $bits(AWREADY), UVM_DEC);
    //Write Data Channels Signals

    printer.print_field("WID", this.WID, $bits(WID), UVM_DEC);
    foreach (WDATA[i]) begin
      printer.print_field($sformatf("WDATA[%0d]", i), this.WDATA[i], $bits(WDATA[i]), UVM_DEC);
    end
    foreach (WSTRB[i]) begin
      printer.print_field($sformatf("WSTRB[%0d]", i), this.WSTRB[i], $bits(WSTRB[i]), UVM_DEC);
    end

    printer.print_field("WLAST", this.WLAST, $bits(WLAST), UVM_DEC);
    printer.print_field("WVALID", this.WVALID, $bits(WVALID), UVM_DEC);
    printer.print_field("WREADY", this.WREADY, $bits(WREADY), UVM_DEC);

    //Write Response Channel Signals

    printer.print_field("BID", this.BID, $bits(BID), UVM_DEC);
    printer.print_field("BRESP", this.BRESP, $bits(BRESP), UVM_DEC);
    printer.print_field("BVALID", this.BVALID, $bits(BVALID), UVM_DEC);
    printer.print_field("BREADY", this.BREADY, $bits(BREADY), UVM_DEC);

    // Read Address Channel Signals

    printer.print_field("ARID", this.ARID, $bits(ARID), UVM_DEC);
    printer.print_field("ARADDR", this.ARADDR, $bits(ARADDR), UVM_DEC);
    printer.print_field("ARLEN", this.ARLEN, $bits(ARLEN), UVM_DEC);
    printer.print_field("ARSIZE", this.ARSIZE, $bits(ARSIZE), UVM_DEC);
    printer.print_field("ARBURST", this.ARBURST, $bits(ARBURST), UVM_DEC);
    printer.print_field("ARVALID", this.ARVALID, $bits(ARVALID), UVM_DEC);
    printer.print_field("ARREADY", this.AWREADY, $bits(AWREADY), UVM_DEC);

    //Read Data Channel Signals

    printer.print_field("RID", this.RID, $bits(RID), UVM_DEC);
    foreach (RDATA[i]) begin
      printer.print_field($sformatf("RDATA[%0d]", i), this.RDATA[i], $bits(RDATA[i]), UVM_DEC);
    end

    printer.print_field("RRESP", this.RRESP, $bits(RRESP), UVM_DEC);
    printer.print_field("RLAST", this.RLAST, $bits(RLAST), UVM_DEC);
    printer.print_field("RVALID", this.RVALID, $bits(RVALID), UVM_DEC);
    printer.print_field("RREADY", this.RREADY, $bits(RREADY), UVM_DEC);

  endfunction


endclass