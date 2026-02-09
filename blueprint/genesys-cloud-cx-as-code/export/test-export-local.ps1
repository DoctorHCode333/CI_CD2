#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test Genesys Cloud Terraform export locally with verbose debugging

.DESCRIPTION
    This script tests the export configuration locally with full debug logging
    to identify permission issues or configuration problems.
    
    IMPORTANT: This exports from TEST environment (us-east-1) where CI_CD_Test_Flow exists.
#>

Write-Host "=== Local Terraform Export Test with DEBUG Logging ===" -ForegroundColor Cyan
Write-Host "=== Exporting from TEST environment (us-east-1) ===" -ForegroundColor Yellow
Write-Host ""

# Check if OAuth credentials are set
if (-not $env:GENESYSCLOUD_OAUTHCLIENT_ID -or -not $env:GENESYSCLOUD_OAUTHCLIENT_SECRET) {
    Write-Host "ERROR: Genesys Cloud OAuth credentials not set!" -ForegroundColor Red
    Write-Host "Please set the following environment variables for TEST environment:" -ForegroundColor Yellow
    Write-Host "  `$env:GENESYSCLOUD_OAUTHCLIENT_ID = 'your-test-client-id'" -ForegroundColor Yellow
    Write-Host "  `$env:GENESYSCLOUD_OAUTHCLIENT_SECRET = 'your-test-client-secret'" -ForegroundColor Yellow
    Write-Host "  `$env:GENESYSCLOUD_API_REGION = 'https://api.mypurecloud.com'" -ForegroundColor Yellow
    Write-Host "  `$env:GENESYSCLOUD_REGION = 'us-east-1'" -ForegroundColor Yellow
    exit 1
}

Write-Host "OAuth Client ID: $($env:GENESYSCLOUD_OAUTHCLIENT_ID)" -ForegroundColor Green
Write-Host "API Region: $($env:GENESYSCLOUD_API_REGION)" -ForegroundColor Green
Write-Host "Region: $($env:GENESYSCLOUD_REGION)" -ForegroundColor Green
Write-Host ""

# Set Terraform debug logging
$env:TF_LOG = "DEBUG"
$env:TF_LOG_PATH = "./terraform-debug.log"

# Navigate to export directory
Push-Location $PSScriptRoot

try {
    # Clean previous export
    if (Test-Path "exported_resources") {
        Write-Host "Cleaning previous export..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force exported_resources
    }
    
    if (Test-Path "terraform-debug.log") {
        Remove-Item terraform-debug.log
    }
    
    Write-Host "Initializing Terraform..." -ForegroundColor Cyan
    terraform init
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Terraform init failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Running Terraform apply with auto-approve..." -ForegroundColor Cyan
    terraform apply -auto-approve
    
    Write-Host ""
    Write-Host "=== Export Results ===" -ForegroundColor Cyan
    
    if (Test-Path "exported_resources") {
        Write-Host "Exported files:" -ForegroundColor Green
        Get-ChildItem -Recurse exported_resources | Select-Object FullName, Length | Format-Table -AutoSize
        
        Write-Host ""
        Write-Host "=== YAML Flow Files ===" -ForegroundColor Cyan
        $yamlFiles = Get-ChildItem -Recurse exported_resources -Include *.yaml, *.yml -ErrorAction SilentlyContinue
        if ($yamlFiles) {
            $yamlFiles | ForEach-Object { Write-Host "  ✓ $($_.Name)" -ForegroundColor Green }
        } else {
            Write-Host "  ✗ No YAML files found!" -ForegroundColor Red
        }
        
        Write-Host ""
        Write-Host "=== Terraform Files ===" -ForegroundColor Cyan
        $tfFiles = Get-ChildItem -Recurse exported_resources -Include *.tf -ErrorAction SilentlyContinue
        if ($tfFiles) {
            $tfFiles | ForEach-Object { 
                Write-Host "  ✓ $($_.Name) ($($_.Length) bytes)" -ForegroundColor Green 
            }
        }
    } else {
        Write-Host "ERROR: exported_resources directory not created!" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "=== Terraform Debug Log (last 150 lines) ===" -ForegroundColor Cyan
    if (Test-Path "terraform-debug.log") {
        Get-Content terraform-debug.log -Tail 150
    } else {
        Write-Host "No debug log found!" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "=== Provider Version ===" -ForegroundColor Cyan
    terraform version
    
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Cyan
Write-Host "Review the debug log for detailed information about the export process."
