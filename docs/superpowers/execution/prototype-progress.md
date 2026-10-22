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

## v0.2 增量：裁剪、动作、复用与跨电脑交接

- 用户授权上传后初始化 Git，首次原型提交 fe093d6，推送到 Penguins321/cloud-dragon-study-pet，API 核验 private=true。以上“无 Git”等条目为早期历史，不代表当前状态。
- Windows 原生输入区域同时裁剪画面。源图采样回归 RED 3,473 个漏点 → alpha 轮廓、独立点包含判据 → GREEN；四档缩放和五种动作的取整区域、最终组合区域与包围框通过。
- 新增 50% 档；设置增加动作预览后截图暴露底部挤出，改为滚动主体与固定底部按钮。
- 用户要求拖动中不出屏幕：每一帧夹取完整窗口至工作区；固定包围框覆盖全部动作幅度，松手不再是唯一夹取时机。
- 动作 RED 5 failures → 根节点悬浮、轻倾、休息、庆祝、拖动反馈 → GREEN。曲线平滑插值，0.25 秒过渡，隐藏暂停；不对未拆层图进行局部扭曲。
- 实测暴露严重性能问题：7,270 点两两连接，约 1.65 FPS。改显示尺度遮罩与简化、线性零宽桥、半像素阈值更新原生区，头尾 / 须 / 四肢采样仍通过。最终一次生产配置平均 56.28 FPS / P95 20.23 ms / 最大 152.64 ms；偶发长帧作为未解决限制记录，不宣称稳定 60 FPS。
- 动作复用 RED 共享库缺失 → 提取 pet/motions/cloud_dragon_float_v1.tres → GREEN。换色测试证明同一库与庆祝动作保留；动作目录归纳关键帧、坐标、触发、优先级、过渡及复用边界。最终全套 100/100。
- 新姿态 imagegen 结构 / 外观对照图、完整提示词与审阅限制归档到 assets/cloud-dragon/poses；未替换运行素材，待用户审阅与统一关节母版。
- 根目录 HANDOFF.md 与 setup-dev.ps1 / scripts/bootstrap-godot.py 提供固定工具版本和新电脑入口。已在当前电脑验证复用下载、哈希和项目导入；未假称在另一台电脑全新联网运行过。Python launcher 失效回退和 Windows Store alias 情况通过解释器探测处理，离线方式明确需要原 ZIP。
- 源码实际 OpenGL 与 Windows Validation 烟雾检查通过。渲染截图不等于原生裁剪截图，实际鼠标、多屏与 DPI 限制保留。
- 旧版 EXE 正在运行导致覆盖失败，保留用户进程与数据，改输出 CloudDragonPrototype-v0.2.exe；未强制退出用户实例。
- 最后独立只读审查：无新 Important 代码问题，更新过时验证文档后交接。开源项目调研另存 docs/research/desktop-pet-projects.md，仅参考一手资料，无第三方代码或美术复用。
