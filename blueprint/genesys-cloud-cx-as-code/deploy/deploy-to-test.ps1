#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy HarshTestFlow to TEST environment (use1) via Terraform Cloud

.DESCRIPTION
    This script:
    1. Sets up TEST environment credentials (us-east-1)
    2. Connects to Terraform Cloud remote backend
    3. Deploys HarshTestFlow from GitHub to TEST environment
#>

Write-Host "=== Deploy HarshTestFlow to TEST (use1) via Terraform Cloud ===" -ForegroundColor Cyan
Write-Host ""

# Check if OAuth credentials are set for TEST environment
if (-not $env:GENESYSCLOUD_OAUTHCLIENT_ID -or -not $env:GENESYSCLOUD_OAUTHCLIENT_SECRET) {
    Write-Host "ERROR: TEST environment credentials not set!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Set TEST environment variables:" -ForegroundColor Yellow
    Write-Host "  `$env:GENESYSCLOUD_OAUTHCLIENT_ID = 'your-test-client-id'" -ForegroundColor Yellow
    Write-Host "  `$env:GENESYSCLOUD_OAUTHCLIENT_SECRET = 'your-test-client-secret'" -ForegroundColor Yellow
    Write-Host "  `$env:GENESYSCLOUD_REGION = 'us-east-1'" -ForegroundColor Yellow
    Write-Host "  `$env:GENESYSCLOUD_API_REGION = 'https://api.mypurecloud.com'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Also set Terraform Cloud token:" -ForegroundColor Yellow
    Write-Host "  `$env:TF_TOKEN_app_terraform_io = 'your-terraform-cloud-token'" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Verify region is set correctly
if ($env:GENESYSCLOUD_REGION -ne "us-east-1") {
    Write-Host "WARNING: GENESYSCLOUD_REGION should be 'us-east-1' for TEST environment" -ForegroundColor Yellow
    Write-Host "Current value: $($env:GENESYSCLOUD_REGION)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Do you want to continue? (Y/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Host "Deployment cancelled." -ForegroundColor Red
        exit 1
    }
}

# Check Terraform Cloud token
if (-not $env:TF_TOKEN_app_terraform_io) {
    Write-Host "WARNING: Terraform Cloud token not set!" -ForegroundColor Yellow
    Write-Host "You may need to run 'terraform login' first." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "✓ TEST Environment Configuration:" -ForegroundColor Green
Write-Host "  OAuth Client ID: $($env:GENESYSCLOUD_OAUTHCLIENT_ID)" -ForegroundColor Green
Write-Host "  API Region: $($env:GENESYSCLOUD_API_REGION)" -ForegroundColor Green
Write-Host "  Region: $($env:GENESYSCLOUD_REGION)" -ForegroundColor Green
Write-Host "  Terraform Workspace: CI_CD_TEST" -ForegroundColor Green
Write-Host ""

# Final verification: Ensure we're deploying to TEST not DEV
Write-Host "=== Confirming TEST Environment (NOT DEV) ===" -ForegroundColor Cyan
if ($env:GENESYSCLOUD_REGION -eq "us-east-1" -and $env:GENESYSCLOUD_API_REGION -eq "https://api.mypurecloud.com") {
    Write-Host "✓ CONFIRMED: Deploying to TEST environment (us-east-1)" -ForegroundColor Green
    Write-Host "✓ NOT deploying to DEV environment (us-west-2)" -ForegroundColor Green
} else {
    Write-Host "✗ ERROR: Wrong region configured!" -ForegroundColor Red
    Write-Host "  Expected: us-east-1 (TEST)" -ForegroundColor Red
    Write-Host "  Current: $($env:GENESYSCLOUD_REGION)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Navigate to main deployment directory
$deployDir = Join-Path $PSScriptRoot ".."
Push-Location $deployDir

try {
    # Step 1: Initialize Terraform with remote backend
    Write-Host "Step 1: Initializing Terraform with remote backend..." -ForegroundColor Cyan
    terraform init -reconfigure
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Terraform init failed!" -ForegroundColor Red
        Write-Host ""
        Write-Host "If you need to login to Terraform Cloud, run:" -ForegroundColor Yellow
        Write-Host "  terraform login" -ForegroundColor Yellow
        exit 1
    }
    
    # Step 2: Select workspace
    Write-Host ""
    Write-Host "Step 2: Selecting workspace CI_CD_TEST..." -ForegroundColor Cyan
    terraform workspace select CI_CD_TEST
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Workspace doesn't exist, creating it..." -ForegroundColor Yellow
        terraform workspace new CI_CD_TEST
    }
    
    # Step 2.5: Safety Check - Remove Home division from state if it exists
    Write-Host ""
    Write-Host "Step 2.5: Safety Check - Removing Home Division from Terraform Management..." -ForegroundColor Cyan
    $stateList = terraform state list 2>&1
    if ($stateList -match "genesyscloud_auth_division.Home") {
        Write-Host "  ⚠  Found Home division in Terraform state" -ForegroundColor Yellow
        Write-Host "  ⚠  Removing from state (will NOT delete from TEST org)" -ForegroundColor Yellow
        terraform state rm genesyscloud_auth_division.Home 2>&1 | Out-Null
        Write-Host "  ✓ Home division removed from Terraform management" -ForegroundColor Green
        Write-Host "  ✓ Division remains intact in TEST org" -ForegroundColor Green
    } else {
        Write-Host "  ✓ Home division not in state, no action needed" -ForegroundColor Green
    }
    
    # Step 3: Validate configuration
    Write-Host ""
    Write-Host "Step 3: Validating Terraform configuration..." -ForegroundColor Cyan
    terraform validate
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Terraform validation failed!" -ForegroundColor Red
        exit 1
    }
    
    # Step 4: Plan deployment
    Write-Host ""
    Write-Host "Step 4: Planning deployment..." -ForegroundColor Cyan
    terraform plan -out=tfplan
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Terraform plan failed!" -ForegroundColor Red
        exit 1
    }
    
    # Step 5: Review and apply
    Write-Host ""
    Write-Host "=== Deployment Plan Ready ===" -ForegroundColor Yellow
    Write-Host "Review the plan above. Do you want to apply? (Y/N)" -ForegroundColor Yellow
    $applyResponse = Read-Host
    
    if ($applyResponse -eq "Y" -or $applyResponse -eq "y") {
        Write-Host ""
        Write-Host "Step 5: Applying deployment to TEST environment..." -ForegroundColor Cyan
        terraform apply tfplan
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "=== SUCCESS ===" -ForegroundColor Green
            Write-Host "✓ HarshTestFlow deployed to TEST environment (use1)" -ForegroundColor Green
            Write-Host "✓ State stored in Terraform Cloud remote backend" -ForegroundColor Green
            Write-Host ""
            Write-Host "Verification:" -ForegroundColor Cyan
            Write-Host "  1. Check Terraform Cloud workspace: CI_CD_TEST" -ForegroundColor White
            Write-Host "  2. Login to Genesys Cloud TEST org (use1)" -ForegroundColor White
            Write-Host "  3. Navigate to Architect > Flows" -ForegroundColor White
            Write-Host "  4. Verify HarshTestFlow exists and is configured correctly" -ForegroundColor White
        } else {
            Write-Host "ERROR: Terraform apply failed!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        Write-Host "Plan file saved as 'tfplan' for later use." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Cyan
