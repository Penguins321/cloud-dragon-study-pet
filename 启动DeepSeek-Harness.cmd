@echo off
cd /d "%~dp0"
set "DSH_HOME=%~dp0.tools\deepseek-harness\data"
set "PATH=%~dp0.tools\deepseek-harness\node-v24.22.1-win-x64;%PATH%"
"%~dp0.tools\deepseek-harness\node-v24.22.1-win-x64\node.exe" "%~dp0.tools\deepseek-harness\app\node_modules\@deepseek-ai\dsh\lib\bin.js" web --host 127.0.0.1 --port 3080
pause
