module load_fu (
    input clock, 
    input reset,
    input ack,
    input squash,
    input [`XLEN-1:0]   Dmem2proc_data,
    input FU_IN_PACKET fu_in_packet,

    input RS_EX_PACKET rs_ex_load_packet;
    output EX_LSQ_PACKET ex_lsp_load_packet;
    output FU_EX_PACKET fu_out_packet;
); 

    EX_LSQ_PACKET ex_lsp_load_packet_local;
    logic fu_done;


    // Pass-throughs
	assign ex_lsp_load_packet_local.NPC         = rs_ex_load_packet.NPC;
	assign ex_lsp_load_packet_local.inst        = rs_ex_load_packet.inst;
	assign ex_lsp_load_packet_local.rs2_value   = rs_ex_load_packet.rs2_value;
	assign ex_lsp_load_packet_local.rd_mem      = rs_ex_load_packet.rd_mem;
	assign ex_lsp_load_packet_local.wr_mem      = rs_ex_load_packet.wr_mem;
	assign ex_lsp_load_packet_local.dest_reg_idx= rs_ex_load_packet.dest_reg_idx;
	assign ex_lsp_load_packet_local.halt        = rs_ex_load_packet.halt;
	assign ex_lsp_load_packet_local.illegal     = rs_ex_load_packet.illegal;
	assign ex_lsp_load_packet_local.valid       = rs_ex_load_packet.valid;
	assign ex_lsp_load_packet_local.csr_op      = rs_ex_load_packet.csr_op;
	assign ex_lsp_load_packet_local.mem_size    = rs_ex_load_packet.inst.r.funct3;
    assign ex_lsp_load_packet_local.sq_pos      = rs_ex_load_packet.tail_pos; // what is this?
    assign ex_lsp_load_packet_local.tag         = rs_ex_load_packet.tag; //ROB#

    logic [`XLEN-1:0] opb_mux_ld_out;

	 //
	 // ALU opB mux
	 //
	always_comb begin
		// Default value, Set only because the case isnt full.  If you see this
		// value on the output of the mux you have an invalid opb_select
		opb_mux_ld_out = `XLEN'hfacefeed;
		case (is_ex_ld_packet_in.opb_select)
			OPB_IS_I_IMM: opb_mux_ld_out = `RV32_signext_Iimm(rs_ex_load_packet.inst); // load
			OPB_IS_S_IMM: opb_mux_ld_out = `RV32_signext_Simm(rs_ex_load_packet.inst); // store
		endcase 
	end

	assign ex_lsp_load_packet_local.alu_result = rs_ex_load_packet.rs1_value + opb_mux_ld_out; 
    assign ex_lsp_load_packet = ex_lsp_load_packet_local;

    assign fu_out_packet.done = fu_done;
    assign fu_out_packet.v = Dmem2proc_data;
    assign fu_out_packet.rob_tag = fu_in_packet.tag;

    always_ff @(posedge clock) begin
        if (reset) begin
            fu_done <= 0;
        end 
        else begin
            if (ack) fu_done <= 0;
            else fu_done <= 1;
        end
    end

endmodule
