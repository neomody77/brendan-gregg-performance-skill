# Brendan Gregg Linux Performance Investigation Skill

把 Brendan Gregg 的公开性能方法论转化为可执行的 Codex skill：问题陈述 → 初筛 → Workload / USE / TSA → CPU 或等待路径 → 假设验证 → 复测。

这是独立整理，不是作者官方项目，也不包含或提供书籍全文、PDF、第三方笔记镜像。方法来源见 [官方来源](skills/linux-performance-investigation/references/sources.md)。

## 安装与调用

将 `skills/linux-performance-investigation` 整个目录复制到 `~/.codex/skills/`，或项目的 `.agents/skills/`。重新加载后调用：

```text
使用 $linux-performance-investigation 排查这个 Linux 服务延迟升高的问题，先只读诊断。
使用 $linux-performance-investigation 在独立 Lima Linux 实例复现 CPU 竞争并验证恢复。
```

skill 在 [SKILL.md](skills/linux-performance-investigation/SKILL.md)。依赖按模式选择，不自动安装软件、不降低系统安全限制。

## 已实践的教学案例

4 vCPU Linux VM：1 GiB 流式哈希耗时 5.24 → 12.39 → 5.24 秒；三轮 512 MiB 中位数 3.03 → 5.90 → 3.03 秒。记录的是一次受控实验，不是硬件排名，也不保证在其他环境得到相同数字。

见 [脱敏案例与复现](skills/linux-performance-investigation/references/cpu-saturation-lab.md)。

## 发布边界

只发布原创指导、模板、脚本和去标识化的实验摘要。未包含本机路径、主机或实例名、个人邮箱、精确测试时间、原始 PID、内存地址、网络标识、原始日志或采样二进制。

脚本运行产生的输出不是自动脱敏的；排障记录应先本地保留，另行审查后再共享。仓库忽略规则不是安全扫描的替代品。
