# Git 檔案監控自動部署腳本
param(
    [string]$CommitMessage = "Auto update - $(Get-Date)",
    [switch]$WatchMode = $false,
    [switch]$DeployOnly = $false
)

# 設定變數
$REMOTE_HOST = "aws-server"
$REMOTE_PATH = "~/signal-ai-bot"
$SERVICE_NAME = "signal-ai-bot"
$BRANCH = "main"
$WATCH_PATH = Get-Location

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Deploy-ToServer {
    param([string]$Message = "Auto update")
    
    Write-ColorOutput "================================================" "Green"
    Write-ColorOutput "         Git Auto Deploy - Signal AI Bot" "Green"
    Write-ColorOutput "================================================" "Green"
    
    try {
        Write-ColorOutput "[1/8] 檢查 Git 狀態..." "Cyan"
        $status = git status --porcelain
        
        if (-not $DeployOnly) {
            if ($status) {
                Write-ColorOutput "[2/8] 添加檔案變更..." "Cyan"
                git add .
                
                Write-ColorOutput "[3/8] 提交變更..." "Cyan"
                git commit -m $Message
            } else {
                Write-ColorOutput "[2-3/8] 沒有檔案變更，跳過提交..." "Yellow"
            }
            
            Write-ColorOutput "[4/8] 推送到 GitHub..." "Cyan"
            git push origin $BRANCH
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput "WARNING: Git push 失敗，但繼續部署..." "Yellow"
            }
        }
        
        Write-ColorOutput "[5/8] 在 EC2 上拉取最新代碼..." "Cyan"
        ssh $REMOTE_HOST "cd $REMOTE_PATH && git pull origin $BRANCH"
        if ($LASTEXITCODE -ne 0) {
            throw "Git pull 失敗！"
        }
        
        Write-ColorOutput "[6/8] 安裝/更新依賴..." "Cyan"
        ssh $REMOTE_HOST "cd $REMOTE_PATH && if [ -f requirements.txt ]; then pip3 install -r requirements.txt; fi"
        
        Write-ColorOutput "[7/8] 重啟服務..." "Cyan"
        ssh $REMOTE_HOST "sudo systemctl restart $SERVICE_NAME"
        Start-Sleep -Seconds 2
        
        Write-ColorOutput "[8/8] 檢查服務狀態..." "Cyan"
        ssh $REMOTE_HOST "sudo systemctl status $SERVICE_NAME --no-pager -l"
        
        Write-ColorOutput "`n================================================" "Green"
        Write-ColorOutput "            部署完成！" "Green"
        Write-ColorOutput "================================================" "Green"
        
        # 顯示最新提交
        Write-ColorOutput "`n最新提交:" "Yellow"
        git log --oneline -1
        
        Write-ColorOutput "`n有用的命令:" "Yellow"
        Write-ColorOutput "查看即時日誌: ssh $REMOTE_HOST `"sudo journalctl -u $SERVICE_NAME -f`"" "Gray"
        Write-ColorOutput "查看服務狀態: ssh $REMOTE_HOST `"sudo systemctl status $SERVICE_NAME`"" "Gray"
        
        return $true
    }
    catch {
        Write-ColorOutput "ERROR: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Start-FileWatcher {
    Write-ColorOutput "開啟檔案監控模式..." "Yellow"
    Write-ColorOutput "監控路徑: $WATCH_PATH" "Yellow"
    Write-ColorOutput "監控檔案: *.py, *.txt, *.md, *.json" "Yellow"
    Write-ColorOutput "按 Ctrl+C 停止監控" "Yellow"
    
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $WATCH_PATH
    $watcher.Filter = "*.*"
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true
    
    # 只監控特定類型的檔案
    $watchedExtensions = @('.py', '.txt', '.md', '.json', '.yml', '.yaml')
    
    $action = {
        $path = $Event.SourceEventArgs.FullPath
        $changeType = $Event.SourceEventArgs.ChangeType
        $fileName = Split-Path $path -Leaf
        $extension = [System.IO.Path]::GetExtension($path)
        
        # 忽略不需要的檔案
        if ($fileName -match '^\.git' -or $fileName -match '__pycache__' -or $extension -notin $watchedExtensions) {
            return
        }
        
        Write-ColorOutput "`n檔案變更偵測: $fileName ($changeType)" "Magenta"
        Write-ColorOutput "等待檔案寫入完成..." "Gray"
        Start-Sleep -Seconds 2  # 等待檔案寫入完成
        
        $commitMsg = "Auto update: $fileName - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-ColorOutput "開始自動部署..." "Yellow"
        Deploy-ToServer -Message $commitMsg
    }
    
    Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action
    
    try {
        while ($true) {
            Start-Sleep -Seconds 1
        }
    }
    finally {
        $watcher.Dispose()
        Write-ColorOutput "檔案監控已停止" "Yellow"
    }
}

# 主程式
if ($WatchMode) {
    Start-FileWatcher
} else {
    Deploy-ToServer -Message $CommitMessage
}