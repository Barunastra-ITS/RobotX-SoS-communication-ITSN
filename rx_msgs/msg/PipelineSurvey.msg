# /system/vehicle/uuv/task2/pipeline_survey — mirrors robocommand.robotx.v1.PipelineSurveyReport
# Sent once, after the survey (and Advanced-tier repair), typically when surfaced.
std_msgs/Header header
# Active (GREEN) buoy position — the pinger end the segments are ordered from
rx_msgs/LatLng active_buoy_position
# Segment statuses in order from the active buoy end (PipelineSegmentStatus constants)
uint8[] segments
