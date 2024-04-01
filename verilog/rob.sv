`include "verilog/sys_defs.svh"
// 
module rob(
    input logic clock,
    input logic reset,
    // from stage_id
    input ID_RS_PACKET id_packet,

    // from functional units -> priority selector
    input FU_PACKET fu_packet,

    // from reservation station: if not valid, don't move tail
    input dispatch_valid, 
    
    output logic structural_hazard,
    
    // to regfile
    output logic [4:0] r,
    output logic [`XLEN-1:0] v,

    // to reservation responsible for dispatch and for the reservation station
    // to check for dependent values
    output ROB_ENTRY entry [7:0], // TODO: check lab 5 to decide whetehr [7:0] comes before or after entry.
    output ROB_TAG tail_to_rs
    );

    ROB_ENTRY entry [7:0];
    ROB_TAG head, tail;

    assign tail_to_rs = tail;

    always_ff@(posedge clock, posedge reset) begin
	if (reset) begin
	    for (int i = 0; i < 8; i++) begin
	        entry[i].complete <= 0;
                entry[i].r <= '0;
                entry[i].V <= '0;
                entry[i].id_packet <= '0;
            end
	end
	else begin
	    // populate ROB entry at every allocate
	    // Warning: please don't write from scratch. Adapt code from
	    // online implementations of FIFO buffers and note how they move
	    // the head and tail.
	    // the tail should never "overtake" the head
	end
    end

endmodule
