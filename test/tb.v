`timescale 1ns / 1ps

module axi4lite_tb;

    reg clk;
    reg rst;

    reg  [7:0] ui_in;
    reg  [7:0] uio_in;

    wire [7:0] uio_out;
    wire [7:0] uo_out;

    // DUT
    tt_um_axi4lite2x2_top dut (
        .clk    (clk),
        .rst_n  (~rst),
        .ena    (1'b1),
        .ui_in  (ui_in),
        .uio_in (uio_in),
        .uio_out(uio_out),
        .uo_out (uo_out),
        .uio_oe ()
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ---------------- MASTER0 WRITE ----------------
    task m0_write(input [3:0] addr, input [7:0] data);
    begin
        @(posedge clk);
        ui_in  = 0;
        uio_in = data;

        @(posedge clk);
        ui_in[5:2] = addr;
        ui_in[0]   = 1;

        @(posedge clk);
        ui_in[0] = 0;

        // ✅ wait for AXI completion
        repeat (20) @(posedge clk);

        $display("M0 WRITE: Addr=0x%h Data=0x%h", addr, data);
    end
    endtask

    // ---------------- MASTER0 READ ----------------
    task m0_read(input [3:0] addr);
    begin
        @(posedge clk);
        ui_in  = 0;
        uio_in = 0;

        @(posedge clk);
        ui_in[5:2] = addr;
        ui_in[1]   = 1;

        @(posedge clk);
        ui_in[1] = 0;

        // ✅ wait for read data
        repeat (25) @(posedge clk);

        $display("M0 READ: Addr=0x%h Data=0x%h", addr, uo_out);
    end
    endtask

    // ---------------- MASTER1 WRITE ----------------
    task m1_write(input [3:0] addr, input [7:0] data);
    begin
        @(posedge clk);
        ui_in  = data;
        uio_in = 0;

        @(posedge clk);
        uio_in[5:2] = addr;
        uio_in[0]   = 1;

        @(posedge clk);
        uio_in[0] = 0;

        repeat (20) @(posedge clk);

        $display("M1 WRITE: Addr=0x%h Data=0x%h", addr, data);
    end
    endtask

    // ---------------- MASTER1 READ ----------------
    task m1_read(input [3:0] addr);
    begin
        @(posedge clk);
        ui_in  = 0;
        uio_in = 0;

        @(posedge clk);
        uio_in[5:2] = addr;
        uio_in[1]   = 1;

        @(posedge clk);
        uio_in[1] = 0;

        repeat (25) @(posedge clk);

        $display("M1 READ: Addr=0x%h Data=0x%h", addr, uio_out);
    end
    endtask

    // ---------------- TEST ----------------
    initial begin
        rst    = 1;
        ui_in  = 0;
        uio_in = 0;

        repeat(5) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);

        $display("===== MASTER0 → SLAVE0 =====");
        m0_write(4'h2, 8'hAA);
        m0_read (4'h2);

        $display("===== MASTER0 → SLAVE1 =====");
        m0_write(4'hA, 8'hBB);
        m0_read (4'hA);

        $display("===== MASTER1 → SLAVE0 =====");
        m1_write(4'h3, 8'hCC);
        m1_read (4'h3);

        $display("===== MASTER1 → SLAVE1 =====");
        m1_write(4'hB, 8'hDD);
        m1_read (4'hB);

        #50;
        $finish;
    end

endmodule
