`timescale 1ns / 1ps

module axi4lite_tb;

    reg clk;
    reg rst_n;
    reg ena;

    reg  [7:0] ui_in;
    reg  [7:0] uio_in;

    wire [7:0] uio_oe;
    wire [7:0] uio_out;
    wire [7:0] uo_out;

    // DUT
    tt_um_axi4lite_top dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .ena    (ena),
        .ui_in  (ui_in),
        .uio_in (uio_in),
        .uio_oe (uio_oe),
        .uio_out(uio_out),
        .uo_out (uo_out)
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ---------------- TASK: MASTER0 WRITE ----------------
    task m0_write(input [3:0] addr, input [7:0] data);
    begin
        ui_in  = 0;
        uio_in = 0;
        #10;

        ui_in[5:2] = addr;
        ui_in[0]   = 1;     // start_write
        uio_in     = data;

        #10 ui_in[0] = 0;

        #50; // wait for transaction
        $display("M0 WRITE: Addr=0x%h Data=0x%h", addr, data);
    end
    endtask

    // ---------------- TASK: MASTER0 READ ----------------
    task m0_read(input [3:0] addr);
    begin
        ui_in = 0;
        #10;

        ui_in[5:2] = addr;
        ui_in[1]   = 1;     // start_read

        #10 ui_in[1] = 0;

        #50;
        $display("M0 READ: Addr=0x%h Data=0x%h", addr, uo_out);
    end
    endtask

    // ---------------- TASK: MASTER1 WRITE ----------------
    task m1_write(input [3:0] addr, input [7:0] data);
    begin
        ui_in  = 0;
        uio_in = 0;
        #10;

        uio_in[5:2] = addr;
        uio_in[0]   = 1;
        ui_in       = data;

        #10 uio_in[0] = 0;

        #50;
        $display("M1 WRITE: Addr=0x%h Data=0x%h", addr, data);
    end
    endtask

    // ---------------- TASK: MASTER1 READ ----------------
    task m1_read(input [3:0] addr);
    begin
        uio_in = 0;
        #10;

        uio_in[5:2] = addr;
        uio_in[1]   = 1;

        #10 uio_in[1] = 0;

        #50;
        $display("M1 READ: Addr=0x%h Data=0x%h", addr, uio_out);
    end
    endtask

    // ---------------- TEST ----------------
    initial begin
        rst_n  = 0;
        ena    = 1;
        ui_in  = 0;
        uio_in = 0;

        #20 rst_n = 1;
        #20;

        $display("===== MASTER0 → SLAVE0 =====");
        m0_write(4'h2, 8'hAA);   // Slave0
        m0_read (4'h2);

        $display("===== MASTER0 → SLAVE1 =====");
        m0_write(4'hA, 8'hBB);   // Slave1
        m0_read (4'hA);

        $display("===== MASTER1 → SLAVE0 =====");
        m1_write(4'h3, 8'hCC);
        m1_read (4'h3);

        $display("===== MASTER1 → SLAVE1 =====");
        m1_write(4'hB, 8'hDD);
        m1_read (4'hB);

        #100;
        $finish;
    end

endmodule
