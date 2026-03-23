module axi4lite_slave (
    input  wire       clk,
    input  wire       rst,

    // Write address channel
    input  wire [3:0] awaddr,
    input  wire       awvalid,
    output reg        awready,

    // Write data channel
    input  wire [7:0] wdata,
    input  wire       wvalid,
    output reg        wready,

    // Write response
    output reg        bvalid,
    input  wire       bready,

    // Read address channel
    input  wire [3:0] araddr,
    input  wire       arvalid,
    output reg        arready,

    // Read data channel
    output reg [7:0]  rdata,
    output reg        rvalid,
    input  wire       rready
);

    // Simple memory
    reg [7:0] mem [0:15];

    // Write buffers
    reg [3:0] awaddr_reg;
    reg [7:0] wdata_reg;
    reg aw_seen;
    reg w_seen;

    integer i;

    // Reset memory (optional but good for simulation)
    initial begin
        for (i = 0; i < 16; i = i + 1)
            mem[i] = 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            awready <= 0;
            wready  <= 0;
            bvalid  <= 0;
            arready <= 0;
            rvalid  <= 0;
            aw_seen <= 0;
            w_seen  <= 0;
        end else begin

            // ---------------- AW CHANNEL ----------------
            if (awvalid && !aw_seen) begin
                awaddr_reg <= awaddr;
                aw_seen <= 1;
                awready <= 1;
            end else begin
                awready <= 0;
            end

            // ---------------- W CHANNEL ----------------
            if (wvalid && !w_seen) begin
                wdata_reg <= wdata;
                w_seen <= 1;
                wready <= 1;
            end else begin
                wready <= 0;
            end

            // ---------------- WRITE COMMIT ----------------
            if (aw_seen && w_seen && !bvalid) begin
                mem[awaddr_reg] <= wdata_reg;
                bvalid <= 1;
                aw_seen <= 0;
                w_seen  <= 0;
            end

            // ---------------- WRITE RESPONSE ----------------
            if (bvalid && bready) begin
                bvalid <= 0;
            end

            // ---------------- READ ADDRESS ----------------
            if (arvalid && !rvalid) begin
                arready <= 1;
                rdata <= mem[araddr];
                rvalid <= 1;
            end else begin
                arready <= 0;
            end

            // ---------------- READ DATA ----------------
            if (rvalid && rready) begin
                rvalid <= 0;
            end
        end
    end

endmodule
