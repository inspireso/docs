## install

```sh
sudo apt-get update
sudo apt-get upgrade -y

# Checkout the source and install
git clone https://github.com/Chia-Network/chia-blockchain.git -b latest
cd chia-blockchain

sh install.sh

. ./activate

# The GUI requires you have Ubuntu Desktop or a similar windowing system installed.
# You can not install and run the GUI as root

sh install-gui.sh

cd chia-blockchain-gui
npm run electron &

```

## init

```sh
. ./activate
chia keys generate
chia key show
chia init
```



## 启动挖矿

```sh
. ./activate
chia start farmer

```



## P盘

```sh
. ./activate
nohup chia plots create -k 32 -b 4000 -r 2 -n 6 -t /plots -d /data >> plots1.log 2>&1 &

-b就是使用的缓存大小（MB），我的系统是16GB的，所以我运行了两个任务，一个-b 8000，一个-b 4000，留一部分内存给其他进程。

-n 6就是要连续制作6个plot文件

-r就是并发线程，官网说默认2就比较好了，具体没研究。

-t /tmp1，临时盘的目录地址

-d /data1，最终存储plot文件的地址

#查看farm情况
chia farm summary
```

