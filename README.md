# Genesys Cloud CI/CD Pipeline: DEV to TEST Flow Deployment

This repository contains a CI/CD pipeline that exports **HarshTestFlow** from a DEV environment (us-west-2) and deploys it to a TEST environment (us-east-1) using GitHub Actions and Terraform Cloud.

## 🚀 Quick Start

### Prerequisites
1. **Genesys Cloud Organizations**
   - DEV org (us-west-2 / usw2.pure.cloud)
   - TEST org (us-east-1 / mypurecloud.com)

2. **OAuth Clients** 
   - DEV OAuth client with `architect` permissions
   - TEST OAuth client with `architect` permissions

3. **Terraform Cloud**
   - Organization: `TestCognizant`
   - Workspace: `CI_CD_TEST`

4. **GitHub Repository Secrets**
   - `GENESYSCLOUD_OAUTHCLIENT_ID_DEV`
   - `GENESYSCLOUD_OAUTHCLIENT_SECRET_DEV`
   - `GENESYSCLOUD_OAUTHCLIENT_ID_TEST`
   - `GENESYSCLOUD_OAUTHCLIENT_SECRET_TEST`
   - `TF_API_TOKEN`

### Running the Pipeline

**Automatic:** Push to `main` branch triggers the pipeline

**Manual:** 
1. Go to Actions tab
2. Select "Deploy Flow from DEV to TEST"
3. Click "Run workflow"

## 📋 Pipeline Overview

```
┌─────────────────────────────────────────────────────────────┐
│                 1. Export from DEV (usw2)                   │
│  • Connect to DEV environment                                │
│  • Export HarshTestFlow + dependencies                       │
│  • Create genesyscloud.tf (all resources)                    │
│  • Create architect_flows/*.yaml (flow definitions)          │
│  • Commit to GitHub                                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                 2. Deploy to TEST (use1)                     │
│  • Checkout latest code                                      │
│  • Use main.tf (backend) + genesyscloud.tf (resources)      │
│  • Deploy via Terraform Cloud                                │
│  • Workspace: CI_CD_TEST                                     │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Repository Structure

```
CI_CD2/
├── .github/
│   ├── workflows/
│   │   └── deploy-flow.yaml              # Main CI/CD pipeline
│   └── actions/
│       ├── genesys-cloud-dev-tools/      # Python SDK & Archy setup
│       ├── genesys-cloud-export-queues/  # Export from DEV
│       └── genesys-cloud-apply-terraform/ # Deploy to TEST
│
└── blueprint/
    ├── genesys-cloud-architect-flows/
    │   └── testFlowHarsh.yaml            # Original flow (HarshTestFlow)
    │
    └── genesys-cloud-cx-as-code/
        ├── main.tf                       # Backend config (TEST)
        ├── genesyscloud.tf              # EXPORTED resources (auto-generated)
        ├── architect_flows/              # EXPORTED flow YAMLs (auto-generated)
        │   └── HarshTestFlow.yaml
        │
        └── export/
            ├── main.tf                   # Export configuration (DEV)
            ├── list-flows.py            # List DEV flows utility
            └── test-export-local.ps1    # Local export test script
```

## 🔑 Key Files

### `main.tf` - Backend Configuration Only
**Location:** `blueprint/genesys-cloud-cx-as-code/main.tf`

Contains **only** remote backend and provider configuration:
```terraform
terraform {
  backend "remote" {
    organization = "TestCognizant"
    workspaces {
      name = "CI_CD_TEST"
    }
  }
}

provider "genesyscloud" {
  sdk_debug = true
}
```

### `genesyscloud.tf` - Exported Resources
**Location:** `blueprint/genesys-cloud-cx-as-code/genesyscloud.tf`

**⚠️ Auto-generated file - Do not manually edit!**

This file is created by the export process and contains:
- Flow resources (`genesyscloud_flow`)
- Dependencies (queues, data actions, etc.)
- All related configurations

### `export/main.tf` - Export Configuration
**Location:** `blueprint/genesys-cloud-cx-as-code/export/main.tf`

Configures what to export from DEV:
```terraform
resource "genesyscloud_tf_export" "harsh_test_flow_export" {
  directory = "../"  # Exports to parent directory
  include_filter_resources = [
    "genesyscloud_flow::HarshTestFlow"
  ]
}
```

## 🔄 How It Works

### Export Process
When the export runs:
```bash
# In export/ directory
terraform init
terraform apply -auto-approve

# Creates in parent directory (blueprint/genesys-cloud-cx-as-code/):
# - genesyscloud.tf (all flows and dependencies)
# - architect_flows/HarshTestFlow.yaml
# - terraform.tfvars (optional)
```

### Deploy Process
When the deploy runs:
```bash
# In blueprint/genesys-cloud-cx-as-code/ directory
terraform init    # Connects to Terraform Cloud workspace CI_CD_TEST
terraform apply --auto-approve

# Terraform reads:
# - main.tf (backend config)
# - genesyscloud.tf (resources to create/update)
# - architect_flows/*.yaml (flow definitions)
```

## 📊 Pipeline Jobs

### Job 1: export-flow-from-dev

**Environment:** DEV (us-west-2)

**Steps:**
1. Checkout code
2. Setup Python SDK and Archy (via `genesys-cloud-dev-tools` action)
3. Setup Terraform
4. List flows in DEV (verification)
5. Run Terraform export (via `genesys-cloud-export-queues` action)
   - Connects to DEV org
   - Exports HarshTestFlow with all dependencies
   - Creates `genesyscloud.tf` in `blueprint/genesys-cloud-cx-as-code/`
   - Creates YAML files in `architect_flows/`
6. Verify exported files
7. Commit and push to GitHub

**Output Files:**
- `blueprint/genesys-cloud-cx-as-code/genesyscloud.tf`
- `blueprint/genesys-cloud-cx-as-code/architect_flows/*.yaml`
- `blueprint/genesys-cloud-cx-as-code/terraform.tfvars` (if exists)

### Job 2: deploy-to-test

**Environment:** TEST (us-east-1)

**Steps:**
1. Checkout latest code (includes exported files)
2. Setup tools (via `genesys-cloud-dev-tools` action)
3. Setup Terraform with Cloud token
4. Verify required files exist
5. Deploy using `genesys-cloud-apply-terraform` action
   - Initializes Terraform with remote backend
   - Connects to Terraform Cloud workspace `CI_CD_TEST`
   - Applies configuration to TEST org
6. Generate deployment summary

**Terraform Files Used:**
- `main.tf` - Backend and provider configuration
- `genesyscloud.tf` - Resources to create/update
- `architect_flows/*.yaml` - Flow definitions

## 🛠️ Local Testing

### Test Export from DEV

```powershell
# Set DEV credentials
$env:GENESYSCLOUD_OAUTHCLIENT_ID = "your-dev-client-id"
$env:GENESYSCLOUD_OAUTHCLIENT_SECRET = "your-dev-client-secret"
$env:GENESYSCLOUD_REGION = "us-west-2"
$env:GENESYSCLOUD_API_REGION = "https://api.usw2.pure.cloud"

# Navigate to export directory
cd blueprint/genesys-cloud-cx-as-code/export

# List available flows
python list-flows.py

# Run export
terraform init
terraform apply -auto-approve

# Verify results
ls -la ../genesyscloud.tf
ls -la ../architect_flows/
```

### Test Deployment to TEST

```powershell
# Set TEST credentials
$env:GENESYSCLOUD_OAUTHCLIENT_ID = "your-test-client-id"
$env:GENESYSCLOUD_OAUTHCLIENT_SECRET = "your-test-client-secret"
$env:GENESYSCLOUD_REGION = "us-east-1"
$env:GENESYSCLOUD_API_REGION = "https://api.mypurecloud.com"

# Login to Terraform Cloud
terraform login

# Navigate to deployment directory
cd blueprint/genesys-cloud-cx-as-code

# Deploy
terraform init
terraform plan
terraform apply
```

## ✅ Verification

After deployment completes:

### 1. Terraform Cloud
- Navigate to: https://app.terraform.io/app/TestCognizant/workspaces/CI_CD_TEST
- Check run status and logs
- Verify state file updated

### 2. Genesys Cloud TEST Org
- Login to TEST org (us-east-1)
- Navigate to: Admin > Architect > Flows
- Locate: HarshTestFlow
- Verify configuration matches DEV

### 3. GitHub Repository
- Check latest commit message
- Verify `genesyscloud.tf` was updated
- Verify `architect_flows/` contains YAML files

## 🐛 Troubleshooting

### Export Issues

**Flow not found in DEV:**
```bash
cd blueprint/genesys-cloud-cx-as-code/export
python list-flows.py
```

**Export fails:**
- Check `terraform-debug.log` in export directory
- Verify DEV OAuth credentials
- Ensure flow exists and is published in DEV

**genesyscloud.tf not created:**
- Verify `export/main.tf` has `directory = "../"`
- Check export directory in GitHub Actions logs
- Ensure export completed without errors

### Deployment Issues

**Can't connect to Terraform Cloud:**
- Verify `TF_API_TOKEN` secret is set correctly
- Run `terraform login` locally to test
- Check workspace name is exactly `CI_CD_TEST`

**Deployment fails:**
- Check TEST OAuth credentials in Terraform Cloud
- Verify credentials have `architect` permission
- Review Terraform Cloud run logs

**Files not found:**
- Ensure export job completed successfully
- Verify commit was pushed to GitHub
- Check deploy job checked out latest code

## 🏗️ Architecture Details

### File Structure During Pipeline

```
Export Phase (DEV → GitHub):
  blueprint/genesys-cloud-cx-as-code/export/main.tf
    ↓ (terraform export with directory="../")
  blueprint/genesys-cloud-cx-as-code/
    ├── genesyscloud.tf ✅ (created)
    ├── architect_flows/
    │   └── HarshTestFlow.yaml ✅ (created)
    └── terraform.tfvars (optional)
    ↓ (commit & push to GitHub)

Deploy Phase (GitHub → TEST):
  blueprint/genesys-cloud-cx-as-code/
    ├── main.tf (backend config only)
    ├── genesyscloud.tf (all resources)
    └── architect_flows/*.yaml
    ↓ (via genesys-cloud-apply-terraform action)
  Terraform Cloud Workspace: CI_CD_TEST
```

### GitHub Actions Used

1. **genesys-cloud-dev-tools** - Setup Python SDK & Archy
   - Installs PureCloudPlatformClientV2
   - Downloads and configures Archy
   
2. **genesys-cloud-export-queues** - Export from DEV
   - Runs Terraform export locally
   - Creates genesyscloud.tf and YAML files
   
3. **genesys-cloud-apply-terraform** - Deploy to TEST
   - Changes to blueprint/genesys-cloud-cx-as-code
   - Runs terraform init and apply
   - Uses Terraform Cloud remote backend

## 🔐 Security & OAuth Permissions

### OAuth Client Permissions

**DEV Client (Export):**
- `architect` or `architect:readonly`

**TEST Client (Deploy):**
- `architect` (create/update flows)
- Additional scopes for dependencies (queues, data actions, etc.)

### Terraform Cloud Configuration

**Workspace Variables (Set in Terraform Cloud):**
```
GENESYSCLOUD_OAUTHCLIENT_ID (sensitive)
GENESYSCLOUD_OAUTHCLIENT_SECRET (sensitive)
GENESYSCLOUD_REGION = "us-east-1"
GENESYSCLOUD_API_REGION = "https://api.mypurecloud.com"
```

### Secret Management

All sensitive credentials are stored as GitHub Secrets:
- Never commit credentials to the repository
- Use Terraform Cloud workspace variables for TEST credentials
- Rotate OAuth client secrets regularly

## 📝 Important Notes

1. **genesyscloud.tf is auto-generated** - Don't edit it manually! It's regenerated on each export.

2. **main.tf only has backend config** - All resource definitions come from genesyscloud.tf

3. **Exports go to parent directory** - The export creates files in `blueprint/genesys-cloud-cx-as-code/`, not in a subdirectory

4. **Workspace name is CI_CD_TEST** - Ensure this matches your Terraform Cloud workspace

5. **Flow name is case-sensitive** - Make sure "HarshTestFlow" matches exactly in your DEV org

## 🤝 Contributing

1. Create a feature branch from `main`
2. Make changes
3. Test locally before pushing
4. Create a pull request
5. Wait for CI/CD checks to pass
6. Merge to `main`

## 📚 Additional Resources

- **[blueprint/index.md](blueprint/index.md)** - Blueprint overview and background
- **[GitHub Actions Documentation](https://docs.github.com/en/actions)**
- **[Terraform Cloud Documentation](https://www.terraform.io/cloud-docs)**
- **[Genesys Cloud CX as Code](https://registry.terraform.io/providers/MyPureCloud/genesyscloud/latest/docs)**

## 📞 Support

For issues or questions:
1. Check GitHub Actions logs for pipeline errors
2. Review Terraform Cloud run logs for deployment issues
3. Use `list-flows.py` to verify flow exists in DEV
4. Verify OAuth client permissions in Genesys Cloud
5. Contact your Genesys Cloud administrator

## 📄 License

See [LICENSE](LICENSE) file for details.

---

**Last Updated:** February 2026  
**Pipeline Version:** 2.0  
**Terraform Cloud Organization:** TestCognizant  
**Workspace:** CI_CD_TEST  
**Flow:** HarshTestFlow

