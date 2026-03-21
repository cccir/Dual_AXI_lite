module axi4lite_slave (
    input clk,
    input rst,

    input [3:0] awaddr,
    input awvalid,
    output reg awready,

    input [7:0] wdata,
    input wvalid,
    output reg wready,

    output reg bvalid,
    input bready,

    input [3:0] araddr,
    input arvalid,
    output reg arready,

    output reg [7:0] rdata,
    output reg rvalid,
    input rready
);

reg [7:0] mem [0:15];
integer i;

// 🔴 NEW: latch address
reg [3:0] awaddr_reg;
reg aw_seen;

always @(posedge clk) begin
    if (rst) begin
        for (i=0;i<16;i=i+1)
            mem[i] <= 0;

        awready <= 0;
        wready  <= 0;
        bvalid  <= 0;
        arready <= 0;
        rvalid  <= 0;

        aw_seen <= 0;
    end else begin

        // ================= WRITE ADDRESS =================
        if (awvalid && !aw_seen) begin
            awaddr_reg <= awaddr;
            aw_seen    <= 1;
            awready    <= 1;
        end else begin
            awready <= 0;
        end

        // ================= WRITE DATA =================
        if (wvalid && aw_seen && !bvalid) begin
            mem[awaddr_reg] <= wdata;
            wready <= 1;
            bvalid <= 1;
            aw_seen <= 0;
        end else begin
            wready <= 0;
        end

        // ================= WRITE RESPONSE =================
        if (bvalid && bready)
            bvalid <= 0;

        // ================= READ =================
        if (arvalid && !rvalid) begin
            rdata   <= mem[araddr];
            arready <= 1;
            rvalid  <= 1;
        end else begin
            arready <= 0;
        end

        if (rvalid && rready)
            rvalid <= 0;
    end
end

endmodule
