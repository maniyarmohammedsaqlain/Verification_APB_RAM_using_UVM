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
