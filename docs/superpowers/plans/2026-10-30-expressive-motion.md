# Expressive motion implementation plan

Spec: `docs/superpowers/specs/2026-10-30-expressive-motion-design.md`。用户已委托选择并规定20分钟内提交。

- [x] 获取第一手产品热度/交互与动画原则证据，先向用户总结。
- [x] 独立 rig 任务：四个情绪动作与安全节奏细化，先红后绿的动作测试。
- [x] 独立纯模型任务：SocialInteraction.step(delta, relative_point, enabled) -> {attention, action}，停留/轻扫/惊喜/冷却，不读取全局输入。
- [x] 主代理：将四动作注册到23项循环与设置；双击/中键路由；main统一指针/图标朝向和自动反应阻塞规则。
- [x] 完整回归、GPU透明/裁切/投影、实际动作预览，修复失败；审查。
- [x] 更新说明、构建当前EXE、提交全部完成源码/测试/研究/说明到本地Git。

时间安排：约前3分钟调研总结，随后7分钟并行实现，最后10分钟验证/修复/构建与提交。和经用户授权协调的动物伙伴任务统一为 v0.17，作为当前功能的动作增强提交；不因截止时间删除断言或虚称尚未运行的安装/Mac验收。
