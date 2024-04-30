module BP (
    input clock,
    input reset, 
    input [`XLEN-1:0] if_pc,
    input INST inst,
    input EX_BP_PACKET ex_bp_packet, 
    input valid,

    output logic [`XLEN-1:0] bp_pc,
    output logic [`XLEN-1:0] bp_npc,
    output logic bp_taken
);

    logic [2:0] bht_if_out;
    logic [2:0] bht_ex_out;
    logic [`XLEN-1:0] link_pc;
    logic predict_taken;

    logic hit;
    logic [`XLEN-1:0] predict_pc_out;
    logic [`XLEN-1:0] return_addr;

    logic cond_branch;
    logic uncond_branch;

    logic jump;
    logic link;

    pre_decode pre_decode_0(
        .inst(inst),
        .valid(valid),
        .cond_branch(cond_branch),
        .uncond_branch(uncond_branch),
        .jump(jump),
        .link(link)
    );

    BHT bht_0(
        .clock(clock),
        .reset(reset),
        .wr_en(ex_bp_packet.con_br_en),
        .ex_pc(ex_bp_packet.PC),
        .take_branch(ex_bp_packet.con_br_taken),
        .if_pc(if_pc),

        .bht_if_out(bht_if_out),
        .bht_ex_out(bht_ex_out)
    );

    PHT pht_0(
        .clock(clock),
        .reset(reset),
        .wr_en(ex_bp_packet.con_br_en),
        .ex_pc(ex_bp_packet.PC),
        .take_branch(ex_bp_packet.con_br_taken),
        .if_pc(if_pc),
        .bht_if_in(bht_if_out),
        .bht_ex_in(bht_ex_out),
        .predict_taken(predict_taken)
    );

    BTB btb_0(
        .clock(clock),
        .reset(reset),
        .wr_en(ex_bp_packet.con_br_en),
        .ex_pc(ex_bp_packet.PC),
        .ex_tg_pc(ex_bp_packet.tg_pc), 
        .if_pc(if_pc),
        .hit(hit),
        .predict_pc_out(predict_pc_out)
    );

    RAS ras_0(
        .clock(clock),
        .reset(reset),
        .jal(jump),
        .jalr(link),
        .link_pc(link_pc),
        .return_addr(return_addr)
    );

    always_comb begin
        if (link) begin
            bp_npc = return_addr + 4;
            bp_pc = return_addr;
        end else if (jump && hit) begin
            bp_npc = predict_pc_out + 4;
            bp_pc = predict_pc_out;
        end else if (cond_branch && predict_taken && hit) begin
            bp_npc = predict_pc_out + 4;
            bp_pc = predict_pc_out;
        end else begin
            bp_npc = if_pc + 8; // Increment PC by 4 for non-branch instructions
            bp_pc = if_pc + 4;
        end
        bp_taken = (jump && hit) || (cond_branch && predict_taken && hit);
    end

endmodule


