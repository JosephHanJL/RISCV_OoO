/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  vtuber_test.sv                                      //
//                                                                     //
//  Description :  Visual Debugger for project 4                       //
//                 Outputs only IF part                                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


`include "verilog/sys_defs.svh"

extern void initcurses(int,int,int,int,int,int,int,int,int,int);
extern void flushpipe();
extern void waitforresponse();
extern void initmem();
extern int get_instr_at_pc(int);
extern int not_valid_pc(int);

module testbench;
    string program_memory_file;

    // Registers and wires used in the testbench
    logic        clock;
    logic        reset;
    logic [31:0] clock_count;
    logic [31:0] instr_count;
    int          wb_fileno;
    logic [63:0] debug_counter; // counter used for when pipeline infinite loops, forces termination

    logic [1:0]       proc2mem_command;
    logic [`XLEN-1:0] proc2mem_addr;
    logic [63:0]      proc2mem_data;
    logic [3:0]       mem2proc_response;
    logic [63:0]      mem2proc_data;
    logic [3:0]       mem2proc_tag;
`ifndef CACHE_MODE
    MEM_SIZE          proc2mem_size;
`endif

    logic [3:0]            pipeline_completed_insts;
    EXCEPTION_CODE         pipeline_error_status;
    logic [4:0]            pipeline_commit_wr_idx;
    logic [`XLEN-1:0]      pipeline_commit_wr_data;
    logic                   pipeline_commit_wr_en;
    logic [`XLEN-1:0]      pipeline_commit_NPC;
    logic [`XLEN-1:0]      if_NPC_dbg;
    logic [31:0]           if_inst_dbg;
    logic                   if_valid_dbg;
    logic [`XLEN-1:0]      ex_mem_NPC_dbg;
    logic [31:0]           ex_mem_inst_dbg;
    logic                   ex_mem_valid_dbg;
    logic [`XLEN-1:0]      mem_wb_NPC_dbg;
    logic [31:0]           mem_wb_inst_dbg;
    logic                   mem_wb_valid_dbg;
    MAP_PACKET [31:0]      m_table_dbg;
    logic [`NUM_FU:0]      dones_dbg;
    logic [`NUM_FU:0]      ack_dbg;
    CDB_PACKET             cdb_packet_dbg;
    CDB_EX_PACKET          cdb_ex_packet_dbg;
    MAP_RS_PACKET          map_rs_packet_dbg;
    MAP_ROB_PACKET         map_rob_packet_dbg;
    EX_CDB_PACKET          ex_cdb_packet_dbg;
    DP_PACKET              dp_packet_dbg;
    logic                  dp_packet_req_dbg;
    RS_DP_PACKET           avail_vec_dbg;
    RS_EX_PACKET           rs_ex_packet_dbg;
    ROB_RS_PACKET          rob_rs_packet_dbg;
    ROB_MAP_PACKET         rob_map_packet_dbg;
    logic                  rob_dp_available_dbg;
    ROB_RT_PACKET          rob_rt_packet_dbg;
    logic                  dispatch_valid_dbg;
    logic [`XLEN-1:0]      id_ex_inst_dbg;
    RT_DP_PACKET           rt_dp_packet_dbg;
    IB_DP_PACKET           ib_dp_packet_dbg;
    IF_IB_PACKET           if_ib_packet_dbg;
    logic                  ib_full_dbg;
    logic                  ib_empty_dbg;
    logic                  squash_dbg;

    pipeline pipeline_inst (
        .clock(clock),
        .reset(reset),
        .mem2proc_response(mem2proc_response),
        .mem2proc_data(mem2proc_data),
        .mem2proc_tag(mem2proc_tag),
        .proc2mem_command(proc2mem_command),
        .proc2mem_addr(proc2mem_addr),
        .proc2mem_data(proc2mem_data),
    `ifndef CACHE_MODE
        .proc2mem_size(proc2mem_size),
    `endif
        .pipeline_completed_insts(pipeline_completed_insts),
        .pipeline_error_status(pipeline_error_status),
        .pipeline_commit_wr_idx(pipeline_commit_wr_idx),
        .pipeline_commit_wr_data(pipeline_commit_wr_data),
        .pipeline_commit_wr_en(pipeline_commit_wr_en),
        .pipeline_commit_NPC(pipeline_commit_NPC),
        .if_NPC_dbg(if_NPC_dbg),
        .if_inst_dbg(if_inst_dbg),
        .if_valid_dbg(if_valid_dbg),
        .ex_mem_NPC_dbg(ex_mem_NPC_dbg),
        .ex_mem_inst_dbg(ex_mem_inst_dbg),
        .ex_mem_valid_dbg(ex_mem_valid_dbg),
        .mem_wb_NPC_dbg(mem_wb_NPC_dbg),
        .mem_wb_inst_dbg(mem_wb_inst_dbg),
        .mem_wb_valid_dbg(mem_wb_valid_dbg),
        .m_table_dbg(m_table_dbg),
        .dones_dbg(dones_dbg),
        .ack_dbg(ack_dbg),
        .cdb_packet_dbg(cdb_packet_dbg),
        .cdb_ex_packet_dbg(cdb_ex_packet_dbg),
        .map_rs_packet_dbg(map_rs_packet_dbg),
        .map_rob_packet_dbg(map_rob_packet_dbg),
        .ex_cdb_packet_dbg(ex_cdb_packet_dbg),
        .dp_packet_dbg(dp_packet_dbg),
        .dp_packet_req_dbg(dp_packet_req_dbg),
        .avail_vec_dbg(avail_vec_dbg),
        .rs_ex_packet_dbg(rs_ex_packet_dbg),
        .rob_rs_packet_dbg(rob_rs_packet_dbg),
        .rob_map_packet_dbg(rob_map_packet_dbg),
        .rob_dp_available_dbg(rob_dp_available_dbg),
        .rob_rt_packet_dbg(rob_rt_packet_dbg),
        .dispatch_valid_dbg(dispatch_valid_dbg),
        .id_ex_inst_dbg(id_ex_inst_dbg),
        .rt_dp_packet_dbg(rt_dp_packet_dbg),
        .ib_dp_packet_dbg(ib_dp_packet_dbg),
        .if_ib_packet_dbg(if_ib_packet_dbg),
        .ib_full_dbg(ib_full_dbg),
        .ib_empty_dbg(ib_empty_dbg),
        .squash_dbg(squash_dbg)
    );


    initial begin
        clock = 0;
        reset = 0;
        // Initialization related to IF stage
        initcurses(
            5,  // IF
            0,  // IF/ID - No signals
            0,  // ID - No signals
            0,  // ID/EX - No signals
            0,  // EX - No signals
            0,  // EX/MEM - No signals
            0,  // MEM - No signals
            0,  // MEM/WB - No signals
            0,  // WB - No signals
            0   // Miscellaneous - No signals
        );
        // Other initialization steps
    end

    always @(posedge clock) begin
        // Counting logic
    end

    always @(negedge clock) begin
        // Halting conditions
    end

    always @(clock) begin
        // Dumping signals only for IF stage
    end

endmodule // module testbench
