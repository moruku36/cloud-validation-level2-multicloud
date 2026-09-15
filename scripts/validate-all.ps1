# validate-all.ps1
# Multi-cloud Terraform format and validation script
param (
    [switch]$FormatCheck = $true,
    [switch]$Validate = $true
)

$rootDir = Split-Path -Parent $PSScriptRoot
$targets = @("aws", "azure", "gcp")
$hasError = $false

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Running Multi-Cloud Terraform Checks" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Warning "'terraform' CLI is not found in PATH. Please install Terraform to execute local validations."
    Write-Host "Skipping execution."
    exit 0
}

foreach ($cloud in $targets) {
    $cloudDir = Join-Path $rootDir $cloud
    Write-Host "`n[$($cloud.ToUpper())] Checking root configuration..." -ForegroundColor Yellow
    
    Push-Location $cloudDir
    try {
        if ($FormatCheck) {
            Write-Host "  -> terraform fmt -check -recursive"
            terraform fmt -check -recursive
            if ($LASTEXITCODE -ne 0) { $hasError = $true; Write-Warning "  Format issues detected in $cloud" }
        }
        
        if ($Validate) {
            Write-Host "  -> terraform init -backend=false"
            terraform init -backend=false -input=false > $null
            Write-Host "  -> terraform validate"
            terraform validate
            if ($LASTEXITCODE -ne 0) { $hasError = $true; Write-Warning "  Validation failed in $cloud" }
        }

        # Check bootstrap if exists
        $bootstrapDir = Join-Path $cloudDir "bootstrap"
        if (Test-Path $bootstrapDir) {
            Write-Host "`n[$($cloud.ToUpper())] Checking bootstrap configuration..." -ForegroundColor Yellow
            Push-Location $bootstrapDir
            try {
                if ($Validate) {
                    Write-Host "  -> terraform init -backend=false"
                    terraform init -backend=false -input=false > $null
                    Write-Host "  -> terraform validate"
                    terraform validate
                    if ($LASTEXITCODE -ne 0) { $hasError = $true; Write-Warning "  Bootstrap validation failed in $cloud" }
                }
            }
            finally {
                Pop-Location
            }
        }
    }
    finally {
        Pop-Location
    }
}

Write-Host "`n=========================================" -ForegroundColor Cyan
if ($hasError) {
    Write-Host " Completed with errors or format warnings." -ForegroundColor Red
    exit 1
} else {
    Write-Host " All checks passed successfully!" -ForegroundColor Green
    exit 0
}