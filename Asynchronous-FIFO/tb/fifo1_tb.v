//--------------DESCRIPTION--------------
// Self-checking testbench for the asynchronous FIFO.
// Random data is written to the FIFO, read back and compared
// with a scoreboard that stores the data in write order.
//---------------------------------------

`timescale 1ns/1ps

module fifo1_tb();

    parameter DSIZE = 8;           // Data bus size
    parameter ASIZE = 3;           // Address bus size
    parameter DEPTH = 1 << ASIZE;  // Depth of the FIFO memory

    reg [DSIZE-1:0] wdata;         // Input data
    wire [DSIZE-1:0] rdata;        // Output data
    wire wfull, rempty;            // Write full and read empty signals
    reg winc, rinc, wclk, rclk, wrst_n, rrst_n;

    fifo1 #(.DSIZE(DSIZE), .ADDRSIZE(ASIZE)) dut (
        .rdata(rdata),
        .wdata(wdata),
        .wfull(wfull),
        .rempty(rempty),
        .winc(winc),
        .rinc(rinc),
        .wclk(wclk),
        .rclk(rclk),
        .wrst_n(wrst_n),
        .rrst_n(rrst_n)
    );

    integer i = 0;
    integer seed = 1;

    // Read and write clock in loop
    initial begin wclk = 0; rclk = 0; end
    always #5  wclk = ~wclk;       // faster writing
    always #10 rclk = ~rclk;       // slower reading

    //--------------SCOREBOARD (checker only)--------------
    // Stores every accepted write (winc && !wfull) and compares every
    // accepted read (rinc && !rempty) with the oldest stored word.
    reg [DSIZE-1:0] sb [0:2*DEPTH-1];
    integer wcnt = 0, rcnt = 0, errors = 0;

    always @(posedge wclk)
        if (wrst_n && winc && !wfull) begin
            sb[wcnt % (2*DEPTH)] <= wdata;
            wcnt <= wcnt + 1;
        end

    always @(posedge rclk)
        if (rrst_n && rinc && !rempty) begin
            if (rdata !== sb[rcnt % (2*DEPTH)]) begin
                errors = errors + 1;
                $display("[ERROR] %0t: rdata=%0h expected=%0h", $time, rdata, sb[rcnt % (2*DEPTH)]);
            end
            rcnt <= rcnt + 1;
        end

    task check(input cond, input [8*32-1:0] msg);
        if (!cond) begin
            errors = errors + 1;
            $display("[ERROR] %0t: %0s", $time, msg);
        end
    endtask

    //--------------STIMULUS--------------
    // Inputs change on negedge, DUT samples on posedge (no races).
    initial begin
        // Initialize all signals
        wrst_n = 0;     // Active low reset
        rrst_n = 0;
        winc = 0;
        rinc = 0;
        wdata = 0;

        // TEST CASE 1: Reset the FIFO
        #40;
        check(rempty === 1'b1 && wfull === 1'b0, "flags wrong during reset");
        @(negedge wclk) wrst_n = 1;
        @(negedge rclk) rrst_n = 1;
        repeat (4) @(negedge wclk);

        // TEST CASE 2: Write data and read it back
        rinc = 1;
        for (i = 0; i < 10; i = i + 1) begin
            @(negedge wclk);
            wdata = $random(seed);
            winc = 1;
            @(negedge wclk);
            winc = 0;
        end
        repeat (4) @(negedge rclk);
        rinc = 0;
        check(wcnt == 10 && rcnt == 10, "not all data read back");
        check(rempty === 1'b1, "rempty not set when empty");

        // TEST CASE 3: Concurrent random read and write
        fork
            begin
                repeat (100) begin
                    @(negedge wclk);
                    winc = $random(seed);
                    wdata = $random(seed);
                end
                @(negedge wclk);
                winc = 0;
            end
            begin
                repeat (50) begin
                    @(negedge rclk);
                    rinc = $random(seed);
                end
                @(negedge rclk);
                rinc = 0;
            end
        join

        // TEST CASE 4: Write data to make FIFO full and try to write more data
        for (i = 0; i < DEPTH + 3; i = i + 1) begin
            @(negedge wclk);
            wdata = $random(seed);
            winc = 1;
        end
        @(negedge wclk);
        winc = 0;
        check(wfull === 1'b1, "wfull not set when full");
        check(wcnt - rcnt == DEPTH, "overflow changed FIFO content");

        // TEST CASE 5: Read data from empty FIFO and try to read more data
        repeat (3) @(negedge rclk);
        for (i = 0; i < DEPTH + 3; i = i + 1) begin
            @(negedge rclk);
            rinc = 1;
        end
        @(negedge rclk);
        rinc = 0;
        check(rempty === 1'b1, "rempty not set when empty");
        check(wcnt == rcnt, "write/read count mismatch");
        repeat (3) @(negedge wclk);
        check(wfull === 1'b0, "wfull not cleared");

        // Summary
        $display("\n------------ SUMMARY ------------");
        $display("Writes = %0d, Reads = %0d, Errors = %0d", wcnt, rcnt, errors);
        if (errors == 0) $display("RESULT: PASS");
        else             $display("RESULT: FAIL");
        $display("---------------------------------\n");
        $finish;
    end

    // Watchdog: simulation always ends
    initial begin
        #50000;
        $display("RESULT: FAIL (timeout)");
        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, fifo1_tb);
    end

endmodule

//----------------------------EXPLANATION-----------------------------------------------
// The testbench has five test cases:
// 1. Reset: flags must be rempty=1 and wfull=0.
// 2. Write data and read it back (read and write at the same time).
// 3. Concurrent random read and write; the scoreboard checks data and order.
// 4. Write more than DEPTH words: wfull must be set, extra writes must be ignored.
// 5. Read more than DEPTH words: rempty must be set, extra reads must be ignored.
// Every accepted write is stored and every accepted read is compared with it, so data
// and FIFO order are checked. Pointers wrap around because more than DEPTH words are
// written in total. The testbench prints the transaction counts and PASS or FAIL.
//--------------------------------------------------------------------------------------