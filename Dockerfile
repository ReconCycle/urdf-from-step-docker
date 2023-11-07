FROM sha256:ce590ec63b9707a79a71137c3d019d9142717e6518644bf14d5c8f9c5fbb65b0 #ros:noetic-ros-core-focal

# Set some environment variables for the GUI
ENV HOME=/root \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=C.UTF-8

# Install cli tools
RUN set -ex; \
    apt update && apt install -y \
    python3-pip \
    screen \
    vim \
    nano \
    net-tools \
    iputils-ping \
    git \
    wget 


######################
#OCC :
#####################


RUN apt-get install -y wget git build-essential libgl1-mesa-dev libfreetype6-dev libglu1-mesa-dev libzmq3-dev libsqlite3-dev libicu-dev python3-dev libgl2ps-dev libfreeimage-dev libtbb-dev ninja-build bison autotools-dev automake libpcre3 libpcre3-dev tcl8.6 tcl8.6-dev tk8.6 tk8.6-dev libxmu-dev libxi-dev libopenblas-dev libboost-all-dev swig libxml2-dev cmake rapidjson-dev

RUN dpkg-reconfigure --frontend noninteractive tzdata


############################################################
# OCCT 7.5.3                                               #
# Download the official source package from git repository #
############################################################
WORKDIR /opt/build
RUN wget 'https://git.dev.opencascade.org/gitweb/?p=occt.git;a=snapshot;h=fecb042498514186bd37fa621cdcf09eb61899a3;sf=tgz' -O occt-fecb042.tar.gz
RUN tar -zxvf occt-fecb042.tar.gz >> extracted_occt753_files.txt
RUN mkdir occt-fecb042/build
WORKDIR /opt/build/occt-fecb042/build

RUN ls /usr/include
RUN cmake -G Ninja \
 -DINSTALL_DIR=/opt/build/occt753 \
 -DBUILD_RELEASE_DISABLE_EXCEPTIONS=OFF \
 ..

RUN ninja install

RUN echo "/opt/build/occt753/lib" >> /etc/ld.so.conf.d/occt.conf
RUN ldconfig

RUN ls /opt/build/occt753
RUN ls /opt/build/occt753/lib

#############
# pythonocc #
#############


WORKDIR /opt/build
RUN git clone https://github.com/tpaviot/pythonocc-core.git
WORKDIR /opt/build/pythonocc-core
RUN git checkout 7.7.0 #7.6.2  #
RUN python3 --version

#RUN python --version
#RUN swig -version
#RUN apt-get install swig==4.1.1
#RUN pip3 install swig==4.1.1

WORKDIR /opt/build/pythonocc-core/build

RUN cmake \
 -DOCE_INCLUDE_PATH=/opt/build/occt753/include/opencascade \
 -DOCE_LIB_PATH=/opt/build/occt753/lib \
 -DPYTHONOCC_BUILD_TYPE=Release \
 ..

RUN make -j3 && make install 

############
# svgwrite #
############
RUN pip install svgwrite


RUN pip install catkin_tools

RUN set -ex; \
    apt update && apt install -y \
    ros-noetic-urdfdom-py \
    ros-noetic-tf


WORKDIR /input_step_files
WORKDIR /output_ros_urdf_packages

# Source stuff
SHELL ["/bin/bash", "-c"] 


RUN source /opt/ros/$ROS_DISTRO/setup.bash



WORKDIR /ros_ws


# catkin build
RUN source /opt/ros/$ROS_DISTRO/setup.bash && \
    catkin init && \
    catkin clean -y 

WORKDIR /ros_ws/src

RUN git clone https://github.com/ReconCycle/urdf_from_step.git

WORKDIR /ros_ws/src/urdf_from_step
RUN git pull
RUN git rev-parse --short HEAD

WORKDIR /ros_ws


RUN source /opt/ros/$ROS_DISTRO/setup.bash && \
    catkin build


# Always source ros_catkin_entrypoint.sh when launching bash (e.g. when attaching to container)



RUN echo "source /source_ws.sh" >> /root/.bashrc
WORKDIR /
RUN echo "#!/bin/bash" >> /source_ws.sh
RUN echo "set -e" >> /source_ws.sh
RUN echo "source \"/opt/ros/$ROS_DISTRO/setup.bash\" --" >> /source_ws.sh
RUN chmod +x /source_ws.sh
RUN echo "source \"/ros_ws/devel/setup.bash\" --" >> /source_ws.sh
RUN echo "exec \"\$@\"" >> /source_ws.sh
RUN ./source_ws.sh

WORKDIR /ros_ws

ENTRYPOINT ["/source_ws.sh"]
CMD ["bash"]
