module tff0(q,t,c);
    output q;
    input t,c;
    reg q;
    initial 
     begin 
      q=1'b1;
     end
    always @ (posedge c)
    begin
        if (t==1'b0) begin q=q; end
        else begin q=~q;  end
    end
endmodule
 
module tff1(q,t,c);
    output q;
    input t,c;
    reg q;
    initial 
     begin 
      q=1'b0;
     end
    always @ (posedge c)
    begin
        if (t==1'b0) begin q=q; end
        else begin q=~q;  end
    end
endmodule