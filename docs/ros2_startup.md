# ROS 2 startup notes

Once the containers are running (see the main README), the ROS 2 side can be
used for interactive work and custom programming.

## Interactive shell

```sh
docker exec -it moveit_ros2_container bash
cd /shared_ws && source /opt/ros/humble/setup.bash
```

## Custom programming

From this shell you can write ROS 2 code against the standard MoveIt 2 and
trajectory interfaces. Commands are relayed to the physical robot through the
ROS 1 bridge (see "Known limitations" in the main README for the current
state of the bridge build).

Note: `shared_ws/simple_baxter_control.py` is a ROS 1 Baxter SDK script and
must be run inside `baxter_ros1_container`, not here. See the usage section
of the main README.
