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
