# 原型验证记录 · v0.2

日期：2026-10-22。以下只代表实际测试环境，不代表所有 Windows 设备已通过。

## 环境与产物

- Windows 11，内核 NT 10.0.26200.0；Intel UHD Graphics 630，驱动 31.0.101.2135。
- Godot `4.7.2.stable.official.ed1daf0bf` 标准版，GDScript，Compatibility / OpenGL 3.3。
- 用户原型：`build/CloudDragonPrototype-v0.2.exe`，Windows x64 Debug，嵌入 PCK，约 99.1 MiB，未签名；不是安装器。
- `CloudDragonValidation.exe` 是相同生产代码的独立验证入口，不能作为用户产品分享。
- 工具来自官方 godotengine/godot-builds；开发准备脚本固定编辑器 ZIP 和 Windows debug 模板 SHA256，模板提取经过 ZIP CRC 检查。这不等于数字签名验证。
- 仓库已上传至私有 [Penguins321/cloud-dragon-study-pet](https://github.com/Penguins321/cloud-dragon-study-pet)。源码、文档与素材纳入 Git，工具、EXE、进度与原始日志被忽略。

## 自动检查

`test-prototype.ps1`：**100 checks，0 failures，ALL CHECKS PASSED**。

覆盖屏幕内恢复与拖动目标夹取、左右面板布局、透明空隙、单实例保护、两种节点结构的皮肤、动作优先级与回退、旧回调隔离、四档缩放、学习状态、损坏恢复和写入失败、控件信号、源图可见像素采样、动画 / 缩放下取整后的轮廓覆盖、完整动作包围框、动作过渡与循环首尾、隐藏暂停、轮廓更新节流，以及换色复用共享动画库。

修复前，原粗略轮廓漏掉 3,473 个可见像素采样点；修复后，对完整源 PNG 的当前采样没有漏点。部分 Geometry2D 点包含判定出现退化，已改用独立半开区间射线算法作为测试判据，避免错误扩大素材轮廓。

动作复用检查曾观察到共享动画库缺失的失败，提取资源后通过。动作曲线的唯一来源为 `pet/motions/cloud_dragon_float_v1.tres`，规则见 [action-catalog.md](action-catalog.md)。

## 实际渲染与导出

源码 `tests/smoke.gd` 在真实 OpenGL 窗口运行，检查打开计划信号、完成不自动推进、手动下一项、设置、50% 缩放、动作预览、托盘最小化 / 恢复。另检查交给 Window 的最终组合轮廓（含窗口坐标平移、取整及多帧轮廓更新滞后）在四档大小、五种动作下覆盖角色采样点。

Windows Validation 导出程序运行相同烟雾检查；成功标志是日志内出现 `SMOKE TEST PASSED`，仅有引擎启动日志不算通过。Godot 导出模板不采用外部 `--script` 入口，因此验证版使用单独主场景，不把它混入产品入口。

截图经查看，50% 云龙、目标气泡和设置页底部显示完整。**这些截图来自 Godot viewport，在 Windows 原生区域裁剪之前获取**；它们不能独立证明实际桌面裁剪或鼠标穿透正确，需结合几何检查及后续实机鼠标验收。

原始日志在根目录 `docs/superpowers/execution/`（不提交）；界面截图在 `docs/screenshots/`。独立只读审查未发现最终代码 Important 问题；审查指出的 Python 启动器回退、离线准备文档和设置页底部可达性均已处理。

## 动画帧率实测与限制

初版逐帧组合 7,270 个轮廓点，出现约 1.65 FPS。优化为显示尺度遮罩、简化轮廓、线性连接轮廓、半像素阈值更新原生区域，并避免重复设置不变窗口尺寸后，性能显著改善。曲线平滑插值，动作之间混合 0.25 秒，渲染上限 60 FPS；可见时正常处理，隐藏后暂停动画并启用低占用模式。

最终生产配置短时样本：预热 3 秒后统计 360 个 `RenderingServer.frame_post_draw` 间隔，耗时 6.396449 秒，平均 **56.28 FPS**，P95 **20.23 ms**，最长 **152.64 ms**。这是当前机器的一次短样本，仍存在偶发长帧，不能声称已稳定锁定 60 FPS 或完全无卡顿。

对照试验中固定矩形轮廓、停止动态轮廓更新后仍出现约 138 ms 长帧；因此尚不能把剩余停顿完全归因于轮廓计算。后续应在其他电脑、显卡 / 渲染链及真实拖动中继续定位。旧静态版本的启动 CPU / 内存样本不能作为本动画版本的占用结论；本轮未完成长期 CPU / GPU / 内存测量。

复现帧率：在根目录 PowerShell 执行以下命令。所有数据独立，脚本自动退出：

```powershell
$env:APPDATA = Join-Path (Get-Location) '.tools/appdata'
$env:CLOUD_DRAGON_DATA_DIR = Join-Path (Get-Location) '.tools/frame-check'
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path desktop-pet --quit-after 1200 --script res://tests/measure_motion.gd
```

真实渲染烟雾测试将最后的 `--script` 改为 `res://tests/smoke.gd`，同样必须保留隔离数据目录。可选 `CLOUD_DRAGON_SCREENSHOTS` 设置截图目录。普通启动请开新终端或清除这些测试环境变量，以免继续使用测试数据。

## 明确未完成的验收

- 桌面控制工具的应用授权曾超时，未完成真实鼠标点击、拖动、托盘菜单及透明处操作底层桌面的端到端检查；程序化控件信号不等于真实鼠标。
- 拖动代码在每一帧夹取完整动画包围框，几何检查通过；真正鼠标快速越界、不同 DPI、多屏拔插与 Windows 10 仍待实机验证。
- 偶发长帧尚未完全解决，尚无长期资源占用结论。
- 新的舒展、收拢休息和抬头图是待审结构候选，未接入运行时；当前动作为整身变换，不是四肢独立骨架动画。
- 安装 / 卸载、自启动、清单导入导出、用户备份恢复界面和自动更新未实现。

## 数据与构建约束

单实例锁采用仅监听 127.0.0.1 的进程生命周期 TCP 绑定，不发送任务数据；按数据目录选择端口，极少数碰撞会安全拒绝启动。未来产品化可改 Windows 命名互斥量。

旧 EXE 仍运行时 Windows 会阻止覆盖文件，故本轮输出 v0.2 名称。启动新版前先从旧版托盘退出；不强制结束用户进程，也不把个人学习数据提交 Git。换电脑步骤见根目录 HANDOFF.md。
