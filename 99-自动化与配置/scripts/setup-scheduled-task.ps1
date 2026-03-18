# ============================================
# Windows 任务计划程序设置脚本
# 用于自动执行 Obsidian 备份
# ====================================

# 需要管理员权限运行

$taskName = "Obsidian-Backup"
$scriptPath = "D:\Docs\Books\my second brain\99-自动化与配置\scripts\backup-obsidian.ps1"

# 检查是否已存在同名任务
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "任务 '$taskName' 已存在，正在删除..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# 创建触发器 - 每周日凌晨2点
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am

# 创建操作 - 运行 PowerShell 脚本
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""

# 创建任务设置
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# 注册任务
Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings -Description "Obsidian 第二大脑每周备份"

Write-Host "任务 '$taskName' 已创建成功！" -ForegroundColor Green
Write-Host "执行时间: 每周日凌晨 2:00"
Write-Host "脚本路径: $scriptPath"

# 显示任务信息
Get-ScheduledTask -TaskName $taskName | Get-ScheduledTaskInfo
