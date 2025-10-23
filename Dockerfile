# ---- Base stage ----
ARG ROS_DISTRO=jazzy
ARG PKG=trxbewi_cam  

# 1) BASE RUNTIME — tout ce qui est nécessaire à l'exécution (RMW, utils…)
FROM ros:${ROS_DISTRO}-ros-base AS base

ARG ROS_DISTRO
ENV DEBIAN_FRONTEND=noninteractive

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
      ros-${ROS_DISTRO}-rmw-cyclonedds-cpp \
      python3-opencv \
    && rm -rf /var/lib/apt/lists/* && ldconfig
# Variables runtime communes
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp \
    ROS_DOMAIN_ID=42 \
    ROS_AUTOMATIC_DISCOVERY_RANGE=SUBNET \
    ROS_LOCALHOST_ONLY=0 \
    RMW_CYCLONEDDS_ENABLE_SHM=0

# 2) LIBCAMERA BUILD
FROM base AS libcamera-build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \  
      meson ninja-build pkg-config libyaml-dev python3-yaml \
      python3-ply python3-jinja2 libevent-dev libdrm-dev \
      libcap-dev python3-pip python3-opencv\
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/src \
    && cd /opt/src \
    && git clone https://github.com/raspberrypi/libcamera.git \
    && cd libcamera \
    && meson setup build \
    && ninja -C build install 

# 3) BUILD ROS
FROM base AS ros

ARG ROS_DISTRO
ARG PKG

# Outils build + rosdep + CycloneDDS (car tu l'utilises)
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential cmake git python3-colcon-common-extensions \
      python3-rosdep python3-vcstool \
      ros-${ROS_DISTRO}-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

# Init rosdep (idempotent dans les containers)
RUN rosdep init 2>/dev/null || true && rosdep update
WORKDIR /opt/ws

# cache deps 
COPY package.xml src/${PKG}/package.xml
RUN apt-get update && \
    . /opt/ros/${ROS_DISTRO}/setup.sh && \
    rosdep install --from-paths src --rosdistro ${ROS_DISTRO} -y --ignore-src && \
    rm -rf /var/lib/apt/lists/*

# (3) Copier le reste des sources (code, CMakeLists, launch, etc.)
COPY . src/${PKG}
RUN . /opt/ros/${ROS_DISTRO}/setup.sh && \
    pwd && \
    colcon build

# 4) RUNTIME FINAL
FROM ros AS runtime
ARG PKG

# libcamera runtime (copié depuis l’étape de build libcamera)
COPY --from=libcamera-build /usr/local/ /usr/local/
RUN ldconfig

WORKDIR /opt/ws

COPY docker/ros.env /ros.env
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN ls -l /opt/ws
ENTRYPOINT ["/entrypoint.sh"]
CMD ["ros2","launch","trxbewi_cam","cam.launch.py"]
