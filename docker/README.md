# OBP Scala Library - Docker Development Environment

This Docker environment provides a complete **containerized** development setup for the OBP Scala Library with cross-compilation support for Scala 2.12, 2.13, and 3.3.

**⚠️ Important**: All commands in this document are for the **Docker environment only**. For native/local development, see the main [README.md](../README.md).

## 🚀 Quick Start

### One-Command Docker Setup (Recommended)

```bash
# From project root (Docker environment)
cd OBP-Scala-Library/docker
./start-dev.sh
```

This automated script:
- Builds Docker images
- Starts services (SBT + Nexus)
- Runs comprehensive tests
- Sets up repositories
- Verifies everything works

### Manual Docker Setup

```bash
# All commands for Docker environment
cd docker
docker-compose build sbt
docker-compose up -d
docker exec -it sbt bash
cd /workspace
sbt +compile +test
```

## 🏗️ Architecture

### Services

| Service | Purpose | Port | Access |
|---------|---------|------|--------|
| **sbt** | Scala build environment | - | `docker exec -it sbt bash` |
| **nexus** | Maven repository manager | 8081 | http://localhost:8081 |

### Containers

- **SBT Container**: OpenJDK 17 + SBT 1.9.0 + development tools
- **Nexus Container**: Sonatype Nexus Repository Manager 3

## 📦 Publishing Configuration

### Default: Local File Repository

Currently configured for development with no authentication required:

```scala
publishTo := Some(Resolver.file("local-repo", file("/workspace/target/local-repo")))
```

**Benefits:**
- No authentication needed
- Fast publishing
- Cross-platform artifacts stored locally

### Alternative: Nexus Repository

Switch to Nexus by uncommenting in `build.sbt`:

```scala
publishTo := {
  val nexus = "http://nexus:8081/"
  if (isSnapshot.value)
    Some(("snapshots" at nexus + "repository/maven-snapshots/").withAllowInsecureProtocol(true))
  else
    Some(("releases" at nexus + "repository/maven-releases/").withAllowInsecureProtocol(true))
}

credentials += Credentials("Sonatype Nexus Repository Manager", "nexus", "admin", "20b05303-d54d-434e-8aa6-48cc9ed3de20")
```

## 🛠️ Development Workflow

### Quick Docker Commands

```bash
# Start Docker services
docker-compose up -d

# Test all Scala versions (Docker)
docker exec sbt bash -c "cd /workspace && sbt +test"

# Publish artifacts (Docker)
docker exec sbt bash -c "cd /workspace && sbt +publish"

# Interactive development (Docker)
docker exec -it sbt bash
cd /workspace && sbt
```

### Step-by-Step Example Workflow

#### 1. Start Services
```bash
cd docker
docker-compose build sbt
docker-compose up -d
```

#### 2. Verify Services are Running
```bash
docker-compose ps
```

Expected output:
```
NAME      COMMAND                  SERVICE   STATUS       PORTS
nexus     "sh -c ${SONATYPE_DIR…"  nexus     running      0.0.0.0:8081->8081/tcp
sbt       "/bin/bash"              sbt       running
```

#### 3. Compile for All Scala Versions
```bash
docker exec sbt bash -c "cd /workspace && sbt +compile"
```

Expected output:
```
[info] Setting Scala version to 2.12.17 on 1 projects.
[info] compiling 1 Scala source to /workspace/target/scala-2.12/classes ...
[info] done compiling
[success] Total time: 12 s, completed ...

[info] Setting Scala version to 2.13.14 on 1 projects.
[info] compiling 1 Scala source to /workspace/target/scala-2.13/classes ...
[info] done compiling
[success] Total time: 9 s, completed ...

[info] Setting Scala version to 3.3.1 on 1 projects.
[info] compiling 1 Scala source to /workspace/target/scala-3.3.1/classes ...
[info] done compiling
[success] Total time: 6 s, completed ...
```

#### 4. Run Tests
```bash
docker exec sbt bash -c "cd /workspace && sbt +test"
```

Expected output:
```
[info] MyLibSpec:
[info] MyLib
[info] - should return correct greeting
[info] Run completed in 322 milliseconds.
[info] Total number of tests run: 1
[info] Suites: completed 1, aborted 0
[info] Tests: succeeded 1, failed 0, canceled 0, ignored 0, pending 0
[info] All tests passed.
```

#### 5. Publish Locally
```bash
docker exec sbt bash -c "cd /workspace && sbt +publishLocal"
```

### Interactive Docker Development Session

```bash
# Enter Docker container
docker exec -it sbt bash
cd /workspace
sbt

# In SBT shell (inside Docker container):
sbt> ~compile    # Auto-recompile on changes
sbt> ~test       # Auto-test on changes
sbt> console     # Scala REPL with project classpath
sbt> +compile    # Cross-compile all versions
```

## 📋 Common Docker Commands

### Docker Container Management
```bash
docker-compose up -d           # Start Docker services
docker-compose down            # Stop Docker services
docker-compose ps              # Check Docker container status
docker-compose logs sbt        # View SBT container logs
```

### SBT Operations (Inside Docker Container)
```bash
# Basic (run inside Docker container)
sbt clean                      # Clean build artifacts
sbt compile                    # Compile default Scala version
sbt test                       # Run tests
sbt publishLocal              # Publish to local Ivy

# Cross-compilation (inside Docker)
sbt +compile                  # Compile all Scala versions
sbt +test                     # Test all versions
sbt +publish                  # Publish all versions

# Utilities (inside Docker)
sbt console                   # Start Scala REPL
sbt dependencyTree           # Show dependency tree
sbt "testOnly *MyTest"        # Run specific test

# Or run from host:
docker exec sbt bash -c "cd /workspace && sbt <command>"
```

## 🔧 Configuration

### Supported Scala Versions
- **Scala 2.12.17** (JVM)
- **Scala 2.13.14** (JVM, default)
- **Scala 3.3.1** (JVM)

### Build Settings
```scala
crossScalaVersions := Seq("2.12.17", "2.13.14", "3.3.1")
organization := "org.openbankproject"
versionScheme := Some("early-semver")
```

## 🌐 Nexus Web Interface

- **URL**: http://localhost:8081
- **Username**: admin  
- **Password**: 20b05303-d54d-434e-8aa6-48cc9ed3de20

### Available Repositories
- `maven-central` (proxy) - Maven Central proxy
- `maven-releases` (hosted) - Release artifacts
- `maven-snapshots` (hosted) - Snapshot artifacts

## 🐛 Troubleshooting Guide

### Quick Fixes

#### "cd: docker: No such file or directory"
**Problem**: Trying to run `cd docker` when already in the docker directory.
**Solution**: 
```bash
# From project root
cd OBP-Scala-Library/docker
./start-dev.sh

# OR if you're already in the docker directory
./start-dev.sh
```

#### "Project loading failed"
**Problem**: SBT can't load the project due to configuration issues.
**Solution**:
```bash
# Clear SBT caches and reload
docker exec sbt bash -c "rm -rf ~/.ivy2/cache && rm -rf ~/.sbt"
docker exec sbt bash -c "cd /workspace && sbt reload"
```

#### "Container not accessible"
**Problem**: Can't connect to containers or services aren't responding.
**Solution**:
```bash
# Check if containers are running
docker-compose ps

# Restart services
docker-compose restart

# Or rebuild from scratch
docker-compose down --rmi all
docker-compose build --no-cache
docker-compose up -d
```

#### SBT Plugin Dependency Errors
**Problem**: Seeing errors like "Error downloading com.jsuereth:sbt-pgp" or similar plugin issues.
**Solution**:
```bash
# Clear SBT caches
docker exec sbt bash -c "rm -rf ~/.ivy2/cache && rm -rf ~/.sbt"

# Restart SBT
docker exec sbt bash -c "cd /workspace && sbt"
```

#### "insecure HTTP request is unsupported"
**Problem**: SBT complains about HTTP (non-HTTPS) repositories.
**Solution**: This is already fixed in the current `build.sbt`. If you still see this error, make sure your `build.sbt` contains:
```scala
publishTo := Some(("Local Nexus" at "http://nexus:8081/repository/maven-releases/").withAllowInsecureProtocol(true))
```

#### Publishing Issues
**Problem**: Publishing fails with connection or authentication errors.
**Solution**:
```bash
# Check current repository configuration
docker exec sbt bash -c "cd /workspace && sbt 'show publishTo'"

# Verify published artifacts
find /workspace/target/local-repo -name '*.jar' | sort

# Test network connectivity between containers
docker exec sbt ping nexus
```

#### "the input device is not a TTY"
**Problem**: Trying to run interactive commands without proper TTY allocation.
**Solution**: Use `-it` flags properly:
```bash
# Correct
docker exec -it sbt bash

# For non-interactive commands
docker exec sbt bash -c "cd /workspace && sbt compile"
```

#### Can't Access Nexus Web UI
**Problem**: http://localhost:8081 not accessible.
**Solution**:
```bash
# Check if Nexus container is running
docker-compose ps

# Check Nexus logs
docker-compose logs nexus

# Wait for Nexus to fully start (can take 2-3 minutes)
docker exec nexus bash -c "tail -f /nexus-data/log/nexus.log"
```

#### Performance Issues
- **Slow compilation**: Increase Docker memory in Docker Desktop settings
- **Out of memory**: Add `ENV SBT_OPTS="-Xmx2G -Xms1G"` to sbt/Dockerfile
- **Keep SBT session alive**: Start persistent session with `docker exec -it sbt bash -c "cd /workspace && sbt"`

#### File Permission Issues
**Problem**: "Permission denied" errors between host and container.
**Solution**:
```bash
# Fix ownership of generated files
docker exec sbt bash -c "chown -R $(id -u):$(id -g) /workspace/target"
```

### Complete Reset Procedure

If you're experiencing persistent issues, try a complete reset:

```bash
# Stop and remove all containers
docker-compose down --rmi all --volumes

# Remove any dangling images
docker system prune -f

# Rebuild everything from scratch
docker-compose build --no-cache
docker-compose up -d
```

### Debug Mode

To enable verbose logging and debug information:

```bash
# Enable SBT debug mode
docker exec sbt bash -c "cd /workspace && sbt -v compile"

# Check container logs
docker-compose logs -f sbt

# Interactive debugging session
docker exec -it sbt bash
cd /workspace
sbt
```

## 📊 Docker Environment Verification

### Test Docker Environment Works
```bash
# Run complete Docker setup and test
./start-dev.sh
```

Expected results:
- ✅ Docker containers start successfully
- ✅ Cross-compilation succeeds (2.12, 2.13, 3.3)
- ✅ All tests pass
- ✅ Publishing works (12 artifacts generated)

### Manual Docker Verification
```bash
# Check published artifacts (inside Docker container)
docker exec sbt bash -c "find /workspace/target/local-repo -name '*.jar' | wc -l"  # Should return 12

# Test cross-compilation (Docker)
docker exec sbt bash -c "cd /workspace && sbt +compile"

# Verify Nexus connectivity (from host)
curl -u admin:20b05303-d54d-434e-8aa6-48cc9ed3de20 http://localhost:8081/service/rest/v1/status

# Test Scala example app (Docker)
docker exec sbt bash -c "cd /workspace/scala-example-app && sbt run"
```

## 📁 File Structure

```
docker/
├── start-dev.sh                 # Main startup script
├── setup-nexus-enhanced.sh      # Nexus configuration
├── docker-compose.yml           # Service definitions
├── sbt/Dockerfile              # SBT container definition
└── README.md                   # This comprehensive guide
```

## 🚀 Next Steps (Docker Environment)

1. **Development**: Edit code on host with your preferred IDE (files are mounted)
2. **Testing**: Use `docker exec sbt bash -c "cd /workspace && sbt +test"` for testing  
3. **Publishing**: Artifacts auto-published to local repository in Docker
4. **CI/CD**: GitHub Actions workflow ready for automated publishing
5. **Production**: Switch to HTTPS repositories for production use

**Note**: For native/local development without Docker, see the main [README.md](../README.md).

## 📞 Support

- **Common Issues**: See the Troubleshooting Guide section above
- **Logs**: Use `docker-compose logs [service]`
- **Debug**: Use `docker exec -it sbt bash` for interactive troubleshooting
- **Reset**: Use the Complete Reset Procedure if all else fails

---

**Status**: ✅ **Docker Environment Production Ready**

This Docker environment provides a fully functional, containerized, cross-platform Scala development setup with working compilation, testing, and publishing for all supported Scala versions.

**For native development**: See the main [README.md](../README.md) for local setup instructions.