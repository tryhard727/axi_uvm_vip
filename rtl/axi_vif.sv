



interface axi_vif (
    input bit clk
);

  //Write Address Signals
  logic [7:0] AWID;
  logic [31:0] AWADDR;
  logic [7:0] AWLEN;
  logic [2:0] AWSIZE;
  logic [1:0] AWBURST;
  bit AWVALID;
  bit AWREADY;


  //Write Data Channels Signals
  logic [7:0] WID;
  logic [31:0] WDATA;
  logic [3:0] WSTRB;
  bit WLAST;
  bit WVALID;
  bit WREADY;

  //Write Response Channel Signals
  logic [7:0] BID;
  logic [1:0] BRESP;
  bit BVALID;
  bit BREADY;

  // Read Address Channel Signals
  logic [7:0] ARID;
  logic [31:0] ARADDR;
  logic [7:0] ARLEN;
  logic [2:0] ARSIZE;
  logic [1:0] ARBURST;
  bit ARVALID;
  bit ARREADY;


  //Read Data Channel Signals
  logic [7:0] RID;
  logic [31:0] RDATA;
  logic [1:0] RRESP;
  logic RLAST;
  bit RVALID;
  bit RREADY;

  // Master Driver Clocking Block
  clocking mst_drv_cb @(posedge clk);
    default input #1 output #1;

    // Write Address Signals
    output AWID;
    output AWADDR;
    output AWLEN;
    output AWSIZE;
    output AWBURST;

    output AWVALID;

    input AWREADY;


    // Write Data Signals
    output WID;
    output WDATA;
    output WSTRB;
    output WLAST;

    output WVALID;

    input WREADY;

    //Write Response Signals
    input BID;
    input BRESP;

    input BVALID;
    output BREADY;




    // Read Address Signals
    output ARID;
    output ARADDR;
    output ARLEN;
    output ARSIZE;
    output ARBURST;

    output ARVALID;
    input ARREADY;




    // Read Data Signals
    input RID;
    input RDATA;
    input RRESP;
    input RLAST;

    input RVALID;
    output RREADY;

  endclocking



  clocking mst_mon_cb @(posedge clk);
    default input #1 output #1;

    // Write Address Signals
    input AWID;
    input AWADDR;
    input AWLEN;
    input AWSIZE;
    input AWBURST;

    input AWVALID;
    input AWREADY;


    // Write Data Signals
    input WID;
    input WDATA;
    input WSTRB;
    input WLAST;

    input WVALID;
    input WREADY;

    //Write Response Signals
    input BID;
    input BRESP;

    input BVALID;
    input BREADY;

    // Read Address Signals
    input ARID;
    input ARADDR;
    input ARLEN;
    input ARSIZE;
    input ARBURST;

    input ARVALID;
    input ARREADY;




    // Read Data Signals
    input RID;
    input RDATA;
    input RRESP;
    input RLAST;

    input RVALID;
    input RREADY;

  endclocking




  modport AXI_MDRV(clocking mst_drv_cb);
  modport MST_MON(clocking mst_mon_cb);

  clocking slv_drv_cb @(posedge clk);
    default input #1 output #1;

    // Write Address Signals
    input AWID;
    input AWADDR;
    input AWLEN;
    input AWSIZE;
    input AWBURST;

    input AWVALID;
    output AWREADY;



    // Write Data Signals
    input WID;
    input WDATA;
    input WSTRB;
    input WLAST;

    input WVALID;
    output WREADY;

    //Write Response Signals
    output BID;
    output BRESP;

    output BVALID;
    input BREADY;

    // Read Address Signals
    input ARID;
    input ARADDR;
    input ARLEN;
    input ARSIZE;
    input ARBURST;

    input ARVALID;
    output ARREADY;


    // Read Data Signals
    output RID;
    output RDATA;
    output RRESP;
    output RLAST;

    output RVALID;
    input RREADY;

  endclocking





  clocking slv_mon_cb @(posedge clk);
    default input #1 output #1;

    // Write Address Signals
    input AWID;
    input AWADDR;
    input AWLEN;
    input AWSIZE;
    input AWBURST;

    input AWVALID;
    input AWREADY;



    // Write Data Signals
    input WID;
    input WDATA;
    input WSTRB;
    input WLAST;

    input WVALID;
    input WREADY;

    //Write Response Signals
    input BID;
    input BRESP;

    input BVALID;
    input BREADY;


    // Read Address Signals
    input ARID;
    input ARADDR;
    input ARLEN;
    input ARSIZE;
    input ARBURST;

    input ARVALID;
    input ARREADY;


    // Read Data Signals
    input RID;
    input RDATA;
    input RRESP;
    input RLAST;

    input RVALID;
    input RREADY;

  endclocking





  modport SLV_DRV(clocking slv_drv_cb);
  modport SLV_MON(clocking slv_mon_cb);

endinterface