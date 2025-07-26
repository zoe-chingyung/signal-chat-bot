@echo off
echo 檢查服務狀態...
ssh -o "StrictHostKeyChecking=no" -i "C:\Users\porkb\Downloads\ec2-key-pair.pem" ubuntu@ec2-35-178-1-8.eu-west-2.compute.amazonaws.com "sudo systemctl status signal-ai-bot --no-pager"
pause