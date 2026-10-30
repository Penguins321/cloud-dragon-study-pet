# 温玉灵核学习搭子：开发说明

当前版本 v0.17，角色为温玉灵核、柯基、小鸭、水母。功能与操作见[项目首页](../README.md)。

## 模块

- `main.gd`：组合学习计划、专注会话、设置、桌面窗口与伙伴。
- `pet/skin_catalog.gd`：当前四个角色目录；`pet/skins/warm_jade` 为玉核，`pet/skins/animals` 为动物模型。
- `pet/pet_view.gd`、`pet/pet_skin.gd`：皮肤场景、动作与窗口几何；缺失可选动作回退待机。
- `pet/crystal_view_3d.gd`、`pet/energy_motes_3d.gd`：三维晶体、空间环绕光点；支持 2D 回退。
- `pet/effects/goal_light.gd`：独立引光光笺，不依赖旧形象或吐息特效。
- `study/`：计划持久化、数据导入导出、专注与设置保护。
- `ui/`：共享主题、顶部栏、设置与学习界面，支持全局字号。
- `desktop/`：拖动、透明区域、托盘、自启动、单实例与桌面图标感知。

## 构建与测试

从项目父目录执行 `./setup-dev.ps1`、`./test-prototype.ps1`、`./build-prototype.ps1`。Godot 固定为 4.7.2 标准版。启动入口为 `启动温玉灵核.cmd`。安装包和 Mac 包按需构建，方法见 [Windows 打包](packaging/README.md) 和 [macOS 打包](packaging/MACOS.md)。

`tests/run_tests.gd` 验证现有基础模块；其他专项覆盖玉核、动物、空间动作、界面、持久化和用户交互。不再包含云龙／玉龙专属测试。

## 数据兼容

学习数据继续保存在 `%APPDATA%\CloudDragonStudyPrototype`，测试隔离继续使用 `CLOUD_DRAGON_DATA_DIR`、`CLOUD_DRAGON_TEST_DIR`。保留旧技术标识，避免升级后丢失已有计划和设置。删除应用、切换角色和构建都不应删除用户学习数据。
