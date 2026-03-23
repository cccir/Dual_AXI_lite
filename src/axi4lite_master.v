module axi4lite_master (
    input  wire       clk,
    input  wire       rst,

    input  wire       start_write,
    input  wire       start_read,
    input  wire [3:0] addr,
    input  wire [7:0] wdata,

    output reg  [7:0] rdata,
    output reg        done,

    // AXI
    output reg [3:0] awaddr,
    output reg       awvalid,
    input  wire      awready,

    output reg [7:0] wdata_o,
    output reg       wvalid,
    input  wire      wready,

    input  wire      bvalid,
    output reg       bready,

    output reg [3:0] araddr,
    output reg       arvalid,
    input  wire      arready,

    input  wire [7:0] rdata_i,
    input  wire       rvalid,
    output reg        rready
);

    typedef enum logic [2:0] {
        IDLE, AW, W, B, AR, R
    } state_t;

    state_t state;

    always @(posedge clk) begin
        if (rst) begin
            state   <= IDLE;
            awvalid <= 0; wvalid <= 0; bready <= 0;
            arvalid <= 0; rready <= 0;
            done    <= 0;
        end else begin
            done <= 0;

            case (state)

            IDLE: begin
                if (start_write) begin
                    awaddr  <= addr;
                    wdata_o <= wdata;
                    awvalid <= 1;
                    state   <= AW;
                end else if (start_read) begin
                    araddr  <= addr;
                    arvalid <= 1;
                    state   <= AR;
                end
            end

            AW: if (awready) begin
                awvalid <= 0;
                wvalid  <= 1;
                state   <= W;
            end

            W: if (wready) begin
                wvalid <= 0;
                bready <= 1;
                state  <= B;
            end

            B: if (bvalid) begin
                bready <= 0;
                done   <= 1;
                state  <= IDLE;
            end

            AR: if (arready) begin
                arvalid <= 0;
                rready  <= 1;
                state   <= R;
            end

            R: if (rvalid) begin
                rdata  <= rdata_i;
                rready <= 0;
                done   <= 1;
                state  <= IDLE;
            end

            endcase
        end
    end
endmodule
