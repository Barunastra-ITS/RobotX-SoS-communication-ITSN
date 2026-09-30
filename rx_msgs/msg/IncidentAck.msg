# /system/vehicle/<vehicle>/task4/incident_ack — mirrors robocommand.robotx.v1.IncidentAck
# Acknowledges AssistanceRequest, KeepOutZone, or AllClear with that command's seq.
std_msgs/Header header
uint32 command_seq
