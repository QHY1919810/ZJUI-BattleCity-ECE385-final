module SoundFX_Selector(
    input logic Clk,
    input logic [17:0] InputSelect,
    output logic loop, play, Audio_Reset,
    output logic [22:0]  Start_Addr, // Address to start an audio
    output logic [22:0]  End_Addr // Address to end an audio 
);
logic [17:0] SoundSelect;
always_ff @( posedge  Clk) begin
    SoundSelect<=InputSelect;
end

always_comb begin
    if (SoundSelect != InputSelect)  //make sure one audio is end before the other begins
        Audio_Reset=1;
    else
        Audio_Reset=0;
end

always_comb begin
    loop=0;
    play=0;
    Start_Addr=23'd0;
    End_Addr=23'd0;
case(SoundSelect)
    18'd1: begin   //camp_bomb
        loop=0;
        play=1;
        Start_Addr=23'd0;
        End_Addr=23'd3890;
    end
    18'd2: begin   //enemy_bomb
        loop=0;
        play=1;
        Start_Addr=23'd3891;
        End_Addr=23'd6729;
    end
    18'd4: begin   //fail
        loop=0;
        play=1;
        Start_Addr=23'd6730;
        End_Addr=23'd153065;
    end
    18'd8: begin   //addlife
        loop=0;
        play=1;
        Start_Addr=23'd153066;
        End_Addr=23'd161061;
    end
    18'd16: begin   //bonus 1000
        loop=0;
        play=1;
        Start_Addr=23'd161062;
        End_Addr=23'd164887;
    end
    18'd32: begin   //get-prop
        loop=0;
        play=1;
        Start_Addr=23'd164888;
        End_Addr=23'd170165;
    end
    18'd64: begin   //player_bomb
        loop=0;
        play=1;
        Start_Addr=23'd170166;
        End_Addr=23'd174714;
    end
    18'd128: begin   //player_move
        loop=1;
        play=1;
        Start_Addr=23'd174715;
        End_Addr=23'd178532;
    end
    18'd256: begin   //shoot
        loop=0;
        play=1;
        Start_Addr=23'd178533;
        End_Addr=23'd180061;
    end
    18'd512: begin   //start
        loop=0;
        play=1;
        Start_Addr=23'd180062;
        End_Addr=23'd230895;
    end
    18'd1024: begin   //test (猫中毒)
        loop=1;
        play=1;
        Start_Addr=23'd230896;
        End_Addr=23'd1331925;
    end

    default: begin
        loop=0;
        play=0;
        Start_Addr=23'd0;
        End_Addr=23'd0;
    end
endcase
end
endmodule