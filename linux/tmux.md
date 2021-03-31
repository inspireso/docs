# tmux

## install

```sh
 # ubuntu
 sudo apt-get install tmux
 
 #centos
 yum install -y tmux
```





## tmux的快捷键

**Ctrl+b: 激活控制台；此时以下按键生效**

### 系统操作

| ?      | 列出所有快捷键；按q返回                                      |
| ------ | ------------------------------------------------------------ |
| d      | 脱离当前会话；这样可以暂时返回Shell界面，输入tmux attach能够重新进入之前的会话 |
| D      | 选择要脱离的会话；在同时开启了多个会话时使用                 |
| Ctrl+z | 挂起当前会话                                                 |
| r      | 强制重绘未脱离的会话                                         |
| s      | 选择并切换会话；在同时开启了多个会话时使用                   |
| :      | 进入命令行模式；此时可以输入支持的命令，例如kill-server可以关闭服务器 |
| [      | 进入复制模式；此时的操作与vi/emacs相同，按q/Esc退出          |
| ~      | 列出提示信息缓存；其中包含了之前tmux返回的各种提示信息       |

### 窗口操作

| c      | 创建新窗口                           |
| ------ | ------------------------------------ |
| &      | 关闭当前窗口                         |
| 数字键 | 切换至指定窗口                       |
| p      | 切换至上一窗口                       |
| n      | 切换至下一窗口                       |
| l      | 在前后两个窗口间互相切换             |
| w      | 通过窗口列表切换窗口                 |
| ,      | 重命名当前窗口；这样便于识别         |
| .      | 修改当前窗口编号；相当于窗口重新排序 |
| f      | 在所有窗口中查找指定文本             |

### 面板操作

| ”           | 将当前面板平分为上下两块                                     |
| ----------- | ------------------------------------------------------------ |
| %           | 将当前面板平分为左右两块                                     |
| x           | 关闭当前面板                                                 |
| !           | 将当前面板置于新窗口；即新建一个窗口，其中仅包含当前面板     |
| Ctrl+方向键 | 以1个单元格为单位移动边缘以调整当前面板大小                  |
| Alt+方向键  | 以5个单元格为单位移动边缘以调整当前面板大小                  |
| Space       | 在预置的面板布局中循环切换；依次包括even-horizontal、even-vertical、main-horizontal、main-vertical、tiled |
| q           | 显示面板编号                                                 |
| o           | 在当前窗口中选择下一面板                                     |
| 方向键      | 移动光标以选择面板                                           |
| {           | 向前置换当前面板                                             |
| }           | 向后置换当前面板                                             |
| Alt+o       | 逆时针旋转当前窗口的面板                                     |
| Ctrl+o      | 顺时针旋转当前窗口的面板                                     |

> 进入tmux面板后，一定要先按ctrl+b，然后松开，再按其他的组合键才生效。

### 常用到的几个组合键

```

`1）进入tmux面板后，一定要先按ctrl+b，然后松开，再按其他的组合键才生效。` 
`2）常用到的几个组合键：`
`ctrl+b ?           显示快捷键帮助`
`ctrl+b 空格键       采用下一个内置布局，这个很有意思，在多屏时，用这个就会将多有屏幕竖着展示`
`ctrl+b !           把当前窗口变为新窗口`
`ctrl+b  "          模向分隔窗口`
`ctrl+b %           纵向分隔窗口`
`ctrl+b q           显示分隔窗口的编号`
`ctrl+b o           跳到下一个分隔窗口。多屏之间的切换`
`ctrl+b 上下键       上一个及下一个分隔窗口`
`ctrl+b C-方向键     调整分隔窗口大小`
`ctrl+b &           确认后退出当前tmux`
`ctrl+b [           复制模式，即将当前屏幕移到上一个的位置上，其他所有窗口都向前移动一个。`
`ctrl+b c           创建新窗口`
`ctrl+b n           选择下一个窗口`
`ctrl+b l           最后使用的窗口`
`ctrl+b p           选择前一个窗口`
`ctrl+b w           以菜单方式显示及选择窗口`
`ctrl+b s           以菜单方式显示和选择会话。这个常用到，可以选择进入哪个tmux`
`ctrl+b t           显示时钟。然后按enter键后就会恢复到shell终端状态`
`ctrl+b d           脱离当前会话；这样可以暂时返回Shell界面，输入tmux attach能够重新进入之前的会话`

```

## 常用命令

```sh
# 新建会话，比如新创建一个会话以"ccc"命名
[root@cs ~]# tmux new -s ccc
 
加上参数-d，表示在后台新建会话
[root@cs ~]# tmux new -s shibo -d
[root@cs ~]# tmux ls
shibo: 1 windows (created Tue Oct  2 19:22:32 2018) [135x35]
 
# 查看创建得所有会话
[root@cs ~]# tmux ls
0: 1 windows (created Wed Aug 30 17:58:20 2017) [112x22](attached)    #这里的attached表示该会话是当前会话
aaa: 2 windows (created Wed Aug 30 16:54:33 2017) [112x22]
ccc: 1 windows (created Wed Aug 30 17:01:05 2017) [112x22]
   
# 登录一个已知会话。即从终端环境进入会话。
第一个参数a也可以写成attach。后面的aaa是会话名称。
[root@cs ~]# tmux a -t aaa 
　　
# 退出会话不是关闭：
登到某一个会话后，依次按键ctrl-b + d，这样就会退化该会话，但不会关闭会话。
如果直接ctrl + d，就会在退出会话的通话也关闭了该会话！
   
# 关闭会话（销毁会话）
[root@cs ~]# tmux ls
aaa: 2 windows (created Wed Aug 30 16:54:33 2017) [112x22]
bbb: 1 windows (created Wed Aug 30 19:02:09 2017) [112x22]
   
[root@cs ~]# tmux kill-session -t bbb
   
[root@cs ~]# tmux ls
aaa: 2 windows (created Wed Aug 30 16:54:33 2017) [112x22]
  
# 重命名会话
[root@cs ~]# tmux ls  
wangshibo: 1 windows (created Sun Sep 30 10:17:00 2018) [136x29] (attached)
  
[root@cs ~]# tmux rename -t wangshibo kevin
  
[root@cs ~]# tmux ls
kevin: 1 windows (created Sun Sep 30 10:17:00 2018) [136x29] (attached)
```

