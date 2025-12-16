# IAP Module - Deployment Guide

## 🎯 What Was Added

A complete **Identity-Aware Proxy (IAP)** module has been integrated into your Looply infrastructure with:

### Core Components
✅ **OAuth 2.0 Configuration** - Secure authentication  
✅ **IAP Client & Brand** - Google OAuth consent screen  
✅ **Backend Service Protection** - 3 services protected (Admin, User Management, Analytics)  
✅ **Access Control** - Role-based IAM bindings  
✅ **Service Account** - Dedicated IAP service account with proper roles  
✅ **Monitoring & Alerts** - Failed authentication alerts  
✅ **Logging** - Comprehensive audit trail to Cloud Storage  
✅ **Security** - Cloud KMS encryption for OAuth secrets  

---

## 📁 Files Created

### New Module
```
terraform/modules/iap/
  ├── main.tf              # 155 lines - IAP resources
  ├── variables.tf         # 110 lines - 40+ input variables
  ├── outputs.tf           # 50 lines - Configuration outputs
  └── README.md            # 500+ lines - Complete documentation
```

### Updated Root Configuration
```
terraform/
  ├── main.tf              # Added IAP module integration
  ├── variables.tf         # Added 14 IAP variables
  ├── outputs.tf           # Added IAP outputs section
  └── terraform.tfvars     # Added IAP configuration
```

### Updated Service Accounts Module
```
terraform/modules/service_accounts/
  ├── main.tf              # Added IAP service account (40 lines)
  └── outputs.tf           # Added IAP SA output
```

### Documentation
```
terraform/
  ├── IAP_IMPLEMENTATION.md # Implementation summary
  └── GAP_ANALYSIS.md      # Updated with IAP status
```

---

## 🔑 Key IAP Variables

Add these to your `terraform/terraform.tfvars`:

```hcl
# IAP Support Email
iap_support_email = "security@looply.io"

# Application Title
iap_application_title = "Looply - Video Streaming Platform"

# Backend Services to Protect
iap_admin_backend_service = "admin-backend"
iap_user_mgmt_backend_service = "user-management-backend"
iap_analytics_backend_service = "analytics-backend"

# Authorized Users/Groups (add your actual users)
iap_admin_authorized_users = [
  "user:admin@looply.io",
  "group:admins@looply.io"
]

iap_user_mgmt_authorized_users = [
  "group:backend-team@looply.io"
]

iap_analytics_authorized_users = [
  "user:analyst@looply.io",
  "group:analytics-team@looply.io"
]

# Optional: Enable public access
iap_enable_public_access = false

# Monitoring
iap_enable_alerts = true
iap_failed_auth_threshold = 50
```

---

## 🚀 Deployment Steps

### 1. Review Module
```bash
cd terraform
cat modules/iap/README.md
```

### 2. Update Configuration
Edit `terraform.tfvars` with your:
- Support email
- Admin users/groups
- API users/groups
- Analyst users/groups

### 3. Initialize (if needed)
```bash
terraform init
```

### 4. Plan IAP Deployment
```bash
terraform plan -target=module.iap
```

### 5. Apply IAP Module
```bash
terraform apply -target=module.iap
```

### 6. Verify Deployment
```bash
# Check IAP outputs
terraform output iap

# List IAP resources
gcloud iap-web backends list
gcloud iap-web describe --service-account=iap
```

---

## 📊 IAP Architecture

```
┌──────────────────────────────────────┐
│       Internet Users                 │
└──────────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────┐
│  Load Balancer (HTTPS)               │
│  - Global Static IP                  │
│  - SSL/TLS Certificate               │
└──────────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────┐
│  IAP - Identity-Aware Proxy          │
│  ────────────────────────────────────│
│  ✓ OAuth 2.0 Verification            │
│  ✓ User Identity Check               │
│  ✓ Token Validation                  │
│  ✓ Role-Based Authorization          │
└──────────────────────────────────────┘
      ┌──────────┬──────────┬──────────┐
      ▼          ▼          ▼          ▼
  ┌─────────┐ ┌──────┐ ┌──────────┐ ┌──────┐
  │ Admin   │ │ User │ │Analytics │ │ API  │
  │ Panel   │ │Mgmt  │ │Dashboard │ │Check │
  └─────────┘ └──────┘ └──────────┘ └──────┘
  Cloud Run   Cloud Run  Cloud Run   Cloud Run
```

---

## 🔐 Security Features

### OAuth 2.0
- Secure user verification with Google account
- Automatic token refresh
- Session management

### Access Control
- User-based access (user:email@domain.com)
- Group-based access (group:name@domain.com)
- Role-based IAM binding (iap.httpsResourceAccessor)

### Encryption
- OAuth client secrets encrypted with Cloud KMS
- Data in transit: HTTPS only
- Audit logs stored securely

### Monitoring
- Failed authentication alerts
- Complete access audit trail
- Cloud Logging integration

---

## 📋 Configuration Examples

### Example 1: Admin Only Access
```hcl
iap_admin_authorized_users = [
  "user:john.doe@looply.io",
  "user:jane.smith@looply.io"
]
```

### Example 2: Group-Based Access
```hcl
iap_admin_authorized_users = [
  "group:platform-admins@looply.io"
]

iap_user_mgmt_authorized_users = [
  "group:backend-team@looply.io"
]

iap_analytics_authorized_users = [
  "group:data-analysts@looply.io"
]
```

### Example 3: Mixed Access
```hcl
iap_admin_authorized_users = [
  "user:security-lead@looply.io",
  "group:on-call-admins@looply.io"
]
```

---

## 🧪 Testing IAP

### 1. Access Protected Service
```bash
# This will redirect to Google login
curl -v https://admin.looply.io/

# Expected: 302 redirect to Google Sign-In
```

### 2. Check Logs
```bash
# View recent IAP access logs
gcloud logging read "resource.type=http_load_balancer" \
  --format=json --limit=10

# Check failed auth attempts
gcloud logging read "severity=WARNING AND resource.type=http_load_balancer" \
  --format=json
```

### 3. Verify OAuth Client
```bash
# List IAP brands
gcloud iap-web describe --service-account

# Get OAuth client info
terraform output iap
```

---

## 🔧 Managing User Access

### Add a New Admin User
```hcl
# In terraform.tfvars
iap_admin_authorized_users = [
  "user:john.doe@looply.io",
  "user:newadmin@looply.io"  # Add this
]

# Apply change
terraform apply
```

### Add Admin Group
```hcl
iap_admin_authorized_users = [
  "group:admins@looply.io"  # All admins via group
]

terraform apply
```

### Remove User Access
```hcl
# Simply remove from list and re-apply
iap_admin_authorized_users = [
  "user:john.doe@looply.io"  # Removed jane.smith
]

terraform apply
```

---

## 📈 Monitoring

### Alert Configuration
- **What**: Failed authentication rate
- **When**: > 50 failures in 5 minutes
- **Action**: Email notification to ops team

### Log Location
- **Destination**: `gs://looply-logs/`
- **Filter**: IAP-related entries
- **Retention**: 90 days

### Dashboard
Access monitoring dashboard:
```bash
# View in Cloud Console
gcloud monitoring dashboards list
```

---

## 💡 Key Features

| Feature | Status | Notes |
|---------|--------|-------|
| OAuth 2.0 | ✅ | Google authentication |
| User Access Control | ✅ | Per-user authorization |
| Group Access Control | ✅ | Google Groups supported |
| Audit Logging | ✅ | All access logged |
| Failed Auth Alerts | ✅ | Real-time notifications |
| MFA Support | ✅ | Via Cloud Identity |
| Cloud KMS | ✅ | Secret encryption |
| Multi-Region | ⏳ | Load Balancer handles |

---

## ⚡ Quick Commands

```bash
# Initialize Terraform
terraform init

# Plan IAP deployment
terraform plan -target=module.iap

# Deploy IAP
terraform apply -target=module.iap

# Verify deployment
terraform output iap

# Check IAP clients
gcloud iap-web backends list

# View IAP logs
gcloud logging read "resource.type=http_load_balancer" --limit=50

# Monitor failed auth
gcloud monitoring alerts list
```

---

## 📚 Documentation

- **Module README**: [modules/iap/README.md](modules/iap/README.md)
- **Implementation Guide**: [IAP_IMPLEMENTATION.md](IAP_IMPLEMENTATION.md)
- **Gap Analysis**: [GAP_ANALYSIS.md](GAP_ANALYSIS.md) (Updated)
- **GCP IAP Docs**: https://cloud.google.com/iap/docs

---

## 🎓 Next Steps

1. **Update terraform.tfvars**
   - Add support email
   - Add admin users/groups
   - Add API users/groups
   - Add analyst users/groups

2. **Deploy IAP Module**
   - Run `terraform plan`
   - Review changes
   - Run `terraform apply`

3. **Verify OAuth Setup**
   - Check OAuth client creation
   - Test Google Sign-In flow
   - Verify token validation

4. **Configure Monitoring**
   - Setup email alerts
   - Configure Slack/PagerDuty
   - Create custom dashboards

5. **Enable MFA (Optional)**
   - Configure Cloud Identity
   - Enforce for admins
   - Test MFA flow

---

## ✅ Checklist

- [ ] Reviewed IAP module documentation
- [ ] Updated terraform.tfvars with users/groups
- [ ] Run `terraform plan`
- [ ] Reviewed planned changes
- [ ] Run `terraform apply`
- [ ] Verified OAuth client created
- [ ] Tested access to protected service
- [ ] Verified alerts working
- [ ] Documented custom access rules
- [ ] Trained team on IAP usage

---

**Status**: ✅ Ready to Deploy
**Module Version**: 1.0.0
**Created**: 2025-12-16

For questions or issues, refer to the comprehensive module README and GCP documentation.
