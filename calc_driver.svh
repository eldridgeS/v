class calc_driver #(int DataSize, int AddrSize);

  mailbox #(calc_seq_item #(DataSize, AddrSize)) drv_box;

  virtual interface calc_if #(.DataSize(DataSize), .AddrSize(AddrSize)) calcVif;

  function new(virtual interface calc_if #(DataSize, AddrSize) calcVif,
      mailbox #(calc_seq_item #(DataSize, AddrSize)) drv_box);
    this.calcVif = calcVif;
    this.drv_box = drv_box;
  endfunction

  task reset_task();
    // TODO: Write the code to apply a reset sequence to the DUT.
    // HINT: Does the DUT does an active-high or active-low reset?
    // HINT: Use @(calcVif.cb) to wait for a clock cycle. This is called a clocking
    // event which is equivalent to @(posedge clk) if the clocking block (CB) uses the
    // same clock signal, but with the input signals in the CB being sampled with the
    // specified delay BEFORE the clock edge and the output signals in the CB being
    // sampled with the specified delay AFTER the clock edge. This helps with addressing
    // race conditions in simulation to keep testbenches deterministic.
    // Apply a reset sequence to the DUT.
    // The DUT has an active-high reset.
    $display($stime, " Drv: Resetting DUT");
    calcVif.cb.reset <= 1;
    @(calcVif.cb);
    calcVif.cb.reset <= 0;
    $display($stime, " Drv: Reset complete");
  endtask

  virtual task initialize_sram(input [AddrSize-1:0] addr, input [DataSize-1:0] data, input logic block_sel);
    // TODO: Write the code to drive the signals for SRAM initialization.
    //       Add a display statement to make it clearer in the simulation log that the driver is
    //       initializing the SRAM (and which one out of A or B it is)
    // HINT: Think about which signals in the clocking block should be driven to allow the
    // monitor to determine that SRAM is being initialized.
    // Drive the signals for SRAM initialization.
    //$display($stime, " Drv: Initializing SRAM %s, Addr: 0x%0h, Data: 0x%0h", block_sel ? "B" : "A", addr, data);
    calcVif.cb.initialize <= 1;
    calcVif.cb.initialize_addr <= addr;
    calcVif.cb.initialize_data <= data;
    calcVif.cb.initialize_loc_sel <= block_sel;
    @(calcVif.cb);
    calcVif.cb.initialize <= 0;
  endtask : initialize_sram

  virtual task start_calc(input logic [AddrSize-1:0] read_start_addr, input logic [AddrSize-1:0] read_end_addr,
      input logic [AddrSize-1:0] write_start_addr, input logic [AddrSize-1:0] write_end_addr,
      input bit direct = 1);

    int delay;
    calc_seq_item #(DataSize, AddrSize) trans;
    // TODO: Drive the calculation parameters to the DUT's interface.
    // HINT: Use calcVif.cb.signal_name <= value;
    //       Think about what the DUT's top level inputs are
    // TODO: Add a display statement to show the transaction is starting.
    // Drive the calculation parameters to the DUT's interface.
    $display($stime, " Drv: Starting calculation. Read Addr: 0x%0h -> 0x%0h, Write Addr: 0x%0h -> 0x%0h", read_start_addr, read_end_addr, write_start_addr, write_end_addr);
    calcVif.cb.read_start_addr <= read_start_addr;
    calcVif.cb.read_end_addr <= read_end_addr;
    calcVif.cb.write_start_addr <= write_start_addr;
    calcVif.cb.write_end_addr <= write_end_addr;
    
    reset_task();
    @(calcVif.cb iff calcVif.cb.ready);

    if (!direct) begin // Random Mode
      if (drv_box.try_peek(trans)) begin
        delay = $urandom_range(0, 5); // Add a Random delay before the next transaction
        repeat (delay) begin
          @(calcVif.cb);
        end
      end
    end
    calcVif.cb.reset <= 1;
  endtask : start_calc

  virtual task drive();
    calc_seq_item #(DataSize, AddrSize) trans;
    while (drv_box.try_get(trans)) begin
      start_calc(trans.read_start_addr, trans.read_end_addr, trans.write_start_addr, trans.write_end_addr, 0);
    end
  endtask : drive

endclass : calc_driver