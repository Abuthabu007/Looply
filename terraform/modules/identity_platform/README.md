# Identity Platform Module

This module configures Google Cloud Identity Platform with OAuth 2.0 providers, enabling Google Sign-In and custom authentication UI.

## Overview

The Identity Platform module:
- Enables the Identity Toolkit API
- Configures Google as an OAuth 2.0 Identity Provider
- Sets up the authentication configuration for your project
- Enables default OAuth provider support

## Prerequisites

Before using this module, you need to:

1. **Create OAuth 2.0 Credentials in Google Cloud Console:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Navigate to `APIs & Services` > `Credentials`
   - Click `Create Credentials` > `OAuth client ID`
   - Select `Web Application`
   - Add authorized JavaScript origins:
     - `http://localhost:3000` (for development)
     - `http://localhost:5000` (for development)
     - `https://yourdomain.com` (for production)
   - Add authorized redirect URIs:
     - `http://localhost:3000/auth/callback`
     - `http://localhost:5000/auth/callback`
     - `https://yourdomain.com/auth/callback`
   - Copy the `Client ID` and `Client Secret`

2. **Update terraform.tfvars:**
   ```hcl
   google_oauth_client_id = "YOUR_OAUTH_CLIENT_ID"
   google_oauth_client_secret = "YOUR_OAUTH_CLIENT_SECRET"
   allowed_redirect_uris = [
     "http://localhost:3000/auth/callback",
     "https://yourdomain.com/auth/callback"
   ]
   ```

## Features

### Google OAuth 2.0 IdP
- Enables users to sign in with their Google accounts
- Automatically handles token refresh and validation
- Supports custom scopes and permissions

### Identity Platform Configuration
- Project-level IdP settings
- Anonymous user handling
- Token customization options

## Usage

```hcl
module "identity_platform" {
  source = "./modules/identity_platform"

  gcp_project_id               = var.gcp_project_id
  google_oauth_client_id       = var.google_oauth_client_id
  google_oauth_client_secret   = var.google_oauth_client_secret
  allowed_redirect_uris        = var.allowed_redirect_uris

  depends_on = [module.apis]
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `gcp_project_id` | The GCP project ID | `string` | - | Yes |
| `google_oauth_client_id` | Google OAuth 2.0 Client ID | `string` | - | Yes |
| `google_oauth_client_secret` | Google OAuth 2.0 Client Secret | `string` | - | Yes |
| `allowed_redirect_uris` | List of allowed redirect URIs | `list(string)` | `["http://localhost:3000", "http://localhost:5000"]` | No |

## Outputs

| Name | Description |
|------|-------------|
| `identity_platform_project` | The GCP project ID for Identity Platform |
| `google_oauth_idp_name` | The resource name of the Google OAuth Identity Provider |
| `google_idp_enabled` | Whether Google is enabled as an Identity Provider |
| `identity_platform_config_resource` | The Identity Platform configuration resource name |

## Integration with IAP

To use Identity Platform with Identity-Aware Proxy (IAP), you can:

1. Configure the same OAuth credentials in both Identity Platform and IAP
2. Use Identity Platform for custom sign-in UI
3. Use IAP for protection of backend services

## Customization

### Add Additional OAuth Providers

To add more OAuth providers (GitHub, Microsoft, etc.), add similar resources:

```hcl
resource "google_identity_platform_oauth_idp_config" "github" {
  name          = "github.com"
  display_name  = "GitHub"
  client_id     = var.github_oauth_client_id
  client_secret = var.github_oauth_client_secret
  enabled       = true
  project       = var.gcp_project_id

  depends_on = [google_identity_platform_config.default]
}
```

### Customize Sign-In UI

You can customize the sign-in UI configuration:
- Custom branding and logos
- Custom email templates
- Multi-language support
- Custom domain configuration

Refer to [Google Cloud Identity Platform Documentation](https://cloud.google.com/docs/authentication/external-identities) for more details.

## Security Considerations

1. **Store Credentials Securely:**
   - Use Terraform Cloud/Enterprise state encryption
   - Use GCP Secret Manager for production credentials
   - Never commit `.tfvars` with real credentials to version control

2. **OAuth Scope Management:**
   - Request only necessary OAuth scopes
   - Regularly audit client IDs and secrets
   - Rotate credentials periodically

3. **HTTPS in Production:**
   - Always use HTTPS redirect URIs in production
   - Implement proper SSL/TLS certificates

## Troubleshooting

### Error: "Google should be enabled at the Identity Platform project-level IdPs"

This occurs when:
1. The Identity Platform API is not enabled (resolved by this module)
2. Google is not configured as an IdP (resolved by this module)
3. The OAuth credentials are invalid or not properly configured

**Solution:**
- Verify OAuth credentials are correct in Google Cloud Console
- Check that `allowed_redirect_uris` match your application's callback URLs
- Ensure the Identity Toolkit API is enabled: `gcloud services enable identitytoolkit.googleapis.com`

### Error: "Redirect URI mismatch"

Ensure the redirect URIs in your application exactly match the ones configured in:
1. Google Cloud Console OAuth settings
2. `allowed_redirect_uris` in terraform.tfvars
3. Your application's authentication configuration

## References

- [Google Cloud Identity Platform](https://cloud.google.com/docs/authentication/external-identities)
- [OAuth 2.0 Configuration](https://cloud.google.com/docs/authentication/external-identities/oauth2)
- [Terraform Google Identity Platform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/identity_platform_config)
