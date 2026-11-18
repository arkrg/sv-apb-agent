class apb_master_driver extends apb_driver;
  `uvm_component_utils(apb_master_driver);

  function new(string name = "apb_master_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task drive_transfer(apb_item item);
    @(vif.cb);
    vif.cb.psel   <= 1;
    vif.cb.paddr  <= (item.paddr & addr_mask);
    vif.cb.pwrite <= item.pwrite;
    if (item.pwrite) vif.cb.pwdata <= (item.pwdata & data_mask);
    vif.cb.penable <= 0;
    @(vif.cb);
    vif.cb.penable <= 1;
    do begin
      @(vif.cb);
    end while (!vif.cb.pready);
    if (!item.pwrite) item.prdata = vif.cb.prdata;
    item.pslverr = vif.cb.pslverr;
    clear();
  endtask

endclass
