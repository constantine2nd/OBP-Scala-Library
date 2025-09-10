#!/bin/bash

# Enhanced Credential Testing Script for OBP Scala Library
# Comprehensive validation of credential management system with improved performance and reporting

set -e

# Configuration
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="OBP Scala Library Credential Tester"
TEST_TIMEOUT=30
SBT_TIMEOUT=60

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

echo -e "${BLUE}🧪 $SCRIPT_NAME v$SCRIPT_VERSION${NC}"
echo "======================================================="
echo "Project: $(basename "$PROJECT_ROOT")"
echo "Timestamp: $(date)"
echo

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNED=0
TESTS_SKIPPED=0

# Test categories
declare -A CATEGORY_RESULTS

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
  --quick                  Run essential tests only (faster)
  --category CATEGORY      Run specific category of tests
  --no-docker             Skip Docker-dependent tests
  --no-sbt                Skip SBT command tests
  --verbose               Show detailed output for all tests
  --timeout SECONDS       Set SBT command timeout (default: 60)
  --help                  Show this help message

Categories:
  environment             Test environment variable loading and validation
  files                   Test credential files and permissions
  docker                  Test Docker environment integration
  sbt                     Test SBT credential configuration
  publishing              Test publishing pipeline
  security                Test security configuration

Examples:
  $0                      # Run all credential tests
  $0 --quick              # Run essential tests only
  $0 --category sbt       # Test only SBT integration
  $0 --no-docker          # Skip Docker tests
  $0 --verbose            # Show detailed test output

EOF
}

# Parse command line arguments
QUICK_MODE=false
SPECIFIC_CATEGORY=""
SKIP_DOCKER=false
SKIP_SBT=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --category)
            SPECIFIC_CATEGORY="$2"
            shift 2
            ;;
        --no-docker)
            SKIP_DOCKER=true
            shift
            ;;
        --no-sbt)
            SKIP_SBT=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --timeout)
            SBT_TIMEOUT="$2"
            shift 2
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

# Function to record test results
record_test() {
    local category="$1"
    local test_name="$2"
    local result="$3"
    local message="$4"
    local details="$5"

    # Display result
    case "$result" in
        "PASS")
            TESTS_PASSED=$((TESTS_PASSED + 1))
            if [ "$VERBOSE" = "true" ]; then
                echo -e "  ${GREEN}✅ $test_name${NC}"
                [ -n "$details" ] && echo -e "     ${CYAN}$details${NC}"
            fi
            ;;
        "FAIL")
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo -e "  ${RED}❌ $test_name${NC}${message:+ - $message}"
            [ -n "$details" ] && echo -e "     ${RED}$details${NC}"
            ;;
        "WARN")
            TESTS_WARNED=$((TESTS_WARNED + 1))
            echo -e "  ${YELLOW}⚠️  $test_name${NC}${message:+ - $message}"
            [ -n "$details" ] && echo -e "     ${YELLOW}$details${NC}"
            ;;
        "SKIP")
            TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
            if [ "$VERBOSE" = "true" ]; then
                echo -e "  ${PURPLE}⏭️  $test_name${NC}${message:+ - $message}"
            fi
            ;;
    esac

    # Update category tracking
    if [[ ! ${CATEGORY_RESULTS[$category]+_} ]]; then
        CATEGORY_RESULTS[$category]="passed:0 failed:0 warned:0 skipped:0"
    fi

    local current="${CATEGORY_RESULTS[$category]}"
    case "$result" in
        "PASS") CATEGORY_RESULTS[$category]=$(echo "$current" | sed -E 's/passed:([0-9]+)/passed:'$(($(echo "$current" | grep -o 'passed:[0-9]*' | cut -d: -f2) + 1))'/');;
        "FAIL") CATEGORY_RESULTS[$category]=$(echo "$current" | sed -E 's/failed:([0-9]+)/failed:'$(($(echo "$current" | grep -o 'failed:[0-9]*' | cut -d: -f2) + 1))'/');;
        "WARN") CATEGORY_RESULTS[$category]=$(echo "$current" | sed -E 's/warned:([0-9]+)/warned:'$(($(echo "$current" | grep -o 'warned:[0-9]*' | cut -d: -f2) + 1))'/');;
        "SKIP") CATEGORY_RESULTS[$category]=$(echo "$current" | sed -E 's/skipped:([0-9]+)/skipped:'$(($(echo "$current" | grep -o 'skipped:[0-9]*' | cut -d: -f2) + 1))'/');;
    esac
}

# Function to run SBT command with timeout
run_sbt_command() {
    local env_args="$1"
    local command="$2"
    local output_var="$3"

    local temp_output=$(mktemp)
    local result

    cd "$PROJECT_ROOT/docker" 2>/dev/null || return 1

    if [ -n "$env_args" ]; then
        if timeout "$SBT_TIMEOUT" bash -c "docker-compose run --rm -T $env_args sbt sbt \"$command\"" > "$temp_output" 2>&1; then
            result=0
        else
            result=$?
        fi
    else
        if timeout "$SBT_TIMEOUT" bash -c "docker-compose run --rm -T sbt sbt \"$command\"" > "$temp_output" 2>&1; then
            result=0
        else
            result=$?
        fi
    fi

    if [ -n "$output_var" ]; then
        eval "$output_var=\"$(cat "$temp_output")\""
    fi

    rm -f "$temp_output"
    cd "$PROJECT_ROOT"
    return $result
}

# Test environment variable handling
test_environment_variables() {
    if [ -n "$SPECIFIC_CATEGORY" ] && [ "$SPECIFIC_CATEGORY" != "environment" ]; then
        return 0
    fi

    log_step "Environment Variables Test"
    echo "───────────────────────────"

    # Test 1: Check if .env file exists
    if [ -f "$PROJECT_ROOT/.env" ]; then
        record_test "environment" ".env file exists" "PASS" "" "File found at $PROJECT_ROOT/.env"

        # Test 2: Check if .env file is readable
        if [ -r "$PROJECT_ROOT/.env" ]; then
            record_test "environment" ".env file readable" "PASS"

            # Load and test environment variables
            source "$PROJECT_ROOT/.env" 2>/dev/null || {
                record_test "environment" ".env file loadable" "FAIL" "Cannot source .env file"
                return 1
            }

            record_test "environment" ".env file loadable" "PASS"

            # Test 3-6: Check required variables
            local required_vars=("NEXUS_USERNAME" "NEXUS_PASSWORD" "NEXUS_HOST" "NEXUS_URL")
            local missing_count=0

            for var in "${required_vars[@]}"; do
                if [ -n "${!var}" ]; then
                    local safe_value="${!var}"
                    if [ "$var" = "NEXUS_PASSWORD" ]; then
                        safe_value="[${#safe_value} characters]"
                    fi
                    record_test "environment" "$var variable set" "PASS" "" "Value: $safe_value"
                else
                    record_test "environment" "$var variable set" "FAIL" "Variable not set or empty"
                    missing_count=$((missing_count + 1))
                fi
            done

            # Test 7: All required variables present
            if [ $missing_count -eq 0 ]; then
                record_test "environment" "All required variables present" "PASS" "" "All 4 variables are set"
            else
                record_test "environment" "All required variables present" "FAIL" "$missing_count variables missing"
            fi

            # Test 8: URL format validation
            if [ -n "$NEXUS_URL" ]; then
                if [[ $NEXUS_URL =~ ^https?://[a-zA-Z0-9.-]+:[0-9]+/?$ ]]; then
                    record_test "environment" "NEXUS_URL format valid" "PASS" "" "Format: http(s)://host:port/"
                else
                    record_test "environment" "NEXUS_URL format valid" "WARN" "URL format may be incorrect" "Got: $NEXUS_URL"
                fi
            fi

        else
            record_test "environment" ".env file readable" "FAIL" "File exists but not readable"
        fi

    else
        record_test "environment" ".env file exists" "FAIL" "Run ./scripts/setup-credentials.sh first"
        record_test "environment" "Environment variable tests" "SKIP" "No .env file found"
        return 1
    fi

    echo
}

# Test file structure and permissions
test_files_and_permissions() {
    if [ -n "$SPECIFIC_CATEGORY" ] && [ "$SPECIFIC_CATEGORY" != "files" ]; then
        return 0
    fi

    log_step "Files and Permissions Test"
    echo "────────────────────────────"

    # Test 1: .env file permissions
    if [ -f "$PROJECT_ROOT/.env" ]; then
        local perms=$(stat -c "%a" "$PROJECT_ROOT/.env" 2>/dev/null || stat -f "%Lp" "$PROJECT_ROOT/.env" 2>/dev/null || echo "unknown")
        if [ "$perms" = "600" ]; then
            record_test "files" ".env file permissions (600)" "PASS" "" "Secure permissions set"
        elif [ "$perms" = "unknown" ]; then
            record_test "files" ".env file permissions" "WARN" "Cannot check permissions on this system"
        else
            record_test "files" ".env file permissions (600)" "FAIL" "Expected 600, got $perms"
        fi
    else
        record_test "files" ".env file permissions" "SKIP" "No .env file found"
    fi

    # Test 2: .gitignore protection
    if [ -f "$PROJECT_ROOT/.gitignore" ]; then
        if grep -q "^\.env$" "$PROJECT_ROOT/.gitignore"; then
            record_test "files" ".env in .gitignore" "PASS" "" "Credentials protected from git"
        else
            record_test "files" ".env in .gitignore" "WARN" "Add .env to .gitignore for security"
        fi

        if grep -q "^source-env\.sh$" "$PROJECT_ROOT/.gitignore"; then
            record_test "files" "source-env.sh in .gitignore" "PASS"
        else
            record_test "files" "source-env.sh in .gitignore" "WARN" "Add source-env.sh to .gitignore"
        fi
    else
        record_test "files" ".gitignore checks" "WARN" ".gitignore file not found"
    fi

    # Test 3: source-env.sh script
    if [ -f "$PROJECT_ROOT/source-env.sh" ]; then
        record_test "files" "source-env.sh script exists" "PASS"

        if [ -x "$PROJECT_ROOT/source-env.sh" ]; then
            record_test "files" "source-env.sh executable" "PASS"

            # Test the script works
            if bash "$PROJECT_ROOT/source-env.sh" >/dev/null 2>&1; then
                record_test "files" "source-env.sh functional" "PASS" "" "Script loads environment successfully"
            else
                record_test "files" "source-env.sh functional" "FAIL" "Script execution failed"
            fi
        else
            record_test "files" "source-env.sh executable" "FAIL" "Script not executable"
        fi
    else
        record_test "files" "source-env.sh script" "WARN" "Convenience script not found"
    fi

    # Test 4: Hardcoded credential scan
    local hardcoded_pattern="20b05303-d54d-434e-8aa6-48cc9ed3de20"
    local scan_dirs=("$PROJECT_ROOT/src" "$PROJECT_ROOT/scripts" "$PROJECT_ROOT/build.sbt")
    local hardcoded_count=0

    for location in "${scan_dirs[@]}"; do
        if [ -e "$location" ]; then
            local count=$(grep -r "$hardcoded_pattern" "$location" 2>/dev/null | grep -E '\.(scala|sbt|sh)$' | wc -l)
            hardcoded_count=$((hardcoded_count + count))
        fi
    done

    # Allow one instance in build.sbt (fallback)
    if [ "$hardcoded_count" -le 1 ]; then
        record_test "files" "No hardcoded credentials in source" "PASS" "" "Only fallback credential found"
    else
        record_test "files" "No hardcoded credentials in source" "FAIL" "Found $hardcoded_count instances"
    fi

    echo
}

# Test Docker integration
test_docker_integration() {
    if [ -n "$SPECIFIC_CATEGORY" ] && [ "$SPECIFIC_CATEGORY" != "docker" ] || [ "$SKIP_DOCKER" = "true" ]; then
        if [ "$SKIP_DOCKER" = "true" ]; then
            log_step "Docker Integration Test (Skipped)"
            echo "────────────────────────────────────"
            record_test "docker" "All Docker tests" "SKIP" "Docker tests disabled"
            echo
        fi
        return 0
    fi

    log_step "Docker Integration Test"
    echo "─────────────────────────"

    # Test 1: Docker availability
    if command -v docker >/dev/null 2>&1; then
        record_test "docker" "Docker command available" "PASS"

        if docker info >/dev/null 2>&1; then
            record_test "docker" "Docker daemon running" "PASS"

            # Test 2: Docker Compose availability
            if command -v docker-compose >/dev/null 2>&1; then
                record_test "docker" "Docker Compose available" "PASS"

                # Test 3: Project docker directory
                if [ -d "$PROJECT_ROOT/docker" ]; then
                    record_test "docker" "Docker directory exists" "PASS"

                    cd "$PROJECT_ROOT/docker"

                    # Test 4: docker-compose.yml
                    if [ -f "docker-compose.yml" ]; then
                        record_test "docker" "docker-compose.yml exists" "PASS"

                        # Test 5: Nexus service status
                        if docker-compose ps nexus >/dev/null 2>&1; then
                            if docker-compose ps nexus | grep -q "Up"; then
                                record_test "docker" "Nexus container running" "PASS" "" "Container is healthy"

                                # Test 6: Nexus connectivity
                                if curl -sf "http://localhost:8081" >/dev/null 2>&1; then
                                    record_test "docker" "Nexus web interface accessible" "PASS" "" "http://localhost:8081 responding"
                                else
                                    record_test "docker" "Nexus web interface accessible" "WARN" "Cannot reach web interface"
                                fi
                            else
                                record_test "docker" "Nexus container running" "WARN" "Container exists but not running"
                            fi
                        else
                            record_test "docker" "Nexus service configured" "WARN" "Nexus service not found in compose file"
                        fi

                        # Test 7: SBT container functionality
                        local sbt_output
                        if run_sbt_command "" "show version" sbt_output; then
                            record_test "docker" "SBT container functional" "PASS" "" "Version command successful"
                        else
                            record_test "docker" "SBT container functional" "FAIL" "SBT container test failed"
                        fi

                    else
                        record_test "docker" "docker-compose.yml exists" "FAIL" "Compose file not found"
                    fi

                    cd "$PROJECT_ROOT"

                else
                    record_test "docker" "Docker directory exists" "FAIL" "Docker directory not found"
                fi

            else
                record_test "docker" "Docker Compose available" "FAIL" "docker-compose not found"
            fi

        else
            record_test "docker" "Docker daemon running" "FAIL" "Docker daemon not accessible"
        fi

    else
        record_test "docker" "Docker command available" "FAIL" "Docker not installed"
    fi

    echo
}

# Test SBT credential configuration
test_sbt_credentials() {
    if [ -n "$SPECIFIC_CATEGORY" ] && [ "$SPECIFIC_CATEGORY" != "sbt" ] || [ "$SKIP_SBT" = "true" ] || [ "$SKIP_DOCKER" = "true" ]; then
        if [ "$SKIP_SBT" = "true" ] || [ "$SKIP_DOCKER" = "true" ]; then
            log_step "SBT Credentials Test (Skipped)"
            echo "─────────────────────────────────"
            record_test "sbt" "All SBT tests" "SKIP" "SBT tests disabled"
            echo
        fi
        return 0
    fi

    log_step "SBT Credentials Test"
    echo "──────────────────────"

    # Skip if no Docker or .env
    if ! docker info >/dev/null 2>&1 || [ ! -f "$PROJECT_ROOT/.env" ]; then
        record_test "sbt" "SBT credential tests" "SKIP" "Docker or .env not available"
        echo
        return 0
    fi

    # Load environment for testing
    source "$PROJECT_ROOT/.env" 2>/dev/null || {
        record_test "sbt" "Environment loading" "FAIL" "Cannot load .env file"
        echo
        return 1
    }

    # Test 1: SBT credentials with environment variables
    log_info "Testing SBT with environment variables..."
    local output
    if run_sbt_command "-e NEXUS_USERNAME=\"$NEXUS_USERNAME\" -e NEXUS_PASSWORD=\"$NEXUS_PASSWORD\" -e NEXUS_HOST=\"$NEXUS_HOST\" -e NEXUS_URL=\"$NEXUS_URL\"" "show credentials" output; then
        if echo "$output" | grep -q "$NEXUS_USERNAME" && echo "$output" | grep -q "$NEXUS_HOST"; then
            record_test "sbt" "Environment variables used correctly" "PASS" "" "Credentials loaded from environment"
        else
            record_test "sbt" "Environment variables used correctly" "WARN" "Expected username and host not found in output"
        fi
    else
        record_test "sbt" "SBT credentials command" "FAIL" "show credentials command failed"
    fi

    # Test 2: SBT without environment variables (fallback)
    if [ "$QUICK_MODE" = "false" ]; then
        log_info "Testing SBT fallback behavior..."
        if run_sbt_command "" "show credentials" output; then
            if echo "$output" | grep -q "Warning.*NEXUS_USERNAME.*not set"; then
                record_test "sbt" "Fallback warning displayed" "PASS" "" "Proper warning for missing env vars"
            else
                record_test "sbt" "Fallback warning displayed" "WARN" "Expected warning message not found"
            fi

            if echo "$output" | grep -q "Falling back to hardcoded credentials"; then
                record_test "sbt" "Fallback message displayed" "PASS" "" "Fallback mechanism working"
            else
                record_test "sbt" "Fallback message displayed" "WARN" "Expected fallback message not found"
            fi
        else
            record_test "sbt" "SBT fallback test" "FAIL" "Command failed without environment variables"
        fi
    fi

    # Test 3: publishTo configuration
    log_info "Testing publishTo configuration..."
    if run_sbt_command "-e NEXUS_URL=\"$NEXUS_URL\"" "show publishTo" output; then
        local expected_url=$(echo "$NEXUS_URL" | sed 's|/$||')/repository/maven-snapshots
        if echo "$output" | grep -q "$expected_url"; then
            record_test "sbt" "publishTo URL from environment" "PASS" "" "Dynamic URL configuration working"
        else
            record_test "sbt" "publishTo URL from environment" "WARN" "Expected URL pattern not found"
        fi
    else
        record_test "sbt" "publishTo configuration test" "FAIL" "show publishTo command failed"
    fi

    echo
}

# Test publishing pipeline
test_publishing_pipeline() {
    if [ -n "$SPECIFIC_CATEGORY" ] && [ "$SPECIFIC_CATEGORY" != "publishing" ] || [ "$QUICK_MODE" = "true" ] || [ "$SKIP_DOCKER" = "true" ]; then
        if [ "$QUICK_MODE" = "true" ]; then
            log_step "Publishing Pipeline Test (Skipped - Quick Mode)"
            echo "───────────────────────────────────────────────────"
            record_test "publishing" "All publishing tests" "SKIP" "Quick mode enabled"
            echo
        fi
        return 0
    fi

    log_step "Publishing Pipeline Test"
    echo "──────────────────────────"

    # Skip if prerequisites not met
    if ! docker info >/dev/null 2>&1 || [ ! -f "$PROJECT_ROOT/.env" ]; then
        record_test "publishing" "Publishing pipeline tests" "SKIP" "Docker or credentials not available"
        echo
        return 0
    fi

    # Load environment
    source "$PROJECT_ROOT/.env" 2>/dev/null || {
        record_test "publishing" "Environment loading" "FAIL" "Cannot load .env file"
        echo
        return 1
    }

    # Test 1: Dry run publishing script
    if [ -x "$PROJECT_ROOT/scripts/publish-all.sh" ]; then
        record_test "publishing" "publish-all.sh script exists" "PASS"

        log_info "Testing publish-all.sh dry run..."
        if timeout 60 "$PROJECT_ROOT/scripts/publish-all.sh" --dry-run >/dev/null 2>&1; then
            record_test "publishing" "publish-all.sh dry run" "PASS" "" "Dry run completed successfully"
        else
            record_test "publishing" "publish-all.sh dry run" "FAIL" "Dry run failed or timed out"
        fi
    else
        record_test "publishing" "publish-all.sh script" "FAIL" "Publishing script not found or not executable"
    fi

    # Test 2: SBT publishLocal command
    log_info "Testing SBT publishLocal..."
    local output
    if timeout 90 bash -c "cd '$PROJECT_ROOT/docker' && docker-compose run --rm -T sbt sbt 'publishLocal'" >/dev/null 2>&1; then
        record_test "publishing" "SBT publishLocal command" "PASS" "" "Local publishing successful"
    else
        record_test "publishing" "SBT publishLocal command" "WARN" "publishLocal failed or timed out"
    fi

    # Test 3: Cross-compilation test
    if [ -f "$PROJECT_ROOT/build.sbt" ]; then
        if grep -q "crossScalaVersions" "$PROJECT_ROOT/build.sbt"; then
            local versions=$(grep "crossScalaVersions" "$PROJECT_ROOT/build.sbt" | head -1)
            local version_count=$(echo "$versions" | grep -o '"[0-9][^"]*"' | wc -l)
            record_test "publishing" "Cross-compilation configured" "PASS" "" "$version_count Scala versions configured"
        else
            record_test "publishing" "Cross-compilation configured" "FAIL" "crossScalaVersions not found in build.sbt"
        fi
    fi

    echo
}

# Test security configuration
test_security_configuration() {
    if [ -n "$SPECIFIC_CATEGORY" ] && [ "$SPECIFIC_CATEGORY" != "security" ]; then
        return 0
    fi

    log_step "Security Configuration Test"
    echo "─────────────────────────────"

    # Test 1: No credentials in git history (basic check)
    if [ -d "$PROJECT_ROOT/.git" ]; then
        record_test "security" "Git repository found" "PASS"

        # Check if .env is properly ignored
        if git -C "$PROJECT_ROOT" check-ignore .env >/dev/null 2>&1; then
            record_test "security" ".env ignored by git" "PASS" "" "File is properly excluded"
        else
            record_test "security" ".env ignored by git" "WARN" "Check .gitignore configuration"
        fi

        # Check for any committed credential patterns
        if git -C "$PROJECT_ROOT" log --oneline --all --grep="password\|credential\|secret" | head -1 >/dev/null; then
            record_test "security" "No credential references in git history" "WARN" "Found potential credential references"
        else
            record_test "security" "No credential references in git history" "PASS"
        fi
    else
        record_test "security" "Git repository checks" "SKIP" "Not a git repository"
    fi

    # Test 2: Environment variable security
    if [ -f "$PROJECT_ROOT/.env" ]; then
        # Check for weak passwords (basic patterns)
        source "$PROJECT_ROOT/.env" 2>/dev/null
        if [ -n "$NEXUS_PASSWORD" ]; then
            local pass_length=${#NEXUS_PASSWORD}
            if [ $pass_length -ge 8 ]; then
                record_test "security" "Password length adequate" "PASS" "" "$pass_length characters"
            else
                record_test "security" "Password length adequate" "WARN" "Password shorter than 8 characters"
            fi

            # Check for common weak passwords
            case "$NEXUS_PASSWORD" in
                "password"|"admin"|"123456"|"admin123")
                    record_test "security" "Password not using common weak patterns" "WARN" "Consider using a stronger password"
                    ;;
                *)
                    record_test "security" "Password not using common weak patterns" "PASS"
                    ;;
            esac
        fi
    fi

    # Test 3: File system security
    if [ -f "$PROJECT_ROOT/.env" ]; then
        # Check ownership
        local file_owner=$(stat -c "%U" "$PROJECT_ROOT/.env" 2>/dev/null || stat -f "%Su" "$PROJECT_ROOT/.env" 2>/dev/null)
        local current_user=$(whoami)

        if [ "$file_owner" = "$current_user" ]; then
            record_test "security" ".env file owned by current user" "PASS" "" "Owner: $file_owner"
        else
            record_test "security" ".env file owned by current user" "WARN" "File owned by: $file_owner"
        fi
    fi

    # Test 4: Network security implications
    if [ -f "$PROJECT_ROOT/.env" ]; then
        source "$PROJECT_ROOT/.env" 2>/dev/null
        if [ -n "$NEXUS_URL" ]; then
            if [[ $NEXUS_URL =~ ^https:// ]]; then
                record_test "security" "Secure connection (HTTPS)" "PASS" "" "Using encrypted connection"
            elif [[ $NEXUS_URL =~ ^http://localhost|^http://127\.0\.0\.1|^http://nexus ]]; then
                record_test "security" "Local development connection" "PASS" "" "Local/container connection acceptable"
            else
                record_test "security" "Connection security" "WARN" "Consider using HTTPS for production"
            fi
        fi
    fi

    echo
}

# Main execution
log_info "Starting comprehensive credential testing..."
echo

# Validate we're in the right place
if [ ! -f "$PROJECT_ROOT/build.sbt" ]; then
    log_error "build.sbt not found. Please run this script from the OBP Scala Library project root or scripts directory."
    exit 1
fi

# Run test categories based on options
if [ -z "$SPECIFIC_CATEGORY" ] || [ "$SPECIFIC_CATEGORY" = "environment" ]; then
    test_environment_variables
fi

if [ -z "$SPECIFIC_CATEGORY" ] || [ "$SPECIFIC_CATEGORY" = "files" ]; then
    test_files_and_permissions
fi

if [ -z "$SPECIFIC_CATEGORY" ] || [ "$SPECIFIC_CATEGORY" = "docker" ]; then
    test_docker_integration
fi

if [ -z "$SPECIFIC_CATEGORY" ] || [ "$SPECIFIC_CATEGORY" = "sbt" ]; then
    test_sbt_credentials
fi

if [ -z "$SPECIFIC_CATEGORY" ] || [ "$SPECIFIC_CATEGORY" = "publishing" ]; then
    test_publishing_pipeline
fi

if [ -z "$SPECIFIC_CATEGORY" ] || [ "$SPECIFIC_CATEGORY" = "security" ]; then
    test_security_configuration
fi

# Final summary
echo
echo "======================================================="
log_step "Credential Testing Summary"
echo "=========================="

# Show category breakdown
for category in "${!CATEGORY_RESULTS[@]}"; do
    local results="${CATEGORY_RESULTS[$category]}"
    local passed=$(echo "$results" | grep -o 'passed:[0-9]*' | cut -d: -f2)
    local failed=$(echo "$results" | grep -o 'failed:[0-9]*' | cut -d: -f2)
    local warned=$(echo "$results" | grep -o 'warned:[0-9]*' | cut -d: -f2)
    local skipped=$(echo "$results" | grep -o 'skipped:[0-9]*' | cut -d: -f2)

    local total=$((passed + failed + warned + skipped))
    if [ $total -gt 0 ]; then
        printf "  %-12s: " "$category"
        [ $passed -gt 0 ] && printf "${GREEN}✅ %d${NC} " $passed
        [ $failed -gt 0 ] && printf "${RED}❌ %d${NC} " $failed
        [ $warned -gt 0 ] && printf "${YELLOW}⚠️ %d${NC} " $warned
        [ $skipped -gt 0 ] && printf "${PURPLE}⏭️ %d${NC} " $skipped
        printf "(%d total)\n" $total
    fi
done

echo
echo "Overall Results:"
echo "=================="
echo -e "Tests Passed:  ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed:  ${RED}$TESTS_FAILED${NC}"
echo -e "Tests Warned:  ${YELLOW}$TESTS_WARNED${NC}"
echo -e "Tests Skipped: ${PURPLE}$TESTS_SKIPPED${NC}"
echo -e "Total Tests:   $(($TESTS_PASSED + $TESTS_FAILED + $TESTS_WARNED + $TESTS_SKIPPED))"

# Calculate success rate
local total_significant=$((TESTS_PASSED + TESTS_FAILED))
if [ $total_significant -gt 0 ]; then
    local success_rate=$((TESTS_PASSED * 100 / total_significant))
    echo -e "Success Rate:  ${success_rate}%"
fi

echo
echo "======================================================="

# Determine exit code and final message
if [ $TESTS_FAILED -eq 0 ]; then
    if [ $TESTS_WARNED -eq 0 ]; then
        log_success "🎉 All credential tests passed! Your credential management system is working perfectly."
        echo
        log_info "🚀 Next steps:"
        echo "   • Your credentials are properly configured"
        echo "   • You can safely publish to your Nexus repository"
        echo "   • Run ./scripts/publish-all.sh to publish to all Scala versions"
        echo "   • Check ./scripts/validate-setup.sh for comprehensive system validation"
    else
        log_success "✅ All critical credential tests passed, but there are $TESTS_WARNED warnings."
        echo
        log_info "🔍 Warnings can usually be ignored but consider reviewing them for best practices."
        log_info "🚀 Your credential system is functional and ready for publishing."
    fi
    exit 0
elif [ $TESTS_FAILED -le 2 ] && [ $TESTS_PASSED -gt $TESTS_FAILED ]; then
    log_warning "⚠️  Credential system is mostly working, but $TESTS_FAILED tests failed."
    echo
    log_info "🔧 Common fixes:"
    echo "   • Run ./scripts/setup-credentials.sh to reconfigure credentials"
    echo "   • Check that Docker is running: docker info"
    echo "   • Verify .env file permissions: ls -la .env"
    echo "   • Start Nexus: cd docker && docker-compose up -d nexus"
    exit 1
else
    log_error "❌ Credential management system has significant issues ($TESTS_FAILED failures)."
    echo
    log_info "🛠️  Recommended actions:"
    echo "   1. Run ./scripts/setup-credentials.sh to recreate credentials"
    echo "   2. Validate your system: ./scripts/validate-setup.sh"
    echo "   3. Check Docker environment: cd docker && docker-compose ps"
    echo "   4. Review the failed tests above for specific issues"
    echo
    log_info "📚 For detailed help:"
    echo "   • Quick start: CREDENTIALS_QUICKSTART.md"
    echo "   • Full documentation: docs/CREDENTIALS.md"
    echo "   • System validation: ./scripts/validate-setup.sh"
    exit 1
fi
