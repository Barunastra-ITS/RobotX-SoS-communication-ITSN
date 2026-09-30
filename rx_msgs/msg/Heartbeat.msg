# /system/vehicle/<vehicle>/heartbeat — mirrors robocommand.robotx.v1.Heartbeat (RxReport body)
std_msgs/Header header
uint8 state
rx_msgs/LatLng position
float32 spd_mps
float32 heading_deg
float32 roll_deg
float32 pitch_deg
float32 altitude_hae_m
# UUV only
float32 depth_m
uint8 current_task
uint8 vehicle_type
# UAV only
uint8 flight_phase
