`timescale 1ns/1ps

module stepper_ctrl #(
    parameter integer NUM_STEPS = 60
)(
    input  wire clk,
    input  wire rstn,
    input  wire pulse,

    output reg  [3:0] coils,
    output reg  [5:0] pos
);

initial
begin
    coils = 4'b0001;
    pos   = 0;
end

always @(posedge clk or negedge rstn)
begin
    if(!rstn)
    begin
        pos   <= 0;
        coils <= 4'b0001;
    end
    else
    begin
        if(pulse)
        begin
            if(pos + 1 >= NUM_STEPS)
                pos <= 0;
            else
                pos <= pos + 1;

            case((pos + 1) % 4)
                0: coils <= 4'b0001;
                1: coils <= 4'b0010;
                2: coils <= 4'b0100;
                3: coils <= 4'b1000;
                default: coils <= 4'b0001;
            endcase
        end
    end
end

endmodule