# 🚀 Nexus Credentials Quick Start Guide

**Get secure credential management working in under 2 minutes!**

[![Quick Setup](https://img.shields.io/badge/⚡%20Setup%20Time-2%20minutes-green)]()
[![Security](https://img.shields.io/badge/🔒%20Security-Validated-blue)]()
[![Docker](https://img.shields.io/badge/🐳%20Docker-Ready-blue)]()

---

## 📋 Table of Contents

- [🎯 What You Need](#-what-you-need)
- [⚡ Super Quick Setup](#-super-quick-setup)
- [🐳 Docker Users](#-docker-users)
- [🏠 Local Development](#-local-development)
- [🔧 Manual Setup](#-manual-setup)
- [🧪 Testing & Validation](#-testing--validation)
- [🚨 Troubleshooting](#-troubleshooting)
- [📚 Reference](#-reference)
- [🆘 Getting Help](#-getting-help)

---

## 🎯 What You Need

**Prerequisites** (quick check):
- ✅ Your Nexus username (usually `admin`)
- ✅ Your Nexus password
- ✅ 2 minutes of your time
- ✅ Docker installed (for Docker setup)

**Quick compatibility check:**
```bash
docker --version && docker-compose --version
# Should show versions without errors
```

---

## ⚡ Super Quick Setup

### 🚀 One-Liner Setup

**For Docker environment (recommended):**
```bash
./scripts/setup-credentials.sh --username admin --password YOUR_PASSWORD --env docker
```

**For local development:**
```bash
./scripts/setup-credentials.sh --username admin --password YOUR_PASSWORD --env local
```

**Interactive mode (guided prompts):**
```bash
./scripts/setup-credentials.sh
```

### ✅ Verify It Works

```bash
# Load credentials
source .env

# Quick test
echo "✅ Username: $NEXUS_USERNAME"
echo "✅ Host: $NEXUS_HOST"
echo "✅ URL: $NEXUS_URL"

# Test publishing
sbt publishLocal
```

**Expected output:**
```
✅ Username: admin
✅ Host: nexus
✅ URL: http://nexus:8081/
[info] published obp-scala-library_2.13 to local repository
```

### 🎉 That's it! 

**Your credentials are now configured securely. Skip to [Testing & Validation](#-testing--validation) to verify everything works.**

---

## 🐳 Docker Users

### 🔥 Ultra-Fast Docker Setup

```bash
# 1. Setup credentials (30 seconds)
./scripts/setup-credentials.sh --env docker

# 2. Start everything (30 seconds)
cd docker && ./start-dev.sh

# 3. Test it works (30 seconds)
docker exec sbt bash -c "cd /workspace/scala-example-app && sbt run"
```

**Expected output:**
```
🔐 Environment file created successfully
🐳 Starting Nexus container...
✅ Nexus container started successfully
📦 Publishing to all Scala versions...
✅ Successfully published for Scala 2.12.17
✅ Successfully published for Scala 2.13.14
✅ Successfully published for Scala 3.3.1
Hello, Scala Developer from OBP Scala Library!
```

### 📦 Docker Publishing Commands

```bash
# Publish to all Scala versions (recommended)
./scripts/publish-all.sh

# Publish to specific version
source .env && cd docker && docker-compose run --rm -T \
  -e NEXUS_USERNAME="$NEXUS_USERNAME" \
  -e NEXUS_PASSWORD="$NEXUS_PASSWORD" \
  -e NEXUS_HOST="$NEXUS_HOST" \
  -e NEXUS_URL="$NEXUS_URL" \
  sbt sbt "++2.13.14" "publish"

# Quick local publish
docker exec sbt bash -c "cd /workspace && sbt publishLocal"
```

### 🔍 Docker Service Management

```bash
# Check service status
cd docker && docker-compose ps

# View Nexus web UI
open http://localhost:8081

# Access SBT container
docker exec -it sbt bash

# View logs
docker-compose logs nexus
docker-compose logs sbt

# Stop services
docker-compose down
```

---

## 🏠 Local Development

### ⚡ Local Quick Setup

```bash
# 1. Setup for localhost
./scripts/setup-credentials.sh --env local

# 2. Start local Nexus (if you have one)
# Or use the Docker Nexus:
cd docker && docker-compose up -d nexus

# 3. Publish and test
source .env && sbt publishLocal
cd scala-example-app && sbt run
```

### 🔧 Local Environment Variables

**For local Nexus instance:**
```bash
NEXUS_USERNAME=admin
NEXUS_PASSWORD=your-password
NEXUS_HOST=localhost
NEXUS_URL=http://localhost:8081/
```

### 📦 Local Publishing

```bash
# Load credentials
source .env

# Publish locally (fast)
sbt publishLocal

# Publish to repository
sbt publish

# Cross-compile and publish
sbt +publish
```

---

## 🔧 Manual Setup

### 📝 Create .env File Manually

```bash
# Create the file
cat > .env << 'EOF'
# OBP Scala Library - Nexus Credentials
# Generated on $(date)

# Authentication
NEXUS_USERNAME=admin
NEXUS_PASSWORD=your-actual-password-here

# Connection (choose one)
# For Docker:
NEXUS_HOST=nexus
NEXUS_URL=http://nexus:8081/

# For Local:
# NEXUS_HOST=localhost
# NEXUS_URL=http://localhost:8081/
EOF

# Set secure permissions
chmod 600 .env
```

### 🔒 Security Verification

```bash
# Check file permissions
ls -la .env
# Should show: -rw------- 1 username group size date .env

# Check .gitignore protection
grep "^\.env$" .gitignore
# Should show: .env

# Test loading
source .env && echo "Variables loaded: $NEXUS_USERNAME at $NEXUS_HOST"
```

### 🛠️ Manual Convenience Script

```bash
# Create helper script
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
```

---

## 🧪 Testing & Validation

### 🚀 Quick Validation

```bash
# Comprehensive system check
./scripts/validate-setup.sh

# Quick health check
./scripts/validate-setup.sh --quick

# Check specific components
./scripts/validate-setup.sh --category security
./scripts/validate-setup.sh --category docker
```

### 🔐 Credential-Specific Tests

```bash
# Test credential setup
./scripts/test-credentials.sh

# Manual credential test
source .env && sbt "show credentials"

# Test publishing pipeline
./scripts/publish-all.sh --dry-run
```

### ✅ Expected Test Results

**Validation should show:**
```
🔍 OBP Scala Library Environment Validator v2.0.0
==============================================================

📋 Prerequisites Check
─────────────────────
✅ Docker available (20.10.17)
✅ Docker Compose available (2.6.0)
✅ curl available (7.68.0)

🔐 Security Configuration Check
──────────────────────────────
✅ .env in .gitignore
✅ .env file exists
✅ .env file permissions (600)
✅ Hardcoded credentials limited

📊 Validation Summary
====================
Checks Passed: 15
Checks Failed: 0
Checks Warned: 2
Total Checks: 17

🎉 All critical validations passed! Your setup is ready.
```

### 🎯 Functional Tests

```bash
# Test Scala example
cd scala-example-app && sbt run
# Expected: Hello, Scala Developer from OBP Scala Library!

# Test Java example
cd java-example-app && mvn compile exec:java -Dexec.mainClass="com.example.app.MainApp"
# Expected: Hello, Java Developer from OBP Scala Library!

# Test Docker workflow
docker exec sbt bash -c "cd /workspace/scala-example-app && sbt run"
# Expected: Hello, Scala Developer from OBP Scala Library!
```

---

## 🚨 Troubleshooting

### ❓ Common Issues & Quick Fixes

| Issue | Symptoms | Quick Fix | Details |
|-------|----------|-----------|---------|
| **🔑 Missing credentials** | `Warning: NEXUS_USERNAME ... not set` | `source .env` | Load environment variables |
| **🔒 Permission denied** | `bash: .env: Permission denied` | `chmod 600 .env` | Fix file permissions |
| **🌐 Connection refused** | `Connection to nexus:8081 refused` | `cd docker && docker-compose up -d nexus` | Start Nexus container |
| **🚫 401 Unauthorized** | `HTTP 401` response | Check password in `.env` | Verify credentials |
| **📦 HTTP 400 error** | `Bad Request` from Nexus | Check version in `build.sbt` | Ensure SNAPSHOT format |
| **🐳 Docker not found** | `docker: command not found` | Install Docker | See Docker installation guide |
| **📁 File not found** | `build.sbt not found` | `cd OBP-Scala-Library` | Run from project root |

### 🔧 Step-by-Step Diagnostics

**Problem: Setup script doesn't work**
```bash
# 1. Check prerequisites
docker --version && docker-compose --version

# 2. Check project location
pwd
ls -la build.sbt  # Should exist

# 3. Check script permissions
ls -la scripts/setup-credentials.sh  # Should be executable

# 4. Run with verbose output
bash -x ./scripts/setup-credentials.sh --env docker
```

**Problem: Publishing fails**
```bash
# 1. Check environment
source .env
echo "User: $NEXUS_USERNAME, Host: $NEXUS_HOST, URL: $NEXUS_URL"

# 2. Check Nexus is running
curl -f http://localhost:8081/  # Should return HTML

# 3. Check credentials
./scripts/test-credentials.sh

# 4. Check version format
grep "version :=" build.sbt  # Should end with -SNAPSHOT
```

**Problem: Docker issues**
```bash
# 1. Check Docker daemon
docker info

# 2. Check Docker Compose
cd docker && docker-compose ps

# 3. Check container logs
docker-compose logs nexus
docker-compose logs sbt

# 4. Restart services
docker-compose down && docker-compose up -d
```

### 🆘 Advanced Troubleshooting

**Reset everything and start fresh:**
```bash
# 1. Stop all Docker services
cd docker && docker-compose down

# 2. Remove old credentials
rm -f .env source-env.sh

# 3. Clear Docker volumes (optional - removes Nexus data)
docker-compose down -v

# 4. Start fresh
./scripts/setup-credentials.sh --env docker
cd docker && ./start-dev.sh
```

**Network connectivity issues:**
```bash
# Test external connectivity
curl -v https://google.com

# Test local Docker network
docker network ls
docker network inspect docker_default

# Test Nexus connectivity
curl -v http://localhost:8081/
telnet localhost 8081
```

**File permission issues (Linux/macOS):**
```bash
# Check current permissions
ls -la .env
stat -c "%a %n" .env  # Linux
stat -f "%A %N" .env  # macOS

# Fix permissions
chmod 600 .env
chown $USER .env

# Check ownership
ls -la .env
```

### 🐞 Debug Mode

**Enable detailed logging:**
```bash
# Run setup with debug output
bash -x ./scripts/setup-credentials.sh --env docker

# Run validation with verbose output
./scripts/validate-setup.sh --verbose

# Run publishing with detailed output
./scripts/publish-all.sh --verbose
```

**Check log files:**
```bash
# Publishing logs (created by publish-all.sh)
ls -la logs/
cat logs/publish-2.13.14-attempt-1.log

# Docker logs
cd docker && docker-compose logs --tail 50 nexus
```

---

## 📚 Reference

### 🔧 Environment Variables Reference

| Variable | Purpose | Docker Value | Local Value | Required |
|----------|---------|--------------|-------------|----------|
| `NEXUS_USERNAME` | Authentication username | `admin` | `admin` | ✅ Yes |
| `NEXUS_PASSWORD` | Authentication password | Your password | Your password | ✅ Yes |
| `NEXUS_HOST` | Server hostname | `nexus` | `localhost` | ✅ Yes |
| `NEXUS_URL` | Full server URL | `http://nexus:8081/` | `http://localhost:8081/` | ✅ Yes |
| `SETUP_DATE` | Creation timestamp | Auto-generated | Auto-generated | ❌ No |
| `SETUP_ENVIRONMENT` | Environment preset | `docker` | `local` | ❌ No |

### 🎯 Command Reference

**Setup Commands:**
```bash
# Interactive setup
./scripts/setup-credentials.sh

# Quick Docker setup  
./scripts/setup-credentials.sh --env docker --username admin --password PASSWORD

# Quick local setup
./scripts/setup-credentials.sh --env local --username admin --password PASSWORD

# Custom setup
./scripts/setup-credentials.sh --username USER --password PASS --host HOST --url URL

# Non-interactive setup
./scripts/setup-credentials.sh --non-interactive --env docker --force

# Show help
./scripts/setup-credentials.sh --help
```

**Publishing Commands:**
```bash
# Publish all versions
./scripts/publish-all.sh

# Publish specific version
./scripts/publish-all.sh --version 2.13.14

# Dry run (preview only)
./scripts/publish-all.sh --dry-run

# Parallel publishing
./scripts/publish-all.sh --parallel 2

# With retries
./scripts/publish-all.sh --max-retries 5
```

**Validation Commands:**
```bash
# Full validation
./scripts/validate-setup.sh

# Quick check
./scripts/validate-setup.sh --quick

# Specific category
./scripts/validate-setup.sh --category security

# Fix permissions
./scripts/validate-setup.sh --fix-permissions

# Skip network tests
./scripts/validate-setup.sh --no-network
```

### 🔄 Version Management

**SNAPSHOT versions (development):**
```scala
version := "0.1.0-SNAPSHOT"  // ✅ Correct for snapshots repository
```

**Release versions (production):**
```scala
version := "0.1.0"  // ✅ Correct for releases repository
```

**Repository URLs:**
- **Snapshots:** `http://nexus:8081/repository/maven-snapshots/`
- **Releases:** `http://nexus:8081/repository/maven-releases/`

### 🛡️ Security Best Practices

**✅ DO:**
- Use environment variables for credentials
- Set `.env` file permissions to `600`
- Keep `.env` in `.gitignore`
- Use strong passwords
- Regularly rotate passwords
- Use different credentials for different environments

**❌ DON'T:**
- Hardcode passwords in source code
- Commit `.env` files to version control
- Share `.env` files via email/chat
- Use default passwords in production
- Store credentials in plain text files with loose permissions
- Use the same password across multiple environments

---

## 🆘 Getting Help

### 📞 Support Channels

| Issue Type | Channel | Response Time |
|------------|---------|---------------|
| **🐛 Setup Issues** | [GitHub Issues](https://github.com/OpenBankProject/OBP-Scala-Library/issues) | 1-2 days |
| **❓ Usage Questions** | [GitHub Discussions](https://github.com/OpenBankProject/OBP-Scala-Library/discussions) | 1 day |
| **🔒 Security Concerns** | [security@openbankproject.com](mailto:security@openbankproject.com) | 24 hours |
| **💡 Feature Requests** | [GitHub Issues](https://github.com/OpenBankProject/OBP-Scala-Library/issues) | Weekly review |

### 🔍 Before Asking for Help

**Run the diagnostic commands:**
```bash
# 1. System validation
./scripts/validate-setup.sh --verbose > validation-report.txt

# 2. Credential testing
./scripts/test-credentials.sh > credential-test.txt

# 3. Environment check
source .env 2>/dev/null && env | grep NEXUS > env-check.txt

# 4. Docker status
cd docker && docker-compose ps > docker-status.txt
```

**Include this information in your issue:**
- Operating system and version
- Docker and Docker Compose versions
- Output of `./scripts/validate-setup.sh`
- Any error messages (full text)
- Steps you've already tried

### 📚 Additional Documentation

- **🏠 Main README:** [README.md](README.md)
- **🐳 Docker Guide:** [docker/README.md](docker/README.md)
- **🔐 Security Details:** [docs/CREDENTIALS.md](docs/CREDENTIALS.md)
- **🛠️ Troubleshooting:** [docker/TROUBLESHOOTING.md](docker/TROUBLESHOOTING.md)

---

<div align="center">

**🚀 Ready to get started?**

[![Get Started](https://img.shields.io/badge/▶️%20Get%20Started-./scripts/setup--credentials.sh-green?style=for-the-badge)]()

**Your secure development environment is just one command away!**

---

**🏦 Open Bank Project | 🔐 Secure by Design | 🚀 Ready in Minutes**

</div>