# urdf-from-step-docker


## Use prebuilded docker image 


Builded docker image is [hier](https://github.com/ReconCycle/urdf-from-step-docker/pkgs/container/urdf-from-step).

Pull builded docker image

```bash
docker pull ghcr.io/reconcycle/urdf-from-step:latest
```

## Build docker image 

```bash
git clone https://github.com/ReconCycle/urdf-from-step-docker.git
cd urdf-from-step-docker
docker build -t urdf-from-step .
```


## Usage

```bash
docker run urdf-from-step:latest .......
```

```bash
docker run urdf-from-step:latest .......
```

## Example


## For developers

Run with development compose

```bash
docker run urdf-from-step:latest .......

docker run -it -v /home/rok/catkin_ws/src/urdf_from_step:/ros_ws/src/urdf_from_step -v /home/rok/Documents/urdf-from-step-examples/examples/robot_arm/input_step_files:/input_step_files -v /home/rok/Documents/urdf-from-step-examples/examples/robot_arm/output_ros_urdf_packages:/output_ros_urdf_packages urdf-from-step:latest
```

```bash
cd docker-compose/devel/
docker-compose up
```





Push builded docker image:

```bash
docker image push ghcr.io/reconcycle/urdf-from-step:latest
```
