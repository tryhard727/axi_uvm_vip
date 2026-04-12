class slave_driver extends uvm_driver#(axi_xtn);
	`uvm_component_utils(slave_driver)	//factory registration

	virtual axi_if.SLV_DRV vif;		//local virtual interface handle for driver
	slave_config  cfg;	
	
	axi_xtn q1[$],q2[$],q3[$];	//queues for putting address channels into them and accessing in three different channels
	
	//declaring semaphores for making sure transaction happens in our required way
	semaphore wa = new(1);    //2 address channels have key as they need to start immediately
	semaphore ra =new(1);
	semaphore wd = new();	//3 remaining channels initially have no key. On completion of address channels, data channels get key from the end of address logics.
	semaphore rd = new(1);
	semaphore wr = new();	// the response channel get key after completion of write data channel logic.
	//semaphore wdc = new(1);	// these three keys were used to block the channels( data channels and response) for next transfer while one transfer is in process.
	//semaphore rdc = new(1); // to avoid overriding the data of different beats
	//semaphore wrc = new(1);

	
	//constructor new
	function new(string name ="s_axi_drv",uvm_component parent);
		super.new(name,parent);
	endfunction

	//--------------------BUILD PAHSE-----------------------------------
	function void build_phase(uvm_phase phase);
		if(!uvm_config_db#(slave_config)::get(this,"","slave_config",cfg))
			`uvm_fatal(get_type_name(),"error")
		super.build_phase(phase);

	endfunction

	//--------------------CONNECT PHASE--------------------------------
	function void connect_phase(uvm_phase phase);
		vif = cfg.vif;
		super.connect_phase(phase);
	endfunction

	//--------------------RUN PHASE-----------------------------------
	task run_phase(uvm_phase phase);
		forever
			begin
			//	seq_item_port.get_next_item(req);
				
				send_to_dut();
                wa.get(2);
				ra.get(2);
			//	seq_item_port.item_done();
				
			end
	endtask

	task send_to_dut();
		fork
		//-----------------write address channel----------
		begin
			wa.get(1);	//as it already have a key in the object it gets the key, on getting the key it doesnt have any more keys left
			slave_waddr();
			wa.put(3);

			wd.put(1);     //assigning the key to to write data channel as write addr logic finished
		end

		//-----------------write data channel------------
		begin
			wd.get(1);
			//wdc.get(1);	
			slave_wdata(q1.pop_front());
			wr.put(1);
			//wd.put(1);
			//wdc.put(1);
		end

		//--------------write response channel------------
		begin
			wr.get(1);
			//wrc.get(1);
			slave_wresp(q2.pop_front());
			//wrc.put(1);
			//wr.put(1);
		end

		//---------------read address channel-------------
		begin
			ra.get(1);
			slave_raddr();
			rd.put(1);
			ra.put(3);
		end
		
		//---------------read data channel------------------
		begin
			rd.get(2);
			//rdc.get(1);
			slave_rdata(q3.pop_front());
			//rdc.put(1);
			rd.put(1);
		end
	    join_any		
	endtask

	//-----------------write address channel logic-------------------
	task slave_waddr();
		axi_xtn  xtn1; 
		xtn1 = axi_xtn::type_id::create("xtn1");
		$display("Start of slave driver waddr");
		vif.slv_drv_cb.AWREADY <= 1'b1;
		@(vif.slv_drv_cb);
		wait(vif.slv_drv_cb.AWVALID);
			xtn1.AWADDR = vif.slv_drv_cb.AWADDR ;
			xtn1.AWLEN = vif.slv_drv_cb.AWLEN;
			xtn1.AWSIZE = vif.slv_drv_cb.AWSIZE ;
			xtn1.AWBURST = vif.slv_drv_cb.AWBURST;
			xtn1.AWVALID = vif.slv_drv_cb.AWVALID;
			xtn1.AWID = vif.slv_drv_cb.AWID;

		@(vif.slv_drv_cb);
		vif.slv_drv_cb.AWREADY <= 1'b0;
		repeat($urandom_range(1,5))
			@(vif.slv_drv_cb);
			`uvm_info("From Slave(drv)write address",$sformatf(xtn1.sprint()),UVM_LOW)
		$display("End of slave driver waddr");
		q1.push_back(xtn1);
		q2.push_back(xtn1);
	
	endtask

	//----------------write data channel logic-------------------
	task slave_wdata(axi_xtn xtn);
		$display("Start of slave driver wdata");	
		xtn.WDATA = new[xtn.AWLEN+1];
		xtn.WSTRB = new[xtn.AWLEN+1];

		for(int i=0;i<xtn.AWLEN+1;i++)
			begin
				vif.slv_drv_cb.WREADY <= 1'b1;
				@(vif.slv_drv_cb);
				wait(vif.slv_drv_cb.WVALID && vif.slv_drv_cb.WID==xtn.AWID);
				xtn.WDATA[i] = vif.slv_drv_cb.WDATA;
				xtn.WSTRB[i] = vif.slv_drv_cb.WSTRB;
				xtn.WID=vif.slv_drv_cb.WID;
				@(vif.slv_drv_cb);
				vif.slv_drv_cb.WREADY <= 1'b0;
				//repeat($urandom_range(1,5))
				@(vif.slv_drv_cb);
				
			end
			`uvm_info("From Slave(drv)write data",$sformatf(xtn.sprint()),UVM_LOW)
		$display("End of slave driver waddr");
	endtask	

	//----------------write response channel logic--------------------
	task slave_wresp(axi_xtn xtn);
		$display("Start of slave driver resp");
	//	for(int i=0;i<xtn.AWLEN+1;i++)
	//		begin
				vif.slv_drv_cb.BID <= xtn.AWID;
				vif.slv_drv_cb.BRESP <= 2'b0;
				vif.slv_drv_cb.BVALID <=1'b1;
				@(vif.slv_drv_cb);
				wait(vif.slv_drv_cb.BREADY);	
				vif.slv_drv_cb.BVALID <= 1'b0;
				vif.slv_drv_cb.BRESP <= 'hzz;
		repeat($urandom_range(1,5))
			@(vif.slv_drv_cb);
			`uvm_info("From Slave(drv)write response",$sformatf(xtn.sprint()),UVM_LOW)
		$display("End of slave driver resp");
	endtask

	//----------------read address channel logic--------------------
	task slave_raddr();
		axi_xtn  xtn1; 
		xtn1 = axi_xtn::type_id::create("xtn1");
	
		$display("Start of slave driver raddr");
		vif.slv_drv_cb.ARREADY <= 1'b1;
		@(vif.slv_drv_cb);
		wait(vif.slv_drv_cb.ARVALID);
			xtn1.ARADDR = vif.slv_drv_cb.ARADDR ;
			xtn1.ARLEN = vif.slv_drv_cb.ARLEN;
			xtn1.ARSIZE = vif.slv_drv_cb.ARSIZE ;
			xtn1.ARID = vif.slv_drv_cb.ARID ;
			xtn1.ARBURST = vif.slv_drv_cb.ARBURST;
			xtn1.ARVALID = vif.slv_drv_cb.ARVALID;

			@(vif.slv_drv_cb);
			vif.slv_drv_cb.ARREADY <= 1'b0;
		repeat($urandom_range(1,5))
			@(vif.slv_drv_cb);
			`uvm_info("From Slave(drv)read address",$sformatf(xtn1.sprint()),UVM_LOW)
		$display("End of slave driver raddr");
		q3.push_back(xtn1);
	endtask

	//--------------read data channel logic---------------------
	task slave_rdata(axi_xtn xtn);
		$display("Start of slave driver rdata");
		xtn.RDATA = new[xtn.ARLEN+1];
		for(int i=0;i<(xtn.ARLEN+1);i++)
			begin
			vif.slv_drv_cb.RID <= xtn.ARID;
			vif.slv_drv_cb.RDATA <= $urandom();
			vif.slv_drv_cb.RVALID <=1'b1;
			vif.slv_drv_cb.RRESP <=1'b0;
			if(i==(xtn.ARLEN))
				vif.slv_drv_cb.RLAST <=1'b1;
			else
				vif.slv_drv_cb.RLAST <=1'b0;
			@(vif.slv_drv_cb);
			wait(vif.slv_drv_cb.RREADY);
				vif.slv_drv_cb.RVALID <=1'b0;
				vif.slv_drv_cb.RRESP <='hzz;
			repeat($urandom_range(1,5))
				@(vif.slv_drv_cb);
			end
			`uvm_info("From Slave(drv)read data",$sformatf(xtn.sprint()),UVM_LOW)
		$display("End of slave driver rdata");
	endtask	

endclass
	
