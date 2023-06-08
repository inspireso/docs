# 定制镜像

## xz
###	解压 
```sh
xz -dkv -T0 hiveos-0.6-208-stable@210818.img.xz
```

###	压缩img
```sh
xz -zkv -T0 hiveos-0.6-208-stable@210818.img

fdisk -lu hiveos-0.6-217-stable@220423.img

mkdir -p /tmp/hiveos
cd /tmp/hiveos
mkdir ./hive-config
mount -o loop,offset=1048576 hiveos-0.6-217-stable@220509.img /tmp/hiveos/hive-config

mount -o loop,offset=1048576 hiveos-0.6-211-stable@220509.img /tmp/hiveos/hive-config


mkdir ./rootfs
mount -o loop,offset=65011712 hiveos-0.6-217-stable@220423.img /tmp/hiveos/rootfs

mount -o loop,offset=65011712 'hiveos-0.6-217-stable@220509.img' /tmp/hiveos/rootfs


losetup -f -P hiveos-0.6-217-stable@220423.img
lsblk -f
mkfs.fat /dev/loop7p1
fatlabel /dev/loop7p1 HIVE
```

## 修改 ntfs -> fat 分区
```sh
sed -i 's/ntfs-3g/vfat/g' etc/fstab
sed -i 's/remove_hiberfile,nofail/nodiratime,utf8,nofail/g' etc/fstab

LABEL=HIVE /hive-config vfat  errors=remount-ro,fmask=0133,dmask=0022,utf8,noatime,nodiratime,nofail 0 2

run/blkid/blkid.tab
<device DEVNO="0x0811" TIME="1560509137.300704" LABEL="HIVE" UUID="1194-C919" TYPE="vfat" PARTLABEL="HIVE" PARTUUID="03661d4c-e4f0-460f-9521-b8131e40507b">/dev/sdb1</device>
```

## 添加 tmate2+hssh2
````sh
cp -vf /home/ubuntu/Home/Downloads/hiveos/component/tmate2 hive/bin/
chmod +x hive/bin/tmate2
cp -vf /home/ubuntu/Home/Downloads/hiveos/component/hssh2 hive/bin/
chmod +x hive/bin/hssh2
```

## 精简
```sh
rm -rvf etc/syclib etc/rc.local \
 root/.ssh/authorized_keys \
 home/user/.ssh/authorized_keys
rm -rvf etc/systemd/system/multi-user.target.wants/apache2.service
rm -rvf etc/systemd/system/multi-user.target.wants/ssh.service

for lvl in {2,3,4,5}
do
  rm -vf "etc/rc$lvl.d/S01ssh"
  ln -svf "../init.d/ssh" "etc/rc$lvl.d/K01ssh";
done

  ln -sf "../init.d/ssh" "etc/rc$lvl.d/K01ssh";

find etc/rc*.d/ | grep ssh | xargs ls -ld

rm -rvf  K01shellinabox

chattr +i etc/crontab \
  hive/etc/crontab.root \
```

## 启动ufw
```sh
sed -i 's/^ENABLED=no/ENABLED=yes/g' etc/ufw/ufw.conf
```

## "dns ..."
```sh
ln -sf ../run/systemd/resolve/resolv.conf etc/resolv.conf
sed -i 's/^#DNSStubListener=yes/DNSStubListener=no/g' etc/systemd/resolved.conf
```

## 替换源
```sh
rm -vf etc/apt/sources.list.d/openvpn-aptrepo.list
mv -vnf etc/apt/sources.list.d/hiverepo.list etc/apt/sources.list.d/hiverepo.list.bak 

mkdir -p var/debs
cp -vf /home/ubuntu/Home/Downloads/hiveos/img/debs/* var/debs

cd var/debs
dpkg-scanpackages -m . > Packages
apt-ftparchive release . > Release

cat > etc/apt/sources.list.d/hiverepo.list <<EOF
deb [trusted=yes] file:/var/debs ./
deb [trusted=yes] https://mirrors.wochaincapital.com/repo/binary /
EOF

mv -vnf etc/apt/sources.list etc/apt/sources.list.bak
cat > etc/apt/sources.list <<EOF
deb [trusted=yes] http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb-src [trusted=yes] http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse

deb [trusted=yes] http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb-src [trusted=yes] http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse

deb [trusted=yes] http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb-src [trusted=yes] http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse

# deb http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
# deb-src http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse

deb [trusted=yes] http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
deb-src [trusted=yes] http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
EOF

cat > etc/xc-release <<EOF
NAME="XCloud"
BUILD="beta"
BUILD_DATE="2022-05-10"
EOF
```
