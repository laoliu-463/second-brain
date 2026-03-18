param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("init","status","next")]
  [string]$Action,

  [string]$Workdir = "d:\Docs\Books\my second brain"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SystemDir = Join-Path $Workdir "00-系统"
$SampleDir = Join-Path $SystemDir "测试样例"
$ReviewOutDir = Join-Path $SystemDir "审核结果"
$ReviewRealOutDir = Join-Path $SystemDir "审核结果-真实样本"
$AutoOutDir = Join-Path $Workdir "99-自动化/AI输出"
$TestLogDir = Join-Path $Workdir "99-自动化/测试日志"
$RealSampleDir = Join-Path $Workdir "01-收件箱"

# MVP 第一轮核心三篇
$CoreSamples = @(
  "样例01-项目推进.md",
  "样例03-阅读笔记-有来源.md",
  "样例04-资料整理-无具体链接.md"
)

function Ensure-Dir {
  param([string]$Path)
  if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Get-SampleFiles {
  if (-not (Test-Path $SampleDir)) { return @() }
  return @(Get-ChildItem -Path $SampleDir -File -Filter "样例*.md" | Sort-Object Name)
}

function Get-RealSampleFiles {
  if (-not (Test-Path $RealSampleDir)) { return @() }
  return @(Get-ChildItem -Path $RealSampleDir -File -Filter "真实样本*.md" | Sort-Object Name)
}

function Get-ResultFileName {
  param(
    [string]$SampleName,
    [bool]$IsReal
  )

  $base = [System.IO.Path]::GetFileNameWithoutExtension($SampleName)
  if ($IsReal) {
    if ($base -match "^(真实样本\d+)-") {
      return "$($matches[1])-审核结果.md"
    }
    return "$base-审核结果.md"
  }

  if ($base -match "^(样例\d+)-") {
    return "$($matches[1])-审核结果.md"
  }
  return "$base-审核结果.md"
}

function New-ReviewStub {
  param(
    [string]$OutputPath,
    [string]$SampleRelative,
    [string]$Title
  )

  if (Test-Path $OutputPath) { return }

  $body = @"
# ${Title} - 审核结果

- 当前笔记：[[${SampleRelative}]]
- 整理模式：审核模式

## 分类结果
- 主类型：
- 转正状态：
- 次级判断：
- 是否建议拆分：

## 目录结果
- 目标目录：
- 处理方式：
- 目标笔记：

## 处理策略
-

## 已自动执行
-

## 需确认后执行
-

## 仅给出建议
-

## 判定依据
1.
2.
3.

## 链接状态
- 已确认链接：
- 候选链接：
- 未插入原因：

## 参考资料状态
- 已写入：
- 待补充：
- 当前是否满足正式定稿条件：

## 风险说明
-

## 最终建议
- 直接执行 / 审核后执行 / 退回收件箱
- 补充说明：

## 检查结论
- 结果等级：合格 / 有风险 / 不合格
- 失败标签：
"@

  Set-Content -Path $OutputPath -Value $body -Encoding UTF8
}

function Test-IsCompleted {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return $false }

  $raw = Get-Content -Path $Path -Raw -Encoding UTF8

  # 占位文本仍在，视为未完成
  if ($raw -match "直接执行\s*/\s*审核后执行\s*/\s*退回收件箱") { return $false }
  if ($raw -match "结果等级：\s*合格\s*/\s*有风险\s*/\s*不合格") { return $false }

  $lines = $raw -split "`r?`n"
  $hasFinal = $false
  $hasGrade = $false

  foreach ($line in $lines) {
    if ($line -match "^-\s*(直接执行|审核后执行|退回收件箱)\s*$") {
      $hasFinal = $true
    }
    if ($line -match "^-\s*结果等级：\s*(合格|有风险|不合格)\s*$") {
      $hasGrade = $true
    }
  }

  return ($hasFinal -and $hasGrade)
}

switch ($Action) {
  "init" {
    Ensure-Dir -Path $ReviewOutDir
    Ensure-Dir -Path $ReviewRealOutDir
    Ensure-Dir -Path $AutoOutDir
    Ensure-Dir -Path $TestLogDir

    $samples = Get-SampleFiles
    foreach ($s in $samples) {
      $outName = Get-ResultFileName -SampleName $s.Name -IsReal $false
      $outPath = Join-Path $ReviewOutDir $outName
      $rel = "00-系统/测试样例/$($s.Name)"
      $title = [System.IO.Path]::GetFileNameWithoutExtension($s.Name)
      New-ReviewStub -OutputPath $outPath -SampleRelative $rel -Title $title
    }

    $realSamples = Get-RealSampleFiles
    foreach ($r in $realSamples) {
      $outName = Get-ResultFileName -SampleName $r.Name -IsReal $true
      $outPath = Join-Path $ReviewRealOutDir $outName
      $rel = "01-收件箱/$($r.Name)"
      $title = [System.IO.Path]::GetFileNameWithoutExtension($r.Name)
      New-ReviewStub -OutputPath $outPath -SampleRelative $rel -Title $title
    }

    Write-Output "INIT_DONE"
    Write-Output "SAMPLE_COUNT: $($samples.Count)"
    Write-Output "REAL_SAMPLE_COUNT: $($realSamples.Count)"
    Write-Output "CORE_ROUND_COUNT: $($CoreSamples.Count)"
  }

  "status" {
    $samples = Get-SampleFiles
    $total = $samples.Count

    $completed = 0
    $pending = 0

    foreach ($s in $samples) {
      $outName = Get-ResultFileName -SampleName $s.Name -IsReal $false
      $outPath = Join-Path $ReviewOutDir $outName
      if (Test-IsCompleted -Path $outPath) { $completed++ } else { $pending++ }
    }

    $coreCompleted = 0
    foreach ($core in $CoreSamples) {
      $outName = Get-ResultFileName -SampleName $core -IsReal $false
      $outPath = Join-Path $ReviewOutDir $outName
      if (Test-IsCompleted -Path $outPath) { $coreCompleted++ }
    }

    $realSamples = Get-RealSampleFiles
    $realTotal = $realSamples.Count
    $realCompleted = 0
    $realPending = 0
    foreach ($r in $realSamples) {
      $outName = Get-ResultFileName -SampleName $r.Name -IsReal $true
      $outPath = Join-Path $ReviewRealOutDir $outName
      if (Test-IsCompleted -Path $outPath) { $realCompleted++ } else { $realPending++ }
    }

    Write-Output "CORE_ROUND: $coreCompleted/$($CoreSamples.Count) completed"
    Write-Output "SAMPLE_TEST: $completed/$total completed, $pending pending"
    Write-Output "REAL_TEST: $realCompleted/$realTotal completed, $realPending pending"
  }

  "next" {
    foreach ($core in $CoreSamples) {
      $outName = Get-ResultFileName -SampleName $core -IsReal $false
      $outPath = Join-Path $ReviewOutDir $outName
      if (-not (Test-IsCompleted -Path $outPath)) {
        Write-Output "NEXT_SAMPLE: 00-系统/测试样例/$core"
        Write-Output "RESULT_FILE: 00-系统/审核结果/$outName"
        return
      }
    }

    $samples = Get-SampleFiles
    foreach ($s in $samples) {
      $outName = Get-ResultFileName -SampleName $s.Name -IsReal $false
      $outPath = Join-Path $ReviewOutDir $outName
      if (-not (Test-IsCompleted -Path $outPath)) {
        Write-Output "NEXT_SAMPLE: 00-系统/测试样例/$($s.Name)"
        Write-Output "RESULT_FILE: 00-系统/审核结果/$outName"
        return
      }
    }

    Write-Output "NEXT_SAMPLE: none"
  }
}
