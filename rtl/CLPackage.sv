//creating cacheline Package to be used in simplecache module
package cacheLinePackage;
	//adding state definitions for mesi protocol
	//typedef enum{m, e, s, i} CacheState;
	typedef enum logic [1:0] {
		INVALID = 2'b00,
		SHARED = 2'b01,
		EXCLUSIVE = 2'b10,
		MODIFIED = 2'b11
	} CacheState;
    //creating cacheline object
    typedef struct packed {
		logic valid;
		logic dirty;
		logic [25:0] tag; //24 bits bc tag = 28-index(8) = 20
		logic [127:0] block; //data block is 4 words each being 32 bits
		CacheState state; //each cacheline is in a certain state
	 } cacheLine;
endpackage