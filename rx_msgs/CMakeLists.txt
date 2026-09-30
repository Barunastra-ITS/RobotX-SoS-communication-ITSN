cmake_minimum_required(VERSION 3.15)
project(rx_msgs)

find_package(ament_cmake REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(std_msgs REQUIRED)

set(msgs
  msg/BuoyDetection.msg
  msg/Color.msg
  msg/Delivery.msg
  msg/Docking.msg
  msg/FlightPhase.msg
  msg/Heartbeat.msg
  msg/LatLng.msg
  msg/MissionCommand.msg
  msg/MissionRequest.msg
  msg/MissionStatus.msg
  msg/PipelineStatus.msg
  msg/RobotState.msg
  msg/RxTask.msg
  msg/Task4Status.msg
  msg/TaskTier.msg
  msg/VehicleType.msg
)

rosidl_generate_interfaces(${PROJECT_NAME}
  ${msgs}
  DEPENDENCIES
  std_msgs
)

ament_package()
