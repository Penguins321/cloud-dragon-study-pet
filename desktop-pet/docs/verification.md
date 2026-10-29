# 原型验证记录 · v0.5

这是旧玉龙版本的历史验证记录。当前温玉灵核 v0.15.1 的检查结果、分发哈希和剩余验收事项见 [最新发布验证](release-v0.15.1.md)。

日期：2026-10-22。旧版记录保留在 [verification-v0.4.md](verification-v0.4.md)。以下只代表实际测试范围。

## 环境与产物

Windows 11（NT 10.0.26200.0），Intel UHD Graphics 630，驱动 31.0.101.2135；Godot 4.7.2 标准版 / GDScript，Compatibility / OpenGL 3.3。`build-prototype.ps1` 成功输出 `build/CloudDragonPrototype-v0.5.exe`，Windows x64 Debug、嵌入 PCK，**107,192,152 字节**，未签名；引擎与第三方许可说明同时生成。引擎、EXE、原始日志、测试数据和个人进度不纳入 Git。

## 自动与实际渲染检查

`test-prototype.ps1`：**178 checks，0 failures，ALL CHECKS PASSED**。

保留学习完成 / 手动推进、保存恢复、动作优先级、快速拖动、四档缩放、旧皮肤复用等检查。新增玉骨皮肤比例与透明边缘、刚性眼鼻 / 骨角、独立眨眼及隐藏暂停、46 个关节与五组软鬃连接 / 相对运动、六动作循环、45° 吐息锚点、真实当前目标、最小字号和效果点击范围。

新形象按六动作 × 七时间点 × 十六相位采样，并检查切换帧；包括骨段长度、归一化权重、刚性面部和可见三角形方向。所有源 alpha ≥ 0.05 像素所覆盖三角形均参与可见性标记，涵盖细须 / 脚边 / 焰尖。旧皮肤回归也通过。有限采样不能保证任意未来参数都安全。

源码与 **Windows Validation 导出 EXE** 均在实际 OpenGL 窗口运行，通过：

`SMOKE TEST PASSED: jade default, context menu, breath goal, click actions, rapid drag, study state, scaling, GPU coverage, hide/show`

验证默认玉骨、无常驻目标、右键菜单及菜单吐息、吐息结束后目标消失、点击雾幕进入计划、学习状态、缩放、隐藏恢复。四档尺寸 / 全动作的最终原生区域覆盖源图可见点；另在 50% / 125% 下独立扫描实际 GPU framebuffer，对游动、舒展、收拢及吐息 **0.6 / 1.4 / 5.4 秒**检查原生区域覆盖，包含喷出、成雾和淡出。

两处缺陷先失败后修复：重叠身体 / 喷流轮廓直接拼接会被 Windows ALTERNATE 填充切孔，改成先并集；扩大采样到喷出和淡出后发现布尔合并的小数边经原生取整仍会裁边，增加屏幕坐标 2 像素保守扩张及所有轮廓并集。整数覆盖回归先失败，再通过。测试没有降低可见 alpha 阈值或删除失败阶段。

独立只读代码审查两轮均无 Critical / Important；绝对路径临时诊断已移除。所有验证使用隔离目录，未用用户实际任务做完成 / 推进测试。

## 图像与性能

已生成并查看实际引擎渲染的全身游动、头部近景、睁闭眼、姿态、右键菜单与完整云雾吐息。云雾由显式动画时间驱动的连续雾团与噪声 Shader 生成，颜色为青玉阴影与灰白亮部；不是体积流体模拟。预览见 [jade-dragon-v1.md](jade-dragon-v1.md)。

GIF 为约 30 FPS 的确定性时间线导出，全身 / 头部各 64 帧，吐息 168 帧；不能据此声称实时性能。近景故意裁切构图，不表示桌面窗口裁剪。viewport 截图在原生区域裁剪前获取，需结合覆盖检查理解。

生产配置为 60 FPS 上限、主窗口关闭额外 GL VSync 等待。此前玉骨悬浮样本：预热 3 秒后 360 帧，平均 **56.68 FPS**、P95 **21.71 ms**、最长 **182.74 ms**。新增云雾与保守并集后的吐息样本：360 帧 / **6.647851 秒**，平均 **54.15 FPS**、P95 **24.56 ms**、最长 **190.38 ms**；样本涵盖吐息和结束后的短暂悬浮。仍有偶发长帧，不声称稳定锁定 60 FPS；长期 CPU / GPU / 内存未测量。

复现命令在根目录 PowerShell 执行，数据目录必须隔离：

```powershell
$env:APPDATA = Join-Path (Get-Location) '.tools/appdata'
$env:CLOUD_DRAGON_DATA_DIR = Join-Path (Get-Location) '.tools/isolated-frame-check'
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path desktop-pet --quit-after 1500 --script res://tests/measure_motion.gd -- --breath
```

去掉末尾 `-- --breath` 测悬浮；脚本换为 `res://tests/smoke.gd` 测源码渲染。导出验证用独立 `Windows Validation` 预设，必须检查退出码和成功标志，不能因程序退出就认定通过。原始日志在根目录 `docs/superpowers/execution/`，不提交。

## 尚未完成

本版完成默认玉骨外观、局部头部表情、身体软鬃、吐息云雾和菜单；完整全身动力学、分区惯性求解、所有动作阶段、独立下颌张合、补画拆层、转背 / 翻身、近远肢遮挡交换、盘绕和尾焰生成消散仍未实现，继续按[全身动作规格](../../docs/superpowers/specs/2026-10-22-jade-dragon-whole-body-motion.md)追踪。

真实鼠标穿透 / 菜单点击 / 快速越界拖动、多屏拔插、不同 DPI、其他显卡和 Windows 10 实机验收尚未完成；本轮使用引擎输入事件与真实 GPU / 原生区域检查。安装器、自启动、清单分享、备份恢复界面和自动更新未实现。

## 数据与交接

源码仓库为私有 [Penguins321/cloud-dragon-study-pet](https://github.com/Penguins321/cloud-dragon-study-pet)。个人数据默认位于用户 AppData，Git 不包含个人进度；复制方式与换电脑入口见根目录 [HANDOFF.md](../../HANDOFF.md)。单实例使用 localhost TCP 生命周期绑定，不传输数据，端口碰撞可能拒绝启动；测试换新隔离目录重试，不绕过保护。

输出采用独立 v0.5 名称，避免覆盖运行中的旧 EXE。启动新版前先从旧版托盘退出，不强制结束用户宠物。
