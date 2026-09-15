# 调查流程

## 问题与初筛

记录用户可见指标、正常值和当前值、采样时间窗、影响边界、输入负载和最近变化。区分症状、测量结果和解释。

Linux 清单依次为 `uptime`、`dmesg -T | tail`、`vmstat 1`、`mpstat -P ALL 1`、`pidstat 1`、`iostat -xz 1`、`free -m`、`sar -n DEV 1`、`sar -n TCP,ETCP 1`、`top`。
实际运行给采样命令设置有限次数，top 用批处理；权限不足和缺工具记为未知。
vmstat/iostat 首份报告可能是启动以来累计值，不能当作故障窗口。
load 包含 runnable 和部分不可中断等待，不等于 CPU 利用率；低 free 不等于内存压力。

## Workload 与 USE

Workload：Who 产生工作；Why 为什么触发/对应代码路径；What 数量、类型和大小；How 随时间变化。输入变化与服务退化必须对齐。

| 资源 | 利用 | 饱和 | 错误 |
|---|---|---|---|
| CPU | 每核 busy / 实际配额 | run queue、调度等待、throttling | 硬件/CPU 错误 |
| 内存 | 物理/cgroup 使用与上限 | reclaim、swap、页等待 | OOM、分配失败 |
| 存储 I/O | busy、吞吐相对能力 | 队列、完成延迟 | timeout、reset、I/O error |
| 容量/inode | 已用比例 | 无通用队列，N/A 或系统指标 | ENOSPC、只读挂载 |
| 网络 | RX/TX 相对链路/限额 | 队列、drop | 接口错误，TCP 重传线索 |
| 软件资源 | 池、锁、FD 使用 | 排队、等锁、限流 | 获取失败、拒绝 |

容器必须看进程所在 cgroup 和祖先限制；只检查当前层不能排除父层 throttling。
虚拟化注意 steal、事件不支持、宿主争用和时钟扰动。不同设备的利用率不直接可比。

## TSA 与深入分支

| 时间主导状态 | 调查方向 |
|---|---|
| Executing | user/system、CPU 栈、syscall/内核路径 |
| Runnable | 调度等待、CPU 压力、绑核、配额 |
| Anonymous Paging | 容量、reclaim、匿名换页 |
| Sleeping | I/O、阻塞栈、唤醒路径 |
| Lock | 持有者、竞争栈、临界区 |
| Idle | 等新工作，不计作请求阻塞 |

`/proc/PID/schedstat` 的差值可观察 executing/runqueue wait；不覆盖六种状态，更不是完整端到端时间拆分。
每进程 CPU 百分比注明是否按单核或全机归一化。

CPU profile 选择支持的事件、目标 PID/cgroup、采样频率和窗口，检查 lost samples、符号和开销。
VM 硬件事件不支持时可用软件 cpu-clock，但不能由此推导物理 cycles。
约 1% 以上未解析路径应列为缺口，不能把地址猜成函数名。
off-CPU 按阻塞时间而非采样次数解释，并排除空闲工作线程；总阻塞时间跨线程可大于墙钟时间。

单请求慢时按应用、依赖、syscall、内核/设备逐层拆分同步延迟，避免把嵌套时间相加或把并行 CPU 时间从 wall time 直接扣除。

## 验证与闭环

先写可证伪预测；一次只改变一个关键变量，保留回退。
用相同输入、时间窗和指标重复 baseline → intervention → recovery；基准稳态时同步观察 limiter。
排队/资源压力和用户结果应按预测同步变化。估算可消除时间的比例，不承诺超过该比例的收益。

最终区分根因证实、缓解、排除和证据不足。未采到的资源、缺失符号、权限限制及背景扰动都必须列出。
实验只清理本轮拥有的 PID 和精确临时文件，并恢复 VM 初始运行状态；不杀同名服务或删除用户数据。
