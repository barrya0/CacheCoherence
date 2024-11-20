/*
-Direct-mapped cache
-write-back using write allocate
-block size: 4 words (16 bytes / 128 bits)
-Cache size:  8 KiB (512 blocks in total)
-32-bit address
-The cache includes a valid bit and dirty bit per block
-Decide address fields
-Byte offset: 2 bits
-Block offset: 2 bits
-Cache index: 8 bits
-Tag size: 20 bits = 32 - (8+2+2)
-non-blocking
*/
import cacheLinePackage::*;

module L3cache(input logic clk, reset,
				 input logic read, write, valid,
				 input logic [31:0] Addr, write_word,
				 output logic [31:0] read_word,
				 input logic [127:0] data_in,
				 output logic [127:0] data_out,
				 output logic ready,
				 output logic write_to_mem, read_from_mem);

	//Define the address tag, index, block and offsets
	logic [7:0] index;
	logic [1:0] offset;
	logic [23:0] addrTag;
	assign {addrTag, index, offset} = Addr;

	//Number of rows = 2^k where k = cache index -> 2^8 = 256
	parameter int rows = 256; //only 16 cache lines
	//create array of cacheline objects
	cacheLine cache[0:rows-1];
	//initialize the table with default 0 - happens at compile time
	initial begin
	 for (int i = 0; i < rows; i++) begin
		cache[i].valid <= 1'b0;
		cache[i].dirty <= 1'b0;
		cache[i].tag <= 24'b0;
		cache[i].block <= 128'b0;
		cache[i].state <= INVALID; //this shouldn't matter?
	 end
	end
	cacheLine newCacheLine;

	DMcacheFSM controller(clk, reset, read, write, valid, offset, addrTag, 
						write_word, cache[index], data_in, 
						data_out, read_word, newCacheLine, ready, write_to_mem, read_from_mem);
	always_ff @(posedge clk) begin
		cache[index] <= newCacheLine; //update cacheline on clock edge
	end
endmodule
module L3cacheFSM(input logic clk, reset,
					 input logic read, write, valid,
					 input logic [1:0] offset,
					 input logic [23:0] addrTag,
					 input logic [31:0] write_word,
					 input cacheLine oldCL /*using cacheline struct in fsm*/,
					 input logic [127:0] data_in,
					 output logic [127:0] data_out,
					 output logic [31:0] read_word,
					 output cacheLine newCL,
					 output logic ready,
					 output logic write_to_mem, read_from_mem);
 
	//Enumerate Cache Controller States
	typedef enum {idle, compareTag, allocate, writeBack} fsm_states;

	fsm_states state, nextstate;

	//state register
	always_ff @(posedge clk) begin
	  if (reset)    state <= idle;
	  else          state <= nextstate;
	end

	//transition and output logic
	always_comb begin
		//default values to avoid inferring latches
		ready <= 1'b0;
		data_out <= '0;
		newCL <= oldCL;
		read_word <= '0;
		write_to_mem <= 1'b0;
		read_from_mem <= 1'b0;
	  case(state)
			idle: begin
						if(valid)	nextstate <= compareTag;
						else begin
							nextstate <= idle;
							ready <= 1'b1;
						end
					end
			compareTag:	begin
							  if(write) begin
									newCL.valid <= 1'b0;	//data invalidated or modified
									newCL.dirty <= 1'b1; //on first write to the cacheline, set dirty bit to 0
							  end
							  if(oldCL.valid && (oldCL.tag == addrTag)) begin //check if tag from cacheline is equal to cpu address tag
									nextstate <= idle;
									if(read) begin
										//read the word from the datablock in the cache using the offset
										case(offset)
											2'b00:	read_word <= {oldCL.block[127:96]};
											2'b01:	read_word <= {oldCL.block[95:64]};
											2'b10:	read_word <= {oldCL.block[63:32]};
											2'b11:	read_word <= {oldCL.block[31:0]};
										endcase
									end	
									else if(write) begin
										//write word from cpu to cache using offset
										case(offset)
											2'b00:	newCL.block[127:96] <= write_word;
											2'b01:	newCL.block[95:64] <= write_word;
											2'b10:	newCL.block[63:32] <= write_word;
											2'b11:	newCL.block[31:0] <= write_word;
										endcase
									end
							  end else begin
									nextstate <= oldCL.dirty ? writeBack : allocate; /*cache miss and old block is dirty : cache miss and old block is clean*/
									//set tag
									newCL.tag <= addrTag;
							  end
						  end
			writeBack:	begin
							  //write old block to mem
							  write_to_mem <= 1'b1;
							  data_out <= oldCL.block;
							  nextstate <= allocate;
							end
			allocate:	begin
							  //read new block from mem
							  read_from_mem <= 1'b1;
							  newCL.valid <= 1'b1; //Validate the line when a new block is allocated to it
							  newCL.dirty <= 1'b0; //set dirty back to low, cacheline is clean
							  newCL.block <= data_in;
							  nextstate <= compareTag;
							end
			default:    begin
								 nextstate <= idle;
							end
	  endcase
	end
endmodule