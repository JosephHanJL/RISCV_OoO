/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  pipeline_test.sv                                    //
//                                                                     //
//  Description :  Testbench module for the verisimple pipeline;       //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"
// P4 TODO: Add your own debugging framework. Basic printing of data structures
//          is an absolute necessity for the project. You can use C functions
//          like in test/pipeline_print.c or just do everything in verilog.
//          Be careful about running out of space on CAEN printing lots of state
//          for longer programs (alexnet, outer_product, etc.)


// these link to the pipeline_print.c file in this directory, and are used below to print
// detailed output to the pipeline_output_file, initialized by open_pipeline_output_file()
// import "DPI-C" function void open_pipeline_output_file(string file_name);
// import "DPI-C" function void print_header(string str);
// import "DPI-C" function void print_cycles();
// import "DPI-C" function void print_stage(string div, int inst, int npc, int valid_inst);
// import "DPI-C" function void print_reg(int wb_reg_wr_data_out_hi, int wb_reg_wr_data_out_lo,
//                                        int wb_reg_wr_idx_out, int wb_reg_wr_en_out);
// import "DPI-C" function void print_membus(int proc2mem_command, int mem2proc_response,
//                                           int proc2mem_addr_hi, int proc2mem_addr_lo,
//                                           int proc2mem_data_hi, int proc2mem_data_lo);
// import "DPI-C" function void print_close();


module testbench;
    // used to parameterize which files are used for memory and writeback/pipeline outputs
    // "./simv" uses program.mem, writeback.out, and pipeline.out
    // but now "./simv +MEMORY=<my_program>.mem" loads <my_program>.mem instead
    // use +WRITEBACK=<my_program>.wb and +PIPELINE=<my_program>.ppln for those outputs as well
    string program_memory_file;
    string writeback_output_file;
    // string pipeline_output_file;

    // variables used in the testbench
    logic        clock;
    logic        reset;
    logic [31:0] clock_count;
    logic [31:0] instr_count;
    int          wb_fileno;
    logic [63:0] debug_counter; // counter used for infinite loops, forces termination

    logic [1:0]       proc2mem_command;
    logic [`XLEN-1:0] proc2mem_addr;
    logic [63:0]      proc2mem_data;
    logic [3:0]       mem2proc_response;
    logic [63:0]      mem2proc_data;
    logic [3:0]       mem2proc_tag;
`ifndef CACHE_MODE
    MEM_SIZE          proc2mem_size;
`endif

    logic [3:0]       pipeline_completed_insts;
    EXCEPTION_CODE    pipeline_error_status;
    logic [4:0]       pipeline_commit_wr_idx;
    logic [`XLEN-1:0] pipeline_commit_wr_data;
    logic             pipeline_commit_wr_en;
    logic [`XLEN-1:0] pipeline_commit_NPC;

    logic [`XLEN-1:0] if_NPC_dbg;
    logic [31:0]      if_inst_dbg;
    logic             if_valid_dbg;
    logic [`XLEN-1:0] ex_mem_NPC_dbg;
    logic [31:0]      ex_mem_inst_dbg;
    logic             ex_mem_valid_dbg;
    logic [`XLEN-1:0] mem_wb_NPC_dbg;
    logic [31:0]      mem_wb_inst_dbg;
    logic             mem_wb_valid_dbg;
    MAP_PACKET [31:0] m_table_dbg;
    logic [`NUM_FU:0] dones_dbg;
    logic [`NUM_FU:0] ack_dbg;
    CDB_PACKET        cdb_packet_dbg;
    CDB_EX_PACKET     cdb_ex_packet_dbg;
    MAP_RS_PACKET     map_rs_packet_dbg;
    MAP_ROB_PACKET    map_rob_packet_dbg;
    EX_CDB_PACKET     ex_cdb_packet_dbg;
    DP_PACKET [1:0]   dp_packet_dbg;
    logic [1:0]       dp_packet_req_dbg;
    RS_DP_PACKET      avail_vec_dbg;
    RS_EX_PACKET      rs_ex_packet_dbg;
    ROB_RS_PACKET     rob_rs_packet_dbg;
    ROB_MAP_PACKET    rob_map_packet_dbg;
    logic [1:0]       rob_dp_available_dbg;
    ROB_RT_PACKET     rob_rt_packet_dbg;
    logic             dispatch_valid_dbg;
    logic [`XLEN-1:0] id_ex_inst_dbg;


    // Instantiate the Pipeline
    pipeline core (
        .clock                       (clock),
        .reset                       (reset),
        .mem2proc_response           (mem2proc_response),
        .mem2proc_data               (mem2proc_data),
        .mem2proc_tag                (mem2proc_tag),

        .proc2mem_command            (proc2mem_command),
        .proc2mem_addr               (proc2mem_addr),
        .proc2mem_data               (proc2mem_data),
        .proc2mem_size               (proc2mem_size),

        .pipeline_completed_insts    (pipeline_completed_insts),
        .pipeline_error_status       (pipeline_error_status),
        .pipeline_commit_wr_idx      (pipeline_commit_wr_idx),
        .pipeline_commit_wr_data     (pipeline_commit_wr_data),
        .pipeline_commit_wr_en       (pipeline_commit_wr_en),
        .pipeline_commit_NPC         (pipeline_commit_NPC),

        // Debug outputs:
        .if_NPC_dbg                  (if_NPC_dbg),
        .if_inst_dbg                 (if_inst_dbg),
        .if_valid_dbg                (if_valid_dbg),
        .ex_mem_NPC_dbg              (ex_mem_NPC_dbg),
        .ex_mem_inst_dbg             (ex_mem_inst_dbg),
        .ex_mem_valid_dbg            (ex_mem_valid_dbg),
        .mem_wb_NPC_dbg              (mem_wb_NPC_dbg),
        .mem_wb_inst_dbg             (mem_wb_inst_dbg),
        .mem_wb_valid_dbg            (mem_wb_valid_dbg),
        .m_table_dbg                 (m_table_dbg),
        .dones_dbg                   (dones_dbg),
        .ack_dbg                     (ack_dbg),
        .cdb_packet_dbg              (cdb_packet_dbg),
        .cdb_ex_packet_dbg           (cdb_ex_packet_dbg),
        .map_rs_packet_dbg           (map_rs_packet_dbg),
        .map_rob_packet_dbg          (map_rob_packet_dbg),
        .ex_cdb_packet_dbg           (ex_cdb_packet_dbg),
        .dp_packet_dbg               (dp_packet_dbg),
        .dp_packet_req_dbg           (dp_packet_req_dbg),
        .avail_vec_dbg               (avail_vec_dbg),
        .rs_ex_packet_dbg            (rs_ex_packet_dbg),
        .rob_rs_packet_dbg           (rob_rs_packet_dbg),
        .rob_map_packet_dbg          (rob_map_packet_dbg),
        .rob_dp_available_dbg        (rob_dp_available_dbg),
        .rob_rt_packet_dbg           (rob_rt_packet_dbg),
        .dispatch_valid_dbg          (dispatch_valid_dbg),
        .id_ex_inst_dbg              (id_ex_inst_dbg)
    );


    // Instantiate the Data Memory
    mem memory (
        // Inputs
    // .if_NPC_dbg       (if_NPC_dbg),
        // .if_inst_dbg      (if_inst_dbg),
        // .if_valid_dbg     (if_valid_dbg),
        // .if_id_NPC_dbg    (if_id_NPC_dbg),
        // .if_id_inst_dbg   (if_id_inst_dbg),
        // .if_id_valid_dbg  (if_id_valid_dbg),
        // .id_ex_NPC_dbg    (id_ex_NPC_dbg),
        // .id_ex_inst_dbg   (id_ex_inst_dbg),
        // .id_ex_valid_dbg  (id_ex_valid_dbg),
        // .ex_mem_NPC_dbg   (ex_mem_NPC_dbg),
        // .ex_mem_inst_dbg  (ex_mem_inst_dbg),
        // .ex_mem_valid_dbg (ex_mem_valid_dbg),
        // .mem_wb_NPC_dbg   (mem_wb_NPC_dbg),
        // .mem_wb_inst_dbg  (mem_wb_inst_dbg),
        // .mem_wb_valid_dbg (mem_wb_valid_dbg)
        .clk              (clock),
        .proc2mem_command (proc2mem_command),
        .proc2mem_addr    (proc2mem_addr),
        .proc2mem_data    (proc2mem_data),
`ifndef CACHE_MODE
        .proc2mem_size    (proc2mem_size),
`endif

        // Outputs
        .mem2proc_response (mem2proc_response),
        .mem2proc_data     (mem2proc_data),
        .mem2proc_tag      (mem2proc_tag)
    );


    // Generate System Clock
    always begin
        #(`CLOCK_PERIOD/2.0);
        clock = ~clock;
    end


    // Task to display # of elapsed clock edges
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
        // if ($value$plusargs("PIPELINE=%s", pipeline_output_file)) begin
        //     $display("Using pipeline output file: %s", pipeline_output_file);
        // end else begin
        //     $display("Using default pipeline output file: pipeline.out");
        //     pipeline_output_file = "pipeline.out";
        // end

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
        // print_header("removed for line length");
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
            // print_cycles();
            // print_stage(" ", if_inst_dbg,     if_NPC_dbg    [31:0], {31'b0,if_valid_dbg});
            // print_stage("|", if_id_inst_dbg,  if_id_NPC_dbg [31:0], {31'b0,if_id_valid_dbg});
            // print_stage("|", id_ex_inst_dbg,  id_ex_NPC_dbg [31:0], {31'b0,id_ex_valid_dbg});
            // print_stage("|", ex_mem_inst_dbg, ex_mem_NPC_dbg[31:0], {31'b0,ex_mem_valid_dbg});
            // print_stage("|", mem_wb_inst_dbg, mem_wb_NPC_dbg[31:0], {31'b0,mem_wb_valid_dbg});
            // print_reg(32'b0, pipeline_commit_wr_data[31:0],
            //     {27'b0,pipeline_commit_wr_idx}, {31'b0,pipeline_commit_wr_en});
            // print_membus({30'b0,proc2mem_command}, {28'b0,mem2proc_response},
            //     32'b0, proc2mem_addr[31:0],
            //     proc2mem_data[63:32], proc2mem_data[31:0]);

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
