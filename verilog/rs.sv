`include "verilog/sys_defs.svh"
//`include "verilog/entry.svh"


module rs(
    input logic clock,
    input logic reset,
    // from stage_id
    input ID_RS_PACKET id_packet,

    // from CDB
    input CDB_PACKET cdb_packet,

    // from map table, whether rs_T1/2 is empty or a specific #RS
    input RS_TAG rs_tag_a,
    input RS_TAG rs_tag_b, 

    // to map table, keeping naming convention same as map_table.sv
    output dispatch_valid, 
    output RS_TAG fu_source, 

    // TODO: this part tentatively goes to the execution stage. In milestone 2, Expand this part so that it goes to separate functional units
    output ID_RS_PACKET rs_packet
); // TODO: The rs doesn't talk to the map table yet. Expand interface to enable talking to and getting packets from map table

    // Define and initialize the entry packets array
    RS_ENTRY entry [5:0];
    logic allocate, free;
    RS_TAG allocate_tag, free_tag;

    assign dispatch_valid = allocate;
    assign fu_source = allocate_tag;
    
    // Initialize FU types for each entry packet instance
    initial begin
        entry[0].fu = ALU;
        entry[1].fu = Load;
        entry[2].fu = Store;
        entry[3].fu = FloatingPoint;
        entry[4].fu = FloatingPoint;
    end

    // TODO: re-do this part to correspond to specific entries for debugging only
    always_ff @(posedge clock or posedge reset) begin
	if (reset) begin
	    rs_packet <= 0;
	end
	else begin
	    rs_packet <= id_packet;
	end
    end

    // Free Entry Logic
    always_comb begin
        free = 0;
        free_tag = 7;
        for (int i = 5; i >= 1; i--) begin
            if (i == cdb_packet.tag) begin
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
                entry[i].r <= '0;
                entry[i].opcode <= '0;
                entry[i].valid <= '0;
                entry[i].busy <= '0;
                entry[i].v1_valid <= '0;
                entry[i].v2_valid <= '0;
                entry[i].issued <= '0;
                entry[i].id_packet <= '0;
            end
        end 
        if (free) begin
            entry[free_tag].t1 <= '0;
            entry[free_tag].t2 <= '0;
            entry[free_tag].v1 <= '0;
            entry[free_tag].v2 <= '0;
            entry[free_tag].r <= '0;
            entry[free_tag].id_packet <= '0;
            entry[free_tag].busy <= 1'b0;
        end
        if (allocate) begin 
            entry[allocate_tag].t1 <= rs_tag_a;
            entry[allocate_tag].t2 <= rs_tag_b;
            entry[allocate_tag].v1 <= id_packet.rs1_value; // TODO: the logic for this part is not complete
            entry[allocate_tag].v2 <= id_packet.rs2_value;
            entry[allocate_tag].r <= id_packet.dest_reg_idx;
            entry[allocate_tag].id_packet <= rs_packet;
            entry[allocate_tag].busy <= 1'b1;
	    end
    end
    
endmodule
