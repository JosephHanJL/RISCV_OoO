/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  vtuber_test.sv                                      //
//                                                                     //
//  Description :  Visual Debugger for project 4                       //
//                 Outputs only IF part                                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module testbench;
    // Remove signals and variables related to stages other than IF
    logic [`XLEN-1:0] if_NPC_dbg;
    logic [31:0]      if_inst_dbg;
    logic             if_valid_dbg;

    // Instantiate the Pipeline
    pipeline pipeline_0 (
        // Inputs and Outputs relevant to the IF stage
        .clock             (clock),
        .reset             (reset),
        // Remove other inputs and outputs
        .if_NPC_dbg        (if_NPC_dbg),
        .if_inst_dbg       (if_inst_dbg),
        .if_valid_dbg      (if_valid_dbg)
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
