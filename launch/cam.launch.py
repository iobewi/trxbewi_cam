# launch/cam.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory
import os


def generate_launch_description():
    # Localisation du paquet et des fichiers intégrés
    pkg_trxbewi_cam = get_package_share_directory("trxbewi_cam")
    params_file = os.path.join(pkg_trxbewi_cam, "config", "config.yaml")

    # camera_info.yaml (converti en URL file:// pour camera_info_manager)
    camera_info_path = os.path.join(pkg_trxbewi_cam, "camera_info", "rpi_csi.yaml")
    camera_info_url = f"file://{camera_info_path}"

    # Node caméra (camera_ros). Tous les autres paramètres sont dans config.yaml
    camera_node = Node(
        package="camera_ros",
        executable="camera_node",
        name="camera_node",
        output="screen",
        parameters=[
            params_file,                 # -> ton trxbewi_cam/config/config.yaml
            {"camera_info_url": camera_info_url},
        ],
        # Remaps minimalistes si besoin (laisse par défaut sinon)
        # remappings=[("image_raw", "image_raw"), ("camera_info", "camera_info")],
    )

    return LaunchDescription([camera_node])
