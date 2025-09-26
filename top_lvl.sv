/* 
 * This top_level module integrates the controller, memory, adder, and result buffer to form a complete calculator system.
 * It handles memory reads/writes, arithmetic operations, and result buffering.
 */
module top_lvl import calculator_pkg::*; (
    input  logic                 clk,
    input  logic                 rst,

    // Memory Config
    input  logic [ADDR_W-1:0]    read_start_addr,
    input  logic [ADDR_W-1:0]    read_end_addr,
    input  logic [ADDR_W-1:0]    write_start_addr,
    input  logic [ADDR_W-1:0]    write_end_addr
    
);

  //Any wires, combinational assigns, etc should go at the top for visibility
  // Internal wires
  logic write, read, loc_sel;
  logic [ADDR_W-1:0] w_addr, r_addr;
  logic [MEM_WORD_SIZE-1:0] w_data, r_data, buffer_o;
  logic [DATA_W-1:0] op_a, op_b, sum_o;

  // Controller instantiation
  controller u_ctrl (
    .clk_i(clk),
    .rst_i(rst),
    .read_start_addr(read_start_addr),
    .read_end_addr(read_end_addr),
    .write_start_addr(write_start_addr),
    .write_end_addr(write_end_addr),
    .write(write),
    .w_addr(w_addr),
    .w_data(w_data),
    .read(read),
    .r_addr(r_addr),
    .r_data(r_data),
    .loc_sel(loc_sel),
    .op_a(op_a),
    .op_b(op_b),
    .buff_result(buffer_o)
  );

    //TODO: Look at the sky130_sram_2kbyte_1rw1r_32x512_8 module and instantiate it using variables defined above.
    // Note: This module has two ports, port 0 for read and write and port 1 for read only. We are using port 0 writing and port 1 for reading in this design.    
    // we have provided all of the input ports of SRAM_A, which you will need to connect to calculator ports inside the parentheses. 
    // Your instantiation for SRAM_A will be similar to SRAM_B. 
  	/*
     * .clk0 : sram macro clock input. Connect to same clock as controller.sv. 
     * .csb0 : chip select, active low. Set low when you want to write. Refer to sky130_sram instantiation to see what value to use for both read and write operations in port 0.
     * .web0 : write enable, active low. Set low when you want to write.  Refer to sky130_sram instantiation to see what value to use for both read and write operations in port 0.
     * .wmask0 : write mask, used to select which bits to write. For this design, we will write all bits, so use 4'hF.
     * .addr0 : address to read/write
     * .din0 : data to write
     * .dout0 : data output from memory when performing a read. Will leave blank here because we are only writing to port 0. 
     * .clk1  : sram macro clock input for port 2. Connect to same clock as controller.sv. 
     * .csb1  : chip select, active low. Set low when you want to read. Since this second port can only be used to read, there is no write enable bit (web) 
     * .addr1 : address to read from. You will supply this value. 
     * .dout1 : data output from the SRAM macro port.
     */
  	
  // SRAM_A instantiation (lower half)
  sky130_sram_2kbyte_1rw1r_32x512_8 sram_A (
    .clk0(clk),
    .csb0(~write), // active low
    .web0(~write), // active low
    .wmask0(4'hF),
    .addr0(read ? r_addr : w_addr), // Use r_addr for read, w_addr for write
    .din0(w_data[31:0]),
    .dout0(),
    .clk1(clk),
    .csb1(~read), // active low
    .addr1(r_addr),
    .dout1(r_data[31:0])
  );

  
  // SRAM_B instantiation (upper half)
  sky130_sram_2kbyte_1rw1r_32x512_8 sram_B (
    .clk0(clk),
    .csb0(~write),
    .web0(~write),
    .wmask0(4'hF),
    .addr0(read ? r_addr : w_addr), // Use r_addr for read, w_addr for write
    .din0(w_data[63:32]),
    .dout0(),
    .clk1(clk),
    .csb1(~read),
    .addr1(r_addr),
    .dout1(r_data[63:32])
  );
  	
  // Adder instantiation
  adder32 u_adder (
    .a_i(op_a),
    .b_i(op_b),
    .sum_o(sum_o)
  );

  // Result buffer instantiation
  result_buffer u_resbuf (
    .clk_i(clk),
    .rst_i(rst),
    .result_i(sum_o),
    .loc_sel(loc_sel),
    .buffer_o(buffer_o)
  );

endmodule
