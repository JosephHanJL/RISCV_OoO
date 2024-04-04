///////////////////////////////////////////////////////////////////////
// Modulename : vtuber_test.sv
// Description: Visual Debugger for project 4
///////////////////////////////////////////////////////////////////////

`ifndef XLEN
`define XLEN 32 
`endif

`include "../verilog/sys_defs.svh"

module testbench;
    // Inputs and outputs for pipeline and nohazard modules
    logic clock, reset;
    // Add inputs and outputs relevant to the IF stage
    logic [`XLEN-1:0] if_NPC_dbg;
    logic [31:0]      if_inst_dbg;
    logic             if_valid_dbg;
    // Add inputs and outputs for nohazard module
    logic [31:0]      hazard_PC;
    logic             hazard_stall;

    // Instantiate the Pipeline
    pipeline core (
        // Inputs
        .clock                   (clock),
        .reset                   (reset),
        .mem2proc_response       (mem2proc_response),
        .mem2proc_data           (mem2proc_data),
        .mem2proc_tag            (mem2proc_tag),

        // Outputs
        .proc2mem_command        (proc2mem_command),
        .proc2mem_addr           (proc2mem_addr),
        .proc2mem_data           (proc2mem_data),
        .proc2mem_size           (proc2mem_size),

        .pipeline_completed_insts(pipeline_completed_insts),
        .pipeline_error_status   (pipeline_error_status),
        .pipeline_commit_wr_data (pipeline_commit_wr_data),
        .pipeline_commit_wr_idx  (pipeline_commit_wr_idx),
        .pipeline_commit_wr_en   (pipeline_commit_wr_en),
        .pipeline_commit_NPC     (pipeline_commit_NPC)
    );

    // Instantiate the No Hazard module
    nohazard nohazard_0 (
        .clk                (clock),
        .rst                (reset),
        // Connect hazard signals
        .pc                 (hazard_PC),
        .stall              (hazard_stall)
    );

    // Instantiate the Data Memory
    mem memory (
        .clk                  (clock),
        .proc2mem_command     (proc2mem_command),
        .proc2mem_addr        (proc2mem_addr),
        .proc2mem_data        (proc2mem_data),
        .proc2mem_size        (proc2mem_size),
        .mem2proc_response    (mem2proc_response),
        .mem2proc_data        (mem2proc_data),
        .mem2proc_tag         (mem2proc_tag)
    );

    // Generate System Clock
    always begin
        #(`CLOCK_PERIOD/2.0);
        clock = ~clock;
    end

endmodule // testbench
