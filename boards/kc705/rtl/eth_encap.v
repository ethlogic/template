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



assign m_axis_tx0_tvalid = s_axis_rx0_tvalid;
assign m_axis_tx0_tdata  = s_axis_rx0_tdata;
assign m_axis_tx0_tkeep  = s_axis_rx0_tkeep;
assign m_axis_tx0_tlast  = s_axis_rx0_tlast;
assign m_axis_tx0_tuser  = 1'b0;

endmodule

