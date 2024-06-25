#!/bin/sh
set -e

# 安装开发工具包
xcode-select --install

git clone https://mirrors.aliyun.com/homebrew/install.git brew-install
/bin/bash brew-install/install.sh
rm -rf brew-install
brew -v

export HOMEBREW_INSTALL_FROM_API=1
export HOMEBREW_API_DOMAIN="https://mirrors.aliyun.com/homebrew-bottles/api"
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.aliyun.com/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.aliyun.com/homebrew/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.aliyun.com/homebrew/homebrew-bottles"
brew update

# 绝大部分用户无需额外配置 tap 仓库
# 如果您需要使用 Homebrew 的开发命令，则按照如下命令配置 homebrew/core 和 homebrew/cask 镜像。
brew tap -v --custom-remote --force-auto-update homebrew/core https://mirrors.aliyun.com/homebrew/homebrew-core.git
brew tap -v --custom-remote --force-auto-update homebrew/cask https://mirrors.aliyun.com/homebrew/homebrew-cask.git

# 其他 tap 仓库按需配置即可
brew tap -v --custom-remote --force-auto-update homebrew/cask-fonts https://mirrors.aliyun.com/homebrew/homebrew-cask-fonts.git
brew tap -v --custom-remote --force-auto-update homebrew/cask-versions https://mirrors.aliyun.com/homebrew/homebrew-cask-versions.git
brew tap -v --custom-remote --force-auto-update homebrew/command-not-found https://mirrors.aliyun.com/homebrew/homebrew-command-not-found.git
brew tap -v --custom-remote --force-auto-update homebrew/services https://mirrors.aliyun.com/homebrew/homebrew-services.git

# 写入 sh profile
test -r ~/.bash_profile && echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
test -r ~/.zprofile && echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile