/*
Upper level module for L1 and L2 hierarchy
Will contain a snooper fsm module that will observe bus actions from other private caches and set bus actions from within the L1 <-> L2 interaction2(e.g. cache's l1 and l2 have a miss and must send a getS request on the bus to which the other processor caches/main memory will respond with data/information
*/
import cacheLinePackage::*;

module Exclusive_L1L2(input logic clk, reset,
							 input logic [33:0] FullAddr,
							 input logic [31:0] write_word,
							 input logic read, write, request,
							 inout share,
							 input logic gets_obs, getx_obs, inv_obs,
							 input logic [127:0] data_in,
							 output logic [127:0] data_out,
							 output logic [31:0] read_word,
							 output logic ready,
							 output logic getx_BA, inv_BA,
							 output logic putx_BA, gets_BA);
		 
	//Intermediate signals
	CacheState currMESI, newMESI;
	logic [1:0] pid; //processor ID
	logic [31:0] Addr;
	assign {pid, Addr} = FullAddr;
	logic [127:0] blockForward, newBlock, blockOut;
	//for L1-L2 communication
	logic write_to_L2;
	logic read_from_L2;
	logic replacement;
	logic rm, wm, rh, wh, L2hit;
	
	assign newBlock = L2hit ? blockForward : data_in; /*Assign the newBlock (data_in) to L1 cache based on L2 hit signal, if L2 high then we know there was a miss in L1 but it was found in L2 so set the input to Block forward from L2 : otherwise newBlock will be from block loaded from external memory*/
	assign data_out = replacement ? blockForward : 128'b0;
	
	//dm cache module - L1
	dmcache L1(clk, reset, read, write, request, newMESI, Addr, write_word, read_word, newBlock, blockOut, ready, write_to_L2, read_from_L2, rh, wh, currMESI);
	
	//SA cache module - L2
	frway_cache L2(clk, reset, read, write, read_from_L2, write_to_L2, Addr, newMESI, blockOut/*L1 block to L2*/, blockForward/*L2 block to L1 or writeback*/, replacement, rm, wm, L2hit);
	
	//MESI Snooper module -- SNOOPER MUST ALSO MONITOR 32-BIT DATA/ADDRESS ON BUS FOR BROADCASTED BUS ACTIONS
	MESI snooper(clk, reset, rh, wh, rm, wm, currMESI /*current state of a cache line in L1 or L2?*/, share/*input from bus to see if other processors have requested cache line*/, replacement, gets_obs, getx_obs, inv_obs, getx_BA, inv_BA, putx_BA, gets_BA, newMESI/*new updated cache state written to where the line was found?*/);
	always_comb begin
		share <= 1'b0;
		if(gets_obs) begin
			share <= rh ? 1'b1: 1'b0;
		end
	end
endmodule
