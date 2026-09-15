# CPU 竞争教学实验：脱敏案例与复现

## 已有结果

4 vCPU、aarch64、VZ Linux VM；Ubuntu 25.10、内核 6.17、sysstat、perf 6.17.13、bpftrace 0.23.5、OpenSSL 3.5.3。
哈希程序为 uutils coreutils 0.2.2，不是 GNU 实现。环境和版本仅描述本次实验，非必需版本。

数据由 /dev/zero 流入 sha256sum，不读写磁盘数据集。

| 工作负载 | 基线秒 | 8 竞争进程秒 | 停止竞争后秒 |
|---|---:|---:|---:|
| 1 GiB 单轮 | 5.24 | 12.39 | 5.24 |
| 512 MiB 三轮中位数 | 3.03 | 5.90 | 3.03 |

三轮原始测量值：基线 2.21 / 3.03 / 3.03；竞争 5.84 / 6.58 / 5.90；恢复 3.03 / 3.03 / 2.23。

CPU busy 100%、runnable 8；一个竞争线程 executing 2262.06 ms、runqueue wait 2364.09 ms，二者中等待占 51.1%。
没有观察到换页、块设备活动、网络瓶颈或当前 session 配额 throttling；未完成全部祖先 cgroup、控制器和硬件错误审计。

原哈希 CPU profile 242 样本、0 lost，但热点符号缺失。
独立 OpenSSL BPF 补充采样 496 样本，其中 485 栈含 EVP_Digest → SHA256_Update，内层汇编符号仍不完整。
补充实验不属于原哈希的现场采样，也不是 off-CPU 分析。

结论限定为受控 CPU 竞争导致同一任务变慢，移除竞争后恢复。精确时间、主机/实例、PID、路径、地址及原始日志均未随案例发布。

## 运行条件与安全边界

仅在获授权的隔离 Linux 实例运行。脚本默认不运行，须显式传 --run；固定 8 个 CPU 竞争进程，适合复现本次 4 vCPU 案例，其他 CPU 数量不保证形成饱和。
需 bash、/usr/bin/time、coreutils；主实验另需 sysstat、perf 和已有免交互 sudo；补充实验另需 OpenSSL、perf、bpftrace 和 sudo。不安装工具、不改 sysctl。

每脚本通常约 30–90 秒，实际取决于 CPU 和竞争程度。输出仍可能含 PID、cgroup 路径和栈地址，必须本地保留并另行脱敏；不要直接上传 perf 数据。

以下从本仓库根目录执行，INSTANCE 是你已检查、授权的隔离实例名；路径在运行时解析：

```sh
limactl list
INSTANCE=performance-lab
# 仅当该隔离实例原来停止时启动；不存在则先明确授权和配置再创建。
limactl start "$INSTANCE"
limactl shell "$INSTANCE" -- bash "$PWD/skills/linux-performance-investigation/scripts/lima-cpu-saturation.sh" --run
limactl shell "$INSTANCE" -- bash "$PWD/skills/linux-performance-investigation/scripts/lima-repeat.sh" --run
limactl shell "$INSTANCE" -- bash "$PWD/skills/linux-performance-investigation/scripts/lima-profile.sh" --run
# 仅当本轮启动过它时停止，恢复原运行状态。
limactl stop "$INSTANCE"
```

脚本路径需要 Lima 挂载可读；没有共享挂载时，将整个 scripts 目录以授权方式复制到 guest 后运行。不要将停机命令用于原本运行的其他服务实例。

脚本用 trap 停止自己的负载，并仅删除自有临时 perf 文件。SIGKILL、宿主崩溃不能被 trap 捕获；异常后依据本轮实际 PID/路径核查清理，不使用 pkill、killall 或递归删目录。
