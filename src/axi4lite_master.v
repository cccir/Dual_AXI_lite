module axi4lite_master (
    input clk,
    input rst,

    input start_write,
    input start_read,
    input [3:0] addr,
    input [7:0] wdata,

    output reg [7:0] rdata,
    output reg done,

    // AXI
    output reg [3:0] awaddr,
    output reg awvalid,
    input awready,

    output reg [7:0] wdata_o,
    output reg wvalid,
    input wready,

    input bvalid,
    output reg bready,

    output reg [3:0] araddr,
    output reg arvalid,
    input arready,

    input [7:0] rdata_i,
    input rvalid,
    output reg rready
);

localparam IDLE=0, WA=1, WD=2, WR=3, RA=4, RD=5;
reg [2:0] state;

always @(posedge clk) begin
    if (rst) begin
        state   <= IDLE;
        done    <= 0;

        awvalid <= 0;
        wvalid  <= 0;
        bready  <= 0;
        arvalid <= 0;
        rready  <= 0;
    end else begin

        // DEFAULTS (VERY IMPORTANT)
        done <= 0;

        case(state)

        // =====================
        IDLE
        // =====================
        IDLE: begin
            if(start_write)
                state <= WA;
            else if(start_read)
                state <= RA;
        end

        // =====================
        WRITE ADDRESS
        // =====================
        WA: begin
            awaddr  <= addr;
            awvalid <= 1;

            if(awvalid && awready) begin
                awvalid <= 0;
                state   <= WD;
            end
        end

        // =====================
        WRITE DATA
        // =====================
        WD: begin
            wdata_o <= wdata;
            wvalid  <= 1;

            if(wvalid && wready) begin
                wvalid <= 0;
                state  <= WR;
            end
        end

        // =====================
        WRITE RESPONSE
        // =====================
        WR: begin
            bready <= 1;

            if(bvalid && bready) begin
                bready <= 0;
                done   <= 1;
                state  <= IDLE;
            end
        end

        // =====================
        READ ADDRESS
        // =====================
        RA: begin
            araddr  <= addr;
            arvalid <= 1;

            if(arvalid && arready) begin
                arvalid <= 0;
                state   <= RD;
            end
        end

        // =====================
        READ DATA
        // =====================
        RD: begin
            rready <= 1;

            if(rvalid && rready) begin
                rdata  <= rdata_i;
                rready <= 0;
                done   <= 1;
                state  <= IDLE;
            end
        end

        endcase
    end
end

endmodule
