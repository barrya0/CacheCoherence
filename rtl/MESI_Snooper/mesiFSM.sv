//mesi fsm
/*
Takes cpu actions and observes bus actions to respond and change the state of a given cacheline
Outputs Bus Actions based on the inputs
*/
import cacheLinePackage::*;

module MESI(input logic clk, reset,
				input logic rh, wh, rm, wm,
				input CacheState currMESI,
				input logic share/*always zero, except when a processor pulls it to one*/,
				input logic replacement, gets_obs, getx_obs, inv_obs,
				output logic getx_busAction, inv_busAction,
				output logic putx_busAction, gets_busAction,
				output CacheState newMESI
				);
	
	CacheState state, nextstate;
	
	always @(posedge clk) begin
	  if (reset) state <= INVALID;
	  else	state <= nextstate;
	end
	always_comb begin
		getx_busAction <= 1'b0;
		inv_busAction <= 1'b0;
		putx_busAction <= 1'b0;
		gets_busAction <= 1'b0;
		nextstate <= state; //Might want to change to invalid
		case(state)
			INVALID: begin
				if(rm) begin
					nextstate <= share ? SHARED : EXCLUSIVE; //If other sharers : no other sharers
					gets_busAction <= 1'b1;
				end
				else if(wm) begin
					nextstate <= MODIFIED;
					getx_busAction <= 1'b1;
				end
			end
			MODIFIED:	begin
				if(gets_obs) begin
					nextstate <= SHARED;
					putx_busAction <= 1'b1;
				end
				else if(getx_obs || replacement) begin
					nextstate <= INVALID;
					putx_busAction <= 1'b1;
				end
				else if(rh || wh) begin
					nextstate <= MODIFIED;
				end
			end
			SHARED:	begin
				if(replacement || getx_obs || inv_obs) begin
					nextstate <= INVALID;
				end
				else if(wh) begin
					nextstate <= MODIFIED;
					inv_busAction <= 1'b1;
				end
				else if(rh || gets_obs) begin
					nextstate <= SHARED;
				end
			end
			EXCLUSIVE:	begin
				if(wh) begin
					nextstate <= MODIFIED;
				end
				else if(getx_obs) begin
					nextstate <= INVALID;
				end
				else if(gets_obs) begin
					nextstate <= SHARED;
				end
				else if(rh) begin
					nextstate <= EXCLUSIVE;
				end
			end
		endcase
	end
	assign newMESI = nextstate;
endmodule 