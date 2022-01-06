module drawer(
    input logic         Clk, Reset, Drawing,
    output logic        Draw_Ready,

    // control signal for sprite OCM
    input logic [19:0]  Start_ADDR,
    output logic [19:0] ADDR,
    input logic [4:0]   ColorId,

    // control signal for frame_buffer
    output logic        FB_Write,
    output logic [8:0]  FB_AddrX,
                        FB_AddrY,
    output logic [4:0]  ColorId_Write,

    // signals for drawing
    input logic         Transparent, // if the black color is set to transparent
    input logic [8:0]   X_Max, // width of the graph
                        Y_Max, // height of the graph
    input logic [8:0]   X_Offset,
                        Y_Offset
    
);
    enum logic [1:0] {
        Draw,
        Idle_1,
        Idle_2,
        Idle_3
    } State, Next_State;

    logic [8:0] h_counter, v_counter, h_counter_in, v_counter_in;

    logic Draw_Ready_in;
    logic FB_Write_in;
    logic [8:0] FB_AddrX_in, FB_AddrY_in;
    logic [4:0] ColorId_in;


    initial
    begin
        State = Idle_1;
        Draw_Ready = 1'b0;
        FB_Write = 1'b0;
        FB_AddrX = 9'd0;
        FB_AddrY = 9'd0;
        h_counter = 9'b0;
        v_counter = 9'b0;
        ColorId_Write = 5'd0;
    end
    
    // update registers
    always_ff @ (posedge Clk)
    begin
        if (Reset)
        begin
            State <= Idle_1;
            Draw_Ready <= 1'b0;
            FB_Write <= 1'b0;
            FB_AddrX <= 9'd0;
            FB_AddrY <= 9'd0;
            h_counter <= 9'b0;
            v_counter <= 9'b0;
            ColorId_Write <= 5'd0;
        end
        else
        begin
            State <= Next_State;
            Draw_Ready <= Draw_Ready_in;
            FB_Write <= FB_Write_in;
            FB_AddrX <= FB_AddrX_in;
            FB_AddrY <= FB_AddrY_in;
            h_counter <= h_counter_in;
            v_counter <= v_counter_in;
            ColorId_Write <= ColorId_in;
        end
    end

    always_comb
    begin
        Next_State = State;
        Draw_Ready_in = Draw_Ready;

        ADDR = 20'b0;

        FB_Write_in = 1'b0;
        FB_AddrX_in = FB_AddrX;
        FB_AddrY_in = FB_AddrY;
        ColorId_in = 5'd0;

        h_counter_in = h_counter;
        v_counter_in = v_counter;

        unique case (State)
            Draw:
            begin
                ADDR = Start_ADDR + h_counter + (v_counter * X_Max);

                FB_Write_in = 1'b1;
                FB_AddrX_in = X_Offset + h_counter;
                FB_AddrY_in = Y_Offset + v_counter;
                ColorId_in = ColorId;
                // set black color as transparent
                if(Transparent && ColorId_in == 5'd0)
                    FB_Write_in = 1'b0;
                else
                    FB_Write_in = 1'b1;

                h_counter_in = h_counter + 9'd1;
                if(h_counter + 9'd1 == X_Max)
                begin
                    h_counter_in = 9'd0;
                    v_counter_in = v_counter + 9'd1;
                    if(v_counter + 9'd1 == Y_Max)
                    begin
                        v_counter_in = 9'd0;
                        Next_State = Idle_1;
                        Draw_Ready_in = 1'b1;
                    end
                end
            end

            Idle_1:
            begin
                if (~Drawing)
                begin
                    Next_State = Idle_2;
                end
                Draw_Ready_in = 1'b0;
            end

            Idle_2:
            begin
                if (Drawing)
                begin
                    Next_State = Draw;
                end
            end

            default: ;
        endcase
    end

endmodule
