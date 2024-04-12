/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  pipeline.sv                                         //
//                                                                     //
//  Description :  Top-level module of the verisimple pipeline;        //
//                 This instantiates and connects the 5 stages of the  //
//                 Verisimple pipeline together.                       //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
`include "verilog/sys_defs.svh"

module pipeline (
    input        clock,             // System clock
    input        reset,             // System reset
    input [3:0]  mem2proc_response, // Tag from memory about current request
    input [63:0] mem2proc_data,     // Data coming back from memory
    input [3:0]  mem2proc_tag,      // Tag from memory about current reply

    output logic [1:0]       proc2mem_command, // Command sent to memory
    output logic [`XLEN-1:0] proc2mem_addr,    // Address sent to memory
    output logic [63:0]      proc2mem_data,    // Data sent to memory
`ifndef CACHE_MODE // no longer sending size to memory
    output MEM_SIZE          proc2mem_size,    // Data size sent to memory
`endif

    // Note: these are assigned at the very bottom of the module
    output logic [3:0]       pipeline_completed_insts,
    output EXCEPTION_CODE    pipeline_error_status,
    output logic [4:0]       pipeline_commit_wr_idx,
    output logic [`XLEN-1:0] pipeline_commit_wr_data,
    output logic             pipeline_commit_wr_en,
    output logic [`XLEN-1:0] pipeline_commit_NPC,

    // Debug outputs: these signals are solely used for debugging in testbenches
    // Do not change for project 3
    // You should definitely change these for project 4
    output logic [`XLEN-1:0]    if_NPC_dbg,
    output logic [31:0]         if_inst_dbg,
    output logic                if_valid_dbg,
    output logic [`XLEN-1:0]    ex_mem_NPC_dbg,
    output logic [31:0]         ex_mem_inst_dbg,
    output logic                ex_mem_valid_dbg,
    output logic [`XLEN-1:0]    mem_wb_NPC_dbg,
    output logic [31:0]         mem_wb_inst_dbg,
    output logic                mem_wb_valid_dbg,
    output MAP_PACKET [31:0]    m_table_dbg,
    output logic [`NUM_FU:0]    dones_dbg,
    output logic [`NUM_FU:0]    ack_dbg,
    output CDB_PACKET           cdb_packet_dbg,
    output CDB_EX_PACKET        cdb_ex_packet_dbg,
    output MAP_RS_PACKET        map_rs_packet_dbg,
    output MAP_ROB_PACKET       map_rob_packet_dbg,
    output EX_CDB_PACKET        ex_cdb_packet_dbg,
    output DP_PACKET            dp_packet_dbg,
    output logic                dp_packet_req_dbg,
    output RS_DP_PACKET         avail_vec_dbg,
    output RS_EX_PACKET         rs_ex_packet_dbg,
    output ROB_RS_PACKET        rob_rs_packet_dbg,
    output ROB_MAP_PACKET       rob_map_packet_dbg,
    output logic                rob_dp_available_dbg,
    output ROB_RT_PACKET        rob_rt_packet_dbg,
    output logic                dispatch_valid_dbg,
    output logic [`XLEN-1:0]    id_ex_inst_dbg,
    output RT_DP_PACKET         rt_dp_packet_dbg,
    output IB_DP_PACKET         ib_dp_packet_dbg,
    output IF_IB_PACKET         if_ib_packet_dbg,
    output logic                ib_full_dbg,
    output logic                ib_empty_dbg,
    output logic                squash_dbg
);   

    //////////////////////////////////////////////////
    //                                              //
    //                Pipeline Wires                //
    //                                              //
    //////////////////////////////////////////////////

    // Global Signals
    logic squash, dispatch_valid;
    assign squash_dbg = squash;
    assign dispatch_valid_dbg = dispatch_valid;

    // CDB Outputs
    CDB_PACKET cdb_packet;
    CDB_EX_PACKET cdb_ex_packet;
    assign cdb_packet_dbg = cdb_packet;
    assign cdb_ex_packet_dbg = cdb_ex_packet;

    // Map Table Outputs
    MAP_RS_PACKET map_rs_packet;
    MAP_ROB_PACKET map_rob_packet;
    assign map_rs_packet_dbg = map_rs_packet;
    assign map_rob_packet_dbg = map_rob_packet;

    // IF Stage Outputs
    IF_IB_PACKET if_ib_packet;
    logic [31:0] proc2Imem_addr;
    assign if_ib_packet_dbg = if_ib_packet;

    // IB Stage Outputs
    IB_DP_PACKET ib_dp_packet;
    logic ib_full, ib_empty;
    assign ib_full_dbg = ib_full;
    assign ib_empty_dbg = ib_empty;
    assign ib_dp_packet_dbg = ib_dp_packet;

    // EX Stage Outputs
    EX_CDB_PACKET ex_cdb_packet;
    assign ex_cdb_packet_dbg = ex_cdb_packet;

    // DP Stage Outputs
    DP_PACKET dp_packet;
    logic dp_packet_req;
    assign dp_packet_dbg = dp_packet;
    assign dp_packet_req_dbg = dp_packet_req;

    // RS Outputs
    RS_DP_PACKET avail_vec;
    RS_EX_PACKET rs_ex_packet;
    logic rs_dispatch_valid;
    assign rs_dispatch_valid_dbg = rs_dispatch_valid;
    assign avail_vec_dbg = avail_vec;
    assign rs_ex_packet_dbg = rs_ex_packet;

    // ROB Outputs
    ROB_RS_PACKET rob_rs_packet;
    ROB_MAP_PACKET rob_map_packet;
    logic rob_dp_available;
    ROB_RT_PACKET rob_rt_packet;
    assign rob_rs_packet_dbg = rob_rs_packet;
    assign rob_map_packet_dbg = rob_map_packet;
    assign rob_dp_available_dbg = rob_dp_available;
    assign rob_rt_packet_dbg = rob_rt_packet;
    

    // RT Outputs
    RT_DP_PACKET rt_dp_packet;
    assign rt_dp_packet_dbg = rt_dp_packet;
     
    // IF control signals
    logic if_stall, if_take_branch, if_branch_target;
    assign if_NPC_dbg = if_ib_packet.NPC;
    assign if_inst_dbg = if_ib_packet.inst;
    assign if_valid_dbg = if_ib_packet.valid;

    // ID control signals
    logic id_stall;

    // Outputs from EX-Stage and EX/MEM Pipeline Register
    EX_MEM_PACKET ex_packet, ex_mem_reg;

    // Outputs from MEM-Stage and MEM/WB Pipeline Register
    MEM_WB_PACKET mem_packet, mem_wb_reg;

    // /* Not used in Project 4 architecture
    // // Outputs from EX-Stage and EX/MEM Pipeline Register
    // EX_MEM_PACKET ex_packet, ex_mem_reg;

    // Outputs from MEM-Stage to memory
    logic [`XLEN-1:0] proc2Dmem_addr;
    logic [`XLEN-1:0] proc2Dmem_data;
    logic [1:0]       proc2Dmem_command;
    MEM_SIZE          proc2Dmem_size;

    // Outputs from WB-Stage (These loop back to the register file in ID)
    logic             wb_regfile_en;
    logic [4:0]       wb_regfile_idx;
    logic [`XLEN-1:0] wb_regfile_data;


    
    //////////////////////////////////////////////////
    //                                              //
    //          GLOBAL SIGNAL CONTROL LOGIC         //
    //                                              //
    //////////////////////////////////////////////////


    assign squash = 0; // TEMP DEBUG LOGIC
    assign rob_dp_available = 1; // TEMP DEBUG LOGIC
    assign rs_dispatch_valid = 1; // TEMP DEBUG LOGIC
    assign dispatch_valid = !ib_empty && rs_dispatch_valid && rob_dp_available;



    //////////////////////////////////////////////////
    //                                              //
    //                  BP Stage                    //
    //                                              //
    //////////////////////////////////////////////////




    //////////////////////////////////////////////////
    //                                              //
    //                  IF Stage                    //
    //                                              //
    //////////////////////////////////////////////////

    // IF Stage Logic
    logic if_stall, bp_taken;
    logic [31:0] bp_pc, bp_npc;
    assign if_stall = (proc2mem_command != BUS_LOAD);
    
    // temp debug logic
    assign bp_taken = 0;
    assign bp_pc = 0;
    assign bp_npc = 0;

    // IF_stage module declaration
    // logic [1:0][63:0] superscaler_proc2Imem_addr;
    // assign proc2Imem_addr = superscaler_proc2Imem_addr[0];
    if_stage u_if_stage (
        // Inputs
        .clock             (clock),
        .reset             (reset),
        .ib_full           (ib_full),
        .if_stall          (if_stall),
        .bp_pc             (bp_pc),
        .bp_taken          (bp_taken),
        .mem2proc_data     (mem2proc_data),
        // Outputs
        .if_ib_packet      (if_ib_packet),
        .proc2Imem_addr    (proc2Imem_addr)
    );


    //////////////////////////////////////////////////
    //                                              //
    //                  IB Stage                    //
    //                                              //
    //////////////////////////////////////////////////


    insn_buffer u_insn_buffer (
        .clock                (clock),
        .reset                (reset),
        .dispatch_valid_in    (dispatch_valid),
        .squash_in            (squash),
        .if_ib_packet         (if_ib_packet),
        .ib_full              (ib_full),
        .ib_empty             (ib_empty),
        // Instruction output
        .ib_dp_packet         (ib_dp_packet)
    );
    
    //////////////////////////////////////////////////
    //                                              //
    //                Decode Stage                  //
    //                                              //
    //////////////////////////////////////////////////

    stage_dp u_stage_dp (
        // Inputs
        .clock           (clock),
        .reset           (reset),
        .rt_dp_packet    (rt_dp_packet),
        .ib_dp_packet    (ib_dp_packet),
        // Outputs
        .dp_packet       (dp_packet)
    );
    //////////////////////////////////////////////////
    //                                              //
    //            Reservation Station               //
    //                                              //
    //////////////////////////////////////////////////
    // assign rob_rs_packet.rob_tail.rob_tag = if_ib_packet.PC >> 2; // DEBUG ONLY
    // assign rob_map_packet.rob_new_tail.rob_tag = if_ib_packet.PC >> 2;
    rob u_rob (
        // Basic Signal Input:
        .clock                             (clock),
        .reset                             (reset),
        // Signal for rob:
        // Input packages from Map_Table:
        .map_rob_packet                    (map_rob_packet),
        // Output packages to Map_Table:
        .rob_map_packet                    (rob_map_packet),
        // Input packages from Instructions_Buffer:
        .instructions_buffer_rob_packet    (dp_packet),
        // Output packages to Map_Table:
        .rob_rs_packet                     (rob_rs_packet),
        // Input packages to ROB
        .cdb_rob_packet                    (cdb_rob_packet),
        // dispatch available
        .dp_rob_available                  (dispatch_valid),
        .rob_dp_available                  (rob_dispatch_valid),
        // output retire inst to dispatch_module:
        .rob_rt_packet                     (rob_rt_packet)
        // Rob_interface, just for rob_test
        // .`INTERFACE_PORT                   (`INTERFACE_PORT)
    );

    //////////////////////////////////////////////////
    //                                              //
    //                  ROB Stage                   //
    //                                              //
    //////////////////////////////////////////////////

    // rob u_rob (
    //     // Basic Signal Input:
    //     .clock                             (clock),
    //     .reset                             (reset),
    //     // Signal for rob:
    //     // Input packages from Map_Table:
    //     .map_rob_packet                    (map_rob_packet),
    //     // Output packages to Map_Table:
    //     .rob_map_packet                    (rob_map_packet),
    //     // Input packages from Instructions_Buffer:
    //     .instructions_buffer_rob_packet    (dp_packet),
    //     // Output packages to Map_Table:
    //     .rob_rs_packet                     (rob_rs_packet),
    //     // Input packages to ROB
    //     .cdb_rob_packet                    (cdb_rob_packet),
    //     // dispatch available
    //     .dp_rob_available                  (dispatch_valid),
    //     .rob_dp_available                  (rob_dp_available),
    //     // output retire inst to dispatch_module:
    //     .rob_rt_packet                     (rob_rt_packet)
    //     // Rob_interface, just for rob_test
    //     // .`INTERFACE_PORT                   (`INTERFACE_PORT)
    // );
    
    

    //////////////////////////////////////////////////
    //                                              //
    //                  Map Table                   //
    //                                              //
    //////////////////////////////////////////////////

    // Temporarily hardcode signals that should come from RS

    map_table u_map_table (
        // global signals
        .clock             (clock),
        .reset             (reset),
        .dispatch_valid    (dispatch_valid),
        // input packets
        .cdb_packet        (cdb_packet),
        .rob_map_packet    (rob_map_packet),
        // output packets
        .map_rs_packet     (map_rs_packet),
        .map_rob_packet    (map_rob_packet),
        // debug
        .m_table_dbg       (m_table_dbg)
    );
   
    //////////////////////////////////////////////////
    //                                              //
    //                  RT Stage                    //
    //                                              //
    //////////////////////////////////////////////////

    retire u_retire (
        .rob_rt_packet    (rob_rt_packet),
        .rt_dp_packet     (rt_dp_packet)
    );


    //////////////////////////////////////////////////
    //                                              //
    //                Execution Stage               //
    //                                              //
    //////////////////////////////////////////////////

    ex u_ex (
        // global signals
        .clock            (clock),
        .reset            (reset),
        .squash           (squash),
        // input packets
        .cdb_packet       (cdb_packet),
        .cdb_ex_packet    (cdb_ex_packet),
        .rs_ex_packet     (rs_ex_packet),
        // output packets
        // debug
        .ex_cdb_packet    (ex_cdb_packet)
    );

    //////////////////////////////////////////////////
    //                                              //
    //           EX/MEM Pipeline Register           //
    //                                              //
    //////////////////////////////////////////////////

    assign ex_mem_enable = 1'b1; // always enabled
    // synopsys sync_set_reset "reset"
    always_ff @(posedge clock) begin
        if (reset || ex_mem_reg.take_branch) begin
            ex_mem_inst_dbg <= `NOP; // debug output
            ex_mem_reg      <= 0;    // the defaults can all be zero!
        end else if (ex_mem_enable) begin
            ex_mem_inst_dbg <= id_ex_inst_dbg; // debug output, just forwarded from ID
            ex_mem_reg      <= ex_packet;
        end
    end

    // debug outputs
    assign ex_mem_NPC_dbg   = ex_mem_reg.NPC;
    assign ex_mem_valid_dbg = ex_mem_reg.valid;

    //////////////////////////////////////////////////
    //                                              //
    //                   Mem-Stage                  //
    //                                              //
    //////////////////////////////////////////////////
 
    // stage_mem stage_mem_0 (
    //     // Inputs
    //     .ex_mem_reg     (ex_mem_reg),
    //     .Dmem2proc_data (mem2proc_data[`XLEN-1:0]), // for p3, we throw away the top 32 bits

    //     // Outputs
    //     .mem_packet        (mem_packet),
    //     .proc2Dmem_command (proc2Dmem_command),
    //     .proc2Dmem_size    (proc2Dmem_size),
    //     .proc2Dmem_addr    (proc2Dmem_addr),
    //     .proc2Dmem_data    (proc2Dmem_data)
    // );
    assign proc2Dmem_command = BUS_NONE; // ignore memory for now

    //////////////////////////////////////////////////
    //                                              //
    //           MEM/WB Pipeline Register           //
    //                                              //
    //////////////////////////////////////////////////

    assign mem_wb_enable = 1'b1; // always enabled
    // synopsys sync_set_reset "reset"
    always_ff @(posedge clock) begin
        if (reset) begin
            mem_wb_inst_dbg <= `NOP; // debug output
            mem_wb_reg      <= 0;    // the defaults can all be zero!
        end else if (mem_wb_enable) begin
            mem_wb_inst_dbg <= ex_mem_inst_dbg; // debug output, just forwarded from EX
            mem_wb_reg      <= mem_packet;
        end
    end

    // debug outputs
    assign mem_wb_NPC_dbg   = mem_wb_reg.NPC;
    assign mem_wb_valid_dbg = mem_wb_reg.valid;

    //////////////////////////////////////////////////
    //                                              //
    //                  WB-Stage                    //
    //                                              //
    //////////////////////////////////////////////////

    stage_wb stage_wb_0 (
        // Input
        .mem_wb_reg (mem_wb_reg), // doesn't use all of these

        // Outputs
        .wb_regfile_en   (wb_regfile_en),
        .wb_regfile_idx  (wb_regfile_idx),
        .wb_regfile_data (wb_regfile_data)
    );

    //////////////////////////////////////////////////
    //                                              //
    //                Memory Outputs                //
    //                                              //
    //////////////////////////////////////////////////

    // these signals go to and from the processor and memory
    // we give precedence to the mem stage over instruction fetch
    // note that there is no latency in project 3
    // but there will be a 100ns latency in project 4

    always_comb begin
        if (proc2Dmem_command != BUS_NONE) begin // read or write DATA from memory
            proc2mem_command = proc2Dmem_command;
            proc2mem_addr    = proc2Dmem_addr;
`ifndef CACHE_MODE
            proc2mem_size    = proc2Dmem_size;  // size is never DOUBLE in project 3
`endif
        end else begin                          // read an INSTRUCTION from memory
            proc2mem_command = BUS_LOAD;
            proc2mem_addr    = proc2Imem_addr;
`ifndef CACHE_MODE
            proc2mem_size    = DOUBLE;          // instructions load a full memory line (64 bits)
`endif
        end
        proc2mem_data = {32'b0, proc2Dmem_data};
    end

    //////////////////////////////////////////////////
    //                                              //
    //               Pipeline Outputs               //
    //                                              //
    //////////////////////////////////////////////////

    assign pipeline_completed_insts = {3'b0, mem_wb_reg.valid}; // commit one valid instruction
    assign pipeline_error_status = mem_wb_reg.illegal        ? ILLEGAL_INST :
                                   mem_wb_reg.halt           ? HALTED_ON_WFI :
                                   (mem2proc_response==4'h0) ? LOAD_ACCESS_FAULT : NO_ERROR;

    assign pipeline_commit_wr_en   = wb_regfile_en;
    assign pipeline_commit_wr_idx  = wb_regfile_idx;
    assign pipeline_commit_wr_data = wb_regfile_data;
    assign pipeline_commit_NPC     = mem_wb_reg.NPC;

endmodule // pipeline
