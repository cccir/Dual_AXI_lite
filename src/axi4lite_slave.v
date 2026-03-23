module axi4lite_slave (
    input  wire       clk,
    input  wire       rst,

    input  wire [3:0] awaddr,
    input  wire       awvalid,
    output reg        awready,

    input  wire [7:0] wdata,
    input  wire       wvalid,
    output reg        wready,

    output reg        bvalid,
    input  wire       bready,

    input  wire [3:0] araddr,
    input  wire       arvalid,
    output reg        arready,

    output reg [7:0]  rdata,
    output reg        rvalid,
    input  wire       rready
);

    reg [7:0] mem [0:15];
    reg [3:0] waddr_reg, raddr_reg;

    always @(posedge clk) begin
        if (rst) begin
            awready <= 0; wready <= 0; bvalid <= 0;
            arready <= 0; rvalid <= 0;
        end else begin

            // WRITE ADDRESS
            if (awvalid && !awready) begin
                awready   <= 1;
                waddr_reg <= awaddr;
            end else awready <= 0;

            // WRITE DATA
            if (wvalid && !wready) begin
                wready <= 1;
                mem[waddr_reg] <= wdata;
                bvalid <= 1;
            end else wready <= 0;

            if (bvalid && bready)
                bvalid <= 0;

            // READ ADDRESS
            if (arvalid && !arready) begin
                arready   <= 1;
                raddr_reg <= araddr;
                rdata     <= mem[araddr];
                rvalid    <= 1;
            end else arready <= 0;

            if (rvalid && rready)
                rvalid <= 0;
        end
    end
endmodule
