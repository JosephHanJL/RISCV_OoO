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
    input RT_DP_PACKET [1:0] rt_dp_packet,
    input IB_DP_PACKET [1:0] ib_dp_packet,
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
        .read_idx_1({ib_dp_packet[1].inst.r.rs1, ib_dp_packet[0].inst.r.rs1}),
        .read_idx_2({ib_dp_packet[1].inst.r.rs2, ib_dp_packet[0].inst.r.rs2}),
        .write_en({rt_dp_packet[1].valid, rt_dp_packet[0].valid}),
        .write_idx({rt_dp_packet[1].data_retired.r, rt_dp_packet[0].data_retired.r}),
        .write_data({rt_dp_packet[1].data_retired.V, rt_dp_packet[0].data_retired.V}),

        .read_out_1({dp_packet[1].rs1_value, dp_packet[0].rs1_value}),
        .read_out_2({dp_packet[1].rs2_value, dp_packet[0].rs2_value})
    );

    generate
		genvar i;
		for (i = 0; i < 2; i++) begin : gen_loop
			assign dp_packet[i].inst  = ib_dp_packet[i].inst;
			assign dp_packet[i].NPC   = ib_dp_packet[i].NPC;
			assign dp_packet[i].PC    = ib_dp_packet[i].PC;
            assign dp_packet[i].rs1_idx = ib_dp_packet[i].inst.r.rs1;
            assign dp_packet[i].rs2_idx = ib_dp_packet[i].inst.r.rs2;
			assign dp_packet[i].dp_en = ib_dp_packet[i].valid; //???
			decoder decoder (
				// input
				.if_packet(ib_dp_packet[i]),
				// outputs
				.opa_select(dp_packet[i].opa_select),
				.opb_select(dp_packet[i].opb_select),
				.has_dest(has_dest[i]), 
				.alu_func(dp_packet[i].alu_func),
				.rd_mem(dp_packet[i].rd_mem),
				.wr_mem(dp_packet[i].wr_mem),
				.cond_branch(dp_packet[i].cond_branch),
				.uncond_branch(dp_packet[i].uncond_branch),
				.csr_op(dp_packet[i].csr_op),
				.halt(dp_packet[i].halt),
				.illegal(dp_packet[i].illegal),
				.valid_inst_out(dp_packet[i].valid),
				.has_rs1(dp_packet[i].rs1_valid),
				.has_rs2(dp_packet[i].rs2_valid),
				.fu_sel(dp_packet[i].fu_sel)
			);
		end
	endgenerate

    always_comb begin
		for (int j = 0; j < 2; j++) begin
            dp_packet[j].has_dest = has_dest[j] ? `TRUE : `FALSE;
			case (has_dest[j])
				`TRUE:    dp_packet[j].dest_reg_idx = ib_dp_packet[j].inst.r.rd;
				`FALSE:   dp_packet[j].dest_reg_idx = `ZERO_REG;
				default:  dp_packet[j].dest_reg_idx = `ZERO_REG; 
			endcase
		end
	end
   
endmodule // module stage_dp

