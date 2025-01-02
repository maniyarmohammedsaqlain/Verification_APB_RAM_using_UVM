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
