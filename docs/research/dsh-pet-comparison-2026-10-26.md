# dsh-pet 与玉骨天龙原型对比

调研日期：2026-10-26。dsh-pet 基线为 `dfc03961bdb4d26898838cb72c9c2ac09699b1e2`（包版本 0.3.8）；本项目基线为 `104924f5f3db481b7eb5b191d53d8a34b63ed547`（v0.5）。只做静态资料与源码核对，没有安装、执行上游脚本或实测对方帧率。

## 核心差别

dsh-pet 是透明视频动作库与行为调度系统；当前玉骨天龙是整体透明贴图的实时骨架 / 网格变形，辅以局部闭眼与程序化云雾。前者目前更容易扩充丰富完整动作；后者适合连续调整尾巴、须、鬃毛和动态目标特效，但当前整体贴图绑定尚不能完成转背、肢体遮挡交换和独立下颌张合。[上游 README](https://github.com/PC2005-cloud/dsh-pet/blob/dfc03961bdb4d26898838cb72c9c2ac09699b1e2/README.md)、[本地绑定说明](../../desktop-pet/docs/jade-dragon-v1.md)。

## 动作制作与资产复用

上游流程是每个动作生成一段 10 秒绿幕视频，固定画幅与人物比例，并规定首尾回到标准正面站立。视频经抠像、站姿归一化、缩小至 640×360，产出 VP9-alpha WebM。文档特别说明：本项目所有动作实际采用 Premiere 手工抠像，自动 HSV 是保留的兜底路线。因此“添加视频与配置即可扩展”描述的是接入成本，不代表动画素材可以无成本产生。[制作文档](https://github.com/PC2005-cloud/dsh-pet/blob/dfc03961bdb4d26898838cb72c9c2ac09699b1e2/MAKE-YOUR-OWN-PET.md)。

| 情况 | dsh-pet 当前路线 | 玉骨天龙 v0.5 |
| --- | --- | --- |
| 新增打滚、吃东西、玩道具等完整表演 | 制作新视频并登记动作池，播放框架通常不变；结构一致性由素材制作负责 | 同视角小变形可复用绑定；涉及背面、道具或遮挡变化，需要补画拆层或独立动画素材 |
| 实时调整尾梢、龙须、鬃毛相位 | 视频内的局部运动已烘焙，不能直接操纵某节骨骼 | 已能连续调整绑定关节与软区参数，动作库继续复用 |
| 给同一条龙换颜色 | 统一滤镜可以整体调色；精确换局部颜色需对各视频处理或重做 | 调制色不改变骨架、时间线与相位；局部贴图重绘须同步闭眼区域 |
| 换成另一种身体比例的角色 | 制作其自己的完整视频池，可复用播放器与调度配置结构 | 可复用动作语义和驱动思路，必须重新绑定与验证；不同结构不能盲目套旧权重 |
| 展示每天不同的目标 | 可叠加独立文字与效果，不能把变化文字烘焙进每条视频 | 已将当前任务文本与云雾效果分离，口部锚点随网格变形 |

上述局部控制与重用成本是依据两种素材形态推导的工程判断；不表示任一引擎只能播放视频或只能用骨架。Godot 也可加入离线序列动作，Electron 也可以再引入骨架渲染，但都需额外实现。

## 切换与扩展接口

上游提供权重动画链、分类点播、事件槽位、多实例及 pet pack。一个新种类使用自己的配置和视频目录，动画池和素材与主宠物隔离，配置错误显式跳过；它的内容扩展入口比本项目当前内置 skin 和固定六动作循环成熟。[配置文档](https://github.com/PC2005-cloud/dsh-pet/blob/dfc03961bdb4d26898838cb72c9c2ac09699b1e2/CONFIG.md)、[本地动作入口](../../desktop-pet/pet/pet_view.gd)。

双缓冲交叉淡入能避免切换空白；统一首尾站姿也有助于接片。但交叉淡入是两幅图像透明度混合，并不计算骨架的姿态过渡、惯性或全身传力，不能仅凭“无缝”描述认定任意两个动作都具备物理连续性。本项目已有参数混合与持续相位，也仍未实现完整惯性求解。[上游 README 的切换说明](https://github.com/PC2005-cloud/dsh-pet/blob/dfc03961bdb4d26898838cb72c9c2ac09699b1e2/README.md)、[动作生成首尾约束](https://github.com/PC2005-cloud/dsh-pet/blob/dfc03961bdb4d26898838cb72c9c2ac09699b1e2/MAKE-YOUR-OWN-PET.md)。

进一步核对实际播放源码：`sprite.js` 创建两个 video 元素，`switchTo` 等待新视频 loadeddata 后切换 is-front；CSS 为 opacity 设置 0.18 秒过渡。`shared/physics.ts` 的弹簧、重力、恢复系数和摩擦处理整只宠物的运动 / 挤压，不是龙身各骨节的动力链。本次目录树统计内置 `assets/webm/` 为 106 个 WebM 文件；这是素材文件数，不是测试过的动作质量评分。[播放器](https://github.com/PC2005-cloud/dsh-pet/blob/dfc03961bdb4d26898838cb72c9c2ac09699b1e2/dsh-pet/runtime/electron-helper/sprite.js#L491-L580)、[淡入样式](https://github.com/PC2005-cloud/dsh-pet/blob/dfc03961bdb4d26898838cb72c9c2ac09699b1e2/dsh-pet/runtime/electron-helper/index.html#L44-L55)、[整宠物理](https://github.com/PC2005-cloud/dsh-pet/blob/dfc03961bdb4d26898838cb72c9c2ac09699b1e2/dsh-pet/src/shared/physics.ts)、[内置视频目录](https://github.com/PC2005-cloud/dsh-pet/tree/dfc03961bdb4d26898838cb72c9c2ac09699b1e2/dsh-pet/assets/webm)。

## 分发、目标功能与许可

上游有 DSH 插件、浏览器与 Electron 桌面模式，并提供无需启动 DSH 的独立 npm 入口。独立模式保留动作、拖拽、菜单、多开与 pet pack；聊天、余额等宿主能力不可用。源码存在 Windows 便携打包能力，不能笼统说朋友必须手动安装 Node；截至此次父任务核对，最新 v0.3.8 release 的 assets 列表为空，未确认可直接下载的 Windows 成品包。[README 独立运行说明](https://github.com/PC2005-cloud/dsh-pet/blob/dfc03961bdb4d26898838cb72c9c2ac09699b1e2/README.md)、[发行页](https://github.com/PC2005-cloud/dsh-pet/releases/tag/v0.3.8)。

本项目已有离线学习清单、手动完成 / 推进、本地保存与独立 Windows EXE；上游的会话事件与 AI 陪伴更丰富，但不能等同于已实现本项目的学习计划规则。双方自启动、实际安装便利性及性能优劣不能在未实测或未核对对应实现时下结论。[本地项目说明](../../desktop-pet/README.md)、[既有验证边界](../../desktop-pet/docs/verification.md)。

上游根许可证为 MIT，要求保留版权与许可声明。此事实支持评估代码复用；它没有逐项列出 AI 生成来源或第三方道具的独立授权链，不能由 MIT 文件推断所有外部权利均已清理。本次不做法律结论，也未复制上游美术或代码。[LICENSE](https://github.com/PC2005-cloud/dsh-pet/blob/dfc03961bdb4d26898838cb72c9c2ac09699b1e2/LICENSE)。

## 对本项目的建议

保留 Godot 与现有学习数据模块，优先借鉴上游的动作清单、分类与权重调度、pet pack 清单和动作素材验收流程；不要为了动作数量直接整体重写。云龙常态保留可交互的骨架、局部风动与独立雾幕；复杂翻身、盘绕或大幅表演可考虑制作独立经过结构验收的动作片段，再增加明确进入 / 退出姿态与可打断点。这是后续架构选项，尚未实施。

格式边界：Godot 4 核心只内置 Ogg Theora 视频支持，WebM 核心支持在 4.0 移除，因此不能直接把 dsh-pet 的 VP9-alpha 文件拖入本项目就播放。混合方案可以使用透明序列帧 / 图集；若沿用视频须另选解码扩展并验证透明与窗口轮廓。[Godot 官方视频说明](https://docs.godotengine.org/en/stable/tutorials/animation/playing_videos.html#supported-playback-formats)。
