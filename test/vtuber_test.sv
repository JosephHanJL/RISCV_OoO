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
    // Remove signals and variables related to stages other than IF
    logic [`XLEN-1:0] if_NPC_dbg;
    logic [31:0]      if_inst_dbg;
    logic             if_valid_dbg;
    // used to parameterize which file is loaded into memory
    // "./vis_simv" still just uses program.mem
    // but now "./simv +MEMORY=<my_program>.mem" loads <my_program>.mem instead
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
