@echo off
setlocal enabledelayedexpansion

echo ================================================
echo         Signal AI Bot - Git Auto Deploy
echo ================================================

set KEY_PATH=C:\Users\porkb\Downloads\ec2-key-pair.pem
set HOST=ubuntu@ec2-35-178-1-8.eu-west-2.compute.amazonaws.com
set REMOTE_PATH=~/signal-ai-bot
set SERVICE_NAME=signal-ai-bot

set COMMIT_MSG=%*
if "!COMMIT_MSG!"=="" set COMMIT_MSG=Auto update

echo [1/6] 添加檔案變更...
git add .

echo [2/6] 提交變更...
git commit -m "!COMMIT_MSG!" || echo "沒有新變更"

echo [3/6] 推送到 GitHub...
git push origin main

echo [4/6] 在 EC2 上拉取最新代碼...
ssh -o "StrictHostKeyChecking=no" -i "%KEY_PATH%" %HOST% "cd %REMOTE_PATH% && git pull origin main"

echo [5/6] 重啟服務...
ssh -o "StrictHostKeyChecking=no" -i "%KEY_PATH%" %HOST% "sudo systemctl restart %SERVICE_NAME%"

echo [6/6] 檢查服務狀態...
ssh -o "StrictHostKeyChecking=no" -i "%KEY_PATH%" %HOST% "sudo systemctl status %SERVICE_NAME% --no-pager -l"

echo.
echo ================================================
echo            部署完成！
echo ================================================
pause