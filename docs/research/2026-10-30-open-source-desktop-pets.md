# 温玉桌宠：开源项目机制调研

核对日期：2026-10-30。目的：为温玉的后续路线提供可追溯的设计参考，不改变当前实现。本次读取项目自己的 GitHub 仓库、固定提交文件与发行元数据；未安装或运行上游，没有帧率、内存、功耗、实际交互手感或安装成功率对比，也未复用代码、美术、音效或模型。

本次任务给定基线为 Godot 4.7.2、离线安静学习陪伴、三件式温玉能量核心、19 个动作、目标灯、本地有序学习清单与手动推进，以及现有 3D / 2D、Windows / macOS 包。下文“建议”是针对这组约束的设计判断，不是上游作者结论，也不表示温玉已经具备所建议功能。

证据标记：**文档**指作者的 README、ADR、开发说明或发布说明；**源码**指本次实际阅读的代码或配置；**发行**指 GitHub release 元数据和附件列表；**判断**指本项目的推导。公开源码、作者描述的成品能力、实际发出的二进制包分别记录；“未核实”不等于功能不存在。

## 1. 固定快照与需要更新的旧结论

| 项目 | 本次默认分支 HEAD | 发行与状态边界 |
| --- | --- | --- |
| [ayangweb/BongoCat][B0] | `master`，[`47a73ed1765b13fdd674ec356d51b5b16a6b5a5b`][BH]，2026-10-28 | **发行**：最新稳定版 [v2.4.1][BR]，有 Windows x64 EXE、macOS arm64 / x64 DMG。2.0 发布说明明确改为 Rust 原生架构，并停止提供 Linux 构建，不能沿用早期 Tauri / Linux 印象。[2.0 说明][B2] |
| [LorisYounger/VPet][V0] | `main`，[`515d7887fa3479d03dd11cd567a2cf752bd5b15f`][VH]，2026-10-28 | **文档**：WPF 桌宠，可由 Steam 获取，也提供可嵌入 WPF 应用的 NuGet 核心。本次没有取得可作为稳定版对照的 GitHub latest release，因此以下只评估固定源码与官方文档，不声称 Steam 成品和 HEAD 完全一致。[README][V1] |
| [ChaozhongLiu/DyberPet][D0] | `main`，[`20e2ff3366f8d6785a517bb8a7f0dc3f5a9b0a10`][DH]，2026-10-16 | **文档**明确仅开源到 v0.6.7，LLM 能力尚未完全开源；**发行**最新为 [v0.11.5][DR]，附件只有 Windows full / patch ZIP。发布说明另描述 Mac 包和网盘入口，本次未查验网盘内包。[源码边界][D1] |
| [zenghongtu/PPet][P0] | `dev`，[`2185c3f90600e3f809d55dbeedc7b82a341d06ca`][PH]，2022-02-27 | **发行**：[v3.3.0][PR] 发布于 2022-02-21，有 Windows、macOS、Linux 附件；**源码** package.json 为 Electron 16 / React 17。旧包存在不等于已验证对当前系统的兼容性。[package.json][P2] |
| [PC2005-cloud/dsh-pet][S0] | `main`，[`e858586a74a44468c923f71b00f3ee10c0a7c315`][SH]，2026-10-29 | **发行**：stable [v0.3.8][SR] 仍无附件；预发布 [v0.3.8-test.2][ST]（2026-10-25，prerelease）已有 `dsh-pet-win-x64.zip`。因此应更新 10-26 旧报告的交付边界为“已有 Windows 预发布绿色包”，不能写成稳定版已带包。HEAD 的 package.json 仍写 0.3.8，同版本号不能证明和旧 stable 源码等同。[包版本][S7] |
| [pixelomer/Shijima-Qt][Q0] | `main`，[`57723f1d7a4ea4a32e5fbb90deb7febc0dd49f63`][QH]，2026-04-29 | **文档**已明确停止维护和归档；作者说明稳定版长期停在 [v0.1.0][QR]，缺少后续库修复。该版有 Win / Linux / Mac 附件，但说明 Mac 与 Linux arm64 构建未测试。作为行为配置参考，不作为持续维护的发行底座。[归档说明][Q1] |

与旧研究相比，最重要的事实变化是 BongoCat 2.x 的平台 / 架构与插件功能，以及 dsh-pet 已存在的预发布 Windows ZIP 和如今明确分列的素材许可。DyberPet 的“公开源码落后于新成品”边界仍成立。[BongoCat 2.0][B2]、[2.4 插件][B24]、[dsh 预发布][ST]、[dsh 当前许可段][S1]、[DyberPet 状态][D1]。

## 2. 互动、行为调度与实用闭环

| 项目 | 互动与持续使用循环 | 行为调度证据 | 实用功能与边界 |
| --- | --- | --- | --- |
| BongoCat | **文档**：键盘、鼠标、手柄输入触发 Live2D 反馈，自定义模型；README 定位离线陪伴。本次未审计其所有网络路径。[README][B1] | **源码**：随机行为有关闭 / 表情 / 动作 / 两者四种模式；切模型重新等待完整间隔，长暂停不补发一串动作；自动动作使用 Idle 优先级，会让位于尚未完成的手动动作。[调度器][B3]、[执行准入][B4] | **文档 / 发行**：2.4.0 新增插件中心、番茄时钟、按键音效与输入法状态。可借鉴“宠物表现和小工具分开”，不据此推定其番茄钟具备温玉的有序清单与手动推进规则。[2.4.0][B24] |
| VPet | **文档**：抚摸、提起、投喂、工作和角色扩展，适合养成型陪伴。[README][V1] | **源码** `GraphInfo` 将动作分为 Start / Loop / End / Single；**源码** `MainLogic` 有事件定时器、空闲判定和可扩展随机互动列表。三段式描述的是播放契约，不能直接推定所有动画衔接都无视觉跳变。[GraphInfo][V2]、[MainLogic][V3] | **源码** `WorkTimer` 区分时间完成、状态失败等停止原因，维护工作收益并发出事件。其游戏内工作、经验与金钱不是对真实学习成果的检测。[WorkTimer][V4] |
| DyberPet | **文档**：动画、互动、养成、任务、物品、迷你宠物；AI 是可选项。新 LLM 成品不能当作已公开实现。[README][D1] | **源码**：按状态与配置权重计算随机动作；`focus_timer_on` 且存在 focus 动作时优先播放专注动作。**文档**将 `pet_conf` 的行为配置与 `act_conf` 的帧数、间隔和移动分开。[modules.py][D2]、[素材文档][D3] | **源码**任务页面组装 FocusPanel、ProgressPanel、TaskPanel；帮助文案描述专注 / 番茄钟、每日目标与待办奖励。能证实“学习工具连到宠物状态”的结构，不能由此断言新成品和该版 UI 一致。[taskUI][D4] |
| PPet | **文档**：Live2D v2/v3、本地 / 在线模型、拖动、缩放。**源码** Current 以 `autoMotion: true` 创建 viewer；本次没有核实 viewer 内部完整动作算法。[README][P1]、[Current][P3] | **源码** Tips 有消息优先级和自动消失时间；它是消息裁决，不应写成全角色行为调度系统。[Tips][P4] | **源码**工具栏提供切模型、调整大小、模型信息和在线一言请求，截图入口被注释。本次未发现可支持“完整学习计划器”结论的证据；不将“小工具”截图等同于待办 / 番茄钟已实现。[Toolbar][P5] |
| dsh-pet | **文档**：透明视频、随机动作、拖拽抛掷、分类点播、多实例；DSH 会话映射思考 / 工作 / 整理 / 等待 / 成功 / 出错状态。[README][S1]、[功能详解][S2] | **源码**将分类权重、避免连续重复、固定位置时禁止 turn / move 抽取等集中在共享纯函数；动画决策在走位已占用时不重复切片。[pickers][S3]、[next-animation][S4] | **文档 / 源码**：待办有到期时间，数据为用户级 `todos.json`；提醒政策独立成模块，一拍最多挑一条，临近时提高频率。其优先按到期时间展示与自动提醒不等同于温玉的用户有序清单；独立模式文档还列出余额、聊天、系统通知等不可用能力。[功能详解][S2]、[提醒源码][S5]、[独立边界][S6] |
| Shijima-Qt | **源码配置**：角色在地面、墙面、活动窗口边缘等条件下走动、攀爬，并配置鼠标追逐、拖动、抛掷；是环境互动型循环。[behaviors.xml][Q2]、[actions.xml][Q3] | **源码配置**使用 Condition、Frequency、NextBehavior 表达条件、相对频率和后继行为；菜单只列非隐藏行为供点播。它提供了“动作与行为图分开”的具体样本。[行为配置][Q2]、[菜单][Q4] | **判断**：本次所读 README、行为配置与菜单未提供学习工具的充分证据；它在本研究中主要贡献环境感知与行为图参考，而非学习产品闭环。[README][Q1]、[菜单][Q4] |

## 3. 打断控制、扩展与桌面交付

| 项目 | 用户控制与安静程度的可核实机制 | 内容 / 模组扩展 | 平台代价与适配判断 |
| --- | --- | --- | --- |
| BongoCat | **源码** overlay 配置包含点击穿透、悬停隐藏、闲置隐藏，以及按住快捷键暂时恢复可操作性；注释明确部分隐藏只降低渲染 alpha，帧循环仍运行，因此不能推断隐藏必然省电。[overlay 配置][B5] | **文档**支持导入 Live2D 模型；当前插件 ADR 采用独立进程和有版本协议，模型、渲染、功能扩展有独立边界。[README][B1]、[插件 ADR][B6] | **判断**：最值得借鉴穿透后的恢复入口与自动行为让位规则。全局输入捕获、Live2D 与插件进程会增加权限和维护面；温玉现在无需为轻量陪伴复制整套架构。Win / Mac 发包事实见 [v2.4.1][BR]。 |
| VPet | **源码**工作结束通过 C_End 返回常态，MainLogic 存在移动到侧边隐藏的处理；本次没有完整核实成品的全屏避让或统一勿扰开关。[WorkTimer][V4]、[MainLogic][V3] | **文档**创意工坊覆盖动画、物品、自定义工作、文本、主题和代码插件；核心可嵌入 WPF。可学习其“表现层 / 控制器 / 工作事件”分工。[README][V1] | **判断**：动作契约有价值；整套数值养成、商店、代码插件的内容成本明显高于温玉当前核心。README 的 WPF / Windows 路线不能直接替代 Godot 的双平台实现。[README][V1] |
| DyberPet | **文档**公开版更新记录包含关闭气泡、锁屏后暂停饱食 / 好感变化；**源码**专注状态会切到 focus 动作。[README][D1]、[modules.py][D2] | **文档**JSON 配置角色动作、物品、通知和语音，角色信息里单列作者与主页；**新版发行说明**新增稳定 mod ID 与文件夹名解耦、导入冲突重命名。这些 0.11.5 描述不能标成 0.6.7 源码已有。[素材文档][D3]、[0.11.5][DR] | **判断**：最适合参考“专注时缩窄行为”和角色内容包。饥饿衰减、索要食物、金币商店不是温玉必须具备的闭环；不照搬可减小用户照料负担。Win 附件已查，Mac 只确认作者说明。[发行][DR] |
| PPet | **文档 / 源码**有置顶与忽略点击；配置独立保存 `alwaysOnTop`、`ignoreMouseEvents`、`showTool`。**源码**工具栏默认透明，悬停才显露。[README][P1]、[配置][P6]、[Toolbar][P5] | **文档**支持文件夹拖入或 JSON 路径导入本地模型，也可在线模型；模型内容另指向外部资源库。[README][P1] | **判断**：少量入口和按需工具可参考；不引入在线语录依赖。2022 年发布包只能证明当时提供过多平台分发，需重新验证才可评价今日体验。[v3.3.0][PR]、[Toolbar][P5] |
| dsh-pet | **文档 / 发行**支持显示模式 none、固定位置、锁定当前屏；stable 说明默认关闭反复抬高窗口的看门狗，目的为避免打断全屏游戏与截图。**源码**同一动画池支持固定模式屏蔽漫游。[配置][S8]、[v0.3.8][SR]、[pickers][S3] | **文档**pet pack 的素材目录和动画池按种类隔离，缺失动作不回落到主宠素材；配置错误显式报告。只借鉴数据隔离与验收规则，不把透明视频数量作为体验质量指标。[CONFIG][S8] | **判断**：很适合参考“播放决定与各平台窗口壳分开”。当前可核实可下载的独立包仅 Windows 预发布；作者对其他平台的运行声明不等于本次完成双平台实机验证。[README][S1]、[预发布][ST] |
| Shijima-Qt | **源码**菜单提供 Pause、Dismiss、Dismiss all but one、Dismiss all；暂停与移除有明确入口。[菜单][Q4] | **源码配置**动作 XML 与行为 XML 分开；管理菜单允许点播，角色画面从资源加载层取得。[行为][Q2]、[动作][Q3]、[AssetLoader][Q5] | **文档**Mac 跟踪前台窗口需要辅助功能权限；Linux 涉及不同桌面环境和 shell 插件，且作者明确停止维护。**判断**：跨窗口攀爬不是免费的跨平台功能，应排在安静驻留、恢复入口和打包稳定性之后。[平台 / 归档说明][Q1] |

## 4. 代码、模型与美术许可分开记录

以下记录作者文件中的许可边界，用于选择研究参考；不是对再分发或商用资格的完整审查。本次只形成机制建议，不引入第三方内容。

| 项目 | 本次查见的代码许可 | 素材 / 依赖边界 |
| --- | --- | --- |
| BongoCat | [Apache-2.0][BL] | 作者专门记录 Cubism Core 与 Framework 的独立许可门禁；不能把仓库 Apache 标识解释为模型、Cubism 二进制或第三方音效的统一授权。[SDK 许可文档][B7] |
| VPet | [Apache-2.0][VL] | README 另列自带动画 / 图片的使用与分发条件，商用情形要求醒目来源说明并联系作者；第三方作者动画另行授权。代码许可不覆盖这些独立约定。[动画授权段][V1] |
| DyberPet | [GPL-3.0][DL] | 素材开发文档为角色与物品单列作者信息；本次未核实各外部角色包的独立授权，不将 GPL 根文件当作所有角色资源的统一复用许可。[作者信息][D3] |
| PPet | [MIT][PL] | README 的模型资源指向另一仓库。此处只确认程序代码许可，未核实外部模型、Live2D 组件或模型角色形象的完整授权链。[README][P1] |
| dsh-pet | [MIT][SL] | **当前 README 明确区分**代码与素材：动画 / 提示词 / 源视频禁止商用；形象标为 CC BY-NC-SA 4.0，并规定衍生作品公开渠道署名来源。仅看根 LICENSE 会漏掉这一重要边界。[许可段][S1] |
| Shijima-Qt | [GPL-3.0][QL]；源码头另写 version 3 or later。[菜单源码][Q4] | 当前仓库含依赖与默认角色；本次没有逐个核实外部 Shimeji 角色包的授权。只研究行为描述方式。[仓库][Q0]、[默认行为][Q2] |

## 5. 五项最值得进入温玉路线的机制

以下均为**判断 / 待实施建议**。成本是相对工程估计，未给虚构工时；不要求迁移引擎，不要求接入 AI，不扩大当前学习清单规则。

| 优先级与建议 | 借鉴来源与温玉落点 | 成本 / 不适合直接照搬的部分 | 可验证的完成标准 |
| --- | --- | --- | --- |
| **P0：先控制何时动，再扩动作数量** | 参考 BongoCat 的手动动作优先、睡醒不补发，以及 DyberPet 专注动作准入。为 19 动作建立“直接操作 / 学习事件 / 常态微动作”次序；专注中只允许低幅度驻留，拖动 / 手动点播立即获得控制。建议静默优先使用温玉核心与目标灯的缓慢变化。[B3][B3]、[B4][B4]、[D2][D2] | **中**：需要单一动作入口、取消规则与专注策略。不要同时复制全局键盘捕获、频繁语音、饥饿催促；这些增加权限或注意力负担。 | 专注、拖拽、庆祝同时发生时输出确定；从锁屏 / 睡眠恢复不连播漏掉的动作；手动交互结束后才回到许可的常态动作。 |
| **P0：给每个动作补进入、保持、退出与边界** | 参考 VPet 三段式和 Shijima 后继行为。为当前动作登记进入 / 退出姿态、持续时长、可打断点、移动范围、2D / 3D 映射与缺失回退；独立目标灯不烘焙进角色动作。[V2][V2]、[Q2][Q2] | **中**：主要成本是逐动作姿态与窗口边界验收；不是换一个状态机就会自动变自然。dsh 的视频混合也不能当作骨骼姿态连续性保证。[dsh 播放形态][S1] | 19 动作逐项预览、打断和回常态；极端缩放下完整轮廓不被裁切；同一学习事件可映射 2D / 3D，缺动作仍保留学习状态。 |
| **P0：把学习事件变成短而有意义的回应** | 参考 VPet 区分完成 / 停止原因，以及 dsh 成功 / 出错只播一次、稳定状态持续的节奏。温玉仅在用户开始、暂停、手动完成、手动推进时更新姿态 / 核心 / 目标灯；结束庆祝一次后回到安静陪伴。[V4][V4]、[S2][S2] | **低至中**：以现有本地数据事件驱动。不要把时间到、AI 会话完成、金币奖励或到期排序当作学习任务已完成；dsh 的临近高频提醒不适合默认复制。[S5][S5] | 时间到只产生提示；完成和推进始终由用户确认；重开或重复事件不重复领奖 / 庆祝；当前任务、目标灯和清单顺序一致。 |
| **P1：先做小型本地内容包契约** | 参考 DyberPet 的动作 / 角色配置和稳定 mod ID 思路，及 dsh 的包间隔离。用稳定 ID 表示角色，清单记录资源版本、作者、来源、代码 / 美术许可、支持表现模式、动作映射和必要锚点；先只支持可信本地数据包。[D3][D3]、[DR][DR]、[S8][S8] | **中**：包括校验、错误提示、存档引用与资源验收。独立插件进程、代码 MOD、在线工坊和复杂脚本系统会把成本显著抬高，当前无需同步引入。[B6][B6] | 文件夹改名不丢失用户设置；缺资源明确报错且不串用别的角色；无许可说明的素材不进入发布清单；切角色不改学习数据。 |
| **P1：把“穿透后可恢复”和双平台包列为正式功能** | 参考 BongoCat 按键暂时恢复操作、PPet 的按需工具、Shijima 的暂停 / 移除入口。规划统一的隐藏 / 恢复 / 暂停策略，双平台逐项验证透明轮廓、缩放、多屏、睡醒恢复、首次启动、用户数据与退出。[B5][B5]、[P5][P5]、[Q4][Q4] | **中至高**：平台窗口行为往往比 UI 代码更昂贵。暂缓跨窗口攀爬与自动繁殖；有附件不等于已完成安装、签名、公证、权限和实机体验验证。[Q1][Q1]、[QR][QR] | Windows / macOS 各有明确包、系统 / 架构说明与验证结果；开启穿透或隐藏后有可发现的恢复路径；多屏拔插、DPI / Retina、全屏、锁屏后仍可恢复且不抢焦点。 |

建议执行顺序为动作准入与安静策略 → 19 动作契约与轮廓验收 → 学习事件闭环 → 可恢复桌面控制与双平台交付 → 小型本地内容包。包契约可以先写说明，但不应在自有角色和基本交付未稳定前投入完整工坊。该顺序是围绕温玉定位的取舍，不是开源项目功能排名。

## 6. 证据来源

下列源文件均在 2026-10-30 通过 GitHub 连接器读取；`blob/<SHA>` 固定源码，release 链接固定发行标签。搜索仅帮助发现项目与变化，本文未把第三方聚合页作为事实依据。既有 [项目参考](desktop-pet-projects.md) 与 [10-26 dsh 对比](dsh-pet-comparison-2026-10-26.md) 仅用于确定复核项，发生变化时以上述新快照为准。

[B0]: https://github.com/ayangweb/BongoCat
[BH]: https://github.com/ayangweb/BongoCat/commit/47a73ed1765b13fdd674ec356d51b5b16a6b5a5b
[B1]: https://github.com/ayangweb/BongoCat/blob/47a73ed1765b13fdd674ec356d51b5b16a6b5a5b/README.md
[B2]: https://github.com/ayangweb/BongoCat/releases/tag/v2.0.0
[BR]: https://github.com/ayangweb/BongoCat/releases/tag/v2.4.1
[B24]: https://github.com/ayangweb/BongoCat/releases/tag/v2.4.0
[B3]: https://github.com/ayangweb/BongoCat/blob/47a73ed1765b13fdd674ec356d51b5b16a6b5a5b/crates/bongocat-runtime/src/random_behavior.rs
[B4]: https://github.com/ayangweb/BongoCat/blob/47a73ed1765b13fdd674ec356d51b5b16a6b5a5b/crates/bongocat-runtime/src/worker/random_behavior.rs
[B5]: https://github.com/ayangweb/BongoCat/blob/47a73ed1765b13fdd674ec356d51b5b16a6b5a5b/crates/bongocat-config/src/config_schema/overlay.rs
[B6]: https://github.com/ayangweb/BongoCat/blob/47a73ed1765b13fdd674ec356d51b5b16a6b5a5b/docs/adr/0090-independent-plugin-processes.md
[B7]: https://github.com/ayangweb/BongoCat/blob/47a73ed1765b13fdd674ec356d51b5b16a6b5a5b/docs/cubism/cubism-sdk-source-and-license.md
[BL]: https://github.com/ayangweb/BongoCat/blob/47a73ed1765b13fdd674ec356d51b5b16a6b5a5b/LICENSE
[V0]: https://github.com/LorisYounger/VPet
[VH]: https://github.com/LorisYounger/VPet/commit/515d7887fa3479d03dd11cd567a2cf752bd5b15f
[V1]: https://github.com/LorisYounger/VPet/blob/515d7887fa3479d03dd11cd567a2cf752bd5b15f/README.md
[V2]: https://github.com/LorisYounger/VPet/blob/515d7887fa3479d03dd11cd567a2cf752bd5b15f/VPet-Simulator.Core/Graph/GraphInfo.cs
[V3]: https://github.com/LorisYounger/VPet/blob/515d7887fa3479d03dd11cd567a2cf752bd5b15f/VPet-Simulator.Core/Display/MainLogic.cs
[V4]: https://github.com/LorisYounger/VPet/blob/515d7887fa3479d03dd11cd567a2cf752bd5b15f/VPet-Simulator.Core/Display/WorkTimer.xaml.cs
[VL]: https://github.com/LorisYounger/VPet/blob/515d7887fa3479d03dd11cd567a2cf752bd5b15f/LICENSE
[D0]: https://github.com/ChaozhongLiu/DyberPet
[DH]: https://github.com/ChaozhongLiu/DyberPet/commit/20e2ff3366f8d6785a517bb8a7f0dc3f5a9b0a10
[D1]: https://github.com/ChaozhongLiu/DyberPet/blob/20e2ff3366f8d6785a517bb8a7f0dc3f5a9b0a10/README.md
[D2]: https://github.com/ChaozhongLiu/DyberPet/blob/20e2ff3366f8d6785a517bb8a7f0dc3f5a9b0a10/DyberPet/modules.py
[D3]: https://github.com/ChaozhongLiu/DyberPet/blob/20e2ff3366f8d6785a517bb8a7f0dc3f5a9b0a10/docs/art_dev.md
[D4]: https://github.com/ChaozhongLiu/DyberPet/blob/20e2ff3366f8d6785a517bb8a7f0dc3f5a9b0a10/DyberPet/Dashboard/taskUI.py
[DR]: https://github.com/ChaozhongLiu/DyberPet/releases/tag/v0.11.5
[DL]: https://github.com/ChaozhongLiu/DyberPet/blob/20e2ff3366f8d6785a517bb8a7f0dc3f5a9b0a10/LICENSE
[P0]: https://github.com/zenghongtu/PPet
[PH]: https://github.com/zenghongtu/PPet/commit/2185c3f90600e3f809d55dbeedc7b82a341d06ca
[P1]: https://github.com/zenghongtu/PPet/blob/2185c3f90600e3f809d55dbeedc7b82a341d06ca/README.md
[P2]: https://github.com/zenghongtu/PPet/blob/2185c3f90600e3f809d55dbeedc7b82a341d06ca/package.json
[P3]: https://github.com/zenghongtu/PPet/blob/2185c3f90600e3f809d55dbeedc7b82a341d06ca/src/renderer/src/pages/Model/Current.tsx
[P4]: https://github.com/zenghongtu/PPet/blob/2185c3f90600e3f809d55dbeedc7b82a341d06ca/src/renderer/src/pages/Model/Tips.tsx
[P5]: https://github.com/zenghongtu/PPet/blob/2185c3f90600e3f809d55dbeedc7b82a341d06ca/src/renderer/src/pages/Model/Toolbar.tsx
[P6]: https://github.com/zenghongtu/PPet/blob/2185c3f90600e3f809d55dbeedc7b82a341d06ca/src/common/config.ts
[PR]: https://github.com/zenghongtu/PPet/releases/tag/v3.3.0
[PL]: https://github.com/zenghongtu/PPet/blob/2185c3f90600e3f809d55dbeedc7b82a341d06ca/LICENSE.md
[S0]: https://github.com/PC2005-cloud/dsh-pet
[SH]: https://github.com/PC2005-cloud/dsh-pet/commit/e858586a74a44468c923f71b00f3ee10c0a7c315
[S1]: https://github.com/PC2005-cloud/dsh-pet/blob/e858586a74a44468c923f71b00f3ee10c0a7c315/README.md
[S2]: https://github.com/PC2005-cloud/dsh-pet/blob/e858586a74a44468c923f71b00f3ee10c0a7c315/FEATURES.md
[S3]: https://github.com/PC2005-cloud/dsh-pet/blob/e858586a74a44468c923f71b00f3ee10c0a7c315/dsh-pet/src/shared/pickers.ts
[S4]: https://github.com/PC2005-cloud/dsh-pet/blob/e858586a74a44468c923f71b00f3ee10c0a7c315/dsh-pet/src/client/pet/animation/next-animation.ts
[S5]: https://github.com/PC2005-cloud/dsh-pet/blob/e858586a74a44468c923f71b00f3ee10c0a7c315/dsh-pet/src/host/todo/policy.ts
[S6]: https://github.com/PC2005-cloud/dsh-pet/blob/e858586a74a44468c923f71b00f3ee10c0a7c315/INSTALL.md
[S7]: https://github.com/PC2005-cloud/dsh-pet/blob/e858586a74a44468c923f71b00f3ee10c0a7c315/dsh-pet/package.json
[S8]: https://github.com/PC2005-cloud/dsh-pet/blob/e858586a74a44468c923f71b00f3ee10c0a7c315/CONFIG.md
[SR]: https://github.com/PC2005-cloud/dsh-pet/releases/tag/v0.3.8
[ST]: https://github.com/PC2005-cloud/dsh-pet/releases/tag/v0.3.8-test.2
[SL]: https://github.com/PC2005-cloud/dsh-pet/blob/e858586a74a44468c923f71b00f3ee10c0a7c315/LICENSE
[Q0]: https://github.com/pixelomer/Shijima-Qt
[QH]: https://github.com/pixelomer/Shijima-Qt/commit/57723f1d7a4ea4a32e5fbb90deb7febc0dd49f63
[Q1]: https://github.com/pixelomer/Shijima-Qt/blob/57723f1d7a4ea4a32e5fbb90deb7febc0dd49f63/README.md
[Q2]: https://github.com/pixelomer/Shijima-Qt/blob/57723f1d7a4ea4a32e5fbb90deb7febc0dd49f63/DefaultMascot/behaviors.xml
[Q3]: https://github.com/pixelomer/Shijima-Qt/blob/57723f1d7a4ea4a32e5fbb90deb7febc0dd49f63/DefaultMascot/actions.xml
[Q4]: https://github.com/pixelomer/Shijima-Qt/blob/57723f1d7a4ea4a32e5fbb90deb7febc0dd49f63/ShijimaContextMenu.cc
[Q5]: https://github.com/pixelomer/Shijima-Qt/blob/57723f1d7a4ea4a32e5fbb90deb7febc0dd49f63/AssetLoader.cc
[QR]: https://github.com/pixelomer/Shijima-Qt/releases/tag/v0.1.0
[QL]: https://github.com/pixelomer/Shijima-Qt/blob/57723f1d7a4ea4a32e5fbb90deb7febc0dd49f63/LICENSE
