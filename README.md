# RobotX 2026 — System-of-Systems ROS 2 Communication Interface Guide

## 1. Purpose

This document defines the common ROS 2 communication interface between the UAV, USV, UUV, and RoboCommand/GCS systems.

The three vehicles are developed as independent systems. To allow them to operate as one System-of-Systems, all inter-vehicle and RoboCommand communication must use the interfaces defined in this document.

The interface is divided into:

1. **Mission Interface** — mission configuration and commands from RoboCommand.
2. **Vehicle Heartbeat** — periodic state information from each vehicle.
3. **Task Reports** — mission-specific information produced by each vehicle.
4. **Task 4 Command/Status** — coordinated commands and acknowledgements.
5. **Vehicle Internal Interface** — ROS 2 topics used only within an individual vehicle.

Only the topics defined as **System Interface** should be routed between ROS 2 domains using DDS Router.

---

# 2. ROS 2 Domain Architecture

Each system operates in an isolated ROS 2 domain.

| System            | ROS_DOMAIN_ID |
| ----------------- | ------------: |
| RoboCommand / GCS |          `10` |
| USV               |          `20` |
| UAV               |          `30` |
| UUV               |          `40` |

The DDS Router running on the GCS bridges the required topics between these domains.

```text
                       ┌─────────────────────┐
                       │   RoboCommand / GCS │
                       │    ROS Domain 10    │
                       └──────────┬──────────┘
                                  │
                            DDS Router
                                  │
                 ┌────────────────┼────────────────┐
                 │                │                │
                 ▼                ▼                ▼
          ┌────────────┐   ┌────────────┐   ┌────────────┐
          │    USV     │   │    UAV     │   │    UUV     │
          │ Domain 20  │   │ Domain 30  │   │ Domain 40  │
          └────────────┘   └────────────┘   └────────────┘
```

The network connection itself does not determine ROS 2 communication. ROS 2 domain isolation is maintained by DDS, while DDS Router selectively forwards the required System Interface topics.

---

# 3. Naming Convention

All System-of-Systems topics use the following namespace:

```text
/system/
```

Mission-level communication:

```text
/system/mission/<name>
```

Vehicle-specific communication:

```text
/system/vehicle/<vehicle>/<name>
```

Task-specific vehicle communication:

```text
/system/vehicle/<vehicle>/task<N>/<name>
```

where:

```text
<vehicle> = uav | usv | uuv
<N>       = 1 | 2 | 3 | 4
```

Examples:

```text
/system/mission/request
/system/mission/command
/system/vehicle/uav/heartbeat
/system/vehicle/uuv/task2/pipeline
/system/vehicle/usv/task3/docking
```

Topic names must use lowercase `snake_case`.

---

# 4. System Interface Topics

These topics form the common communication API between vehicles and RoboCommand.

## 4.1 Mission Interface

| Topic                     | Publisher   | Subscriber        | Purpose                                    |
| ------------------------- | ----------- | ----------------- | ------------------------------------------ |
| `/system/mission/request` | RoboCommand | All vehicles      | Mission configuration before mission start |
| `/system/mission/command` | RoboCommand | Target vehicle(s) | Commands requiring vehicle action          |
| `/system/mission/status`  | Vehicles    | RoboCommand       | Overall mission status                     |

### `/system/mission/request`

Sent before the mission starts.

The message contains the mission configuration defined by `rx_request.proto`.

Required information includes:

```text
vehicle_id[]
task_tier[]
uav_geofence
```

The mission request should be treated as a single configuration message rather than separate topics for each field.

---

# 5. Vehicle Heartbeat

Every vehicle must periodically publish a heartbeat.

## Topics

```text
/system/vehicle/uav/heartbeat
/system/vehicle/usv/heartbeat
/system/vehicle/uuv/heartbeat
```

### Message

The heartbeat follows the information defined in `rx_report.proto`.

```text
RobotState state
LatLng position
float spd_mps
float heading_deg
float roll_deg
float pitch_deg
float altitude_hae_m
float depth_m
RxTask current_task
VehicleType vehicle_type
FlightPhase flight_phase
```

Vehicle-specific fields:

| Field            | UAV | USV | UUV |
| ---------------- | :-: | :-: | :-: |
| `state`          |  ✓  |  ✓  |  ✓  |
| `position`       |  ✓  |  ✓  |  ✓  |
| `spd_mps`        |  ✓  |  ✓  |  ✓  |
| `heading_deg`    |  ✓  |  ✓  |  ✓  |
| `roll_deg`       |  ✓  |  ✓  |  ✓  |
| `pitch_deg`      |  ✓  |  ✓  |  ✓  |
| `altitude_hae_m` |  ✓  |  ✓  |  ✓  |
| `depth_m`        |  —  |  —  |  ✓  |
| `current_task`   |  ✓  |  ✓  |  ✓  |
| `vehicle_type`   |  ✓  |  ✓  |  ✓  |
| `flight_phase`   |  ✓  |  —  |  —  |

The heartbeat should be published continuously while the vehicle is operational.

---

# 6. UAV Interface

The UAV publishes the following System Interface topics.

## 6.1 UAV Heartbeat

```text
/system/vehicle/uav/heartbeat
```

---

## 6.2 UAV Task 1

Task 1 provides buoy information to the other systems.

### Entry Buoy

```text
/system/vehicle/uav/task1/entry_buoy
```

Content:

```text
LatLng
```

### Exit Buoy

```text
/system/vehicle/uav/task1/exit_buoy
```

Content:

```text
LatLng
```

### Buoy Detection

```text
/system/vehicle/uav/task1/buoy_detection
```

Content:

```text
LatLng
state
```

The `state` describes the detected buoy state according to the RobotX mission requirements.

The same topics are used regardless of mission tier. The active mission tier determines when the information is required.

---

## 6.3 UAV Task 2

For Advance and Disruptive tiers, the UAV reports the active buoy and delivery information.

### Active Buoy

```text
/system/vehicle/uav/task2/active_buoy
```

Content:

```text
LatLng
```

### Delivery Information

```text
/system/vehicle/uav/task2/delivery
```

Content:

```text
resource_color
delivery_color
```

`resource_color` identifies the resource/tin to deliver.

`delivery_color` identifies the target circle/color.

Example:

```text
resource_color = RED
delivery_color = GREEN
```

---

## 6.4 UAV Task 3

### Delivery Information

```text
/system/vehicle/uav/task3/delivery
```

Content:

```text
resource_color
delivery_color
```

---

## 6.5 UAV Task 4

### Status

```text
/system/vehicle/uav/task4/status
```

The status message must include the relevant:

```text
command_seq
status
```

The `command_seq` is used to correlate the vehicle response with the command received from RoboCommand.

---

# 7. USV Interface

## 7.1 USV Heartbeat

```text
/system/vehicle/usv/heartbeat
```

---

## 7.2 USV Task 1

### Entry Buoy

```text
/system/vehicle/usv/task1/entry_buoy
```

Content:

```text
LatLng
```

### Exit Buoy

```text
/system/vehicle/usv/task1/exit_buoy
```

Content:

```text
LatLng
```

### Buoy Detection

```text
/system/vehicle/usv/task1/buoy_detection
```

Content:

```text
LatLng
state
```

These topics follow the same interface structure as the UAV Task 1 report.

---

## 7.3 USV Task 3

### Docking

```text
/system/vehicle/usv/task3/docking
```

Content:

```text
bay_id
extinguished_window_id
```

`bay_id` identifies the docking bay.

`extinguished_window_id` identifies the window/light that was extinguished and subsequently changed from red to green.

### Delivery

```text
/system/vehicle/usv/task3/delivery
```

Content:

```text
resource_color
delivery_color
```

---

## 7.4 USV Task 4

### Status

```text
/system/vehicle/usv/task4/status
```

Content:

```text
command_seq
status
```

---

# 8. UUV Interface

## 8.1 UUV Heartbeat

```text
/system/vehicle/uuv/heartbeat
```

---

## 8.2 UUV Task 1

### Entry Buoy

```text
/system/vehicle/uuv/task1/entry_buoy
```

Content:

```text
LatLng
```

### Exit Buoy

```text
/system/vehicle/uuv/task1/exit_buoy
```

Content:

```text
LatLng
```

### Buoy Detection

```text
/system/vehicle/uuv/task1/buoy_detection
```

Content:

```text
LatLng
state
```

---

## 8.3 UUV Task 2

### Active Buoy

```text
/system/vehicle/uuv/task2/active_buoy
```

Content:

```text
LatLng
```

The active buoy is identified using the acoustic pinger.

### Pipeline Status

```text
/system/vehicle/uuv/task2/pipeline
```

Content:

```text
status
```

Valid values:

```text
UNKNOWN
INTACT
DAMAGED
```

### Delivery Information

```text
/system/vehicle/uuv/task2/delivery
```

Content:

```text
resource_color
delivery_color
```

Example:

```text
resource_color = RED
delivery_color = GREEN
```

---

## 8.4 UUV Task 4

### Status

```text
/system/vehicle/uuv/task4/status
```

Content:

```text
command_seq
status
```

---

# 9. Task 4 — Coordinated Vehicle Command

Task 4 is controlled through RoboCommand.

All Task 4 commands use:

```text
/system/mission/command
```

The command identifies the target vehicle using `vehicle_type` or the appropriate vehicle identifier defined in the protocol.

The response is published through:

```text
/system/vehicle/<vehicle>/task4/status
```

---

# 10. Task 4 Core

### RoboCommand → Vehicle

The vehicle receives:

```text
target coordinate
vehicle type
command_seq
```

The vehicle must:

1. Receive the command.
2. Record the `command_seq`.
3. Navigate toward the target coordinate.
4. Report the received `command_seq`.
5. Once the target is reached, report the same `command_seq`.
6. Wait for `ReadinessConfirm`.
7. Resume the previous mission.

Example:

```text
RoboCommand
     │
     │ /system/mission/command
     │ command_seq = 42
     │ target = (lat, lon)
     ▼
 Vehicle
     │
     │ /system/vehicle/<vehicle>/task4/status
     │ command_seq = 42
     ▼
RoboCommand
     │
     │ ReadinessConfirm
     ▼
 Vehicle
     │
     └── Resume mission
```

The vehicle must not generate a new sequence number for the acknowledgement. The original `command_seq` must be preserved.

---

# 11. Task 4 Advance

### RoboCommand → Vehicle

The vehicle receives:

```text
center coordinate
radius_m
vehicle type
command_seq
```

The vehicle must avoid entering the specified circular region.

Conceptually:

```text
              radius
          <------------>
              ______
           .-'      '-.
         .'            '.
        /       X        \
        \                /
         '.            .'
           '-.______.-'
                ↑
             center
```

After receiving the command, the vehicle reports the corresponding `command_seq`.

Once RoboCommand determines that the restriction can be cleared, it sends `AllClear`.

The vehicle then returns the same `command_seq` in its response.

---

# 12. Task 4 Disruptive

### RoboCommand → Vehicle

The vehicle receives information about another vehicle/object that must be avoided:

```text
position
heading
speed
vehicle_type
command_seq
```

The receiving vehicle uses this information as an external dynamic obstacle.

The vehicle should not reinterpret or modify the received `command_seq`.

The command and response use:

```text
/system/mission/command
/system/vehicle/<vehicle>/task4/status
```

---

# 13. Complete Topic List

## Common

```text
/system/mission/request
/system/mission/command
/system/mission/status
```

## UAV

```text
/system/vehicle/uav/heartbeat

/system/vehicle/uav/task1/entry_buoy
/system/vehicle/uav/task1/exit_buoy
/system/vehicle/uav/task1/buoy_detection

/system/vehicle/uav/task2/active_buoy
/system/vehicle/uav/task2/delivery

/system/vehicle/uav/task3/delivery

/system/vehicle/uav/task4/status
```

## USV

```text
/system/vehicle/usv/heartbeat

/system/vehicle/usv/task1/entry_buoy
/system/vehicle/usv/task1/exit_buoy
/system/vehicle/usv/task1/buoy_detection

/system/vehicle/usv/task3/docking
/system/vehicle/usv/task3/delivery

/system/vehicle/usv/task4/status
```

## UUV

```text
/system/vehicle/uuv/heartbeat

/system/vehicle/uuv/task1/entry_buoy
/system/vehicle/uuv/task1/exit_buoy
/system/vehicle/uuv/task1/buoy_detection

/system/vehicle/uuv/task2/active_buoy
/system/vehicle/uuv/task2/pipeline
/system/vehicle/uuv/task2/delivery

/system/vehicle/uuv/task4/status
```

---

# 14. Communication Responsibility

Each vehicle team is responsible for implementing the System Interface independently.

The implementation inside each vehicle may be different, but the external interface must remain identical.

For example:

```text
                     UAV
        ┌───────────────────────────┐
        │                            │
        │  vision_geo                │
        │       │                    │
        │       ▼                    │
        │  Communication Node       │
        │       │                    │
        └───────┼────────────────────┘
                │
                ▼
 /system/vehicle/uav/task1/buoy_detection
```

The UAV's internal vision topics do not need to be exposed outside the UAV domain.

The same principle applies to the USV and UUV.

---

# 15. Internal vs System Topics

## System Topics

These are allowed to cross DDS domains:

```text
/system/...
```

They form the public API of the System-of-Systems.

## Internal Topics

Vehicle-specific topics remain inside their respective ROS 2 domains.

Examples:

```text
/camera/image_raw
/lidar/points
/map
/costmap
/tf
/tf_static
/vision_geo/detections
/vision_geo/markers
```

These topics should not be routed through DDS Router unless there is a specific system requirement.

This prevents high-bandwidth sensor data and implementation-specific topics from unnecessarily occupying the inter-vehicle network.

---

# 16. Migration From Existing UAV Interface

The current UAV implementation uses:

```text
/mission/order
```

with commands such as:

```text
UAV-GO
MISSION-DONE
UAV-GO:RED:GREEN
```

This should be considered an **internal/legacy interface**.

The System-of-Systems interface should instead use structured messages through:

```text
/system/mission/command
```

For example, instead of:

```text
UAV-GO:RED:GREEN
```

the communication layer should provide structured information equivalent to:

```text
command_type: UAV_DELIVERY
resource_color: RED
delivery_color: GREEN
```

This removes the need for string parsing and makes the interface consistent with RoboCommand's protobuf definitions.

The existing UAV control logic can remain unchanged initially by implementing a translation layer:

```text
/system/mission/command
          │
          ▼
 UAV Communication Node
          │
          ▼
   /mission/order
          │
          ▼
   Existing UAV Control
```

This allows the new System Interface to be integrated without immediately rewriting the existing UAV mission controller.

---

# 17. UUV Communication Model

The UUV does not require continuous communication while submerged.

The UUV may operate using a store-and-forward communication model:

```text
          UUV
           │
        Dive
           │
           ▼
   Perform mission
           │
           ▼
      Store data
           │
           ▼
        Surface
           │
           ▼
     Wi-Fi connected
           │
           ▼
 Synchronize System topics
           │
           ▼
     Receive ACK
           │
           ▼
        Dive
```

Only information required by the System-of-Systems needs to be synchronized.

High-bandwidth underwater sensor data remains local to the UUV unless explicitly required.

---

# 18. Implementation Requirements

Every vehicle implementation must:

* Use the exact topic names defined in this document.
* Use the message definitions specified by the shared protobuf/ROS interface.
* Preserve `command_seq` when responding to commands.
* Publish heartbeat continuously while operational.
* Publish task reports when the corresponding mission event occurs.
* Subscribe only to commands relevant to the vehicle.
* Keep internal sensor and control topics private to the vehicle's ROS domain.
* Avoid using string-based commands for the final System Interface.
* Maintain compatibility with the common `rx_request.proto`, `rx_report.proto`, and `rx_common.proto` definitions.

The vehicle's internal architecture may remain different between teams as long as the external System Interface remains compatible.

---

# 19. DDS Router Interface

The DDS Router should be configured to expose only the System Interface.

Conceptually, the allowed namespace is:

```text
/system/...
```

while topics such as:

```text
/camera/...
/lidar/...
/map
/costmap
/tf
/tf_static
```

remain local.

The resulting communication architecture is:

```text
                  ┌──────────────────┐
                  │   RoboCommand    │
                  │    Domain 10     │
                  └────────┬─────────┘
                           │
                     DDS Router
                           │
          ┌────────────────┼────────────────┐
          │                │                │
       Domain 20        Domain 30        Domain 40
          │                │                │
         USV              UAV              UUV
          │                │                │
     /system/...      /system/...      /system/...
          │                │                │
     Internal only     Internal only    Internal only
```

The `/system/...` namespace is therefore the **contract between the four independent systems**.

---

# 20. Interface Principle

The key design principle is:

> **Vehicle implementation is independent; System Interface is shared.**

Each team may implement perception, localization, planning, control, and mission logic differently.

However, when communicating with another system, the vehicle must use the common interface defined in this document.

This allows the UAV, USV, UUV, and RoboCommand systems to be developed and tested independently while still operating as a single integrated RobotX System-of-Systems.

---

# 21. ROS 2 Interface Package — `rx_msgs`

The System Interface is implemented as a single ROS 2 interface package:

```text
rx_msgs/
├── CMakeLists.txt
├── package.xml
└── msg/
    ├── LatLng.msg
    ├── VehicleType.msg
    ├── RobotState.msg
    ├── FlightPhase.msg
    ├── RxTask.msg
    ├── TaskTier.msg
    ├── Color.msg
    ├── MissionRequest.msg
    ├── MissionCommand.msg
    ├── MissionStatus.msg
    ├── Heartbeat.msg
    ├── BuoyDetection.msg
    ├── Delivery.msg
    ├── PipelineStatus.msg
    ├── Docking.msg
    └── Task4Status.msg
```

All four systems (RoboCommand, UAV, USV, UUV) depend on this package. No other interface package is needed: the contract is the `/system/...` topics defined in this document, typed by the `rx_msgs` messages below.

## 21.1 Topic → Message Type Mapping

| Topic | Type |
| --- | --- |
| `/system/mission/request` | `rx_msgs/msg/MissionRequest` |
| `/system/mission/command` | `rx_msgs/msg/MissionCommand` |
| `/system/mission/status` | `rx_msgs/msg/MissionStatus` |
| `/system/vehicle/uav/heartbeat` | `rx_msgs/msg/Heartbeat` |
| `/system/vehicle/usv/heartbeat` | `rx_msgs/msg/Heartbeat` |
| `/system/vehicle/uuv/heartbeat` | `rx_msgs/msg/Heartbeat` |
| `/system/vehicle/<vehicle>/task1/entry_buoy` | `rx_msgs/msg/LatLng` |
| `/system/vehicle/<vehicle>/task1/exit_buoy` | `rx_msgs/msg/LatLng` |
| `/system/vehicle/<vehicle>/task1/buoy_detection` | `rx_msgs/msg/BuoyDetection` |
| `/system/vehicle/uav/task2/active_buoy` | `rx_msgs/msg/LatLng` |
| `/system/vehicle/uuv/task2/active_buoy` | `rx_msgs/msg/LatLng` |
| `/system/vehicle/uuv/task2/pipeline` | `rx_msgs/msg/PipelineStatus` |
| `/system/vehicle/uav/task2/delivery` | `rx_msgs/msg/Delivery` |
| `/system/vehicle/uuv/task2/delivery` | `rx_msgs/msg/Delivery` |
| `/system/vehicle/uav/task3/delivery` | `rx_msgs/msg/Delivery` |
| `/system/vehicle/usv/task3/delivery` | `rx_msgs/msg/Delivery` |
| `/system/vehicle/usv/task3/docking` | `rx_msgs/msg/Docking` |
| `/system/vehicle/uav/task4/status` | `rx_msgs/msg/Task4Status` |
| `/system/vehicle/usv/task4/status` | `rx_msgs/msg/Task4Status` |
| `/system/vehicle/uuv/task4/status` | `rx_msgs/msg/Task4Status` |

## 21.2 Message Definitions

```text
rx_msgs/msg/LatLng
    float64 lat_deg
    float64 lon_deg

rx_msgs/msg/MissionRequest
    std_msgs/Header header
    uint32 mission_id
    string[] vehicle_id
    uint8[] task_tier              # TaskTier constants
    rx_msgs/LatLng[] uav_geofence

rx_msgs/msg/MissionCommand
    std_msgs/Header header
    uint64 command_seq
    uint8 target_vehicle           # VehicleType constants, UNKNOWN = broadcast
    uint8 command_type             # MissionCommand constants
    rx_msgs/LatLng target          # CMD_TASK4_NAVIGATE / CMD_TASK4_AVOID_ZONE
    float32 radius_m               # CMD_TASK4_AVOID_ZONE
    rx_msgs/LatLng obstacle_position    # CMD_TASK4_DYNAMIC_AVOID
    float32 obstacle_heading_deg
    float32 obstacle_speed_mps
    uint8 resource_color           # CMD_DELIVERY, Color constants
    uint8 delivery_color
    string detail

rx_msgs/msg/MissionStatus
    std_msgs/Header header
    uint32 mission_id
    string vehicle_id
    uint8 state                    # RobotState constants
    uint8 current_task             # RxTask constants
    string message

rx_msgs/msg/Heartbeat
    std_msgs/Header header
    uint8 state                    # RobotState constants
    rx_msgs/LatLng position
    float32 spd_mps
    float32 heading_deg
    float32 roll_deg
    float32 pitch_deg
    float32 altitude_hae_m
    float32 depth_m                # UUV only
    uint8 current_task             # RxTask constants
    uint8 vehicle_type             # VehicleType constants
    uint8 flight_phase             # FlightPhase constants, UAV only

rx_msgs/msg/BuoyDetection
    std_msgs/Header header
    rx_msgs/LatLng position
    uint8 state                    # BuoyDetection constants

rx_msgs/msg/Delivery
    std_msgs/Header header
    uint8 resource_color           # Color constants
    uint8 delivery_color

rx_msgs/msg/PipelineStatus
    std_msgs/Header header
    uint8 status                   # PipelineStatus constants

rx_msgs/msg/Docking
    std_msgs/Header header
    uint32 bay_id
    uint32 extinguished_window_id

rx_msgs/msg/Task4Status
    std_msgs/Header header
    uint64 command_seq             # must equal the received command_seq
    uint8 status                   # Task4Status constants
    string detail
```

## 21.3 Constants

```text
VehicleType:    UNKNOWN=255  UAV=0  USV=1  UUV=2

RobotState:     STATE_UNKNOWN=0  STATE_OFFLINE=1  STATE_IDLE=2  STATE_READY=3
                STATE_MISSION=4  STATE_RETURNING=5  STATE_LANDED=6  STATE_DOCKED=7
                STATE_EMERGENCY=8  STATE_FAULT=9

FlightPhase:    PHASE_UNKNOWN=0  PHASE_TAXI=1  PHASE_TAKEOFF=2  PHASE_CRUISE=3
                PHASE_APPROACH=4  PHASE_LANDING=5  PHASE_LANDED=6  PHASE_EMERGENCY=7

RxTask:         TASK_NONE=0  TASK_1=1  TASK_2=2  TASK_3=3  TASK_4=4

TaskTier:       TIER_UNKNOWN=0  TIER_CORE=1  TIER_ADVANCE=2  TIER_DISRUPTIVE=3

Color:          COLOR_UNKNOWN=0  COLOR_RED=1  COLOR_GREEN=2  COLOR_BLUE=3  COLOR_YELLOW=4

MissionCommand: CMD_NONE=0  CMD_GO=1  CMD_MISSION_DONE=2  CMD_DELIVERY=3
                CMD_TASK4_NAVIGATE=4  CMD_TASK4_AVOID_ZONE=5  CMD_TASK4_DYNAMIC_AVOID=6
                CMD_READINESS_CONFIRM=7  CMD_ALL_CLEAR=8

BuoyDetection:  STATE_UNKNOWN=0  STATE_NORMAL=1  STATE_DAMAGED=2  STATE_MISSING=3

PipelineStatus: PIPELINE_UNKNOWN=0  PIPELINE_INTACT=1  PIPELINE_DAMAGED=2

Task4Status:    TASK4_UNKNOWN=0  TASK4_RECEIVED=1  TASK4_NAVIGATING=2  TASK4_REACHED=3
                TASK4_ACTIVE=4  TASK4_CLEARED=5  TASK4_REJECTED=6  TASK4_FAILED=7
```

## 21.4 Build and Usage

```bash
source /opt/ros/<distro>/setup.bash
colcon build --packages-select rx_msgs
source install/setup.bash
```

Inspect and use the interface:

```bash
ros2 interface show rx_msgs/MissionCommand
ros2 interface list -p rx_msgs

# example: publish a Task 4 Core command (RoboCommand, domain 10)
ros2 topic pub -r 1 /system/mission/command rx_msgs/MissionCommand \
  "{command_seq: 42, target_vehicle: 0, command_type: 4, target: {lat_deg: 1.02, lon_deg: 103.83}}"

# example: echo a heartbeat (RoboCommand)
ros2 topic echo /system/vehicle/uav/heartbeat rx_msgs/Heartbeat
```

Vehicle teams may add their own implementation packages (communication nodes, translation layers, etc.) on top of `rx_msgs`, but they must use exactly these topic names, message types, and constant values. If the protobuf definitions (`rx_request.proto`, `rx_report.proto`, `rx_common.proto`) evolve, `rx_msgs` must be updated so that all four systems continue to interoperate.
