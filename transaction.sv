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
