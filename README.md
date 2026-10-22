# 云龙学习搭子

面向 Windows 的桌面学习伙伴，使用 Godot 与 GDScript 开发。云龙展示当前学习目标，用户手动完成任务并推进下一项。

![界面设计](assets/cloud-dragon/ui/ui-overview-v1.png)

## 当前状态

已完成可运行的交互原型：透明宠物窗口、目标气泡、学习清单编辑、手动完成与推进、本地保存、大小设置，以及托盘接线。

皮肤、姿态与动画独立于学习逻辑，普通控件使用独立 Theme。现有云龙已支持悬浮、好奇轻倾、休息、庆祝与拖动反馈，采用整身变换保留身体结构；新的舒展等姿态仍需结构确认后制作。

已修复粗略窗口轮廓裁掉角色的问题，增加 50% 更小档；拖动每帧限制完整窗口在屏幕工作区内。100 项自动检查通过，实际渲染与导出范围见验证记录。真实鼠标穿透、多屏、DPI 与 Windows 10 的实机验收尚未完成。

自启动、安装器、清单分享、用户备份恢复界面与正式骨架动画尚未实现，原型中明确标记对应功能状态。

## 目录

- `desktop-pet/`：Godot 项目、测试和开发说明。
- `assets/cloud-dragon/`：角色候选、用户选定的原始参考、界面原型与来源记录。
- `docs/superpowers/`：需求、界面拆解、实施计划与执行记录。
- `build-prototype.ps1`、`test-prototype.ps1`：本地构建与回归检查入口。

详细操作与架构见 [项目说明](desktop-pet/README.md)，实测范围见 [验证记录](desktop-pet/docs/verification.md)。

## 开发

换电脑从 [HANDOFF.md](HANDOFF.md) 开始。准备 Git 与 Python 3.10+，克隆后运行 `./setup-dev.ps1`，自动准备固定版本引擎与 Windows 调试模板；再运行 `./test-prototype.ps1` 和 `./build-prototype.ps1`。使用 Godot 4.7.2 标准版打开 `desktop-pet/project.godot`。

当前产物为 `desktop-pet/build/CloudDragonPrototype-v0.2.exe`；双击“启动云龙原型.cmd”运行。启动新版前先从旧版托盘退出。新姿态候选与来源在 [poses](assets/cloud-dragon/poses/README.md)，当前动作约束见 [拆解说明](desktop-pet/docs/motion-design.md)，换色复用规则见 [动作手册](desktop-pet/docs/action-catalog.md)。开源项目参考见 [调研笔记](docs/research/desktop-pet-projects.md)。

本地引擎、下载包、导出程序、测试数据、用户数据和原始运行日志不纳入 Git。界面截图及设计素材保留在仓库。正常用户数据位于用户目录，不应提交。

## 资源与许可

角色素材由本项目设计探索产生，仍为待校验候选；生成与修改来源记录在相应素材目录。Godot 引擎及其第三方依赖的许可说明在构建阶段生成，并应随可执行程序一起分发。本项目尚未选择对外开源许可证。
