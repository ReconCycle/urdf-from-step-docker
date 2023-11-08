FROM ros:noetic-ros-core-focal  
#ros@sha256:ce590ec63b9707a79a71137c3d019d9142717e6518644bf14d5c8f9c5fbb65b0

#

#

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



RUN apt-get install -y wget libglu1-mesa-dev libgl1-mesa-dev libxmu-dev libxi-dev build-essential cmake libfreetype6-dev tk-dev python3-dev rapidjson-dev python3 git python3-pip libpcre2-dev

RUN dpkg-reconfigure --frontend noninteractive tzdata

RUN wget http://prdownloads.sourceforge.net/swig/swig-4.1.1.tar.gz
RUN tar -zxvf swig-4.1.1.tar.gz 
WORKDIR swig-4.1.1
RUN ./configure && make -j4 && make install


############################################################
# OCCT 7.7.2                                               #
# Download the official source package from git repository #
############################################################
WORKDIR /occt
RUN ls
RUN wget 'https://git.dev.opencascade.org/gitweb/?p=occt.git;a=snapshot;h=cec1ecd0c9f3b3d2572c47035d11949e8dfa85e2;sf=tgz' -O occt-7.7.2.tgz #occt-cec1ecd.tar.gz #


RUN ls

RUN tar -xvzf occt-7.7.2.tgz # >> extracted_occt772_files.txt
WORKDIR  /occt/occt-cec1ecd
RUN mkdir cmake-build
WORKDIR /occt/occt-cec1ecd/cmake-build

RUN cmake -DINSTALL_DIR=/opt/build/occt772 -DBUILD_RELEASE_DISABLE_EXCEPTIONS=OFF ..
RUN make -j4
RUN make install
RUN echo "/opt/build/occt772/lib" >> /etc/ld.so.conf.d/occt.conf


#############
# pythonocc #
#############


WORKDIR /opt/build
RUN git clone https://github.com/tpaviot/pythonocc-core.git
WORKDIR /opt/build/pythonocc-core
RUN git checkout 7.7.2 #7.7.0 #7.5.1  #
RUN python3 --version

#RUN apt remove -y swig swig4.0
#RUN python --version
#RUN swig -version
#RUN apt-get install swig==4.1.1
#RUN pip3 install swig==4.0.2 #4.1.1

RUN mkdir cmake-build && cd cmake-build

RUN cmake \
 -DOCCT_INCLUDE_DIR=/opt/build/occt772/include/opencascade \
 -DOCCT_LIBRARY_DIR=/opt/build/occt772/lib \
 -DPYTHONOCC_BUILD_TYPE=Release \
 -DPYTHONOCC_INSTALL_DIR=/where_to_install
 # ..

RUN make -j4 && make install 


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
