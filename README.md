# RobotX 2026 — Vehicle ⇄ GCS ROS 2 Interface (UAV · USV · UUV)

This repository defines the ROS 2 interface between the team's three vehicles (one UAV, one USV, one UUV) and the team's GCS.

- All vehicle ⇄ GCS communication uses the `/system/...` topics and `rx_msgs` types defined here.
- The GCS is the team's only RoboCommand endpoint (MQTT + protobuf, handbook §3.4; implemented in the GCS repo). **Vehicles must not connect to RoboCommand directly.**
- Message names and constant values mirror the official RoboCommand schemas (`robonation/robocommand`, `RobotX_2026/`), so the GCS can relay them to RoboCommand unchanged.

**Rules (vehicles)**

- Use the exact topic names and `rx_msgs` message types defined here.
- Publish the heartbeat at **2 Hz** while active. UAV heartbeats are relayed to Garuda Robotics (Network Remote ID) and must be complete and reliable.
- `current_task` transitions are authoritative: a transition into a task value begins the attempt; a transition to `TASK_NONE` ends it. Never use `TASK_UNKNOWN`.
- Preserve the sequence references exactly as received (`command_seq`, `report_seq`); never renumber.
- Use `TIER_NONE`, not `TIER_UNKNOWN`, for tasks the team is not attempting.
- Keep internal topics (`/camera/...`, `/lidar/...`, `/map`, `/costmap`, `/tf`, `/tf_static`, ...) private to the vehicle; only `/system/...` crosses to the GCS.

---

## 1. Architecture

```text
 UAV (domain 30)   USV (domain 20)   UUV (domain 40)
        │               │               │
        └────── ROS 2 /system/... ──────┘   DDS Router: /system/... only
                        │
                    Team GCS (domain 10)
```

| System | ROS_DOMAIN_ID |
| ------ | ------------: |
| GCS    |        `10`   |
| USV    |        `20`   |
| UAV    |        `30`   |
| UUV    |        `40`   |

The GCS publishes course configuration and commands to the vehicles and collects their heartbeats and task reports. How the GCS talks to RoboCommand is out of scope for this repository.

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

| Topic                   | Direction | Type                  |
| ----------------------- | --------- | --------------------- |
| `/system/mission/course` | subscribe | `rx_msgs/Course`     |
| `/system/mission/command` | subscribe | `rx_msgs/Command`  |
| `/system/mission/status` | publish   | `rx_msgs/MissionStatus` |

- `Course` is published once before the run: `course_id`, `pinger_freq_hz` (UUV homing), the course boundary (closed polygon), and the `uav_geofence` (closed polygon within the boundary).
- `Command` targets a vehicle via `target_vehicle` (`TYPE_UNKNOWN` = all vehicles). `CMD_RUN_START` carries `run_id`.
- **Position-hold until the run start:** after switching to autonomous mode, no vehicle begins the run until `CMD_RUN_START` is received.

### 3.2 Heartbeat

Publish `/system/vehicle/<vehicle>/heartbeat` (`rx_msgs/Heartbeat`) at 2 Hz while active.

| Field                                                                   | UAV | USV | UUV |
| ----------------------------------------------------------------------- | :-: | :-: | :-: |
| `state`, `position`, `spd_mps`, `heading_deg`, `roll_deg`, `pitch_deg`, `altitude_hae_m` | ✓ | ✓ | ✓ |
| `depth_m`                                                                |  —  |  —  |  ✓  |
| `current_task`, `vehicle_type`                                          |  ✓  |  ✓  |  ✓  |
| `flight_phase`                                                           |  ✓  |  —  |  —  |

- `state` is `STATE_KILLED`, `STATE_MANUAL`, or `STATE_AUTO`; each autonomous and ready vehicle reports `STATE_AUTO` before the run starts.
- `current_task` uses `RxTask` values (`TASK_SAFE_PASSAGE`, `TASK_INFRA_SURVEY_REPAIR`, `TASK_COORDINATED_LOGISTICS`, `TASK_DYNAMIC_INCIDENT`); `TASK_NONE` = no task in progress.

---

## 4. Per-Vehicle Interface

### 4.1 UAV

| Topic                                  | Type                   |
| -------------------------------------- | ---------------------- |
| `/system/vehicle/uav/task1/safe_passage` | `rx_msgs/SafePassage`  |
| `/system/vehicle/uav/task2/delivery`   | `rx_msgs/ResourceDelivery` |
| `/system/vehicle/uav/task3/delivery`   | `rx_msgs/ResourceDelivery` |
| `/system/vehicle/uav/task4/incident_ack` | `rx_msgs/IncidentAck`  |
| `/system/vehicle/uav/task4/readiness`  | `rx_msgs/ReadinessReport` |

- **Task 1 (UAV-only):** the UAV detects the buoy field and publishes `SafePassage` (entry, exit, all buoys) whenever a detection updates; the USV subscribes to it for mission planning. The handbook assigns the Task 1 report to the USV/UUV at Core tier and to the UAV at Advanced/Disruptive — the GCS attributes the report to the detecting vehicle, so align the declared tier with the detecting vehicle.
- **Delivery echo:** when the UAV begins a delivery, it publishes `ResourceDelivery` echoing the `resource_color` and `delivery_circle_color` of the detecting vehicle's request (`task` = the delivery task).
- Enforce the `uav_geofence` from `/system/mission/course`.
- **Legacy bridge:** the existing UAV mission controller consumes the internal `/mission/order` topic with string commands (`UAV-GO`, `UAV-GO:RED:GREEN`, `MISSION-DONE`). The communication layer must translate `Command` messages (`CMD_GO`, `CMD_DELIVERY`, `CMD_MISSION_DONE`) into these strings and keep `/mission/order` inside the UAV domain.

### 4.2 USV

| Topic                                    | Type                   |
| ---------------------------------------- | ---------------------- |
| `/system/vehicle/usv/task3/docking`      | `rx_msgs/Docking`      |
| `/system/vehicle/usv/task3/firefighting` | `rx_msgs/Firefighting` |
| `/system/vehicle/usv/task3/delivery`     | `rx_msgs/ResourceDelivery` |
| `/system/vehicle/usv/task4/incident_ack` | `rx_msgs/IncidentAck`  |
| `/system/vehicle/usv/task4/readiness`    | `rx_msgs/ReadinessReport` |

- **Subscribes** to `/system/vehicle/uav/task1/safe_passage` for mission planning.
- `Docking.bay_id` = bay (1–3) of the safe (GREEN) bay; docking also signals readiness for tasking — the window light activates after the GCS forwards the report.
- `Firefighting.window_id` = the window whose light changed RED → GREEN after the water delivery.
- When the USV reads the flashing LED code, publish `ResourceDelivery` with `task = TASK_COORDINATED_LOGISTICS`.

### 4.3 UUV

| Topic                                    | Type                   |
| ---------------------------------------- | ---------------------- |
| `/system/vehicle/uuv/task2/pipeline_survey` | `rx_msgs/PipelineSurvey` |
| `/system/vehicle/uuv/task2/delivery`     | `rx_msgs/ResourceDelivery` |
| `/system/vehicle/uuv/task4/incident_ack` | `rx_msgs/IncidentAck`  |
| `/system/vehicle/uuv/task4/readiness`    | `rx_msgs/ReadinessReport` |

- `PipelineSurvey` = active (GREEN) buoy position plus segment statuses ordered from the active buoy end. Send it once, after the survey and (Advanced tier) the repair — typically when surfaced, since the UUV cannot transmit while submerged.
- **Store-and-forward:** no continuous communication while submerged; when surfaced and connected, synchronize `/system/...` topics, wait for the ACK, then dive again.
- Use `Course.pinger_freq_hz` for acoustic homing.
- When the UUV reads the flashing LED code, publish `ResourceDelivery` with `task = TASK_INFRA_SURVEY_REPAIR`.

---

## 5. Task 4 — Dynamic Incident Response

Commands arrive on `/system/mission/command`; responses are published on `/system/vehicle/<vehicle>/task4/...`.

| Tier       | Flow                                                              |
| ---------- | ----------------------------------------------------------------- |
| Core       | assistance request → ack → readiness report → readiness confirm   |
| Advanced   | keep-out zone → ack → all clear → ack                             |
| Disruptive | moving object alert — keep ≥ 10 m from the object; no ack or clear |

Vehicle behavior:

- `CMD_TASK4_ASSISTANCE` (`position`): publish `IncidentAck{command_seq}` on receipt, transit to the position, then publish `ReadinessReport{command_seq}` (same seq as the assistance command). On `CMD_TASK4_READINESS_CONFIRM` (matched by `report_seq` + vehicle), resume the previous mission.
- `CMD_TASK4_KEEP_OUT_ZONE` (`center`, `radius_m`): publish `IncidentAck{command_seq}`, stay outside the zone. On `CMD_TASK4_ALL_CLEAR`: publish `IncidentAck{command_seq}` and resume.
- `CMD_TASK4_MOVING_OBJECT` (`position`, `heading_deg`, `speed_mps`): treat the object as a dynamic external obstacle; no acknowledgement.

---

## 6. Pre-Run Sequence

1. The GCS relays the course configuration to the vehicles as `/system/mission/course` (from the RoboCommand course config, with the team's UAV geofence).
2. The GCS publishes the team's `RunDeclaration` to RoboCommand: all participating vehicle IDs, the tier per task (`TIER_NONE` when not attempting), and the closed UAV geofence.
3. Vehicles publish heartbeats; each autonomous vehicle reports `STATE_AUTO`.
4. The GCS relays the run start as `CMD_RUN_START` (after RoboCommand has accepted the declaration).
5. Vehicles hold position until step 4, then begin the run.

---

## 7. `rx_msgs` Package

```bash
colcon build --packages-select rx_msgs
source install/setup.bash
ros2 interface list | grep rx_msgs
```

### 7.1 Message definitions

```text
rx_msgs/msg/LatLng
    float64 latitude
    float64 longitude

rx_msgs/msg/Course
    string course_id
    uint32 pinger_freq_hz
    rx_msgs/LatLng[] boundary
    rx_msgs/LatLng[] uav_geofence

rx_msgs/msg/Command
    std_msgs/Header header
    uint32 command_seq
    uint8 target_vehicle           # VehicleType constants, TYPE_UNKNOWN = all
    uint8 command_type             # Command constants
    uint32 run_id                  # CMD_RUN_START
    rx_msgs/LatLng position        # CMD_TASK4_ASSISTANCE / CMD_TASK4_MOVING_OBJECT
    rx_msgs/LatLng center          # CMD_TASK4_KEEP_OUT_ZONE
    float32 radius_m               # CMD_TASK4_KEEP_OUT_ZONE
    float32 heading_deg            # CMD_TASK4_MOVING_OBJECT
    float32 speed_mps              # CMD_TASK4_MOVING_OBJECT
    uint32 report_seq              # CMD_TASK4_READINESS_CONFIRM
    uint8 task                     # CMD_DELIVERY, RxTask constants
    uint8 resource_color           # CMD_DELIVERY, Color constants
    uint8 delivery_circle_color    # CMD_DELIVERY, Color constants
    string detail

rx_msgs/msg/MissionStatus
    std_msgs/Header header
    uint32 run_id
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
    rx_msgs/LatLng position
    uint8 state                    # BeaconState constants

rx_msgs/msg/SafePassage
    std_msgs/Header header
    rx_msgs/LatLng entry_position
    rx_msgs/LatLng exit_position
    rx_msgs/BuoyDetection[] buoys

rx_msgs/msg/PipelineSurvey
    std_msgs/Header header
    rx_msgs/LatLng active_buoy_position
    uint8[] segments               # PipelineSegmentStatus constants

rx_msgs/msg/ResourceDelivery
    std_msgs/Header header
    uint8 task                     # RxTask constants
    uint8 resource_color           # Color constants
    uint8 delivery_circle_color    # Color constants

rx_msgs/msg/Docking
    std_msgs/Header header
    uint32 bay_id

rx_msgs/msg/Firefighting
    std_msgs/Header header
    uint32 window_id

rx_msgs/msg/IncidentAck
    std_msgs/Header header
    uint32 command_seq

rx_msgs/msg/ReadinessReport
    std_msgs/Header header
    uint32 command_seq
```

### 7.2 Constants

Values mirror the RoboCommand proto schemas exactly.

```text
VehicleType:            TYPE_UNKNOWN=0  TYPE_USV=1  TYPE_UUV=2  TYPE_UAV=3

RobotState:             STATE_UNKNOWN=0  STATE_KILLED=1  STATE_MANUAL=2  STATE_AUTO=3

TaskTier:               TIER_UNKNOWN=0  TIER_NONE=1  TIER_CORE=2  TIER_ADVANCED=3  TIER_DISRUPTIVE=4

RxTask:                 TASK_UNKNOWN=0  TASK_NONE=1  TASK_SAFE_PASSAGE=2
                        TASK_INFRA_SURVEY_REPAIR=3  TASK_COORDINATED_LOGISTICS=4  TASK_DYNAMIC_INCIDENT=5

BeaconState:            BEACON_STATE_UNKNOWN=0  BEACON_STATE_OFF=1  BEACON_STATE_FLASHING_RED=2
                        BEACON_STATE_FLASHING_GREEN=3  BEACON_STATE_FLASHING_BLUE=4  BEACON_STATE_STEADY_BLUE=5

PipelineSegmentStatus:  PIPELINE_SEGMENT_UNKNOWN=0  PIPELINE_SEGMENT_INTACT=1  PIPELINE_SEGMENT_DAMAGED=2

FlightPhase:            FLIGHT_PHASE_UNKNOWN=0  FLIGHT_PHASE_GROUNDED=1  FLIGHT_PHASE_AIRBORNE=2

Color:                  COLOR_UNKNOWN=0  COLOR_RED=1  COLOR_GREEN=2  COLOR_BLUE=3  COLOR_ANY=4

Command:                CMD_NONE=0  CMD_RUN_START=1  CMD_DELIVERY=2  CMD_TASK4_ASSISTANCE=3
                        CMD_TASK4_KEEP_OUT_ZONE=4  CMD_TASK4_ALL_CLEAR=5  CMD_TASK4_MOVING_OBJECT=6
                        CMD_TASK4_READINESS_CONFIRM=7  CMD_GO=8  CMD_MISSION_DONE=9
```

If the RoboCommand schema release changes, update `rx_msgs` to match (values and field order) so the GCS relay stays compatible.
