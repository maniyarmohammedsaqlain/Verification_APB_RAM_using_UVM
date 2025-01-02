class monitor extends uvm_monitor;
  `uvm_component_utils(monitor);
  transaction trans;
  uvm_analysis_port #(transaction)send;
  virtual apb_if inf;
  function new(string path="mon",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    trans=transaction::type_id::create("trans",this);
    send=new("send",this);
    if(!uvm_config_db #(virtual apb_if)::get(this,"","inf",inf))
      `uvm_info("DRV","ERROR IN CONFIG OF DRIVER",UVM_NONE);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever
      begin
        @(posedge inf.pclk)
        if(!inf.presetn)
          begin
            trans.op=0;
            `uvm_info("MON_RST","RESET OF MONITOR",UVM_NONE);
            send.write(trans);
          end
        else if(inf.pwrite && inf.presetn)
          begin
            @(negedge inf.pready);
            trans.op=1;
            trans.paddr=inf.paddr;
            trans.pwdata=inf.pwdata;
            trans.pslverr=inf.pslverr;
            `uvm_info("MON_WRITE",$sformatf("ADDR:%0d DATA:%0d SLVERR:%0d",trans.paddr,trans.pwdata,trans.pslverr),UVM_NONE);
            send.write(trans);
          end
        else if(!inf.pwrite && inf.presetn)
          begin
            @(negedge inf.pready);
            trans.op=2;
            trans.paddr=inf.paddr;
            trans.prdata=inf.prdata;
            trans.pslverr=inf.pslverr;
            `uvm_info("MON_READ",$sformatf("ADDR:%0d DATA:%0d SLVERR:%0d",trans.paddr,trans.pwdata,trans.pslverr),UVM_NONE);
            send.write(trans);
          end
      end
  endtask
endclass
