# Windows 分发包

需要 64 位 Windows。在仓库根目录运行：

```powershell
./setup-installer-tools.ps1
./build-prototype.ps1
./build-installer.ps1
./desktop-pet/packaging/test-installer.ps1
```

输出：`desktop-pet/build/dist/WarmJade-v0.13-Setup.exe`、`WarmJade-v0.13-Portable.zip` 和 `SHA256SUMS.txt`。构建输入固定为对应版本的导出 EXE；安装后使用稳定文件名 `WarmJade.exe`。安装只写当前用户，允许选择目录，创建桌面和开始菜单快捷方式及 Windows 应用卸载项，不自动启动或开启开机启动。升级前先退出温玉，安装器沿用上次安装位置。

卸载只删除已知程序文件，保留用户自行放入的其他文件和 `%APPDATA%\CloudDragonStudyPrototype` 中的学习数据。仅当开机启动快捷方式指向本安装目录 EXE 时才删除它。请勿将两个版本同时运行。

安装器与 EXE 尚无代码签名，分发时可同时提供校验文件。NSIS 3.11 采用仓库 `.tools` 中的便携编译器，不安装系统软件。下载镜像为 NJU MacPorts；提取前必须匹配 [官方 SourceForge SHA256](https://sourceforge.net/projects/nsis/files/NSIS%203/3.11/nsis-3.11.zip/download) `c7d27f780ddb6cffb4730138cd1591e841f4b7edb155856901cdf5f214394fa1`。

`test-installer.ps1` 使用安装器的 `/TESTMODE` 和唯一工作区目录，跳过真实注册表、快捷方式和开机启动集成，验证安装文件、EXE 哈希、卸载及非程序文件保留。测试不验证真实用户集成写入；需在干净 Windows 用户或虚拟机中人工检查这些操作。测试目录保留作检查证据。

