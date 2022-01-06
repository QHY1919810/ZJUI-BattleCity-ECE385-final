module Audio_judgement( input logic Clk,
                        input logic End_flag,
                        input logic Tank_Die, 
                        input logic Win,
                        input logic Upgrade,
                        input logic Menu,
                        input logic Loading,
                        input logic Over,
                        input logic [3:0] Tank_Control_1,
                                          Tank_Control_2,
                        input logic [1:0] Bonus_Type,
                        output logic [17:0] InputSelect
                        );

enum logic [3:0] {MENU, LOADING, WIN, OVER, TANK_DIE, NO_SOUND} current_state, next_state;

initial begin
    current_state = NO_SOUND;
end

always_ff @( posedge  Clk) begin
    current_state <= next_state;
end

always_comb begin
    next_state=current_state;
	 case (current_state)
	    NO_SOUND: begin
            if ( Over == 1 ) begin
                next_state = OVER;
            end
            if ( Loading ==1 ) begin
                next_state = LOADING;
            end
            if ( Win ==1 ) begin
                next_state = WIN;
            end
            if ( Menu == 1 ) begin
                next_state = MENU;
            end
            if ( Tank_Die == 1 ) begin
                next_state = TANK_DIE;
            end
         end
        MENU: begin
            if (Menu == 0) begin
                next_state = NO_SOUND;
            end
        end
        LOADING: begin
            if (Loading == 0) begin
                next_state = NO_SOUND;
            end
        end
        WIN: begin
            if (Win == 0) begin
                next_state = NO_SOUND;
            end
        end
        OVER: begin
            if (Over == 0) begin
                next_state = NO_SOUND;
            end
        end
        TANK_DIE:begin
            if (End_flag == 1) begin
                next_state = NO_SOUND;
            end
        end
	 endcase
end
always_comb begin
    case (current_state) 
        OVER: InputSelect= 18'd4;
        LOADING: InputSelect= 18'd512;
        WIN: InputSelect= 18'd1024;
        MENU: InputSelect= 18'd1024;
        TANK_DIE: InputSelect= 18'd2;
        NO_SOUND: InputSelect= 18'd0;
    endcase
end



endmodule