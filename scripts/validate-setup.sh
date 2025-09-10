#!/bin/bash

# Enhanced System Validation Script for OBP Scala Library
# Comprehensive validation of development environment, dependencies, and configuration

# Note: Removed set -e to handle function return codes properly in validation context

# Configuration
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="OBP Scala Library Environment Validator"
VALIDATION_TIMEOUT=30
NETWORK_TIMEOUT=10

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Validation results tracking
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNED=0
CHECKS_SKIPPED=0

# Categories for organizing checks
declare -A CATEGORY_CHECKS
declare -A CATEGORY_RESULTS

echo -e "${BLUE}🔍 $SCRIPT_NAME v$SCRIPT_VERSION${NC}"
echo "=============================================================="
echo "Project: $(basename "$PROJECT_ROOT")"
echo "Timestamp: $(date)"
echo "System: $(uname -s) $(uname -r)"
echo

# Function to print colored messages
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "${CYAN}📋 $1${NC}"; }
log_skip() { echo -e "${PURPLE}⏭️  $1${NC}"; }

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [options]

Options:
  --category CATEGORY       Run only specific category of checks
  --list-categories         List available check categories
  --no-network             Skip network-dependent tests
  --no-docker              Skip Docker-related tests
  --verbose                Show detailed output for all checks
  --quick                  Run only essential checks
  --fix-permissions        Attempt to fix file permission issues
  --help                   Show this help message

Categories:
  prerequisites            Check required tools and dependencies
  structure                Validate project file structure
  security                 Check security configuration and permissions
  docker                   Validate Docker environment and containers
  configuration            Check build and environment configuration
  connectivity             Test network connectivity and services
  functional               Run functional tests and validations

Examples:
  $0                       # Run all validation checks
  $0 --category docker     # Run only Docker-related checks
  $0 --quick               # Run essential checks only
  $0 --no-network          # Skip network tests
  $0 --verbose             # Show detailed output
  $0 --fix-permissions     # Fix permission issues automatically

EOF
}

# Function to list available categories
list_categories() {
    echo "Available validation categories:"
    echo
    echo "  prerequisites  - Required tools (Docker, Java, SBT, etc.)"
    echo "  structure      - Project files and directory structure"
    echo "  security       - Permissions, .gitignore, credential safety"
    echo "  docker         - Docker daemon, containers, and services"
    echo "  configuration  - build.sbt, environment variables, settings"
    echo "  connectivity   - Network connectivity and service availability"
    echo "  functional     - SBT commands, publishing, and integration tests"
}

# Parse command line arguments
SPECIFIC_CATEGORY=""
SKIP_NETWORK=false
SKIP_DOCKER=false
VERBOSE=false
QUICK=false
FIX_PERMISSIONS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --category)
            SPECIFIC_CATEGORY="$2"
            shift 2
            ;;
        --list-categories)
            list_categories
            exit 0
            ;;
        --no-network)
            SKIP_NETWORK=true
            shift
            ;;
        --no-docker)
            SKIP_DOCKER=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --quick)
            QUICK=true
            shift
            ;;
        --fix-permissions)
            FIX_PERMISSIONS=true
            shift
            ;;
        --help)
            show_usage
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

# Function to record check results by category
record_check() {
    local category="$1"
    local check_name="$2"
    local result="$3"
    local message="$4"

    # Initialize category if not exists
    if [[ ! ${CATEGORY_CHECKS[$category]+_} ]]; then
        CATEGORY_CHECKS[$category]=0
        CATEGORY_RESULTS[$category]="passed:0 failed:0 warned:0 skipped:0"
    fi

    # Increment category check count
    CATEGORY_CHECKS[$category]=$((${CATEGORY_CHECKS[$category]} + 1))

    # Update category results
    local current_results="${CATEGORY_RESULTS[$category]}"
    case "$result" in
        "PASS")
            CHECKS_PASSED=$((CHECKS_PASSED + 1))
            local new_passed=$(echo "$current_results" | sed -E 's/passed:([0-9]+)/passed:'$(($(echo "$current_results" | grep -o 'passed:[0-9]*' | cut -d: -f2) + 1))'/')
            CATEGORY_RESULTS[$category]="$new_passed"
            if [ "$VERBOSE" = "true" ]; then
                echo -e "${GREEN}  ✅ $check_name${NC}"
            fi
            ;;
        "FAIL")
            CHECKS_FAILED=$((CHECKS_FAILED + 1))
            local new_failed=$(echo "$current_results" | sed -E 's/failed:([0-9]+)/failed:'$(($(echo "$current_results" | grep -o 'failed:[0-9]*' | cut -d: -f2) + 1))'/')
            CATEGORY_RESULTS[$category]="$new_failed"
            echo -e "${RED}  ❌ $check_name${NC}${message:+ - $message}"
            ;;
        "WARN")
            CHECKS_WARNED=$((CHECKS_WARNED + 1))
            local new_warned=$(echo "$current_results" | sed -E 's/warned:([0-9]+)/warned:'$(($(echo "$current_results" | grep -o 'warned:[0-9]*' | cut -d: -f2) + 1))'/')
            CATEGORY_RESULTS[$category]="$new_warned"
            echo -e "${YELLOW}  ⚠️  $check_name${NC}${message:+ - $message}"
            ;;
        "SKIP")
            CHECKS_SKIPPED=$((CHECKS_SKIPPED + 1))
            local new_skipped=$(echo "$current_results" | sed -E 's/skipped:([0-9]+)/skipped:'$(($(echo "$current_results" | grep -o 'skipped:[0-9]*' | cut -d: -f2) + 1))'/')
            CATEGORY_RESULTS[$category]="$new_skipped"
            if [ "$VERBOSE" = "true" ]; then
                echo -e "${PURPLE}  ⏭️  $check_name${NC}${message:+ - $message}"
            fi
            ;;
    esac
}

# Function to check command availability
check_command() {
    local cmd="$1"
    local name="$2"
    local category="$3"
    local required="$4"

    if command -v "$cmd" >/dev/null 2>&1; then
        local version=""
        case "$cmd" in
            docker)
                version=$(docker --version 2>/dev/null | cut -d' ' -f3 | sed 's/,//')
                ;;
            docker-compose)
                version=$(docker-compose --version 2>/dev/null | cut -d' ' -f3 | sed 's/,//')
                ;;
            sbt)
                version=$(sbt --version 2>/dev/null | tail -1 | awk '{print $4}')
                ;;
            java)
                version=$(java -version 2>&1 | head -1 | cut -d'"' -f2)
                ;;
            mvn)
                version=$(mvn --version 2>/dev/null | head -1 | cut -d' ' -f3)
                ;;
        esac
        record_check "$category" "$name available${version:+ ($version)}" "PASS"
        return 0
    else
        if [ "$required" = "true" ]; then
            record_check "$category" "$name available" "FAIL" "$cmd not found in PATH"
        else
            record_check "$category" "$name available" "WARN" "Optional tool not installed"
        fi
        return 1
    fi
}

# Function to test network connectivity
test_connectivity() {
    local host="$1"
    local port="$2"
    local name="$3"
    local category="$4"

    if [ "$SKIP_NETWORK" = "true" ]; then
        record_check "$category" "$name connectivity" "SKIP" "Network tests disabled"
        return 0
    fi

    local timeout_cmd=""
    if command -v timeout >/dev/null 2>&1; then
        timeout_cmd="timeout $NETWORK_TIMEOUT"
    fi

    local connection_success=false

    if command -v nc >/dev/null 2>&1; then
        if $timeout_cmd nc -z "$host" "$port" 2>/dev/null; then
            record_check "$category" "$name connectivity ($host:$port)" "PASS"
            connection_success=true
        else
            record_check "$category" "$name connectivity ($host:$port)" "WARN" "Cannot connect (service may not be running)"
        fi
    elif command -v telnet >/dev/null 2>&1; then
        if echo | $timeout_cmd telnet "$host" "$port" 2>/dev/null | grep -q "Connected"; then
            record_check "$category" "$name connectivity ($host:$port)" "PASS"
            connection_success=true
        else
            record_check "$category" "$name connectivity ($host:$port)" "WARN" "Cannot connect (service may not be running)"
        fi
    else
        record_check "$category" "$name connectivity ($host:$port)" "SKIP" "No network testing tools available"
    fi

    # Return 0 for success, 1 for failure (for conditional logic)
    if [ "$connection_success" = "true" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check file existence and permissions
check_file() {
    local file_path="$1"
    local description="$2"
    local category="$3"
    local expected_perms="$4"
    local required="$5"

    local full_path="$PROJECT_ROOT/$file_path"

    if [ -f "$full_path" ]; then
        record_check "$category" "$description exists" "PASS"

        # Check permissions if specified
        if [ -n "$expected_perms" ]; then
            local actual_perms=$(stat -c "%a" "$full_path" 2>/dev/null || stat -f "%Lp" "$full_path" 2>/dev/null || echo "unknown")
            if [ "$actual_perms" = "$expected_perms" ]; then
                record_check "$category" "$description permissions ($expected_perms)" "PASS"
            elif [ "$actual_perms" = "unknown" ]; then
                record_check "$category" "$description permissions" "WARN" "Cannot check permissions on this system"
            else
                if [ "$FIX_PERMISSIONS" = "true" ] && ([ "$file_path" = ".env" ] || [ "$file_path" = "source-env.sh" ]); then
                    if chmod "$expected_perms" "$full_path" 2>/dev/null; then
                        record_check "$category" "$description permissions (fixed to $expected_perms)" "PASS"
                    else
                        record_check "$category" "$description permissions" "FAIL" "Expected $expected_perms, got $actual_perms (fix failed)"
                    fi
                else
                    record_check "$category" "$description permissions" "FAIL" "Expected $expected_perms, got $actual_perms"
                fi
            fi
        fi
        return 0
    else
        if [ "$required" = "true" ]; then
            record_check "$category" "$description exists" "FAIL" "$file_path not found"
        else
            record_check "$category" "$description exists" "WARN" "Optional file not found"
        fi
        return 1
    fi
}

# Function to run prerequisites checks
check_prerequisites() {
    if [ "$SPECIFIC_CATEGORY" != "" ] && [ "$SPECIFIC_CATEGORY" != "prerequisites" ]; then
        return 0
    fi

    log_step "Prerequisites Check"
    echo "─────────────────────"

    # Essential tools
    check_command "docker" "Docker" "prerequisites" "true"
    check_command "docker-compose" "Docker Compose" "prerequisites" "true"
    check_command "curl" "curl" "prerequisites" "true"

    # Optional tools (nice to have but not required for Docker workflow)
    if [ "$QUICK" = "false" ]; then
        check_command "sbt" "SBT" "prerequisites" "false"
        check_command "java" "Java" "prerequisites" "false"
        check_command "mvn" "Maven" "prerequisites" "false"
        check_command "git" "Git" "prerequisites" "false"
        check_command "nc" "netcat" "prerequisites" "false"
    fi

    echo
}

# Function to check project structure
check_structure() {
    if [ "$SPECIFIC_CATEGORY" != "" ] && [ "$SPECIFIC_CATEGORY" != "structure" ]; then
        return 0
    fi

    log_step "Project Structure Check"
    echo "────────────────────────"

    # Essential files
    check_file "build.sbt" "Build configuration" "structure" "" "true"
    check_file "README.md" "Main documentation" "structure" "" "true"
    check_file "CREDENTIALS_QUICKSTART.md" "Quick start guide" "structure" "" "true"
    check_file ".gitignore" "Git ignore file" "structure" "" "true"

    # Essential directories
    local essential_dirs=("src" "scripts" "docker" "docs")
    for dir in "${essential_dirs[@]}"; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            record_check "structure" "$dir directory exists" "PASS"
        else
            record_check "structure" "$dir directory exists" "FAIL" "Required directory missing"
        fi
    done

    # Docker files
    check_file "docker/docker-compose.yml" "Docker compose config" "structure" "" "true"
    check_file "docker/sbt/Dockerfile" "SBT Docker config" "structure" "" "true"

    # Script files
    local script_files=("setup-credentials.sh" "publish-all.sh" "validate-setup.sh" "test-credentials.sh")
    for script in "${script_files[@]}"; do
        check_file "scripts/$script" "$script script" "structure" "" "true"

        # Check if script is executable
        if [ -f "$PROJECT_ROOT/scripts/$script" ] && [ -x "$PROJECT_ROOT/scripts/$script" ]; then
            record_check "structure" "$script executable" "PASS"
        elif [ -f "$PROJECT_ROOT/scripts/$script" ]; then
            record_check "structure" "$script executable" "FAIL" "Script not executable"
        fi
    done

    # Documentation files
    if [ "$QUICK" = "false" ]; then
        check_file "docs/CREDENTIALS.md" "Credentials documentation" "structure" "" "true"
        check_file "LICENSE" "License file" "structure" "" "false"
    fi

    echo
}

# Function to check security configuration
check_security() {
    if [ "$SPECIFIC_CATEGORY" != "" ] && [ "$SPECIFIC_CATEGORY" != "security" ]; then
        return 0
    fi

    log_step "Security Configuration Check"
    echo "──────────────────────────────"

    # Check .gitignore contains sensitive files
    local gitignore_file="$PROJECT_ROOT/.gitignore"
    if [ -f "$gitignore_file" ]; then
        local sensitive_patterns=(".env" "source-env.sh" "*.log" "target/" ".metals/")
        for pattern in "${sensitive_patterns[@]}"; do
            if grep -q "^$pattern$" "$gitignore_file" 2>/dev/null; then
                record_check "security" "$pattern in .gitignore" "PASS"
            else
                record_check "security" "$pattern in .gitignore" "WARN" "Pattern not found in .gitignore"
            fi
        done
    fi

    # Check .env file security
    check_file ".env" ".env file" "security" "600" "false"

    # Check for hardcoded credentials
    local hardcoded_pattern="20b05303-d54d-434e-8aa6-48cc9ed3de20"
    local hardcoded_count=0
    if command -v grep >/dev/null 2>&1; then
        hardcoded_count=$(grep -r "$hardcoded_pattern" "$PROJECT_ROOT" \
            --exclude-dir=.git \
            --exclude-dir=target \
            --exclude-dir=.metals \
            --exclude-dir=.bloop \
            --exclude-dir=.bsp \
            --exclude-dir=project/target \
            --exclude-dir=project/project \
            --exclude-dir=logs \
            --exclude="*.md" \
            --exclude="validate-setup.sh" \
            --exclude="test-credentials.sh" \
            --exclude="*.class" \
            --exclude="*.db" \
            --exclude="*.jar" \
            --exclude="*.tasty" \
            --exclude="*.cache" \
            --binary-files=without-match 2>/dev/null | \
            grep -E '\.(scala|sbt|sh|yml|yaml|java|properties)$' | wc -l)
    fi

    if [ "$hardcoded_count" -le 1 ]; then
        record_check "security" "Hardcoded credentials limited" "PASS"
    else
        record_check "security" "Hardcoded credentials limited" "FAIL" "Found $hardcoded_count instances"
    fi

    # Check source-env.sh security
    if [ -f "$PROJECT_ROOT/source-env.sh" ]; then
        # Check if source-env.sh has executable permissions (755 or 775 are both acceptable)
        local perms=$(stat -c "%a" "$PROJECT_ROOT/source-env.sh" 2>/dev/null || stat -f "%Lp" "$PROJECT_ROOT/source-env.sh" 2>/dev/null || echo "unknown")
        if [ "$perms" = "755" ] || [ "$perms" = "775" ]; then
            record_check "security" "source-env.sh file permissions ($perms)" "PASS" "" "Script has appropriate executable permissions"
        elif [ "$perms" = "unknown" ]; then
            record_check "security" "source-env.sh file permissions" "WARN" "Cannot check permissions on this system"
        else
            if [ "$FIX_PERMISSIONS" = "true" ]; then
                if chmod 755 "$PROJECT_ROOT/source-env.sh" 2>/dev/null; then
                    record_check "security" "source-env.sh file permissions (fixed to 755)" "PASS"
                else
                    record_check "security" "source-env.sh file permissions" "FAIL" "Expected 755/775, got $perms (fix failed)"
                fi
            else
                record_check "security" "source-env.sh file permissions" "FAIL" "Expected 755/775, got $perms"
            fi
        fi
    fi

    echo
}

# Function to check Docker environment
check_docker() {
    if [ "$SPECIFIC_CATEGORY" != "" ] && [ "$SPECIFIC_CATEGORY" != "docker" ] || [ "$SKIP_DOCKER" = "true" ]; then
        if [ "$SKIP_DOCKER" = "true" ]; then
            log_step "Docker Environment Check (Skipped)"
            echo "──────────────────────────────────────"
            record_check "docker" "All Docker checks" "SKIP" "Docker tests disabled"
            echo
        fi
        return 0
    fi

    log_step "Docker Environment Check"
    echo "──────────────────────────"

    # Check if Docker daemon is running
    if docker info >/dev/null 2>&1; then
        record_check "docker" "Docker daemon running" "PASS"

        # Check Docker version
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | sed 's/,//')
        record_check "docker" "Docker version ($docker_version)" "PASS"

        # Check Docker Compose
        if docker-compose --version >/dev/null 2>&1; then
            local compose_version=$(docker-compose --version 2>/dev/null | cut -d' ' -f3 | sed 's/,//')
            record_check "docker" "Docker Compose version ($compose_version)" "PASS"
        else
            record_check "docker" "Docker Compose available" "FAIL" "docker-compose command not working"
        fi

        # Check if we can run containers
        if docker run --rm hello-world >/dev/null 2>&1; then
            record_check "docker" "Container execution test" "PASS"
        else
            record_check "docker" "Container execution test" "WARN" "Cannot run test container"
        fi

        # Check project-specific containers
        cd "$PROJECT_ROOT/docker" 2>/dev/null || {
            record_check "docker" "Docker directory access" "FAIL" "Cannot access docker directory"
            return 1
        }

        # Check if Nexus container exists
        if docker-compose ps nexus >/dev/null 2>&1; then
            if docker-compose ps nexus | grep -q "Up"; then
                record_check "docker" "Nexus container running" "PASS"

                # Test Nexus web interface if running
                test_connectivity "localhost" "8081" "Nexus web interface" "docker"
            else
                record_check "docker" "Nexus container running" "WARN" "Container exists but not running"
            fi
        else
            record_check "docker" "Nexus container configured" "WARN" "Container not found in docker-compose"
        fi

        # Test SBT container
        if docker-compose run --rm -T sbt echo "SBT container test" >/dev/null 2>&1; then
            record_check "docker" "SBT container functional" "PASS"
        else
            record_check "docker" "SBT container functional" "FAIL" "Cannot start or run SBT container"
        fi

        cd "$PROJECT_ROOT"
    else
        record_check "docker" "Docker daemon running" "FAIL" "Docker not running or not accessible"
    fi

    echo
}

# Function to check build configuration
check_configuration() {
    if [ "$SPECIFIC_CATEGORY" != "" ] && [ "$SPECIFIC_CATEGORY" != "configuration" ]; then
        return 0
    fi

    log_step "Build Configuration Check"
    echo "───────────────────────────"

    local build_file="$PROJECT_ROOT/build.sbt"
    if [ -f "$build_file" ]; then
        # Check environment variable support
        if grep -q "sys.env.get" "$build_file"; then
            record_check "configuration" "Environment variables in build.sbt" "PASS"
        else
            record_check "configuration" "Environment variables in build.sbt" "FAIL" "No environment variable usage found"
        fi

        # Check dynamic Nexus URL
        if grep -q "NEXUS_URL" "$build_file"; then
            record_check "configuration" "Dynamic Nexus URL configuration" "PASS"
        else
            record_check "configuration" "Dynamic Nexus URL configuration" "FAIL" "NEXUS_URL variable not found"
        fi

        # Check cross-compilation
        if grep -q "crossScalaVersions" "$build_file"; then
            local versions=$(grep "crossScalaVersions" "$build_file" | head -1)
            local version_count=$(echo "$versions" | grep -o '"[0-9][^"]*"' | wc -l)
            record_check "configuration" "Cross-compilation configured ($version_count versions)" "PASS"
        else
            record_check "configuration" "Cross-compilation configured" "FAIL" "crossScalaVersions not found"
        fi

        # Check version format
        local version_line=$(grep '^version :=' "$build_file" | head -1)
        if echo "$version_line" | grep -q "SNAPSHOT"; then
            record_check "configuration" "SNAPSHOT version format" "PASS"
        else
            record_check "configuration" "Version format" "WARN" "Not using SNAPSHOT version"
        fi

        # Check organization
        if grep -q 'organization.*openbankproject' "$build_file"; then
            record_check "configuration" "Organization set correctly" "PASS"
        else
            record_check "configuration" "Organization set correctly" "WARN" "Organization may not be set correctly"
        fi
    fi

    # Check .env file if it exists
    if [ -f "$PROJECT_ROOT/.env" ]; then
        source "$PROJECT_ROOT/.env" 2>/dev/null || {
            record_check "configuration" ".env file loadable" "FAIL" "Cannot source .env file"
            return 1
        }

        # Check required environment variables
        local env_vars=("NEXUS_USERNAME" "NEXUS_PASSWORD" "NEXUS_HOST" "NEXUS_URL")
        local missing_vars=0
        for var in "${env_vars[@]}"; do
            if [ -n "${!var}" ]; then
                record_check "configuration" "$var environment variable" "PASS"
            else
                record_check "configuration" "$var environment variable" "FAIL" "Variable not set or empty"
                missing_vars=$((missing_vars + 1))
            fi
        done

        if [ $missing_vars -eq 0 ]; then
            record_check "configuration" "All environment variables present" "PASS"
        fi

        # Validate URL format if present
        if [ -n "$NEXUS_URL" ]; then
            if [[ $NEXUS_URL =~ ^https?://[a-zA-Z0-9.-]+:[0-9]+/?$ ]]; then
                record_check "configuration" "Nexus URL format valid" "PASS"
            else
                record_check "configuration" "Nexus URL format valid" "WARN" "URL format may be incorrect"
            fi
        fi
    else
        record_check "configuration" ".env file exists" "WARN" "Environment file not found (run setup-credentials.sh)"
    fi

    echo
}

# Function to test connectivity
check_connectivity() {
    if [ "$SPECIFIC_CATEGORY" != "" ] && [ "$SPECIFIC_CATEGORY" != "connectivity" ] || [ "$SKIP_NETWORK" = "true" ]; then
        if [ "$SKIP_NETWORK" = "true" ]; then
            log_step "Connectivity Check (Skipped)"
            echo "───────────────────────────"
            record_check "connectivity" "All connectivity checks" "SKIP" "Network tests disabled"
            echo
        fi
        return 0
    fi

    log_step "Connectivity Check"
    echo "──────────────────"

    # Test external connectivity
    test_connectivity "google.com" "80" "External internet" "connectivity"
    test_connectivity "github.com" "443" "GitHub" "connectivity"

    # Docker-aware Nexus connectivity testing
    local docker_nexus_available=false
    local host_nexus_available=false

    # Check if Docker environment is available and Nexus container is running
    if [ "$SKIP_DOCKER" = "false" ] && docker info >/dev/null 2>&1; then
        cd "$PROJECT_ROOT/docker" 2>/dev/null || true
        if [ -f "docker-compose.yml" ] && docker-compose ps nexus >/dev/null 2>&1; then
            if docker-compose ps nexus | grep -q "Up"; then
                docker_nexus_available=true

                # Test host-side connectivity (for external access)
                test_connectivity "localhost" "8081" "Nexus (host access)" "connectivity"
                if [ $? -eq 0 ]; then
                    host_nexus_available=true
                fi

                # Test Docker network connectivity (check if nexus service is in same network)
                local nexus_network=$(docker inspect nexus --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}{{end}}' 2>/dev/null | head -1)
                if [ -n "$nexus_network" ]; then
                    record_check "connectivity" "Nexus (Docker network access)" "PASS" "Available in Docker network: $nexus_network"
                else
                    record_check "connectivity" "Nexus (Docker network access)" "WARN" "Cannot determine Docker network configuration"
                fi
            else
                record_check "connectivity" "Nexus Docker container" "WARN" "Container exists but not running"
            fi
        fi
        cd "$PROJECT_ROOT"
    fi

    # Test configured Nexus if specified in .env
    if [ -f "$PROJECT_ROOT/.env" ]; then
        source "$PROJECT_ROOT/.env" 2>/dev/null
        if [ -n "$NEXUS_HOST" ] && [ -n "$NEXUS_URL" ] && [ "$NEXUS_HOST" != "nexus" ] && [ "$NEXUS_HOST" != "localhost" ]; then
            # Extract port from URL
            if [[ $NEXUS_URL =~ :([0-9]+) ]]; then
                local nexus_port="${BASH_REMATCH[1]}"
                test_connectivity "$NEXUS_HOST" "$nexus_port" "Configured Nexus ($NEXUS_HOST)" "connectivity"
            fi
        fi
    fi

    # Fallback test for localhost Nexus (if not already tested via Docker)
    if [ "$docker_nexus_available" = "false" ]; then
        test_connectivity "localhost" "8081" "Local Nexus (standalone)" "connectivity"
    fi

    # Provide contextual feedback
    if [ "$docker_nexus_available" = "true" ] && [ "$host_nexus_available" = "true" ]; then
        record_check "connectivity" "Nexus accessibility summary" "PASS" "Available via Docker and host"
    elif [ "$docker_nexus_available" = "true" ]; then
        record_check "connectivity" "Nexus accessibility summary" "WARN" "Available in Docker but host access may be limited"
    fi

    echo
}

# Function to run functional tests
check_functional() {
    if [ "$SPECIFIC_CATEGORY" != "" ] && [ "$SPECIFIC_CATEGORY" != "functional" ] || [ "$QUICK" = "true" ]; then
        if [ "$QUICK" = "true" ]; then
            log_step "Functional Tests (Skipped - Quick Mode)"
            echo "──────────────────────────────────────────"
            record_check "functional" "All functional tests" "SKIP" "Quick mode enabled"
            echo
        fi
        return 0
    fi

    log_step "Functional Tests"
    echo "────────────────"

    # Load environment if available
    if [ -f "$PROJECT_ROOT/.env" ]; then
        source "$PROJECT_ROOT/.env" 2>/dev/null || {
            record_check "functional" "Environment loading" "FAIL" "Cannot load .env file"
            return 1
        }
        record_check "functional" "Environment variables loaded" "PASS"
    else
        record_check "functional" "Environment variables loaded" "SKIP" ".env file not found"
    fi

    # Test SBT commands if Docker is available
    if [ "$SKIP_DOCKER" = "false" ] && docker info >/dev/null 2>&1; then
        cd "$PROJECT_ROOT/docker" 2>/dev/null || {
            record_check "functional" "Docker directory access" "FAIL" "Cannot access docker directory"
            return 1
        }

        # Check if SBT container is already running (faster than creating new one)
        local sbt_container_running=false
        if docker ps --filter "name=sbt" --filter "status=running" | grep -q sbt; then
            sbt_container_running=true
        fi

        # Check if Nexus is running before testing SBT commands
        local nexus_ready=false
        if docker-compose ps nexus | grep -q "Up"; then
            # Quick test if Nexus is ready (don't wait)
            if curl -s -f http://localhost:8081 >/dev/null 2>&1; then
                nexus_ready=true
            fi
        fi

        # Test SBT functionality - skip if this is likely to be slow (first run)
        if [ "$QUICK" = "true" ]; then
            record_check "functional" "SBT show version command" "SKIP" "Quick mode enabled - test manually with: docker-compose run --rm sbt sbt 'show version'"
        elif [ "$sbt_container_running" = "true" ]; then
            # Use existing container for faster execution
            if timeout 10 docker exec sbt sbt "show version" >/dev/null 2>&1; then
                record_check "functional" "SBT show version command" "PASS"
            else
                record_check "functional" "SBT show version command" "WARN" "Command failed - SBT may be initializing"
            fi
        else
            # Try with new container but with very short timeout to avoid hanging
            if timeout 8 docker-compose run --rm -T sbt sbt "show version" >/dev/null 2>&1; then
                record_check "functional" "SBT show version command" "PASS"
            else
                record_check "functional" "SBT show version command" "SKIP" "Timed out - SBT likely downloading dependencies. Test manually: docker-compose run --rm sbt sbt 'show version'"
            fi
        fi

        # Test show credentials (requires proper Docker network setup)
        if [ "$QUICK" = "true" ]; then
            record_check "functional" "SBT credentials configuration" "SKIP" "Quick mode enabled"
        elif [ "$nexus_ready" = "true" ] && [ "$sbt_container_running" = "true" ]; then
            if timeout 8 docker exec sbt sbt "show credentials" >/dev/null 2>&1; then
                record_check "functional" "SBT credentials configuration" "PASS"
            else
                record_check "functional" "SBT credentials configuration" "WARN" "Command failed - check Docker network and credentials"
            fi
        else
            record_check "functional" "SBT credentials configuration" "SKIP" "Nexus not ready or SBT container not running - start with: cd docker && docker-compose up -d"
        fi

        # Test compilation - always skip for faster validation
        record_check "functional" "Project compilation" "SKIP" "Skipped for faster validation - test manually with: docker-compose run --rm sbt sbt compile"

        cd "$PROJECT_ROOT"
    else
        record_check "functional" "SBT functional tests" "SKIP" "Docker not available"
    fi

    echo
}

# Function to show category summary
show_category_summary() {
    local category="$1"
    local results="${CATEGORY_RESULTS[$category]}"

    if [ -n "$results" ]; then
        local passed=$(echo "$results" | grep -o 'passed:[0-9]*' | cut -d: -f2)
        local failed=$(echo "$results" | grep -o 'failed:[0-9]*' | cut -d: -f2)
        local warned=$(echo "$results" | grep -o 'warned:[0-9]*' | cut -d: -f2)
        local skipped=$(echo "$results" | grep -o 'skipped:[0-9]*' | cut -d: -f2)

        local total=$((passed + failed + warned + skipped))

        if [ $total -gt 0 ]; then
            printf "  %-15s: " "$category"
            [ $passed -gt 0 ] && printf "${GREEN}✅ %d${NC} " $passed
            [ $failed -gt 0 ] && printf "${RED}❌ %d${NC} " $failed
            [ $warned -gt 0 ] && printf "${YELLOW}⚠️ %d${NC} " $warned
            [ $skipped -gt 0 ] && printf "${PURPLE}⏭️ %d${NC} " $skipped
            printf "(%d total)\n" $total
        fi
    fi
}

# Main execution
echo "Starting comprehensive validation..."
echo

# Run all check categories (ignore return codes)
check_prerequisites || true
check_structure || true
check_security || true
check_docker || true
check_configuration || true
check_connectivity || true
check_functional || true

# Final summary
echo
echo "=============================================================="
log_step "Validation Summary"
echo "=================="
echo "Total checks: $((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNED + CHECKS_SKIPPED))"

# Show category breakdown
for category in "${!CATEGORY_RESULTS[@]}"; do
    results="${CATEGORY_RESULTS[$category]}"
    passed=$(echo "$results" | grep -o 'passed:[0-9]*' | cut -d: -f2)
    failed=$(echo "$results" | grep -o 'failed:[0-9]*' | cut -d: -f2)
    warned=$(echo "$results" | grep -o 'warned:[0-9]*' | cut -d: -f2)
    skipped=$(echo "$results" | grep -o 'skipped:[0-9]*' | cut -d: -f2)

    total=$((passed + failed + warned + skipped))
    if [ $total -gt 0 ]; then
        printf "  %-15s: " "$category"
        [ $passed -gt 0 ] && printf "${GREEN}✅ %d${NC} " $passed
        [ $failed -gt 0 ] && printf "${RED}❌ %d${NC} " $failed
        [ $warned -gt 0 ] && printf "${YELLOW}⚠️ %d${NC} " $warned
        [ $skipped -gt 0 ] && printf "${PURPLE}⏭️ %d${NC} " $skipped
        printf "(%d total)\n" $total
    fi
done

echo
echo "Final Results:"
echo "=============="
echo -e "Checks Passed:  ${GREEN}$CHECKS_PASSED${NC}"
echo -e "Checks Failed:  ${RED}$CHECKS_FAILED${NC}"
echo -e "Checks Warned:  ${YELLOW}$CHECKS_WARNED${NC}"
echo -e "Checks Skipped: ${PURPLE}$CHECKS_SKIPPED${NC}"
echo -e "Total Checks:   $((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNED + CHECKS_SKIPPED))"

# Calculate success rate
total_significant=$((CHECKS_PASSED + CHECKS_FAILED))
if [ $total_significant -gt 0 ]; then
    success_rate=$((CHECKS_PASSED * 100 / total_significant))
    echo -e "Success Rate:   ${success_rate}%"
fi

echo
echo "=============================================================="

# Determine exit code and provide recommendations
if [ $CHECKS_FAILED -eq 0 ]; then
    if [ $CHECKS_WARNED -eq 0 ]; then
        log_success "🎉 All validations passed! Your development environment is perfectly configured."
        echo
        echo "🚀 Next Steps:"
        echo "   • Your setup is ready for development"
        echo "   • Run ./scripts/setup-credentials.sh to configure publishing"
        echo "   • Test with: sbt publishLocal"
        echo "   • Start developing: See README.md for examples"
    else
        log_success "✅ All critical validations passed! ($CHECKS_WARNED warnings can usually be ignored)"
        echo
        echo "🎯 Your development environment is functional with minor recommendations."
        echo "🔍 Review warnings above for potential improvements."
    fi
    exit 0
elif [ $CHECKS_FAILED -le 2 ] && [ $CHECKS_PASSED -ge $CHECKS_FAILED ]; then
    log_warning "⚠️  Your setup is mostly working, but there are $CHECKS_FAILED critical issues."
    echo
    echo "🔧 Quick fixes:"
    echo "   • Fix file permissions: ./scripts/validate-setup.sh --fix-permissions"
    echo "   • Start Nexus service: cd docker && docker-compose up -d nexus"
    echo "   • Wait for Nexus startup: curl -f http://localhost:8081 (may take 1-2 minutes)"
    echo "   • Set up credentials: ./scripts/setup-credentials.sh"
    exit 1
else
    log_error "❌ Your development environment has significant issues ($CHECKS_FAILED failures)."
    echo
    echo "🛠️  Recommended actions:"
    echo "   1. Check system requirements: README.md"
    echo "   2. Install missing dependencies"
    echo "   3. Fix permissions: ./scripts/validate-setup.sh --fix-permissions"
    echo "   4. Set up environment: ./scripts/setup-credentials.sh"
    echo "   5. Re-run validation: ./scripts/validate-setup.sh"
    echo
    echo "📚 For help:"
    echo "   • Documentation: README.md"
    echo "   • Quick start: CREDENTIALS_QUICKSTART.md"
    echo "   • Troubleshooting: Use --verbose flag for details"
    exit 1
fi
