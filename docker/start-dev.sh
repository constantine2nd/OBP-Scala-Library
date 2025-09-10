#!/bin/bash

# OBP Scala Library Docker Development Environment Startup Script

set -e

echo "================================================================="
echo "    OBP Scala Library Docker Development Environment"
echo "================================================================="
echo ""

# Change to the docker directory (in case we're not already there)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📦 Building Docker images..."
docker-compose build sbt

echo ""
echo "🚀 Starting services..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check if containers are running
echo "🔍 Checking service status..."
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Error: Services failed to start properly"
    docker-compose logs
    exit 1
fi

echo "✅ Services are running!"
echo ""

# Function to run commands in container
run_sbt_command() {
    local cmd=$1
    local description=$2
    echo "🔨 $description..."
    if docker exec sbt bash -c "cd /workspace && $cmd"; then
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
run_sbt_command "sbt +compile" "Compiling for all Scala versions (2.12, 2.13, 3.3)"

# Test 3: Run tests for all Scala versions
run_sbt_command "sbt +test" "Running tests for all Scala versions"

# Test 4: Test local publishing (ivy repository)
run_sbt_command "sbt publishLocal" "Testing local Ivy publishing"

# Test 5: Test Maven-style publishing to local file repository
run_sbt_command "sbt publish" "Testing Maven-style publishing to local file repository"

# Test 6: Cross-platform publishing
run_sbt_command "sbt +publish" "Testing cross-platform publishing (all Scala versions)"

# Test 7: Check project info
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
echo "   - Nexus Repository: http://localhost:8081 (admin/admin123)"
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
echo "   • Currently using local file repository for publishing"
echo "   • To use Nexus: edit build.sbt and uncomment Nexus configuration"
echo "   • Nexus is available at http://localhost:8081 (admin/20b05303-d54d-434e-8aa6-48cc9ed3de20)"
echo ""
echo "💡 Quick commands to try:"
echo "   sbt +compile          # Compile for all Scala versions"
echo "   sbt +test            # Run tests for all Scala versions"
echo "   sbt publishLocal     # Publish to local Ivy repository"
echo "   sbt publish          # Publish to configured repository (currently local file)"
echo "   sbt +publish         # Cross-publish for all Scala versions"
echo "   sbt clean            # Clean build artifacts"
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
echo "================================================================="
