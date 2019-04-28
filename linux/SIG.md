## Linux进程被信号杀死后退出状态码(exit code)

linux系统下，进程对信号的默认响应方式有5种：

1. 忽略信号，即当做没收到信号一样；
2.  终止进程；
3.  产生核心转储文件，同时进程终止；
4. 停止进程，即暂停进程的执行；
5. 于之前的暂停之后恢复执行；

## 信号

| 信号编号 | 信号名称          | 信号描述              | 默认处理方式     | Exit code |
| -------- | ----------------- | --------------------- | ---------------- | --------- |
| 1        | SIGHUP            | 挂起                  | 终止             | 1         |
| 2        | SIGINT            | 终端中断              | 终止             | 2         |
| 3        | SIGQUIT           | 终端退出              | 终止、core dump  | 131       |
| 4        | SIGILL            | 非法指令              | 终止、core dump  | 132       |
| 5        | SIGTRAP           | 跟踪/断点陷阱         | 终止、core dump  | 133       |
| 6        | SIGABRT           | 终止进程              | 终止、core dump  | 134       |
| 7        | SIGBUS            | Bus error             | 终止、core dump  | 135       |
| 8        | SIGFPE            | 算术异常              | 终止、core dump  | 136       |
| 9        | SIGKILL           | 杀死进程（必杀）      | 终止             | 9         |
| 10       | SIGUSR1           | 用户自定义信号1       | 终止             | 10        |
| 11       | SIGSEGV           | 段错误                | 终止、core dump  | 139       |
| 12       | SIGUSR2           | 用户自定义信号2       | 终止             | 12        |
| 13       | SIGPIPE           | 管道断开              | 终止             | 13        |
| 14       | SIGALRM           | 定时器信号            | 终止             | 14        |
| 15       | SIGTERM           | 终止进程              | 终止             | 15        |
| 16       | SIGSTKFLT         | 栈错误                | 终止             | 16        |
| 17       | SIGCHLD           | 子进程退出            | 忽略             | 无        |
| 18       | SIGCONT           | 继续执行              | 若停止则继续执行 | 无        |
| 19       | SIGSTOP           | 停止执行（必停）      | 暂停执行         | 无        |
| 20       | SIGTSTP           | 停止                  | 暂停执行         | 无        |
| 21       | SIGTTIN           | Stopped (tty input)   | 暂停执行         | 无        |
| 22       | SIGTTOU           | Stopped (tty out put) | 暂停执行         | 无        |
| 23       | SIGURG            | io紧急数据            | 忽略             | 无        |
| 24       | SIGXCPU           | 突破对cpu时间的限制   | 终止、core dump  | 152       |
| 25       | SIGXFSZ           | 突破对文件大小的限制  | 终止、core dump  | 153       |
| 26       | SIGVTALRM         | 虚拟定时器超时        | 终止             | 26        |
| 27       | SIGPROF           | 性能分析定时器超时    | 终止             | 27        |
| 28       | SIGWINCH          | 终端窗口尺寸发生变化  | 忽略             | 无        |
| 29       | SIGIO             | io时可能产生          | 终止             | 29        |
| 30       | SIGPWR            | 电量行将耗尽          | 终止             | 30        |
| 31       | SIGSYS            | 错误的系统调用        | 终止、core dump  | 159       |
| 34~64    | SIGRTMIN~SIGRTMAX | 实时信号              | 终止             | 34~64     |

> 说明：
>
> 1. 能使进程被终止执行并产生 core dump 的信号，它的退出状态码是信号编号 + 128，比如 SIGQUIT 信号，它的编号为 3，进程收到该信号后会 core dump，退出状态码为 3+128=131；
>
> 2. 只是使进程被终止，而不会产生 core dump 的信号，它的退出状态码就是信号本身的编号。

