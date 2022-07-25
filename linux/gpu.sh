#!/usr/bin/env bash

set -e

nvidia-xconfig -a --cool-bits=28

cat <<"EOF" > /etc/gpus.local
#!/usr/bin/env bash

export DISPLAY=:0
nvidia-smi -pm 1

#1660s
##设置所有的gpu
nvidia-settings -a GPUPowerMizerMode=1
##设置功耗
nvidia-smi -pl 85
##设置核心频率Mhz(pclk)
nvidia-smi -lgc 1050,1050

##设置clock
#nvidia-settings -q GPUGraphicsClockOffset
#nvidia-settings -a GPUGraphicsClockOffset[4]=0

##设置显存Mhz(mclk)
nvidia-settings -q GPUMemoryTransferRateOffset
nvidia-settings -a GPUMemoryTransferRateOffset[4]=-1100

exit 0
EOF

chmod +x /etc/gpus.local

cat <<"EOF" > /lib/systemd/system/gpus.service
[Unit]
Description=GPUS
ConditionFileIsExecutable=/etc/gpus.local

# replaces the getty
Conflicts=getty@tty1.service
After=getty@tty1.service
After=gdm.service gdm3.service
After=network.target

[Service]
Type=forking
ExecStart=/etc/gpus.local start
TimeoutSec=0
RemainAfterExit=yes
GuessMainPID=no
Restart=on-failure
RestartSec=1s

[Install]
WantedBy=multi-user.target
EOF

systemctl enable gpus.service
systemctl daemon-reload && systemctl restart gpus.service 