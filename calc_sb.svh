class calc_sb #(int DataSize, int AddrSize);

  // Signals needed for the golden model implementation in the scoreboard
  int mem_a [2**AddrSize];
  int mem_b [2**AddrSize];
  logic second_read = 0;
  int golden_lower_data;
  int golden_upper_data;
  mailbox #(calc_seq_item #(DataSize, AddrSize)) sb_box;

  function new(mailbox #(calc_seq_item #(DataSize, AddrSize)) sb_box);
    this.sb_box = sb_box;
    // Initialize memory arrays to avoid X propagation
    foreach(mem_a[i]) begin
      mem_a[i] = 0;
      mem_b[i] = 0;
    end
  endfunction

  task main();
    calc_seq_item #(DataSize, AddrSize) trans;
    forever begin
      sb_box.get(trans);
      // Handle initialization transactions
      if (trans.initialize) begin
        if (!trans.initialize_loc_sel) begin
          mem_a[trans.initialize_addr] = trans.initialize_data;
          $display("[SB] Initialized SRAM A addr=0x%0h with data=0x%0h", trans.initialize_addr, trans.initialize_data);
        end else begin
          mem_b[trans.initialize_addr] = trans.initialize_data;
          $display("[SB] Initialized SRAM B addr=0x%0h with data=0x%0h", trans.initialize_addr, trans.initialize_data);
        end
      end
      
      // Handle read transactions
      else if (!trans.rdn_wr) begin
        // Compare read data with stored memory values
        if (!second_read) begin
          // First read - store for later comparison
          golden_lower_data = mem_a[trans.curr_rd_addr];
          golden_upper_data = mem_b[trans.curr_rd_addr];
          
          // Compare against DUT read values
          if (trans.lower_data !== golden_lower_data) begin
            $error("[SB] SRAM A read mismatch at addr=0x%0h: Expected=0x%0h, Got=0x%0h", 
                  trans.curr_rd_addr, golden_lower_data, trans.lower_data);
            $finish;
          end
          if (trans.upper_data !== golden_upper_data) begin
            $error("[SB] SRAM B read mismatch at addr=0x%0h: Expected=0x%0h, Got=0x%0h", 
                  trans.curr_rd_addr, golden_upper_data, trans.upper_data);
            $finish;
          end
          second_read = 1;
          $display("[SB] Read verified from addr=0x%0h: SRAM_A=0x%0h, SRAM_B=0x%0h", 
                  trans.curr_rd_addr, golden_lower_data, golden_upper_data);
        end
      end
      
      // Handle write transactions
      else begin
        if (second_read) begin
          // Calculate expected result (add values from both reads)
          longint expected_result = golden_lower_data + golden_upper_data;
          longint dut_result = {trans.upper_data, trans.lower_data};
          
          if (dut_result !== expected_result) begin
            $error("[SB] Addition result mismatch at addr=0x%0h: Expected=0x%0h, Got=0x%0h", 
                  trans.curr_wr_addr, expected_result, dut_result);
            $finish;
          end
          
          // Update scoreboard memory with new values
          mem_a[trans.curr_wr_addr] = trans.lower_data;
          mem_b[trans.curr_wr_addr] = trans.upper_data;
          
          $display("[SB] Write verified at addr=0x%0h: Result=0x%0h", 
                  trans.curr_wr_addr, dut_result);
          
          second_read = 0; // Reset for next operation
        end
      end
    end
  endtask

endclass : calc_sb
