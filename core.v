`timescale 1us/1ps
module core(
	input clk,
	input rst,
	output[7:0] pin_out,	
	input[7:0] pin_in
 );

wire clk0;   

PLL pll(
.sub (32'd24),
.clk (clk),
.rst (rst),
.clk_out (clk0)
);   


R8051 cpu(
.clk (clk0),
.rst (~rst),
.pin_out (pin_out),
.pin_in (pin_in)
);
endmodule



module PLL(
	input[31:0] sub,
	input clk,
	input rst,
	output reg clk_out
);
reg[31:0] cnt;

initial begin
	cnt = 32'd1;
	clk_out = 0;
end

always @(posedge clk or negedge rst) begin
	if (rst == 0) begin
		cnt = 32'd1;
		clk_out = 0;
	end
	else if(cnt < sub) begin
		cnt = cnt + 1;
	end
	else if(cnt >= sub) begin
		clk_out = ~clk_out;
		cnt = 32'd1;
	end
end
endmodule


`timescale 1 ns/1 ps
`define PERIOD 10 
`define HALF_PERIOD (`PERIOD/2)
//`define TYPE8052
`define CODE_FILE "demo.list"

module R8051(
	input clk, 
	input rst,		
	output[7:0] pin_out,
	input[7:0] pin_in
);

wire            rom_en;
wire [15:0]     rom_addr;
reg  [7:0]      rom_byte;
reg             rom_vld;

wire            ram_rd_en_data;
wire            ram_rd_en_sfr;
wire            ram_rd_en_xdata;
wire [15:0]     ram_rd_addr;

reg  [7:0]      ram_rd_byte;

wire            ram_wr_en_data;
wire            ram_wr_en_sfr;
wire            ram_wr_en_xdata;
wire [15:0]     ram_wr_addr;
wire [7:0]      ram_wr_byte;


r8051 u_cpu (
    .clk                  (    clk              ),
	.rst                  (    rst              ),
	.cpu_en               (    1'b1             ),
	.cpu_restart          (    1'b0             ),
	
	.rom_en               (    rom_en           ),
	.rom_addr             (    rom_addr         ),
	.rom_byte             (    rom_byte         ),
	.rom_vld              (    rom_vld          ),
	
	.ram_rd_en_data       (    ram_rd_en_data   ),
	.ram_rd_en_sfr        (    ram_rd_en_sfr    ),
	.ram_rd_en_xdata      (    ram_rd_en_xdata  ),
	.ram_rd_addr          (    ram_rd_addr      ),
	.ram_rd_byte          (    ram_rd_byte      ),
	.ram_rd_vld           (    1'b1             ),
	
	.ram_wr_en_data       (    ram_wr_en_data   ),
	.ram_wr_en_sfr        (    ram_wr_en_sfr    ),
	.ram_wr_en_xdata      (    ram_wr_en_xdata  ),
	.ram_wr_addr          (    ram_wr_addr      ),
	.ram_wr_byte          (    ram_wr_byte      )

);

reg [7:0] rom[(1'b1<<16)-1:0];



integer fd,fx;
initial begin
	$readmemh(`CODE_FILE,rom,0,1000);
  	//fd = $fopen(`CODE_FILE,"rb"); 
  	//fx = $fread(rom,fd);
	//$fclose(fd);
end
	
always @ ( posedge clk )
	if ( rom_en )
    	rom_byte <=  rom[rom_addr];
	else; 

	always @ ( posedge clk )
		rom_vld <=  rom_en;


reg [7:0] data[127:0];
reg [7:0] data_rd_byte;

initial begin
	data[127] = 8'hff;
end	

assign pin_out = data[127];

//读内存
always @ ( posedge clk ) begin
	if ( ram_rd_en_data )begin
    	data_rd_byte <=  data[ram_rd_addr[6:0]];
	end
end
//写内存 
always @ ( posedge clk ) begin
	data[126] = pin_in;
	if ( ram_wr_en_data )begin
    	data[ram_wr_addr[6:0]] <=  ram_wr_byte;			
	end
end

reg [7:0] xdata [127:0];
reg [7:0] xdata_rd_byte;

always @ ( posedge clk )
	if ( ram_rd_en_xdata )
    	xdata_rd_byte <=  xdata[ram_rd_addr[6:0]];
else;

//always @ ( posedge clk )
//	if ( ram_wr_en_xdata )
//    	if (( ram_wr_addr[6:0]==8'h7f ) & ram_wr_byte[0] ) begin
//		    repeat(1000) @ (posedge clk);
//			$display("Test over, simulation is OK!");
//			$stop(1);
//			end
//		else
//	        xdata[ram_wr_addr[6:0]] <=  ram_wr_byte;
//else;


reg [7:0] sfr_rd_byte;

//always @ ( posedge clk )
//	if ( ram_wr_en_sfr & ( ram_wr_addr[7:0]==8'h99 ) )
//    	$write("%s",ram_wr_byte);
//else;


//always @ ( posedge clk )
//	if ( ram_rd_en_sfr ) 
//    	if ( ram_rd_addr[7:0]==8'h98 )
//	    	sfr_rd_byte <=  8'h3;
//		else if ( ram_rd_addr[7:0]==8'h99 )
//	    	sfr_rd_byte <=  0;
//		else
//    	begin
//        	$display($time," ns : --- SFR READ: %2h---",ram_rd_addr[7:0]);
//        	//$stop;
//    	end
//else;    	
	

//always @ ( posedge clk )
//	if ( ram_wr_en_sfr )
//    	if(( ram_wr_addr[7:0]==8'h98 )|( ram_wr_addr[7:0]==8'h99 ))
//	    	#0;
//    	else	
//    	begin
//    	$display($time," ns : --- SFR WRITE: %2h -> %2h---",ram_wr_addr[7:0],ram_wr_byte);
//    	//$stop;
//    	end
//	else;	


reg [1:0] read_flag;
always @ ( posedge clk )
	if ( ram_rd_en_sfr )
    	read_flag <= 2'b10;
	else if ( ram_rd_en_xdata )
    	read_flag <= 2'b01;	
	else if ( ram_rd_en_data )
    	read_flag <= 2'b0;
else;

always @*
	if ( read_flag[1] )
    	ram_rd_byte = sfr_rd_byte;
	else if ( read_flag[0] )
    	ram_rd_byte = xdata_rd_byte;
	else
    	ram_rd_byte = data_rd_byte;
endmodule