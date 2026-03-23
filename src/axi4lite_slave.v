module axi4lite_slave #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input  wire                   clk,
    input  wire                   rst,

    // WRITE ADDRESS CHANNEL
    input  wire [ADDR_WIDTH-1:0]  awaddr,
    input  wire                   awvalid,
    output reg                    awready,

    // WRITE DATA CHANNEL
    input  wire [DATA_WIDTH-1:0]  wdata,
    input  wire                   wvalid,
    output reg                    wready,

    // WRITE RESPONSE CHANNEL
    output reg                    bvalid,
    input  wire                   bready,

    // READ ADDRESS CHANNEL
    input  wire [ADDR_WIDTH-1:0]  araddr,
    input  wire                   arvalid,
    output reg                    arready,

    // READ DATA CHANNEL
    output reg [DATA_WIDTH-1:0]   rdata,
    output reg                    rvalid,
    input  wire                   rready
);

    // ================= MEMORY =================
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // ================= WRITE REGISTERS =================
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg aw_seen, w_seen;

    // ================= WRITE CHANNEL =================
    always @(posedge clk) begin
        if (rst) begin
            awready <= 0;
            wready  <= 0;
            bvalid  <= 0;
            aw_seen <= 0;
            w_seen  <= 0;
        end
        else begin

            // ---- AW HANDSHAKE ----
            if (awvalid && !aw_seen) begin
                awaddr_reg <= awaddr;
                aw_seen <= 1;
                awready <= 1;
            end
            else
                awready <= 0;

            // ---- W HANDSHAKE ----
            if (wvalid && !w_seen) begin
                wdata_reg <= wdata;
                w_seen <= 1;
                wready <= 1;
            end
            else
                wready <= 0;

            // ---- WRITE COMMIT ----
            if (aw_seen && w_seen && !bvalid) begin
                mem[awaddr_reg] <= wdata_reg;
                bvalid <= 1;
                aw_seen <= 0;
                w_seen  <= 0;
            end

            // ---- WRITE RESPONSE COMPLETE ----
            if (bvalid && bready)
                bvalid <= 0;
        end
    end

    // ================= READ CHANNEL =================
    always @(posedge clk) begin
        if (rst) begin
            arready <= 0;
            rvalid  <= 0;
            rdata   <= 0;
        end
        else begin
            if (arvalid && !rvalid) begin
                rdata   <= mem[araddr];
                rvalid  <= 1;
                arready <= 1;
            end
            else
                arready <= 0;

            if (rvalid && rready)
                rvalid <= 0;
        end
    end

endmodule
