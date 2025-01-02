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
