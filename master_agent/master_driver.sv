class master_driver extends uvm_driver#(axi_xtn);
	`uvm_component_utils(master_driver)	//factory registration

	virtual axi_if.MST_DRV vif;		//local virtual interface handle for driver
	master_config 	cfg;
	
	//declaring queues  for storing data	
	axi_xtn q1[$], q2[$], q3[$], q4[$], q5[$];
	
	//declaring semaphores for making sure transaction happens in our required way
	semaphore wa = new(1);    //2 address channels have key as they need to start immediately
	semaphore ra =new(1);
	semaphore wd = new();	//3 remaining channels initially have no key. On completion of address channels, data channels get key from the end of address logics.
	semaphore rd = new(1);
	semaphore wr = new();	// the response channel get key after completion of write data channel logic.
	semaphore avr = new(1);	// these three keys were used to block the channels( data channels and response) for next transfer while one transfer is in process.
	//semaphore rdc = new(1); // to avoid overriding the data of different beats
	//semaphore wrc = new(1);


	//constructor new
	function new(string name ="m_axi_drv",uvm_component parent);
		super.new(name,parent);
	endfunction

	//--------------------BUILD PAHSE-----------------------------------
	function void build_phase(uvm_phase phase);
		if(!uvm_config_db#(master_config)::get(this,"","master_config",cfg))
			`uvm_fatal("config","error")
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

				seq_item_port.get_next_item(req);
				wa.get(2);
				ra.get(2);
				seq_item_port.item_done();

			end
	endtask

	//------------------driving logic----------------------------------
	task send_to_dut(axi_xtn xtn);
		q1.push_front(xtn);
		q2.push_front(xtn);
		q3.push_front(xtn);
		q4.push_front(xtn);
		q5.push_front(xtn);
	
		fork
			//---------------write address---------------------
			begin
				wa.get(1);	//as it already have a key in the object it gets the key, on getting the key it doesnt have any more keys left
				driver_waddr(q1.pop_back());
				wa.put(3);	// as it dont have any key it blocks for next time, inorder to proceed further we are assigning key for write addr.		
			        
				wd.put(1);	//assigning the key to to write data channel as write addr logic finished
			end	
			
			//---------------write data------------------------
			begin
				wd.get(1);	// we got the key , which is assigned after the address logic
				//wdc.get(1);	// we gave the key while creating the object. this make sure it avoids overriding- when other address is given until the previous data transfer is finished the next address - respective data needs to transfer will be blocked.
				driver_wdata(q2.pop_back());
				//wdc.put(1); 	//when next time data channel is called to make sure it runs successfully with blocking, we are assigning the key
				wr.put(1);
				//wd.put(1); 	//after data transfer got finished assiging key to response channel.
			end
			
			//---------------write response=----------------------
			begin
				wr.get(1);	// we got this key as it was set in the w-data channel on finishing the data transfer
				//wrc.get(1);	//to avoid overriding we are using this
				driver_wresp(q3.pop_back());
				//wrc.put(1);   // only on  completion of current response it allows for other response.
				//wr.put(1);
			end	
	
			//--------------read address---------------------------
			begin
				ra.get(1);	//as it already have a key in the object it gets the key, on getting the key it doesnt have any more keys left
				driver_raddr(q4.pop_back());
				rd.put(1);	//assigning the key to to read data channel as read addr logic finished
				ra.put(3);	// as it dont have any key it blocks for next time, inorder to proceed further we are assigning key for read addr.	
			end
	
			begin
				rd.get(2);	// we got the key , which is assigned after the address logic
				//rdc.get(1);	// we gave the key while creating the object. this make sure it avoids overriding- when other address is given until the previous data transfer is finished the next address - respective dat							a needs to transfer will be blocked.
				driver_rdata(q5.pop_back());
				//rdc.put(1); 	//when next time data channel is called to make sure it runs successfully with blocking, we are assigning the key
				rd.put(1);
			end
		join_any
	endtask

	//----------------------Write Address Channel logic----------------------
	task driver_waddr(axi_xtn xtn);	
	//	@(vif.mst_drv_cb);
		$display("Start of Master driver w_addr");
		vif.mst_drv_cb.AWID <= xtn.AWID;
		vif.mst_drv_cb.AWADDR <= xtn.AWADDR;
		vif.mst_drv_cb.AWLEN <= xtn.AWLEN;
		vif.mst_drv_cb.AWSIZE <= xtn.AWSIZE;
		vif.mst_drv_cb.AWBURST <= xtn.AWBURST;
		vif.mst_drv_cb.AWVALID <= 1'b1;
		@(vif.mst_drv_cb);
		wait(vif.mst_drv_cb.AWREADY);
			vif.mst_drv_cb.AWVALID <= 1'b0;

		repeat($urandom_range(1,5))
			@(vif.mst_drv_cb);
		`uvm_info("From Master(drv)write address",$sformatf(xtn.sprint()),UVM_LOW)
		$display("End of Master drive w_addr");
	endtask


	//----------------------Write DATA Channel logic----------------------
	task driver_wdata(axi_xtn xtn);
		//@(vif.mst_drv_cb);
		$display("Start of Master driver wdata");
		foreach(xtn.WDATA[i])
			begin
				#($urandom_range(1,2));
				avr.get(1);
				vif.mst_drv_cb.WID <= xtn.WID;
				vif.mst_drv_cb.WDATA <= xtn.WDATA[i];
				vif.mst_drv_cb.WSTRB <= xtn.WSTRB[i];
			//	vif.mst_drv_cb.WLAST <= 1'b0;
				vif.mst_drv_cb.WVALID <= 1'b1;

				if(i==(xtn.AWLEN))
					vif.mst_drv_cb.WLAST <= 1'b1;
				else
					vif.mst_drv_cb.WLAST <= 1'b0;
					
				@(vif.mst_drv_cb);
				wait(vif.mst_drv_cb.WREADY);
					vif.mst_drv_cb.WVALID <= 1'b0;
					vif.mst_drv_cb.WLAST <= 1'b0;
				repeat($urandom_range(1,5))
					@(vif.mst_drv_cb);
				avr.put(1);
			end
				`uvm_info("From Master(drv)write data",$sformatf(xtn.sprint()),UVM_LOW)
		$display("End of Master driver wdata");
	endtask



	//----------------------Write Response Channel logic----------------------
	task driver_wresp(axi_xtn xtn);
	//	@(vif.mst_drv_cb);
		$display("Start of Master driver wresp");
		vif.mst_drv_cb.BREADY <= 1'b1;
		@(vif.mst_drv_cb);
		wait(vif.mst_drv_cb.BVALID && xtn.BID==xtn.WID);
			xtn.BID = vif.mst_drv_cb.BID;
			xtn.BRESP = vif.mst_drv_cb.BRESP;
		
			vif.mst_drv_cb.BREADY <= 1'b0;
	
		repeat($urandom_range(1,5))
			@(vif.mst_drv_cb);
				`uvm_info("From Master(drv)write response",$sformatf(xtn.sprint()),UVM_LOW)
		$display("End of Master driver wresp");
	endtask



	//----------------------Read Address Channel logic----------------------
	task driver_raddr(axi_xtn xtn);
	//	@(vif.mst_drv_cb);
		$display("Start of Master driver raddr");
		vif.mst_drv_cb.ARID <= xtn.ARID;
		vif.mst_drv_cb.ARADDR <= xtn.ARADDR;
		vif.mst_drv_cb.ARLEN <= xtn.ARLEN;
		vif.mst_drv_cb.ARSIZE <= xtn.ARSIZE;
		vif.mst_drv_cb.ARBURST <= xtn.ARBURST;
		vif.mst_drv_cb.ARVALID <= 1'b1;
		@(vif.mst_drv_cb);
		wait(vif.mst_drv_cb.ARREADY);
			vif.mst_drv_cb.ARVALID <= 1'b0;
		repeat($urandom_range(1,5))
			@(vif.mst_drv_cb);
				`uvm_info("From Master(drv)read address",$sformatf(xtn.sprint()),UVM_LOW)
		$display("End of Master driver raddr");
	endtask



	//----------------------Read DATA Channel logic----------------------
	task driver_rdata(axi_xtn xtn);
	//	@(vif.mst_drv_cb);
	//	xtn.RDATA = new[xtn.ARLEN+1];
		$display("Start of Master driver rdata");
		for(int i=0; i<(xtn.ARLEN+1);i++)
			begin
				vif.mst_drv_cb.RREADY <= 1'b1;

				//if(i==(xtn.ARLEN))
				//	vif.mst_drv_cb.RLAST <= 1'b0;
				@(vif.mst_drv_cb);
				wait(vif.mst_drv_cb.RVALID);
					xtn.RDATA[i] = vif.mst_drv_cb.RDATA;
					xtn.RRESP[i] = vif.mst_drv_cb.RRESP;
					xtn.RID = vif.mst_drv_cb.RID;
				
					vif.mst_drv_cb.RREADY <= 1'b0;
				repeat($urandom_range(1,5))
					@(vif.mst_drv_cb);
			end
		$display("End of Master driver rdata");
				`uvm_info("From Master(drv)read data",$sformatf(xtn.sprint()),UVM_LOW)
	endtask

endclass
	
