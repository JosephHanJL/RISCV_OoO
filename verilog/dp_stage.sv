/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename :  stage_dp.sv                                          //
//  Version: 1.0                                                       //
//  Description :  dispatch stage of the module                        //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

module stage_dp(
    input clock,
    input reset, 
    input ROB_RT_PACKET [1:0] rt_packet,
    input IF_DP_PACKET [1:0] if_dp_packet,
    input logic [1:0] rob_spaces,
    input logic [1:0] rs_spaces,
    input logic [1:0] lsq_spaces,

    output DP_PACKET [1:0] dp_packet,
    output logic [1:0] dp_packet_req
);

    logic [1:0] has_dest;
    logic [1:0][4:0] rs1_idx, rs2_idx;

    always_comb begin
        // dp_packet_req = (rob_spaces <= rs_spaces) ? rob_spaces : rs_spaces;
        // if (lsq_spaces < dp_packet_req) begin
        //     dp_packet_req = lsq_spaces;
        // end
        dp_packet_req = 2'b01;
    end

    regfile regfile(
        .clock(clock),
        .read_idx_1({if_dp_packet[1].inst.r.rs1, if_dp_packet[0].inst.r.rs1}),
        .read_idx_2({if_dp_packet[1].inst.r.rs2, if_dp_packet[0].inst.r.rs2}),
        .write_en({rt_packet[1].valid, rt_packet[0].valid}),
        .write_idx({rt_packet[1].retire_reg, rt_packet[0].retire_reg}),
        .write_data({rt_packet[1].value, rt_packet[2].value}),

        .read_out_1({dp_packet[1].rs1_value, dp_packet[0].rs1_value}),
        .read_out_2({dp_packet[1].rs2_value, dp_packet[0].rs2_value})
    );

    generate
		genvar i;
		for (i = 0; i < 2; i++) begin
			assign dp_packet[i].inst  = if_dp_packet[i].inst;
			assign dp_packet[i].NPC   = if_dp_packet[i].NPC;
			assign dp_packet[i].PC    = if_dp_packet[i].PC;
            assign dp_packet[i].rs1_idx = if_dp_packet[i].inst;
            assign dp_packet[i].rs2_idx = if_dp_packet[i].inst.r.rs2;
			assign dp_packet[i].dp_en = dp_packet[i].valid; //???
			decoder decoder (
				// input
				.if_packet(if_dp_packet[i]),
				// outputs
				.opa_select(dp_packet[i].opa_select),
				.opb_select(dp_packet[i].opb_select),
				.dest_reg(has_dest[i]), 
				.alu_func(dp_packet_out[i].alu_func),
				.rd_mem(dp_packet[i].rd_mem),
				.wr_mem(dp_packet[i].wr_mem),
				.cond_branch(dp_packet[i].cond_branch),
				.uncond_branch(dp_packet[i].uncond_branch),
				.csr_op(dp_packet[i].csr_op),
				.halt(dp_packet[i].halt),
				.illegal(dp_packet[i].illegal),
				.valid_inst(dp_packet[i].valid),
				.has_rs1(dp_packet[i].has_rs1),
				.has_rs2(dp_packet[i].has_rs2),
				.fu_sel(dp_packet[i].fu_sel)
			);
            case (dp_packet[i].opa_select)
                OPA_IS_RS1: begin
                    rs1_idx[i] = instruction.r.rs1;
                end
                OPA_IS_NPC: begin
                    rs1_idx[i] = `ZERO_REG;
                end
                OPA_IS_PC: begin
                    rs1_idx[i] = instruction.s.rs1; 
                    rs2_idx[i] = instruction.s.rs2; 
                end
                OPCODE_B_TYPE: begin
                    rs1_idx[i] = instruction.s.rs1; 
                    rs2_idx[i] = instruction.s.rs2; 
                default: begin
                    rs1_idx[i] = `ZERO_REG;
                    rs2_idx[i] = `ZERO_REG;
                end
            endcase
            assign dp_packet[i].rs1_idx = rs1_idx[i];
            assign dp_packet[i].rs2_idx = rs2_idx[i];
		end
	endgenerate

    always_comb begin
		for (int j = 0; j < `2; j++) begin
            dp_packet[j].has_dest = has_dest[j] ? `TRUE : `FALSE;
			case (has_dest[j])
				`TRUE:    dp_packet[j].dest_reg_idx = if_dp_packet[j].inst.r.rd;
				`FALSE:   dp_packet[j].dest_reg_idx = `ZERO_REG;
				default:  dp_packet[j].dest_reg_idx = `ZERO_REG; 
			endcase
		end
	end
   
endmodule // module stage_dp

