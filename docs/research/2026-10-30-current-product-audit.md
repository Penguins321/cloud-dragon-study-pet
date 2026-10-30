# DesktopAnimal v0.15.1 当前产品审计

日期：2026-10-30。审计基线：`codex/finish-v0.15.1-validation`，提交 `d464678`；以当前源码为准。本文只提出改进建议，不实现功能，不把历史设计文档当作已交付能力。

审计方法：阅读 `main.gd`、`study/*`、`pet_view.gd`、陪伴成长模型、桌面适配、计划/设置界面及相关测试源码；没有读取个人 APPDATA，没有运行会写入数据的测试，也没有验证真实 Windows/macOS 桌面行为。下面的“已有”表示源码中存在实现；测试链接表示已有回归契约，不表示本次执行通过。本文不包含竞品事实，外部研究应另行引用原始来源。

## 结论

当前产品已经形成辨识度很高的“温玉灵核 + 安静离线学习搭子”：三块刚性晶体、有完整动作表现、桌面托盘与位置恢复、手动顺序清单、可见陪伴时间成长。下一阶段最大的用户价值来自**让真实计划可以长期维护、让数据可以带走和恢复、让陪伴强度可控**。继续堆动作或增加联网聊天，并不能先解决这些日用断点。

当前主循环是“打开清单 → 完成当前任务 → 用户主动开始下一项”，没有每日分组、任务编辑保留进度、撤销、专注会话、导入导出或日程调度。已有的安静气质适合作为约束：新能力应能关闭、能暂停，不替用户判定完成，也不因离线或休息惩罚成长。

## 1. 当前已经实现什么

| 领域 | 当前源码能够证明的能力 | 证据 |
| --- | --- | --- |
| 手动计划 | 单一近期目标与顺序任务清单；目标最多 300 字、任务最多 500 项、单项最多 200 字；空清单有效 | [study_plan.gd:3](../../desktop-pet/study/study_plan.gd#L3)、[study_plan.gd:8](../../desktop-pet/study/study_plan.gd#L8) |
| 完成与推进 | “标记完成”保留当前项；只有再点“开始下一项”才推进；未完成不能前进，末项不循环；完成操作幂等 | [study_plan.gd:20](../../desktop-pet/study/study_plan.gd#L20)、[plan_panel.gd:108](../../desktop-pet/ui/plan_panel.gd#L108)、[test_study.gd:11](../../desktop-pet/tests/test_study.gd#L11) |
| 批量输入 | 以每行一个任务编辑整张清单；忽略空行；替换前弹窗确认，并明确告知重置进度 | [plan_panel.gd:77](../../desktop-pet/ui/plan_panel.gd#L77)、[plan_panel.gd:146](../../desktop-pet/ui/plan_panel.gd#L146) |
| 计划容错 | `plan.json.tmp` 写入、flush，再保存有效主文件为 `.bak`、重命名临时文件；加载先主文件后备份；两者损坏则阻止覆盖；保存成功后才切换内存计划 | [plan_store.gd:8](../../desktop-pet/study/plan_store.gd#L8)、[plan_store.gd:16](../../desktop-pet/study/plan_store.gd#L16)、[main.gd:161](../../desktop-pet/main.gd#L161)、[main.gd:194](../../desktop-pet/main.gd#L194) |
| 桌面控制 | 透明置顶窗口、按住拖动、透明间隙穿透、右键/托盘菜单、隐藏与恢复、真正退出；跨屏工作区约束与面板择边布局 | [pet_window.gd:27](../../desktop-pet/desktop/pet_window.gd#L27)、[pet_window.gd:126](../../desktop-pet/desktop/pet_window.gd#L126)、[window_geometry.gd:3](../../desktop-pet/desktop/window_geometry.gd#L3)、[run_tests.gd:17](../../desktop-pet/tests/run_tests.gd#L17) |
| 外观与可读性 | 材质与颜色实时预览、四档显示大小、四档全局字号；2D/3D 选择，玉晶/水晶/欧泊用 3D，渲染失败可回退 2D；部分控件有无障碍名称 | [settings_panel.gd:53](../../desktop-pet/ui/settings_panel.gd#L53)、[settings_panel.gd:85](../../desktop-pet/ui/settings_panel.gd#L85)、[settings_panel.gd:125](../../desktop-pet/ui/settings_panel.gd#L125)、[rig.gd:13](../../desktop-pet/pet/skins/warm_jade/rig.gd#L13)、[main.gd:80](../../desktop-pet/main.gd#L80) |
| 动作执行 | 19 个点击轮换/设置预览动作，另有 idle/dragging 等状态；动作优先级、拖动保护、动作结束回 idle、旧皮肤完成信号失效保护 | [pet_view.gd:16](../../desktop-pet/pet/pet_view.gd#L16)、[pet_view.gd:91](../../desktop-pet/pet/pet_view.gd#L91)、[pet_view.gd:114](../../desktop-pet/pet/pet_view.gd#L114)、[test_pet.gd:62](../../desktop-pet/tests/test_pet.gd#L62) |
| 少量情境响应 | 完成任务庆祝、打开计划好奇、拖动响应；Windows 图标几何感知下的目光转向与短距离避让；面板打开、拖动、右键菜单、感知过期等情况下抑制图标交互 | [main.gd:177](../../desktop-pet/main.gd#L177)、[main.gd:270](../../desktop-pet/main.gd#L270)、[main.gd:300](../../desktop-pet/main.gd#L300) |
| 陪伴成长 | 可见且活跃的连续运行时间累加，40 小时成熟；不计隐藏、离线与挂起间隙；只增加，不衰退；设置中保存终身累计时间 | [companionship.gd:3](../../desktop-pet/pet/companionship.gd#L3)、[main.gd:140](../../desktop-pet/main.gd#L140)、[test_companionship.gd:14](../../desktop-pet/tests/test_companionship.gd#L14) |
| 已有节能措施 | 主循环上限 60 FPS；隐藏时停宠物动画、停图标读取子进程并开启低处理器模式；设置预览可见时约 30Hz、隐藏时停更新；3D 视口隐藏/最小化时停更新 | [main.gd:48](../../desktop-pet/main.gd#L48)、[main.gd:94](../../desktop-pet/main.gd#L94)、[appearance_preview.gd:40](../../desktop-pet/ui/appearance_preview.gd#L40)、[crystal_view_3d.gd:64](../../desktop-pet/pet/crystal_view_3d.gd#L64) |
| 系统接入 | Windows 启动快捷方式、macOS LaunchAgent 适配；默认不开启自启动；隔离测试不改真实启动项/不读真实桌面；同数据目录单实例互斥 | [startup.gd:9](../../desktop-pet/desktop/startup.gd#L9)、[startup_macos.gd:10](../../desktop-pet/desktop/startup_macos.gd#L10)、[single_instance.gd:5](../../desktop-pet/desktop/single_instance.gd#L5)、[icon_awareness.gd:41](../../desktop-pet/desktop/icon_awareness.gd#L41) |

“今日目标（引光）”菜单的实际数据来自**当前任务标题**，不是日期筛选的今日任务：[main.gd:206](../../desktop-pet/main.gd#L206)、[main.gd:154](../../desktop-pet/main.gd#L154)。产品文案与数据模型的这一差异应在路线图中处理，不能据菜单名称宣称已有每日计划。

## 2. 缺失与尚不确定的边界

### 源码可确认尚未提供的能力

- **保留进度的任务维护**：模型只有整单替换、完成当前、开始下一项；任务 ID 是重建时的 `task_索引`。没有单项增删改、稳定 ID、重排、撤销完成、归档、多清单。顺序校验还要求当前项之前全部完成、之后全部未完成，不能直接叠加任意勾选。[study_plan.gd:8](../../desktop-pet/study/study_plan.gd#L8)、[study_plan.gd:56](../../desktop-pet/study/study_plan.gd#L56)
- **每日工作流**：无日期、重复规则、任务预计时间、会话、暂停/续接、今日回顾或完成历史。`active_seconds` 只表示可见运行陪伴时间，不能叫“专注时间”或“学习时长”。[study_plan.gd:3](../../desktop-pet/study/study_plan.gd#L3)、[companionship.gd:11](../../desktop-pet/pet/companionship.gd#L11)
- **数据可携带与可操作恢复**：当前 UI 没有文件导入、文件导出、手动快照、恢复预览、数据目录入口、跨设备迁移。`.bak` 只是一份前次有效计划，不是历史库；后续成功保存可继续覆盖它。偏好/成长另存于 `preferences.cfg`，没有对应备份轮换。[plan_store.gd:29](../../desktop-pet/study/plan_store.gd#L29)、[main.gd:391](../../desktop-pet/main.gd#L391)、[settings_panel.gd:42](../../desktop-pet/ui/settings_panel.gd#L42)
- **可控的陪伴强度**：没有“减少动态”“安静一小时”“工作中暂停”“固定在此”“置顶开关”或显式功耗档位；窗口每 0.5 秒重新确认置顶。已有隐藏、2D 切换与关闭图标感知可缓解，不能据此声称有完整打扰/资源策略。[pet_window.gd:75](../../desktop-pet/desktop/pet_window.gd#L75)、[main.gd:48](../../desktop-pet/main.gd#L48)、[settings_panel.gd:85](../../desktop-pet/ui/settings_panel.gd#L85)
- **自主动作调度**：执行器有优先级，但没有闲置计时、冷却、频率预算、情境选择或动作请求队列。闲置主要是循环 idle；丰富的动作由点击、设置预览或少数业务事件触发。图标避让是局部情境能力，不等于日常行为系统。[pet_view.gd:49](../../desktop-pet/pet/pet_view.gd#L49)、[pet_view.gd:91](../../desktop-pet/pet/pet_view.gd#L91)、[main.gd:300](../../desktop-pet/main.gd#L300)
- **键盘与发现性闭环**：宠物窗口 unfocusable，原生交互处理主要是鼠标；没有产品级快捷键入口或首次引导。部分按钮有 accessibility_name，不能等价于已验证全流程键盘/读屏可用。[pet_window.gd:36](../../desktop-pet/desktop/pet_window.gd#L36)、[pet_window.gd:145](../../desktop-pet/desktop/pet_window.gd#L145)、[settings_panel.gd:107](../../desktop-pet/ui/settings_panel.gd#L107)

### 需要运行验证，不能当成已知故障或已交付保证

1. **真实硬件资源成本**：存在节流实现和帧时测量脚本，但本次没有执行 CPU/GPU/内存/电量测量。60 FPS、3D、复杂输入区域和 PowerShell 图标读取分别占多少成本尚未知，不应先贴“高耗电”标签。
2. **操作系统可访问性**：Tab/Shift-Tab、焦点顺序、Escape 关闭、读屏宣布当前任务与错误、系统高对比、放大后超小屏布局，需在目标系统实际验收。默认 Godot 控件可能提供部分能力，缺少显式代码不代表全部不工作。
3. **macOS 产品完成度**：有启动项适配与相关测试，不代表本机静态阅读能证明签名、公证、安装、菜单栏恢复、Retina、多屏和全屏应用共处已通过。Windows 图标感知被明确禁用，属于平台能力差异。
4. **异常断电与并发边界**：计划使用临时文件与备份，但进程被强制结束、磁盘写满、重命名失败、不同文件系统的持久化语义需要故障注入；不可把 flush/rename 实现直接表述为“绝不丢数据”。
5. **成长保存风险大小**：偏好直接保存，并且失败提示只报告一次；活跃时间通常每 60 秒保存。断电、连续写失败和偏好损坏时的实际损失范围未测。源码支持“需要增强恢复”，不支持宣称已有用户数据丢失事件。[main.gd:145](../../desktop-pet/main.gd#L145)、[main.gd:391](../../desktop-pet/main.gd#L391)
6. **二次启动体验**：互斥失败会打印消息并退出，没有唤醒既有实例的 IPC。端口冲突与真实双开无法由当前返回值区分；发生频率未知，不能猜测其普遍性。[main.gd:40](../../desktop-pet/main.gd#L40)、[single_instance.gd:8](../../desktop-pet/desktop/single_instance.gd#L8)

## 3. 按用户价值排列的 10 个缺口

以下全部是**建议**。P0 = 日用信任与计划连续性；P1 = 下一阶段体验主线；P2 = 基础能力稳定后扩展。工作量为相对判断，不是交付承诺。

| 排序 | 建议与用户收益 | 最小可评审结果 / 验收方向 | 前置与规模 |
| --- | --- | --- | --- |
| 1 · P0 | **编辑任务保留进度 + 撤销误操作**。学到一半补一项、改错字，不必全清；误点完成可以恢复。 | 使用稳定 ID；支持追加、改名、删除确认与短期撤销；至少保证改任务名称不重置其他已完成项；撤销完成不自动推进。先保留顺序学习模式，重排规则另定。 | 先定义线性不变量与 schema 迁移；中 |
| 2 · P0 | **统一备份、导出和可预览恢复**。用户能主动把计划与陪伴记录带走，也能从坏文件中自救。 | 明示数据位置；导出包含格式版本的离线包；导入先校验并预览“替换什么/保留什么”，先建恢复快照；支持取消，未知版本不覆盖；计划、设置、成长都进入恢复边界。 | 存储策略、版本迁移；中 |
| 3 · P1 | **从“整张清单”补成“今天可开始的一小步”**。首次启动与每天返回都有清晰入口。 | 首次用示例或空白由用户选择；显示当前任务与今日选定项；可把未完成项留到下次，不扣成长；完成整单后提供“归档并创建下一轮”。先不做复杂日历与重复引擎。 | 稳定任务 ID、归档与时间语义；中 |
| 4 · P1 | **陪伴强度与减少动态**。让长期悬浮可接受，支持怕动效或需要高度专注的人。 | 一键安静/恢复、限时静默、固定位置、减少动态；图标感知、自动动作、提示共用同一策略；静默期间仍可主动打开计划与退出。 | 独立运行策略，动作调度消费策略；中 |
| 5 · P1 | **全流程键盘与可读性验收**。不靠精确点击晶体或图笺也能管理任务。 | 托盘/面板可发现入口；选定快捷键至少覆盖显示计划与隐藏/恢复；检查焦点顺序、无焦点陷阱、错误可读屏、字号放大后能操作；快捷键需允许禁用/改键并检查系统冲突。 | 先完成目标系统测试矩阵；中 |
| 6 · P1 | **可选轻量专注会话**。从“标记完成”前补一个开始、暂停、结束的过程，而不改成强制番茄钟。 | 计时与任务完成解耦；用户可暂停/结束但不完成任务；重启/挂起后能解释如何续接；会话数据与陪伴可见时长分开。提醒默认温和并可关闭。 | 独立 Session 模型、恢复语义；中到大 |
| 7 · P1 | **有预算的自主陪伴动作**。已有 19 个动作不再主要藏在设置里，也避免连续表演打扰工作。 | 闲置时低频挑选少量安静动作；有冷却与连续上限；用户动作、拖动、菜单、面板、引光优先；允许固定 idle；种子/时钟可注入，能重现调度问题。 | 运行策略、动作请求接口；中 |
| 8 · P1 | **测量后建立资源档位**。用户知道“省电/平衡/流畅”的实际效果，隐藏后可验证释放了工作量。 | 先记录典型机器与场景基线；再设可配置帧率、3D/2D、粒子与图标轮询预算；验收含显示/隐藏/设置预览、长时运行、挂起恢复；报告 CPU/GPU/内存和帧时分布。 | 保留现有 60 FPS 档和回退；中 |
| 9 · P2 | **温和回顾与成长可解释性**。让陪伴留下可理解的轨迹，同时避免刷时长/羞辱性连续签到。 | 显示已完成任务或自选会话记录；明示成长来自可见陪伴；休息/离线不倒退；如果引入里程碑，先用纪念与回顾，不加饥饿、死亡和强制签到。 | 完成历史与独立时间模型；中 |
| 10 · P2 | **日常可靠性与平台能力说明**。二次启动、图标读取失效、设置保存失败都有可操作反馈。 | 二次启动可唤回既有实例或给出可见说明；提供不含个人任务内容的诊断摘要；失败状态有重试/打开数据位置；在 UI 显示各平台能力差异。 | OS 适配/存储状态接口；中 |

建议实施顺序为 **1 → 2 → 3/4/5 → 6/7/8 → 9/10**。资源测量可在第一阶段并行开展；这里的顺序不要求先做大规模架构重写。多宠物市场、联网大模型、复杂养成经济与插件平台没有当前日用闭环价值证据，暂不列入首轮。

## 4. 可以沿用的架构边界与风险

### 计划模型与用例

`study_plan.gd` 是纯模型，`plan_store.gd` 是存储边界，`plan_panel.gd` 通过信号请求操作，`main.gd` 用 candidate 保存后再渲染；这是可沿用的清晰起点。[main.gd:177](../../desktop-pet/main.gd#L177)

下一步可在此边界增加稳定 ID、单项编辑命令、撤销与迁移，保留“先校验/持久化，再发布新状态”。不要让 UI 直接改 `plan.data`，也不要把“今日选择”或“计时状态”偷偷塞进 completed 布尔值。最大风险是重排/任意勾选破坏目前线性校验，以及旧版本文件因 schema 不识别而不能读；应明确升级方向与导出兼容范围，保留升级前快照。

### 存储与恢复

目前计划与偏好是两套生命周期：前者有校验/备份/阻断，后者 `ConfigFile.load/save`。建议先抽出小型数据仓库/备份服务，统一导出边界、写入状态、快照和恢复流程，而不是立即换数据库。[plan_store.gd:16](../../desktop-pet/study/plan_store.gd#L16)、[main.gd:391](../../desktop-pet/main.gd#L391)

风险包括恢复后计划与成长不匹配、导入覆盖新进度、错误版本静默降级、备份积累无上限、导出包含绝对路径/系统启动项。导出应携带逻辑数据，平台启动配置由新设备重新选择；保留未知配置字段，明确损坏文件不覆盖。

### 会话、日程与陪伴成长

`companionship.gd` 是小而可测的终身可见时间模型，应保留它的含义。专注 Session、今日选择、完成历史应各自表达业务时间；单调时钟计算持续时间，日历日期仅用于分组，挂起/系统时钟更改行为单独定义。[companionship.gd:11](../../desktop-pet/pet/companionship.gd#L11)、[main.gd:140](../../desktop-pet/main.gd#L140)

不要因为引入番茄钟，把当前总陪伴时间改写成“有效学习积分”；也不要让计时结束自动完成当前任务或自动切换下一项。

### 动作执行与行为决策

`pet_view.gd` 已有动作执行、优先级、生命周期和几何输出，应保持为渲染/执行器。新增行为调度器可以只读取时间、交互状态与安静策略，产出动作请求；输入感知继续由 `desktop/*` 提供事实，不直接启动庆祝或修改任务。[pet_view.gd:114](../../desktop-pet/pet/pet_view.gd#L114)、[main.gd:300](../../desktop-pet/main.gd#L300)

注意现有 `select_action` 是用户直接选择，绕过普通优先级比较；调度器不能复用它来抢占用户动作。须区分手动请求、业务事件和后台闲置请求；计划完成的庆祝可能被拖动阻断，是否延后播放应是明确策略，不能靠多个 Timer 竞争。

### 运行策略与系统适配

当前隐藏事件已经联动宠物、图标读取、窗口与低处理器模式，设置预览也有自己的可见性预算。将“活跃/隐藏/菜单/减少动态/静默/性能档位”的结果集中成小型策略状态，再传给执行器与桌面适配，能减少遗漏；但不需要先泛化出复杂行为树。[main.gd:94](../../desktop-pet/main.gd#L94)、[appearance_preview.gd:40](../../desktop-pet/ui/appearance_preview.gd#L40)

Windows/macOS 启动项已有分平台类；图标感知已有 freshness/失效回退和父进程管理，应该继续隔离。`read_desktop_icons.ps1` 获取图标几何、指针位置与按键状态，不请求图标文本或执行图标动作；后续功能不应为“更智能”随意扩大感知范围。[read_desktop_icons.ps1:90](../../desktop-pet/desktop/read_desktop_icons.ps1#L90)、[read_desktop_icons.ps1:124](../../desktop-pet/desktop/read_desktop_icons.ps1#L124)

## 5. 不可退化的回归约束

1. **手动推进**：完成当前不自动切下一项，计时结束不自动完成；末项不循环；重复点击完成不重复副作用。已有契约：[test_study.gd:11](../../desktop-pet/tests/test_study.gd#L11)、[test_ui.gd:17](../../desktop-pet/tests/test_ui.gd#L17)。
2. **失败不丢原状态**：保存失败不切内存状态；坏主文件可回退有效备份；主备均坏不重置；未知格式拒绝并保留原文件。已有契约：[test_study.gd:37](../../desktop-pet/tests/test_study.gd#L37)。新存储功能须增加故障注入与恢复取消路径。
3. **无惩罚的成长**：隐藏、离线、挂起不增长也不扣减；非法数值不污染累计；超过 40 小时外观进度保持上限，累计仍可增加。已有契约：[test_companionship.gd:10](../../desktop-pet/tests/test_companionship.gd#L10)、[check_growth_persistence.gd:29](../../desktop-pet/tests/check_growth_persistence.gd#L29)。
4. **桌面可操作**：透明空隙穿透；晶体/光笺显示完整且可点击；拖动不误触动作；全动作/缩放/屏幕工作区不截断；右键只开一次，菜单期间冻结移动输入区域。已有契约：[run_tests.gd:17](../../desktop-pet/tests/run_tests.gd#L17)、[test_context_menu.gd:20](../../desktop-pet/tests/test_context_menu.gd#L20)、test_coverage.gd:31（旧形象资料已移除）。
5. **恢复与退出入口**：托盘可恢复；无托盘时隐藏不能使唯一入口消失；系统关闭是真退出，不遗留图标子进程；保持启动项明确选择。已有实现：[pet_window.gd:137](../../desktop-pet/desktop/pet_window.gd#L137)、[icon_awareness.gd:159](../../desktop-pet/desktop/icon_awareness.gd#L159)。
6. **表现一致性**：保持温玉灵核与三块刚性晶体的身份；2D/3D 动作一致、几何覆盖与显示比例不因节能开关失配；失败回退可理解。不能用新增日程功能退回旧角色外观。
7. **隐藏确实停工作**：设置预览隐藏后不推进相位/不渲染；隐藏宠物停动画和图标读取；新增 scheduler、提醒、特效不能绕过静默策略。已有契约：[test_appearance_settings.gd:65](../../desktop-pet/tests/test_appearance_settings.gd#L65)。
8. **字号与平台边界**：全局字号覆盖设置/计划/确认框/菜单，放大后可操作；Windows 专用能力在其他平台解释并降级，不能导致主功能不可用。
9. **隔离验证**：所有写入型验证必须显式使用隔离目录；不得读取或覆盖真实学习数据、桌面快照与系统启动项。现有测试要求与实现：[test_study.gd:45](../../desktop-pet/tests/test_study.gd#L45)、[icon_awareness.gd:41](../../desktop-pet/desktop/icon_awareness.gd#L41)、[startup.gd:13](../../desktop-pet/desktop/startup.gd#L13)。

## 6. 实施前需要补齐的验收证据

- **计划连续性**：完成几项后改名/加项/撤销/退出重启；保留完成状态、当前项与备份恢复路径；整单完成后进入新一轮。
- **恢复安全性**：坏 JSON、主备均坏、未知版本、导入取消、写满磁盘、权限失败、强制结束；验证原文件、当前进度与成长不被静默覆盖。
- **安静与自主动作**：用可控时钟验证冷却/频率；拖动、菜单、计划窗口、引光、隐藏、减少动态下不抢占；用户关闭后完全停止自动决策。
- **日用可访问性**：鼠标与纯键盘各走一遍首次使用、加任务、完成、撤销、恢复数据、隐藏/找回、退出；目标系统读屏与四档字号实际检查。
- **资源与平台**：以当前版本为基线测显示/隐藏/预览/2D/3D/图标感知组合；记录典型 Windows 机器与 macOS 真实环境，测试多屏、DPI/Retina、挂起恢复和长时运行。先拿基线，再为性能档位设具体预算。

这些检查用于后续实现验收；本审计未运行它们，也不替代 v0.15.1 发布验证。
