#!/bin/bash

# Enhanced .env File Creation Script for OBP Scala Library
# This script creates a secure .env file with comprehensive validation and user guidance

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="OBP Scala Library Credentials Setup"

echo -e "${BLUE}🔐 $SCRIPT_NAME v$SCRIPT_VERSION${NC}"
echo "======================================================="
echo

# Function to print colored messages
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "${CYAN}📋 $1${NC}"; }

# Function to read input with default value and validation
read_with_default() {
    local prompt="$1"
    local default="$2"
    local is_password="$3"
    local validation_pattern="$4"
    local result

    while true; do
        if [ "$is_password" = "true" ]; then
            if [ -n "$default" ]; then
                read -s -p "$prompt [$default]: " result
            else
                read -s -p "$prompt: " result
            fi
            echo  # Add newline after password input
        else
            if [ -n "$default" ]; then
                read -p "$prompt [$default]: " result
            else
                read -p "$prompt: " result
            fi
        fi

        result="${result:-$default}"

        # Validation
        if [ -n "$validation_pattern" ]; then
            if [[ $result =~ $validation_pattern ]]; then
                echo "$result"
                return 0
            else
                log_error "Invalid input format. Please try again."
                continue
            fi
        fi

        if [ -n "$result" ]; then
            echo "$result"
            return 0
        else
            log_error "This field is required. Please provide a value."
        fi
    done
}

# Function to validate URL format
validate_url() {
    local url="$1"
    if [[ $url =~ ^https?://[a-zA-Z0-9.-]+:[0-9]+/?$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to test network connectivity
test_connectivity() {
    local host="$1"
    local port="$2"
    local timeout=5

    log_info "Testing connectivity to $host:$port..."

    if command -v nc >/dev/null 2>&1; then
        if timeout $timeout bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
            log_success "Successfully connected to $host:$port"
            return 0
        else
            log_warning "Cannot connect to $host:$port (this might be normal if service isn't running)"
            return 1
        fi
    elif command -v telnet >/dev/null 2>&1; then
        if echo | timeout $timeout telnet $host $port 2>/dev/null | grep -q "Connected"; then
            log_success "Successfully connected to $host:$port"
            return 0
        else
            log_warning "Cannot connect to $host:$port (this might be normal if service isn't running)"
            return 1
        fi
    else
        log_warning "Network testing tools (nc/telnet) not available, skipping connectivity test"
        return 0
    fi
}

# Parse command line arguments
USERNAME=""
PASSWORD=""
HOST=""
URL=""
ENVIRONMENT=""
FORCE_OVERWRITE=false
VALIDATE_CONNECTIVITY=true
INTERACTIVE=true

show_usage() {
    cat << EOF
Usage: $0 [options]

Options:
  -u, --username USERNAME    Nexus username (default: admin)
  -p, --password PASSWORD    Nexus password
  -h, --host HOST           Nexus host (default: nexus)
  --url URL                 Full Nexus URL (default: http://nexus:8081/)
  -e, --env ENVIRONMENT     Environment preset (docker|local|custom)
  -f, --force              Force overwrite existing .env file
  --no-connectivity-test   Skip connectivity testing
  --non-interactive        Non-interactive mode (requires all parameters)
  --help                   Show this help message
  --version                Show version information

Environment presets:
  docker: --host=nexus --url=http://nexus:8081/ (for Docker Compose setup)
  local:  --host=localhost --url=http://localhost:8081/ (for local Nexus)
  custom: Specify custom --host and --url values

Examples:
  # Interactive mode (recommended for first-time setup)
  $0

  # Quick Docker setup
  $0 --username admin --password mypass --env docker

  # Local Nexus setup
  $0 -u admin -p mypass --env local

  # Custom setup with validation
  $0 -u admin -p mypass -h nexus.example.com --url https://nexus.example.com:8443/

  # Non-interactive mode for automation
  $0 --non-interactive -u admin -p mypass --env docker --force

Security Notes:
  • Passwords are hidden during input
  • .env file permissions are set to 600 (owner only)
  • .env file is automatically added to .gitignore
  • No credentials are logged or displayed in plain text

EOF
}

show_version() {
    echo "$SCRIPT_NAME v$SCRIPT_VERSION"
    echo "Part of OBP Scala Library credential management system"
    echo "For more information, see: docs/CREDENTIALS.md"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            USERNAME="$2"
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -h|--host)
            HOST="$2"
            shift 2
            ;;
        --url)
            URL="$2"
            shift 2
            ;;
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -f|--force)
            FORCE_OVERWRITE=true
            shift
            ;;
        --no-connectivity-test)
            VALIDATE_CONNECTIVITY=false
            shift
            ;;
        --non-interactive)
            INTERACTIVE=false
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        --version)
            show_version
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo
            show_usage
            exit 1
            ;;
    esac
done

# Validate project root
if [ ! -f "$PROJECT_ROOT/build.sbt" ]; then
    log_error "build.sbt not found. Please run this script from the OBP Scala Library project root or scripts directory."
    exit 1
fi

# Apply environment presets
if [ -n "$ENVIRONMENT" ]; then
    log_step "Applying environment preset: $ENVIRONMENT"
    case "$ENVIRONMENT" in
        docker)
            HOST="${HOST:-nexus}"
            URL="${URL:-http://nexus:8081/}"
            log_info "Using Docker Compose environment configuration"
            ;;
        local)
            HOST="${HOST:-localhost}"
            URL="${URL:-http://localhost:8081/}"
            log_info "Using local development environment configuration"
            ;;
        custom)
            log_info "Using custom environment (requires --host and --url parameters)"
            ;;
        *)
            log_error "Unknown environment preset: $ENVIRONMENT"
            log_info "Valid presets: docker, local, custom"
            exit 1
            ;;
    esac
fi

# Set defaults
USERNAME="${USERNAME:-admin}"
HOST="${HOST:-nexus}"
URL="${URL:-http://nexus:8081/}"

# Validate URL format
if ! validate_url "$URL"; then
    log_error "Invalid URL format: $URL"
    log_info "Expected format: http://hostname:port/ or https://hostname:port/"
    exit 1
fi

# Check if .env file exists
if [ -f "$ENV_FILE" ]; then
    log_warning ".env file already exists at: $ENV_FILE"
    if [ "$FORCE_OVERWRITE" = "false" ]; then
        if [ "$INTERACTIVE" = "true" ]; then
            read -p "Do you want to overwrite it? (y/N): " overwrite
            if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
                log_info "Exiting without changes."
                exit 0
            fi
        else
            log_error "File exists and --force not specified. Use --force to overwrite."
            exit 1
        fi
    else
        log_info "Overwriting existing .env file (--force specified)"
    fi
fi

# Interactive prompts for missing values
if [ "$INTERACTIVE" = "true" ]; then
    echo
    log_step "Configuration Setup"
    echo "Please provide the following information:"
    echo

    USERNAME=$(read_with_default "Nexus Username" "$USERNAME" false "^[a-zA-Z0-9_.-]+$")

    if [ -z "$PASSWORD" ]; then
        echo
        log_info "Nexus password is required and will be hidden during input"
        PASSWORD=$(read_with_default "Nexus Password" "" true)
    fi

    HOST=$(read_with_default "Nexus Host" "$HOST" false "^[a-zA-Z0-9.-]+$")
    URL=$(read_with_default "Nexus URL" "$URL" false)

    # Re-validate URL after potential change
    if ! validate_url "$URL"; then
        log_error "Invalid URL format: $URL"
        exit 1
    fi
else
    # Non-interactive mode validation
    if [ -z "$PASSWORD" ]; then
        log_error "Password is required in non-interactive mode. Use --password or -p option."
        exit 1
    fi
fi

# Validate required parameters
if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$HOST" ] || [ -z "$URL" ]; then
    log_error "Missing required parameters."
    log_info "Required: username, password, host, url"
    exit 1
fi

# Test connectivity if requested
if [ "$VALIDATE_CONNECTIVITY" = "true" ]; then
    echo
    log_step "Connectivity Test"

    # Extract host and port from URL for testing
    if [[ $URL =~ ^https?://([^:]+):([0-9]+) ]]; then
        test_host="${BASH_REMATCH[1]}"
        test_port="${BASH_REMATCH[2]}"

        # Special handling for Docker environment
        if [ "$test_host" = "nexus" ] && [ "$ENVIRONMENT" = "docker" ]; then
            log_info "Docker environment detected. Checking if Nexus container is running..."
            if command -v docker >/dev/null 2>&1; then
                if docker ps | grep -q "nexus"; then
                    log_success "Nexus container is running"
                else
                    log_warning "Nexus container not running. You may need to start it with:"
                    echo "  cd docker && docker-compose up -d nexus"
                fi
            else
                log_warning "Docker not available for container status check"
            fi
        elif [ "$test_host" = "localhost" ] || [ "$test_host" = "127.0.0.1" ]; then
            test_connectivity "$test_host" "$test_port"
        fi
    else
        log_warning "Could not extract host/port from URL for connectivity testing"
    fi
fi

echo
log_step "Creating Configuration File"
log_info "Writing .env file with the following configuration:"
echo "  Username: $USERNAME"
echo "  Host: $HOST"
echo "  URL: $URL"
echo "  Password: [HIDDEN]"

# Create .env file with comprehensive header
cat > "$ENV_FILE" << EOF
# OBP Scala Library - Nexus Repository Credentials
# Generated on $(date) by $SCRIPT_NAME v$SCRIPT_VERSION
#
# ⚠️  SECURITY WARNING: This file contains sensitive credentials!
# • Do NOT commit this file to version control
# • Do NOT share this file with others
# • File permissions are set to 600 (owner read/write only)
# • This file is automatically added to .gitignore

# Authentication Credentials
NEXUS_USERNAME=$USERNAME
NEXUS_PASSWORD=$PASSWORD

# Connection Settings
NEXUS_HOST=$HOST
NEXUS_URL=$URL

# Environment Context
SETUP_DATE=$(date -Iseconds)
SETUP_ENVIRONMENT=${ENVIRONMENT:-manual}
SETUP_VERSION=$SCRIPT_VERSION

# Usage Examples:
#
# Load environment variables:
#   source .env
#
# Or use convenience script:
#   source ./source-env.sh
#
# Direct SBT usage:
#   source .env && sbt publish
#
# Docker Compose usage:
#   source .env && cd docker && docker-compose run --rm -T \\
#     -e NEXUS_USERNAME="\$NEXUS_USERNAME" \\
#     -e NEXUS_PASSWORD="\$NEXUS_PASSWORD" \\
#     -e NEXUS_HOST="\$NEXUS_HOST" \\
#     -e NEXUS_URL="\$NEXUS_URL" \\
#     sbt sbt publish
#
# Publish to all Scala versions:
#   ./scripts/publish-all.sh
EOF

# Set restrictive permissions
chmod 600 "$ENV_FILE"
log_success "Environment file created with secure permissions (600)"

# Ensure .env is in .gitignore
GITIGNORE_FILE="$PROJECT_ROOT/.gitignore"
if [ -f "$GITIGNORE_FILE" ]; then
    if ! grep -q "^\.env$" "$GITIGNORE_FILE"; then
        echo ".env" >> "$GITIGNORE_FILE"
        log_success "Added .env to .gitignore"
    else
        log_info ".env already protected by .gitignore"
    fi
else
    log_warning ".gitignore not found - consider adding .env to version control ignore"
fi

# Create enhanced convenience script
SOURCE_SCRIPT="$PROJECT_ROOT/source-env.sh"
cat > "$SOURCE_SCRIPT" << 'EOF'
#!/bin/bash
# Enhanced convenience script to source environment variables
# Generated by OBP Scala Library setup-credentials.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    # Check file permissions for security
    PERMS=$(stat -c "%a" "$ENV_FILE" 2>/dev/null || stat -f "%Lp" "$ENV_FILE" 2>/dev/null || echo "unknown")
    if [ "$PERMS" != "600" ] && [ "$PERMS" != "unknown" ]; then
        echo "⚠️  Warning: .env file permissions are $PERMS (should be 600)"
        echo "   Fix with: chmod 600 .env"
    fi

    # Source the environment file
    source "$ENV_FILE"

    # Verify required variables are set
    if [ -z "$NEXUS_USERNAME" ] || [ -z "$NEXUS_PASSWORD" ]; then
        echo "❌ Error: Environment variables not properly loaded"
        exit 1
    fi

    echo "✅ Environment variables loaded successfully"
    echo "   Username: ${NEXUS_USERNAME}"
    echo "   Host: ${NEXUS_HOST}"
    echo "   URL: ${NEXUS_URL%/*}/[credentials-protected]"

    # Show setup information if available
    if [ -n "$SETUP_DATE" ]; then
        echo "   Setup: ${SETUP_ENVIRONMENT:-manual} environment on ${SETUP_DATE}"
    fi
else
    echo "❌ .env file not found at: $ENV_FILE"
    echo "   Run ./scripts/setup-credentials.sh to create it"
    exit 1
fi
EOF

chmod +x "$SOURCE_SCRIPT"

# Ensure source-env.sh is also in .gitignore
if [ -f "$GITIGNORE_FILE" ]; then
    if ! grep -q "^source-env\.sh$" "$GITIGNORE_FILE"; then
        echo "source-env.sh" >> "$GITIGNORE_FILE"
        log_success "Added source-env.sh to .gitignore"
    fi
fi

echo
log_success "Setup completed successfully!"
echo
echo "📁 Created files:"
echo "   • $ENV_FILE (credentials)"
echo "   • $SOURCE_SCRIPT (convenience script)"
echo

log_step "Next Steps & Usage"
cat << EOF

1. 🔄 Load environment variables:
   source .env
   # or use the convenience script:
   source ./source-env.sh

2. 🧪 Test your setup:
   ./scripts/validate-setup.sh

3. 📦 Publish locally (recommended first step):
   source .env && sbt publishLocal

4. 🚀 Publish to all Scala versions:
   ./scripts/publish-all.sh

5. 🔍 Verify credentials work:
   source .env && sbt "show credentials"

🆘 Need help?
   • Quick guide: CREDENTIALS_QUICKSTART.md
   • Full documentation: docs/CREDENTIALS.md
   • Troubleshooting: ./scripts/validate-setup.sh

🔐 Security reminders:
   • Your .env file is protected by .gitignore
   • File permissions are set to 600 (owner only)
   • Never share or commit your credentials

EOF

log_success "🎉 Credential management setup complete!"
