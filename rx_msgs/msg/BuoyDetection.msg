# /system/vehicle/<vehicle>/task1/buoy_detection — detected buoy and its state
std_msgs/Header header
rx_msgs/LatLng position
uint8 state

uint8 STATE_UNKNOWN = 0
uint8 STATE_NORMAL = 1
uint8 STATE_DAMAGED = 2
uint8 STATE_MISSING = 3
