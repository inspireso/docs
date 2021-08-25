
# gpu

## amd

### install

```sh
#ubuntu20
wget "https://drivers.amd.com/drivers/linux/amdgpu-pro-21.20-1271047-ubuntu-20.04.tar.xz"
tar -Jxvf amdgpu-pro-21.20-1271047-ubuntu-20.04.tar.xz

#ubuntu18
wget "https://drivers.amd.com/drivers/linux/amdgpu-pro-21.30-1286092-ubuntu-18.04.tar.xz"
tar -Jxvf amdgpu-pro-21.30-1286092-ubuntu-18.04.tar.xz

apt install -y build-essential dkms clinfo
./amdgpu-pro-install -y --opencl=rocr,legacy

sudo usermod -a -G video $LOGNAME
sudo usermod -a -G render $LOGNAME

ctr image pull registry.cn-beijing.aliyuncs.com/miners/gpu:latest
  
ctr run --rm -t  \
	--privileged \
  --mount type=bind,src=/opt,dst=/opt,options=rbind:r \
  --mount type=bind,src=/dev/dri,dst=/dev/dri,options=rbind:r \
  --device=/dev/kfd \
  registry.cn-beijing.aliyuncs.com/miners/gpu:latest bash 
  
ctr run --rm -t  \
  --mount type=bind,src=/opt,dst=/opt,options=rbind:rw \
  registry.cn-beijing.aliyuncs.com/miners/miner:hive bash   
  
docker run -it --rm -v /opt:/opt --privileged -device=/dev/kfd --device=/dev/dri --group-add video registry.cn-beijing.aliyuncs.com/miners/gpu:latest /bin/bash
```



### overclock

```sh
# 修改启动参数
vi /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash amdgpu.ppfeaturemask=0xffff7fff"

sudo update-grub2
reboot
 
readlink -f /sys/class/drm/card0/device

pp_od_clk_voltage

watch cat /sys/kernel/debug/dri/0/amdgpu_pm_info

# 控制风扇
cat /sys/class/drm/card0/device/hwmon/hwmon1/pwm1_enable
sudo echo "1" > /sys/class/drm/card0/device/hwmon/hwmon1/pwm1_enable
1: manual
2: default auto

cat /sys/class/drm/card0/device/hwmon/hwmon1/pwm1
sudo echo "100" > /sys/class/drm/card0/device/hwmon/hwmon0/pwm1

#控制 GPU
cat /sys/class/drm/card0/device/power_dpm_force_performance_level
echo "manual" >/sys/class/drm/card0/device/power_dpm_force_performance_level

echo "s 0 300 750" > /sys/class/drm/card0/device/pp_od_clk_voltage
echo "s 1 1120 850" > /sys/class/drm/card0/device/pp_od_clk_voltage
echo 'm 0 300 750' > /sys/class/drm/card0/device/pp_od_clk_voltage
echo 'm 1 1950 850' > /sys/class/drm/card0/device/pp_od_clk_voltage
echo 'm 2 2050 850' > /sys/class/drm/card0/device/pp_od_clk_voltage
# 应用更改
echo 'c' > /sys/class/drm/card0/device/pp_od_clk_voltage

cat /sys/class/drm/card0/device/pp_dpm_sclk | grep "*" | awk '{ print $2 }'


cat /sys/class/drm/card0/device/pp_sclk_od
echo 3 > /sys/class/drm/card0/device/pp_sclk_od

cat /sys/class/drm/card0/device/pp_mclk_od
echo 2 > /sys/class/drm/card0/device/pp_mclk_od
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

nvidia-smi
```

### Overclock

```sh
//监控
nvidia-smi dmon

//查看当前的 GPU 时钟速度、默认时钟速度和最大可能的时钟速度
nvidia-smi -q -d CLOCK

//显示每个 GPU 的可用时钟速度列表
nvidia-smi -q -d SUPPORTED_CLOCKS 

//查看当前所有GPU的信息，也可以通过参数i指定具体的GPU
nvidia-smi -q


sudo nvidia-xconfig -a --cool-bits=28 --allow-empty-initial-configuration

export DISPLAY=:0

nvidia-smi -q -d POWER
nvidia-settings -q all
nvidia-settings --query GPUPerfModes | grep -vE "values|target" | tr '\n' ' ' 

#p106-100
sudo nvidia-smi -pl 75
nvidia-settings -a [gpu:0]/GPUPowerMizerMode=1
nvidia-settings -a [gpu:0]/GPUGraphicsClockOffset[1]=200
nvidia-settings -a [gpu:0]/GPUMemoryTransferRateOffset[1]=1000
sudo nvidia-smi -pm 1

#1660s

##设置性能模式
nvidia-settings -q GPUPowerMizerMode
##设置置顶的gpu
nvidia-settings -a [gpu:0]/GPUPowerMizerMode=1
##设置所有的gpu
nvidia-settings -a GPUPowerMizerMode=1
##设置功耗
nvidia-smi -q -d POWER
nvidia-smi -pl 85
##设置核心频率Mhz(pclk)
nvidia-smi -lgc '1050,1050'
#sudo nvidia-smi -i 0 -lgc 1050,1050
nvidia-smi -lmc "-1100,-1100"

##设置clock
#nvidia-settings -q GPUGraphicsClockOffset
#nvidia-settings -a GPUGraphicsClockOffset[4]=175

##设置显存Mhz(mclk)
nvidia-settings -q GPUMemoryTransferRateOffset
nvidia-settings -a GPUMemoryTransferRateOffset[4]=-1058

##设置风扇
nvidia-settings -q [gpu:0]/GPUFanControlState
nvidia-settings -a [gpu:0]/GPUTargetFanSpeed=1
nvidia-settings -q [fan:0]/GPUTargetFanSpeed
nvidia-settings -a [fan:0]/GPUTargetFanSpeed=80
sudo nvidia-smi -pm 1



```

### Overclock on start

```sh
curl -sSL https://raw.githubusercontent.com/inspireso/docs/master/linux/gpu.sh | bash


```
