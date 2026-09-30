# /system/mission/command — GCS -> vehicle command (mirrors the RxCommand bodies)
std_msgs/Header header
# seq of the RxCommand (or internal sequence for CMD_GO / CMD_MISSION_DONE)
uint32 command_seq
# VehicleType constants; TYPE_UNKNOWN = all vehicles
uint8 target_vehicle
uint8 command_type
# CMD_RUN_START
uint32 run_id
# CMD_TASK4_ASSISTANCE / CMD_TASK4_MOVING_OBJECT
rx_msgs/LatLng position
# CMD_TASK4_KEEP_OUT_ZONE
rx_msgs/LatLng center
float32 radius_m
# CMD_TASK4_MOVING_OBJECT
float32 heading_deg
float32 speed_mps
# CMD_TASK4_READINESS_CONFIRM
uint32 report_seq
# CMD_DELIVERY
uint8 task
uint8 resource_color
uint8 delivery_circle_color
string detail

uint8 CMD_NONE = 0
uint8 CMD_RUN_START = 1
uint8 CMD_DELIVERY = 2
uint8 CMD_TASK4_ASSISTANCE = 3
uint8 CMD_TASK4_KEEP_OUT_ZONE = 4
uint8 CMD_TASK4_ALL_CLEAR = 5
uint8 CMD_TASK4_MOVING_OBJECT = 6
uint8 CMD_TASK4_READINESS_CONFIRM = 7
uint8 CMD_GO = 8
uint8 CMD_MISSION_DONE = 9
