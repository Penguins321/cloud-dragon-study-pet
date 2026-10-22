# Cloud Dragon Interactive Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. 用户尚未选择执行方式，不自行派发子代理。

**Goal:** 构建 Windows 下可运行的 Godot 桌面原型，验证透明宠物、独立皮肤/动作模块，以及已确认界面的手动学习流程。

**Architecture:** 单进程 Godot 项目。普通数据模型负责学习计划，PetView 隐藏皮肤与动作细节；界面主题、Windows 窗口管理和数据保存各有明确职责。不引入跨引擎抽象、插件框架或外部资源执行。

**Tech Stack:** Godot 4 稳定标准版、GDScript、AnimationPlayer、Resource、Theme、JSON。执行时固定具体引擎版本，优先验证 Compatibility 渲染器。

**Spec:** `docs/superpowers/specs/2026-10-22-desktop-study-pet-design.md`；`docs/superpowers/specs/2026-10-22-desktop-study-pet-ui-prototype.md`。

## Global Constraints

- 面向 Windows 10/11，技术栈为 Godot 与 GDScript。
- 窗口无边框、透明、不置顶，可被普通应用遮挡。
- 日期变化不触发推进。只有用户点击“开始下一项”才推进。
- 不主动弹窗、定时提醒、播放催促台词。
- 所有设计先拆解，再依据结构与运动规律设计姿态和动作。
- 已确认 UI 图是视觉基线；生成图不是结构定稿、透明切图或可直接绑定的动作资源。
- 第一版只提供云龙，不提供外部皮肤导入或换肤管理界面。
- 原始参考图不覆盖。临时素材必须明确标记，不伪装为正式动画资产。

## Review Focus

1. 可选动作缺失、皮肤无效或旧动画回调到达：回退稳定，不影响学习进度；Task 2 验证。
2. 长任务名、空清单、最后一项完成：按钮与当前任务一致，文字不覆盖操作；Task 3/4 验证。
3. 写入失败或损坏文件：不假装保存成功，不静默清空；Task 3 验证。
4. 拔除显示器、DPI 变化、换尺寸：宠物和面板可找回，命中区域与画面一致；Task 1/4 验证。
5. 拖拽释放、隐藏后恢复、退出：不误触展开、不抢焦点、不残留进程；Task 1/4 验证。

## 阶段范围与现状

工作区当前不是 Git 仓库；PATH 未找到 Godot，不代表机器上一定没有安装。执行时先查找本机程序；没有可用版本才取得官方稳定版本，记录版本和路径。没有引擎或交互环境时必须报告未验证项，不能宣布原型通过。

本计划交付可交互桌面原型和 Windows 导出验证，不交付正式安装器、自启动注册、清单导入导出、多屏完整兼容承诺或完整角色动作集。这些属于下一阶段产品化，不能标记为已完成。原型设置页中的未实现功能明确显示“待产品化”，禁止假开关或无反馈按钮。

首版视觉实现先复用已归档的候选外观，不生成新姿态。若需要透明素材，以现有单张母版为目标进行背景处理并复核轮廓，不把整张设定板当作运行时宠物。没有合适素材时采用明确标记的轮廓占位资源，不能阻塞桌面能力验证。

## 文件分工

项目目录：`desktop-pet/`，避免把设计原图作为 Godot 运行资源全量导入。

| 文件 | 职责 |
| --- | --- |
| project.godot、main.tscn、main.gd | 项目与事件连线，不存放皮肤节点逻辑 |
| desktop/pet_window.gd | 窗口坐标、拖拽、透明输入、托盘、屏幕恢复 |
| pet/pet_view.gd | 唯一宠物表现入口、动作控制和皮肤切换 |
| pet/pet_skin.gd | 皮肤 Resource 定义与验证 |
| pet/skins/cloud_dragon/skin.tres、view.tscn | 云龙资源与独立场景，素材放在同目录 |
| study/study_plan.gd | 纯学习数据与状态转换 |
| study/plan_store.gd | JSON 读取、原子式替换与备份恢复 |
| ui/plan_panel.tscn、plan_panel.gd | 已确认计划界面与清单编辑 |
| ui/settings_panel.tscn、settings_panel.gd | 大小、功能状态与入口 |
| ui/study_theme.tres | 普通控件样式，不包含角色结构 |
| tests/run_tests.gd | 无第三方测试框架的状态、资源、保存回归检查 |
| tests/fixtures/ | 两个简单测试外观及损坏数据样本，仅测试使用 |
| docs/verification.md | 实际引擎、设备、手工检查和资源测量结果 |

测试入口使用 extends SceneTree 的脚本；断言失败以非零退出，全部通过输出 ALL CHECKS PASSED。统一命令：PowerShell `& $godotExe --headless --path desktop-pet --script res://tests/run_tests.gd`。`$godotExe` 必须赋值为执行阶段实际验证的绝对路径，不把未知程序名写成已可执行命令。

### Task 1：可找回、可操作的透明桌面窗口

**Files:** project.godot、main.tscn、main.gd、desktop/pet_window.gd、tests/run_tests.gd、docs/verification.md。

**Interfaces:** PetWindow 提供 `set_visual_geometry(bounds: Rect2, hit_polygon: PackedVector2Array) -> void`、`restore_visible_position(saved: Vector2i) -> void`，发出 `pet_clicked()`、`drag_started()`、`drag_finished(position: Vector2i)`、`visibility_changed(is_visible: bool)`。坐标传入窗口前统一转换为屏幕坐标；平台细节不泄露给学习模型。

- [ ] 确认引擎路径、版本、标准版导出模板，记录环境；尚不满足则明确阻碍。
- [ ] 写窗口位置夹取的失败检查：完全离屏坐标恢复到可见工作区；已有可见坐标保持不变；运行测试确认失败。
- [ ] 实现透明无边框、不置顶窗口及位置恢复，以简单占位图验证，重跑检查通过。
- [ ] 实现点击/拖拽区分（启动阈值 8 个逻辑像素）、托盘显示/隐藏/退出；拖动释放后不发送 pet_clicked。
- [ ] 在真实窗口检查透明区能点击底层桌面、角色区能操作、关闭/托盘恢复明确、退出无残留。系统拖动不能满足拖拽结束语义时使用受控坐标拖动，并验证跨屏缩放。
- [ ] 记录可复现检查结果及失败环境。Git 已存在才提交，不自行把未验证内容标为通过。

### Task 2：独立皮肤与动作模块

**Files:** pet/pet_view.gd、pet/pet_skin.gd、pet/skins/cloud_dragon/、tests/fixtures/skin_a.tscn、skin_b.tscn、tests/run_tests.gd。

**Interfaces:** `PetSkin extends Resource` 包含 `id: StringName`、`scene: PackedScene`、`action_map: Dictionary`（语义动作到动画名）、`visual_bounds: Rect2`、`hit_polygon: PackedVector2Array`、`bubble_anchor: Vector2`；坐标均为皮肤根节点局部坐标。场景根为 Node2D，提供内部 AnimationPlayer，路径只由 PetView/皮肤约定，外部不得访问。不同皮肤不要求共享骨架。

PetView 对外仅暴露 `apply_skin(skin: PetSkin) -> Error`、`play_action(action: StringName) -> void`、`set_display_scale(value: float) -> void`、`get_visual_geometry() -> Dictionary`（bounds、hit_polygon、bubble_anchor），发出 `geometry_changed()`。支持任意已声明动作；基础动作 idle 必需，curious/sleepy/celebrate/dragging 可选。界面和行为只调用语义动作。

- [ ] 写失败检查：skin_a 与节点结构不同的 skin_b 均可加载；缺可选动作回 idle；缺 idle 或空场景拒绝且保留旧皮肤；重复回退不递归。先运行确认失败。
- [ ] 实现资源验证、加载和语义映射，避免更换过程中丢掉有效旧皮肤。AnimationPlayer 的轨道路径保留在各自场景中，不在外部拼接云龙身体节点路径。
- [ ] 实现优先级：dragging > celebrate > curious > sleepy > idle；播放同一循环动作不重启。更高优先级中断时清理旧结束回调；换皮肤时失效旧回调。隐藏后暂停不必要的播放，恢复后回 idle。
- [ ] 添加检查：庆祝后返回 idle；拖拽中忽略好奇；切皮肤后旧庆祝结束不覆盖新动作；缩放 0.75/1/1.25 时锚点、包围框和命中轮廓同步变化。
- [ ] 建立云龙皮肤占位资源和 AnimationPlayer 的静态 idle。新形变、骨骼或姿态须先完成用户要求的结构拆解，不在此任务顺便生成。
- [ ] 运行统一测试；外观换成测试皮肤时学习界面仍可工作。两个测试皮肤不进入产品菜单。

### Task 3：手动学习流程与可靠本地保存

**Files:** study/study_plan.gd、study/plan_store.gd、tests/run_tests.gd、tests/fixtures/。

**Interfaces:** `StudyPlan extends RefCounted` 提供 `to_dict() -> Dictionary`、`mark_current_complete() -> Error`、`start_next() -> Error`、`replace_content(goal: String, titles: Array[String]) -> Error`；数据包含 schema_version=1、goal、tasks（id/title/completed）、current_id。`PlanStore.load_plan() -> Dictionary` 返回 error/plan/recovered；`save_plan(plan: Dictionary) -> Error`。拒绝未完成时推进；最后一项 start_next 返回 ERR_DOES_NOT_EXIST，界面显示全部完成。

- [ ] 先写失败检查：完成不推进、重复完成幂等、未完成不能推进、完成后手动推进、最后一项不越界、空清单不崩溃；日期不是状态转换条件。
- [ ] 实现纯状态模型，运行检查通过。示例四项只在首次创建演示计划时提供，不每次启动覆盖。
- [ ] 对存储写失败检查：主文件损坏可恢复备份；主备皆坏返回错误不覆盖；写入受限目录返回错误；未知 schema_version 拒绝加载。
- [ ] 实现 user:// 下临时写入、旧文件备份和替换；失败保留可用旧文件。修改先在候选数据上完成，保存成功后再发布给界面、触发动作。
- [ ] 运行检查通过；测试只使用独立测试目录，不能读写真实用户进度。

### Task 4：已确认界面、皮肤衔接和导出验收

**Files:** main.gd、ui/plan_panel.*、ui/settings_panel.*、ui/study_theme.tres、desktop/pet_window.gd、docs/verification.md、export_presets.cfg。

**Interfaces:** PlanPanel 接收 `render_plan(plan: Dictionary) -> void`，发出 `complete_requested()`、`next_requested()`、`content_replace_requested(goal: String, titles: Array[String])`、`settings_requested()`。SettingsPanel 发出 `display_scale_requested(value: float)`。main 协调保存、刷新与 `PetView.play_action(&"celebrate")`，不操作皮肤内部节点。

- [ ] 建立奶白浅蓝 Theme；实现常驻两行气泡、计划、完成后等待和设置四状态，参照 ui-overview-v1.png；完成后的当前任务不得变化。
- [ ] 增加最小清单编辑：近期目标输入框、每行一个任务的文本区；替换进度前确认。编辑入口是交互细化，不改变主视觉层级。
- [ ] 显示大小使用小/中/大=0.75/1/1.25。计划面板与宠物不重叠，按屏幕可用空间选择方向；主操作始终可见。
- [ ] 接线宠物点击、拖拽及几何变化。拖拽后保持放置点；换测试皮肤不改变任务、进度或放置点。布局读取 PetView 的几何信息，不自行猜测云龙头部位置。
- [ ] 未实现的自启动、分享清单、备份恢复显示明确状态与说明，不模拟成功。原型中启动不写入系统自启动配置。
- [ ] 检查 200 字任务名、空清单、四项全完成、保存失败、关闭面板后恢复、100%/150% 缩放，以及可用多屏条件；有键盘焦点和清楚标签。无设备条件的项目标为未测。
- [ ] 执行 headless 导入/解析及统一测试，再导出 Windows x64 Debug 原型。编辑器通过不能替代导出程序运行。
- [ ] 在导出程序复测透明输入、托盘、状态、重启保存，记录静止/动画/隐藏三状态 CPU、GPU、内存及实际环境；只有被测平台可声称验证通过。
- [ ] 更新 verification.md，列出运行入口、已实现与未实现项，保存界面截图供对比。原型通过后另立产品化计划补齐安装、自启动、导入导出与正式角色动作。

## 自查结论

覆盖本阶段桌面验证、模块化动作、学习流程、可靠保存与四状态界面。五类 Review Focus 分别由上述任务的明确检查覆盖。产品化缺项已列明，不将原型视为最终成品。计划不要求所有动作现在就有素材，也不允许用未经结构校验的生成姿态替代正确母版。

## 执行交接

待用户审阅计划并选择当前会话直接执行，或逐任务委派执行。推荐当前会话直接执行，因为四项共享紧密的界面与窗口几何接口，先消除透明窗口兼容性的不确定性更有价值。
