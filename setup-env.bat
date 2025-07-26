@echo off
echo ================================================
echo      Signal AI Bot 環境變數設置
echo ================================================

set KEY_PATH=C:\Users\porkb\Downloads\ec2-key-pair.pem
set HOST=ubuntu@ec2-35-178-1-8.eu-west-2.compute.amazonaws.com

echo 請輸入你的 OpenAI API Key:
set /p OPENAI_KEY=

if "%OPENAI_KEY%"=="" (
    echo ERROR: API Key 不能為空！
    pause
    exit /b 1
)

echo [1/5] 停止現有服務...
ssh -o "StrictHostKeyChecking=no" -i "%KEY_PATH%" %HOST% "sudo systemctl stop signal-ai-bot"

echo [2/5] 創建 .env 文件...
ssh -o "StrictHostKeyChecking=no" -i "%KEY_PATH%" %HOST% "echo 'OPENAI_API_KEY=%OPENAI_KEY%' > ~/signal-ai-bot/.env && chmod 600 ~/signal-ai-bot/.env"

echo [3/5] 安裝依賴（如果需要）...
ssh -o "StrictHostKeyChecking=no" -i "%KEY_PATH%" %HOST% "cd ~/signal-ai-bot && pip3 install python-dotenv openai requests flask 2>/dev/null || echo '依賴已安裝'"

echo [4/5] 更新 systemd service...
ssh -o "StrictHostKeyChecking=no" -i "%KEY_PATH%" %HOST% "sudo tee /etc/systemd/system/signal-ai-bot.service > /dev/null << 'EOF'
[Unit]
Description=Signal AI Bot
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/signal-ai-bot
ExecStart=/usr/bin/python3 /home/ubuntu/signal-ai-bot/main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=signal-ai-bot
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF"

echo [5/5] 重新載入並啟動服務...
ssh -o "StrictHostKeyChecking=no" -i "%KEY_PATH%" %HOST% "sudo systemctl daemon-reload && sudo systemctl restart signal-ai-bot"

echo 等待服務啟動...
timeout /t 5 /nobreak >nul

echo 檢查服務狀態...
ssh -o "StrictHostKeyChecking=no" -i "%KEY_PATH%" %HOST% "sudo systemctl status signal-ai-bot --no-pager"

echo.
echo 檢查最新日誌...
ssh -o "StrictHostKeyChecking=no" -i "%KEY_PATH%" %HOST% "sudo journalctl -u signal-ai-bot -n 10 --no-pager"

echo.
echo ================================================
echo        環境變數設置完成！
echo ================================================
pause