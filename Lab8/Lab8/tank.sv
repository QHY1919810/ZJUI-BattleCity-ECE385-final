module tank(
    input logic         Clk, Reset,
    input logic         frame_clk,
    input logic [3:0]   Tank_Control,
    output logic [1:0]  Tank_Direction, // 0: up, 1: left, 2: down, 3: right
    output logic [8:0]  Tank_X,
                        Tank_Y,
    output logic        Tank_State // movement state
);
    parameter [1:0] Tank_Direction_up = 2'b00; // initial direction is UP
    parameter [8:0] Tank_X_Center = 9'd136;  // Center position on the X axis
    parameter [8:0] Tank_Y_Center = 9'd112;  // Center position on the Y axis
    parameter [8:0] Tank_X_Min = 9'd0;       // Leftmost point on the X axis
    parameter [8:0] Tank_X_Max = 9'd272;     // Rightmost point on the X axis
    parameter [8:0] Tank_Y_Min = 9'd0;       // Topmost point on the Y axis
    parameter [8:0] Tank_Y_Max = 9'd224;     // Bottommost point on the Y axis
    parameter [8:0] Tank_X_Step = 9'd1;      // Step size on the X axis
    parameter [8:0] Tank_Y_Step = 9'd1;      // Step size on the Y axis
    parameter [8:0] Tank_Size = 9'd16;       // Tank size

    logic [8:0] Tank_X_Motion, Tank_Y_Motion, Tank_X_in, Tank_Y_in;
    logic [1:0] Tank_Direction_in;
    logic Tank_State_in;
    logic turn_direction;

    initial
    begin
        Tank_Direction <= Tank_Direction_up;
        Tank_X = Tank_X_Center;
        Tank_Y = Tank_Y_Center;
        Tank_State = 1'b0;
        turn_direction = 1'b0;
    end

    // Detect rising edge of frame_clk
    logic frame_clk_delayed, frame_clk_rising_edge;
    always_ff @ (posedge Clk) begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
    end
    // Update registers
    always_ff @ (posedge Clk)
    begin
        if (Reset)
        begin
            Tank_Direction <= Tank_Direction_up;
            Tank_X <= Tank_X_Center;
            Tank_Y <= Tank_Y_Center;
            Tank_State <= 1'b0;
        end
        else
        begin
            Tank_Direction <= Tank_Direction_in;
            Tank_X <= Tank_X_in;
            Tank_Y <= Tank_Y_in;
            Tank_State <= Tank_State_in;
        end
    end

    always_comb
    begin
        // By default, keep motion and position unchanged
        Tank_Direction_in = Tank_Direction;
        Tank_X_in = Tank_X;
        Tank_Y_in = Tank_Y;
        Tank_X_Motion = 9'b0;
        Tank_Y_Motion = 9'b0;
        Tank_State_in = Tank_State;
        turn_direction = 1'b0;
        
        // Update position and motion only at rising edge of frame clock
        if (frame_clk_rising_edge)
        begin
            // Be careful when using comparators with "logic" datatype because compiler treats 
            //   both sides of the operator as UNSIGNED numbers.
            case (Tank_Control[2:0])
                    3'b101: // A is pressed
                    begin
                        if(Tank_Direction == 2'b01)
                        begin
                            Tank_X_Motion = (~(Tank_X_Step)+1'b1);
                            Tank_Y_Motion = 9'd0;
                            Tank_State_in = ~Tank_State;
                        end
                        else
                        begin
                            turn_direction = 1'b1;
                            Tank_Direction_in = 2'b01;
                            Tank_Y_in = (Tank_Y + 2) / 4 * 4;
                        end
                    end
                    3'b111: // D is pressed
                    begin
                        if(Tank_Direction == 2'b11)
                        begin
                            Tank_X_Motion = Tank_X_Step;
                            Tank_Y_Motion = 9'd0;
                            Tank_State_in = ~Tank_State;
                        end
                        else
                        begin
                            turn_direction = 1'b1;
                            Tank_Direction_in = 2'b11;
                            Tank_Y_in = (Tank_Y + 2) / 4 * 4;
                        end
                    end
                    3'b100: // W is pressed
                    begin
                        if(Tank_Direction == 2'b00)
                        begin
                            Tank_Y_Motion = (~(Tank_Y_Step) + 1'b1);
                            Tank_X_Motion = 9'd0;
                            Tank_State_in = ~Tank_State;
                        end
                        else
                        begin
                            turn_direction = 1'b1;
                            Tank_Direction_in = 2'b00;
                            Tank_X_in = (Tank_X + 2) / 4 * 4;
                        end
                    end
                    3'b110: // S is pressed
                        if(Tank_Direction == 2'b10)
                        begin
                            Tank_Y_Motion = Tank_Y_Step;
                            Tank_X_Motion = 9'd0;
                            Tank_State_in = ~Tank_State;
                        end
                        else
                        begin
                            turn_direction = 1'b1;
                            Tank_Direction_in = 2'b10;
                            Tank_X_in = (Tank_X + 2) / 4 * 4;
                        end
                    default: ;
            endcase

            if(~turn_direction)
            begin
                // Update the Tank's position with its motion
                Tank_X_in = Tank_X + Tank_X_Motion;
                Tank_Y_in = Tank_Y + Tank_Y_Motion;

                // Boundary Judgement
                if( Tank_X_in + Tank_Size > Tank_X_Max || Tank_X_in > Tank_X_Max )  // Tank is at the edge
                    Tank_X_in = Tank_X;
                // else if ( Tank_X_in[8] && ~Tank_X[8] )  // Tank is at the left edge
                //     Tank_X_in = Tank_X;
                if( Tank_Y_in + Tank_Size > Tank_Y_Max || Tank_Y_in > Tank_Y_Max )  // Tank is at the edge
                    Tank_Y_in = Tank_Y;
                // else if ( Tank_Y_in[8] && ~Tank_Y[8] )  // Tank is at the top edge
                //     Tank_Y_in = Tank_Y;
            end
        end
    end
endmodule
