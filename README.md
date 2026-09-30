# RobotX 2026 — System-of-Systems ROS 2 Interface

This document is the communication contract for the three vehicles (one UAV, one USV, one UUV) and RoboCommand/GCS.

Each vehicle is developed as an independent system. All inter-vehicle and RoboCommand communication must use the topics, message types, and constants defined here. Vehicle internals are free; the external interface must stay identical across all teams.

**Rules**

- Use the exact topic names and `rx_msgs` message types defined in this document.
- Never modify or regenerate `command_seq` when responding to a command.
- Publish the heartbeat continuously while the vehicle is operational.
- Keep internal topics (`/camera/...`, `/lidar/...`, `/map`, `/costmap`, `/tf`, `/tf_static`, `/vision_geo/...`) private to your ROS 2 domain. Only `/system/...` topics are routed between domains.

---

## 1. Domains

| System            | ROS_DOMAIN_ID |
| ----------------- | ------------: |
| RoboCommand / GCS |        `10`   |
| USV               |        `20`   |
| UAV               |        `30`   |
| UUV               |        `40`   |

A DDS Router on the GCS bridges only `/system/...` topics between domains.

```text
               RoboCommand / GCS (10)
                        │
              DDS Router — /system/... only
       ┌────────────────┼────────────────┐
      USV (20)        UAV (30)        UUV (40)
```

---

## 2. Topic Naming

```text
/system/mission/<name>
/system/vehicle/<vehicle>/<name>
/system/vehicle/<vehicle>/task<N>/<name>
```

`<vehicle>` = `uav | usv | uuv`, `<N>` = `1 | 2 | 3 | 4`, names in lowercase `snake_case`.

---

## 3. Common Interface (all vehicles)

### 3.1 Mission topics

| Topic                     | Direction | Type                  |
| ------------------------- | --------- | --------------------- |
| `/system/mission/request` | subscribe | `rx_msgs/MissionRequest`   |
| `/system/mission/command` | subscribe | `rx_msgs/MissionCommand`   |
| `/system/mission/status`  | publish   | `rx_msgs/MissionStatus`    |

- `MissionRequest` arrives before the mission starts and carries the whole configuration (`vehicle_id[]`, `task_tier[]`, `uav_geofence`) as a single message.
- `MissionCommand` selects its target with `target_vehicle` (`255` = broadcast). Subscribe only to commands relevant to your vehicle.
- Publish `MissionStatus` with your overall mission state.

### 3.2 Heartbeat

Publish `/system/vehicle/<vehicle>/heartbeat` (`rx_msgs/Heartbeat`) continuously (≥ 1 Hz) while operational.

| Field                                                                  | UAV | USV | UUV |
| ---------------------------------------------------------------------- | :-: | :-: | :-: |
| `state`, `position`, `spd_mps`, `heading_deg`, `roll_deg`, `pitch_deg`, `altitude_hae_m` | ✓ | ✓ | ✓ |
| `depth_m`                                                              |  —  |  —  |  ✓  |
| `current_task`, `vehicle_type`                                         |  ✓  |  ✓  |  ✓  |
| `flight_phase`                                                         |  ✓  |  —  |  —  |

### 3.3 Task 1 — buoy reports

| Topic                                          | Type                   |
| ---------------------------------------------- | ---------------------- |
| `/system/vehicle/<vehicle>/task1/entry_buoy`   | `rx_msgs/LatLng`       |
| `/system/vehicle/<vehicle>/task1/exit_buoy`    | `rx_msgs/LatLng`       |
| `/system/vehicle/<vehicle>/task1/buoy_detection` | `rx_msgs/BuoyDetection` |

The same topics are used for every mission tier; the active tier determines when the information is required.

---

## 4. Per-Vehicle Interface

### 4.1 UAV

| Topic                                    | Type                  |
| ---------------------------------------- | --------------------- |
| `/system/vehicle/uav/task2/active_buoy`  | `rx_msgs/LatLng`      |
| `/system/vehicle/uav/task2/delivery`     | `rx_msgs/Delivery`    |
| `/system/vehicle/uav/task3/delivery`     | `rx_msgs/Delivery`    |
| `/system/vehicle/uav/task4/status`       | `rx_msgs/Task4Status` |

- Task 2 reports are required for the Advance and Disruptive tiers.
- **Legacy bridge:** the existing UAV mission controller consumes the internal `/mission/order` topic with string commands (`UAV-GO`, `UAV-GO:RED:GREEN`, `MISSION-DONE`). Your communication layer must translate `/system/mission/command` into these strings and keep `/mission/order` inside the UAV domain.

### 4.2 USV

| Topic                                   | Type                  |
| --------------------------------------- | --------------------- |
| `/system/vehicle/usv/task3/docking`     | `rx_msgs/Docking`     |
| `/system/vehicle/usv/task3/delivery`    | `rx_msgs/Delivery`    |
| `/system/vehicle/usv/task4/status`      | `rx_msgs/Task4Status` |

`Docking` carries `bay_id` and `extinguished_window_id` (the window/light that was extinguished and changed from red to green).

### 4.3 UUV

| Topic                                    | Type                   |
| ---------------------------------------- | ---------------------- |
| `/system/vehicle/uuv/task2/active_buoy`  | `rx_msgs/LatLng`       |
| `/system/vehicle/uuv/task2/pipeline`     | `rx_msgs/PipelineStatus` |
| `/system/vehicle/uuv/task2/delivery`     | `rx_msgs/Delivery`     |
| `/system/vehicle/uuv/task4/status`       | `rx_msgs/Task4Status`  |

- The active buoy is identified using the acoustic pinger.
- **Store-and-forward:** no continuous communication while submerged. When surfaced and Wi-Fi connected, synchronize the system topics, wait for the ACK, then dive again. High-bandwidth sensor data stays local.

---

## 5. Task 4 — Coordinated Commands

All Task 4 commands arrive on `/system/mission/command`. Responses are published on `/system/vehicle/<vehicle>/task4/status` (`rx_msgs/Task4Status`).

| `command_type`            | Fields                                        | Behavior                                                                                                                                       |
| ------------------------- | --------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `CMD_TASK4_NAVIGATE` (Core) | `target`                                    | Navigate to the target. Report the received `command_seq` on receipt and again on arrival. Wait for `CMD_READINESS_CONFIRM`, then resume the previous mission. |
| `CMD_TASK4_AVOID_ZONE` (Advance) | `target`, `radius_m`                   | Avoid the circular region. Report the `command_seq`. After `CMD_ALL_CLEAR`, report the same `command_seq`.                                             |
| `CMD_TASK4_DYNAMIC_AVOID` (Disruptive) | `obstacle_position`, `obstacle_heading_deg`, `obstacle_speed_mps` | Use the other vehicle as an external dynamic obstacle.                                                     |

`CMD_READINESS_CONFIRM` and `CMD_ALL_CLEAR` are also sent on `/system/mission/command`.

**`command_seq` rule:** every response must carry exactly the `command_seq` received with the command. The vehicle must never generate or renumber it.

`Task4Status.status`: `TASK4_RECEIVED`, `TASK4_NAVIGATING`, `TASK4_REACHED`, `TASK4_ACTIVE`, `TASK4_CLEARED`, `TASK4_REJECTED`, `TASK4_FAILED`.

---

## 6. `rx_msgs` Package

```bash
colcon build --packages-select rx_msgs
source install/setup.bash
ros2 interface list | grep rx_msgs
```

### 6.1 Message definitions

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

### 6.2 Constants

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

If the protobuf definitions (`rx_request.proto`, `rx_report.proto`, `rx_common.proto`) evolve, `rx_msgs` must be updated and every system re-verified so all four remain interoperable.
