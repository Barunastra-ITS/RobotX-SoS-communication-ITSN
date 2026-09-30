# /system/vehicle/<vehicle>/taskN/delivery — mirrors robocommand.robotx.v1.ResourceDeliveryRequest
# Sent by the vehicle that reads the flash signal; the UAV echoes it when delivery begins.
std_msgs/Header header
# RxTask constants (TASK_INFRA_SURVEY_REPAIR / TASK_COORDINATED_LOGISTICS)
uint8 task
# COLOR_ANY = any tin acceptable (Advanced tier)
uint8 resource_color
uint8 delivery_circle_color
