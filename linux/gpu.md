
# gpu

## amd

### install

```sh
wget "https://drivers.amd.com/drivers/linux/amdgpu-pro-21.20-1271047-ubuntu-20.04.tar.xz"
tar -Jxvf amdgpu-pro-21.20-1271047-ubuntu-20.04.tar.xz

apt install build-essential dkms clinfo
./amdgpu-pro-install -y --opencl=rocr,legacy

sudo usermod -a -G video $LOGNAME
sudo usermod -a -G render $LOGNAME

docker run -it --rm -v /opt:/opt --privileged -device=/dev/kfd --device=/dev/dri --group-add video ubuntu:focal /bin/bash
docker run -it --rm -v /opt:/opt --device=/dev/kfd --device=/dev/dri --group-add video --cap-add=SYS_PTRACE --security-opt seccomp=unconfined  ubuntu:focal /bin/bash
```



## nvidia

 ### install

```sh
sudo ubuntu-drivers devices
选择推荐驱动(recommended driver
sudo ubuntu-drivers autoinstall

apt search nvidia-driver
sudo apt update
sudo apt upgrade
sudo apt install [driver_name]
sudo reboot
```



## 超频

```sh
sudo nvidia-smi -q -d POWER
sudo nvidia-smi -i 0 -pl 115
sudo nvidia-smi -pm 1

//查看当前的 GPU 时钟速度、默认时钟速度和最大可能的时钟速度
sudo nvidia-smi -q -d CLOCK

//显示每个 GPU 的可用时钟速度列表
sudo nvidia-smi -q -d SUPPORTED_CLOCKS 

//查看当前所有GPU的信息，也可以通过参数i指定具体的GPU
sudo nvidia-smi -q

DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 nvidia-settings -q all

DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 nvidia-settings -a [gpu:0]/GPUPowerMizerMode=1
DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 nvidia-settings -a [gpu:0]/GPUGraphicsClockOffset=200
DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 nvidia-settings -a [gpu:0]/GPUMemoryTransferRateOffset=100


nvidia-settings -a '[gpu:0]/GPUGraphicsClockOffset=0'

nvidia-settings -a '[gpu:0]/GPUMemoryTransferRateOffset=800'

nvidia-settings -a '[gpu:0]/GPUFanControlState=0'

nvidia-settings -a '[fan:0]/GPUTargetFanSpeed=75'

nvidia-settings -a '[fan:1]/GPUTargetFanSpeed=75'
```



## k8s

```sh

```



