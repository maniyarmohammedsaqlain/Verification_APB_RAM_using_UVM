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
