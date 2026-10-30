# 换电脑继续开发

更新日期：2026-10-30。入口：[私有 GitHub 仓库](https://github.com/Penguins321/cloud-dragon-study-pet)。仓库内容包括源码、参考图、设计、测试与本交接文件；本地引擎、导出程序和个人学习进度不在 Git 中。

## 新电脑第一次启动

准备 Windows 10/11 x64、Git、Python 3.10+（勾选 Windows launcher）。GitHub 使用有此私有仓库权限的账号登录；凭据交给 Git Credential Manager，不复制旧电脑的 token。

在 PowerShell 中执行，目录可自行选择：

```powershell
git clone https://github.com/Penguins321/cloud-dragon-study-pet.git
cd cloud-dragon-study-pet
powershell -ExecutionPolicy Bypass -File .\setup-dev.ps1
powershell -ExecutionPolicy Bypass -File .\test-prototype.ps1
powershell -ExecutionPolicy Bypass -File .\build-prototype.ps1
.\启动温玉灵核.cmd
```

`ExecutionPolicy Bypass` 只作用于这次 PowerShell 进程，不修改电脑全局策略。首次准备需要访问官方 GitHub 下载；公司网络限制时按下述手动方式准备。工具下载约 120 MB，另需解压与导入缓存空间。Python 只用于准备开发环境，朋友运行 EXE 不需要 Python 或 Godot。

`setup-dev.ps1` 固定 Godot **4.7.2 标准版 / GDScript**，下载至 `.tools/`，校验编辑器 ZIP 与 Windows debug 模板 SHA256，再导入项目。它只提取 Windows x64 debug 模板，不下载整个多平台模板包。哈希固定于已核对的官方发布文件，不代替数字签名验证。重复执行可重建编辑器并复用已校验下载。

在 Godot 编辑器中打开 `desktop-pet/project.godot`，F6 运行当前场景，F5 运行项目。不要切换 .NET 版或自动升级引擎后直接提交导入变化。

手动 / 离线准备：从官方 `godotengine/godot-builds` 的 `4.7.2-stable` 发布下载 `Godot_v4.7.2-stable_win64.exe.zip`，**保留原 ZIP 并改名放到 `.tools/godot-4.7.2.zip`**；仅复制解压后的 EXE 不够。模板成员 `windows_debug_x86_64.exe` 放到 `.tools/templates/`。将这两份文件复制到新电脑后运行 `setup-dev.ps1`，脚本校验已有文件后解压导入，无需下载。若在线模板服务器不支持 HTTP Range，脚本会明确失败，不偷偷下载 1 GB 以上的完整包。

## 当前项目

当前版本 v0.17，仅支持温玉灵核、柯基、小鸭、水母。云龙与玉龙皮肤、骨架、动作、特效和专属验证资料已移除，不再恢复为运行形象。

柯基使用独立细化脚本（corgi_view.gd）：实例头部权重、局部五官／耳朵动作、温暖毛色与地面接触影；原始 GLB 未修改。

顶部栏统一为浅玉色；玉核 3D 环绕粒子和设置预览共用渲染。当前功能见根目录 README 与 desktop-pet/docs/release-v0.17.md。

开发顺序：`./test-prototype.ps1`、`./build-prototype.ps1`，双击 `启动温玉灵核.cmd`。安装包按需执行 `./build-installer.ps1`；Mac 包按需执行 `python scripts/build-macos-friends.py`。过期导出文件已清除，不再保留多代 EXE 和 ZIP。

学习数据目录 `%APPDATA%\CloudDragonStudyPrototype`、测试环境变量 `CLOUD_DRAGON_*` 和远端仓库地址保留原名以保持兼容；这些技术标识不再关联任何旧形象。不要清理个人学习数据或把测试数据打包给朋友。

待真实设备验收：macOS、Windows 安装集成、多显示器和 DPI。未经用户要求不推送远端。
