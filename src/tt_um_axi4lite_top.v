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
    wire m0_awvalid, m0_wvalid, m0_bready;
    wire m0_arvalid, m0_rready;

    wire m0_awready, m0_wready, m0_bvalid;
    wire m0_arready, m0_rvalid;
    wire [7:0] m0_rdata;

    // =========================
    // MASTER 1 SIGNALS
    // =========================
    wire [3:0] m1_awaddr, m1_araddr;
    wire m1_awvalid, m1_wvalid, m1_bready;
    wire m1_arvalid, m1_rready;

    wire m1_awready, m1_wready, m1_bvalid;
    wire m1_arready, m1_rvalid;
    wire [7:0] m1_rdata;

    // =========================
    // INTERCONNECT SIGNALS
    // =========================
    wire [3:0] awaddr_mux;
    wire awvalid_mux, awready_mux;

    wire [3:0] araddr_mux;
    wire arvalid_mux, arready_mux;

    wire select_master;
    wire select_slave;

    // =========================
    // MASTER INSTANCES
    // =========================
    axi4lite_master master0 (
        .clk(clk), .rst(rst),
        .start_write(ui_in[0]),
        .start_read(ui_in[1]),
        .write_addr(ui_in[5:2]),
        .read_addr(ui_in[5:2]),
        .awaddr(m0_awaddr),
        .awvalid(m0_awvalid),
        .awready(m0_awready),
        .wvalid(m0_wvalid),
        .wready(m0_wready),
        .bvalid(m0_bvalid),
        .bready(m0_bready),
        .araddr(m0_araddr),
        .arvalid(m0_arvalid),
        .arready(m0_arready),
        .rdata(m0_rdata),
        .rvalid(m0_rvalid),
        .rready(m0_rready)
    );

    axi4lite_master master1 (
        .clk(clk), .rst(rst),
        .start_write(uio_in[0]),
        .start_read(uio_in[1]),
        .write_addr(uio_in[5:2]),
        .read_addr(uio_in[5:2]),
        .awaddr(m1_awaddr),
        .awvalid(m1_awvalid),
        .awready(m1_awready),
        .wvalid(m1_wvalid),
        .wready(m1_wready),
        .bvalid(m1_bvalid),
        .bready(m1_bready),
        .araddr(m1_araddr),
        .arvalid(m1_arvalid),
        .arready(m1_arready),
        .rdata(m1_rdata),
        .rvalid(m1_rvalid),
        .rready(m1_rready)
    );

    // =========================
    // ARBITER (FIXED PRIORITY)
    // =========================
    assign select_master = (m0_awvalid | m0_arvalid) ? 0 : 1;

    // =========================
    // MUX MASTER → BUS
    // =========================
    assign awaddr_mux  = (select_master == 0) ? m0_awaddr  : m1_awaddr;
    assign awvalid_mux = (select_master == 0) ? m0_awvalid : m1_awvalid;

    assign araddr_mux  = (select_master == 0) ? m0_araddr  : m1_araddr;
    assign arvalid_mux = (select_master == 0) ? m0_arvalid : m1_arvalid;

    // =========================
    // SLAVE SELECT (ADDRESS DECODE)
    // =========================
    assign select_slave = awaddr_mux[3]; // MSB decides slave

    // =========================
    // SLAVE SIGNALS
    // =========================
    wire s0_awready, s1_awready;
    wire s0_arready, s1_arready;
    wire [7:0] s0_rdata, s1_rdata;
    wire s0_rvalid, s1_rvalid;

    // =========================
    // ROUTE TO SLAVES
    // =========================
    axi4lite_slave slave0 (
        .clk(clk), .rst(rst),
        .awaddr(awaddr_mux),
        .awvalid(awvalid_mux & ~select_slave),
        .awready(s0_awready),
        .araddr(araddr_mux),
        .arvalid(arvalid_mux & ~select_slave),
        .arready(s0_arready),
        .rdata(s0_rdata),
        .rvalid(s0_rvalid)
    );

    axi4lite_slave slave1 (
        .clk(clk), .rst(rst),
        .awaddr(awaddr_mux),
        .awvalid(awvalid_mux & select_slave),
        .awready(s1_awready),
        .araddr(araddr_mux),
        .arvalid(arvalid_mux & select_slave),
        .arready(s1_arready),
        .rdata(s1_rdata),
        .rvalid(s1_rvalid)
    );

    // =========================
    // RETURN PATH
    // =========================
    assign m0_awready = (select_master==0) ? (select_slave ? s1_awready : s0_awready) : 0;
    assign m1_awready = (select_master==1) ? (select_slave ? s1_awready : s0_awready) : 0;

    assign m0_arready = (select_master==0) ? (select_slave ? s1_arready : s0_arready) : 0;
    assign m1_arready = (select_master==1) ? (select_slave ? s1_arready : s0_arready) : 0;

    assign m0_rdata = (select_slave ? s1_rdata : s0_rdata);
    assign m1_rdata = (select_slave ? s1_rdata : s0_rdata);

    assign m0_rvalid = (select_master==0) ? (select_slave ? s1_rvalid : s0_rvalid) : 0;
    assign m1_rvalid = (select_master==1) ? (select_slave ? s1_rvalid : s0_rvalid) : 0;

    // =========================
    // OUTPUT
    // =========================
    assign uo_out  = m0_rdata;
    assign uio_out = m1_rdata;

endmodule
