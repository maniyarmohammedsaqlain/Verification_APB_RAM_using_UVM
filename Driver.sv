class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver);
  transaction trans;
  virtual apb_if inf;
  function new(string path="drv",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    trans=transaction::type_id::create("trans");
    
    if(!uvm_config_db #(virtual apb_if)::get(this,"","inf",inf))
      `uvm_info("DRV","ERROR IN CONFIG OF DRIVER",UVM_NONE);
  endfunction
  
  task reset();
    repeat(5)
      begin
        inf.presetn<=0;
        inf.paddr<=0;
        inf.pwrite<=0;
        inf.pwdata<=0;
        inf.penable<=0;
        inf.psel<=0;
        `uvm_info("DRV_RST","DUT RESET DONE",UVM_NONE);
        @(posedge inf.pclk);
      end
  endtask
  
  virtual task run_phase(uvm_phase phase);
    reset();
    forever
      begin
        seq_item_port.get_next_item(trans);
        if(trans.op==0)
          begin
            inf.presetn<=0;
            inf.paddr<=0;
            inf.pwrite<=0;
            inf.pwdata<=0;
            inf.penable<=0;
            inf.psel<=0;
            @(posedge inf.pclk);
          end
        else if(trans.op==1)
          begin
            inf.psel<=1;
            inf.paddr<=trans.paddr;
            inf.pwdata<=trans.pwdata;
            inf.presetn<=1;
            inf.pwrite<=1;
            @(posedge inf.pclk);
            inf.penable<=1;
            
            @(negedge inf.pready);
            inf.penable<=0;
            trans.pslverr = inf.pslverr;
            `uvm_info("WRITE",$sformatf("ADDR:%0d DATA:%0d SLVERR:%0d",trans.paddr,trans.pwdata,trans.pslverr),UVM_NONE);
          end
        else if(trans.op==2)
          begin
            inf.psel<=1;
            inf.paddr<=trans.paddr;
            inf.presetn<=1;
            inf.pwrite<=0;
            @(posedge inf.pclk);
            inf.penable<=1;
            
            @(negedge inf.pready);
            inf.penable<=0;
            trans.prdata=inf.prdata;
            trans.pslverr=inf.pslverr;
            `uvm_info("READ",$sformatf("ADDR:%0d DATA:%0d RDATA:%0d SLVERR:%0d",trans.paddr,trans.pwdata,trans.prdata,trans.pslverr),UVM_NONE);
          end
        seq_item_port.item_done();
      end
  endtask
endclass
