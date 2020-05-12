# zsh

## install

```sh
# centos
sudo yum install zsh
# ubuntu
sudo apt-get install zsh
zsh：chsh -s /bin/zsh

wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
#or
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
```

## config

~/.zshrc

```sh
plugins=(ubuntu git command-not-found common-aliases kubectl tmux zsh-wakatime)

alias cls='clear'
alias dig='dig +nocookie'

alias grep="grep --color=auto"
alias -s html=mate   # 在命令行直接输入后缀为 html 的文件名，会在 TextMate 中打开
alias -s rb=mate     # 在命令行直接输入 ruby 文件，会在 TextMate 中打开
alias -s py=vi       # 在命令行直接输入 python 文件，会用 vim 中打开，以下类似
alias -s js=vi
alias -s yaml=vi
alias -s txt=vi
alias -s gz='tar -xzvf'
alias -s tgz='tar -xzvf'
alias -s zip='unzip'
alias -s bz2='tar -xjvf'

export TIME_STYLE='+%Y/%m/%d %H:%M:%S'
```

