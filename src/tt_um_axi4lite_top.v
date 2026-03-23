module tt_um_axi4lite_top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       ena,

    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,

    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe
);

    wire rst = ~rst_n;

    assign uio_oe = 8'hFF;

    // ---------------- MASTER WIRES ----------------
    wire [3:0] m0_awaddr, m1_awaddr;
    wire [3:0] m0_araddr, m1_araddr;
    wire [7:0] m0_wdata,  m1_wdata;

    wire m0_awvalid, m1_awvalid;
    wire m0_wvalid,  m1_wvalid;
    wire m0_bready,  m1_bready;
    wire m0_arvalid, m1_arvalid;
    wire m0_rready,  m1_rready;

    wire m0_awready, m1_awready;
    wire m0_wready,  m1_wready;
    wire m0_bvalid,  m1_bvalid;
    wire m0_arready, m1_arready;
    wire m0_rvalid,  m1_rvalid;

    wire [7:0] m0_rdata_i, m1_rdata_i;

    // ---------------- MASTER INST ----------------
    axi4lite_master m0 (
        .clk(clk), .rst(rst),
        .start_write(ui_in[0]),
        .start_read(ui_in[1]),
        .addr(ui_in[5:2]),
        .wdata(uio_in),
        .rdata(uo_out),

        .awaddr(m0_awaddr), .awvalid(m0_awvalid), .awready(m0_awready),
        .wdata_o(m0_wdata), .wvalid(m0_wvalid), .wready(m0_wready),
        .bvalid(m0_bvalid), .bready(m0_bready),
        .araddr(m0_araddr), .arvalid(m0_arvalid), .arready(m0_arready),
        .rdata_i(m0_rdata_i), .rvalid(m0_rvalid), .rready(m0_rready)
    );

    axi4lite_master m1 (
        .clk(clk), .rst(rst),
        .start_write(uio_in[0]),
        .start_read(uio_in[1]),
        .addr(uio_in[5:2]),
        .wdata(ui_in),
        .rdata(uio_out),

        .awaddr(m1_awaddr), .awvalid(m1_awvalid), .awready(m1_awready),
        .wdata_o(m1_wdata), .wvalid(m1_wvalid), .wready(m1_wready),
        .bvalid(m1_bvalid), .bready(m1_bready),
        .araddr(m1_araddr), .arvalid(m1_arvalid), .arready(m1_arready),
        .rdata_i(m1_rdata_i), .rvalid(m1_rvalid), .rready(m1_rready)
    );

    // ---------------- SIMPLE ARBITER ----------------
    reg sel; // 0 = M0, 1 = M1

    always @(posedge clk)
        if (rst) sel <= 0;
        else if (m1_awvalid | m1_arvalid) sel <= 1;
        else if (m0_awvalid | m0_arvalid) sel <= 0;

    wire use_m0 = (sel == 0);

    // ---------------- MUX ----------------
    wire [3:0] awaddr = use_m0 ? m0_awaddr : m1_awaddr;
    wire [7:0] wdata  = use_m0 ? m0_wdata  : m1_wdata;
    wire awvalid = use_m0 ? m0_awvalid : m1_awvalid;
    wire wvalid  = use_m0 ? m0_wvalid  : m1_wvalid;
    wire bready  = use_m0 ? m0_bready  : m1_bready;

    wire [3:0] araddr = use_m0 ? m0_araddr : m1_araddr;
    wire arvalid = use_m0 ? m0_arvalid : m1_arvalid;
    wire rready  = use_m0 ? m0_rready  : m1_rready;

    wire sel_w = awaddr[3];
    wire sel_r = araddr[3];

    // ---------------- SLAVES ----------------
    wire [7:0] s0_rdata, s1_rdata;
    wire s0_rvalid, s1_rvalid;
    wire s0_awready, s1_awready;
    wire s0_wready,  s1_wready;
    wire s0_bvalid,  s1_bvalid;
    wire s0_arready, s1_arready;

    axi4lite_slave s0 (
        .clk(clk), .rst(rst),
        .awaddr(awaddr), .awvalid(awvalid & ~sel_w), .awready(s0_awready),
        .wdata(wdata), .wvalid(wvalid & ~sel_w), .wready(s0_wready),
        .bvalid(s0_bvalid), .bready(bready),
        .araddr(araddr), .arvalid(arvalid & ~sel_r), .arready(s0_arready),
        .rdata(s0_rdata), .rvalid(s0_rvalid), .rready(rready)
    );

    axi4lite_slave s1 (
        .clk(clk), .rst(rst),
        .awaddr(awaddr), .awvalid(awvalid & sel_w), .awready(s1_awready),
        .wdata(wdata), .wvalid(wvalid & sel_w), .wready(s1_wready),
        .bvalid(s1_bvalid), .bready(bready),
        .araddr(araddr), .arvalid(arvalid & sel_r), .arready(s1_arready),
        .rdata(s1_rdata), .rvalid(s1_rvalid), .rready(rready)
    );

    // ---------------- RETURN ----------------
    assign m0_awready = use_m0 ? (sel_w ? s1_awready : s0_awready) : 0;
    assign m1_awready = !use_m0 ? (sel_w ? s1_awready : s0_awready) : 0;

    assign m0_wready = use_m0 ? (sel_w ? s1_wready : s0_wready) : 0;
    assign m1_wready = !use_m0 ? (sel_w ? s1_wready : s0_wready) : 0;

    assign m0_bvalid = use_m0 ? (sel_w ? s1_bvalid : s0_bvalid) : 0;
    assign m1_bvalid = !use_m0 ? (sel_w ? s1_bvalid : s0_bvalid) : 0;

    assign m0_arready = use_m0 ? (sel_r ? s1_arready : s0_arready) : 0;
    assign m1_arready = !use_m0 ? (sel_r ? s1_arready : s0_arready) : 0;

    assign m0_rvalid = use_m0 ? (sel_r ? s1_rvalid : s0_rvalid) : 0;
    assign m1_rvalid = !use_m0 ? (sel_r ? s1_rvalid : s0_rvalid) : 0;

    assign m0_rdata_i = use_m0 ? (sel_r ? s1_rdata : s0_rdata) : 0;
    assign m1_rdata_i = !use_m0 ? (sel_r ? s1_rdata : s0_rdata) : 0;

endmodule
