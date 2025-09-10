# OBP Scala Library

[![License](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()
[![Scala Versions](https://img.shields.io/badge/scala-2.12%20%7C%202.13%20%7C%203.x-red.svg)]()
[![Docker](https://img.shields.io/badge/docker-supported-blue.svg)]()

**OBP Scala Library** is a cross-version Scala library for the Open Bank Project ecosystem. It supports Scala 2.12, 2.13, and 3.x, and can be used in **Scala, Java, and Kotlin projects**.

---

## 📚 Table of Contents

- [🚀 Quick Start](#-quick-start)
- [✨ Features](#-features) 
- [💼 Usage Examples](#-usage-examples)
- [🔧 Development](#-development)
- [🐳 Docker Environment](#-docker-environment)
- [🔐 Credentials Management](#-credentials-management)
- [📦 Publishing](#-publishing)
- [🧪 Testing](#-testing)
- [📖 Documentation](#-documentation)
- [🛠️ System Requirements](#-system-requirements)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [🆘 Support](#-support)

---

## 🚀 Quick Start

### ⚡ 30-Second Setup (Docker - Recommended)

```bash
# 1. Clone and enter the project
git clone https://github.com/OpenBankProject/OBP-Scala-Library.git
cd OBP-Scala-Library

# 2. Set up credentials
./scripts/setup-credentials.sh --env docker

# 3. Start development environment
cd docker && ./start-dev.sh

# 4. Test the library works
docker exec sbt bash -c "cd /workspace/scala-example-app && sbt run"
# Output: Hello, Scala Developer from OBP Scala Library!
```

### 🏠 Native Setup (Local SBT)

```bash
# Prerequisites: Java 17+, SBT 1.9+
git clone https://github.com/OpenBankProject/OBP-Scala-Library.git
cd OBP-Scala-Library

# Build and test
sbt +compile +test

# Publish locally
sbt +publishLocal

# Test with example
cd scala-example-app && sbt run
```

### 🚦 Validation

```bash
# Validate your setup
./scripts/validate-setup.sh

# Quick validation
./scripts/validate-setup.sh --quick

# Docker-specific validation
./scripts/validate-setup.sh --category docker
```

---

## ✨ Features

### 🎯 Core Features
- **🔄 Cross-version Scala support**: 2.12.17, 2.13.14, 3.3.1
- **🌐 Multi-language compatibility**: Works with Scala, Java, and Kotlin
- **📦 Maven/Nexus publishing**: Ready for artifact repositories
- **🐳 Docker development environment**: No local setup required
- **⚙️ Automated CI/CD**: GitHub Actions workflow included

### 🛠️ Developer Experience
- **📝 Example applications**: Both Scala (SBT) and Java (Maven) examples
- **🔐 Secure credential management**: Environment-based configuration
- **🧪 Comprehensive testing**: Automated validation and testing scripts
- **📚 Rich documentation**: Quick-start guides and detailed documentation

### 🏗️ Build System
- **🔨 SBT-based**: Modern Scala build tool
- **🔀 Cross-compilation**: Automatic building for all supported versions
- **📊 Version management**: SNAPSHOT and release support
- **🔍 Quality assurance**: Automated testing and validation

---

## 💼 Usage Examples

### 🟢 In Scala Projects (SBT)

Add to your `build.sbt`:

```scala
// After publishing locally
libraryDependencies += "org.openbankproject" %% "obp-scala-library" % "0.1.0-SNAPSHOT"

// Using Nexus repository
resolvers += ("Local Nexus" at "http://localhost:8081/repository/maven-snapshots/").withAllowInsecureProtocol(true)
libraryDependencies += "org.openbankproject" %% "obp-scala-library" % "0.1.0-SNAPSHOT"
```

Using the library:
```scala
import org.openbankproject.library.OBPLibrary

object MyApp extends App {
  val library = new OBPLibrary()
  println(library.greet("Scala Developer"))
}
```

### ☕ In Java Projects (Maven)

Add to your `pom.xml`:

```xml
<dependencies>
  <dependency>
    <groupId>org.openbankproject</groupId>
    <artifactId>obp-scala-library_2.13</artifactId>
    <version>0.1.0-SNAPSHOT</version>
  </dependency>
  <dependency>
    <groupId>org.scala-lang</groupId>
    <artifactId>scala-library</artifactId>
    <version>2.13.14</version>
  </dependency>
</dependencies>
```

Using the library:
```java
import org.openbankproject.library.OBPLibrary;

public class MyJavaApp {
    public static void main(String[] args) {
        OBPLibrary library = new OBPLibrary();
        System.out.println(library.greet("Java Developer"));
    }
}
```

### 🏃 Running Examples

```bash
# Scala example (Docker)
docker exec sbt bash -c "cd /workspace/scala-example-app && sbt run"

# Scala example (Native)
cd scala-example-app && sbt run

# Java example (Native)
cd java-example-app && mvn compile exec:java -Dexec.mainClass="com.example.app.MainApp"
```

---

## 🔧 Development

### 📂 Repository Structure

```
OBP-Scala-Library/
├── 📁 src/                         # Library source code
│   ├── main/scala/                 # Main library implementation
│   └── test/scala/                 # Unit tests
├── 📁 scripts/                     # Utility and automation scripts
│   ├── setup-credentials.sh        # Secure credential setup
│   ├── publish-all.sh              # Multi-version publishing
│   ├── validate-setup.sh           # Environment validation
│   └── test-credentials.sh         # Credential testing
├── 📁 docker/                      # Docker development environment
│   ├── docker-compose.yml          # Services configuration
│   ├── start-dev.sh                # Development environment launcher
│   └── sbt/Dockerfile              # Custom SBT container
├── 📁 docs/                        # Additional documentation
│   ├── CREDENTIALS.md              # Detailed credential guide
│   └── developer-guide/            # Developer documentation
├── 📁 scala-example-app/           # Scala usage example
├── 📁 java-example-app/            # Java integration example
├── build.sbt                       # Main SBT configuration
├── CREDENTIALS_QUICKSTART.md       # 2-minute credential setup
└── README.md                       # This file
```

### 🔄 Development Workflow

#### 🐳 Docker Workflow (Recommended)
```bash
# 1. Initial setup
./scripts/setup-credentials.sh --env docker
cd docker && ./start-dev.sh

# 2. Development cycle
# Edit files in src/main/scala/
# Files are automatically mounted in containers

# 3. Test changes
docker exec sbt bash -c "cd /workspace && sbt +test"

# 4. Publish updated library
./scripts/publish-all.sh

# 5. Test with examples
docker exec sbt bash -c "cd /workspace/scala-example-app && sbt run"
```

#### 🏠 Native Workflow
```bash
# 1. Make changes in src/main/scala/

# 2. Test locally
sbt +test

# 3. Publish locally
sbt +publishLocal

# 4. Test with examples
cd scala-example-app && sbt run
cd ../java-example-app && mvn compile exec:java -Dexec.mainClass="com.example.app.MainApp"
```

### 🧰 Development Tools

```bash
# Validate entire setup
./scripts/validate-setup.sh

# Test specific components
./scripts/validate-setup.sh --category docker
./scripts/validate-setup.sh --category security

# Quick development check
./scripts/validate-setup.sh --quick

# Fix common issues automatically
./scripts/validate-setup.sh --fix-permissions
```

---

## 🐳 Docker Environment

### 🚀 Quick Start

```bash
# One-command setup
cd docker && ./start-dev.sh
```

### 🔧 Manual Setup

```bash
# Start services
cd docker && docker-compose up -d

# Access SBT container
docker exec -it sbt bash

# Access Nexus UI
open http://localhost:8081
```

### 📋 Available Services

| Service | Port | Purpose | Access |
|---------|------|---------|--------|
| Nexus | 8081 | Artifact repository | http://localhost:8081 |
| SBT | - | Scala build environment | `docker exec -it sbt bash` |

### 🛠️ Docker Commands

```bash
# View service status
cd docker && docker-compose ps

# View logs
docker-compose logs nexus
docker-compose logs sbt

# Stop services
docker-compose down

# Rebuild SBT container
docker-compose build sbt
```

### 📖 Detailed Docker Documentation
- **[Complete Docker Guide](docker/README.md)** - Comprehensive setup and usage
- **[Troubleshooting](docker/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Usage Examples](docker/EXAMPLE_USAGE.md)** - Practical workflows

---

## 🔐 Credentials Management

### ⚡ Quick Setup (2 minutes)

```bash
# Interactive setup
./scripts/setup-credentials.sh

# Or one-liner for Docker
./scripts/setup-credentials.sh --username admin --password your-password --env docker

# For local Nexus
./scripts/setup-credentials.sh --username admin --password your-password --env local
```

### 🔑 Environment Variables

| Variable | Description | Docker Value | Local Value |
|----------|-------------|--------------|-------------|
| `NEXUS_USERNAME` | Nexus username | `admin` | `admin` |
| `NEXUS_PASSWORD` | Nexus password | Your password | Your password |
| `NEXUS_HOST` | Nexus hostname | `nexus` | `localhost` |
| `NEXUS_URL` | Full Nexus URL | `http://nexus:8081/` | `http://localhost:8081/` |

### 🛡️ Security Features

- ✅ **Environment-based**: No hardcoded credentials
- ✅ **File permissions**: Automatic 600 permissions on .env
- ✅ **Git protection**: Automatic .gitignore entries
- ✅ **Validation**: Built-in credential testing
- ✅ **Fallback safety**: Secure fallback for development

### 📚 Credential Documentation

- **[🚀 CREDENTIALS_QUICKSTART.md](CREDENTIALS_QUICKSTART.md)** - 2-minute setup guide
- **[📖 docs/CREDENTIALS.md](docs/CREDENTIALS.md)** - Comprehensive credential guide

### 🔍 Testing Credentials

```bash
# Test credential setup
./scripts/test-credentials.sh

# Validate all credential components
./scripts/validate-setup.sh --category security
```

---

## 📦 Publishing

### 🚀 Publish to All Versions

```bash
# Recommended: Publish to all Scala versions
./scripts/publish-all.sh

# With options
./scripts/publish-all.sh --dry-run          # Preview what would be published
./scripts/publish-all.sh --version 2.13.14  # Publish specific version only
./scripts/publish-all.sh --parallel 2       # Use parallel publishing
```

### 🎯 Publish Specific Version

```bash
# Load credentials and publish
source .env && cd docker && docker-compose run --rm -T \
  -e NEXUS_USERNAME="$NEXUS_USERNAME" \
  -e NEXUS_PASSWORD="$NEXUS_PASSWORD" \
  -e NEXUS_HOST="$NEXUS_HOST" \
  -e NEXUS_URL="$NEXUS_URL" \
  sbt sbt "++2.13.14" "publish"
```

### 🏠 Local Publishing

```bash
# Docker environment
docker exec sbt bash -c "cd /workspace && sbt +publishLocal"

# Native environment
sbt +publishLocal
```

### 🔄 Automated Releases

Create a git tag to trigger automated release:

```bash
# Tag a release
git tag v0.1.0
git push origin v0.1.0

# GitHub Actions will automatically:
# • Build all Scala versions
# • Run comprehensive tests  
# • Publish signed artifacts
# • Create GitHub release
```

### 📊 Publishing Status

```bash
# Check what would be published
./scripts/publish-all.sh --dry-run

# Monitor publishing progress
./scripts/publish-all.sh --verbose

# Check published artifacts
curl http://localhost:8081/repository/maven-snapshots/org/openbankproject/
```

---

## 🧪 Testing

### ⚡ Quick Tests

```bash
# Run all tests (Docker)
docker exec sbt bash -c "cd /workspace && sbt +test"

# Run all tests (Native)
sbt +test

# Run tests for specific Scala version
sbt "++2.13.14" test
```

### 🔍 Validation Tests

```bash
# Full system validation
./scripts/validate-setup.sh

# Test categories
./scripts/validate-setup.sh --category functional
./scripts/validate-setup.sh --category docker
./scripts/validate-setup.sh --category security

# Quick health check
./scripts/validate-setup.sh --quick
```

### 🧪 Credential Tests

```bash
# Test credential configuration
./scripts/test-credentials.sh

# Test publishing pipeline
./scripts/publish-all.sh --dry-run
```

### 📋 Integration Tests

```bash
# Test Scala example
cd scala-example-app && sbt run

# Test Java example  
cd java-example-app && mvn compile exec:java -Dexec.mainClass="com.example.app.MainApp"

# Test in Docker
docker exec sbt bash -c "cd /workspace/scala-example-app && sbt run"
```

---

## 📖 Documentation

### 📚 Available Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| **[README.md](README.md)** | Main project overview | All users |
| **[CREDENTIALS_QUICKSTART.md](CREDENTIALS_QUICKSTART.md)** | 2-minute credential setup | New users |
| **[docs/CREDENTIALS.md](docs/CREDENTIALS.md)** | Comprehensive credential guide | Developers |
| **[docker/README.md](docker/README.md)** | Docker environment guide | Docker users |
| **[docs/developer-guide/](docs/developer-guide/)** | Developer documentation | Contributors |

### 🎯 Documentation by Use Case

**🆕 First-time setup:**
1. Start with this README
2. Follow [CREDENTIALS_QUICKSTART.md](CREDENTIALS_QUICKSTART.md)
3. Use `./scripts/validate-setup.sh`

**🐳 Docker users:**
1. [docker/README.md](docker/README.md) - Complete Docker guide
2. [docker/TROUBLESHOOTING.md](docker/TROUBLESHOOTING.md) - Problem solving
3. [docker/EXAMPLE_USAGE.md](docker/EXAMPLE_USAGE.md) - Practical examples

**🔐 Security-focused:**
1. [docs/CREDENTIALS.md](docs/CREDENTIALS.md) - Security best practices
2. [CREDENTIALS_QUICKSTART.md](CREDENTIALS_QUICKSTART.md) - Quick secure setup

**👩‍💻 Developers:**
1. [docs/developer-guide/](docs/developer-guide/) - Development workflows
2. [docs/CREDENTIALS.md](docs/CREDENTIALS.md) - Implementation details

---

## 🛠️ System Requirements

### 🐳 Docker Environment (Recommended)

| Component | Version | Purpose |
|-----------|---------|---------|
| **Docker** | 20.0+ | Container runtime |
| **Docker Compose** | 2.0+ | Multi-container orchestration |
| **Git** | 2.30+ | Version control |
| **Bash** | 4.0+ | Script execution |

**Supported Platforms:** Linux, macOS, Windows (WSL2)

### 🏠 Native Environment

| Component | Version | Purpose |
|-----------|---------|---------|
| **Java/JVM** | 17+ | Runtime environment |
| **SBT** | 1.9+ | Scala build tool |
| **Maven** | 3.9+ | Java examples (optional) |
| **Git** | 2.30+ | Version control |

**Supported Scala Versions:** 2.12.17, 2.13.14, 3.3.1

### 🎯 Minimum Requirements

```bash
# Check your system
./scripts/validate-setup.sh --category prerequisites

# Quick compatibility check  
docker --version && docker-compose --version && git --version
```

### 📊 Performance Recommendations

- **RAM:** 4GB+ (Docker), 2GB+ (Native)
- **Disk:** 2GB+ free space
- **Network:** Stable internet for downloading dependencies
- **CPU:** 2+ cores recommended for parallel compilation

---

## 🤝 Contributing

We welcome contributions! Here's how to get started:

### 🚀 Quick Contribution Setup

```bash
# 1. Fork and clone your fork
git clone https://github.com/YOUR-USERNAME/OBP-Scala-Library.git
cd OBP-Scala-Library

# 2. Set up development environment
./scripts/setup-credentials.sh --env docker
./scripts/validate-setup.sh

# 3. Create feature branch
git checkout -b feature/my-amazing-feature

# 4. Make changes and test
# Edit files in src/main/scala/
sbt +test
./scripts/validate-setup.sh

# 5. Submit pull request
git push origin feature/my-amazing-feature
# Then create PR on GitHub
```

### 🔍 Development Guidelines

- **🧪 Test coverage:** Ensure all changes are tested
- **📝 Documentation:** Update docs for user-facing changes  
- **🎨 Code style:** Follow existing Scala conventions
- **🔄 Cross-compilation:** Test across all Scala versions
- **✅ Validation:** Run `./scripts/validate-setup.sh` before submitting

### 📋 Pull Request Checklist

- [ ] Tests pass: `sbt +test`
- [ ] Validation passes: `./scripts/validate-setup.sh`  
- [ ] Documentation updated
- [ ] Examples work with changes
- [ ] Cross-compilation tested
- [ ] No hardcoded credentials

### 🐛 Reporting Issues

1. **Check existing issues** first
2. **Use our templates** for bug reports and feature requests
3. **Provide reproduction steps** for bugs
4. **Include system information** (`./scripts/validate-setup.sh` output)

---

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0**.

**Key Points:**
- ✅ **Commercial use** allowed
- ✅ **Modification** allowed  
- ✅ **Distribution** allowed
- ⚠️ **Network use** requires source disclosure
- ⚠️ **Same license** required for derivatives

See the [LICENSE](LICENSE) file for complete details.

---

## 🆘 Support

### 💬 Getting Help

| Issue Type | Best Channel | Response Time |
|------------|--------------|---------------|
| **🐛 Bugs** | [GitHub Issues](https://github.com/OpenBankProject/OBP-Scala-Library/issues) | 1-3 days |
| **❓ Questions** | [GitHub Discussions](https://github.com/OpenBankProject/OBP-Scala-Library/discussions) | 1-2 days |
| **💡 Feature Requests** | [GitHub Issues](https://github.com/OpenBankProject/OBP-Scala-Library/issues) | Review weekly |
| **🔒 Security Issues** | [Email Security Team](mailto:security@openbankproject.com) | 24 hours |

### 🔧 Self-Service Troubleshooting

```bash
# 1. Run comprehensive validation
./scripts/validate-setup.sh

# 2. Check specific components
./scripts/validate-setup.sh --category docker    # Docker issues
./scripts/validate-setup.sh --category security  # Credential issues  
./scripts/validate-setup.sh --category functional # Build issues

# 3. Test credentials
./scripts/test-credentials.sh

# 4. Fix common permission issues
./scripts/validate-setup.sh --fix-permissions
```

### 📚 Documentation Resources

- **🚀 Quick Start:** [CREDENTIALS_QUICKSTART.md](CREDENTIALS_QUICKSTART.md)
- **🐳 Docker Guide:** [docker/README.md](docker/README.md)
- **🔧 Troubleshooting:** [docker/TROUBLESHOOTING.md](docker/TROUBLESHOOTING.md)
- **🔐 Security:** [docs/CREDENTIALS.md](docs/CREDENTIALS.md)

### 🌐 Community

- **GitHub:** [OpenBankProject/OBP-Scala-Library](https://github.com/OpenBankProject/OBP-Scala-Library)
- **Website:** [openbankproject.com](https://www.openbankproject.com/)
- **Email:** [contact@openbankproject.com](mailto:contact@openbankproject.com)

---

<div align="center">

**🏦 Open Bank Project**  
*Building the future of open banking*

[![Website](https://img.shields.io/badge/🌐%20Website-openbankproject.com-blue)](https://www.openbankproject.com/)
[![GitHub](https://img.shields.io/badge/🐙%20GitHub-OpenBankProject-black)](https://github.com/OpenBankProject)
[![License](https://img.shields.io/badge/📄%20License-AGPL%20v3-red)](LICENSE)

*Made with ❤️ by the OBP community*

</div>