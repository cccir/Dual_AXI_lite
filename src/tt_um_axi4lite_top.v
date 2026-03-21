module tt_um_axi4lite_top (
    input  wire clk,
    input  wire rst,

    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,

    input  wire [7:0] uio_in,
    output wire [7:0] uio_out
);

    // =========================
    // MASTER 0 SIGNALS
    // =========================
    wire [3:0] m0_awaddr, m0_araddr;
    wire [7:0] m0_wdata;
    wire m0_awvalid, m0_wvalid, m0_bready;
    wire m0_arvalid, m0_rready;

    wire m0_awready, m0_wready, m0_bvalid;
    wire m0_arready, m0_rvalid;
    wire [7:0] m0_rdata;

    // =========================
    // MASTER 1 SIGNALS
    // =========================
    wire [3:0] m1_awaddr, m1_araddr;
    wire [7:0] m1_wdata;
    wire m1_awvalid, m1_wvalid, m1_bready;
    wire m1_arvalid, m1_rready;

    wire m1_awready, m1_wready, m1_bvalid;
    wire m1_arready, m1_rvalid;
    wire [7:0] m1_rdata;

    // =========================
    // MASTER INSTANCES
    // =========================
    axi4lite_master master0 (
        .clk(clk), .rst(rst),
        .start_write(ui_in[0]),
        .start_read(ui_in[1]),
        .addr(ui_in[5:2]),
        .wdata(uio_in),

        .rdata(), .done(),

        .awaddr(m0_awaddr),
        .awvalid(m0_awvalid),
        .awready(m0_awready),

        .wdata_o(m0_wdata),
        .wvalid(m0_wvalid),
        .wready(m0_wready),

        .bvalid(m0_bvalid),
        .bready(m0_bready),

        .araddr(m0_araddr),
        .arvalid(m0_arvalid),
        .arready(m0_arready),

        .rdata_i(m0_rdata),
        .rvalid(m0_rvalid),
        .rready(m0_rready)
    );

    axi4lite_master master1 (
        .clk(clk), .rst(rst),
        .start_write(uio_in[0]),
        .start_read(uio_in[1]),
        .addr(uio_in[5:2]),
        .wdata(ui_in),

        .rdata(), .done(),

        .awaddr(m1_awaddr),
        .awvalid(m1_awvalid),
        .awready(m1_awready),

        .wdata_o(m1_wdata),
        .wvalid(m1_wvalid),
        .wready(m1_wready),

        .bvalid(m1_bvalid),
        .bready(m1_bready),

        .araddr(m1_araddr),
        .arvalid(m1_arvalid),
        .arready(m1_arready),

        .rdata_i(m1_rdata),
        .rvalid(m1_rvalid),
        .rready(m1_rready)
    );

    // =========================
    // ARBITER (M0 PRIORITY)
    // =========================
    wire use_m0 = m0_awvalid | m0_arvalid;

    // =========================
    // MUX MASTER → BUS
    // =========================
    wire [3:0] awaddr_mux  = use_m0 ? m0_awaddr  : m1_awaddr;
    wire       awvalid_mux = use_m0 ? m0_awvalid : m1_awvalid;

    wire [7:0] wdata_mux   = use_m0 ? m0_wdata   : m1_wdata;
    wire       wvalid_mux  = use_m0 ? m0_wvalid  : m1_wvalid;

    wire       bready_mux  = use_m0 ? m0_bready  : m1_bready;

    wire [3:0] araddr_mux  = use_m0 ? m0_araddr  : m1_araddr;
    wire       arvalid_mux = use_m0 ? m0_arvalid : m1_arvalid;

    wire       rready_mux  = use_m0 ? m0_rready  : m1_rready;

    // =========================
    // SLAVE SELECT
    // =========================
    wire sel = awaddr_mux[3];

    // =========================
    // SLAVE SIGNALS
    // =========================
    wire s0_awready, s1_awready;
    wire s0_wready,  s1_wready;
    wire s0_bvalid,  s1_bvalid;

    wire s0_arready, s1_arready;
    wire s0_rvalid,  s1_rvalid;
    wire [7:0] s0_rdata, s1_rdata;

    // =========================
    // SLAVE INSTANCES
    // =========================
    axi4lite_slave slave0 (
        .clk(clk), .rst(rst),
        .awaddr(awaddr_mux),
        .awvalid(awvalid_mux & ~sel),
        .awready(s0_awready),

        .wdata(wdata_mux),
        .wvalid(wvalid_mux & ~sel),
        .wready(s0_wready),

        .bvalid(s0_bvalid),
        .bready(bready_mux & ~sel),

        .araddr(araddr_mux),
        .arvalid(arvalid_mux & ~sel),
        .arready(s0_arready),

        .rdata(s0_rdata),
        .rvalid(s0_rvalid),
        .rready(rready_mux & ~sel)
    );

    axi4lite_slave slave1 (
        .clk(clk), .rst(rst),
        .awaddr(awaddr_mux),
        .awvalid(awvalid_mux & sel),
        .awready(s1_awready),

        .wdata(wdata_mux),
        .wvalid(wvalid_mux & sel),
        .wready(s1_wready),

        .bvalid(s1_bvalid),
        .bready(bready_mux & sel),

        .araddr(araddr_mux),
        .arvalid(arvalid_mux & sel),
        .arready(s1_arready),

        .rdata(s1_rdata),
        .rvalid(s1_rvalid),
        .rready(rready_mux & sel)
    );

    // =========================
    // RETURN PATH
    // =========================
    assign m0_awready = use_m0 ? (sel ? s1_awready : s0_awready) : 0;
    assign m1_awready = ~use_m0 ? (sel ? s1_awready : s0_awready) : 0;

    assign m0_wready  = use_m0 ? (sel ? s1_wready  : s0_wready)  : 0;
    assign m1_wready  = ~use_m0 ? (sel ? s1_wready : s0_wready)  : 0;

    assign m0_bvalid  = use_m0 ? (sel ? s1_bvalid  : s0_bvalid)  : 0;
    assign m1_bvalid  = ~use_m0 ? (sel ? s1_bvalid : s0_bvalid)  : 0;

    assign m0_arready = use_m0 ? (sel ? s1_arready : s0_arready) : 0;
    assign m1_arready = ~use_m0 ? (sel ? s1_arready : s0_arready) : 0;

    assign m0_rvalid  = use_m0 ? (sel ? s1_rvalid  : s0_rvalid)  : 0;
    assign m1_rvalid  = ~use_m0 ? (sel ? s1_rvalid : s0_rvalid)  : 0;

    assign m0_rdata   = sel ? s1_rdata : s0_rdata;
    assign m1_rdata   = sel ? s1_rdata : s0_rdata;

    // =========================
    // OUTPUT
    // =========================
    assign uo_out  = m0_rdata;
    assign uio_out = m1_rdata;

endmodule
