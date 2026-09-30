cmake_minimum_required(VERSION 3.15)
project(rx_msgs)

find_package(ament_cmake REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(std_msgs REQUIRED)

set(msgs
  msg/BeaconState.msg
  msg/BuoyDetection.msg
  msg/Color.msg
  msg/Command.msg
  msg/Course.msg
  msg/Docking.msg
  msg/FlightPhase.msg
  msg/Firefighting.msg
  msg/Heartbeat.msg
  msg/IncidentAck.msg
  msg/LatLng.msg
  msg/MissionStatus.msg
  msg/PipelineSegmentStatus.msg
  msg/PipelineSurvey.msg
  msg/ReadinessReport.msg
  msg/ResourceDelivery.msg
  msg/RobotState.msg
  msg/RxTask.msg
  msg/SafePassage.msg
  msg/TaskTier.msg
  msg/VehicleType.msg
)

rosidl_generate_interfaces(${PROJECT_NAME}
  ${msgs}
  DEPENDENCIES
  std_msgs
)

ament_package()
