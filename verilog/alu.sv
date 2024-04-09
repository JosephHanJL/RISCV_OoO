`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

// ALU: computes the result of FUNC applied with operands A and B
// This module is purely combinational
module alu (
    input [`XLEN-1:0] opa,
    input [`XLEN-1:0] opb,
    ALU_FUNC          func,

    output logic [`XLEN-1:0] result
);

    logic signed [`XLEN-1:0]   signed_opa, signed_opb;
    // logic signed [2*`XLEN-1:0] signed_mul, mixed_mul;
    // logic        [2*`XLEN-1:0] unsigned_mul;

    assign signed_opa   = opa;
    assign signed_opb   = opb;

    // We let verilog do the full 32-bit multiplication for us.
    // This gives a large clock period.
    // You will replace this with your pipelined multiplier in project 4.
    // assign signed_mul   = signed_opa * signed_opb;
    // assign unsigned_mul = opa * opb;
    // assign mixed_mul    = signed_opa * opb;

    always_comb begin
        case (func)
            ALU_ADD:    result = opa + opb;
            ALU_SUB:    result = opa - opb;
            ALU_AND:    result = opa & opb;
            ALU_SLT:    result = signed_opa < signed_opb;
            ALU_SLTU:   result = opa < opb;
            ALU_OR:     result = opa | opb;
            ALU_XOR:    result = opa ^ opb;
            ALU_SRL:    result = opa >> opb[4:0];
            ALU_SLL:    result = opa << opb[4:0];
            ALU_SRA:    result = signed_opa >>> opb[4:0]; // arithmetic from logical shift
            // ALU_MUL:    result = signed_mul[`XLEN-1:0];
            // ALU_MULH:   result = signed_mul[2*`XLEN-1:`XLEN];
            // ALU_MULHSU: result = mixed_mul[2*`XLEN-1:`XLEN];
            // ALU_MULHU:  result = unsigned_mul[2*`XLEN-1:`XLEN];

            default:    result = `XLEN'hfacebeec;  // here to prevent latches
        endcase
    end

endmodule // alu

module conditional_branch (
    input [2:0]       func, // Specifies which condition to check
    input [`XLEN-1:0] rs1,  // Value to check against condition
    input [`XLEN-1:0] rs2,

    output logic take // True/False condition result
);

    logic signed [`XLEN-1:0] signed_rs1, signed_rs2;
    assign signed_rs1 = rs1;
    assign signed_rs2 = rs2;
    always_comb begin
        case (func)
            3'b000:  take = signed_rs1 == signed_rs2; // BEQ
            3'b001:  take = signed_rs1 != signed_rs2; // BNE
            3'b100:  take = signed_rs1 < signed_rs2;  // BLT
            3'b101:  take = signed_rs1 >= signed_rs2; // BGE
            3'b110:  take = rs1 < rs2;                // BLTU
            3'b111:  take = rs1 >= rs2;               // BGEU
            default: take = `FALSE;
        endcase
    end

endmodule // conditional_branch

module alu_fu (
    input clock,
    input reset,
    input enable,
    input squash,
    input RS_EX_PACKET rs_ex_packet,

    output EX_BP_PCKET ex_bp_packet,
    output EX_CP_PCKET ex_cp_packet,
);

    EX_CP_PACKET ex_cp_packet_local;
    EX_BP_PACKET ex_bp_packet_local;
    
    logic [`XLEN-1:0] opa_mux_out, opb_mux_out;
    logic             take_conditional;
    logic [`XLEN-1:0] alu_result;

    // Pass-throughs
    assign ex_cp_packet_local.inst         = rs_ex_packet.inst;
    assign ex_cp_packet_local.dest_reg_idx = rs_ex_packet.dest_reg_idx;
    assign ex_cp_packet_local.halt         = rs_ex_packet.halt;
    assign ex_cp_packet_local.illegal      = rs_ex_packet.illegal;
    assign ex_cp_packet_local.valid        = rs_ex_packet.valid; // still need a done signal
    assign ex_cp_packet_local.tag          = rs_ex_packet.tag;

    // Break out the signed/unsigned bit and memory read/write size
    // assign ex_packet.rd_unsigned  = id_ex_reg.inst.r.funct3[2]; // 1 if unsigned, 0 if signed
    // assign ex_packet.mem_size     = MEM_SIZE'(id_ex_reg.inst.r.funct3[1:0]);

    // ultimate "take branch" signal:
    // unconditional, or conditional and the condition is true
    assign ex_cp_packet_local.take_branch = ex_cp_packet_local.uncond_branch || (id_ex_reg.cond_branch && take_conditional); // havent finished writing

    // ALU opA mux
    always_comb begin
        case (rs_ex_packet.opa_select)
            OPA_IS_RS1:  opa_mux_out = rs_ex_packet.rs1_value;
            OPA_IS_NPC:  opa_mux_out = rs_ex_packet.NPC;
            OPA_IS_PC:   opa_mux_out = rs_ex_packet.PC;
            OPA_IS_ZERO: opa_mux_out = 0;
            default:     opa_mux_out = `XLEN'hdeadface; // dead face
        endcase
    end

    // ALU opB mux
    always_comb begin
        case (rs_ex_packet.opb_select)
            OPB_IS_RS2:   opb_mux_out = rs_ex_packet.rs2_value;
            OPB_IS_I_IMM: opb_mux_out = `RV32_signext_Iimm(rs_ex_packet.inst);
            OPB_IS_S_IMM: opb_mux_out = `RV32_signext_Simm(rs_ex_packet.inst);
            OPB_IS_B_IMM: opb_mux_out = `RV32_signext_Bimm(rs_ex_packet.inst);
            OPB_IS_U_IMM: opb_mux_out = `RV32_signext_Uimm(rs_ex_packet.inst);
            OPB_IS_J_IMM: opb_mux_out = `RV32_signext_Jimm(rs_ex_packet.inst);
            default:      opb_mux_out = `XLEN'hfacefeed; // face feed
        endcase
    end

    // Instantiate the ALU
    alu alu_0 (
        // Inputs
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .func(rs_ex_packet.alu_func),

        // Output
        .result(alu_result)
    );

    // Instantiate the conditional branch module
    conditional_branch conditional_branch_0 (
        // Inputs
        .func(rs_ex_packet.inst.b.funct3), // instruction bits for which condition to check
        .rs1(id_ex_reg.rs1_value),
        .rs2(id_ex_reg.rs2_value),

        // Output
        .take(take_conditional)
    );

    always_ff @(posedge clock) begin
		if (reset)begin
			ex_cp_packet.Value <= `SD 0;
			ex_cp_packet.NPC <= `SD 0;
			ex_cp_packet.take_branch <= `SD 0;
			ex_cp_packet.inst <= `SD `NOP;
			ex_cp_packet.dest_reg_idx <= `SD `ZERO_REG;
			ex_cp_packet.halt <= `SD `FALSE;
			ex_cp_packet.illegal <= `SD `FALSE;
			ex_cp_packet.valid <= `SD 0;
			ex_cp_packet.done <= `SD 0; // done still here
			ex_cp_packet.Tag <= `SD 0;
		end
		else if (squash_in) begin
			ex_cp_packet.Value <= `SD 0;
			ex_cp_packet.NPC <= `SD 0;
			ex_cp_packet.take_branch <= `SD 0;
			ex_cp_packet.inst <= `SD `NOP;
			ex_cp_packet.dest_reg_idx <= `SD `ZERO_REG;
			ex_cp_packet.halt <= `SD `FALSE;
			ex_cp_packet.illegal <= `SD `FALSE;
			ex_cp_packet.valid <= `SD 0;
			ex_cp_packet.done <= `SD 0; // done still here
			ex_cp_packet.Tag <= `SD 0;
		end
		else if (enable) begin
			ex_cp_packet <= ex_cp_packet_local;
		end
	end

	// synopsys sync_set_reset "reset"
	always_ff @(posedge clock) begin
		if (reset) begin
			ex_bp_packet <= `SD 0;
		end
		else if (squash_in) begin
			ex_bp_packet <= `SD 0;
		end
		else if (enable) begin
			ex_bp_packet <= ex_bp_packet_local;
		end
		else begin
			ex_bp_packet <= `SD 0;
		end
	end

endmodule // stage_ex