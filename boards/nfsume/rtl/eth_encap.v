module eth_encap (
	input  wire        clk156,
	input  wire        eth_rst,
	output wire [ 7:0] debug,

	input  wire        s_axis_rx0_tvalid,
	input  wire [63:0] s_axis_rx0_tdata,
	input  wire [ 7:0] s_axis_rx0_tkeep,
	input  wire        s_axis_rx0_tlast,
	input  wire        s_axis_rx0_tuser,

	input  wire        m_axis_tx0_tready,
	output wire        m_axis_tx0_tvalid,
	output wire [63:0] m_axis_tx0_tdata,
	output wire [ 7:0] m_axis_tx0_tkeep,
	output wire        m_axis_tx0_tlast,
	output wire        m_axis_tx0_tuser
);

axis_data_fifo_0 u_axis_data_fifo0 (
  .s_axis_aresetn      (!eth_rst),  
  .s_axis_aclk         (clk156),  

  .s_axis_tvalid       (s_axis_rx0_tvalid),
  .s_axis_tready       (), 
  .s_axis_tdata        (s_axis_rx0_tdata), 
  .s_axis_tkeep        (s_axis_rx0_tkeep), 
  .s_axis_tlast        (s_axis_rx0_tlast), 
  .s_axis_tuser        (1'b0),          

  .m_axis_tvalid       (m_axis_tx0_tvalid),
  .m_axis_tready       (m_axis_tx0_tready),
  .m_axis_tdata        (m_axis_tx0_tdata), 
  .m_axis_tkeep        (m_axis_tx0_tkeep), 
  .m_axis_tlast        (m_axis_tx0_tlast), 
  .m_axis_tuser        (m_axis_tx0_tuser), 
  .axis_data_count     (), 
  .axis_wr_data_count  (), 
  .axis_rd_data_count  ()  
);

endmodule

