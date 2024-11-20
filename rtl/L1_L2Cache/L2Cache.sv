/*
-L2 Cache
-4 ways, 16 sets in each way so the index value 2^k is 4 for a total of 64 cache lines
-block size: 4 words (16 bytes / 128 bits)
-cache size: (1024 bytes) <= numSets * Associativity * block size
-offset: 2 bits
-Cache index: 4 bits
-Tag size: 26 bits = 32 - (4+2)
*/
import cacheLinePackage::*;
//4-way set associative cache module - L2
module frway_cache(input logic clk, reset,
						 input logic read, write, read_from_L2, write_to_L2 /*from L1 cache*/,
						 input logic [31:0] Addr,
						 input CacheState newMESI,
						 input logic [127:0] data_in,
						 output logic [127:0] data_out,
						 output logic replacement, rm, wm, hit);
						 
	parameter int ways = 4; //associativity
	parameter int sets = 16;//16 sets in each way so there are a total of 64 cache lines
	
	//Define address tag, index, block and offsets
	logic [3:0] index;
	logic [1:0] offset; // L2 shouldn't need offset bits as it just brings lines in or out, not sure what to do with this for now
	logic [25:0] addrTag;
	assign {addrTag, index, offset} = Addr;
	cacheLine cache[0:ways-1][0:sets-1];
	//initialize the L2 cache to 0(it is empty)
	initial begin
		for (int i = 0; i < ways;i++) begin
			for(int j = 0; j < sets; j++) begin
				cache[i][j].valid <= 1'b0;
				cache[i][j].dirty <= 1'b0;
				cache[i][j].tag <= 26'b0;
				cache[i][j].block <= 128'b0;
				cache[i][j].state <= INVALID;
			end
		end
	end

	SAcacheFSM controller(clk, reset, read, write, read_from_L2, write_to_L2, newMESI,
								 index, addrTag, data_in, data_out, replacement, rm, wm, hit, cache);
endmodule
module SAcacheFSM(input logic clk, reset,
						input logic read, write, read_from_L2, write_to_L2,
						input CacheState newMESI,
						input logic [3:0] index,
						input logic [25:0] addrTag,
						input logic [127:0] data_in,
						output logic [127:0] data_out,
						output logic replacement,
						output logic rm, wm, hit,
						output cacheLine cache[0:3][0:15]);
	//stuff
	typedef enum{idle, compareTag, place, writeback, update} fsm_states;
	
	logic miss;
	int replace_index;
	int empty_index;
	fsm_states state, nextstate;
	
	logic [127:0] tempDataBlock;
	//state register
	always_ff @(posedge clk) begin
		if (reset) state <= idle;
		else state <= nextstate;
	end
	
	//transition and output logic
	always_comb begin
		miss = 1'b1;
		tempDataBlock <= 128'b0;
		replacement <= 1'b0;
		rm <= 1'b0;
		wm <= 1'b0;
		replace_index = 0;
		data_out <= 'b0;
		hit <= 1'b0;
		empty_index = 0;
		for (int i = 0; i < 4;i++) begin
			for(int j = 0; j < 16; j++) begin
				cache[i][j].valid <= 1'b0;
				cache[i][j].dirty <= 1'b0;
				cache[i][j].tag <= 26'b0;
				cache[i][j].block <= 128'b0;
				cache[i][j].state <= INVALID;
			end
		end
		case(state)
			idle: begin
				//if L1 issues a read
				if(read_from_L2) begin
					nextstate <= compareTag;
				end else if(write_to_L2) begin
					//L1 issues an eviction into L2
					nextstate <= place;
				end
				else begin
					nextstate <= idle;
				end
			end
			compareTag: begin
				//check each way for a hit
				for(int i = 0; i < 4; i++) begin
					if(cache[i][index].valid && (cache[i][index].tag == addrTag)) //If set valid and the tag is the same
						begin
							//L2 hit
							miss = 1'b0;
							tempDataBlock <= cache[i][index].block;
							break;
						end
				end
				if(miss) begin
					if(read)begin
						rm <= 1'b1;
					end
					else if(write) begin
						wm <= 1'b1;
					end
				end
				else begin
					hit <= 1'b1;
					data_out <= tempDataBlock; //send the block to L1 cache
				end
				nextstate <= idle;
			end
			place: begin
				//Write data from L1 to L2 on L1 cache eviction
				/*
					1. Try to place the block in an empty slot
					2. If there isn't one, apply a writeback or replacement policy on the bus to higher level cache
				*/
				// Check for empty slot in the set
            empty_index = -1;
            for (int i = 0; i < 4; i++) begin
                if (!cache[i][index].valid) begin
                    empty_index = i;
                    break;
                end
            end

            if (empty_index != -1) begin
                // Place the block in an empty slot
                cache[empty_index][index].valid <= 1'b1;
                cache[empty_index][index].tag <= addrTag;
                cache[empty_index][index].block <= data_in;
					 cache[empty_index][index].state <= newMESI;
					 nextstate <= idle;
            end else begin
					nextstate <= writeback;
				end
			end
			writeback: begin
				// CPU Replacement High
				replacement <= 1'b1;
				data_out <= cache[replace_index][index].block; //block to be written to higher memory
				nextstate <= update;
			end
			update: begin
				//update the block in the cacheline
				cache[replace_index][index].valid <= 1'b1;
				cache[replace_index][index].tag <= addrTag;
				cache[replace_index][index].block <= data_in;
				cache[replace_index][index].state <= newMESI;
				nextstate <= idle;
			end
			default: nextstate <= idle;
		endcase
	end
endmodule