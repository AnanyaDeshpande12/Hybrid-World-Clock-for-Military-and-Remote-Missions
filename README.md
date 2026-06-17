# Hybrid World Clock

## Overview
A hybrid embedded world clock that combines ESP8266-based digital timekeeping with Verilog-based analog clock simulation.

## Features
- NTP Time Synchronization
- DS3231 RTC Backup
- 20 Global Time Zones
- LCD Time and Date Display
- Verilog Analog Clock Simulation
- Stepper Motor Control Logic

## Hardware Used
- ESP8266 NodeMCU
- DS3231 RTC Module
- 16x2 I2C LCD
- Push Button
- PYNQ-Z2 FPGA

## Software Used
- Arduino IDE
- Vivado
- Verilog HDL

## Project Files

### Arduino
- world_clock.ino

### Verilog
- top_clock.v
- stepper_ctrl.v
- tb_clock.v

## Team Members
- Abhisri R Bammanni
- Adithi A
- Ananya A Deshpande
- Astha S Gramopadhye

## Future Work
- Physical stepper motor implementation
- FPGA deployment
- ESP32 migration
- Dynamic timezone updates
