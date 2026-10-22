# 云龙学习搭子

面向 Windows 的桌面学习伙伴，使用 Godot 与 GDScript 开发。玉骨天龙通过云雾吐息展示当前学习目标，用户手动完成任务并推进下一项。

![玉骨天龙云雾吐息（实际运行渲染）](desktop-pet/docs/screenshots/jade-dragon-breath-v1.gif)

## 当前状态

当前 v0.5：透明宠物窗口、玉骨天龙皮肤、云雾吐息、右键菜单、学习清单编辑、手动完成与推进、本地保存、大小设置，以及托盘接线。今日目标平时隐藏，吐息成雾后短暂显示，结束后消散。

皮肤、姿态与动画独立于学习逻辑，普通控件使用独立 Theme。玉骨天龙重新绑定 46 个控制关节，保留头骨和角的刚性，增加独立眨眼、五组身体鬃毛、双须、五段尾部及分束尾焰。新旧皮肤复用语义动作与风动驱动；换色无需复制动作。

左键依次切换游动、抬头、舒展、收拢、欢腾、吐息；右键打开菜单，可直接选择今日目标、学习计划或设置。默认朝左，吐息沿左上 45° 扩散。支持 50% / 75% / 100% / 125%，拖动每帧限制完整窗口在屏幕工作区内。178 项自动检查通过，实际渲染与导出范围见验证记录。真实鼠标穿透、多屏、DPI 与 Windows 10 的实机验收尚未完成。

**C 玉骨天龙**已替换默认运行形象，见[细化图与结构归档](assets/cloud-dragon/redesigns/2026-10-22-jade-dragon/README.md)及[绑定与动作复用规则](desktop-pet/docs/jade-dragon-v1.md)。完整全身受力求解、分层遮挡交换与更复杂收势仍以[全身动作规格](docs/superpowers/specs/2026-10-22-jade-dragon-whole-body-motion.md)追踪；当前参数驱动动作不代表该完整规格已完成。

自启动、安装器、清单分享、用户备份恢复界面与完整多视角分层动作尚未实现，原型中明确标记对应功能状态。

## 目录

- `desktop-pet/`：Godot 项目、测试和开发说明。
- `assets/cloud-dragon/`：角色候选、用户选定的原始参考、界面原型与来源记录。
- `docs/superpowers/`：需求、界面拆解、实施计划与执行记录。
- `build-prototype.ps1`、`test-prototype.ps1`：本地构建与回归检查入口。

详细操作与架构见 [项目说明](desktop-pet/README.md)，实测范围见 [验证记录](desktop-pet/docs/verification.md)。

## 开发

换电脑从 [HANDOFF.md](HANDOFF.md) 开始。准备 Git 与 Python 3.10+，克隆后运行 `./setup-dev.ps1`，自动准备固定版本引擎与 Windows 调试模板；再运行 `./test-prototype.ps1` 和 `./build-prototype.ps1`。使用 Godot 4.7.2 标准版打开 `desktop-pet/project.godot`。

当前产物为 `desktop-pet/build/CloudDragonPrototype-v0.5.exe`；双击“启动云龙原型.cmd”运行。启动新版前先从旧版托盘退出。旧云龙动作基线见 [v3 风动手册](desktop-pet/docs/wind-and-tail-v3.md)，旧姿态候选保留在 [poses](assets/cloud-dragon/poses/README.md)。开源项目参考见 [调研笔记](docs/research/desktop-pet-projects.md)。

本地引擎、下载包、导出程序、测试数据、用户数据和原始运行日志不纳入 Git。界面截图及设计素材保留在仓库。正常用户数据位于用户目录，不应提交。

## 资源与许可

角色素材由本项目设计探索产生，仍为待校验候选；生成与修改来源记录在相应素材目录。Godot 引擎及其第三方依赖的许可说明在构建阶段生成，并应随可执行程序一起分发。本项目尚未选择对外开源许可证。
