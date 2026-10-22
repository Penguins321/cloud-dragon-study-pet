# 原型验证记录 · v0.4

日期：2026-10-22。旧版记录保留在 [verification-v0.3.md](verification-v0.3.md)。以下只代表实际测试范围。

## 环境与产物

Windows 11（NT 10.0.26200.0），Intel UHD Graphics 630，驱动 31.0.101.2135；Godot 4.7.2 标准版 / GDScript，Compatibility / OpenGL 3.3。原型 `build/CloudDragonPrototype-v0.4.exe` 为 Windows x64 Debug、嵌入 PCK，103,927,992 字节，未签名。`build-prototype.ps1` 已导出成功，并生成 Godot / 第三方许可说明。工具、EXE、日志及个人数据不纳入 Git。

## 本轮新增与测试

`test-prototype.ps1`：**127 checks，0 failures，ALL CHECKS PASSED**。

保留既有学习数据、优先级、点击 / 拖动、四档缩放与覆盖检查；新增双须独立于头骨的运动、须根连接、连续性 / 周期接缝、五段尾部拓扑、尾波顺序延迟，以及焰身 / 火舌的相对变形检查。火舌还必须相对移动中的焰身发生变化，避免整团火焰移动就错误通过。

测试首先观察到旧实现的双须独立摆动失败，随后通过；尾部细分检查也先因控制段不足失败，补齐后通过。曾发现左须影响场在抬头时拉扯颈部，形成局部翻折；扩大渐变区域后，保留双须挂接头部的正确关系并通过校验。

全动作结构采样提高至五动作 × 七时间点 × 十六相位，并检查五次切换各十八帧。覆盖固定骨段长度、每顶点最多四个归一化权重、刚性面部比例、可见三角形方向、稳定包围框及切换连续性。可见三角形由所有 alpha ≥ 0.05 的源像素标记，包含细须 / 脚边 / 焰尖，不只看三角形中心。有限采样不代表任意未来参数均安全。

当前 36 个控制关节，3,300 个网格三角形，原 PNG 像素未改。GPU 和原生窗口轮廓采用相同绑定与三角插值。尾焰 Shader 保持 alpha，只改变局部 RGB；每实例独立材质，保留换色调制。具体结构和复用规则见 [wind-and-tail-v3.md](wind-and-tail-v3.md)。

## 实际渲染与导出验证

源码与 `CloudDragonValidation.exe` 均在实际 OpenGL 窗口输出：

`SMOKE TEST PASSED: left-click actions, bubble plan, rapid drag, study state, scaling, GPU coverage, hide/show`

检查引擎输入事件触发的点击动作、气泡计划、单帧快速拖动、学习完成 / 手动推进、缩放、隐藏恢复；四档尺寸 / 多动作下最终取整组合轮廓覆盖可见点。另在 50% / 125% 下，对游动 / 舒展 / 收拢的实际 GPU framebuffer 逐扫描行检查原生区域覆盖，独立于 CPU 源图映射。

这些图像来自 viewport，在原生窗口区域裁剪之前获取；需结合轮廓检查，不能单凭截图宣称真实鼠标穿透已验收。全身、双须和尾部的 64 帧动图与姿态图已生成并查看；近景是故意裁切构图。独立只读审查未发现 Critical / Important 代码问题，指出的火舌相对焰身测试缺口已补齐。

## 实测帧率

当前生产配置：60 FPS 上限、主窗口关闭额外 GL VSync 等待。预热 3 秒后统计 360 个 frame_post_draw 间隔：6.458444 秒，平均 **55.74 FPS**，P95 **21.75 ms**，最长 **187.77 ms**。仍有偶发长帧，不宣称稳定锁定 60 FPS 或完全无卡顿；GIF 约 30 FPS 只是导出预览。长期 CPU / GPU / 内存未测量。

复现使用根目录 PowerShell：

```powershell
$env:APPDATA = Join-Path (Get-Location) '.tools/appdata'
$env:CLOUD_DRAGON_DATA_DIR = Join-Path (Get-Location) '.tools/frame-check'
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path desktop-pet --quit-after 1200 --script res://tests/measure_motion.gd
```

源码渲染检查将最后的脚本改为 `res://tests/smoke.gd`。导出验证使用 `Windows Validation` 预设，启动后必须看到成功标志。测试须保留隔离目录，不触碰用户学习数据。原始日志位于根目录 `docs/superpowers/execution/`，不提交。

## 当前边界与下一版

用户已选择 C 玉骨天龙，新形象定向图与结构图已归档，**尚未作为运行皮肤接入**。最新要求是全身细致的力传导、分阶段动作和惯性收势，已写入根目录 [全身动作规格](../../docs/superpowers/specs/2026-10-22-jade-dragon-whole-body-motion.md)。当前 v0.4 是旧素材的参数驱动风动基线，不能称为该完整规格已实现。

当前没有全身受力 / 惯性求解、新形象的拆层绑定、火舌生成消散生命周期、独立闭眼表情、转背 / 翻身 / 近远肢遮挡交换或盘绕。真实鼠标穿透、快速越界拖动、不同 DPI、多屏拔插、其他显卡及 Windows 10 实机验收仍未完成。安装器、自启动、清单分享、备份恢复界面与自动更新未实现。

## 数据与同步

源码仓库为私有 [Penguins321/cloud-dragon-study-pet](https://github.com/Penguins321/cloud-dragon-study-pet)。学习数据默认在用户 AppData，Git 不包含个人进度。单实例采用仅监听 localhost 的生命周期 TCP 绑定，端口占用可能导致安全拒绝启动；尚未改用命名互斥量。

新版输出独立 v0.4 名称，避免覆盖正在运行的旧程序。先从旧版托盘退出再启动新版，不强制终止用户宠物。换电脑步骤与最新设计入口见根目录 HANDOFF.md。
