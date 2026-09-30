# /system/mission/request — mission configuration from RoboCommand before mission start
std_msgs/Header header
uint32 mission_id
string[] vehicle_id
uint8[] task_tier
rx_msgs/LatLng[] uav_geofence
