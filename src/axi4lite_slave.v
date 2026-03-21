module axi4lite_slave (
    input clk,
    input rst,

    // WRITE ADDRESS
    input [3:0] awaddr,
    input awvalid,
    output reg awready,

    // WRITE DATA
    input [7:0] wdata,
    input wvalid,
    output reg wready,

    // WRITE RESPONSE
    output reg bvalid,
    input bready,

    // READ ADDRESS
    input [3:0] araddr,
    input arvalid,
    output reg arready,

    // READ DATA
    output reg [7:0] rdata,
    output reg rvalid,
    input rready
);

reg [7:0] mem [0:15];

always @(posedge clk) begin
    if (rst) begin
        awready <= 0; wready <= 0; bvalid <= 0;
        arready <= 0; rvalid <= 0;
    end else begin
        // WRITE ADDRESS
        if (awvalid && !awready) begin
            awready <= 1;
        end else begin
            awready <= 0;
        end

        // WRITE DATA
        if (wvalid && !wready) begin
            wready <= 1;
            mem[awaddr] <= wdata;
            bvalid <= 1;
        end else begin
            wready <= 0;
        end

        // WRITE RESPONSE
        if (bvalid && bready) begin
            bvalid <= 0;
        end

        // READ
        if (arvalid && !arready) begin
            arready <= 1;
            rdata <= mem[araddr];
            rvalid <= 1;
        end else begin
            arready <= 0;
        end

        if (rvalid && rready) begin
            rvalid <= 0;
        end
    end
end

endmodule
