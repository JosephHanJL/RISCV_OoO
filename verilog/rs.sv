`include "sys_defs.svh"
`include "ISA.svh"

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
    // from stage_dp
    input DP_PACKET dp_packet,

    // from CDB
    input CDB_PACKET cdb_packet,

    // from ROB
    input ROB_RS_PACKET rob_packet,
    // from map table, whether rs_T1/2 is empty or a specific #ROB
    input MAP_RS_PACKET map_packet,

    // from reorder buffer, the entire reorder buffer and the tail indicating
    // the instruction being dispatched. 
    // to map table and ROB
    output dispatch_valid,
    output RS_DP_PACKET avail_vec, 

    // TODO: this part tentatively goes to the execution stage. In milestone 2, Expand this part so that it goes to separate functional units
    output RS_FU_PACKET rs_fu_packet,
    `INTERFACE_PORT
);

    // Define and initialize the entry packets array
    RS_ENTRY entry [5:0];
    logic allocate, free;
    RS_TAG allocate_tag;
    logic [`NUM_RS:0] free_tag;
    logic [$clog2(`NUM_RS)-1:0] empty, empty_count; // Empty is sequential, empty_count is combinational
    assign dispatch_valid = allocate;

    
    // Initialize FU types for each entry packet instance
    
    assign entry[1].fu = ALU;
    assign entry[2].fu = Load;
    assign entry[3].fu = Store;
    assign entry[4].fu = FloatingPoint;
    assign entry[5].fu = FloatingPoint;
   

    always_comb begin
	    `ifdef TESTBENCH
	    foreach (if_rs.entry[i]) begin
                if_rs.entry[i] = entry[i];
            end
            `endif
    end

    // Free Entry Logic: Need to free multiple entries
    always_comb begin
        free = 0;
        free_tag = '0;
        for (int i = 5; i >= 1; i--) begin
            if (entry[i].r == cdb_packet.rob_tag) begin
		free = 1;
                free_tag[i] = 1;
            end
        end
    end

    // Allocate Logic
    always_comb begin
	allocate = 0;
	allocate_tag = 7; // Don't have 7 reservation station entries, so reserve 7 for invalid address
	case (dp_packet.fu_sel)
        Load: begin // Load
            for (int i = 5; i >= 1; i--) begin
                if ((!entry[i].busy || free_tag[i]) && entry[i].fu == Load) begin
		            allocate = 1;
		            allocate_tag = i;
		        end
	    end	    
        end
        Store: begin // Store
            for (int i = 5; i >= 1; i--) begin
                if ((!entry[i].busy || free_tag[i]) && entry[i].fu == Store) begin
                    allocate = 1; 
                    allocate_tag = i;
                end
	    end	    
	end
        FloatingPoint: begin // Floating Point
            for (int i = 5; i >= 1; i--) begin
                if ((!entry[i].busy || free_tag[i]) && entry[i].fu == FloatingPoint) begin
                    allocate = 1;
                    allocate_tag = i; 
		        end
	    end	    
	end
	default: begin
            for (int i = 5; i >= 1; i--) begin
                if ((!entry[i].busy || free_tag[i]) && entry[i].fu == ALU) begin
                    allocate = 1; 
                    allocate_tag = i;
		end
	    end	    
	end
        endcase
    end

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
                entry[i].dp_packet <= '0;
            end
        end else begin 
        if (free) begin
	    for (int i = 1; i <= 5; i++) begin
	        if (free_tag[i]) begin
		    entry[i].t1 <= '0;
		    entry[i].t2 <= '0;
		    entry[i].v1 <= '0;
		    entry[i].v2 <= '0;
		    entry[i].v1_valid <= 0;
		    entry[i].v2_valid <= 0;
		    entry[i].r <= '0;
		    entry[i].opcode <= 0;
		    entry[i].valid <= 0;
		    entry[i].busy <= 0; 
		    entry[i].issued <= 0;
		    entry[i].dp_packet <= '0;
	        end
            end
        end // freed and allocated on the same clock cycle
        if (allocate) begin 
            entry[allocate_tag].t1 <= map_packet.map_packet_a.rob_tag;
            entry[allocate_tag].t2 <= map_packet.map_packet_b.rob_tag;
            entry[allocate_tag].v1 <= (map_packet.map_packet_a.t_plus) ? rob_packet.rob_dep_a.V: 
		                      (map_packet.map_packet_a.rob_tag == cdb_packet.rob_tag) ? cdb_packet.v:
				      (map_packet.map_packet_a.rob_tag == `ZERO_REG) ? dp_packet.rs1_value : '0; // TODO: the logic for this part is not correct, be very careful how this part is handled
            entry[allocate_tag].v2 <= (map_packet.map_packet_b.t_plus) ? rob_packet.rob_dep_b.V: 
		                      (map_packet.map_packet_b.rob_tag == cdb_packet.rob_tag) ? cdb_packet.v:
				      (map_packet.map_packet_b.rob_tag == `ZERO_REG) ? dp_packet.rs2_value : '0; // TODO: the logic for this part is not correct, be very careful how this part is handled
	    entry[allocate_tag].v1_valid <= (dp_packet.rs1_valid) ? (map_packet.map_packet_a.t_plus | (map_packet.map_packet_a.rob_tag == cdb_packet.rob_tag) | (map_packet.map_packet_a.rob_tag == `ZERO_REG)) : 0;
	    entry[allocate_tag].v2_valid <= (dp_packet.rs2_valid) ? (map_packet.map_packet_b.t_plus | (map_packet.map_packet_b.rob_tag == cdb_packet.rob_tag) | (map_packet.map_packet_b.rob_tag == `ZERO_REG)) : 0;
            entry[allocate_tag].r <= rob_packet.rob_tail.r;
	    entry[allocate_tag].opcode <= dp_packet.inst[6:0];
	    entry[allocate_tag].valid <= dp_packet.valid;
            entry[allocate_tag].busy <= dp_packet.valid; // TODO: how to handle NOP and WFI
	    entry[allocate_tag].issued <= dp_packet.valid && ((map_packet.map_packet_a.rob_tag == `ZERO_REG) | (map_packet.map_packet_a.t_plus) | (map_packet.map_packet_a.rob_tag == cdb_packet.rob_tag)) && ((map_packet.map_packet_b.rob_tag == `ZERO_REG) | (map_packet.map_packet_b.t_plus) | (map_packet.map_packet_a.rob_tag == cdb_packet.rob_tag)); // TODO: Check this logic
            entry[allocate_tag].dp_packet <= dp_packet;
	end
	// Update logic
        for (int i = 5; i > 0; i--) begin 
            if (entry[i].t1 == cdb_packet.rob_tag && entry[i].t1 != `ZERO_REG) begin
                entry[i].t1 <= `ZERO_REG;
                entry[i].v1 <= cdb_packet.v;
                entry[i].v1_valid <= 1;
            end
            if (entry[i].t2 == cdb_packet.rob_tag && entry[i].t2 != `ZERO_REG) begin
                entry[i].t2 <= `ZERO_REG;
                entry[i].v2 <= cdb_packet.v;
                entry[i].v2_valid <= 1;
            end
	    end
        end
    end

    always_comb begin
        empty = '0;  
        for (int i = 1; i <= 5; i++) begin
	    if (~entry[i].busy) begin
                empty += 1;
            end
        end
    end

    always_comb begin
	for (int i = 1; i <=5; i++) begin
	    rs_fu_packet[i].inst = entry[i].dp_packet.inst;
            rs_fu_packet[i].PC = entry[i].dp_packet.PC;
            rs_fu_packet[i].NPC = entry[i].dp_packet.NPC; // PC + 4
	    rs_fu_packet[i].rs1_value = entry[i].dp_packet.rs1_value;
	    rs_fu_packet[i].rs2_value = entry[i].dp_packet.rs2_value;
	    rs_fu_packet[i].rs1_idx = entry[i].dp_packet.rs1_idx;
	    rs_fu_packet[i].rs2_idx = entry[i].dp_packet.rs2_idx;
	    rs_fu_packet[i].rs1_valid = entry[i].dp_packet.rs1_valid;
	    rs_fu_packet[i].rs2_valid = entry[i].dp_packet.rs2_valid;
	    rs_fu_packet[i].opa_select = entry[i].dp_packet.opa_select;
	    rs_fu_packet[i].opb_select = entry[i].dp_packet.opb_select;
	    rs_fu_packet[i].dest_reg_idx = entry[i].dp_packet.dest_reg_idx;
	    rs_fu_packet[i].has_dest = entry[i].dp_packet.has_dest;
	    rs_fu_packet[i].alu_func = entry[i].dp_packet.alu_func;
	    rs_fu_packet[i].rd_mem = entry[i].dp_packet.rd_mem;
	    rs_fu_packet[i].wr_mem = entry[i].dp_packet.wr_mem;
	    rs_fu_packet[i].cond_branch = entry[i].dp_packet.cond_branch;
	    rs_fu_packet[i].uncond_branch = entry[i].dp_packet.uncond_branch;
	    rs_fu_packet[i].halt = entry[i].dp_packet.halt;
	    rs_fu_packet[i].illegal = entry[i].dp_packet.illegal;
	    rs_fu_packet[i].csr_op = entry[i].dp_packet.csr_op;
	    rs_fu_packet[i].valid = entry[i].dp_packet.valid;
	    rs_fu_packet[i].tag = entry[i].r;
	    rs_fu_packet[i].issue_valid = entry[i].issued;
	    rs_fu_packet[i].fu_id = i;
	end
    end

/*

    logic [4:0] rs1_idx; // reg A index
    logic [4:0] rs2_idx; // reg B index

    logic rs1_valid; // reg A used
    logic rs2_valid; // reg B used

    ALU_OPA_SELECT opa_select; // ALU opa mux select (ALU_OPA_xxx *)
    ALU_OPB_SELECT opb_select; // ALU opb mux select (ALU_OPB_xxx *)

    logic [4:0] dest_reg_idx;  // destination (writeback) register index
    logic has_dest;            // destination register is used

    ALU_FUNC    alu_func;      // ALU function select (ALU_xxx *)
    logic       rd_mem;        // Does inst read memory?
    logic       wr_mem;        // Does inst write memory?
    logic       cond_branch;   // Is inst a conditional branch?
    logic       uncond_branch; // Is inst an unconditional branch?
    logic       halt;          // Is this a halt?
    logic       illegal;       // Is this instruction illegal?
    logic       csr_op;        // Is this a CSR operation? (we use this to get return code)

    logic       valid;
    // DO NOT ADD ABOVE THIS LINE. CAN ADD BELOW

    ROB_TAG tag;
    logic issue_valid;      // goes high when RS issues instr
    logic [`RS_TAG_WIDTH-1:0] fu_id;
*/



    always_comb begin
	    for (int i = 0; i < 5; i++) begin
		avail_vec[i].fu = entry[i+1].fu;
		avail_vec[i].available = ~entry[i+1].busy;
	    end
    end
    // TODO: Add an issue valid logic 
endmodule
