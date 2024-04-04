// Version 1.1.0
`ifdef TESTBENCH
    `include "sys_defs.svh"
`else
    `include "verilog/sys_defs.svh"
`endif

module rob(
    // Basic Signal Input:
    input logic clock,
    input logic reset,

    // Input packages from Map_Table:
    input MAP_ROB_PACKET map_rob_packet,
    // Output packages to Map_Table:
    output ROB_MAP_PACKET rob_map_packet,

    // Input packages from Instructions_Buffer:
    input DP_PACKET instructions_buffer_rob_packet,

    // Output packages to Map_Table:
    output ROB_RS_PACKET rob_rs_packet, 
    
    // Harzard Signal for ROB
    output logic structural_hazard_rob
    );

    // Internal memory define, which connected to FIFO:
    ROB_ENTRY rob_entry [`ROB_SZ - 1:0]; // ROB_SZ default to 8
    ROB_TAG head, tail; // logic [2:0], 3 bits index

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < `ROB_SZ; i++) begin // FIFO initialation
                rob_entry[i].complete   <= '0;
                rob_entry[i].r          <= '0;
                rob_entry[i].V          <= '0;
                rob_entry[i].rob_tag    <= '0;
                rob_entry[i].id_packet  <= '0;
            end

            head <= 3'b0; // Pointers initializaion
            tail <= 3'b0;

            rob_map_packet <= '0; // Output packets initialization
            rob_rs_packet  <= '0;

            structural_hazard_rob <= '0; // Output signal initialization
        end else begin

        end                                              
    end

    /*
	else begin
	    // populate ROB entry at every allocate
	    // Warning: please don't write from scratch. Adapt code from
	    // online implementations of FIFO buffers and note how they move
	    // the head and tail.
	    // the tail should never "overtake" the head
	end
    */

endmodule
