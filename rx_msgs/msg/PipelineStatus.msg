# /system/vehicle/uuv/task2/pipeline — pipeline integrity status
std_msgs/Header header
uint8 status

uint8 PIPELINE_UNKNOWN = 0
uint8 PIPELINE_INTACT = 1
uint8 PIPELINE_DAMAGED = 2
