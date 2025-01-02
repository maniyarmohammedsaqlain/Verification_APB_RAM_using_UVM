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
