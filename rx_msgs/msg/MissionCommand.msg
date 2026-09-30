# /system/mission/command — structured commands from RoboCommand (replaces string-based /mission/order)
std_msgs/Header header
uint64 command_seq
# target vehicle, VehicleType constants (UNKNOWN = broadcast)
uint8 target_vehicle
# command type
uint8 command_type
# CMD_TASK4_NAVIGATE / CMD_TASK4_AVOID_ZONE
rx_msgs/LatLng target
# CMD_TASK4_AVOID_ZONE
float32 radius_m
# CMD_TASK4_DYNAMIC_AVOID
rx_msgs/LatLng obstacle_position
float32 obstacle_heading_deg
float32 obstacle_speed_mps
# CMD_DELIVERY
uint8 resource_color
uint8 delivery_color
# free detail for future command types
string detail

uint8 CMD_NONE = 0
uint8 CMD_GO = 1
uint8 CMD_MISSION_DONE = 2
uint8 CMD_DELIVERY = 3
uint8 CMD_TASK4_NAVIGATE = 4
uint8 CMD_TASK4_AVOID_ZONE = 5
uint8 CMD_TASK4_DYNAMIC_AVOID = 6
uint8 CMD_READINESS_CONFIRM = 7
uint8 CMD_ALL_CLEAR = 8
