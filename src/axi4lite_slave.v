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

always @(posedge clk) begin
    if (rst) begin
        for (i=0;i<16;i=i+1) mem[i]<=0;
        awready<=0; wready<=0; bvalid<=0;
        arready<=0; rvalid<=0;
    end else begin

        // WRITE
        if (awvalid && wvalid && !bvalid) begin
            mem[awaddr] <= wdata;
            awready <= 1;
            wready  <= 1;
            bvalid  <= 1;
        end else begin
            awready <= 0;
            wready  <= 0;
        end

        if (bvalid && bready)
            bvalid <= 0;

        // READ
        if (arvalid && !rvalid) begin
            rdata  <= mem[araddr];
            arready<= 1;
            rvalid <= 1;
        end else begin
            arready<= 0;
        end

        if (rvalid && rready)
            rvalid <= 0;
    end
end

endmodule
