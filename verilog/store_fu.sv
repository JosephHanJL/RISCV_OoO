module store_fu (
    input clock, 
    input reset,
    input squash,
    input RS_EX_PACKET rs_ex_store_packet;
    output EX_LSQ_PACKET ex_lsp_store_packet;
); 

    EX_LSQ_PACKET ex_lsp_store_packet_local;

    // Pass-throughs
	assign ex_lsp_store_packet_local.NPC         = rs_ex_store_packet.NPC;
	assign ex_lsp_store_packet_local.inst        = rs_ex_store_packet.inst;
	assign ex_lsp_store_packet_local.rs2_value   = rs_ex_store_packet.rs2_value;
	assign ex_lsp_store_packet_local.rd_mem      = rs_ex_store_packet.rd_mem;
	assign ex_lsp_store_packet_local.wr_mem      = rs_ex_store_packet.wr_mem;
	assign ex_lsp_store_packet_local.dest_reg_idx= rs_ex_store_packet.dest_reg_idx;
	assign ex_lsp_store_packet_local.halt        = rs_ex_store_packet.halt;
	assign ex_lsp_store_packet_local.illegal     = rs_ex_store_packet.illegal;
	assign ex_lsp_store_packet_local.valid       = rs_ex_store_packet.valid;
	assign ex_lsp_store_packet_local.csr_op      = rs_ex_store_packet.csr_op;
	assign ex_lsp_store_packet_local.mem_size    = rs_ex_store_packet.inst.r.funct3;
    assign ex_lsp_store_packet_local.sq_pos      = rs_ex_store_packet.tail_pos; // what is this?
    assign ex_lsp_store_packet_local.tag         = rs_ex_store_packet.tag; //ROB#

    logic [`XLEN-1:0] opb_mux_st_out;

	 //
	 // ALU opB mux
	 //
	always_comb begin
		// Default value, Set only because the case isnt full.  If you see this
		// value on the output of the mux you have an invalid opb_select
		opb_mux_st_out = `XLEN'hfacefeed;
		case (is_ex_st_packet_in.opb_select)
			OPB_IS_I_IMM: opb_mux_st_out = `RV32_signext_Iimm(rs_ex_store_packet.inst); // load
			OPB_IS_S_IMM: opb_mux_st_out = `RV32_signext_Simm(rs_ex_store_packet.inst); // store
		endcase 
	end

	assign ex_lsp_load_packet_local.alu_result = rs_ex_store_packet.rs1_value + opb_mux_st_out; 
    assign ex_lsp_store_packet = ex_lsp_store_packet_local;

endmodule
