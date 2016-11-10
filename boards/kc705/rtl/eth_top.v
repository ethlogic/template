module eth_top (
	input  wire                clk100,
	input  wire                sys_rst,
	output wire [7:0]          debug,

	input  wire                SFP_CLK_P,
	input  wire                SFP_CLK_N,

	inout  wire                I2C_FPGA_SCL,
	inout  wire                I2C_FPGA_SDA,
	output  wire               I2C_FPGA_RST_N,
	output  wire               SI5324_RST_N,

	// Ether Port 0
	input  wire                ETH0_TX_P,
	input  wire                ETH0_TX_N,
	output wire                ETH0_RX_P,
	output wire                ETH0_RX_N,

	//input  wire                ETH0_TX_FAULT,
	//input  wire                ETH0_RX_LOS,
	output wire                ETH0_TX_DISABLE
);

/*
 * Ethernet Clock Domain : Clocking
 */
wire clk50;			
reg div_clk50 = 0;
always @ (posedge clk100)
		div_clk50 <= ~div_clk50;

BUFG clk50_bufg (
	.I(div_clk50),
	.O(clk50)
);

wire clk156;
clock_control u_clk_control (
	.i2c_clk       (I2C_FPGA_SCL),
	.i2c_data      (I2C_FPGA_SDA),
	.i2c_mux_rst_n (I2C_FPGA_RST_N),
	.si5324_rst_n  (SI5324_RST_N),
	.rst           (sys_rst),
	.clk50         (clk50)
);

/*
 *  Ethernet Clock Domain : Reset
 */
reg [13:0] cold_counter = 0; 
reg        eth_rst;
always @(posedge clk156) 
	if (cold_counter != 14'h3fff) begin
		cold_counter <= cold_counter + 14'd1;
		eth_rst      <= 1'b1;
	end else
		eth_rst <= 1'b0;


/*
 * Ethernet MAC and PCS/PMA Configuration
 */

wire [535:0] pcs_pma_configuration_vector;
pcs_pma_conf pcs_pma_conf0(
	.pcs_pma_configuration_vector(pcs_pma_configuration_vector)
);

wire [79:0] mac_tx_configuration_vector;
wire [79:0] mac_rx_configuration_vector;
eth_mac_conf eth_mac_conf0(
	.mac_tx_configuration_vector(mac_tx_configuration_vector),
	.mac_rx_configuration_vector(mac_rx_configuration_vector)
);

/*
 * AXI interface (Master : encap ---> MAC)
 */
wire        m_axis_tx_tvalid;
wire        m_axis_tx_tready;
wire [63:0] m_axis_tx_tdata;
wire [ 7:0] m_axis_tx_tkeep;
wire        m_axis_tx_tlast;
wire        m_axis_tx_tuser;

/*
 * AXI interface (Slave : MAC ---> encap)
 */
wire        s_axis_rx_tvalid;
wire [63:0] s_axis_rx_tdata;
wire [ 7:0] s_axis_rx_tkeep;
wire        s_axis_rx_tlast;
wire        s_axis_rx_tuser;

wire [ 7:0] eth_debug;

eth_encap eth_encap0 (
	.clk156           (clk156),
	.eth_rst          (eth_rst),

	// Port0 
	.s_axis_rx0_tvalid    (s_axis_rx_tvalid),
	.s_axis_rx0_tdata     (s_axis_rx_tdata),
	.s_axis_rx0_tkeep     (s_axis_rx_tkeep),
	.s_axis_rx0_tlast     (s_axis_rx_tlast),
	.s_axis_rx0_tuser     (s_axis_rx_tuser),

	.m_axis_tx0_tvalid    (m_axis_tx_tvalid),
	.m_axis_tx0_tready    (m_axis_tx_tready),
	.m_axis_tx0_tdata     (m_axis_tx_tdata),
	.m_axis_tx0_tkeep     (m_axis_tx_tkeep),
	.m_axis_tx0_tlast     (m_axis_tx_tlast),
	.m_axis_tx0_tuser     (m_axis_tx_tuser)
);


/*
 * Ethernet MAC
 */
wire txusrclk, txusrclk2;
wire gttxreset, gtrxreset;
wire txuserrdy;
wire areset_coreclk;
wire reset_counter_done;
wire qplllock, qplloutclk, qplloutrefclk;
wire [447:0] pcs_pma_status_vector;
wire [1:0] mac_status_vector;
wire [7:0] pcspma_status;
wire rx_statistics_valid, tx_statistics_valid;


axi_10g_ethernet_0 u_axi_10g_ethernet_0 (
	.tx_axis_aresetn             (!eth_rst),        // input wire tx_axis_aresetn
	.rx_axis_aresetn             (!eth_rst),        // input wire rx_axis_aresetn
	.tx_ifg_delay                (8'd0),            // input wire [7 : 0] tx_ifg_delay
	.dclk                        (clk50),          // input wire dclk
	.txp                         (ETH0_RX_P),       // output wire txp
	.txn                         (ETH0_RX_N),       // output wire txn
	.rxp                         (ETH0_TX_P),       // input wire rxp
	.rxn                         (ETH0_TX_N),       // input wire rxn
	.signal_detect               (1'b1),            // input wire signal_detect
	.tx_fault                    (1'b0),            // input wire tx_fault
	.tx_disable                  (ETH0_TX_DISABLE), // output wire tx_disable
	.pcspma_status               (),                // output wire [7 : 0] pcspma_status
	.sim_speedup_control         (1'b0),            // input wire sim_speedup_control
	.rxrecclk_out                (),                // output wire rxrecclk_out
	.mac_tx_configuration_vector (mac_tx_configuration_vector),   // input wire [79 : 0] mac_tx_configuration_vector
	.mac_rx_configuration_vector (mac_rx_configuration_vector),   // input wire [79 : 0] mac_rx_configuration_vector
	.mac_status_vector           (mac_status_vector),             // output wire [1 : 0] mac_status_vector
	.pcs_pma_configuration_vector(pcs_pma_configuration_vector),  // input wire [535 : 0] pcs_pma_configuration_vector
	.pcs_pma_status_vector       (),           // output wire [447 : 0] pcs_pma_status_vector
	.areset_datapathclk_out      (),           // output wire areset_datapathclk_out
	.txusrclk_out                (),           // output wire txusrclk_out
	.txusrclk2_out               (),           // output wire txusrclk2_out
	.gttxreset_out               (),           // output wire gttxreset_out
	.gtrxreset_out               (),           // output wire gtrxreset_out
	.txuserrdy_out               (),           // output wire txuserrdy_out
	.coreclk_out                 (clk156),     // output wire coreclk_out
	.resetdone_out               (),           // output wire resetdone_out
	.reset_counter_done_out      (),           // output wire reset_counter_done_out
	.qplllock_out                (),           // output wire qplllock_out
	.qplloutclk_out              (),           // output wire qplloutclk_out
	.qplloutrefclk_out           (),           // output wire qplloutrefclk_out
	.refclk_p                    (SFP_CLK_P),  // input wire refclk_p
	.refclk_n                    (SFP_CLK_N),  // input wire refclk_n
	.reset                       (eth_rst),    // input wire reset
	// AXI stream
	.s_axis_tx_tdata             (m_axis_tx_tdata),      // input wire [63 : 0] s_axis_tx_tdata
	.s_axis_tx_tkeep             (m_axis_tx_tkeep),      // input wire [7 : 0] s_axis_tx_tkeep
	.s_axis_tx_tlast             (m_axis_tx_tlast),      // input wire s_axis_tx_tlast
	.s_axis_tx_tready            (m_axis_tx_tready),     // output wire s_axis_tx_tready
	.s_axis_tx_tuser             (m_axis_tx_tuser),      // input wire [0 : 0] s_axis_tx_tuser
	.s_axis_tx_tvalid            (m_axis_tx_tvalid),     // input wire s_axis_tx_tvalid
	.s_axis_pause_tdata          (16'd0),   // input wire [15 : 0] s_axis_pause_tdata
	.s_axis_pause_tvalid         (1'd0),  // input wire s_axis_pause_tvalid

	.m_axis_rx_tdata             (s_axis_rx_tdata),    // output wire [63 : 0] m_axis_rx_tdata
	.m_axis_rx_tkeep             (s_axis_rx_tkeep),    // output wire [7 : 0] m_axis_rx_tkeep
	.m_axis_rx_tlast             (s_axis_rx_tlast),    // output wire m_axis_rx_tlast
	.m_axis_rx_tuser             (s_axis_rx_tuser),    // output wire m_axis_rx_tuser
	.m_axis_rx_tvalid            (s_axis_rx_tvalid),   // output wire m_axis_rx_tvalid

	.tx_statistics_valid         (),      // output wire tx_statistics_valid
	.tx_statistics_vector        (),    // output wire [25 : 0] tx_statistics_vector
	.rx_statistics_valid         (),      // output wire rx_statistics_valid
	.rx_statistics_vector        ()    // output wire [29 : 0] rx_statistics_vector
);


reg [31:0] led_cnt;
always @ (posedge clk156)
	if (eth_rst)
		led_cnt <= 32'd0;
	else 
		led_cnt <= led_cnt + 32'd1;

assign debug = eth_debug;
 
endmodule

