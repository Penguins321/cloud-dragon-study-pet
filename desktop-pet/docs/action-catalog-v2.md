# 云龙动作复用手册 · v2 关节版

更新：2026-10-22。本页保留 v0.3 的身体与动作语义说明；v0.4 新增双须、鬃毛、五段尾部与分束尾焰，当前绑定和运动规则以 [v3 风动手册](wind-and-tail-v3.md) 为准。动作时间线仍共享 v2 库。[v1 手册](action-catalog.md) 和 `cloud_dragon_float_v1.tres` 保留归档。

## 直接操作

左键云龙依次切换 **游动 → 抬头 → 舒展 → 收拢 → 欢腾 → 游动**。在设置里选择姿态后，下次左键继续其后的动作。按住移动仍是拖动，松手不切换动作，单帧内完成的快速拖动也按拖动处理。左键任务气泡或右键云龙打开学习计划。

## 可复用资料

| 文件 | 内容 |
| --- | --- |
| `pet/motions/cloud_dragon_flexible_v2.tres` | 当前动作时间线与强度参数，颜色变化不修改此库 |
| `pet/skins/cloud_dragon/rig.gd` | 18 个关节的绑定位置、父子关系、权重、网格与运动规则 |
| `pet/skins/cloud_dragon/view.tscn` | 贴图 Polygon2D、绑定脚本和动画播放器；引用共享库 |
| `pet/skins/cloud_dragon/skin.tres` | 语义动作映射、素材轮廓、完整运动范围和气泡锚点 |
| [结构拆解](rig-v2-design.md) | 从身体结构到动作的设计原则 |
| [实际姿态与骨架图](screenshots/rig-poses-v2.png) | 由 Godot 网格实际渲染，含游动两个相位、抬头、舒展、收拢与骨架示意 |
| [游动预览](screenshots/rig-swim-v2.gif) | 实际 Godot 骨架网格输出的 64 帧循环，约 30 FPS 预览；只展示关节运动，不用于性能测量 |
| `tests/test_flexible.gd` | 关节长度、权重、三角形、脸部比例、换动作连续性和切换顺序检查 |
| `tests/preview_motion.gd`、根目录 `scripts/encode-motion-preview.ps1` | 复现姿态图和动图的工具 |

上表路径以 `desktop-pet/` 为基准，注明根目录的除外。源 PNG 保持原样，未重新生成不一致的身体帧。

## 结构与单位

使用 440 × 178.86179 局部坐标；原素材画布 1968 × 800。`+Y` 向下，正角度为顺时针。骨骼层级为：

```text
肩带 (331,115)
├─ 胸椎 (280,122) → 腰椎 (235,102) → 骨盆 (190,105)
│  ├─ 尾根 (137,123) → 尾中 (80,125) → 尾尖 (32,86) → 尾焰附着 (31,50)
│  ├─ 近侧后肢上段 (181,115) → 下段 (155,144)
│  └─ 远侧后肢上段 (201,118) → 下段 (194,147)
├─ 颈 (348,81) → 头 (384,41)
├─ 近侧前肢上段 (339,124) → 下段 (350,147)
└─ 远侧前肢上段 (365,121) → 下段 (383,139)
```

父子偏移固定，只旋转关节，骨段长度不因姿态改变。55 × 30 网格单元、3,300 个三角形，顶点最多使用 4 个归一化骨骼权重。面部区域主要随头骨刚性运动。腿部按点到各骨段与脊柱的距离分配影响，避免用矩形选区把尾部边缘拉进后腿动作。同侧前 / 后肢成对交替，近远肢仅延迟 0.35 弧度，不跨越本素材的固定遮挡顺序。肢体旋转使用 0.65 校准增益，保留躯干与尾部较大的波动幅度。

## 参数和动作

| 参数 | 含义 / 校验范围 |
| --- | --- |
| swim_strength | 脊柱波动、尾摆和四肢划动的共同强度，0–1.1 |
| swim_speed | 游动相位每秒增加的弧度；当前动作使用 1–4 rad/s |
| neck_lift | 颈 / 头协作抬起程度，-0.4–1 |
| leg_fold | 四肢向各自肩 / 髋收回程度，0–1 |
| tail_curl | 尾根、中段、尖端依次弯曲的程度，0–0.4 |
| stretch | 四肢舒展和脊柱放缓，0–1 |

渲染使用校准范围内的值，避免时间线平滑插值的过冲超过测试范围。具体关键帧与精确数值以 `.tres` 为唯一数据源，关节角公式以 `rig.gd` 为准。

| 语义 / 动画名 | 时间线 | 主要参数与动作含义 |
| --- | --- | --- |
| idle / float | 4 秒循环 | strength 0.65；尾摆、躯干小波动、近远肢错相；叠加缓慢浮动 |
| swim / swim | 3 秒循环 | strength 1、speed 3；更明显的身体和尾部配合 |
| look、curious / look | 4 秒一次 | lift 峰值 1；胸腔保持，颈和头协作抬起 |
| stretch / stretch | 4 秒一次 | stretch 峰值 1、lift 0.5；前后肢沿合法关节方向展开 |
| rest、sleepy / rest | 6 秒一次 | fold 峰值 1、curl 0.4、lift -0.4；悬浮收拢，不做盘绕和闭眼 |
| celebrate / celebrate | 1.8 秒一次 | strength 1.1、speed 4；加强划动和尾摆，配合最高约 28 单位上浮 |
| dragging / carry | 2 秒循环 | fold 0.6；拖动时轻抬与收肢，释放回 idle |

游动相位持续推进，点击换动作时不重置；通过 0.25 秒参数混合过渡。语义自动动作仍受优先级约束；用户主动点击允许切换到选择的动作，拖动期间禁止点击循环。非循环动作结束回 idle；完成任务仍先保存成功再欢腾，不自动开始下一项。隐藏时暂停相位与动画。

## 换色复用与边界

仅换颜色时，保持同一画布、透明轮廓、身体比例和关节位置，在继承场景中替换 Illustration 的 Texture 或只修改其 `self_modulate` RGB，Alpha 保持 1。继续引用同一个 `rig.gd` 和 v2 动画库。新 skin 的 `render_texture` 必须与实际外观相符；无需重做动作，也不复制关键帧。

换比例、重画四肢位置或换身体结构，需要重新绑定权重并验证；本版不是任意角色通用骨架。当前单面素材不支持转背、翻身、远近肢互换或盘绕，需先补分层 / 多视角素材。收拢姿态也不宣称已提供独立闭眼表情。

显示包围框为 `Rect2(-45,-90,535,345)`，覆盖已测试姿态；拖动每帧限制整个窗口在屏幕工作区内。GPU 与原生显示轮廓使用相同网格三角形的重心插值；轮廓在水平、垂直和对角网格边界处细分，避免大幅弯曲时直线截掉身体。轮廓余量与半像素更新阈值沿用 v1 的取整保护。

## 历史预览与复现

在项目根目录 PowerShell 执行：

```powershell
$env:CLOUD_DRAGON_PREVIEW_DIR = Join-Path (Get-Location) '.tools/rig-frames'
$env:APPDATA = Join-Path (Get-Location) '.tools/appdata'
& '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --path desktop-pet --script res://tests/preview_motion.gd
powershell -NoProfile -STA -ExecutionPolicy Bypass -File .\scripts\encode-motion-preview.ps1 -FrameDirectory $env:CLOUD_DRAGON_PREVIEW_DIR -Destination (Join-Path (Get-Location) 'desktop-pet/docs/screenshots/rig-wind-v3.gif')
```

预览导出器输出静态姿态图及 PNG 帧，编码脚本使用 Windows 自带 WPF，不是运行产品的依赖。帧率实测用 `tests/measure_motion.gd`，不可从 GIF 播放速度推断实时帧率。实际测试范围与未完成项目见 [验证记录](verification.md)。
