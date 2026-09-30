# /system/vehicle/<vehicle>/heartbeat — periodic vehicle state (rx_report.proto)
std_msgs/Header header
# RobotState constants
uint8 state
rx_msgs/LatLng position
float32 spd_mps
float32 heading_deg
float32 roll_deg
float32 pitch_deg
float32 altitude_hae_m
# UUV only
float32 depth_m
# RxTask constants
uint8 current_task
# VehicleType constants
uint8 vehicle_type
# FlightPhase constants, UAV only
uint8 flight_phase
