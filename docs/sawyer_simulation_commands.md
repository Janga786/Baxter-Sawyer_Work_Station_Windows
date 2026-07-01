# Sawyer simulation commands

Reference commands for working with a Sawyer robot using the Intera SDK.
These assume an Intera workspace (`~/sawyer_ws`) with the `intera.sh`
environment script.

## Enable the robot

```sh
rosrun intera_interface enable_robot.py -e
```

## Gazebo simulation

```sh
./intera.sh sim
roslaunch sawyer_gazebo sawyer_world.launch
```

## MoveIt

Terminal 1:

```sh
cd ~/sawyer_ws
./intera.sh
rosrun intera_interface enable_robot.py -e
rosrun intera_interface joint_trajectory_action_server.py
```

Terminal 2:

```sh
roslaunch sawyer_moveit_config sawyer_moveit.launch electric_gripper:=true sim:=false
```
