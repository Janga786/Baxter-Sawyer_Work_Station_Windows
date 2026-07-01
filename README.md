# Baxter/Sawyer Workstation for Windows

A Docker-based development workstation for Rethink Robotics Baxter and Sawyer
robots on Windows. Baxter's SDK is stuck on ROS 1 Indigo (Ubuntu 14.04), which
is effectively impossible to run on modern hardware, let alone Windows. This
project solves that by containerizing the legacy ROS 1 stack alongside a
modern ROS 2 Humble + MoveIt 2 environment, with a `ros1_bridge` path between
them, all orchestrated with Docker Compose and driven from plain Windows
batch scripts. No Linux dual-boot or VM setup required.

## Architecture

```
+----------------------------------------------------------------------+
|                     Windows host (Docker Desktop)                     |
|                                                                       |
|  +-----------------------+          +----------------------------+   |
|  | baxter_ros1_container |          | moveit_ros2_container      |   |
|  | ROS 1 Indigo          |          | ROS 2 Humble               |   |
|  | Baxter SDK + examples |          | MoveIt 2, RViz 2           |   |
|  +-----------+-----------+          | ros1_bridge (source)       |   |
|              |                      +--------------+-------------+   |
|              |                                     |                 |
|              |        +----------------------+     |                 |
|              +--------| ros_bridge_container |-----+                 |
|              |        | ROS 1 <-> ROS 2      |                       |
|              |        +----------------------+                       |
|              |                                                       |
|              |          shared_ws/ mounted at /shared_ws             |
+--------------+-------------------------------------------------------+
               |
               |  Ethernet (ROS_MASTER_URI=http://192.168.42.2:11311)
               v
     Baxter / Sawyer robot (runs the ROS 1 master on board)
```

- **`baxter_ros1_container`** (`baxter_ros1/Dockerfile`) — ROS 1 Indigo with
  the Rethink Robotics SDK (`baxter`, `baxter_interface`, `baxter_tools`,
  `baxter_common`, `baxter_examples`) cloned and built in a catkin workspace
  at `/ros/ws_baxter`. `ROS_MASTER_URI` points at the robot, which runs the
  ROS master on its on-board computer. This container is what talks to the
  physical robot.
- **`ros_bridge_container`** (`bridge/Dockerfile`) — an Ubuntu 18.04
  environment with ROS 1 Melodic message packages and the tooling needed to
  build `ros1_bridge`, so ROS 2 nodes can exchange topics with the ROS 1
  robot. See [Known limitations](#known-limitations).
- **`moveit_ros2_container`** (`moveit_ros2/Dockerfile`) — ROS 2 Humble with
  MoveIt 2, `ros2_control`, RViz 2, and the `ros1_bridge` source in a colcon
  workspace at `/ros/ws_moveit2`. Used for motion planning and new ROS 2
  development.
- **`shared_ws/`** — mounted at `/shared_ws` in the ROS 1 and MoveIt
  containers, so scripts written on the Windows host are immediately
  available inside both.

## Repository layout

```
baxter_ros1/        Dockerfile for the ROS 1 Indigo + Baxter SDK container
bridge/             Dockerfile for the ROS 1 <-> ROS 2 bridge container
moveit_ros2/        Dockerfile for the ROS 2 Humble + MoveIt 2 container
shared_ws/          Host-mounted workspace (example: simple_baxter_control.py)
docs/               ROS 2 startup notes and Sawyer simulation commands
docker-compose.yml  Orchestrates the three containers
setup.bat           Checks Docker, builds and starts everything
test_baxter.bat     Enables the robot and runs a short movement test
start_moveit.bat    Enables the robot and opens a MoveIt container shell
stop_all.bat        Stops all containers
```

## Prerequisites

- [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
  with Linux containers enabled
- [Git for Windows](https://git-scm.com/download/win)
- A network connection to the robot (default IP `192.168.42.2`)
- Optional, for GUI tools such as RViz 2: an X server on the host
  (e.g. [VcXsrv](https://sourceforge.net/projects/vcxsrv/))

## Quick start

```bat
git clone https://github.com/Janga786/Baxter-Sawyer_Work_Station_Windows.git
cd Baxter-Sawyer_Work_Station_Windows
setup.bat
```

`setup.bat` verifies Docker is installed and running, then runs
`docker-compose build` (expect 15–20 minutes on the first build) and
`docker-compose up -d`, and prints the most common robot commands.

If your robot is not at the default IP, set it first:

```bat
set BAXTER_IP=192.168.42.2
setup.bat
```

Equivalent manual commands:

```bat
docker-compose build
docker-compose up -d
docker-compose ps
```

## Usage

Enable the robot (required before any movement):

```bat
docker exec -it baxter_ros1_container bash -c "source /opt/ros/indigo/setup.bash && source /ros/ws_baxter/devel/setup.bash && rosrun baxter_tools enable_robot.py -e"
```

Run a quick movement test (or use `test_baxter.bat`, which does both steps):

```bat
docker exec -it baxter_ros1_container bash -c "source /opt/ros/indigo/setup.bash && source /ros/ws_baxter/devel/setup.bash && rosrun baxter_examples joint_velocity_wobbler.py"
```

Run the included example script (a joint-position wave demo using the Baxter
SDK, from the shared workspace):

```bat
docker exec -it baxter_ros1_container bash -c "source /opt/ros/indigo/setup.bash && source /ros/ws_baxter/devel/setup.bash && python /shared_ws/simple_baxter_control.py"
```

Open a ROS 2 / MoveIt shell (or use `start_moveit.bat`, which also enables
the robot first):

```bat
docker exec -it moveit_ros2_container bash -c "cd /shared_ws && source /opt/ros/humble/setup.bash && bash"
```

Disable the robot:

```bat
docker exec -it baxter_ros1_container bash -c "source /opt/ros/indigo/setup.bash && source /ros/ws_baxter/devel/setup.bash && rosrun baxter_tools enable_robot.py -d"
```

Stop everything (or use `stop_all.bat`):

```bat
docker-compose down
```

For ROS 2 workflow notes and Sawyer (Intera SDK) simulation commands, see
[`docs/ros2_startup.md`](docs/ros2_startup.md) and
[`docs/sawyer_simulation_commands.md`](docs/sawyer_simulation_commands.md).

## Known limitations

- **The `ros1_bridge` build is a manual step.** Building `ros1_bridge`
  requires sourcing a ROS 1 and a ROS 2 environment in the same shell, which
  cannot be done at image-build time across containers. The bridge container
  ships the prerequisites and a `/start_bridge.sh` runner, and the MoveIt
  container carries the `ros1_bridge` source; compose starts the bridge
  container with an interactive shell so the build can be completed there
  (`colcon build --packages-select ros1_bridge` with both environments
  sourced). Until then, robot control works directly through the ROS 1
  container.
- **ROS 1 networking through Docker Desktop NAT.** ROS 1 requires
  bidirectional connectivity between nodes and the master. Publishing and
  service calls from the containers to the robot work; callbacks from the
  robot back into a container can be affected by NAT and may require
  additional network configuration depending on your setup.
- **GUI tools need an X server.** RViz 2 and other Qt tools in the MoveIt
  container render through `DISPLAY` (default `host.docker.internal:0.0`),
  which requires an X server such as VcXsrv running on Windows.

## Troubleshooting

- **Docker is not running** — start Docker Desktop before running
  `setup.bat` or any `docker-compose` command, and make sure Linux
  containers are enabled.
- **Build fails** — re-run `docker-compose build`; the ROS 1 Indigo base
  image and Rethink repositories are old, so transient network errors during
  the first build are the most common cause.
- **Robot does not enable** — confirm the robot is powered on and reachable
  (`ping 192.168.42.2` from the host), and that `BAXTER_IP` /
  `ROS_MASTER_URI` match your robot's actual address.
- **Container exits immediately** — check logs with
  `docker-compose logs <service>`; `docker-compose ps` shows the state of
  all three services.

## License

MIT — see [LICENSE](LICENSE).
