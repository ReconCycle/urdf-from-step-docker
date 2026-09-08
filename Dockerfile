FROM ros@sha256:ce590ec63b9707a79a71137c3d019d9142717e6518644bf14d5c8f9c5fbb65b0
# Exact tested snapshot of ros:noetic-ros-core-focal

SHELL ["/bin/bash", "-c"]

ENV HOME=/root \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=C.UTF-8

############################################################
# ROS repository key
############################################################

ADD https://raw.githubusercontent.com/ros/rosdistro/master/ros.key /tmp/ros.key

RUN apt-key add /tmp/ros.key \
    && rm /tmp/ros.key

############################################################
# Dependencies
############################################################

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        -o Dpkg::Options::="--force-confnew" \
        build-essential \
        cmake \
        git \
        iputils-ping \
        libfreetype6-dev \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
        libpcre2-dev \
        libxi-dev \
        libxmu-dev \
        nano \
        net-tools \
        python3 \
        python3-dev \
        python3-pip \
        rapidjson-dev \
        ros-noetic-tf \
        ros-noetic-urdfdom-py \
        screen \
        tk-dev \
        vim \
        wget \
    && rm -rf /var/lib/apt/lists/*

RUN dpkg-reconfigure --frontend noninteractive tzdata

############################################################
# SWIG 4.1.1
############################################################

WORKDIR /tmp

RUN wget -q \
        https://prdownloads.sourceforge.net/swig/swig-4.1.1.tar.gz \
        -O swig-4.1.1.tar.gz \
    && tar -xzf swig-4.1.1.tar.gz \
    && rm swig-4.1.1.tar.gz

WORKDIR /tmp/swig-4.1.1

RUN ./configure \
    && make -j"$(nproc)" \
    && make install

############################################################
# OCCT 7.7.2
############################################################

WORKDIR /tmp

RUN wget -q \
        https://github.com/Open-Cascade-SAS/OCCT/archive/cec1ecd0c9f3b3d2572c47035d11949e8dfa85e2.tar.gz \
        -O occt-7.7.2.tar.gz \
    && mkdir occt-7.7.2 \
    && tar -xzf occt-7.7.2.tar.gz \
        --strip-components=1 \
        -C occt-7.7.2 \
    && rm occt-7.7.2.tar.gz

WORKDIR /tmp/occt-7.7.2

RUN cmake -S . -B build \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DINSTALL_DIR=/opt/build/occt772 \
        -DBUILD_RELEASE_DISABLE_EXCEPTIONS=OFF \
    && cmake --build build --parallel \
    && cmake --install build \
    && echo '/opt/build/occt772/lib' > /etc/ld.so.conf.d/occt.conf \
    && ldconfig

############################################################
# pythonocc-core 7.7.2
############################################################

WORKDIR /opt/build

RUN git clone --branch 7.7.2 --depth 1 \
        https://github.com/tpaviot/pythonocc-core.git \
        pythonocc-core \
    && mkdir -p pythonocc_install

WORKDIR /opt/build/pythonocc-core

RUN cmake -S . -B build \
        -DOCCT_INCLUDE_DIR=/opt/build/occt772/include/opencascade \
        -DOCCT_LIBRARY_DIR=/opt/build/occt772/lib \
        -DPYTHONOCC_BUILD_TYPE=Release \
        -DPYTHONOCC_MESHDS_NUMPY=ON \
        -DPYTHONOCC_INSTALL_DIR=/opt/build/pythonocc_install \
    && cmake --build build --parallel \
    && cmake --install build

ENV PYTHONPATH=/usr/local/lib/python3/dist-packages:$PYTHONPATH

RUN echo 'export PYTHONPATH=/usr/local/lib/python3/dist-packages:$PYTHONPATH' \
    >> /etc/bash.bashrc

############################################################
# Python packages
############################################################

RUN pip3 install --no-cache-dir \
        svgwrite \
        numpy \
        matplotlib \
        catkin_tools

############################################################
# ROS workspace
############################################################

WORKDIR /ros_ws

RUN source /opt/ros/$ROS_DISTRO/setup.bash \
    && catkin init \
    && catkin clean -y

WORKDIR /ros_ws/src

RUN git clone \
        https://github.com/ReconCycle/urdf_from_step.git \
        urdf_from_step

WORKDIR /ros_ws

RUN source /opt/ros/$ROS_DISTRO/setup.bash \
    && catkin build

############################################################
# ROS environment
############################################################

RUN cat > /source_ws.sh <<'EOF'
#!/bin/bash
set -e

source "/opt/ros/${ROS_DISTRO}/setup.bash"
source "/ros_ws/devel/setup.bash"

exec "$@"
EOF

RUN chmod +x /source_ws.sh \
    && echo 'source /source_ws.sh' >> /root/.bashrc

WORKDIR /ros_ws

ENTRYPOINT ["/source_ws.sh"]
CMD ["bash"]