`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

`ifdef TESTBENCH
`include "RS_ENTRY_IF.sv"
`endif

`ifdef TESTBENCH
    `define INTERFACE_PORT RS_ENTRY_IF.producer if_rs
`else
    `define INTERFACE_PORT
`endif
module rs(
    input logic clock,
    input logic reset,
    // from stage_id. TODO: this part is now redundant because instructions
    // are dispatched from the reorder buffer
    input ID_RS_PACKET id_packet,

    // from CDB
    input CDB_PACKET cdb_packet,

    // from map table, whether rs_T1/2 is empty or a specific #ROB
    input ROB_TAG rob_tag_a,
    input ROB_TAG rob_tag_b, 

    // from reorder buffer, the entire reorder buffer and the tail indicating
    // the instruction being dispatched. 
    input ROB_TAG tail,
    input ROB_ENTRY rob_entry [7:0],

    // to map table and ROB
    output dispatch_valid, 

    // to map table, the tag of the ROB where the instruction is stored
    output ROB_TAG rob_source, 

    // TODO: this part tentatively goes to the execution stage. In milestone 2, Expand this part so that it goes to separate functional units
    output ID_RS_PACKET rs_packet
);

    // Define and initialize the entry packets array
    RS_ENTRY entry [5:0];
    logic allocate, free;
    RS_TAG allocate_tag, free_tag;

    assign dispatch_valid = allocate;
    assign rob_source = tail;
    
    // Initialize FU types for each entry packet instance
    initial begin
        entry[1].fu = ALU;
        entry[2].fu = Load;
        entry[3].fu = Store;
        entry[4].fu = FloatingPoint;
        entry[5].fu = FloatingPoint;
    end

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            rs_packet <= 0;

	    `ifdef TESTBENCH
            foreach (if_rs.entry[i]) begin
                if_rs.entry[i] = '{default:0};
            end
	    `endif
 
        end else begin
            rs_packet <= id_packet;

	    `ifdef TESTBENCH
	    foreach (if_rs.entry[i]) begin
                if_rs.entry[i] = entry[i];
            end
            `endif

        end
    end

    // Free Entry Logic
    always_comb begin
        free = 0;
        free_tag = 7;
        for (int i = 5; i >= 1; i--) begin
            if (i == cdb_packet.tag) begin
                free_tag = i;
	        free = 1;
            end
        end
        ready_for_execution = 1'b0; // Default to not ready
        for (int i = 1; i <= 5; i++) begin
            if (entry[i].v1_valid && entry[i].v2_valid) begin
                ready_for_execution = 1'b1; //when this is high it is ready to produce output packet
                break; // Assuming only one entry is handled per cycle
            end
        end //priority encoder goes here too
    end


    // Free Entry Logic
    always_comb begin
        free = 0;
        free_tag = 7;
        for (int i = 5; i >= 1; i--) begin
            if (entry[i].r == cdb_packet.rob_tag) begin
                free_tag = i;
            end
        end
    end

    // Allocate Logic
    always_comb begin
	allocate = 0;
	allocate_tag = 7; // Don't have 7 reservation station entries, so reserve 7 for invalid address
	case (id_packet.inst[6:0])
        7'b0000011: begin // Load
            for (int i = 5; i >= 1; i--) begin
                if (!entry[i].busy && entry[i].fu == Load) begin
		            allocate = 1;
		            allocate_tag = i;
		        end
	    end	    
        end
        7'b0100011: begin // Store
            for (int i = 5; i >= 1; i--) begin
                if (!entry[i].busy && entry[i].fu == Store) begin
                    allocate = 1; 
                    allocate_tag = i;
                end
	    end	    
	end
        7'b1000011: begin // Floating Point
            for (int i = 5; i >= 1; i--) begin
                if (!entry[i].busy && entry[i].fu == FloatingPoint) begin
                    allocate = 1;
                    allocate_tag = i; 
		        end
	    end	    
	end
	default: begin
            for (int i = 5; i >= 1; i--) begin
                if (!entry[i].busy && entry[i].fu == ALU) begin
                    allocate = 1; 
                    allocate_tag = i;
		end
	    end	    
	end
        endcase
    end

    // Update Logic
     
    
    // Clearing mechanism on reset, preserving the FU content
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            for (int i = 1; i <= 5; i++) begin
                entry[i].t1 <= '0;
                entry[i].t2 <= '0;
                entry[i].v1 <= '0;
                entry[i].v2 <= '0;
		entry[i].v1_valid <= 0;
		entry[i].v2_valid <= 0;
                entry[i].r <= '0;
                entry[i].opcode <= '0;
                entry[i].valid <= '0;
                entry[i].busy <= '0;
                entry[i].issued <= '0;
                entry[i].id_packet <= '0;
            end
        end 
        if (free) begin
            entry[free_tag].t1 <= '0;
            entry[free_tag].t2 <= '0;
            entry[free_tag].v1 <= '0;
            entry[free_tag].v2 <= '0;
	    entry[free_tag].v1_valid <= 0;
	    entry[free_tag].v2_valid <= 0;
            entry[free_tag].r <= '0;
	    entry[free_tag].opcode <= 0;
	    entry[free_tag].valid <= 0;
	    entry[free_tag].busy <= 0;
	    entry[free_tag].issued <= 0;
            entry[free_tag].id_packet <= '0;
        end
        if (allocate) begin 
            entry[allocate_tag].t1 <= rob_tag_a;
            entry[allocate_tag].t2 <= rob_tag_b;
            entry[allocate_tag].v1 <= (rob_tag_a == cdb_packet.rob_tag) ? cdb_packet.value : id_packet.rs1_value; // TODO: the logic for this part is not correct, be very careful how this part is handled
            entry[allocate_tag].v2 <= (rob_tag_b == cdb_packet.rob_tag) ? cdb_packet.value : id_packet.rs2_value;
	    entry[allocate_tag].v1_valid <= (rob_tag_a == 0) ? 1 : 0;
	    entry[allocate_tag].v2_valid <= (rob_tag_b == 0) ? 1 : 0;
            entry[allocate_tag].r <= tail;
	    entry[allocate_tag].opcode <= id_packet.inst[6:0]; // TODO:check this part
	    entry[allocate_tag].valid <= 1;
            entry[allocate_tag].busy <= 1'b1;
	    entry[allocate_tag].issued <= (rob_tag_a == 0) && (rob_tag_b == 0);
            entry[allocate_tag].id_packet <= id_packet;
	end
    end
    
endmodule
