# SDD ledger — plan: docs/superpowers/plans/2026-10-22-cloud-dragon-interactive-prototype.md

执行方式：用户确认推荐的当前会话直接执行，2026-10-22。

## 环境与裁决

- Ruling: 当前路径不是 Git 仓库，在授权的新子目录 desktop-pet 内直接实施，不创建无意义的 Git worktree，也不擅自初始化仓库；代价是本轮无 Git 提交记录，保留此执行记录及测试结果。
- Task 1 环境：已从官方仓库下载并运行 4.7.2.stable.official.ed1daf0bf；模板只按 HTTP 范围提取 Windows debug 成员，ZIP CRC 校验通过。
- Pre-flight Task 1→2: PetView 返回局部坐标，main 统一变换后交给 PetWindow；匹配。
- Pre-flight Task 2→4: 行为只调用语义动作；几何变化刷新气泡与命中区域；匹配。
- Pre-flight Task 3→4: 保存候选状态成功后才发布界面和动画；匹配。
- Ruling: Window 自带 visibility_changed() 信号，计划中的同名带参数信号不能重定义；改用 pet_visibility_changed(is_visible)，保持语义不变；代价是接口改名，全部调用方统一。
- Ruling: 执行工作记录保存在 docs/superpowers/execution，因没有 Git，不能依赖 Git 忽略区和提交恢复；不删除此记录。

## 实现与验证

- Task 1: implementation complete。离屏恢复 RED 2 failures → GREEN 3 checks；透明窗口与托盘接线已在实际 OpenGL 中运行。真正鼠标穿透、拖拽、多屏/DPI 的实机验收仍未完成。
- Task 2: complete。两种内部节点结构的测试皮肤、缺失/无效动作回退、优先级、旧回调与缩放几何均通过。
- Task 3: complete。创建清单 RED → GREEN；保存缺失 RED 2 failures → GREEN，损坏文件与失败写入检查通过。
- Task 4: implementation complete。UI RED 6 failures → GREEN；实际截图已查看，导出 Windows 原型与独立验证程序通过启动/接线检查。完整产品化不在本阶段。
- Ruling: 源码母版结构未定稿，运行时只从既有候选外观提取透明静态素材，不新增姿态或正式动画；代价是本原型没有完整情绪动作集。
- Ruling: Godot 原生主窗口不能直接 hide；按官方桌面方式改用 MODE_MINIMIZED/恢复 MODE_WINDOWED；代价是隐藏指托盘最小化语义，真实鼠标菜单仍需验收。
- Ruling: 导出模板不采用外部 --script 测试入口，增加独立验证预设，只改变入口、保留相同生产代码；代价是额外验证 exe，不作为产品交付入口。
- Final review: 独立只读 reviewer prototype_review，3 Important + 1 Minor；无 Critical。
- Final: fixed 并发实例旧快照覆盖 — scoped single-instance test RED→GREEN；使用 OS 生命周期持有的 localhost TCP 绑定，端口碰撞安全拒绝而不覆盖数据。
- Ruling: 互斥采用数据目录哈希的本地 TCP 端口，仅监听127.0.0.1且不发送任务数据；代价是极少数端口碰撞会拒绝启动，产品化可替换 Windows 命名互斥量。
- Final: fixed 左边缘面板遮挡 — 左右候选位置测试 RED→GREEN。
- Final: fixed 凸包吞掉透明空隙 — 组合轮廓用双向零宽桥保留凹口，几何回归 RED→GREEN；真实桌面输入未确认。
- Final: Ruling: 把缺失低级动作取消拖拽从 Minor 升为 Important — 模块扩展承诺适用于未来有效皮肤，而非仅看当前静态云龙 — 若判断过严只多一项小回归，不影响范围。
- Final: fixed 缺失低优先级动作取消拖拽 — 单项 RED failure→GREEN，全套64/64。
- Deferred minors: none。
- 工具限制：Windows Computer Use 应用授权超时，未继续执行输入；不把程序化信号测试写成鼠标测试。详见 desktop-pet/docs/verification.md。
- Ruling: 非Git工作区无分支可合并，保留工作区，不展示无意义的合并/PR菜单；代价是暂无版本控制，未来由用户选择初始化。
