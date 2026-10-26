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

最新 v0.8：引光已改为聚光成笺，新增半透明水晶渐变与更大动作幅度。所有动作真实轨迹、关键姿态和材质图见 desktop-pet/docs/jade-motion-v0.8.md；215 项回归与动作专项通过，新 EXE 引光全程启动验证退出码 0。


**最新实现（2026-10-26）：温玉灵核 v0.6 已替换默认玉龙。** 不要重新做形象海选。三个刚体部件、持续悬浮相位、动作首尾归零、暖金光缝、柔光与粒子已接入；目标由顶部“引光”展示。首版设计资料在 [温玉灵核细化档案](assets/companions/warm-jade-core/2026-10-26/README.md)，实际实现与验证入口见 [v0.6 手册](desktop-pet/docs/warm-jade-v0.6.md)。设置页支持当前用户登录 Windows 后自动启动；默认关闭，使用 Startup 快捷方式，开发 / 隔离运行不写系统配置，详见 [操作说明](desktop-pet/README.md)。

先读 [需求规格](docs/superpowers/specs/2026-10-22-desktop-study-pet-design.md)、[界面规格](docs/superpowers/specs/2026-10-22-desktop-study-pet-ui-prototype.md)、[项目操作与模块说明](desktop-pet/README.md)，再看 [实际验证范围](desktop-pet/docs/verification.md)。既有实施记录在 [执行记录](docs/superpowers/execution/prototype-progress.md)，保留历史，不把早期“未建 Git”等描述当成当前状态。

历史 v0.5：默认形象为 **C 玉骨天龙**，46 个控制关节、新比例权重、刚性头骨 / 骨角、独立眨眼、五组身体软鬃、双须、五段尾部与分束尾焰。默认朝左，左键六动作循环的最后一项为吐息；右键弹出菜单。今日目标不常驻，只在左上 45° 的青玉灰白云雾中短暂显示，点击雾幕可打开计划。支持 50% 缩放和逐帧拖动边界。历史规则见 [玉骨天龙手册](desktop-pet/docs/jade-dragon-v1.md)，确切测试范围见验证记录。旧云龙和历史动作手册仍保留。

玉骨天龙的[细化设计、透明运行素材与闭眼提示词](assets/cloud-dragon/redesigns/2026-10-22-jade-dragon/README.md)均已归档；当前运行素材仍是整体贴图的受约束网格变形，未完成全身独立拆层。用户要求**全身细致的力传导和动作**，不限尾巴；必须先读[全身动作规格](docs/superpowers/specs/2026-10-22-jade-dragon-whole-body-motion.md)。当前周期风动和局部软鬃不代表已完成整体动力学、惯性求解、转背遮挡交换或所有复杂动作。

下一阶段顺序：

1. 在真实桌面检查 50% / 75% / 100% / 125% 下的尾焰、须、四肢完整性、点击穿透、拖动和托盘恢复；再检查 150% DPI、多屏与 Windows 10。
2. 按全身动作规格继续：现有玉骨侧面重绑定已完成，不必重复替换形象；下一步是补画拆层、独立下颌、主驱动力、关节约束、分区惯性和更完整动作阶段。先实现一次“蓄势—推进—滑翔—收势”，逐部位检查力传递和遮挡，再拓展转身等姿态。仅换色继续复用已有动作与参数。
3. 正式产品化：安装 / 卸载与可选开机自启动、清单导入导出、备份恢复界面、发行包与资源许可核对。这些还没实现，不能向朋友承诺已支持。

## 修改入口与边界

| 要改什么 | 入口 |
| --- | --- |
| 学习目标、任务顺序与完成规则 | `desktop-pet/study/study_plan.gd`；完成不自动推进，日期变化也不推进 |
| 保存与备份 | `desktop-pet/study/plan_store.gd`；先保存候选，再更新 UI 与庆祝 |
| 宠物语义动作 / 优先级 / 轮廓变换 | `desktop-pet/pet/pet_view.gd` |
| 云龙外观、权重、头部、鬃毛 | `desktop-pet/pet/skins/jade_dragon/`；继承旧皮肤的共享驱动，新比例不修改学习模型 |
| 换颜色保留动作 | `desktop-pet/pet/motions/cloud_dragon_flexible_v2.tres` + `jade_interactions_v1.tres`；绑定与材质见 `desktop-pet/docs/jade-dragon-v1.md` |
| 云雾喷流、雾幕、目标文字 | `desktop-pet/pet/effects/goal_breath.gd`、`cloud_mist.gdshader`；只接收显示数据，绝不写学习计划 |
| 透明原生窗口、拖动、托盘、多屏恢复 | `desktop-pet/desktop/pet_window.gd`、`window_geometry.gd` |
| 当前目标、吐息与面板协调 | `desktop-pet/main.gd`；默认皮肤也是在此指定 |
| 普通控件样式与设置 | `desktop-pet/ui/`，Theme 与角色皮肤独立 |
| 参考图、设计图与资源来源 | `assets/cloud-dragon/`；不要覆盖原图 |

关键坑：Windows 的 `mouse_passthrough_polygon` 同时影响显示裁剪，不能用粗略点击多边形替代完整显示区域。当前用 PNG alpha 生成轮廓并沿网格边界细分，使用与 GPU 网格一致的骨骼变换和三角插值；身体与喷流 / 雾幕必须先并集，直接连接重叠多边形会产生 ALTERNATE 填充孔洞。布尔合并后的小数坐标会被原生取整，须保留屏幕坐标 2 像素扩张，并测吐息喷出 / 成雾 / 淡出阶段。固定包围框已包含效果空间，不要再加常驻目标卡。Godot 主窗口用最小化实现托盘隐藏，不能直接 hide。导出模板不执行外部 `--script` 烟雾入口，所以使用独立 `Windows Validation` 预设。

## 验证和交付

`test-prototype.ps1` 当前 215 项，另有温玉灵核动作专项检查，使用隔离测试目录，失败就停下处理；不要删断言来换取通过。旧玉龙真实渲染检查入口 `desktop-pet/tests/smoke.gd` 仍含玉龙专用断言，不应直接作为温玉灵核验收入口；温玉灵核预览用 `tests/preview_warm_jade.gd`，自启动设置预览用 `tests/preview_startup.gd`。`build-prototype.ps1` 输出 `desktop-pet/build/WarmJadePrototype-v0.8.exe` 与 Godot 许可说明。`CloudDragonValidation.exe` 仅供开发验证，不给朋友作为产品。启动新版前先从托盘退出旧版；同一数据目录只允许一个实例，且 Windows 不允许覆盖正在运行的 EXE。测试遇到实例端口碰撞应换新的隔离目录重试，不能强制绕过实例保护。

目前没有安装器或自动更新。开机自启动已通过设置页的当前用户启动目录快捷方式实现。EXE 没签名，分享时附带引擎及第三方许可文件并说明这是原型。项目本身尚未决定对外开源许可证；私有仓库不代表第三方素材可以任意再分发。

## 个人进度与跨电脑迁移

普通数据目录：`%APPDATA%\CloudDragonStudyPrototype\`，包含 `plan.json`、`plan.json.bak`、`preferences.cfg`。**先退出宠物，再复制此目录**；新电脑首次启动前放到相同用户目录。位置在新屏幕上会夹取恢复，缩放保存在 preferences 中。个人学习数据与 Git 源码迁移是两件事，不上传个人进度。

自动测试使用 `.tools/` 下的临时数据；真实渲染测试必须设置 `CLOUD_DRAGON_DATA_DIR` 为隔离目录。不要用用户实际任务清单做完成 / 推进测试。单实例保护使用仅监听 localhost 的 TCP 端口，不传输数据；端口碰撞时会拒绝启动。

## 给新会话 / 新代理的开始指令

> 请先读仓库 HANDOFF.md 与验证记录，确认当前 Git 分支和未提交修改。保留 Godot + GDScript、离线学习计划、手动推进和独立角色表现模块。角色设计必须先拆解结构，四肢连接和头尾连续性检查通过后才制作新姿态。继续下一阶段之前先运行现有检查，不重复生成已有原型。

建议 skills：先 `superpowers:using-superpowers`；缺陷用 `superpowers:systematic-debugging`；新行为用 `superpowers:brainstorming` 和 `test-driven-development`；完成前用 `verification-before-completion`；模块边界可参考 `mattpocock-skills:codebase-design`；正式姿态图用 `imagegen`。这些插件不是项目运行依赖，新电脑没有插件也可正常开发。

## 同步回 GitHub

开始前 `git pull --ff-only`；结束前检查 `git status`、运行回归、查看差异再提交和普通 `git push`。不要 force push，不提交 `.tools/`、`desktop-pet/build/`、用户数据、凭据或日志。临走前确认推送成功，新电脑只能接续已推送的版本。
