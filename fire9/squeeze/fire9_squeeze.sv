/*
* FIRE9  SQUEEZE  IMPLEMENTATION
* INPUT SIZE: 8*8*512
* OUTPUT SIZE: 8*8*112
* STRIDE: 1
* PAD:	1
* WINDOW: 1*1
*/
module fire9_squeeze_1 #(
	parameter DSP_NO = 112,
	parameter STRIDE = 1 ,
	parameter W_IN = 8,
	parameter H_IN = 8 ,
	parameter WIDTH = 16 ,
	parameter CHIN = 512 , 
	parameter KERNEL_DIM = 1 ,
	parameter CHOUT = 112  ,
	parameter WINDOWS=CHIN*(((W_IN-1)/STRIDE)**2),
	parameter ITER = ((W_IN**2)*CHOUT)/DSP_NO //8*8
)
(
	input clk,
	input rst,
	input fire9_squeeze_1_en,
	input [15:0] ifm,
	output reg fire9_squeeze_1_end,
	output reg [WIDTH-1:0] ofm [0:DSP_NO-1]
);

wire [WIDTH-1:0] biasing_wire [0:DSP_NO-1] ;
biasing_rom b7 (
	.bias_mem(biasing_wire)
);
///////////////////////////////////
//KERNELS INSTANTIATION
///////////////////////////////////
wire [WIDTH-1:0] kernels [0:DSP_NO-1] ; 
reg [WIDTH-1:0] kernel_regs [0:DSP_NO-1] ; 
reg [$clog2(KERNEL_DIM**2*CHIN)-1:0] weight_rom_address ; 
//////////////////////////////////
rom_array_layer_1 u_2 (
	.address(weight_rom_address),
	.rom_out(kernels)
);
///////////////////////////////////
//this signal is very important to track
//represents a pulse to clr pin of mac to reset every 27 cycles of clk
///////////////////////////////////
reg clr_pulse ; 
reg clk_sampling;
///////
///////
always @(posedge clk or negedge rst) begin
	if(!rst)
		weight_rom_address<= 0 ; 
	else if (clr_pulse)
		weight_rom_address<= 0;
	else begin
		weight_rom_address<= weight_rom_address+1;
	end
end
always @(posedge clk) begin
	kernel_regs<=kernels ;		
end
////////////////////////////
//GENERATION OF CLR PULSE///
////////////////////////////
reg [$clog2(KERNEL_DIM**2*CHIN):0] counter_10 ; 
always @(posedge clk or negedge rst) begin
	if(!rst) begin
		clr_pulse <= 1'b0 ; 
		clk_sampling <= 1'b0 ; 
		counter_10 <= 0 ;
	end
	else if (!fire9_squeeze_1_end) begin
		if(counter_10 == KERNEL_DIM**2*CHIN) begin
			counter_10 <= 0 ;
			clr_pulse<= 1'b1 ;
			clk_sampling<= 1'b1;//THE SAME LOGIC AS CLR PULSE, HOWEVER SEPARATE THEM FOR NOW
		end
		else begin
			clr_pulse <= 1'b0 ; 
			clk_sampling <= 1'b0 ; 
			counter_10 <= counter_10 +1;
		end
	end
end
//////////////////////////////
//CORE GENERATION/////////////
//////////////////////////////
wire [2*WIDTH-1:0] ofmw [0:DSP_NO-1];
reg [2*WIDTH-1:0] ofmw2 [0:DSP_NO-1];
genvar i ; 
generate for (i = 0 ; i< CHOUT ; i++) begin
	mac mac_i (
		.clr(clr_pulse),
		.clk(clk),
		.rst(rst),
		.pix(ifm),
		.mul_out(ofmw[i]),
		.ker(kernel_regs[i])
	);
end
endgenerate
/////////////////////////////////
//OUTPUT IS READY TO BE SAMPLED//
/////////////////////////////////
always @(*) begin
	for (int i = 0 ; i < DSP_NO ; i++) begin
		ofmw2[i]  = ofmw[i] + {biasing_wire[i],16'b0}  ; //bias + CHECK IF THIS LOGIC IS CORRECT
	end
end
always@(posedge clk_sampling) begin
	if(fire9_squeeze_1_en && !fire9_squeeze_1_end) begin
		for (int i = 0 ; i< DSP_NO ; i++) begin
			if(ofmw2[i][31] == 1'b1 ) 
				ofm[i] <= 16'b0 ;
			else
				ofm[i] <= ofmw2[i][23:8] ;//relu
		end
	end
end
///////////////////////////////
//CHECK FOR LAYER END//////////
///////////////////////////////
reg [$clog2(CHOUT**2)-1:0] fire9_squeeze_1_timer ;// will be changed
always @(posedge clk_sampling or negedge rst) begin
	if (!rst) begin
		fire9_squeeze_1_timer<= 0 ;
		fire9_squeeze_1_end <= 1'b0 ; 
	end
	else if (fire9_squeeze_1_timer == CHOUT)// will be changed
		fire9_squeeze_1_end <= 1'b1 ;//LAYER_1 HAS FINISHED
	else
		fire9_squeeze_1_timer<= fire9_squeeze_1_timer+1 ; 
end
endmodule
