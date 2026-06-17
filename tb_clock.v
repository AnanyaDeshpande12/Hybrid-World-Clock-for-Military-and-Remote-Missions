`timescale 1ns/1ps

module tb_clock;

reg clk = 0;
reg rstn = 0;

reg set_time = 0;
reg [7:0] set_hour = 0;
reg [7:0] set_min  = 59;
reg [7:0] set_sec  = 55;

wire [7:0] hour;
wire [7:0] min;
wire [7:0] sec;

wire [5:0] minute_index;
wire [3:0] stepper_coils;

wire [7:0] tz_hour;
wire [7:0] tz_min;
wire [7:0] tz_sec;

localparam SIM_TPS = 20;

integer i;

always #5 clk = ~clk;

top_clock #(
    .TICKS_PER_SEC(SIM_TPS),
    .TZ_OFFSET_MINUTES(330)
)
DUT
(
    .clk(clk),
    .rstn(rstn),

    .set_time(set_time),
    .set_hour(set_hour),
    .set_min(set_min),
    .set_sec(set_sec),

    .hour(hour),
    .min(min),
    .sec(sec),

    .minute_index(minute_index),

    .stepper_coils(stepper_coils),

    .tz_hour(tz_hour),
    .tz_min(tz_min),
    .tz_sec(tz_sec)
);

initial
begin

    $display("TB: starting simulation");

    #50;
    rstn = 1;

    #20;

    set_hour = 0;
    set_min  = 59;
    set_sec  = 55;

    set_time = 1;

    #10;
    set_time = 0;

    #100;

    for(i = 0; i < 60; i = i + 1)
    begin

        #(SIM_TPS * 600);

        $display(
        "T=%0t | BASE=%0d:%02d:%02d | BANGALORE=%0d:%02d:%02d | MIN_IDX=%02d | COILS=%b",
        $time,
        hour,
        min,
        sec,
        tz_hour,
        tz_min,
        tz_sec,
        minute_index,
        stepper_coils
        );

    end

    $display("TB: done.");

    #20;
    $finish;

end

endmodule