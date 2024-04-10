/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  pipeline_test.sv                                    //
//                                                                     //
//  Description :  Testbench module for the verisimple pipeline;       //
//                 includes a basic visual debugger.                   //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`define CLOCK_PERIOD 30.0
`include "../verilog/sys_defs.svh"

module testbench (
    input wire clock,
    input wire reset
);
    // Define visual debugging signals for each pipeline stage
    logic [4:0]       visual_debug_signals;
    logic [31:0]      instr_count, clock_count;
    string            program_memory_file, writeback_output_file;
    int               wb_fileno;
    logic [3:0]       pipeline_completed_insts;
    logic             pipeline_commit_wr_en;
    EXCEPTION_CODE    pipeline_error_status;
    logic [63:0]      debug_counter;   
    logic [31:0]      if_inst_dbg;
    logic [`XLEN-1:0] if_NPC_dbg; 
    logic             if_valid_dbg; 
    logic [31:0]      if_id_inst_dbg;
    logic [`XLEN-1:0] if_id_NPC_dbg;
    logic             if_id_valid_dbg;
    logic [`XLEN-1:0] id_ex_NPC_dbg;
    logic [31:0]      id_ex_inst_dbg;
    logic             id_ex_valid_dbg;
    logic [`XLEN-1:0] ex_mem_NPC_dbg;
    logic [31:0]      ex_mem_inst_dbg;
    logic             ex_mem_valid_dbg;
    logic [`XLEN-1:0] mem_wb_NPC_dbg;
    logic [31:0]      mem_wb_inst_dbg;
    logic             mem_wb_valid_dbg;
    logic [`XLEN-1:0] pipeline_commit_wr_data;
    logic [4:0]       pipeline_commit_wr_idx;
    logic [1:0]       proc2mem_command;
    logic [`XLEN-1:0] proc2mem_addr;
    logic [63:0]      proc2mem_data;
    logic [3:0]       mem2proc_response;
    logic [63:0]      mem2proc_data;
    logic [3:0]       mem2proc_tag;

    // Instantiate the Pipeline
    pipeline core (
        // Inputs
        .clock (clock),
        .reset (reset),
        // Add visual debugging signals as inputs to the pipeline
        .visual_debug_signals(visual_debug_signals)
    );

    // Generate System Clock
    always begin
        #(`CLOCK_PERIOD/2.0);
        clock = ~clock;
    end

    // Update visual debugging signals at each clock cycle
    always @(posedge clock) begin
        if (!reset) begin
            // Update visual debugging signals based on the activity of each pipeline stage
            // For simplicity, assume each stage is active every other clock cycle
            visual_debug_signals <= {5'b1, 5'b0}; // Example: Fetch stage active, others inactive
            // Display visual debugging signals
            $display("Pipeline Stage Activity: %b", visual_debug_signals);
        end
    end

    // Define task to display # of elapsed clock edges
    task show_clk_count;
        real cpi;
        begin
            cpi = (clock_count + 1.0) / instr_count;
            $display("@@  %0d cycles / %0d instrs = %f CPI\n@@",
                      clock_count+1, instr_count, cpi);
            $display("@@  %4.2f ns total time to execute\n@@\n",
                      clock_count * `CLOCK_PERIOD);
        end
    endtask // task show_clk_count

    // Show contents of a range of Unified Memory, in both hex and decimal
    task show_mem_with_decimal;
        input [31:0] start_addr;
        input [31:0] end_addr;
        int showing_data;
        begin
            $display("@@@");
            showing_data=0;
            for(int k=start_addr;k<=end_addr; k=k+1)
                if (memory.unified_memory[k] != 0) begin
                    $display("@@@ mem[%5d] = %x : %0d", k*8, memory.unified_memory[k],
                                                             memory.unified_memory[k]);
                    showing_data=1;
                end else if(showing_data!=0) begin
                    $display("@@@");
                    showing_data=0;
                end
            $display("@@@");
        end
    endtask // task show_mem_with_decimal

    initial begin
        //$dumpvars;

        // P4 NOTE: You must keep memory loading here the same for the autograder
        //          Other things can be tampered with somewhat
        //          Definitely feel free to add new output files

        // set paramterized strings, see comment at start of module
        if ($value$plusargs("MEMORY=%s", program_memory_file)) begin
            $display("Loading memory file: %s", program_memory_file);
        end else begin
            $display("Loading default memory file: program.mem");
            program_memory_file = "program.mem";
        end
        if ($value$plusargs("WRITEBACK=%s", writeback_output_file)) begin
            $display("Using writeback output file: %s", writeback_output_file);
        end else begin
            $display("Using default writeback output file: writeback.out");
            writeback_output_file = "writeback.out";
        end

        clock = 1'b0;
        reset = 1'b0;

        // Pulse the reset signal
        $display("@@\n@@\n@@  %t  Asserting System reset......", $realtime);
        reset = 1'b1;
        @(posedge clock);
        @(posedge clock);

        // store the compiled program's hex data into memory
        $readmemh(program_memory_file, memory.unified_memory);

        @(posedge clock);
        @(posedge clock);
        #1;
        // This reset is at an odd time to avoid the pos & neg clock edges

        reset = 1'b0;
        $display("@@  %t  Deasserting System reset......\n@@\n@@", $realtime);

        wb_fileno = $fopen(writeback_output_file);

        // Open the pipeline output file after throwing reset
        // open_pipeline_output_file(pipeline_output_file);
        // print_header("removed for line length")
    end

    // Count the number of posedges and number of instructions completed
    // till simulation ends
    always @(posedge clock) begin
        if(reset) begin
            clock_count <= 0;
            instr_count <= 0;
        end else begin
            clock_count <= (clock_count + 1);
            instr_count <= (instr_count + pipeline_completed_insts);
        end
    end

    always @(negedge clock) begin
        if(reset) begin
            $display("@@\n@@  %t : System STILL at reset, can't show anything\n@@",
                     $realtime);
            debug_counter <= 0;
        end else begin
            #2;

            // print the pipeline debug outputs via c code to the pipeline output file
            print_cycles();
            print_stage(" ", if_inst_dbg,     if_NPC_dbg    [31:0], {31'b0,if_valid_dbg});
            print_stage("|", if_id_inst_dbg,  if_id_NPC_dbg [31:0], {31'b0,if_id_valid_dbg});
            print_stage("|", id_ex_inst_dbg,  id_ex_NPC_dbg [31:0], {31'b0,id_ex_valid_dbg});
            print_stage("|", ex_mem_inst_dbg, ex_mem_NPC_dbg[31:0], {31'b0,ex_mem_valid_dbg});
            print_stage("|", mem_wb_inst_dbg, mem_wb_NPC_dbg[31:0], {31'b0,mem_wb_valid_dbg});
            print_reg(32'b0, pipeline_commit_wr_data[31:0],
                {27'b0,pipeline_commit_wr_idx}, {31'b0,pipeline_commit_wr_en});
            print_membus({30'b0,proc2mem_command}, {28'b0,mem2proc_response},
                32'b0, proc2mem_addr[31:0],
                proc2mem_data[63:32], proc2mem_data[31:0]);

            // print register write information to the writeback output file
            if (pipeline_completed_insts > 0) begin
                if(pipeline_commit_wr_en)
                    $fdisplay(wb_fileno, "PC=%x, REG[%d]=%x",
                              pipeline_commit_NPC - 4,
                              pipeline_commit_wr_idx,
                              pipeline_commit_wr_data);
                else
                    $fdisplay(wb_fileno, "PC=%x, ---", pipeline_commit_NPC - 4);
            end

            // deal with any halting conditions
            if(pipeline_error_status != NO_ERROR || debug_counter > 5000) begin
                $display("@@@ Unified Memory contents hex on left, decimal on right: ");
                show_mem_with_decimal(0,`MEM_64BIT_LINES - 1);
                // 8Bytes per line, 16kB total

                $display("@@  %t : System halted\n@@", $realtime);

                case(pipeline_error_status)
                    LOAD_ACCESS_FAULT:
                        $display("@@@ System halted on memory error");
                    HALTED_ON_WFI:
                        $display("@@@ System halted on WFI instruction");
                    ILLEGAL_INST:
                        $display("@@@ System halted on illegal instruction");
                    default:
                        $display("@@@ System halted on unknown error code %x",
                            pipeline_error_status);
                endcase
                $display("@@@\n@@");
                show_clk_count;
                // print_close(); // close the pipe_print output file
                $fclose(wb_fileno);
                #100 $finish;
            end
            debug_counter <= debug_counter + 1;
        end // if(reset)
    end

endmodule // testbench
