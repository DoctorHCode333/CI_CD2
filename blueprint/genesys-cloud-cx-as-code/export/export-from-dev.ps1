#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Export HarshTestFlow from DEV environment (usw2) to GitHub

.DESCRIPTION
    This script:
    1. Sets up DEV environment credentials (us-west-2)
    2. Exports HarshTestFlow using Terraform
    3. Copies exported YAML to genesys-cloud-architect-flows directory
    4. Commits and pushes changes to GitHub
#>

Write-Host "=== Export HarshTestFlow from DEV (usw2) to GitHub ===" -ForegroundColor Cyan
Write-Host ""

# Check if OAuth credentials are set
if (-not $env:GENESYSCLOUD_OAUTHCLIENT_ID -or -not $env:GENESYSCLOUD_OAUTHCLIENT_SECRET) {
    Write-Host "ERROR: DEV environment credentials not set!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Set DEV environment variables:" -ForegroundColor Yellow
    Write-Host "  `$env:GENESYSCLOUD_OAUTHCLIENT_ID = 'your-dev-client-id'" -ForegroundColor Yellow
    Write-Host "  `$env:GENESYSCLOUD_OAUTHCLIENT_SECRET = 'your-dev-client-secret'" -ForegroundColor Yellow
    Write-Host "  `$env:GENESYSCLOUD_REGION = 'us-west-2'" -ForegroundColor Yellow
    Write-Host "  `$env:GENESYSCLOUD_API_REGION = 'https://api.usw2.pure.cloud'" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Verify region is set correctly
if ($env:GENESYSCLOUD_REGION -ne "us-west-2") {
    Write-Host "WARNING: GENESYSCLOUD_REGION should be 'us-west-2' for DEV environment" -ForegroundColor Yellow
    Write-Host "Current value: $($env:GENESYSCLOUD_REGION)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Do you want to continue? (Y/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Host "Export cancelled." -ForegroundColor Red
        exit 1
    }
}

Write-Host "✓ DEV Environment Configuration:" -ForegroundColor Green
Write-Host "  OAuth Client ID: $($env:GENESYSCLOUD_OAUTHCLIENT_ID)" -ForegroundColor Green
Write-Host "  API Region: $($env:GENESYSCLOUD_API_REGION)" -ForegroundColor Green
Write-Host "  Region: $($env:GENESYSCLOUD_REGION)" -ForegroundColor Green
Write-Host ""

# Navigate to export directory
$exportDir = $PSScriptRoot
Push-Location $exportDir

try {
    # Step 1: List flows to verify HarshTestFlow exists
    Write-Host "Step 1: Verifying HarshTestFlow exists in DEV..." -ForegroundColor Cyan
    python list-flows.py
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to list flows!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Press Enter to continue with export..." -ForegroundColor Yellow
    Read-Host
    
    # Step 2: Clean previous export
    if (Test-Path "exported_resources") {
        Write-Host "Step 2: Cleaning previous export..." -ForegroundColor Cyan
        Remove-Item -Recurse -Force exported_resources
    }
    
    # Step 3: Initialize and run Terraform export
    Write-Host "Step 3: Initializing Terraform..." -ForegroundColor Cyan
    terraform init
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Terraform init failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Step 4: Running Terraform export..." -ForegroundColor Cyan
    terraform apply -auto-approve
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Terraform export failed!" -ForegroundColor Red
        exit 1
    }
    
    # Step 5: Copy exported YAML to architect flows directory
    Write-Host ""
    Write-Host "Step 5: Copying exported YAML to architect-flows directory..." -ForegroundColor Cyan
    
    $yamlFiles = Get-ChildItem -Recurse exported_resources -Include *.yaml, *.yml -ErrorAction SilentlyContinue
    
    if ($yamlFiles) {
        $targetDir = Join-Path $exportDir "..\..\..\genesys-cloud-architect-flows"
        
        foreach ($file in $yamlFiles) {
            $targetPath = Join-Path $targetDir $file.Name
            Copy-Item $file.FullName $targetPath -Force
            Write-Host "  ✓ Copied $($file.Name) to architect-flows/" -ForegroundColor Green
        }
    } else {
        Write-Host "  ✗ No YAML files found in export!" -ForegroundColor Red
        exit 1
    }
    
    # Step 6: Show what was exported
    Write-Host ""
    Write-Host "Step 6: Export Summary:" -ForegroundColor Cyan
    Write-Host "Exported files:" -ForegroundColor Green
    Get-ChildItem -Recurse exported_resources | Select-Object FullName | Format-Table -AutoSize
    
    # Step 7: Git operations
    Write-Host ""
    Write-Host "Step 7: Committing to GitHub..." -ForegroundColor Cyan
    
    Pop-Location
    Push-Location (Join-Path $exportDir "..\..\..\..")
    
    git add .
    git commit -m "Export HarshTestFlow from DEV (usw2) - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
    Write-Host ""
    Write-Host "Ready to push to GitHub. Continue? (Y/N)" -ForegroundColor Yellow
    $pushResponse = Read-Host
    
    if ($pushResponse -eq "Y" -or $pushResponse -eq "y") {
        git push origin main
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "=== SUCCESS ===" -ForegroundColor Green
            Write-Host "✓ HarshTestFlow exported from DEV (usw2)" -ForegroundColor Green
            Write-Host "✓ Changes pushed to GitHub" -ForegroundColor Green
            Write-Host "✓ Ready for TEST environment deployment" -ForegroundColor Green
            Write-Host ""
            Write-Host "Next step: Deploy to TEST environment (use1) via Terraform Cloud" -ForegroundColor Cyan
        } else {
            Write-Host "ERROR: Git push failed!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Push cancelled. Changes are committed locally." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
