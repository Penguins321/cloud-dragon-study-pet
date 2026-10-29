# macOS 构建与朋友试用

当前已添加 macOS 适配代码；尚未在真实 Mac 上验收，不能把 Windows 测试通过当作 Mac 发布通过。

## 没有开发者证书：直接发朋友 ZIP

当前请发送 `WarmJade-Friends-macOS-0.15.1.zip`，设置页顶部显示“版本 0.15.1 · 3D 晶体与全局字号”。本版恢复原始晶体形象，仅保留晶体 3D，移除火焰。字号覆盖设置、学习计划、任务列表、编辑输入框和确认弹窗。构建脚本从最终 ZIP 提取 PCK，在隔离项目检查所有页面字号、动态任务行、重启恢复，以及实际 GPU 渲染和 3D 开关。升级前退出旧应用，再替换“应用程序”中的 WarmJade.app。Windows 主机验证不替代 Mac 真机验收，真机状态为待验收。

Windows 上已有项目开发环境时运行 `python scripts/build-macos-friends.py`。脚本下载并校验官方 Mac 模板，调用 Godot 内置 ad-hoc 签名直接导出 ZIP，保留执行权限；生成 `desktop-pet/build/macos/WarmJade-Friends-macOS.zip`。把这一个文件发给朋友即可，内含 `WarmJade.app`、中文安装说明及第三方许可。朋友不需要安装开发工具。

该路径已经在 Windows 成功导出，并检查 ZIP 完整性、两种架构、签名数据存在及执行权限；仍需朋友在 Mac 试运行。Godot 直接导出的 ZIP 不受 Windows 文件系统丢失执行位影响，只有先导出/解压 `.app` 再用普通 Windows 工具打包才会出现这个问题。没有 Apple 证书也可使用内置本地签名，无需付费公证。

## 功能范围

沿用桌宠外观、动作、学习计划、成长、拖动、透明背景、置顶、菜单栏入口和设置。首版不支持桌面图标感知，对应开关禁用。

登录启动使用当前用户 `~/Library/LaunchAgents/org.warmjade.studycompanion.plist`，仅在用户开启后写入，下次登录生效；再次打开移动后的应用会更新已有启动项。系统“登录项”中的禁用也会影响启动，本应用不覆盖系统选择。卸载前先在应用设置中关闭自启动；若应用已删除，只移除上述 plist 即可。学习数据保留。

## 在 Mac 构建

1. 安装 Godot **4.7.2 标准版**及完全相同版本的导出模板（编辑器 → 管理导出模板）。安装 Xcode Command Line Tools，供签名使用。
2. 将 Godot 放到 `/Applications/Godot.app`；其他位置通过 `GODOT` 环境变量指定其 `Contents/MacOS/Godot` 可执行文件。
3. 在仓库根目录执行 `bash test-macos.sh`，然后执行 `bash build-macos.sh`。
4. 输出 `desktop-pet/build/macos/WarmJade-macOS.zip`，包含 Apple Silicon / Intel Universal 应用。构建保留独立 stage 目录供检查，不自动安装或启动。

源码从 Windows 拷贝时保持 shell 脚本 LF 换行。通过 `bash` 执行脚本不依赖脚本的可执行位。最终应用在 Mac 导出、设置可执行权限，然后签名，再由 `ditto` 打 ZIP；不要在 Windows 解压并重新打包 `.app`。

## 可以直接给朋友吗？

可以用于朋友试用，不需要上架 App Store。默认使用 ad-hoc 本地签名：保护签名结构完整性，但不提供 Apple 认证的发布者身份，也没有公证。朋友先解压，将 `WarmJade.app` 移入“应用程序”，再打开；若系统阻止且确认文件来自你，可按 Apple 指引在“系统设置 → 隐私与安全”中选择“仍要打开”。受管理的 Mac 可能不允许例外。不要关闭整个 Gatekeeper，也不要要求清除整机的隔离标记。

签名：Developer ID 证书证明发布者身份及包未被修改。公证：Apple 检查提交包，并签发公证票据。可执行权限：Unix 文件权限，缺失会导致程序不能运行，和前两者是不同问题。

## 更顺畅的正式分发

准备 Apple Developer Program 的 Developer ID Application 证书和钥匙串内的 notarytool 凭据。证书、密码和凭据不要提交 Git。

```bash
MACOS_SIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)' \
MACOS_NOTARY_PROFILE='warmjade-notary' \
bash build-macos.sh
```

脚本执行签名、提交公证、装订票据、验证及重新打包；失败即停止。没有公证凭据时不会提交 Apple。产物通过验收后再发给朋友；SHA-256 会打印在构建结果中。

## 发布前真机验收

- 在 Apple Silicon 和 Intel 目标机器运行，检查透明区域可穿透、点击动作、拖动、缩放及 Retina 显示。
- 点击 VS Code、切换 Spaces、全屏应用、Mission Control 后检查置顶。普通窗口置顶不能视为覆盖所有系统界面的保证。
- 菜单栏隐藏/恢复、右键菜单、设置、退出均可用，关闭窗口后没有后台残留。
- 设置开启自启动，注销再登录；关闭后再次登录不启动；移动应用后打开可更新路径。
- 学习进度、外观和成长重启后保留，重复启动不会创建第二实例。
- 用下载传输方式在另一台 Mac 验证 Gatekeeper，而不是只在构建机双击。

参考：[Godot macOS 导出](https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_macos.html)、[Apple 安全打开应用](https://support.apple.com/en-gb/102445)、[Apple LaunchAgent 说明](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)。
