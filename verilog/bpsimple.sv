module bpsimple (
    input clock,
    input reset, 
    input IF_IB_PACKET if_ib_packet,

    output logic [`XLEN-1:0] bp_pc,
    output logic [`XLEN-1:0] bp_npc,
    output logic bp_taken
);
// Assuming 32-bit instructions and PC. Adjust sizes as necessary.

    logic cond_branch, uncond_branch, jump, link;
    logic [6:0] branch_imm1;
    logic [4:0] branch_imm2;
    logic [`XLEN-1:0] branch_loc;
    logic [11:0] full_imm = {branch_imm1, branch_imm2};

    assign bp_pc = ((cond_branch || uncond_branch) && !link)? branch_loc : if_ib_packet.NPC;
    assign bp_npc = ((cond_branch || uncond_branch) && !link)? branch_loc : if_ib_packet.NPC;
    assign bp_taken = ((cond_branch || uncond_branch) && !link)? 1 : 0; 
    assign branch_loc = if_ib_packet.PC + {{20{full_imm[11]}}, full_imm};  
    

    pre_decode pre_decode_0(
        .inst(if_ib_packet.inst),
        .valid(if_ib_packet.valid),
        .cond_branch(cond_branch),
        .uncond_branch(uncond_branch),
	.branch_imm1(branch_imm1),
	.branch_imm2(branch_imm2),
        .jump(jump),
        .link(link)
    );

endmodule
