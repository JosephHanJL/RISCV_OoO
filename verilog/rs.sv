`include "verilog/sys_defs.svh"
//`include "verilog/entry.svh"


module rs(
    input logic clock,
    input logic reset,
    input ID_RS_PACKET id_packet,
    output ID_RS_PACKET rs_packet
);
    // Define and initialize the entry packets array
    RS_ENTRY entry [4:0];
    logic allocate;
    RS_TAG rs_tag;
    
    // Initialize FU types for each entry packet instance
    initial begin
        entry[0].fu = ALU;
        entry[1].fu = Load;
        entry[2].fu = Store;
        entry[3].fu = FloatingPoint;
        entry[4].fu = FloatingPoint;
    end

    always_ff @(posedge clock or posedge reset) begin
	if (reset) begin
	    rs_packet <= 0;
	end
	else begin
	    rs_packet <= id_packet;
	end
    end

    
    always_comb begin
	allocate = 0;
	rs_tag = 7; // Don't have 7 reservation station entries, so reserve 7 for invalid address
	case (id_packet.inst[6:0])
        7'b0000011: begin // Load
            for (int i = 4; i >= 0; i--) begin
                if (!entry[i].busy && entry[i].fu == Load) begin
		   allocate = 1;
		   rs_tag = i;
		end
	    end	    
        end
        7'b0100011: begin // Store
            for (int i = 4; i >= 0; i--) begin
                if (!entry[i].busy && entry[i].fu == Store) begin
		   allocate = 1; 
		   rs_tag = i;
		end
	    end	    
	end
        7'b1000011: begin // Floating Point
            for (int i = 4; i >= 0; i--) begin
                if (!entry[i].busy && entry[i].fu == FloatingPoint) begin
		   allocate = 1;
		   rs_tag = i; 
		end
	    end	    
	end
	default: begin
            for (int i = 4; i >= 0; i--) begin
                if (!entry[i].busy && entry[i].fu == ALU) begin
		   allocate = 1; 
		   rs_tag = i;
		end
	    end	    
	end
        endcase
    end
    
    // Clearing mechanism on reset, preserving the FU content
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 5; i++) begin
                entry[i].t1 <= '0;
                entry[i].t2 <= '0;
                entry[i].v1 <= '0;
                entry[i].v2 <= '0;
                entry[i].r <= '0;
                entry[i].opcode <= '0;
                entry[i].valid <= '0;
                entry[i].busy <= '0;
                entry[i].id_packet <= '0;
            end
        end else begin 
		entry[rs_tag].r <= id_packet.dest_reg_idx;
		entry[rs_tag].v1 <= id_packet.rs1_value;
		entry[rs_tag].v2 <= id_packet.rs2_value;
		entry[rs_tag].id_packet <= rs_packet;
		entry[rs_tag].busy <= 1'b1;
	end
    end
    
endmodule
