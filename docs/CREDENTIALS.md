# Comprehensive Nexus Repository Credentials Management Guide

This document provides detailed guidance on managing credentials securely for the OBP Scala Library's Nexus repository integration.

[![Security](https://img.shields.io/badge/🔒%20Security-Best%20Practices-blue)]()
[![Environment](https://img.shields.io/badge/🌍%20Multi--Environment-Supported-green)]()
[![Automation](https://img.shields.io/badge/⚙️%20Automation-Ready-orange)]()

---

## 📋 Table of Contents

- [🎯 Overview](#-overview)
- [🔒 Security Best Practices](#-security-best-practices)
- [⚡ Quick Setup](#-quick-setup)
- [🔧 Environment Configuration](#-environment-configuration)
- [🐳 Docker Integration](#-docker-integration)
- [🏠 Local Development](#-local-development)
- [🔄 CI/CD Integration](#-cicd-integration)
- [🧪 Testing & Validation](#-testing--validation)
- [🚨 Troubleshooting](#-troubleshooting)
- [📚 Advanced Topics](#-advanced-topics)
- [🔍 Security Auditing](#-security-auditing)

---

## 🎯 Overview

The OBP Scala Library uses environment-based credential management to securely publish artifacts to Nexus repositories. This approach ensures:

- **🔐 No hardcoded credentials** in source code
- **🌍 Multi-environment support** (Docker, local, CI/CD)
- **🔄 Automated rotation** capabilities
- **🛡️ Security compliance** with best practices
- **📝 Audit trail** for credential usage

### Supported Credential Methods

| Method | Security | Convenience | Best For |
|--------|----------|-------------|----------|
| **Environment Variables** ⭐ | High | High | All environments |
| **Credentials File** | Medium | Medium | Local development |
| **Docker Secrets** | High | Medium | Production containers |
| **CI/CD Variables** | High | High | Automated pipelines |

---

## 🔒 Security Best Practices

### 🛡️ Core Principles

1. **Never hardcode credentials** in source code, configuration files, or documentation
2. **Use environment variables** as the primary credential delivery mechanism
3. **Implement least privilege** - only provide necessary permissions
4. **Regular rotation** of credentials, especially for production environments
5. **Audit credential access** and usage patterns
6. **Secure storage** with appropriate file permissions and encryption

### ✅ Security Checklist

- [ ] Credentials stored as environment variables
- [ ] `.env` file permissions set to `600` (owner read/write only)
- [ ] `.env` and `source-env.sh` added to `.gitignore`
- [ ] No credentials in git history
- [ ] Strong passwords (minimum 12 characters, mixed case, numbers, symbols)
- [ ] Different credentials for different environments
- [ ] Regular credential rotation schedule
- [ ] Monitoring for credential exposure

### ❌ Common Security Mistakes

| ❌ **DON'T** | ✅ **DO** |
|--------------|-----------|
| Commit `.env` files | Add `.env` to `.gitignore` |
| Use weak passwords | Use strong, generated passwords |
| Share credentials via email/chat | Use secure credential sharing tools |
| Hardcode in `build.sbt` | Use `sys.env.get()` |
| Same password everywhere | Environment-specific credentials |
| Ignore file permissions | Set `.env` to `600` permissions |

---

## ⚡ Quick Setup

### 🚀 Automated Setup (Recommended)

The fastest way to get secure credentials configured:

```bash
# Interactive setup with guided prompts
./scripts/setup-credentials.sh

# Quick Docker environment setup
./scripts/setup-credentials.sh --username admin --password YOUR_PASSWORD --env docker

# Quick local development setup
./scripts/setup-credentials.sh --username admin --password YOUR_PASSWORD --env local
```

### 🔍 Verify Setup

```bash
# Load and test credentials
source .env
echo "Username: $NEXUS_USERNAME"
echo "Host: $NEXUS_HOST" 
echo "URL: $NEXUS_URL"

# Comprehensive validation
./scripts/validate-setup.sh

# Credential-specific testing
./scripts/test-credentials.sh
```

---

## 🔧 Environment Configuration

### 📝 Required Environment Variables

| Variable | Purpose | Example | Required |
|----------|---------|---------|----------|
| `NEXUS_USERNAME` | Authentication username | `admin` | ✅ Yes |
| `NEXUS_PASSWORD` | Authentication password | `your-secure-password` | ✅ Yes |
| `NEXUS_HOST` | Repository hostname | `nexus` / `localhost` | ✅ Yes |
| `NEXUS_URL` | Full repository URL | `http://nexus:8081/` | ✅ Yes |

### 📝 Optional Environment Variables

| Variable | Purpose | Example | Default |
|----------|---------|---------|---------|
| `SETUP_DATE` | Credential creation timestamp | `2024-01-15T10:30:00Z` | Auto-generated |
| `SETUP_ENVIRONMENT` | Environment preset used | `docker` / `local` | `manual` |
| `SETUP_VERSION` | Setup script version | `2.0.0` | Current version |

### 🌍 Environment Presets

#### 🐳 Docker Environment
```bash
NEXUS_USERNAME=admin
NEXUS_PASSWORD=your-secure-password
NEXUS_HOST=nexus
NEXUS_URL=http://nexus:8081/
```

#### 🏠 Local Development
```bash
NEXUS_USERNAME=admin
NEXUS_PASSWORD=your-secure-password
NEXUS_HOST=localhost
NEXUS_URL=http://localhost:8081/
```

#### ☁️ Production Environment
```bash
NEXUS_USERNAME=production-user
NEXUS_PASSWORD=highly-secure-production-password
NEXUS_HOST=nexus.company.com
NEXUS_URL=https://nexus.company.com:8443/
```

---

## 🐳 Docker Integration

### 🔄 Docker Compose Integration

The credentials seamlessly integrate with Docker Compose services:

```yaml
# docker/docker-compose.yml
services:
  sbt:
    build: ./sbt
    environment:
      - NEXUS_USERNAME=${NEXUS_USERNAME}
      - NEXUS_PASSWORD=${NEXUS_PASSWORD}
      - NEXUS_HOST=${NEXUS_HOST}
      - NEXUS_URL=${NEXUS_URL}
    volumes:
      - ../:/workspace
```

### 🚀 Docker Workflow

```bash
# 1. Setup credentials for Docker
./scripts/setup-credentials.sh --env docker

# 2. Start development environment
cd docker && docker-compose up -d

# 3. Publish using Docker containers
./scripts/publish-all.sh

# 4. Test publishing worked
docker exec sbt bash -c "cd /workspace/scala-example-app && sbt run"
```

### 🔒 Docker Security Considerations

- **Environment variables** are preferred over volume-mounted credential files
- **Use Docker secrets** for production deployments
- **Limit container privileges** - don't run as root
- **Scan images** for vulnerabilities regularly
- **Network isolation** - use custom networks for services

---

## 🏠 Local Development

### ⚡ Local Setup Process

```bash
# 1. Create credentials for local environment
./scripts/setup-credentials.sh --env local

# 2. Verify local Nexus is running (if using local instance)
curl http://localhost:8081/

# 3. Test credential loading
source .env && echo "Loaded: $NEXUS_USERNAME@$NEXUS_HOST"

# 4. Publish locally
sbt +publishLocal
```

### 🔧 Manual Local Configuration

If you prefer manual setup:

```bash
# Create .env file
cat > .env << 'EOF'
# OBP Scala Library - Local Development Credentials
NEXUS_USERNAME=admin
NEXUS_PASSWORD=your-local-password
NEXUS_HOST=localhost
NEXUS_URL=http://localhost:8081/
EOF

# Set secure permissions
chmod 600 .env

# Create convenience script
cat > source-env.sh << 'EOF'
#!/bin/bash
if [ -f ".env" ]; then
    source .env
    echo "✅ Environment loaded: $NEXUS_USERNAME@$NEXUS_HOST"
else
    echo "❌ .env file not found"
    exit 1
fi
EOF

chmod +x source-env.sh

# Add to .gitignore
echo ".env" >> .gitignore
echo "source-env.sh" >> .gitignore
```

---

## 🔄 CI/CD Integration

### 🤖 GitHub Actions

Example GitHub Actions workflow with secure credential management:

```yaml
name: Build and Publish

on:
  push:
    tags: ['v*']

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup environment
        env:
          NEXUS_USERNAME: ${{ secrets.NEXUS_USERNAME }}
          NEXUS_PASSWORD: ${{ secrets.NEXUS_PASSWORD }}
          NEXUS_HOST: ${{ secrets.NEXUS_HOST }}
          NEXUS_URL: ${{ secrets.NEXUS_URL }}
        run: |
          # Validate credentials are available
          if [ -z "$NEXUS_USERNAME" ] || [ -z "$NEXUS_PASSWORD" ]; then
            echo "❌ Credentials not configured in GitHub secrets"
            exit 1
          fi
          echo "✅ Credentials available"
      
      - name: Publish artifacts
        env:
          NEXUS_USERNAME: ${{ secrets.NEXUS_USERNAME }}
          NEXUS_PASSWORD: ${{ secrets.NEXUS_PASSWORD }}
          NEXUS_HOST: ${{ secrets.NEXUS_HOST }}
          NEXUS_URL: ${{ secrets.NEXUS_URL }}
        run: |
          # Start Nexus container for publishing
          cd docker && docker-compose up -d nexus
          
          # Wait for Nexus to be ready
          timeout 60 bash -c 'until curl -f http://localhost:8081; do sleep 5; done'
          
          # Publish all versions
          ./scripts/publish-all.sh
```

### 🔐 Setting Up CI/CD Secrets

**GitHub Secrets:**
1. Go to repository → Settings → Secrets and variables → Actions
2. Add the following repository secrets:
   - `NEXUS_USERNAME`: Your Nexus username
   - `NEXUS_PASSWORD`: Your Nexus password
   - `NEXUS_HOST`: Your Nexus hostname
   - `NEXUS_URL`: Your Nexus URL

**GitLab CI Variables:**
1. Go to project → Settings → CI/CD → Variables
2. Add variables with protection enabled for protected branches:
   - `NEXUS_USERNAME`
   - `NEXUS_PASSWORD` (marked as masked)
   - `NEXUS_HOST`
   - `NEXUS_URL`

### 🚨 CI/CD Security Best Practices

- **Use masked variables** for passwords
- **Limit variable scope** to specific branches/tags
- **Implement approval workflows** for production deployments
- **Audit CI/CD logs** regularly (passwords should never appear)
- **Use short-lived credentials** where possible
- **Implement credential rotation** in CI/CD systems

---

## 🧪 Testing & Validation

### 🔍 Comprehensive Testing

Run the full credential test suite:

```bash
# Complete credential system test
./scripts/test-credentials.sh

# Quick essential tests only
./scripts/test-credentials.sh --quick

# Test specific components
./scripts/test-credentials.sh --category environment
./scripts/test-credentials.sh --category docker
./scripts/test-credentials.sh --category sbt
```

### ✅ Validation Checklist

Use this checklist to ensure your credential setup is secure and functional:

```bash
# 1. Environment variable validation
source .env
[ -n "$NEXUS_USERNAME" ] && echo "✅ Username set" || echo "❌ Username missing"
[ -n "$NEXUS_PASSWORD" ] && echo "✅ Password set" || echo "❌ Password missing"
[ -n "$NEXUS_HOST" ] && echo "✅ Host set" || echo "❌ Host missing"
[ -n "$NEXUS_URL" ] && echo "✅ URL set" || echo "❌ URL missing"

# 2. File security validation
ls -la .env | grep -q "^-rw-------" && echo "✅ Secure permissions" || echo "❌ Insecure permissions"
grep -q "^\.env$" .gitignore && echo "✅ Git ignored" || echo "❌ Not git ignored"

# 3. Connectivity validation
curl -f "${NEXUS_URL}" >/dev/null && echo "✅ Nexus reachable" || echo "❌ Cannot reach Nexus"

# 4. SBT integration validation
sbt "show credentials" | grep -q "$NEXUS_USERNAME" && echo "✅ SBT integration" || echo "❌ SBT integration failed"
```

### 🧪 Manual Testing Commands

```bash
# Test environment loading
source .env && env | grep NEXUS

# Test SBT credential configuration
sbt "show credentials"
sbt "show publishTo"

# Test Docker integration
cd docker && docker-compose run --rm -T \
  -e NEXUS_USERNAME="$NEXUS_USERNAME" \
  -e NEXUS_PASSWORD="$NEXUS_PASSWORD" \
  -e NEXUS_HOST="$NEXUS_HOST" \
  -e NEXUS_URL="$NEXUS_URL" \
  sbt sbt "show credentials"

# Test publishing pipeline
./scripts/publish-all.sh --dry-run
```

---

## 🚨 Troubleshooting

### 🔧 Common Issues and Solutions

#### ❌ "Warning: NEXUS_USERNAME and/or NEXUS_PASSWORD environment variables not set"

**Cause:** Environment variables not loaded or not set.

**Solutions:**
```bash
# Check if .env exists and is readable
ls -la .env

# Load environment variables
source .env

# Verify variables are set
echo "Username: $NEXUS_USERNAME"
echo "Password length: ${#NEXUS_PASSWORD}"

# If .env doesn't exist, create it
./scripts/setup-credentials.sh
```

#### ❌ "Connection refused" or "Cannot connect to Nexus"

**Cause:** Nexus service not running or unreachable.

**Solutions:**
```bash
# Check if Nexus is running (Docker)
cd docker && docker-compose ps nexus

# Start Nexus if not running
docker-compose up -d nexus

# Test connectivity
curl -v http://localhost:8081/

# Check if port is open
netstat -tlnp | grep 8081
```

#### ❌ "401 Unauthorized" errors

**Cause:** Invalid credentials or authentication failure.

**Solutions:**
```bash
# Verify credentials in .env file
cat .env | grep -v PASSWORD  # Show non-sensitive info

# Test credentials manually
curl -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" http://localhost:8081/service/rest/v1/status

# Reset credentials
./scripts/setup-credentials.sh --force
```

#### ❌ "HTTP 400 Bad Request" during publishing

**Cause:** Version format doesn't match repository type.

**Solutions:**
```bash
# Check current version in build.sbt
grep "version :=" build.sbt

# For snapshots repository, version must end with -SNAPSHOT
# version := "0.1.0-SNAPSHOT"

# For releases repository, version must NOT end with -SNAPSHOT
# version := "0.1.0"

# Check which repository will be used
sbt "show publishTo"
```

#### 🐳 Docker-specific issues

**Container cannot access credentials:**
```bash
# Verify environment variables are passed to container
docker-compose run --rm -T sbt env | grep NEXUS

# Check docker-compose.yml has environment section
grep -A 5 "environment:" docker/docker-compose.yml
```

**Permission denied accessing .env:**
```bash
# Fix file permissions
chmod 600 .env
chown $USER .env

# Verify permissions
ls -la .env
```

### 🔍 Debug Mode

Enable detailed debugging:

```bash
# Debug credential setup
bash -x ./scripts/setup-credentials.sh --env docker

# Debug publishing
bash -x ./scripts/publish-all.sh --dry-run

# Debug SBT with verbose output
sbt -v "show credentials"
```

---

## 📚 Advanced Topics

### 🔄 Credential Rotation

Implement regular credential rotation:

```bash
#!/bin/bash
# credential-rotation.sh - Example rotation script

# Generate new password
NEW_PASSWORD=$(openssl rand -base64 32)

# Update Nexus password (pseudo-code)
# curl -X PUT "$NEXUS_URL/service/rest/v1/security/users/admin/change-password" \
#   -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
#   -H "Content-Type: text/plain" \
#   -d "$NEW_PASSWORD"

# Update local .env file
sed -i.backup "s/NEXUS_PASSWORD=.*/NEXUS_PASSWORD=$NEW_PASSWORD/" .env

# Test new credentials
source .env && sbt "show credentials"

echo "✅ Credential rotation completed"
```

### 🔐 Multiple Environment Management

Manage credentials for different environments:

```bash
# Directory structure
credentials/
├── .env.development
├── .env.staging
├── .env.production
└── switch-env.sh

# switch-env.sh
#!/bin/bash
ENVIRONMENT=${1:-development}
ENV_FILE="credentials/.env.$ENVIRONMENT"

if [ -f "$ENV_FILE" ]; then
    cp "$ENV_FILE" .env
    echo "✅ Switched to $ENVIRONMENT environment"
else
    echo "❌ Environment file not found: $ENV_FILE"
fi
```

### 🏗️ Integration with External Secret Management

#### HashiCorp Vault Integration

```bash
# fetch-credentials.sh - Example Vault integration
#!/bin/bash

# Authenticate with Vault
vault auth -method=userpass username=builder

# Fetch credentials
CREDENTIALS=$(vault kv get -json secret/nexus/credentials)
export NEXUS_USERNAME=$(echo "$CREDENTIALS" | jq -r '.data.data.username')
export NEXUS_PASSWORD=$(echo "$CREDENTIALS" | jq -r '.data.data.password')
export NEXUS_HOST=$(echo "$CREDENTIALS" | jq -r '.data.data.host')
export NEXUS_URL=$(echo "$CREDENTIALS" | jq -r '.data.data.url')

# Validate credentials
if [ -z "$NEXUS_USERNAME" ] || [ -z "$NEXUS_PASSWORD" ]; then
    echo "❌ Failed to fetch credentials from Vault"
    exit 1
fi

echo "✅ Credentials fetched from Vault"
```

#### AWS Secrets Manager Integration

```bash
# aws-secrets.sh - Example AWS integration
#!/bin/bash

SECRET_ARN="arn:aws:secretsmanager:region:account:secret:nexus-credentials"
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --query SecretString --output text)

export NEXUS_USERNAME=$(echo "$SECRET_JSON" | jq -r '.username')
export NEXUS_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')
export NEXUS_HOST=$(echo "$SECRET_JSON" | jq -r '.host')
export NEXUS_URL=$(echo "$SECRET_JSON" | jq -r '.url')
```

### 🔒 Advanced Security Configuration

#### File-based Credentials (Alternative)

```scala
// In build.sbt - using SBT credentials file
credentials += Credentials(Path.userHome / ".sbt" / ".credentials")
```

```properties
# ~/.sbt/.credentials
realm=Sonatype Nexus Repository Manager
host=nexus.company.com
user=your-username
password=your-password
```

#### Network Security

```scala
// build.sbt - HTTPS configuration for production
publishTo := {
  val nexus = "https://nexus.company.com:8443/"
  if (isSnapshot.value)
    Some("snapshots" at nexus + "repository/maven-snapshots/")
  else
    Some("releases" at nexus + "repository/maven-releases/")
}

// Add SSL/TLS configuration if needed
ThisBuild / updateOptions := updateOptions.value.withGigahorse(false)
```

---

## 🔍 Security Auditing

### 🕵️ Regular Security Checks

Implement these regular security audits:

```bash
#!/bin/bash
# security-audit.sh - Comprehensive security check

echo "🔍 OBP Scala Library Credential Security Audit"
echo "==============================================="

# 1. Check for credential exposure in git
echo "Checking git history for credential exposure..."
if git log --all --grep="password\|credential\|secret" --oneline | head -5; then
    echo "⚠️ Potential credential references found in git history"
else
    echo "✅ No credential references in git history"
fi

# 2. Scan source code for hardcoded credentials
echo "Scanning for hardcoded credentials..."
HARDCODED=$(grep -r "password\|secret\|credential" src/ --include="*.scala" --include="*.sbt" | grep -v "sys.env" | wc -l)
if [ "$HARDCODED" -gt 0 ]; then
    echo "❌ Found $HARDCODED potential hardcoded credentials"
else
    echo "✅ No hardcoded credentials found"
fi

# 3. Check file permissions
echo "Checking file permissions..."
if [ -f ".env" ]; then
    PERMS=$(stat -c "%a" .env)
    if [ "$PERMS" = "600" ]; then
        echo "✅ .env file has secure permissions ($PERMS)"
    else
        echo "❌ .env file has insecure permissions ($PERMS)"
    fi
fi

# 4. Check password strength
echo "Checking password strength..."
source .env 2>/dev/null
if [ -n "$NEXUS_PASSWORD" ]; then
    PASSWORD_LENGTH=${#NEXUS_PASSWORD}
    if [ $PASSWORD_LENGTH -ge 12 ]; then
        echo "✅ Password length adequate ($PASSWORD_LENGTH characters)"
    else
        echo "⚠️ Password length inadequate ($PASSWORD_LENGTH characters)"
    fi
fi

# 5. Check for credential exposure in environment
echo "Checking process environment exposure..."
if ps aux | grep -i nexus | grep -v grep | grep -i password; then
    echo "❌ Credentials visible in process list"
else
    echo "✅ No credentials visible in process list"
fi
```

### 📊 Security Compliance Report

Generate compliance reports:

```bash
#!/bin/bash
# compliance-report.sh - Generate security compliance report

cat > security-compliance-report.md << EOF
# OBP Scala Library Security Compliance Report
Generated: $(date)

## Environment Configuration
- Environment Variables: $([ -f .env ] && echo "✅ Configured" || echo "❌ Not Configured")
- File Permissions: $([ -f .env ] && stat -c "%a" .env || echo "N/A")
- Git Protection: $(grep -q "^\.env$" .gitignore && echo "✅ Protected" || echo "❌ Not Protected")

## Credential Strength
- Password Length: ${#NEXUS_PASSWORD} characters
- Uses HTTPS: $(echo "$NEXUS_URL" | grep -q "https://" && echo "✅ Yes" || echo "❌ No")

## Build Configuration
- Environment Variables Used: $(grep -q "sys.env.get" build.sbt && echo "✅ Yes" || echo "❌ No")
- No Hardcoded Credentials: $(grep -r "password" build.sbt | grep -v "sys.env" | wc -l) instances found

## Recommendations
$([ ${#NEXUS_PASSWORD} -lt 12 ] && echo "- Increase password length to at least 12 characters")
$(echo "$NEXUS_URL" | grep -q "http://" && echo "- Consider using HTTPS for production")
$(! grep -q "^\.env$" .gitignore && echo "- Add .env to .gitignore")
EOF

echo "📊 Compliance report generated: security-compliance-report.md"
```

---

**🔒 Remember: Security is an ongoing process, not a one-time setup. Regularly review and update your credential management practices to maintain the highest security standards.**

**📚 For additional help:**
- **Quick Start:** [CREDENTIALS_QUICKSTART.md](../CREDENTIALS_QUICKSTART.md)
- **Main Documentation:** [README.md](../README.md)
- **Troubleshooting:** Use `./scripts/validate-setup.sh` and `./scripts/test-credentials.sh`

---

<div align="center">

**🏦 Open Bank Project | 🔐 Security-First Development**

[![GitHub](https://img.shields.io/badge/GitHub-OpenBankProject-black)](https://github.com/OpenBankProject)
[![Website](https://img.shields.io/badge/Website-openbankproject.com-blue)](https://www.openbankproject.com/)

</div>