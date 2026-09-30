# /system/mission/course — pre-run course configuration (GCS -> all vehicles)
# Mirrors robocommand.robotx.v1.RxCourse; uav_geofence is a team extension
# relayed by the GCS from the team's RunDeclaration.
string course_id
uint32 pinger_freq_hz
rx_msgs/LatLng[] boundary
rx_msgs/LatLng[] uav_geofence
