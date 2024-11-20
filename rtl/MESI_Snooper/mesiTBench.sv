import cacheLinePackage::*;
module MESI_TB;

    // Inputs
    logic clk;
    logic reset;
    logic rh, wh, rm, wm;
	 CacheState currMESI;
    logic share, replacement, gets_obs, getx_obs, inv_obs;

    // Outputs
    logic getx_busAction, inv_busAction, putx_busAction, gets_busAction;
    CacheState newMESI;

    // Instantiate the module under test
    MESI MESI_inst (
        .clk(clk),
        .reset(reset),
        .rh(rh),
        .wh(wh),
        .rm(rm),
        .wm(wm),
		  .currMESI(currMESI),
        .share(share),
        .replacement(replacement),
        .gets_obs(gets_obs),
        .getx_obs(getx_obs),
        .inv_obs(inv_obs),
        .getx_busAction(getx_busAction),
        .inv_busAction(inv_busAction),
        .putx_busAction(putx_busAction),
        .gets_busAction(gets_busAction),
        .newMESI(newMESI)
    );

    // Clock generation
    	//generate clock to sequence tests
	 always
		begin
		clk <=1; #5; clk <= 0; #5;
		end
	 initial
		begin
			reset <= 1; # 11; reset <= 0;
		end
	task gnd;
		begin
		  clk = 0;
		  rh = 0;
		  wh = 0;
		  rm = 0;
		  wm = 0;
		  share = 0;
		  replacement = 0;
		  gets_obs = 0;
		  getx_obs = 0;
		  inv_obs = 0;
		end
	endtask

    // Test cases
	initial begin
		//Set default values
		gnd;
		
		// Case 1: Invalid -> Shared
		$display("Starting test case: Invalid -> Shared");
		#20;
		rm = 1;
		share = 1;
		#10;
		$display("New MESI state: %0d", newMESI);
		assert(newMESI === 1); // Check if state is SHARED
		gnd; //Do after each test

		// Case 2: Shared -> Invalid
		$display("Starting test case: Shared -> Invalid");
		replacement = 1;
		#10;
		$display("New MESI state: %0d", newMESI);
		assert(newMESI === 0); // Check if state is MODIFIED*/
		gnd;

		// Case 3: Invalid -> Exclusive
		$display("Starting test case: Invalid -> Exclusive");
		rm = 1;
		#10;
		$display("New MESI state: %0d", newMESI);
		assert(newMESI === 2); // Check if state is SHARED
		gnd;

		// Case 4:  Exclusive -> Invalid
		$display("Starting test case: Exclusive -> Invalid");
		getx_obs = 1;
		#10;
		$display("New MESI state: %0d", newMESI);
		assert(newMESI === 0); // Check if state is SHARED
		gnd;
		
		// Case 5:  Invalid -> Modified
		$display("Starting test case: Invalid -> Modified");
		wm = 1;
		#10;
		$display("New MESI state: %0d", newMESI);
		assert(newMESI === 3); // Check if state is SHARED
		gnd;
		
		// Case 6:  Modified -> Shared
		$display("Starting test case: Modified -> Shared");
		gets_obs = 1;
		#10;
		$display("New MESI state: %0d", newMESI);
		assert(newMESI === 1); // Check if state is SHARED
		gnd;
		
		// Case 7:  Shared -> Modified
		$display("Starting test case: Shared -> Modified");
		wh = 1;
		#10;
		$display("New MESI state: %0d", newMESI);
		assert(newMESI === 3); // Check if state is SHARED
		gnd;
		
		// Case 8:  Modified -> Invalid
		$display("Starting test case: Modified -> Invalid");
		getx_obs = 1;
		#10;
		$display("New MESI state: %0d", newMESI);
		assert(newMESI === 0); // Check if state is SHARED
		gnd;
		
		//Invalid -> Exclusive - Ignore purely intermediary, we've already seen this functionality(i need a better way to do this :|)
		$display("Intermediate: Invalid -> Exclusive");
		rm = 1;
		#10;
		gnd;
				
		// Case 9:  Exclusive -> Modified
		$display("Starting test case: Exclusive -> Modified");
		wh = 1;
		#10;
		$display("New MESI state: %0d", newMESI);
		assert(newMESI === 3); // Check if state is SHARED
		gnd;
		
		//Modified -> Invalid - Ignore purely intermediary, we've already seen this functionality(i need a better way to do this :|)
		$display("Intermediate: Modified -> Invalid");
		replacement = 1;
		#10;
		gnd;
		
		//Invalid -> Exclusive - Ignore purely intermediary, we've already seen this functionality(i need a better way to do this :|)
		$display("Intermediate: Invalid -> Exclusive");
		rm = 1;
		#10;
		gnd;
		
		// Case 10:  Exclusive -> Shared
		$display("Starting test case: Exclusive -> Shared");
		gets_obs = 1;
		#10;
		$display("New MESI state: %0d", newMESI);
		assert(newMESI === 1); // Check if state is SHARED
		gnd;
	end

endmodule