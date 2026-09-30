# /system/vehicle/<vehicle>/task4/status — Task 4 acknowledgement, command_seq preserved from the command
std_msgs/Header header
uint64 command_seq
uint8 status
string detail

uint8 TASK4_UNKNOWN = 0
uint8 TASK4_RECEIVED = 1
uint8 TASK4_NAVIGATING = 2
uint8 TASK4_REACHED = 3
uint8 TASK4_ACTIVE = 4
uint8 TASK4_CLEARED = 5
uint8 TASK4_REJECTED = 6
uint8 TASK4_FAILED = 7
