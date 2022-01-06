module RandAI(input logic Clk,input logic Reset_h, input logic [31:0] countervalue, input logic [4:0] randominput1,
              input logic [2:0] randominput2,output logic [3:0] AI_tank_control);
    logic [4:0] d1;
	 logic [1:0] direction;
	 logic move,fire;
	 logic trig_rnd;
    logic [31:0] counter; //100000000
	 //logic [4:0] RND0,RND1;
	 logic [3:0] New_AI_tank_control;
//	 always_comb begin
//	     RND0=randominput[4:0];
//	     RND1=randominput[9:5];
//	 end
	 //randomgenerate R1(.Clk(Clk),.o(RND1));
	 initial begin
	     AI_tank_control=4'b0000;
		  trig_rnd=0;
		  counter=0;
		  move=0;
		  fire=0;
		  d1=0;
	 end
	 
    always_ff@(posedge Clk) begin
	 if (Reset_h == 1 ) begin
	     counter<=0;
		  trig_rnd<=0;
		  AI_tank_control<=0;
	     end
	 else if (counter == countervalue) begin
	     counter<=0;
		  trig_rnd<=1;
		  AI_tank_control <= New_AI_tank_control;
	     end
	 else begin
	    counter<=counter+1;
		 trig_rnd<=0;
		 AI_tank_control <= New_AI_tank_control;
	    end
	 end
	 always_comb begin
	 move=0;
	 fire=0;
	 d1=0;
	 New_AI_tank_control=AI_tank_control;
	 if (trig_rnd ==1) begin
	     d1=randominput1;
		  move=(randominput2[1] | randominput2[2]);
		  fire=randominput2[0];
		  New_AI_tank_control={fire,move,direction};
	     end
	 end
	 always_comb begin
	     case (d1) 
		  5'd0:direction=2'b10; //S x11
		  5'd1:direction=2'b10;
		  5'd2:direction=2'b10;
		  5'd3:direction=2'b10;
		  5'd4:direction=2'b10;
		  5'd5:direction=2'b10;
		  5'd6:direction=2'b10;
		  5'd7:direction=2'b10;
		  5'd8:direction=2'b10;
		  5'd9:direction=2'b10;
		  5'd10:direction=2'b10;
		  5'd11:direction=2'b01; //A x7
		  5'd12:direction=2'b01; //A
		  5'd13:direction=2'b01; //A
		  5'd14:direction=2'b01; //A
		  5'd15:direction=2'b01; //A
		  5'd16:direction=2'b01; //a 
		  5'd17:direction=2'b01; //a
		  5'd18:direction=2'b00; //D x7
		  5'd19:direction=2'b00;
		  5'd20:direction=2'b00;
		  5'd21:direction=2'b00;
		  5'd22:direction=2'b00;
		  5'd23:direction=2'b00; 
		  5'd24:direction=2'b00;//
		  5'd25:direction=2'b11; //W x7
		  5'd26:direction=2'b11; //W
		  5'd27:direction=2'b11; //W
		  5'd28:direction=2'b11; //W
		  5'd29:direction=2'b11; //W
		  5'd30:direction=2'b11; //W
		  5'd31:direction=2'b11; //W
        default:;
		  endcase
	 end
endmodule