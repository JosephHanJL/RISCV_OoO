/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  vtuber_test.sv                                      //
//                                                                     //
//  Description :  Visual Debugger for project 4                       //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
// vtuber_test.sv

`include "verilog/sys_defs.svh"

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
    pipeline pipeline_0 (
        .clock              (clock),
        .reset              (reset),
        // Connect IF stage signals
        .if_NPC_dbg         (if_NPC_dbg),
        .if_inst_dbg        (if_inst_dbg),
        .if_valid_dbg       (if_valid_dbg),
        // Connect other pipeline signals (not shown for brevity)
    );

    // Instantiate the No Hazard module
    nohazard nohazard_0 (
        .clk                (clock),
        .rst                (reset),
        // Connect hazard signals
        .pc                 (hazard_PC),
        .stall              (hazard_stall)
    );

    // Other modules and initial blocks (if any)

endmodule // testbench
