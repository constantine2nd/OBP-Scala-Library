#!/bin/bash

# OBP Scala Library Docker Development Environment Startup Script

set -e

echo "================================================================="
echo "    OBP Scala Library Docker Development Environment"
echo "================================================================="
echo ""
set -e

# Configuration defaults
SKIP_NEXUS_PUBLISH=false
SKIP_CROSS_COMPILE=false
SKIP_IVY_PUBLISH=false
SKIP_MAVEN_PUBLISH=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-nexus)
            SKIP_NEXUS_PUBLISH=true
            shift
            ;;
        --skip-cross)
            SKIP_CROSS_COMPILE=true
            shift
            ;;
        --skip-ivy)
            SKIP_IVY_PUBLISH=true
            shift
            ;;
        --skip-maven)
            SKIP_MAVEN_PUBLISH=true
            shift
            ;;
        --fast)
            SKIP_NEXUS_PUBLISH=true
            SKIP_CROSS_COMPILE=true
            SKIP_IVY_PUBLISH=true
            SKIP_MAVEN_PUBLISH=true
            shift
            ;;
        -h|--help)
            echo "OBP Scala Library Docker Development Environment"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-nexus     Skip time-consuming Nexus publishing tests"
            echo "  --skip-cross     Skip cross-compilation testing"
            echo "  --skip-ivy       Skip local Ivy publishing"
            echo "  --skip-maven     Skip local Maven repository publishing"
            echo "  --fast           Skip all optional tests (fastest)"
            echo "  -h, --help       Show this help message"
            echo ""
            echo "Performance Modes:"
            echo "  ./start-dev.sh                    Full comprehensive testing (~160s)"
            echo "  ./start-dev.sh --skip-nexus       Skip Nexus publishing (~70s)"
            echo "  ./start-dev.sh --skip-cross       Skip cross-compilation (~100s)"
            echo "  ./start-dev.sh --skip-ivy         Skip Ivy publishing (~40s)"
            echo "  ./start-dev.sh --skip-maven       Skip Maven publishing (~35s)"
            echo "  ./start-dev.sh --fast             Skip all optional tests (~20s)"
            echo ""
            echo "Examples:"
            echo "  ./start-dev.sh --fast             # Quick validation for development"
            echo "  ./start-dev.sh --skip-nexus       # Test all Scala versions, skip publishing"
            echo "  ./start-dev.sh                    # Full testing before production deploy"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "🔧 Configuration:"
echo "   • Nexus publishing: $([ "$SKIP_NEXUS_PUBLISH" = "true" ] && echo "SKIPPED (use without --skip-nexus to enable)" || echo "ENABLED")"
echo "   • Cross-compilation: $([ "$SKIP_CROSS_COMPILE" = "true" ] && echo "SKIPPED (use without --skip-cross to enable)" || echo "ENABLED")"
echo "   • Ivy publishing: $([ "$SKIP_IVY_PUBLISH" = "true" ] && echo "SKIPPED (use without --skip-ivy to enable)" || echo "ENABLED")"
echo "   • Maven publishing: $([ "$SKIP_MAVEN_PUBLISH" = "true" ] && echo "SKIPPED (use without --skip-maven to enable)" || echo "ENABLED")"
echo ""

# Change to the docker directory (in case we're not already there)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load environment variables
ENV_FILE="../.env"
if [ -f "$ENV_FILE" ]; then
    echo "📋 Loading environment variables from .env file..."
    # Export environment variables to make them available to subprocesses
    set -a
    source "$ENV_FILE"
    set +a
    echo "✅ Environment variables loaded and exported"
    echo "ℹ️  Using Nexus: ${NEXUS_URL:-http://localhost:8081/}"
    echo "ℹ️  Username: ${NEXUS_USERNAME:-not set}"
else
    echo "⚠️  Warning: .env file not found at $ENV_FILE"
    echo "   Some publishing tests may fail without proper credentials"
    echo "   Run '../scripts/setup-credentials.sh' to create the .env file"
    # Set default values when .env is missing
    export NEXUS_HOST="${NEXUS_HOST:-nexus}"
    export NEXUS_URL="${NEXUS_URL:-http://nexus:8081/}"
fi
echo ""

echo "📦 Building Docker images..."
docker-compose build sbt

echo ""
echo "🚀 Starting services..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."

# Wait for Nexus to be fully ready
echo "🔍 Waiting for Nexus to be ready..."
max_wait=120
wait_time=0

while [ $wait_time -lt $max_wait ]; do
    if curl -s -f "http://localhost:8081/service/rest/v1/status" >/dev/null 2>&1; then
        echo "✅ Nexus is ready to accept connections"
        break
    fi
    sleep 5
    wait_time=$((wait_time + 5))
    echo "   Waiting for Nexus... ($wait_time/${max_wait}s)"
done

if [ $wait_time -ge $max_wait ]; then
    echo "⚠️  Warning: Nexus may still be starting up, but proceeding with tests..."
fi

# Check if containers are running
echo "🔍 Checking service status..."
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Error: Services failed to start properly"
    docker-compose logs
    exit 1
fi

echo "✅ Services are running!"
echo ""

# Function to run commands in container with environment variables
run_sbt_command() {
    local cmd=$1
    local description=$2
    echo "🔨 $description..."

    # Environment variables are already loaded at script start
    # Use docker-compose run with environment variables (same approach as publish-all.sh)
    if docker-compose run --rm -T \
        -e NEXUS_USERNAME="${NEXUS_USERNAME:-}" \
        -e NEXUS_PASSWORD="${NEXUS_PASSWORD:-}" \
        -e NEXUS_HOST="${NEXUS_HOST:-nexus}" \
        -e NEXUS_URL="${NEXUS_URL:-http://nexus:8081/}" \
        sbt bash -c "cd /workspace && $cmd"; then
        echo "✅ $description completed successfully!"
    else
        echo "❌ $description failed!"
        return 1
    fi
    echo ""
}

# Comprehensive test suite
echo "🧪 Running comprehensive test suite..."
echo ""

# Test 1: Clean build
run_sbt_command "sbt clean" "Cleaning previous builds"

# Test 2: Compile for all Scala versions
if [ "$SKIP_CROSS_COMPILE" = "true" ]; then
    echo "⏩ Skipping cross-compilation (--skip-cross or --fast specified)"
    run_sbt_command "sbt compile" "Compiling for default Scala version"
else
    run_sbt_command "sbt +compile" "Compiling for all Scala versions (2.12, 2.13, 3.3)"
fi

# Test 3: Run tests for all Scala versions
if [ "$SKIP_CROSS_COMPILE" = "true" ]; then
    echo "⏩ Skipping cross-compilation tests (--skip-cross or --fast specified)"
    run_sbt_command "sbt test" "Running tests for default Scala version"
else
    run_sbt_command "sbt +test" "Running tests for all Scala versions"
fi

# Test 4: Test local publishing (ivy repository) - optional
if [ "$SKIP_IVY_PUBLISH" = "true" ]; then
    echo "⏩ Skipping local Ivy publishing (--skip-ivy or --fast specified)"
    echo ""
else
    run_sbt_command "sbt publishLocal" "Testing local Ivy publishing"
fi

# Test 4b: Test local Maven publishing - optional
if [ "$SKIP_MAVEN_PUBLISH" = "true" ]; then
    echo "⏩ Skipping local Maven publishing (--skip-maven or --fast specified)"
    echo ""
else
    run_sbt_command "sbt publishM2" "Testing local Maven repository publishing"
fi

# Test 5: Test Nexus connectivity and publishing (optional)
if [ "$SKIP_NEXUS_PUBLISH" = "true" ]; then
    echo "⏩ Skipping Nexus publishing tests (--skip-nexus or --fast specified)"
    echo "   This saves significant time. Use without --skip-nexus to test publishing."
    echo ""
else
    echo "🔍 Testing Nexus connectivity..."
    if curl -s -f "http://localhost:8081/service/rest/v1/status" >/dev/null 2>&1; then
        echo "✅ Nexus connectivity test passed"
        echo ""

        # Test 5a: Test Maven-style publishing to Nexus repository
        run_sbt_command "sbt publish" "Testing Maven-style publishing to Nexus repository"

        # Test 5b: Cross-platform publishing (only if not skipped)
        if [ "$SKIP_CROSS_COMPILE" = "false" ]; then
            run_sbt_command "sbt +publish" "Testing cross-platform publishing (all Scala versions)"
        else
            echo "⏩ Skipping cross-platform publishing (--skip-cross or --fast specified)"
            echo ""
        fi
    else
        echo "⚠️  Nexus connectivity test failed - skipping publish test"
        echo "   Note: This may be due to Nexus still starting up"
        echo ""
    fi
fi

# Test 6: Check project info
run_sbt_command "sbt 'show name' 'show version' 'show scalaVersion'" "Displaying project information"

echo "🎉 All tests passed! Your development environment is ready."
echo ""
echo "📋 Available commands:"
echo "   - Interactive shell: docker exec -it sbt bash"
echo "   - Run specific command: docker exec sbt bash -c 'cd /workspace && sbt <command>'"
echo "   - View logs: docker-compose logs"
echo "   - Stop services: docker-compose down"
echo ""
echo "🌐 Services:"
echo "   - Nexus Repository: http://localhost:8081 (admin/20b05303-d54d-434e-8aa6-48cc9ed3de20)"
echo ""
echo "📦 Published Artifacts:"
if [ -d "/workspace/target/local-repo" ]; then
    echo "   Local Maven repository: /workspace/target/local-repo"
    artifact_count=$(find /workspace/target/local-repo -name '*.jar' | wc -l)
    echo "   Total artifacts published: $artifact_count JAR files"
else
    echo "   No local repository found (run 'sbt publish' first)"
fi
echo ""
echo "🔧 Configuration Notes:"
echo "   • Currently using Nexus repository for publishing"
echo "   • Nexus is available at http://localhost:8081 (admin/20b05303-d54d-434e-8aa6-48cc9ed3de20)"
echo "   • Environment variables loaded from .env file for authentication"
echo "   • All publishing tests completed successfully"
echo ""
echo "💡 Quick commands to try:"
echo "   sbt +compile          # Compile for all Scala versions"
echo "   sbt +test            # Run tests for all Scala versions"
echo "   sbt clean            # Clean build artifacts"
echo ""
echo "📦 Publishing Commands & Locations:"
echo "┌─────────────────┬──────────────────────────────────────────────────────────┐"
echo "│ Command         │ Publishes To (on local machine)                         │"
echo "├─────────────────┼──────────────────────────────────────────────────────────┤"
echo "│ publishLocal    │ ~/.ivy2/local/ (Ivy format)                             │"
echo "│ publishM2       │ ~/.m2/repository/ (Maven format)                        │"
echo "│ publish         │ http://localhost:8081/repository/maven-snapshots/       │"
echo "│ +publish        │ All above for each Scala version (2.12, 2.13, 3.3)     │"
echo "└─────────────────┴──────────────────────────────────────────────────────────┘"
echo ""
echo "🎯 For Maven/Gradle projects: Use 'sbt +publishM2' to publish all Scala versions"
echo ""
echo "📝 Usage in your projects:"
echo "   Maven pom.xml:"
echo "   <dependency>"
echo "     <groupId>org.openbankproject</groupId>"
echo "     <artifactId>obp-scala-library_2.13</artifactId>"
echo "     <version>0.1.0-SNAPSHOT</version>"
echo "   </dependency>"
echo ""
echo "   Gradle build.gradle:"
echo "   implementation 'org.openbankproject:obp-scala-library_2.13:0.1.0-SNAPSHOT'"
echo ""
echo "📦 Local Maven Repository Locations:"
echo "   ~/.m2/repository/org/openbankproject/obp-scala-library_2.12/0.1.0-SNAPSHOT/"
echo "   ~/.m2/repository/org/openbankproject/obp-scala-library_2.13/0.1.0-SNAPSHOT/"
echo "   ~/.m2/repository/org/openbankproject/obp-scala-library_3/0.1.0-SNAPSHOT/"
echo ""
echo "🧪 Test Maven integration: cd ../test-maven-project && mvn compile exec:java"
echo ""

# Offer interactive session
read -p "🤔 Would you like to start an interactive session now? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔧 Starting interactive session..."
    echo "   Type 'exit' when you're done to return to host shell."
    echo ""
    docker exec -it sbt bash
    echo ""
    echo "👋 Interactive session ended."
else
    echo "🏁 Setup complete! Use the commands above to interact with your environment."
fi

echo ""
echo "📝 To stop all services when done: docker-compose down"
echo ""
echo "💡 Pro tips for faster development:"
echo "   ./start-dev.sh --fast          # Skip all optional tests (fastest)"
echo "   ./start-dev.sh --skip-nexus    # Skip only Nexus publishing"
echo "   ./start-dev.sh --skip-ivy      # Skip only Ivy publishing"
echo "   ./start-dev.sh --skip-maven    # Skip only Maven publishing"
echo "================================================================="
