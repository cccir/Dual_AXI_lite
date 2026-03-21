`timescale 1ns / 1ps

module axi4lite_tb;

    reg clk;
    reg rst;

    reg  [7:0] ui_in;
    reg  [7:0] uio_in;

    wire [7:0] uio_out;
    wire [7:0] uo_out;

    // DUT
tt_um_axi4lite_top dut (
    .clk    (clk),
    .rst_n  (~rst),   // active LOW reset
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
        ui_in  = 0;
        uio_in = data;
        #10;

        ui_in[5:2] = addr;
        ui_in[0]   = 1;   // start_write

        #10 ui_in[0] = 0;

        wait(dut.m0.done);   // ✅ wait for completion
        #10;

        $display("M0 WRITE: Addr=0x%h Data=0x%h", addr, data);
    end
    endtask

    // ---------------- MASTER0 READ ----------------
    task m0_read(input [3:0] addr);
    begin
        ui_in  = 0;
        uio_in = 0;
        #10;

        ui_in[5:2] = addr;
        ui_in[1]   = 1;   // start_read

        #10 ui_in[1] = 0;

        wait(dut.m0.done);   // ✅ wait for read complete
        #10;

        $display("M0 READ: Addr=0x%h Data=0x%h", addr, uo_out);
    end
    endtask

    // ---------------- MASTER1 WRITE ----------------
    task m1_write(input [3:0] addr, input [7:0] data);
    begin
        ui_in  = data;
        uio_in = 0;
        #10;

        uio_in[5:2] = addr;
        uio_in[0]   = 1;

        #10 uio_in[0] = 0;

        wait(dut.m1.done);   // ✅ wait for completion
        #10;

        $display("M1 WRITE: Addr=0x%h Data=0x%h", addr, data);
    end
    endtask

    // ---------------- MASTER1 READ ----------------
    task m1_read(input [3:0] addr);
    begin
        ui_in  = 0;
        uio_in = 0;
        #10;

        uio_in[5:2] = addr;
        uio_in[1]   = 1;

        #10 uio_in[1] = 0;

        wait(dut.m1.done);   // ✅ wait for read complete
        #10;

        $display("M1 READ: Addr=0x%h Data=0x%h", addr, uio_out);
    end
    endtask

    // ---------------- TEST ----------------
    initial begin
        rst    = 1;
        ui_in  = 0;
        uio_in = 0;

        #20 rst = 0;
        #20;

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
