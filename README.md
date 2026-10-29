# 温玉灵核学习搭子

Windows / macOS 离线桌面学习伙伴。半透明玉核、独立伴生玉片、连续悬浮动作和光影粒子；“引光”展开短暂光笺，显示当前学习目标。

![水晶玉核材质](desktop-pet/docs/screenshots/jade-crystal-material.png)

## 安装与分享

当前版本 **v0.15.1**。分发文件位于 `desktop-pet/build/dist/`：

- `WarmJade-v0.15.1-Setup.exe`：发给别人即可安装，支持选择目录、桌面 / 开始菜单快捷方式和卸载。
- `WarmJade-v0.15.1-Portable.zip`：解压后运行 `WarmJade.exe`，无需安装 Godot。
- `SHA256SUMS.txt`：供分发核验文件完整性。

安装仅针对当前用户，不要求管理员权限。卸载保留学习进度。安装包与程序尚未签名；构建与验证范围见 [打包说明](desktop-pet/packaging/README.md)。生成的二进制不提交 Git。

## 图标感知与新动作

v0.15.1 恢复干净的晶体形象，保留 3D 晶体、内部光芯和原有 15 个互动动作，并新增双片环绕、螺旋升降、交错环绕和核心巡光；火焰主题与火焰粒子已移除。温润玉晶、澄透水晶、幻彩欧泊支持 3D，并可在设置切回原版 2D。其他主题保留原有渲染。详情见 [v0.15.1 发布验证](desktop-pet/docs/release-v0.15.1.md)。

设置中可开关桌面图标感知：只读位置，停留在图标附近时轻轻转向，遮挡时尽量移开，不读取文件内容。新增行走、捧腹大笑、跳跃、连跳、回旋、摇摆，点击或设置页可预览；全部动作结束回悬浮。详见 [图标与动作说明](desktop-pet/docs/icon-awareness-v0.11.md)。

## 粒子成长

玉核从开始就具备内部晶纹、通透层次和折光高光。成长只让粒子从 28 枚渐增到 72 枚，并增强微光；默认累计 40 小时有效陪伴达到上限。隐藏、休眠和离线不累计，退出时保存进度，不掉级。

## 操作

设置页支持四档“全局界面字号”：正常（当前默认）、大一点（120%）、戴眼镜（145%）、老年人（170%）。设置、学习计划、任务列表、编辑输入框、确认弹窗和应用菜单即时同步并记住选择；大字号使用应用绘制的菜单。

“隐藏宠物”保留后台托盘入口；Windows 主窗口 / 任务栏的“关闭”和托盘“退出”会保存后真正结束程序。隐藏图标面板中的托盘菜单使用 Windows 原生菜单接口。

轻点依次切换 19 个互动动作；按住拖动。右键进入学习计划、设置或退出。点击引光光笺打开计划，完成当前项后手动推进下一项。

设置页支持实时换装预览、开机自启动、50% / 75% / 100% / 125% 大小和动作预览，采用浅玉色分组布局。安装版使用固定程序名，升级前先退出旧版。数据保存在 `%APPDATA%\CloudDragonStudyPrototype`，不要把个人数据一起打包给别人。

## macOS 支持

已添加 macOS 自启动、Universal 导出和本地签名 / 可选公证打包流程。首版关闭桌面图标感知；真实 Mac 的置顶、菜单栏和安装验收仍待完成。Mac 上执行 `bash test-macos.sh` 和 `bash build-macos.sh`，详见 [Mac 构建与朋友试用说明](desktop-pet/packaging/MACOS.md)。

Windows 直接打包朋友试用版：`python scripts/build-macos-friends.py`。发送生成的 `desktop-pet/build/macos/WarmJade-Friends-macOS-0.15.1.zip` 即可，不需要 Apple 开发者证书。

## 开发与验证

```powershell
./setup-dev.ps1
./test-prototype.ps1
./build-prototype.ps1
./setup-installer-tools.ps1
./build-installer.ps1
./desktop-pet/packaging/test-installer.ps1
```

使用 Godot 4.7.2 标准版打开 `desktop-pet/project.godot`。本地开发可运行“启动温玉灵核.cmd”。本地引擎、编译器、下载包、导出程序及测试数据位于忽略目录，不纳入 Git。

- [项目操作与模块说明](desktop-pet/README.md)
- [全部动作轨迹及水晶材质](desktop-pet/docs/jade-motion-v0.8.md)
- [设置页优化](desktop-pet/docs/settings-v0.9.md)
- [形象设计资料](assets/companions/warm-jade-core/2026-10-26/README.md)

Godot 引擎与第三方许可随安装版和便携版分发。本项目尚未选择对外开源许可证。旧云龙 / 玉龙实现与历史设计档案保留，但不作为当前默认形象。
