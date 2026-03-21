module axi4lite_slave (
    input clk,
    input rst,

    input [3:0] awaddr,
    input awvalid,
    output reg awready,

    input [3:0] araddr,
    input arvalid,
    output reg arready,

    output reg [7:0] rdata,
    output reg rvalid
);

    reg [7:0] mem [0:15];

    always @(posedge clk) begin
        if (rst) begin
            awready <= 0;
            arready <= 0;
            rvalid  <= 0;
        end else begin
            // WRITE
            if (awvalid) begin
                awready <= 1;
                mem[awaddr] <= awaddr + 8'h10; // demo data
            end else begin
                awready <= 0;
            end

            // READ
            if (arvalid) begin
                arready <= 1;
                rdata <= mem[araddr];
                rvalid <= 1;
            end else begin
                arready <= 0;
                rvalid <= 0;
            end
        end
    end

endmodule
