#!/usr/bin/env bash
set -e

# 1) Environnement ROS
if [ -n "${ROS_DISTRO}" ] && [ -f "/opt/ros/${ROS_DISTRO}/setup.bash" ]; then
  . "/opt/ros/${ROS_DISTRO}/setup.bash"
fi

# 2) Workspace colcon (setup global, pas local_setup du package)
if [ -f "/opt/ws/install/setup.bash" ]; then
  . "/opt/ws/install/setup.bash"
else
  echo "WARN: /opt/ws/install/setup.bash not found (build manquant ?)"
fi
exec "$@"
