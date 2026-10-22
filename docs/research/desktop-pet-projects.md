# GitHub 桌宠项目参考

调研快照：2026-10-22。仅使用项目自己的仓库、README 与源码；Star 是当天页面显示的约数，会变化，以下不是排名。没有安装这些项目，也没有完成运行体验或资源消耗对比。

## 项目与适用参考

| 项目 | 当日关注量 | 已核对的技术与状态 | 对云龙的参考价值与边界 |
| --- | --- | --- | --- |
| [ayangweb/BongoCat](https://github.com/ayangweb/BongoCat) | 约 24.1k Stars | 跨平台桌宠，README 展示键鼠输入反馈与 Live2D；当前 [Cargo.toml](https://github.com/ayangweb/BongoCat/blob/master/Cargo.toml) 为 Rust 2024 多 crate 工程。仓库标注 Apache-2.0。 | 借鉴输入反馈、角色外观与设置入口。不能凭历史标签把当前架构写成 Tauri；本次以当前源码为准。 |
| [LorisYounger/VPet](https://github.com/LorisYounger/VPet) | 约 7k Stars | C# / WPF 桌宠框架，仓库代码标注 Apache-2.0；[README 动画版权声明与授权](https://github.com/LorisYounger/VPet/blob/main/README.md) 单独规定动画美术的使用条件。 | 参考动作组织与可扩展角色。代码许可证不等于角色动画授权，不能直接搬运其美术。 |
| [zenghongtu/PPet](https://github.com/zenghongtu/PPet) | 约 2k Stars | Electron、React、Live2D；仓库标注 MIT，README 提供 Windows、macOS、Linux 使用入口。 | 参考桌面交互与设置体验。它使用的运行栈和角色资源体系与本项目不同。 |
| [ChaozhongLiu/DyberPet](https://github.com/ChaozhongLiu/DyberPet) | 约 1k Stars | Python / PySide6 桌宠框架，仓库标注 GPL-3.0；README 明确公开源码为 v0.6.7，而新发行版为 v0.11.5。 | 参考角色配置与行为分离。阅读公开源码时，不能把较新发行版的全部功能当成源码已包含。 |
| [pixelomer/Shijima-Qt](https://github.com/pixelomer/Shijima-Qt) | 约 201 Stars | Qt 的 Shimeji 桌宠运行器，仓库标注 GPL-3.0；GitHub 页面显示已于 2026-04-29 归档，只读。 | 可参考动作与角色运行器的边界；归档状态意味着不能假定后续有持续维护。 |
| [xccds/DesktopPet](https://github.com/xccds/DesktopPet) | 约 25 Stars | Godot 4.3 桌宠示例，仓库标注 MIT。 | 作为同引擎实现参考，便于对照窗口与角色组织；关注量较低，不称为热门项目。 |

## 对当前项目的判断

以下是结合本项目目标作出的设计判断，不是上述仓库作者的结论。

- 继续使用现有 Godot + GDScript。当前学习计划、透明窗口与独立角色表现层已能工作，这组项目没有提供必须迁移整个代码库的依据。
- 学习逻辑继续只发出 `idle`、`curious`、`sleepy`、`celebrate`、`dragging` 等语义动作；皮肤负责映射动画和几何范围。参考其他项目时，优先比较这种边界是否清楚。
- 输入与设置值得借鉴：拖动范围、透明处穿透、隐藏恢复、大小调整和动作预览，应在本项目中逐项验证。别人的框架或动画资源不能替代 Windows 原生裁剪区域的实测。
- 新云龙姿态继续先检查头颈、肩、骨盆、四肢与尾根结构，再制作正式动画。保留自有或已明确授权的资源；任何第三方角色、Live2D 模型、动画、音效都先核对各自授权，不根据仓库代码许可证推定可复制。

本次只用于选择设计参考，没有复用第三方代码或美术。后续若决定引入具体模块，再核对对应版本、源码与依赖许可。
