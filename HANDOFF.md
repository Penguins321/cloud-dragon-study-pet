# 换电脑继续开发

更新日期：2026-10-22。入口：[私有 GitHub 仓库](https://github.com/Penguins321/cloud-dragon-study-pet)。仓库内容包括源码、参考图、设计、测试与本交接文件；本地引擎、导出程序和个人学习进度不在 Git 中。

## 新电脑第一次启动

准备 Windows 10/11 x64、Git、Python 3.10+（勾选 Windows launcher）。GitHub 使用有此私有仓库权限的账号登录；凭据交给 Git Credential Manager，不复制旧电脑的 token。

在 PowerShell 中执行，目录可自行选择：

```powershell
git clone https://github.com/Penguins321/cloud-dragon-study-pet.git
cd cloud-dragon-study-pet
powershell -ExecutionPolicy Bypass -File .\setup-dev.ps1
powershell -ExecutionPolicy Bypass -File .\test-prototype.ps1
powershell -ExecutionPolicy Bypass -File .\build-prototype.ps1
.\启动云龙原型.cmd
```

`ExecutionPolicy Bypass` 只作用于这次 PowerShell 进程，不修改电脑全局策略。首次准备需要访问官方 GitHub 下载；公司网络限制时按下述手动方式准备。工具下载约 120 MB，另需解压与导入缓存空间。Python 只用于准备开发环境，朋友运行 EXE 不需要 Python 或 Godot。

`setup-dev.ps1` 固定 Godot **4.7.2 标准版 / GDScript**，下载至 `.tools/`，校验编辑器 ZIP 与 Windows debug 模板 SHA256，再导入项目。它只提取 Windows x64 debug 模板，不下载整个多平台模板包。哈希固定于已核对的官方发布文件，不代替数字签名验证。重复执行可重建编辑器并复用已校验下载。

在 Godot 编辑器中打开 `desktop-pet/project.godot`，F6 运行当前场景，F5 运行项目。不要切换 .NET 版或自动升级引擎后直接提交导入变化。

手动 / 离线准备：从官方 `godotengine/godot-builds` 的 `4.7.2-stable` 发布下载 `Godot_v4.7.2-stable_win64.exe.zip`，**保留原 ZIP 并改名放到 `.tools/godot-4.7.2.zip`**；仅复制解压后的 EXE 不够。模板成员 `windows_debug_x86_64.exe` 放到 `.tools/templates/`。将这两份文件复制到新电脑后运行 `setup-dev.ps1`，脚本校验已有文件后解压导入，无需下载。若在线模板服务器不支持 HTTP Range，脚本会明确失败，不偷偷下载 1 GB 以上的完整包。

## 立即接着做什么

先读 [需求规格](docs/superpowers/specs/2026-10-22-desktop-study-pet-design.md)、[界面规格](docs/superpowers/specs/2026-10-22-desktop-study-pet-ui-prototype.md)、[项目操作与模块说明](desktop-pet/README.md)，再看 [实际验证范围](desktop-pet/docs/verification.md)。既有实施记录在 [执行记录](docs/superpowers/execution/prototype-progress.md)，保留历史，不把早期“未建 Git”等描述当成当前状态。

当前 v0.3：左键云龙循环动作，气泡 / 右键打开计划；18 关节 GPU 网格带动身体、尾巴和四肢，显示轮廓使用相同网格变形。保留 50% 缩放和逐帧拖动边界。确切检查结果以验证记录为准。所有动作先按 [v2 结构拆解](desktop-pet/docs/rig-v2-design.md) 设计，不能直接生成一组外观相似但身体结构不同的帧。

下一阶段顺序：

1. 在真实桌面检查 50% / 75% / 100% / 125% 下的尾焰、须、四肢完整性、点击穿透、拖动和托盘恢复；再检查 150% DPI、多屏与 Windows 10。
2. 在已实现的 v2 关节绑定上继续微调动作。若需要闭眼、转背、翻身、近远肢换遮挡或盘绕，先补分层 / 多视角美术并重新校验；不要退回 v1 整图平移，也不要把待审生成候选直接切帧。
3. 正式产品化：安装 / 卸载与可选开机自启动、清单导入导出、备份恢复界面、发行包与资源许可核对。这些还没实现，不能向朋友承诺已支持。

## 修改入口与边界

| 要改什么 | 入口 |
| --- | --- |
| 学习目标、任务顺序与完成规则 | `desktop-pet/study/study_plan.gd`；完成不自动推进，日期变化也不推进 |
| 保存与备份 | `desktop-pet/study/plan_store.gd`；先保存候选，再更新 UI 与庆祝 |
| 宠物语义动作 / 优先级 / 轮廓变换 | `desktop-pet/pet/pet_view.gd` |
| 云龙外观、动画、尺寸范围 | `desktop-pet/pet/skins/cloud_dragon/`；新增皮肤不修改学习模型 |
| 换颜色保留动作 | `desktop-pet/pet/motions/cloud_dragon_flexible_v2.tres` + `pet/skins/cloud_dragon/rig.gd`；规则见 `desktop-pet/docs/action-catalog-v2.md`，v1 保留归档 |
| 透明原生窗口、拖动、托盘、多屏恢复 | `desktop-pet/desktop/pet_window.gd`、`window_geometry.gd` |
| 气泡与面板协调 | `desktop-pet/main.gd` |
| 普通控件样式与设置 | `desktop-pet/ui/`，Theme 与角色皮肤独立 |
| 参考图、设计图与资源来源 | `assets/cloud-dragon/`；不要覆盖原图 |

关键坑：Windows 的 `mouse_passthrough_polygon` 同时影响显示裁剪，不能用粗略点击多边形替代完整显示区域。当前用 PNG alpha 生成轮廓并沿网格边界细分，使用与 GPU 网格一致的骨骼变换和三角插值，预留取整余量；以后改骨架 / 网格或逐帧换图仍须扩展并验证轮廓。Godot 主窗口用最小化实现托盘隐藏，不能直接 hide。导出模板不执行外部 `--script` 烟雾入口，所以使用独立 `Windows Validation` 预设。

## 验证和交付

`test-prototype.ps1` 使用隔离测试目录，失败就停下处理；不要删断言来换取通过。真实渲染检查入口 `desktop-pet/tests/smoke.gd`，运行示例见验证记录。`build-prototype.ps1` 输出 `desktop-pet/build/CloudDragonPrototype-v0.3.exe` 与 Godot 许可说明。`CloudDragonValidation.exe` 仅供开发验证，不给朋友作为产品。启动新版前先从托盘退出旧版；同一数据目录只允许一个实例，且 Windows 不允许覆盖正在运行的 EXE。

目前没有安装器、自启动或自动更新。EXE 没签名，分享时附带引擎及第三方许可文件并说明这是原型。项目本身尚未决定对外开源许可证；私有仓库不代表第三方素材可以任意再分发。

## 个人进度与跨电脑迁移

普通数据目录：`%APPDATA%\CloudDragonStudyPrototype\`，包含 `plan.json`、`plan.json.bak`、`preferences.cfg`。**先退出宠物，再复制此目录**；新电脑首次启动前放到相同用户目录。位置在新屏幕上会夹取恢复，缩放保存在 preferences 中。个人学习数据与 Git 源码迁移是两件事，不上传个人进度。

自动测试使用 `.tools/` 下的临时数据；真实渲染测试必须设置 `CLOUD_DRAGON_DATA_DIR` 为隔离目录。不要用用户实际任务清单做完成 / 推进测试。单实例保护使用仅监听 localhost 的 TCP 端口，不传输数据；端口碰撞时会拒绝启动。

## 给新会话 / 新代理的开始指令

> 请先读仓库 HANDOFF.md 与验证记录，确认当前 Git 分支和未提交修改。保留 Godot + GDScript、离线学习计划、手动推进和独立角色表现模块。角色设计必须先拆解结构，四肢连接和头尾连续性检查通过后才制作新姿态。继续下一阶段之前先运行现有检查，不重复生成已有原型。

建议 skills：先 `superpowers:using-superpowers`；缺陷用 `superpowers:systematic-debugging`；新行为用 `superpowers:brainstorming` 和 `test-driven-development`；完成前用 `verification-before-completion`；模块边界可参考 `mattpocock-skills:codebase-design`；正式姿态图用 `imagegen`。这些插件不是项目运行依赖，新电脑没有插件也可正常开发。

## 同步回 GitHub

开始前 `git pull --ff-only`；结束前检查 `git status`、运行回归、查看差异再提交和普通 `git push`。不要 force push，不提交 `.tools/`、`desktop-pet/build/`、用户数据、凭据或日志。临走前确认推送成功，新电脑只能接续已推送的版本。
