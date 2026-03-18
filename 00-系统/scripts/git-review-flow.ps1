param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("status","commit_inbox","commit_ai_draft","commit_ai_reviewed","push")]
  [string]$Action,

  [string]$Workdir = "d:\Docs\Books\my second brain",
  [string[]]$Paths,
  [string]$Message = "",
  [switch]$Push,
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Run-Git {
  param([string[]]$Args)
  & git @Args
}

function Ensure-Git {
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git not found in PATH."
  }
}

function Add-Paths {
  param([string[]]$LocalPaths)
  foreach ($p in $LocalPaths) {
    Run-Git -Args @("add", "--", $p) | Out-Null
  }
}

function Has-Staged {
  $diff = Run-Git -Args @("diff", "--cached", "--name-only")
  return -not [string]::IsNullOrWhiteSpace(($diff -join "`n"))
}

function Commit-WithPrefix {
  param(
    [string]$Prefix,
    [string]$Desc
  )

  $descFinal = $Desc
  if ([string]::IsNullOrWhiteSpace($descFinal)) {
    $descFinal = "update"
  }

  $msg = "${Prefix}: $descFinal"
  if ($DryRun) {
    Write-Output "DRY_RUN_COMMIT: $msg"
    return
  }

  Run-Git -Args @("commit", "-m", $msg)
}

Ensure-Git
Set-Location $Workdir

switch ($Action) {
  "status" {
    Run-Git -Args @("-c", "core.quotepath=false", "status", "--short", "--untracked-files=all")
  }

  "commit_inbox" {
    $target = $Paths
    if (-not $target -or $target.Count -eq 0) {
      $target = @("01-收件箱")
    }

    if ($DryRun) {
      Write-Output ("DRY_RUN_ADD: " + ($target -join ", "))
    } else {
      Add-Paths -LocalPaths $target
    }

    if (-not (Has-Staged)) {
      Write-Output "NO_STAGED_CHANGES_FOR_COMMIT_INBOX"
      break
    }

    Commit-WithPrefix -Prefix "note(inbox)" -Desc $Message

    if ($Push) {
      if ($DryRun) {
        Write-Output "DRY_RUN_PUSH: origin current-branch"
      } else {
        Run-Git -Args @("push")
      }
    }
  }

  "commit_ai_draft" {
    if (-not $Paths -or $Paths.Count -eq 0) {
      throw "-Paths is required for commit_ai_draft (avoid accidental broad staging)."
    }

    if ($DryRun) {
      Write-Output ("DRY_RUN_ADD: " + ($Paths -join ", "))
    } else {
      Add-Paths -LocalPaths $Paths
    }

    if (-not (Has-Staged)) {
      Write-Output "NO_STAGED_CHANGES_FOR_COMMIT_AI_DRAFT"
      break
    }

    Commit-WithPrefix -Prefix "ai-draft" -Desc $Message

    if ($Push) {
      if ($DryRun) {
        Write-Output "DRY_RUN_PUSH: origin current-branch"
      } else {
        Run-Git -Args @("push")
      }
    }
  }

  "commit_ai_reviewed" {
    if (-not $Paths -or $Paths.Count -eq 0) {
      throw "-Paths is required for commit_ai_reviewed (avoid accidental broad staging)."
    }

    if ($DryRun) {
      Write-Output ("DRY_RUN_ADD: " + ($Paths -join ", "))
    } else {
      Add-Paths -LocalPaths $Paths
    }

    if (-not (Has-Staged)) {
      Write-Output "NO_STAGED_CHANGES_FOR_COMMIT_AI_REVIEWED"
      break
    }

    Commit-WithPrefix -Prefix "ai-reviewed" -Desc $Message

    if ($Push) {
      if ($DryRun) {
        Write-Output "DRY_RUN_PUSH: origin current-branch"
      } else {
        Run-Git -Args @("push")
      }
    }
  }

  "push" {
    if ($DryRun) {
      Write-Output "DRY_RUN_PUSH: origin current-branch"
    } else {
      Run-Git -Args @("push")
    }
  }
}

