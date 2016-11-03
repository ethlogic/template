module eth_top (
	input  wire                clk100,
	input  wire                sys_rst,
	output wire [7:0]          debug,

	input  wire                SFP_CLK_P,
	input  wire                SFP_CLK_N,
	output wire                SFP_REC_CLK_P,
	output wire                SFP_REC_CLK_N,

	inout  wire                I2C_FPGA_SCL,
	inout  wire                I2C_FPGA_SDA,

	input  wire                SFP_CLK_ALARM_B,
	// Ether Port 0
	input  wire                ETH0_TX_P,
	input  wire                ETH0_TX_N,
	output wire                ETH0_RX_P,
	output wire                ETH0_RX_N,

	input  wire                ETH0_TX_FAULT,
	input  wire                ETH0_RX_LOS,
	output wire                ETH0_TX_DISABLE
);

/*
 * Ethernet Clock Domain : Clocking
 */
wire clk156;
assign db_clk = clk156;
sfp_refclk_init sfp_refclk_init0 (
	.CLK               (clk100),
	.RST               (sys_rst),
	.SFP_REC_CLK_P     (SFP_REC_CLK_P), //: out std_logic;
	.SFP_REC_CLK_N     (SFP_REC_CLK_N), //: out std_logic;
	.SFP_CLK_ALARM_B   (SFP_CLK_ALARM_B), //: in std_logic;
	.I2C_FPGA_SCL      (I2C_FPGA_SCL), //: inout std_logic;
	.I2C_FPGA_SDA      (I2C_FPGA_SDA)  //: inout std_logic
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
wire        m_axis_tx0_tvalid;
wire        m_axis_tx0_tready;
wire [63:0] m_axis_tx0_tdata;
wire [ 7:0] m_axis_tx0_tkeep;
wire        m_axis_tx0_tlast;
wire        m_axis_tx0_tuser;

/*
 * AXI interface (Slave : MAC ---> encap)
 */
wire        s_axis_rx0_tvalid;
wire [63:0] s_axis_rx0_tdata;
wire [ 7:0] s_axis_rx0_tkeep;
wire        s_axis_rx0_tlast;
wire        s_axis_rx0_tuser;

wire [ 7:0] eth_debug;

eth_encap eth_encap0 (
	.clk156           (clk156),
	.eth_rst          (eth_rst),

	// Port0 
	.s_axis_rx0_tvalid    (s_axis_rx0_tvalid),
	.s_axis_rx0_tdata     (s_axis_rx0_tdata),
	.s_axis_rx0_tkeep     (s_axis_rx0_tkeep),
	.s_axis_rx0_tlast     (s_axis_rx0_tlast),
	.s_axis_rx0_tuser     (s_axis_rx0_tuser),

	.m_axis_tx0_tvalid    (m_axis_tx0_tvalid),
	.m_axis_tx0_tready    (m_axis_tx0_tready),
	.m_axis_tx0_tdata     (m_axis_tx0_tdata),
	.m_axis_tx0_tkeep     (m_axis_tx0_tkeep),
	.m_axis_tx0_tlast     (m_axis_tx0_tlast),
	.m_axis_tx0_tuser     (m_axis_tx0_tuser)
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
	.coreclk_out                   (clk156),
	.refclk_n                      (SFP_CLK_N),
	.refclk_p                      (SFP_CLK_P),
	.dclk                          (clk100),
	.reset                         (eth_rst),
	.rx_statistics_vector          (),
	.rxn                           (ETH0_TX_N),
	.rxp                           (ETH0_TX_P),
	.s_axis_pause_tdata            (16'b0),
	.s_axis_pause_tvalid           (1'b0),
	.signal_detect                 (!ETH0_RX_LOS),
	.tx_disable                    (ETH0_TX_DISABLE),
	.tx_fault                      (ETH0_TX_FAULT),
	.tx_ifg_delay                  (8'd0),
	.tx_statistics_vector          (),
	.txn                           (ETH0_RX_N),
	.txp                           (ETH0_RX_P),

	.rxrecclk_out                  (),
	.resetdone_out                 (),

	// eth tx
	.s_axis_tx_tready              (m_axis_tx0_tready),
	.s_axis_tx_tdata               (m_axis_tx0_tdata),
	.s_axis_tx_tkeep               (m_axis_tx0_tkeep),
	.s_axis_tx_tlast               (m_axis_tx0_tlast),
	.s_axis_tx_tvalid              (m_axis_tx0_tvalid),
	.s_axis_tx_tuser               (m_axis_tx0_tuser),
	
	// eth rx
	.m_axis_rx_tdata               (s_axis_rx0_tdata),
	.m_axis_rx_tkeep               (s_axis_rx0_tkeep),
	.m_axis_rx_tlast               (s_axis_rx0_tlast),
	.m_axis_rx_tuser               (s_axis_rx0_tuser),
	.m_axis_rx_tvalid              (s_axis_rx0_tvalid),

	.sim_speedup_control           (1'b0),
	.rx_axis_aresetn               (!eth_rst),
	.tx_axis_aresetn               (!eth_rst),

	.tx_statistics_valid           (tx_statistics_valid),         
	.rx_statistics_valid           (rx_statistics_valid),
	.pcspma_status                 (pcspma_status),                
	.mac_tx_configuration_vector   (mac_tx_configuration_vector),  
	.mac_rx_configuration_vector   (mac_rx_configuration_vector),  
	.mac_status_vector             (mac_status_vector),            
	.pcs_pma_configuration_vector  (pcs_pma_configuration_vector), 
	.pcs_pma_status_vector         (pcs_pma_status_vector),        
	.areset_datapathclk_out        (areset_coreclk),        
	.txusrclk_out                  (txusrclk),                  
	.txusrclk2_out                 (txusrclk2),                 
	.gttxreset_out                 (gttxreset),
	.gtrxreset_out                 (gtrxreset),
	.txuserrdy_out                 (txuserrdy), 
	.reset_counter_done_out        (reset_counter_done),
	.qplllock_out                  (qplllock     ),       
	.qplloutclk_out                (qplloutclk   ),     
	.qplloutrefclk_out             (qplloutrefclk)  
);

reg [31:0] led_cnt;
always @ (posedge clk156)
	if (eth_rst)
		led_cnt <= 32'd0;
	else 
		led_cnt <= led_cnt + 32'd1;

assign debug = eth_debug;

endmodule

