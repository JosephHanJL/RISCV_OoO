module retire (
    input   ROB_RT_PACKET    rob_rt_packet,

    output logic             wb_regfile_en,  // register write enable
    output logic [4:0]       wb_regfile_idx, // register write index
    output logic [`XLEN-1:0] wb_regfile_data // register write data
);

    // This enable computation is sort of overkill since the reg file
    // also handles the `ZERO_REG case, but there's no harm in putting this here
    // the valid check is also somewhat redundant
    assign wb_regfile_en = (rob_rt_packet.data_retired.r != `ZERO_REG);

    assign wb_regfile_idx = rob_rt_packet.data_retired.r;

    // Select register writeback data:
    // ALU/MEM result, unless taken branch, in which case we write
    // back the old NPC as the return address. Note that ALL branches
    // and jumps write back the 'link' value, but those that don't
    // use it specify ZERO_REG as the destination.
    // assign wb_regfile_data = (rob_rt_packet.take_branch)? rob_rt_packet.NPC : rob_rt_packet.data_retired.V; 
    assign wb_regfile_data = rob_rt_packet.data_retired.V;
endmodule // stage_wb