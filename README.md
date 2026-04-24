# Genesys Cloud CI/CD Pipeline: DEV to TEST Flow Deployment

This repository contains a CI/CD pipeline that exports **HarshTestFlow** (an inbound call flow) and its dependencies from a DEV environment (us-west-2) and deploys them to a TEST environment (us-east-1) using GitHub Actions, Terraform CX-as-Code, and Terraform Cloud.

## 🚀 Quick Start

### Prerequisites
1. **Genesys Cloud Organizations**
   - DEV org (us-west-2 / usw2.pure.cloud)
   - TEST org (us-east-1 / mypurecloud.com)

2. **OAuth Clients**
   - DEV OAuth client with `architect` permissions (for export)
   - TEST OAuth client with `architect` permissions (for deploy, plus queues and data actions)

3. **Terraform Cloud**
   - Organization: `TestCognizant`
   - Workspace: `CI_CD_TEST` (prefix-based: `CI_CD` prefix + `_TEST` suffix)

4. **GitHub Repository Secrets**
   - `GENESYSCLOUD_OAUTHCLIENT_ID_DEV`
   - `GENESYSCLOUD_OAUTHCLIENT_SECRET_DEV`
   - `GENESYSCLOUD_OAUTHCLIENT_ID_TEST`
   - `GENESYSCLOUD_OAUTHCLIENT_SECRET_TEST`
   - `TF_API_TOKEN`

### Running the Pipeline

**Automatic:** Push to `main` branch triggers the pipeline.

**Manual:**
1. Go to the Actions tab
2. Select "Deploy Flow from DEV to TEST"
3. Click "Run workflow"

## 📋 Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────┐
│              1. Export from DEV (us-west-2 / usw2)              │
│  • Validate DEV OAuth credentials & Architect API access        │
│  • List flows in DEV (verification via list-flows.py)           │
│  • Export HarshTestFlow + dependencies via Terraform             │
│  • Post-export cleanup of genesyscloud.tf:                      │
│      - Remove terraform block (avoid conflict with main.tf)     │
│      - Remove computed file_content_hash attributes             │
│      - Replace Home division resource with data source          │
│      - Remove genesyscloud_integration resource block           │
│      - Fix integration_id to use existing TEST integration      │
│      - Update category to "Genesys Cloud Data Actions"          │
│  • Post-export cleanup of flow YAML files:                      │
│      - Replace 'voice: Jill' with 'defaultVoice: true'         │
│  • Commit exported files to GitHub (with [skip ci])             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              2. Deploy to TEST (us-east-1 / use1)               │
│  • Validate TEST OAuth credentials (format + direct API test)   │
│  • Confirm region is us-east-1 (safety check)                   │
│  • Verify Terraform Cloud workspace configuration               │
│  • Deploy via Terraform Cloud (workspace: CI_CD_TEST)           │
│  • Generate deployment summary (or troubleshooting checklist)   │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Repository Structure

```
CI_CD2/
├── .github/
│   ├── workflows/
│   │   └── deploy-flow.yaml                  # Main CI/CD pipeline
│   └── actions/
│       ├── genesys-cloud-dev-tools/          # Python SDK & Archy setup
│       ├── genesys-cloud-export-flows/       # Export from DEV (Terraform)
│       ├── genesys-cloud-apply-terraform/    # Deploy to TEST (Terraform Cloud)
│       └── genesys-cloud-publish-archy-flow/ # Publish flows via Archy (optional)
│
└── blueprint/
    ├── index.md                              # Blueprint overview
    ├── genesys-cloud-architect-flows/
    │   ├── testFlowHarsh.yaml                # Original HarshTestFlow definition
    │   ├── myTestFlow.yaml                   # Test flow
    │   └── EmailComprehendFlow.yaml          # Email routing flow (AWS Comprehend)
    │
    ├── genesys-cloud-cx-as-code/
    │   ├── deploy/                           # Deployment directory (Terraform Cloud)
    │   │   ├── main.tf                       # Backend config (remote, prefix CI_CD)
    │   │   ├── genesyscloud.tf               # EXPORTED resources (auto-generated)
    │   │   ├── deploy-to-test.ps1            # Local deploy script (PowerShell)
    │   │   └── architect_flows/              # EXPORTED flow YAMLs (auto-generated)
    │   │       └── HarshTestFlow-INBOUNDCALL-*.yaml
    │   │
    │   ├── export/                           # Export configuration
    │   │   ├── main.tf                       # Export config (DEV, local backend)
    │   │   ├── export-from-dev.ps1           # Local export script (PowerShell)
    │   │   ├── list-flows.py                 # List DEV flows utility
    │   │   └── test-export-local.ps1         # Debug export script
    │   │
    │   └── test/                             # TEST environment modules
    │       ├── main.tf                       # Module orchestration
    │       └── modules/
    │           ├── queues/                   # Dynamic queue creation
    │           │   ├── main.tf
    │           │   └── variables.tf
    │           └── data_actions/             # Data action definitions
    │               └── main.tf
    │
    └── scripts/
        ├── create_email_domain.py            # Email domain/route setup
        └── platform_tests.py                 # Post-deployment validation tests
```

## 🔑 Key Files

### `deploy/main.tf` - Backend Configuration
**Location:** `blueprint/genesys-cloud-cx-as-code/deploy/main.tf`

Contains the remote backend and provider configuration. Uses a **workspace prefix** (`CI_CD`) so the local workspace name `_TEST` maps to the Terraform Cloud workspace `CI_CD_TEST`:
```terraform
terraform {
  backend "remote" {
    organization = "TestCognizant"
    workspaces {
      prefix = "CI_CD"
    }
  }
}

provider "genesyscloud" {
  sdk_debug = true
}
```

### `deploy/genesyscloud.tf` - Exported Resources
**Location:** `blueprint/genesys-cloud-cx-as-code/deploy/genesyscloud.tf`

**⚠️ Auto-generated file - Do not manually edit!**

This file is created and cleaned up by the export pipeline. After cleanup it contains:
- `data "genesyscloud_auth_division_home"` - Reference to existing Home division
- `genesyscloud_flow` - HarshTestFlow (INBOUNDCALL type)
- `genesyscloud_integration_action` - waitTime data action (estimated wait time API)
- `genesyscloud_routing_queue` - PremiumSupport, ROTH, 401K queues

### `export/main.tf` - Export Configuration
**Location:** `blueprint/genesys-cloud-cx-as-code/export/main.tf`

Configures what to export from DEV:
```terraform
resource "genesyscloud_tf_export" "harsh_test_flow_export" {
  directory = "../deploy"
  include_filter_resources = [
    "genesyscloud_flow::HarshTestFlow"
  ]
  # Excludes transitive dependencies: users, groups, skills, languages
}
```

### HarshTestFlow - The Flow
The exported inbound call flow provides:
- Welcome greeting: "Hello, Welcome to Cognizant Technology"
- Menu: Press 1 for HR, 2 for IT Support, 3 for Agent
- Data action calls to query estimated wait times via the `waitTime` integration action
- Queue transfers with priority and wait-time playback
- Fallback to PremiumSupport queue
- Loop back on `*` input

## 🔄 How It Works

### Export Process (Job 1)
```bash
# 1. Validate DEV credentials via OAuth API
# 2. List flows to confirm HarshTestFlow exists
# 3. In export/ directory:
terraform init
terraform apply -auto-approve   # Exports to ../deploy/

# 4. Post-export cleanup (sed operations on genesyscloud.tf):
#    - Remove terraform {} block
#    - Remove file_content_hash attributes
#    - Replace Home division resource → data source
#    - Remove genesyscloud_integration resource
#    - Set integration_id to existing TEST integration
#    - Update category to "Genesys Cloud Data Actions"

# 5. YAML cleanup:
#    - Replace 'voice: Jill' → 'defaultVoice: true'

# 6. Commit & force-push to main with [skip ci]
```

### Deploy Process (Job 2)
```bash
# 1. Checkout latest commit (with exported files)
# 2. Validate TEST credentials (format check + direct OAuth test)
# 3. Confirm target region is us-east-1 (safety check)
# 4. In deploy/ directory:
terraform init     # Connects to Terraform Cloud workspace CI_CD_TEST
terraform apply --auto-approve

# Terraform reads:
#  - main.tf (backend config)
#  - genesyscloud.tf (resources to create/update)
#  - architect_flows/*.yaml (flow definitions)
```

## 📊 Pipeline Jobs Detail

### Job 1: `export-flow-from-dev`

**Environment:** DEV (us-west-2 / usw2.pure.cloud)

| Step | Description |
|------|-------------|
| Checkout | Clone repository |
| Dev tools setup | Install Python SDK (`PureCloudPlatformClientV2`) and Archy via `genesys-cloud-dev-tools` |
| Setup Terraform | Install Terraform CLI with Cloud token |
| Credential validation | Test OAuth against DEV API, verify UUID format, check Architect API access |
| List flows | Run `list-flows.py` to confirm HarshTestFlow exists in DEV |
| Export | Run via `genesys-cloud-export-flows` action (terraform init + apply with DEBUG logging) |
| Clean genesyscloud.tf | Remove terraform block, computed attributes, Home division resource; fix integration and category references |
| Clean YAML files | Replace TTS voice `Jill` with `defaultVoice: true` |
| Verify | Confirm exported files exist and list resource counts |
| Commit & push | Git add/commit/push with `[skip ci]` tag and `--force` |

**Output Files:**
- `blueprint/genesys-cloud-cx-as-code/deploy/genesyscloud.tf`
- `blueprint/genesys-cloud-cx-as-code/deploy/architect_flows/*.yaml`
- `blueprint/genesys-cloud-cx-as-code/deploy/terraform.tfvars` (if generated)

### Job 2: `deploy-to-test`

**Environment:** TEST (us-east-1 / mypurecloud.com)
**Depends on:** `export-flow-from-dev`
**TF_WORKSPACE:** `_TEST` (resolves to `CI_CD_TEST` with prefix)

| Step | Description |
|------|-------------|
| Checkout | Clone latest `main` ref (with exported resources) |
| Dev tools setup | Install Python SDK and Archy via `genesys-cloud-dev-tools` |
| Setup Terraform | Install Terraform CLI with Cloud token |
| Verify files | Confirm main.tf, genesyscloud.tf, and YAML files exist |
| Validate credentials | Check secret format (UUID length, whitespace), test OAuth directly against TEST API |
| Check TF Cloud vars | Warn if Terraform Cloud workspace variables may override GitHub secrets |
| Confirm region | Assert `GENESYSCLOUD_REGION=us-east-1` (prevents accidental DEV deployment) |
| Deploy | Run via `genesys-cloud-apply-terraform` action (terraform init + apply) |
| Summary | On success: deployment details; on failure: troubleshooting checklist |

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
Get-ChildItem ../deploy/genesyscloud.tf
Get-ChildItem ../deploy/architect_flows/
```

Or use the provided script:
```powershell
cd blueprint/genesys-cloud-cx-as-code/export
.\export-from-dev.ps1
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
cd blueprint/genesys-cloud-cx-as-code/deploy

# Deploy
terraform init
terraform plan
terraform apply
```

Or use the provided script:
```powershell
cd blueprint/genesys-cloud-cx-as-code/deploy
.\deploy-to-test.ps1
```

### Debug Export Locally

```powershell
cd blueprint/genesys-cloud-cx-as-code/export
.\test-export-local.ps1   # Exports to local directory with TF_LOG=DEBUG
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
- Check latest commit message (`Auto-export HarshTestFlow from DEV (usw2) [skip ci]`)
- Verify `genesyscloud.tf` was updated
- Verify `architect_flows/` contains YAML files

### 4. Platform Tests
```bash
python blueprint/scripts/platform_tests.py
# Validates: IRA, 401K, 529, GeneralSupport queues and LookupQueueName data action
```

## 🐛 Troubleshooting

### Export Issues

**Flow not found in DEV:**
```bash
cd blueprint/genesys-cloud-cx-as-code/export
python list-flows.py
```

**Export fails:**
- Check `terraform-debug.log` in export directory (created with `TF_LOG=DEBUG`)
- Verify DEV OAuth credentials have correct permissions
- Ensure HarshTestFlow exists and is published in DEV

**genesyscloud.tf not created:**
- Verify `export/main.tf` has `directory = "../deploy"`
- Check export directory in GitHub Actions logs
- Ensure export completed without errors

### Deployment Issues

**OAuth authentication fails (HTTP 400):**
- Verify Client ID is UUID format (36 characters)
- Check for leading/trailing whitespace in GitHub secrets
- Confirm OAuth client exists and is enabled in TEST org (us-east-1)
- Regenerate the client secret if needed

**Terraform Cloud workspace variables override secrets:**
- Check Terraform Cloud > TestCognizant > CI_CD_TEST > Settings > Variables
- If `GENESYSCLOUD_*` variables are set there, they override GitHub secrets
- Either update TF Cloud variables or remove them to use GitHub secrets

**Can't connect to Terraform Cloud:**
- Verify `TF_API_TOKEN` secret is set correctly
- Run `terraform login` locally to test
- Check workspace name resolves correctly with prefix `CI_CD` + suffix `_TEST`

**Deployment fails:**
- Check the DEBUG steps in the GitHub Actions run for detailed diagnostics
- Verify TEST OAuth credentials have `architect` permission
- Review Terraform Cloud run logs at app.terraform.io

**Files not found:**
- Ensure export job completed successfully
- Verify commit was pushed to GitHub
- Check deploy job checked out latest `main` ref

## 🏗️ Architecture Details

### File Structure During Pipeline

```
Export Phase (DEV → GitHub):
  blueprint/genesys-cloud-cx-as-code/export/main.tf
    ↓ terraform export (directory="../deploy")
  blueprint/genesys-cloud-cx-as-code/deploy/
    ├── genesyscloud.tf ← created (then cleaned up via sed)
    ├── architect_flows/
    │   └── HarshTestFlow-INBOUNDCALL-*.yaml ← created (then YAML cleaned)
    └── terraform.tfvars (optional)
    ↓ git commit & push to main

Deploy Phase (GitHub → TEST):
  blueprint/genesys-cloud-cx-as-code/deploy/
    ├── main.tf (backend config: remote, prefix CI_CD)
    ├── genesyscloud.tf (cleaned exported resources)
    └── architect_flows/*.yaml (cleaned flow definitions)
    ↓ genesys-cloud-apply-terraform action
  Terraform Cloud Workspace: CI_CD_TEST
    ↓ terraform apply
  Genesys Cloud TEST org (us-east-1)
```

### Post-Export Cleanup Details

The raw Terraform export produces a `genesyscloud.tf` that cannot be directly applied to TEST. The pipeline performs these cleanup steps:

| Cleanup | Reason |
|---------|--------|
| Remove `terraform {}` block | Avoid conflict with `deploy/main.tf` which has its own backend |
| Remove `file_content_hash` | Computed attribute that cannot be set manually |
| Replace Home division resource → data source | Home division already exists in TEST; avoid recreation |
| Fix `division_id` references | Point to `data.genesyscloud_auth_division_home.Home.id` |
| Remove `genesyscloud_integration` resource | Use existing "Genesys Cloud Data Actions" integration in TEST |
| Fix `integration_id` | Hardcode to TEST integration ID |
| Update `category` | Change from `PureCloud_Data_Actions` to `Genesys Cloud Data Actions` |
| Replace `voice: Jill` → `defaultVoice: true` | Use default TTS voice instead of a specific voice |

### Custom GitHub Actions

| Action | Purpose |
|--------|---------|
| `genesys-cloud-dev-tools` | Installs `PureCloudPlatformClientV2` Python SDK and downloads Archy CLI |
| `genesys-cloud-export-flows` | Runs Terraform export locally with DEBUG logging, validates OAuth first |
| `genesys-cloud-apply-terraform` | Changes to `deploy/` directory, runs `terraform init` and `terraform apply --auto-approve` |
| `genesys-cloud-publish-archy-flow` | Publishes flows directly via Archy CLI (optional, not used in main pipeline) |

### Resources Managed

| Resource Type | Name | Description |
|---------------|------|-------------|
| `genesyscloud_flow` | HarshTestFlow | Inbound call flow with HR/IT/Agent menu |
| `genesyscloud_integration_action` | waitTime | Queries estimated wait time API |
| `genesyscloud_routing_queue` | PremiumSupport | Fallback support queue |
| `genesyscloud_routing_queue` | ROTH | ROTH queue |
| `genesyscloud_routing_queue` | 401K | 401K queue |

## 🔐 Security & OAuth Permissions

### OAuth Client Permissions

**DEV Client (Export):**
- `architect` or `architect:readonly`

**TEST Client (Deploy):**
- `architect` (create/update flows)
- Additional scopes for dependencies (queues, data actions, etc.)

### Terraform Cloud Configuration

**Workspace Variables (Set in Terraform Cloud > CI_CD_TEST > Variables):**

> **Warning:** Terraform Cloud workspace variables **override** GitHub secrets' environment variables.

```
GENESYSCLOUD_OAUTHCLIENT_ID     (sensitive, env var)
GENESYSCLOUD_OAUTHCLIENT_SECRET (sensitive, env var)
GENESYSCLOUD_REGION              = "us-east-1"
GENESYSCLOUD_API_REGION          = "https://api.mypurecloud.com"
```

### Secret Management

All sensitive credentials are stored as GitHub Secrets:
- Never commit credentials to the repository
- Use Terraform Cloud workspace variables for TEST credentials
- Rotate OAuth client secrets regularly

## 📝 Important Notes

1. **`genesyscloud.tf` is auto-generated** - Don't edit it manually. It's regenerated and cleaned on every export run.

2. **`main.tf` only has backend config** - Located in `deploy/`, all resource definitions come from the exported `genesyscloud.tf`.

3. **Workspace uses prefix-based naming** - `main.tf` uses `prefix = "CI_CD"` so `TF_WORKSPACE=_TEST` maps to `CI_CD_TEST` in Terraform Cloud.

4. **Post-export cleanup is critical** - Raw exports from DEV cannot be applied to TEST without the sed-based cleanup steps (Home division, integration references, etc.).

5. **Flow name is case-sensitive** - "HarshTestFlow" must match exactly in your DEV org.

6. **`[skip ci]` on export commits** - The export commit uses `[skip ci]` to avoid triggering another pipeline run.

7. **Force push on export** - The export job uses `git push --force` to ensure the latest export is always on `main`.

## 📚 Additional Resources

- [blueprint/index.md](blueprint/index.md) - Blueprint overview and background
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Cloud Documentation](https://www.terraform.io/cloud-docs)
- [Genesys Cloud CX as Code](https://registry.terraform.io/providers/MyPureCloud/genesyscloud/latest/docs)

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

