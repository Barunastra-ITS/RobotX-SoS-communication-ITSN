# /system/vehicle/uav/task1/safe_passage — mirrors robocommand.robotx.v1.SafePassageReport
# Full buoy field as currently mapped; republish whenever a detection updates.
std_msgs/Header header
# FLASHING_BLUE (entry) buoy position
rx_msgs/LatLng entry_position
# STEADY_BLUE (exit) buoy position
rx_msgs/LatLng exit_position
# All detected buoys with their beacon states
rx_msgs/BuoyDetection[] buoys
