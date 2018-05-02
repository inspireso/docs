## 堆的分配

```properties
              			                 -Xms/-Xmx
              +-----------------------------------------------------------------------------+
              			                 -XX:NewRatio=tenured/(eden+from+to)
              				m
              +------------------------------+-----------------------------------------------+
                                                                  -Xmn
                                             +-----------------------------------------------+
 -XX:PermSize/MaxPermSize                     -XX:SurivorRatio=eden/from=eden/to
  +-----------+                              +----------------------+-----------+
  +-----------+------------------------------+----------------------+-----------+------------+
  |           |                              |                      |           |            |
  |           |                              |                      |           |            | 
  |   Perm    |            tenured           |        eden          |    from   |     to     |
  |           |                              |                      |           |            |
  |           |                              |                      |           |            |
  +-----------+------------------------------+----------------------+-----------+------------+   
  +---持久区--+----------------------------------堆-------------------------------------------+ 
              +------------老年代 ------------+---------------------- 新生代 -----------------+
              
              
```



## JVM启动参数

```sh
#打印传递给虚拟机的显式和隐式参数，隐式。
-XX:+PrintCommandLineFlags 
#指定GC 输出日志
-Xloggc:gc.log
#打印GC日志
-XX:+PrintGC
#打印详细的GC日志
-XX:+PrintGCDetails
#每次GC发生时，额外输出GC发生的时间
-XX:+PrintGCTimeStmaps
#输出GC的时间戳（以日期的形式，如 2017-09-04T21:53:59.234+0800）
-XX:+PrintGCDateStamps 
#在GC日志输出前后，都有详细的堆信息输出
-XX:+PrintHeapAtGC
#打印应用程序的执行时间
-XX:+PrintGCApplicationConcurrentTime
#打印应用程序由于GC而产生的停顿时间
-XX:+PrintGCApplicationStoppedTime
#跟踪系统内的软应用、弱引用、虚引用和Finallize队列
-XX:+PrintReferenceGC
#跟踪类的加载和卸载
-verbose:class
-XX:+TraceClassLoading
-XX:+TraceClassUnloading

#新生代和老年代的比例
-XX:NewRatio=老年代/新生代=2
```

##  GC相关参数

### 与串行回收器相关的参数

| 参数                          | 说明                                     |
| :--------------------------------- | :-------------------------------------|
| -XX:+UseSerialGC           | 在新生代和老年代使用串行收集器。                              |
| -XX:SurvivorRatio          | 设置**eden**区大小和**survivior**区大小的比例；**eden/from=eden/to** ,默认值8 |
| -XX:PretenureSizeThreshold   | 设置大对象直接进入老年代的阈值。当对象的大小超过这个值时，将直接在老年代分配。 |
| -XX:MaxTenuringThreshold | 设置对象进入老年代的年龄的最大值。第一次**Minor GC**后，对象年龄就加1.任何大于这个年龄的对象，一定会进入老年代，默认15。 |

### 与并行 GC 相关的参数

| 参数                       | 说明                                                         |
| :------------------------- | ------------------------------------------------------------ |
| -XX:+UseParNewGC           | 在新生代使用并行收集器。                                     |
| -XX:+UseParallelOldGC      | 老年代使用并行回收收集器。                                   |
| -XX:ParallelGCThreads      | 设置用于垃圾回收的线程数。通常情况下可以和**CPU**数量相等，当时在**CPU**数量比较多的情况下，设置相对较小 |
| -XX:MaxGCPauseMills        | 设置最大垃圾回收停顿时间。它的值是一个大于0的整数。收集器在工作时，会调整**Java**堆大小或者其他的一些参数，尽可能地把停顿时间控制在`MaxGCPauseMills`以内。 |
| -XX:GCTimeRatio            | 设置吞吐量大小。它的值是一个0到100之间的整数。假设**GCTimeRatio**的值为**n**，那么系统将花费不超过**1/(1+n)**的时间用于垃圾收集。 |
| -XX:+UseAdaptiveSizePolicy | 打开自适应**GC**策略。在这种模式下，新生代的大小、**eden**和**survivior**的比例、晋升老年代的对象年龄等参数会被自动调整，以达到在堆大小、吞吐量和停顿时间之间的平衡点。 |

### 与 CMS 回收器相关的参数

| 参数                                   | 说明                                                         |
| :------------------------------------- | ------------------------------------------------------------ |
| -XX:+UseConcMarkSweepGC                | 新生代使用并行收集器，老年代使用 **CMS**+串行收集器。        |
| -XX:ParallelCMSThreads                 | 设定 **CMS** 的线程数量。                                    |
| -XX:CMSInitiatingOccupancyFraction     | 设置 **CMS** 收集器在老年代空间被使用多少后触发，默认为68%   |
| -XX:+UseCMSCompactAtFullCollection     | 设置 **CMS** 收集器在完成垃圾收集后是否要进行压缩。          |
| -XX:CMSFullGCsBeforeCompaction         | 设定进行多少次 **CMS **垃圾回收后，进行一次内存压缩。        |
| -XX:+CMSClassUnloadingEnabled          | 允许对类元数据区进行回收                                     |
| -XX:CMSInitiatingPermOccupancyFraction | 当永久区占用率达到这一百分比时，启动 **CMS** 回收（前提是`-XX:+CMSClassUnloadingEnabled`激活了） |
| -XX:UseCMSInitiatingOccupancyOnly      | 表示只在到达阈值的时候才进行 **CMS** 回收。                  |
| -XX:CMSIncrementalMode                 | 使用增量模式，比较适合当 **CPU**。增量模式在 **JDK8** 中标记为废弃，并将在 **JDK9** 中彻底移除。 |

### 与 G1 回收器相关的参数

| 参数                      | 说明                     |
| :------------------------ | ------------------------ |
| -XX:+UseG1GC              | 使用G1回收器             |
| -XX:MaxGCPauseMillis      | 设置最大垃圾收集停顿时间 |
| -XX:GCPauseIntervalMillis | 设置停顿间隔时间         |

### TLAB相关的参数

| 参数            | 说明                 |
| :-------------- | -------------------- |
| -XX:+UseTLAB    | 开启TLAB分配         |
| -XX:+PrintTLAB  | 打印TLAB相关分配信息 |
| -XX:TLABSize    | 设置TLAB大小         |
| -XX:+ResizeTLAB | 自动调整TLAB大小     |

### 其他参数

| 参数                             | 说明                        |
| :------------------------------- | --------------------------- |
| -XX:+DisableExplicitGC           | 禁用显示**GC**              |
| -XX:+ExplicitGCInvokesConcurrent | 使用并发方式处理显示 **GC** |

### GC优化需要考虑的JVM参数

| **类型**       | **参数**          | **描述**                  |
| -------------- | ----------------- | ------------------------- |
| 堆内存大小     | `-Xms`            | 启动**JVM**时堆内存的大小 |
|                | `-Xmx`            | 堆内存最大限制            |
| 新生代空间大小 | `-XX:NewRatio`    | 新生代和老年代的内存比    |
|                | `-XX:NewSize`     | 新生代内存大小            |
| 永久代空间大小 | `-XX:PermSize`    | 永久代的初始大小          |
|                | `-XX:MaxPermSize` | 永久代的最大限制          |

### GC类型可选参数


| **GC类型**             | **参数**                                                     | **备注**                        |
| ---------------------- | :----------------------------------------------------------- | :------------------------------ |
| Serial GC              | -XX:+UseSerialGC                                             |                                 |
| Parallel GC            | -XX:+UseParallelGC-XX:ParallelGCThreads=value                |                                 |
| Parallel Compacting GC | -XX:+UseParallelOldGC                                        |                                 |
| CMS GC                 | -XX:+UseConcMarkSweepGC-XX:+UseParNewGC-XX:+CMSParallelRemarkEnabled-XX:CMSInitiatingOccupancyFraction=value-XX:+UseCMSInitiatingOccupancyOnly |                                 |
| G1                     | -XX:+UnlockExperimentalVMOptions-XX:+UseG1GC                 | 在JDK 6中这两个参数必须配合使用 |

## OOM

```sh
-XX:+HeapDumpOnOUtOfMemoryError
-XX:HeapDumpPath=/data/
-XX:OnOutOfMemoryError=/tools/jdk/bin/printstack.sh %p

```

## 方法区配置

```sh
#配置永久区初始大小
-XX:PermSize=128m
#配置永久区最大限制
-XX:MaxPermSize=256m

```

## 栈配置

```sh
#指定线程的栈大小
-Xss
```

## 直接内存

```sh
-XX:MaxDirectMemorySize
```

