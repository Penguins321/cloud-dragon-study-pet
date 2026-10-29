# v0.15.1 接续记录

此前按用户要求暂停并分批提交；本轮恢复后完成了下列构建与本机验收。保留能量核心方向，未改动生产形象、动作或材质。

## 当前方向

能量核心是主体。质感、运动流畅、玄幻、高级是验收标准。移除火焰，保留三个刚性玉晶部件、内部能量材质、折射与 28–72 灵光粒子。新增 orbit、helix、cross_orbit、refract_turn，连同原15动作共19项。详见 energy-core-structure.md。

## 暂停前的验证

- 完整源码回归：284 checks、动作覆盖11513 checks，均0失败；四档字号同步/持久化通过。
- GPU能量、折射、粒子数量、19动作透明/裁切检查通过。
- 原15动作1080个中心采样，2D/3D投影最大误差约0.000046px。
- 新空间动作深度范围约2.9单位；中途切换/拖拽过渡检查通过，最大后续步进约6.5px/60Hz。
- 本机一次360帧采样平均58.7FPS、P95约20.2ms，存在一次约190ms长帧，仍需继续排查；不能据此承诺全机型流畅。

## 本轮接续验证

环境：Windows build 26100.7623、NVIDIA GeForce RTX 3050 Laptop GPU / 驱动 546.30、Godot 4.7.2、OpenGL Compatibility。全部使用项目内隔离数据目录。

- **Mac 验证器修复**：从本次实际导出的 ZIP 复现 `verify.gd:35` 的 `Nil > float`。材质没有显式覆盖 `refraction_index`，着色器默认值为 1.46，实际 GPU 折射正常。验证器现优先读取覆盖值，再读取 RenderingServer 的着色器默认值；缺失或非数值参数仍失败。依据：[Godot 默认参数接口](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html#class-renderingserver-method-shader-get-parameter-default)。未通过强制设置材质值来规避问题。
- **失败能退出**：包验证器增加 30 秒看门狗；独立参数回归与帧诊断分别为 10 / 60 秒。临时副本注入原始空值比较错误后，均以退出码 1 结束；不再因协程中止而无限等待。参数回归覆盖默认值、有效/无效覆盖、清除覆盖、缺失参数、非数值类型、缺失 shader/material，零失败。
- **完整源码回归**：重新运行 `test-prototype.ps1`，284 项基础检查、11,513 项动作检查及字号、外观持久化等专项通过。日志中两条“无法创建目录”来自 Windows/macOS 自启动的预期失败路径测试，均正确拒绝启用；无脚本异常。
- **实际 GPU**：内部能量与折射检查通过，折射前后 RGB 差值约 53.32；19 动作透明背景/裁切检查零失败；原 15 动作共 1,080 个中心采样最大误差约 0.000046px；中途切换/拖拽最大后续步进约 6.50px/60Hz，均通过。
- **Windows 最终包**：重新构建 EXE、安装器、便携 ZIP；中文带空格目录 `/TESTMODE` 安装、隔离启动、卸载通过。安装与便携内容哈希一致，无关文件保留，HKCU 与快捷方式存在状态未改变。另从最终 EXE 的内嵌资源包验证所有页面字号、重启持久化、3D/2D 切换和 OpenGL 渲染，通过。
- **Mac 最终包**：Universal ZIP 完整性、Intel/ARM64 切片、执行权限、签名数据结构通过；从最终 ZIP 提取 PCK，字体同步/持久化、3D 状态、空间动作和本机 GPU 验收均通过。此处仍是 Windows 主机验证。

### 帧时间诊断

新增 `tests/measure_frame_time.gd`，分开记录脚本初始化至首帧、120 帧预热、360 帧悬浮、360 帧动作切换；采样期间不执行 GPU 像素回读。成长模型固定成熟状态，并核对 72 粒子，避免被主循环还原。三轮 3D 和一轮 2D 顺序执行：

| 轮次 | 悬浮 FPS / P95 | 动作 FPS / P95 | 两阶段最长帧 |
| --- | --- | --- | --- |
| 3D 1 | 60.01 / 17.63ms | 60.00 / 17.46ms | 18.96ms |
| 3D 2 | 60.01 / 17.56ms | 60.01 / 17.36ms | 18.26ms |
| 3D 3 | 60.00 / 17.40ms | 60.01 / 17.50ms | 18.43ms |
| 2D 对照 | 60.00 / 19.12ms | 59.99 / 18.92ms | 22.34ms |

3D 脚本初始化至首帧约 390–406ms（不含进程创建），与稳定运行帧时间分开报告。所有采样阶段均无超过 50ms 的帧。**此前约 190ms 的偶发长帧在本机短测中未复现，根因未确认，不能标为已修复或保证所有机型流畅。**

复现（根目录 PowerShell，使用新隔离目录）：

```powershell
$engine = Join-Path $PWD '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
$env:APPDATA = Join-Path $PWD '.tools/appdata'
$env:CLOUD_DRAGON_DATA_DIR = Join-Path $PWD ('.tools/frame-check-' + [guid]::NewGuid().ToString('N'))
& $engine --path desktop-pet --script ../scripts/test-package-shader-parameters.gd
& $engine --path desktop-pet --script res://tests/measure_frame_time.gd
```

第二条末尾加 `-- --2d` 测 2D；先换隔离目录。检查退出码与 `PACKAGE SHADER PARAMETERS: 0 failures` / `FRAME PROFILE` 标志。诊断 JSON 写入隔离目录的 `frame-profile.json`。本轮原始日志在 `.tools/final-regression.log`、`check_*-final.log`、`macos-after.log`、`windows-pack-gl-final.log`、`installer-final.log`、`profile-mature-*.log`，不纳入 Git。

### 分发文件

| 产物 | SHA-256 |
| --- | --- |
| `build/dist/WarmJade-v0.15.1-Setup.exe` | `ec1c63a920066e0b82985f9daa9d7cd91ba54f5774264b0dd198e5ec306db353` |
| `build/dist/WarmJade-v0.15.1-Portable.zip` | `cadd76331fdd34e3b2b7d2305b73b2c49bedc43716ada059a59dc98e6bd7c6cc` |
| `build/macos/WarmJade-Friends-macOS-0.15.1.zip` | `16ad6585d2f46f2fa979f4748e944bc05f5829f630810b658f88e11b90ff2599` |

## 仍需外部验收

- Mac 真机的启动、Gatekeeper、透明穿透、Retina、Spaces/置顶、菜单栏和登录自启动；用户暂时无法提供真机。
- Windows 普通安装模式的真实注册表/快捷方式集成，以及多屏、高 DPI、其他显卡/Windows 版本；本轮安装测试使用不写入真实集成的 TESTMODE。
- 旧机器长帧复现和长期性能采样，不能用当前机器的短测替代。
- 安装包、Godot 引擎、模板、`.tools` 和个人数据不纳入 Git。换机后先运行 `setup-dev.ps1`、`test-prototype.ps1`，再重新构建；未执行远端推送。

预览：screenshots/energy-core-v0.15.1.png、screenshots/energy-core-orbit-v0.15.1.gif。截图用于观察，不代替真机和主观质感验收。
