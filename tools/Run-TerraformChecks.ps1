#Requires -Version 5.1
<#
.SYNOPSIS
    Runs local Terraform quality checks (fmt, validate and tflint) for this repository.

.DESCRIPTION
    For each Terraform configuration folder this script runs:
    1. terraform fmt -check -recursive -diff (or terraform fmt -recursive when -Fix is specified)
    2. terraform init -backend=false (so validate works without remote state access)
    3. terraform validate
    4. tflint, using the .tflint.hcl file in the repository root

    All steps are run for all folders, failures are collected, and a summary is shown at the end.
    The script exits with code 1 if any check failed.

.PARAMETER Path
    One or more Terraform configuration folders to check, absolute or relative to the repository root.
    Defaults to src/terraform and pipeline/terraform/cicd.

.PARAMETER Fix
    Rewrites files with terraform fmt instead of only checking formatting.

.PARAMETER SkipTflint
    Skips the tflint step (for example when tflint is not installed).

.PARAMETER SkipInit
    Skips terraform init. Use only when providers are already initialised.

.EXAMPLE
    .\tools\Run-TerraformChecks.ps1

.EXAMPLE
    .\tools\Run-TerraformChecks.ps1 -Path src/terraform -Fix

.EXAMPLE
    .\tools\Run-TerraformChecks.ps1 -SkipTflint

.OUTPUTS
    None. Writes progress and a summary to the host and sets the process exit code.

.NOTES
    Requires terraform and (unless -SkipTflint is used) tflint on the PATH.
#>
[CmdletBinding()]
param(
  [Parameter()]
  [string[]]$Path = @('src/terraform', 'pipeline/terraform/cicd'),

  [Parameter()]
  [switch]$Fix,

  [Parameter()]
  [switch]$SkipTflint,

  [Parameter()]
  [switch]$SkipInit
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Path $PSScriptRoot -Parent
$tflintConfigPath = Join-Path -Path $repositoryRoot -ChildPath '.tflint.hcl'

$results = [System.Collections.Generic.List[object]]::new()

function Assert-ToolInstalled
{
  param(
    [Parameter(Mandatory)]
    [string]$Name
  )

  if (-not (Get-Command -Name $Name -ErrorAction SilentlyContinue))
  {
    throw "'$Name' was not found on the PATH. Install it and try again."
  }
}

function Invoke-CheckStep
{
  param(
    [Parameter(Mandatory)]
    [string]$Folder,

    [Parameter(Mandatory)]
    [string]$Step,

    [Parameter(Mandatory)]
    [scriptblock]$Command
  )

  Write-Host "  -> $Step" -ForegroundColor Green
  & $Command | Out-Null
  $exitCode = $LASTEXITCODE

  $results.Add([PSCustomObject]@{
      Folder = $Folder
      Step   = $Step
      Passed = ($exitCode -eq 0)
    })

  if ($exitCode -ne 0)
  {
    Write-Host "  [FAIL] $Step (exit code $exitCode)" -ForegroundColor Red
  } else
  {
    Write-Host "  [OK] $Step" -ForegroundColor Green
  }
}

Assert-ToolInstalled -Name 'terraform'

if (-not $SkipTflint.IsPresent)
{
  Assert-ToolInstalled -Name 'tflint'

  if (-not (Test-Path -Path $tflintConfigPath))
  {
    throw "tflint config not found at '$tflintConfigPath'."
  }

  Write-Host 'Installing tflint plugins...' -ForegroundColor Cyan
  tflint --init --config $tflintConfigPath
  if ($LASTEXITCODE -ne 0)
  {
    throw 'tflint --init failed. Set GITHUB_TOKEN if you are being rate limited.'
  }
}

foreach ($folder in $Path)
{
  $fullPath = if ([System.IO.Path]::IsPathRooted($folder))
  {
    $folder
  } else
  {
    Join-Path -Path $repositoryRoot -ChildPath $folder
  }

  if (-not (Test-Path -Path $fullPath -PathType Container))
  {
    throw "Terraform folder not found: '$fullPath'."
  }

  Write-Host ''
  Write-Host '======================================' -ForegroundColor Cyan
  Write-Host "Checking: $folder" -ForegroundColor Cyan
  Write-Host '======================================' -ForegroundColor Cyan

  Push-Location -Path $fullPath
  try
  {
    if ($Fix.IsPresent)
    {
      Invoke-CheckStep -Folder $folder -Step 'terraform fmt' -Command {
        terraform fmt -recursive
      }
    } else
    {
      Invoke-CheckStep -Folder $folder -Step 'terraform fmt -check' -Command {
        terraform fmt -check -recursive -diff
      }
    }

    $initPassed = $true
    if (-not $SkipInit.IsPresent)
    {
      Invoke-CheckStep -Folder $folder -Step 'terraform init -backend=false' -Command {
        terraform init -backend=false -input=false | Out-Null
      }
      $initPassed = $results[$results.Count - 1].Passed
    }

    if ($initPassed)
    {
      Invoke-CheckStep -Folder $folder -Step 'terraform validate' -Command {
        terraform validate
      }
    } else
    {
      Write-Host '  [SKIP] terraform validate (init failed)' -ForegroundColor Yellow
    }

    if (-not $SkipTflint.IsPresent)
    {
      Invoke-CheckStep -Folder $folder -Step 'tflint' -Command {
        tflint --config $tflintConfigPath
      }
    }
  } finally
  {
    Pop-Location
  }
}
