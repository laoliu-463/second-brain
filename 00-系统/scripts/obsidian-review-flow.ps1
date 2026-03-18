param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("status","search","create_note","append_note","create","append","daily_append","open","open_daily")]
  [string]$Action,

  [string]$VaultPath = "d:\Docs\Books\my second brain",
  [string]$VaultName = "my second brain",
  [string]$Path,
  [string]$Query,
  [string]$Content
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-Cli {
  $com = Get-Command Obsidian.com -ErrorAction SilentlyContinue
  if ($com) { return $com.Path }
  $exe = Get-Command Obsidian.exe -ErrorAction SilentlyContinue
  if ($exe) { return $exe.Path }
  return $null
}

function Invoke-Cli {
  param([string[]]$Args)
  $cli = Resolve-Cli
  if (-not $cli) { throw "Obsidian CLI not found." }
  & $cli @Args
}

function Ensure-ParentDir {
  param([string]$FilePath)
  $dir = Split-Path -Parent $FilePath
  if ($dir -and -not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
}

function Get-AbsPath {
  param([string]$RelativePath)
  if ([System.IO.Path]::IsPathRooted($RelativePath)) { return $RelativePath }
  return (Join-Path $VaultPath $RelativePath)
}

function Get-TodayDailyRelativePath {
  $today = Get-Date
  $yyyy = $today.ToString("yyyy")
  $ym = $today.ToString("yyyy-MM")
  $date = $today.ToString("yyyy-MM-dd")
  return (Join-Path "02-日记\$yyyy\$ym" "$date.md")
}

function Ensure-Note {
  param(
    [string]$RelativePath,
    [string]$InitialContent
  )
  $abs = Get-AbsPath -RelativePath $RelativePath
  Ensure-ParentDir -FilePath $abs
  if (-not (Test-Path $abs)) {
    Set-Content -Encoding UTF8 -Path $abs -Value $InitialContent
  }
  return $abs
}

function Open-NoteByPath {
  param([string]$RelativePath)
  $escapedVault = [System.Uri]::EscapeDataString($VaultName)
  $escapedFile = [System.Uri]::EscapeDataString($RelativePath)
  $uri = "obsidian://open?vault=$escapedVault&file=$escapedFile"
  Start-Process $uri | Out-Null
  Write-Output "OPEN_URI: $uri"
}

switch ($Action) {
  "status" {
    $cli = Resolve-Cli
    if ($cli) {
      Write-Output "CLI_FOUND: $cli"
      $version = ""
      $v = (Get-Item $cli).VersionInfo
      if ($v) {
        if ($v.FileVersion) {
          $version = $v.FileVersion
        } elseif ($v.ProductVersion) {
          $version = $v.ProductVersion
        }
      }

      if (-not $version) {
        $cliDir = Split-Path -Parent $cli
        $exePath = Join-Path $cliDir "Obsidian.exe"
        if (Test-Path $exePath) {
          $v2 = (Get-Item $exePath).VersionInfo
          if ($v2) {
            if ($v2.FileVersion) {
              $version = $v2.FileVersion
            } elseif ($v2.ProductVersion) {
              $version = $v2.ProductVersion
            }
          }
        }
      }

      if ($version) {
        Write-Output "CLI_VERSION: $version"
      } else {
        Write-Output "CLI_VERSION: unknown"
      }
    } else {
      Write-Output "CLI_NOT_FOUND"
    }

    if (Test-Path $VaultPath) {
      Write-Output "VAULT_OK: $VaultPath"
    } else {
      Write-Output "VAULT_MISSING: $VaultPath"
    }
  }

  "search" {
    if (-not $Query) { throw "-Query is required for search." }
    try {
      # Command names vary by CLI version; attempt CLI search first.
      Invoke-Cli -Args @("search", "query=$Query", "vault=$VaultPath")
    } catch {
      # Fallback: ripgrep over markdown files
      if (Get-Command rg -ErrorAction SilentlyContinue) {
        rg -n --glob "*.md" -- $Query $VaultPath
      } else {
        Get-ChildItem -Recurse -File -Filter *.md $VaultPath | Select-String -Pattern $Query
      }
    }
  }

  "create_note" {
    if (-not $Path) { throw "-Path is required for create_note." }
    $abs = Get-AbsPath -RelativePath $Path
    Ensure-ParentDir -FilePath $abs
    $initialValue = ""
    if ($Content) { $initialValue = $Content }
    if (-not (Test-Path $abs)) {
      Set-Content -Encoding UTF8 -Path $abs -Value $initialValue
    } elseif ($Content) {
      Set-Content -Encoding UTF8 -Path $abs -Value $Content
    }
    Write-Output "CREATED_OR_UPDATED: $abs"
  }

  "create" {
    if (-not $Path) { throw "-Path is required for create." }
    $abs = Get-AbsPath -RelativePath $Path
    Ensure-ParentDir -FilePath $abs
    $initialValue = ""
    if ($Content) { $initialValue = $Content }
    if (-not (Test-Path $abs)) {
      Set-Content -Encoding UTF8 -Path $abs -Value $initialValue
    } elseif ($Content) {
      Set-Content -Encoding UTF8 -Path $abs -Value $Content
    }
    Write-Output "CREATED_OR_UPDATED: $abs"
  }

  "append_note" {
    if (-not $Path) { throw "-Path is required for append_note." }
    if (-not $Content) { throw "-Content is required for append_note." }
    $abs = Get-AbsPath -RelativePath $Path
    Ensure-ParentDir -FilePath $abs
    if (-not (Test-Path $abs)) {
      Set-Content -Encoding UTF8 -Path $abs -Value ""
    }
    Add-Content -Encoding UTF8 -Path $abs -Value ("`r`n" + $Content)
    Write-Output "APPENDED: $abs"
  }

  "append" {
    if (-not $Path) { throw "-Path is required for append." }
    if (-not $Content) { throw "-Content is required for append." }
    $abs = Get-AbsPath -RelativePath $Path
    Ensure-ParentDir -FilePath $abs
    if (-not (Test-Path $abs)) {
      Set-Content -Encoding UTF8 -Path $abs -Value ""
    }
    Add-Content -Encoding UTF8 -Path $abs -Value ("`r`n" + $Content)
    Write-Output "APPENDED: $abs"
  }

  "daily_append" {
    if (-not $Content) { throw "-Content is required for daily_append." }
    $relative = Get-TodayDailyRelativePath
    $today = Get-Date
    $title = $today.ToString("yyyy-MM-dd")
    $abs = Ensure-Note -RelativePath $relative -InitialContent "# $title"
    Add-Content -Encoding UTF8 -Path $abs -Value ("`r`n" + $Content)
    Write-Output "DAILY_APPENDED: $abs"
  }

  "open" {
    if (-not $Path) { throw "-Path is required for open." }
    Open-NoteByPath -RelativePath $Path
  }

  "open_daily" {
    $relative = Get-TodayDailyRelativePath
    $today = Get-Date
    $title = $today.ToString("yyyy-MM-dd")
    $null = Ensure-Note -RelativePath $relative -InitialContent "# $title"
    Open-NoteByPath -RelativePath $relative
  }
}

