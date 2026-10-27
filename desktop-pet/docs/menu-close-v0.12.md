# v0.12 托盘菜单与系统关闭

用户反馈：Windows 隐藏图标面板中的右键菜单重叠，最小化窗口的系统关闭不能退出。

根因：托盘右键回调在按下时手动打开独立 Godot 弹窗，未交给系统托盘原生菜单处理；主窗口 close_requested 明确连接到了 hide_pet，因此 Windows 关闭实际再次隐藏。

修复：

- 支持原生弹出菜单的平台通过 StatusIndicator.menu 绑定已有菜单，使用系统托盘菜单的焦点 / 关闭机制，保留原菜单项目与回调。Windows 左键恢复仍由引擎的左键回调处理。
- 主窗口系统关闭转发 quit_requested，接入既有保存设置 / 成长时长和退出流程；“隐藏宠物”仍是单独的可恢复操作。
- 桌宠本体右键等待匹配的松开事件后再延迟弹出；消费右键事件，避免在按下事件中改变接收窗口。
- 右键按下 / 等待弹出 / 自绘菜单可见期间标记交互忙碌，暂停自动避让与动画，避免鼠标下面的命中轮廓移动。原生 Windows 菜单自身运行在系统菜单循环中。

验证入口：`tests/check_context_menu.gd` 覆盖关闭与隐藏分离、匹配右键事件、重复释放、Windows 原生菜单实际绑定、菜单暂停后恢复动画；`tests/check_system_close.gd` 使用隔离主程序，最小化后发出系统关闭请求，验证退出及实际保存文件。

接口依据：[StatusIndicator.menu](https://docs.godotengine.org/en/stable/classes/class_statusindicator.html#class-statusindicator-property-menu)，[Godot Windows 原生菜单实现](https://github.com/godotengine/godot/blob/master/platform/windows/native_menu_windows.cpp)。
