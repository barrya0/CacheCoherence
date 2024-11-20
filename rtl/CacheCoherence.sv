/*
Multi-Core Cache Coherence
• Processor ID in use
	o E.g., add two bits to address (requests)
• L1: direct-mapped
• L2: four-way set-associative
• L3: (?) - might make this just a big direct-mapped if associativity is 2 weird
• Write-back & write-allocate
• Treat a write miss as a read miss followed by a hit
• Two-Phase Clocking in RTL Design
	o Phase 1 on falling edge
	o Phase 2 on rising edge
• Bi-directional, e.g., L1 to / from L2
	o Only one unit can drive the bus at each cycle; others will receive signals from the bus.
	o Add tag bits to inform whether address or data on the bus and its source
• Split-transaction bus
	o E.g., addr, word0, word1, word2, word 4; each takes one cycle.
• Cache controller for basic cache operations
• Arbiters to decide which to drive bus
• Snooper / snooping controller
	o Use MESI snooping protocol
	o L1 snoops on both L1 <-> L2 bus and L2 <-> memory bus
• Develop test cases
	o All possible state transitions
*/
//import cacheLinePackage::*;

module topLevelBench(); //top level test bench to verify full design upon completion
endmodule

module CacheCoherence(input logic clk, reset,
							 input logic [33:0] FullAddr_Pa, FullAddr_Pb, FullAddr_Pc, FullAddr_Pd,
							 inout share);
	logic [31:0] write_word;
	logic read, write, req;
	logic gets_obs, getx_obs, inv_obs;
	logic [127:0] data_in;
	logic [127:0] data_out;
	logic [31:0] read_word;
	logic ready;
	logic getx_BA, inv_BA;
	logic putx_BA, gets_BA;
	//--- NEED TO REFINE THIS AND FIGURE OUT HOW TO CONNECT THESE INSTANCES TO A COMMON BUS INTERFACE ---//
	/*Add requested address input to exclusivel1l2*/
	Exclusive_L1L2 Pa(clk, reset, FullAddr_Pa, write_word, read, write, req, share, gets_obs, getx_obs, inv_obs, data_in, data_out, read_word, ready, getx_BA, inv_BA, putx_BA, gets_BA);
	Exclusive_L1L2 Pb(clk, reset, FullAddr_Pb, write_word, read, write, req, share, gets_obs, getx_obs, inv_obs, data_in, data_out, read_word, ready, getx_BA, inv_BA, putx_BA, gets_BA);
	Exclusive_L1L2 Pc(clk, reset, FullAddr_Pc, write_word, read, write, req, share, gets_obs, getx_obs, inv_obs, data_in, data_out, read_word, ready, getx_BA, inv_BA, putx_BA, gets_BA);
	Exclusive_L1L2 Pd(clk, reset, FullAddr_Pd, write_word, read, write, req, share, gets_obs, getx_obs, inv_obs, data_in, data_out, read_word, ready, getx_BA, inv_BA, putx_BA, gets_BA);
	
	//Instantiate bus interface
	L3Bus bus();
	//Call the Arbiter
	RoundRobinArbiter #(4) Arbiter(bus.clk, bus.rstN, bus.req, bus.grant);
	
	/* --- IGNORE - JUST FOR SHOWING A SHARED L3 ---*/
//	logic [31:0] Addr;
//	logic [1:0] select;
//	logic write_to_mem, read_from_mem;
//	assign {select, Addr} = FullAddr_Pa;
//	//Shared L3 cache - DM
//	L3cache L3(clk, reset, read, write, valid, Addr, write_word, reaad_word, data_in, data_out, ready, write_to_mem, read_from_mem);
	//----------------------------------------------/
endmodule

// Define the L3 bus interface

interface L3Bus;
	//Connect four caches
	//CacheInterface cache1, cache2, cache3, cache4;
	//Create common signals - THESE ARE ALL DANGLING FOR NOW :(
	logic [33:0] FullAddr;
	logic [31:0] write_word;
	logic read;
	logic write;
	logic request;
	logic [127:0] data_in;
	// Common outputs
	logic [127:0] data_out;
	logic [31:0] read_word;
	logic ready;
	// Bus-specific signals
	logic gets_obs;
	logic getx_obs;
	logic inv_obs;
	logic [1:0] select; // Bus select signal to distinguish between different modules
	
	parameter int NumRequests = 4;
	//Arbiter Signals
	logic clk;
	logic rstN;
	logic [NumRequests-1:0] req;
	logic [NumRequests-1:0] grant;
  
endinterface