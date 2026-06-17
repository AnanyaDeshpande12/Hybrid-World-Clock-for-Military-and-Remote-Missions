`timescale 1ns/1ps

module top_clock #(
    parameter integer TICKS_PER_SEC = 50000000,
    parameter integer TZ_OFFSET_MINUTES = 330
)(
    input  wire clk,
    input  wire rstn,

    input  wire set_time,
    input  wire [7:0] set_hour,
    input  wire [7:0] set_min,
    input  wire [7:0] set_sec,

    output reg  [7:0] hour,
    output reg  [7:0] min,
    output reg  [7:0] sec,

    output wire [5:0] minute_index,

    output wire [3:0] stepper_coils,

    output wire [7:0] tz_hour,
    output wire [7:0] tz_min,
    output wire [7:0] tz_sec
);

reg [$clog2(TICKS_PER_SEC)-1:0] tick_cnt = 0;

reg sec_tick;
reg minute_pulse;

always @(posedge clk or negedge rstn)
begin
    if(!rstn)
    begin
        tick_cnt <= 0;
        sec_tick <= 0;
        minute_pulse <= 0;

        hour <= 0;
        min  <= 0;
        sec  <= 0;
    end
    else
    begin
        sec_tick <= 0;
        minute_pulse <= 0;

        if(set_time)
        begin
            hour <= set_hour;
            min  <= set_min;
            sec  <= set_sec;

            tick_cnt <= 0;
        end
        else
        begin
            if(tick_cnt == TICKS_PER_SEC - 1)
            begin
                tick_cnt <= 0;
                sec_tick <= 1'b1;

                if(sec == 8'd59)
                begin
                    sec <= 8'd0;

                    minute_pulse <= 1'b1;

                    if(min == 8'd59)
                    begin
                        min <= 8'd0;

                        if(hour == 8'd23)
                            hour <= 8'd0;
                        else
                            hour <= hour + 8'd1;
                    end
                    else
                    begin
                        min <= min + 8'd1;
                    end
                end
                else
                begin
                    sec <= sec + 8'd1;
                end
            end
            else
            begin
                tick_cnt <= tick_cnt + 1;
            end
        end
    end
end

wire [5:0] step_pos;

stepper_ctrl #(
    .NUM_STEPS(60)
)
u_stepper
(
    .clk(clk),
    .rstn(rstn),
    .pulse(minute_pulse),
    .coils(stepper_coils),
    .pos(step_pos)
);

assign minute_index = step_pos;

wire signed [31:0] base_seconds;
wire signed [31:0] offset_seconds;
wire signed [31:0] tz_total_seconds_unwrapped;
wire signed [31:0] tz_mod;
wire [31:0] tz_total_seconds;

assign base_seconds =
       ($signed(hour) * 3600)
     + ($signed(min)  * 60)
     +  $signed(sec);

assign offset_seconds =
       $signed(TZ_OFFSET_MINUTES) * 60;

assign tz_total_seconds_unwrapped =
       base_seconds + offset_seconds;

assign tz_mod =
       ((tz_total_seconds_unwrapped % 86400)
       + 86400) % 86400;

assign tz_total_seconds = tz_mod;

assign tz_hour = tz_total_seconds / 3600;
assign tz_min  = (tz_total_seconds % 3600) / 60;
assign tz_sec  = tz_total_seconds % 60;

endmodule