# ============================================
# Obsidian 第二大脑定时备份脚本
# 每周执行，保留最近4周备份
# ====================================

# 配置区域
$sourcePath = "D:\Docs\Books\my second brain"
$backupRoot = "D:\Backup\Obsidian"
$retentionWeeks = 4

# 创建备份目录（如果不存在）
if (!(Test-Path $backupRoot)) {
    New-Item -ItemType Directory -Path $backupRoot -Force
}

# 生成备份文件名
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$backupName = "Obsidian-Backup-$timestamp.zip"
$backupPath = Join-Path $backupRoot $backupName

# 执行压缩备份
Write-Host "开始备份: $sourcePath"
Write-Host "备份目标: $backupPath"

try {
    Compress-Archive -Path $sourcePath -DestinationPath $backupPath -Force
    Write-Host "备份完成！" -ForegroundColor Green

    # 清理旧备份（保留最近N周）
    $cutoffDate = (Get-Date).AddDays(-($retentionWeeks * 7))
    $oldBackups = Get-ChildItem -Path $backupRoot -Filter "Obsidian-Backup-*.zip" |
                  Where-Object { $_.LastWriteTime -lt $cutoffDate }

    if ($oldBackups) {
        Write-Host "清理旧备份:"
        $oldBackups | ForEach-Object {
            Write-Host "  删除: $($_.Name)"
            Remove-Item $_.FullName -Force
        }
    }

    # 统计信息
    $backupSize = (Get-Item $backupPath).Length / 1MB
    Write-Host "备份大小: $([math]::Round($backupSize, 2)) MB"

} catch {
    Write-Host "备份失败: $_" -ForegroundColor Red
    exit 1
}

# 保留最近4个备份（额外保险）
$allBackups = Get-ChildItem -Path $backupRoot -Filter "Obsidian-Backup-*.zip" |
              Sort-Object LastWriteTime -Descending

if ($allBackups.Count -gt 4) {
    $toDelete = $allBackups | Select-Object -Skip 4
    $toDelete | ForEach-Object {
        Write-Host "额外清理: $($_.Name)"
        Remove-Item $_.FullName -Force
    }
}

Write-Host "备份任务完成！" -ForegroundColor Green
