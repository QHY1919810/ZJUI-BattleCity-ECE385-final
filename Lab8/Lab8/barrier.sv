module load_map(
    input logic        Clk, Reset, Loading,
    output logic       Load_Ready,
    output logic       Barrier_Write,
    output logic [8:0] Barrier_X,
                       Barrier_Y,
    input logic [2:0]  Barrier_Id_Read,
    output logic [2:0] Barrier_Id_Write
);
    enum logic [1:0] {
        Read,
        Write,
        Idle_1,
        Idle_2
    } State, Next_State;

    logic Load_Ready_in;
    logic Barrier_Write_in;
    logic [8:0] Barrier_X_in, Barrier_Y_in;
    logic [2:0] Barrier_Id, Barrier_Id_in;

    initial
    begin
        State = Read;
        Load_Ready = 1'b0;
        Barrier_Write = 1'b0;
        Barrier_X = 9'b0;
        Barrier_Y = 9'b0;
        Barrier_Id = 3'b111;
    end

    always_ff @(posedge Clk)
    begin
        if (Reset)
        begin
            State <= Read;
            Load_Ready <= 1'b0;
            Barrier_Write <= 1'b0;
            Barrier_X <= 9'b0;
            Barrier_Y <= 9'b0;
            Barrier_Id <= 3'b111;
        end
        else
        begin
            State <= Next_State;
            Load_Ready <= Load_Ready_in;
            Barrier_Write <= Barrier_Write_in;
            Barrier_X <= Barrier_X_in;
            Barrier_Y <= Barrier_Y_in;
            Barrier_Id <= Barrier_Id_in;
        end
    end

    always_comb
    begin
        Next_State = State;
        Load_Ready_in = Load_Ready;
        Barrier_Write_in = Barrier_Write;
        Barrier_X_in = Barrier_X;
        Barrier_Y_in = Barrier_Y;
        Barrier_Id_in = Barrier_Id;

        unique case (State)
            Read:
            begin
                Barrier_Id_in = Barrier_Id_Read;
                Barrier_Write_in = 1'b1;
                Next_State = Write;
            end

            Write:
            begin
                Barrier_Write_in = 1'b0;
                Next_State = Read;

                Barrier_X_in = Barrier_X + 9'd8;
                if(Barrier_X == 9'd264)
                begin
                    Barrier_X_in = 9'd0;
                    Barrier_Y_in = Barrier_Y + 9'd8;
                    if(Barrier_Y == 9'd216)
                    begin
                        Barrier_Y_in = 9'd0;
                        Next_State = Idle_1;
                        Load_Ready_in = 1'b1;
                    end
                end
            end

            Idle_1:
            begin
                if (~Loading)
                begin
                    Next_State = Idle_2;
                end
            end

            Idle_2:
            begin
                if (Loading)
                begin
                    Next_State = Read;
                    Load_Ready_in = 1'b0;
                end
            end
        endcase
    end

    assign Barrier_Id_Write = Barrier_Id;
    
endmodule

module map(
    input logic        Clk,
    input logic [3:0]  Map_Id,
    input logic [8:0]  Barrier_X,
                       Barrier_Y,
    output logic [2:0] Barrier_Id
);
    logic [3:0] map [9520];

    initial
    begin
        $readmemh("sprites_txt/map.txt", map);
    end

    always_ff @ (posedge Clk)
    begin
        Barrier_Id <= map[(Barrier_X >> 3) + 34 * (Barrier_Y >> 3) + 952 * (Map_Id - 1)][2:0];
    end
endmodule

module barrier(
    input logic        Clk, WE,
    input logic [8:0]  Barrier_X_In,
                       Barrier_Y_In,
    input logic [2:0]  Barrier_Id_In,
    input logic [8:0]  Barrier_X_Out,
                       Barrier_Y_Out,
    output logic [2:0] Barrier_Id_Out
);
    logic [2:0] map [34*28];

    always_ff @(posedge Clk)
    begin
        if (WE)
            map[(Barrier_X_In >> 3) + 34 * (Barrier_Y_In >> 3)] <= Barrier_Id_In;
        Barrier_Id_Out <= map[(Barrier_X_Out >> 3) + 34 * (Barrier_Y_Out >> 3)];
    end
endmodule
