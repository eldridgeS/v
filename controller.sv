module controller import calculator_pkg::*;(
  	input  logic              clk_i,
    input  logic              rst_i,
  
  	// Memory Access
    input  logic [ADDR_W-1:0] read_start_addr,
    input  logic [ADDR_W-1:0] read_end_addr,
    input  logic [ADDR_W-1:0] write_start_addr,
    input  logic [ADDR_W-1:0] write_end_addr,
  
  	// Control
    output logic write,
    output logic [ADDR_W-1:0] w_addr,
    output logic [MEM_WORD_SIZE-1:0] w_data,

    output logic read,
    output logic [ADDR_W-1:0] r_addr,
    input  logic [MEM_WORD_SIZE-1:0] r_data,

  	// Buffer Control (1 = upper, 0, = lower)
    output logic              loc_sel,
  
  	// These go into adder
  	output logic [DATA_W-1:0]       op_a,
    output logic [DATA_W-1:0]       op_b,
  
    input  logic [MEM_WORD_SIZE-1:0]       buff_result
  
); 
	//TODO: Write your controller state machine as you see fit. 
	//HINT: See "6.2 Two Always BLock FSM coding style" from refmaterials/1_fsm_in_systemVerilog.pdf
	// This serves as a good starting point, but you might find it more intuitive to add more than two always blocks.

	//See calculator_pkg.sv for state_t enum definition
  state_t state, next;

	//State reg, other registers as needed

	logic [ADDR_W-1:0] cur_read_address, cur_write_address,write_address_r, read_address_r;
	logic address_end;
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			state <= S_IDLE;
        	cur_read_address <= read_start_addr;
        	cur_write_address <= write_start_addr;
        	loc_sel <= 1'b1;
		end else begin
        state <= next;
		if (state == S_IDLE) begin
		end
        if (state == S_READ)
            cur_read_address <= cur_read_address + 1;
        if (state == S_WRITE)
            cur_write_address <= cur_write_address + 1;
        if (state == S_ADD)
            loc_sel <= ~loc_sel;
    end
	end
	
	always_comb begin
    // Default assignments
    write = 1'b0;
    read = 1'b0;
    w_data = '0;
    w_addr = cur_write_address;
    r_addr = cur_read_address;

    case (state)
        S_IDLE: next = S_READ;
        S_READ: begin
			write = 1'b0;
            read = 1'b1;
            next = S_ADD;
        end
        S_ADD: next = (loc_sel == 1'b0) ? S_WRITE : S_READ;
        S_WRITE: begin
			read = 1'b0;
            write = 1'b1;
            w_data = buff_result;
            next = (address_end == 1'b0) ? S_READ : S_END;
        end
        S_END: next = S_END;
    endcase
end

	assign address_end = (cur_write_address >= write_end_addr);
	assign op_a = r_data[DATA_W-1:0];
	assign op_b = r_data[MEM_WORD_SIZE-1:DATA_W];

endmodule