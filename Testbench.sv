`include "uvm_macros.svh";
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction);
  
  function new(string path="trans");
    super.new(path);
  endfunction
  
  rand bit[31:0]paddr;
  rand bit[31:0]pwdata;
  
  bit[31:0]prdata;
  bit pslverr;
  bit pready;
  bit [1:0]op;
  constraint addr_c { paddr <= 31; }
endclass

class resetd extends uvm_sequence #(transaction);
  `uvm_object_utils(resetd);
  transaction trans;
  function new(string path="rst");
    super.new(path);
  endfunction
  
  virtual task body();
    repeat(10)
      begin
        trans=transaction::type_id::create("trans");
        start_item(trans);
        assert(trans.randomize);
        trans.op=0;
        `uvm_info("RST","DUT RESET",UVM_NONE);
        finish_item(trans);
      end
  endtask
endclass

class writed extends uvm_sequence #(transaction);
  `uvm_object_utils(writed);
  transaction trans;
  
  function new(string path="wr");
    super.new(path);
  endfunction
  
  virtual task body();
    repeat(10)
      begin
        trans=transaction::type_id::create("trans");
        start_item(trans);
        assert(trans.randomize);
        trans.op=1;
        `uvm_info("WR",$sformatf("ADDR:%0d DATA:%0d",trans.paddr,trans.pwdata),UVM_NONE);
        finish_item(trans);
      end
  endtask
endclass

class readd extends uvm_sequence #(transaction);
  `uvm_object_utils(readd);
  transaction trans;
  
  function new(string path="rd");
    super.new(path);
  endfunction
  
  virtual task body();
    repeat(10)
      begin
        trans=transaction::type_id::create("trans");
        start_item(trans);
        assert(trans.randomize);
        trans.op=2;
        `uvm_info("RD",$sformatf("ADDR:%0d DATA:%0d",trans.paddr,trans.prdata),UVM_NONE);
        finish_item(trans);
      end
  endtask
endclass

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

class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard);
  transaction trans;
  uvm_analysis_imp #(transaction,scoreboard)recv;
  bit [31:0] mem[32] = '{default:0};
  bit [31:0] data_rd = 0;
  function new(string path="scb",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    trans=transaction::type_id::create("trans");
    recv=new("recv",this);
  endfunction
  
  virtual function write(transaction tr);
    trans=tr;
    if(trans.op==0)
      begin
        `uvm_info("RST","RESET OCCURED",UVM_NONE);
      end
    else if(trans.op==1)
      begin
        if(trans.pslverr==1)
          begin
            `uvm_info("SCOSLV","SLV ERROR OCCURED",UVM_NONE);
          end
        else
          begin
            mem[trans.paddr]=trans.pwdata;
            `uvm_info("SCO_WRITE",$sformatf("ADDR:%0d DATA:%0d",trans.paddr,trans.pwdata),UVM_NONE);
          end
      end
    else if(trans.op==2)
      begin
        if(trans.pslverr==1)
          begin
            `uvm_info("SCOSLV","SLV ERROR OCCURED",UVM_NONE);
          end
        else
          begin
            data_rd=mem[trans.paddr];
            if(data_rd==trans.prdata)
              begin
                `uvm_info("DATA MATCH",$sformatf("DATA MATCHED ADDR:%0d DATA:%0d",trans.paddr,trans.pwdata),UVM_NONE);
              end
            else
              begin
                `uvm_info("DATA MISMATCH",$sformatf("DATA MISMATCHED ADDR:%0d DATA:%0d Read data=%0d",trans.paddr,trans.pwdata,data_rd),UVM_NONE);
              end
          end
      end
    $display("----------------------------------------------------------");
  endfunction
endclass
                
class agent extends uvm_agent;
  `uvm_component_utils(agent);
  uvm_sequencer #(transaction)seqr;
  driver drv;
  monitor mon;
  function new(string path="a",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr=uvm_sequencer#(transaction)::type_id::create("seqr",this);
    drv=driver::type_id::create("drv",this);
    mon=monitor::type_id::create("mon",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass

class env extends uvm_env;
  `uvm_component_utils(env);
  agent a;
  scoreboard scb;
  function new(string path="env",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a=agent::type_id::create("a",this);
    scb=scoreboard::type_id::create("scb",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.mon.send.connect(scb.recv);
  endfunction
endclass

class test extends uvm_test;
  `uvm_component_utils(test);
  
  function new(string path="test",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  env e;
  resetd rstd;
  writed wrtd;
  readd redd;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e=env::type_id::create("e",this);
    rstd=resetd::type_id::create("rstd",this);
    wrtd=writed::type_id::create("wrtd",this);
    redd=readd::type_id::create("redd",this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    rstd.start(e.a.seqr);
    wrtd.start(e.a.seqr);
    redd.start(e.a.seqr);
    #50;
    phase.drop_objection(this);
  endtask
endclass

module tb;
  apb_if inf();
  apb_ram dut (.presetn(inf.presetn), .pclk(inf.pclk), .psel(inf.psel), .penable(inf.penable), .pwrite(inf.pwrite), .paddr(inf.paddr), .pwdata(inf.pwdata), .prdata(inf.prdata), .pready(inf.pready), .pslverr(inf.pslverr));
  initial
    begin
      inf.pclk=0;
    end
  
  always
    #10 inf.pclk=~inf.pclk;
  
  initial
    begin
      uvm_config_db#(virtual apb_if)::set(null,"*","inf",inf);
      run_test("test");
    end
endmodule
