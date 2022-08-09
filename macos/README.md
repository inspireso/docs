# macOS

## brew

### install

```sh

#使用ssh方式获取 git 仓库
export HOMEBREW_BREW_GIT_REMOTE="git@github.com:Homebrew/brew.git"  # put your Git mirror of Homebrew/brew here
export HOMEBREW_CORE_GIT_REMOTE="git@github.com:Homebrew/homebrew-core.git"  # put your Git mirror of Homebrew/homebrew-core here
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew tap homebrew/cask --custom-remote git@github.com:Homebrew/homebrew-cask.git
brew tap homebrew/cask-fonts --custom-remote git@github.com:Homebrew/homebrew-cask-fonts.git
brew tap homebrew/cask-drivers --custom-remote git@github.com:Homebrew/homebrew-cask-drivers.git
brew tap homebrew/cask-versions --custom-remote git@github.com:Homebrew/homebrew-cask-versions.git
brew tap homebrew/services --custom-remote git@github.com:Homebrew/homebrew-services.git
brew tap homebrew/bundle --custom-remote git@github.com:Homebrew/homebrew-bundle.git
brew tap homebrew/autoupdate --custom-remote git@github.com:Homebrew/homebrew-autoupdate.git

```

### backup && restore

```sh
# backup
brew bundle dump

# restore
brew bundle

```

### 替换源

```sh
# 查看 brew.git 当前源
cd "$(brew --repo)" && git remote -v
origin    https://github.com/Homebrew/brew.git (fetch)
origin    https://github.com/Homebrew/brew.git (push)

# 查看 homebrew-core.git 当前源
cd "$(brew --repo homebrew/core)" && git remote -v
origin    https://github.com/Homebrew/homebrew-core.git (fetch)
origin    https://github.com/Homebrew/homebrew-core.git (push)

# 修改 brew.git 为阿里源
git -C "$(brew --repo)" remote set-url origin https://mirrors.aliyun.com/homebrew/brew.git

# 修改 homebrew-core.git 为阿里源
git -C "$(brew --repo homebrew/core)" remote set-url origin https://mirrors.aliyun.com/homebrew/homebrew-core.git

# 修改 homebrew-cask.git 为阿里源
git -C "$(brew --repo homebrew/cask)" remote set-url origin https://mirrors.aliyun.com/homebrew/homebrew-cask.git

# 修改 homebrew-cask-fonts.git 为阿里源
git -C "$(brew --repo homebrew/cask-fonts)" remote set-url origin https://mirrors.aliyun.com/homebrew/homebrew-cask-fonts.git

# 修改 homebrew-cask-drivers.git 为阿里源
git -C "$(brew --repo homebrew/cask-drivers)" remote set-url origin https://mirrors.aliyun.com/homebrew/homebrew-cask-drivers.git

# 修改 homebrew-cask-versions.git 为阿里源
git -C "$(brew --repo homebrew/cask-versions)" remote set-url origin https://mirrors.aliyun.com/homebrew/homebrew-cask-versions.git


# zsh 替换 brew bintray 镜像
echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles' >> ~/.zprofile
source ~/.zprofile

# 刷新源
brew update
```


## man 

### install

```sh
brew install automake
brew install opencc

# 进入下载目录
cd ~/Downloads/
# 下载最新版本的源码包
git clone https://github.com/man-pages-zh/manpages-zh.git manpages-zh
# 进入源码包文件夹
cd manpages-zh/
# 编译安装 1
autoreconf --install --force
# 编译安装 2
./configure
# 编译安装 3
sudo make
# 编译安装 4
sudo make install
# 配置别名（如果是 zsh 对应处理即可）
echo "alias cman='man -M /usr/local/share/man/zh_CN'" >> ~/.bash_profile
# 使别名生效
source ~/.bash_profile
# 我们就安装上了中文版本的 man 工具了，但是运行命令会发现乱码。
cman ls
```

### 解决安装 groff 新版本中文乱码的问题

```sh
# 进入下载目录
cd ~/Downloads/
# 下载1.22版本的源码包
wget http://git.savannah.gnu.org/cgit/groff.git/snapshot/groff-1.22.tar.gz
# 解压
tar zxvf groff-1.22.tar.gz
# 进入目录
cd groff-1.22
# 编译安装
./configure
sudo make
sudo make install
# 打开配置文件
sudo vim /etc/man.conf
NROFF preconv -e UTF8 | /usr/local/bin/nroff -Tutf8 -mandoc -c
#修改NROFF配置如下（将UTF8编码的MAN页面通过转码而被groff识别）
#line 94
NROFF preconv -e utf8 | /usr/local/bin/groff -Wall -mtty-char -Tutf8 -mandoc -c  
...
#修改PAGER配置如下（这样可以避免MAN手册页面中的ANSI Escape字符序列干扰（用于控制显示粗体等格式））
#line 105
PAGER /usr/bin/less -isR
...
# 保存退出
# 运行命令，完美解决乱码问题
cman ls
```



## diskutil

```sh
cd Downloads/
hdiutil convert -format UDRW -o ubuntu-20.04.iso  ubuntu-20.04.2.0-desktop-amd64.iso

diskutil list
diskutil unmountDisk /dev/disk2

mv ubuntu.iso.dmg ubuntu.iso
sudo dd if=./ubuntu.iso of=/dev/disk2 bs=1m

```

## NTFS

```
sudo diskutil list
sudo diskutil unmountDisk /dev/disk4
sudo mkdir  /Volumes/mnt
sudo mount_ntfs -o rw,nobrowse /dev/disk2s1 /Volumes/mnt/
....

sudo umount /Volumes/mnt/
```

