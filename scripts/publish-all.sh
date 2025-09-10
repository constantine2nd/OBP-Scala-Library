#!/bin/bash

# Enhanced Multi-Version Publishing Script for OBP Scala Library
# Publishes the library to Nexus for all supported Scala versions with comprehensive error handling

set -e  # Exit on any error

# Configuration
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="OBP Scala Library Multi-Version Publisher"
MAX_RETRIES=3
RETRY_DELAY=10
PARALLEL_JOBS=1  # Set to > 1 for parallel publishing (experimental)

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Progress tracking
TOTAL_VERSIONS=0
COMPLETED_VERSIONS=0
FAILED_VERSIONS=0
START_TIME=$(date +%s)

echo -e "${BLUE}🚀 $SCRIPT_NAME v$SCRIPT_VERSION${NC}"
echo "=========================================================="

# Function to print colored messages
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "${CYAN}📋 $1${NC}"; }
log_progress() { echo -e "${PURPLE}⏳ $1${NC}"; }

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [options]

Options:
  --dry-run                 Show what would be published without actually publishing
  --version VERSION         Publish only specific Scala version (e.g., 2.13.14)
  --parallel JOBS           Number of parallel publishing jobs (default: 1)
  --max-retries COUNT       Maximum retry attempts per version (default: 3)
  --retry-delay SECONDS     Delay between retries in seconds (default: 10)
  --skip-validation         Skip pre-flight validation checks
  --help                    Show this help message
  --version-info            Show version information

Examples:
  $0                        # Publish all versions sequentially
  $0 --version 2.13.14      # Publish only Scala 2.13.14
  $0 --dry-run              # Show what would be published
  $0 --parallel 2           # Publish with 2 parallel jobs (experimental)
  $0 --max-retries 5        # Retry up to 5 times on failure

Environment Variables:
  NEXUS_USERNAME           Nexus username (required)
  NEXUS_PASSWORD           Nexus password (required)
  NEXUS_HOST              Nexus hostname (required)
  NEXUS_URL               Nexus URL (required)

EOF
}

show_version_info() {
    echo "$SCRIPT_NAME v$SCRIPT_VERSION"
    echo "Part of OBP Scala Library publishing system"
    echo "Supports concurrent publishing with retry logic and comprehensive error handling"
}

# Parse command line arguments
DRY_RUN=false
SPECIFIC_VERSION=""
SKIP_VALIDATION=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --version)
            SPECIFIC_VERSION="$2"
            shift 2
            ;;
        --parallel)
            PARALLEL_JOBS="$2"
            shift 2
            ;;
        --max-retries)
            MAX_RETRIES="$2"
            shift 2
            ;;
        --retry-delay)
            RETRY_DELAY="$2"
            shift 2
            ;;
        --skip-validation)
            SKIP_VALIDATION=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        --version-info)
            show_version_info
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

# Validation function
validate_numeric() {
    local value="$1"
    local name="$2"
    if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -le 0 ]; then
        log_error "$name must be a positive integer, got: $value"
        exit 1
    fi
}

# Validate numeric parameters
validate_numeric "$PARALLEL_JOBS" "Parallel jobs"
validate_numeric "$MAX_RETRIES" "Max retries"
validate_numeric "$RETRY_DELAY" "Retry delay"

# Function to calculate elapsed time
get_elapsed_time() {
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))
    printf "%02d:%02d:%02d" $((elapsed/3600)) $(((elapsed%3600)/60)) $((elapsed%60))
}

# Function to estimate remaining time
estimate_remaining_time() {
    if [ $COMPLETED_VERSIONS -eq 0 ]; then
        echo "Calculating..."
        return
    fi

    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))
    local avg_time_per_version=$((elapsed / COMPLETED_VERSIONS))
    local remaining_versions=$((TOTAL_VERSIONS - COMPLETED_VERSIONS))
    local estimated_remaining=$((avg_time_per_version * remaining_versions))

    printf "%02d:%02d:%02d" $((estimated_remaining/3600)) $(((estimated_remaining%3600)/60)) $((estimated_remaining%60))
}

# Function to show progress
show_progress() {
    local current="$1"
    local total="$2"
    local version="$3"
    local status="$4"

    local percentage=$((current * 100 / total))
    local completed_bars=$((current * 30 / total))
    local remaining_bars=$((30 - completed_bars))

    printf "\r${CYAN}Progress: ["
    printf "%0.s█" $(seq 1 $completed_bars)
    printf "%0.s░" $(seq 1 $remaining_bars)
    printf "] %d%% (%d/%d) | %s | %s${NC}" \
        "$percentage" "$current" "$total" "$version" "$status"

    if [ "$current" -eq "$total" ]; then
        echo
    fi
}

# Function to check Docker environment
check_docker_environment() {
    log_step "Checking Docker environment..."

    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed or not in PATH"
        return 1
    fi

    if ! command -v docker-compose >/dev/null 2>&1; then
        log_error "Docker Compose is not installed or not in PATH"
        return 1
    fi

    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        return 1
    fi

    log_success "Docker environment is ready"
    return 0
}

# Function to validate project structure
validate_project_structure() {
    log_step "Validating project structure..."

    # Check if we're in the right directory
    if [ ! -f "build.sbt" ]; then
        log_error "build.sbt not found. Please run this script from the project root directory."
        return 1
    fi

    # Check for docker directory
    if [ ! -d "docker" ]; then
        log_error "Docker directory not found. This script requires the Docker development environment."
        return 1
    fi

    # Check for docker-compose.yml
    if [ ! -f "docker/docker-compose.yml" ]; then
        log_error "docker-compose.yml not found in docker directory."
        return 1
    fi

    log_success "Project structure is valid"
    return 0
}

# Function to validate environment variables
validate_environment() {
    log_step "Validating environment variables..."

    # Check if .env file exists
    if [ ! -f ".env" ]; then
        log_error ".env file not found. Please run ./scripts/setup-credentials.sh first."
        return 1
    fi

    # Load environment variables
    source .env

    # Verify required environment variables
    local missing_vars=()

    [ -z "$NEXUS_USERNAME" ] && missing_vars+=("NEXUS_USERNAME")
    [ -z "$NEXUS_PASSWORD" ] && missing_vars+=("NEXUS_PASSWORD")
    [ -z "$NEXUS_HOST" ] && missing_vars+=("NEXUS_HOST")
    [ -z "$NEXUS_URL" ] && missing_vars+=("NEXUS_URL")

    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        log_info "Please check your .env file or run ./scripts/setup-credentials.sh"
        return 1
    fi

    log_success "Environment variables loaded and validated"
    log_info "Username: $NEXUS_USERNAME"
    log_info "Host: $NEXUS_HOST"
    log_info "URL: $NEXUS_URL"

    return 0
}

# Function to get Scala versions from build.sbt
get_scala_versions() {
    log_step "Extracting Scala versions from build.sbt..."

    # Extract crossScalaVersions from build.sbt
    local versions_line=$(grep "crossScalaVersions" build.sbt | head -1)
    if [ -z "$versions_line" ]; then
        log_error "crossScalaVersions not found in build.sbt"
        return 1
    fi

    # Parse versions using sed and awk
    local versions=$(echo "$versions_line" | sed 's/.*Seq(//' | sed 's/).*//' | tr -d '"' | tr ',' '\n' | awk '{print $1}' | grep -v '^$')

    if [ -z "$versions" ]; then
        log_error "Could not parse Scala versions from build.sbt"
        return 1
    fi

    echo "$versions"
}

# Function to start Nexus if not running
ensure_nexus_running() {
    log_step "Ensuring Nexus is running..."

    cd docker

    # Check if Nexus container is running
    if docker-compose ps nexus | grep -q "Up"; then
        log_success "Nexus container is already running"
    else
        log_info "Starting Nexus container..."
        if docker-compose up -d nexus; then
            log_success "Nexus container started successfully"

            # Wait for Nexus to be ready
            log_info "Waiting for Nexus to be ready..."
            local max_wait=60
            local wait_time=0

            while [ $wait_time -lt $max_wait ]; do
                if curl -s -f "http://localhost:8081" >/dev/null 2>&1; then
                    log_success "Nexus is ready to accept connections"
                    break
                fi
                sleep 2
                wait_time=$((wait_time + 2))
                show_progress $wait_time $max_wait "nexus" "Starting up..."
            done

            if [ $wait_time -ge $max_wait ]; then
                log_warning "Nexus may still be starting up. Proceeding anyway..."
            fi
        else
            log_error "Failed to start Nexus container"
            cd ..
            return 1
        fi
    fi

    cd ..
    return 0
}

# Function to test SBT container
test_sbt_container() {
    log_step "Testing SBT container functionality..."

    cd docker

    if docker-compose run --rm -T \
        -e NEXUS_USERNAME="$NEXUS_USERNAME" \
        -e NEXUS_PASSWORD="$NEXUS_PASSWORD" \
        -e NEXUS_HOST="$NEXUS_HOST" \
        -e NEXUS_URL="$NEXUS_URL" \
        sbt sbt "show version" >/dev/null 2>&1; then
        log_success "SBT container is working correctly"
        cd ..
        return 0
    else
        log_error "SBT container test failed"
        cd ..
        return 1
    fi
}

# Function to publish a single version with retry logic
publish_version() {
    local version="$1"
    local attempt=1

    while [ $attempt -le $MAX_RETRIES ]; do
        log_progress "Publishing Scala $version (attempt $attempt/$MAX_RETRIES)..."

        if [ "$DRY_RUN" = "true" ]; then
            log_info "[DRY RUN] Would publish Scala $version"
            sleep 2  # Simulate publishing time
            return 0
        fi

        # Change to docker directory for publishing
        cd docker

        # Attempt to publish
        if docker-compose run --rm -T \
            -e NEXUS_USERNAME="$NEXUS_USERNAME" \
            -e NEXUS_PASSWORD="$NEXUS_PASSWORD" \
            -e NEXUS_HOST="$NEXUS_HOST" \
            -e NEXUS_URL="$NEXUS_URL" \
            sbt sbt "++$version" "publish" 2>&1 | tee "../logs/publish-$version-attempt-$attempt.log"; then

            cd ..
            log_success "Successfully published Scala $version"
            return 0
        else
            cd ..
            if [ $attempt -lt $MAX_RETRIES ]; then
                log_warning "Attempt $attempt failed for Scala $version. Retrying in $RETRY_DELAY seconds..."
                sleep $RETRY_DELAY
            else
                log_error "Failed to publish Scala $version after $MAX_RETRIES attempts"
                return 1
            fi
        fi

        attempt=$((attempt + 1))
    done

    return 1
}

# Function to publish versions in parallel
publish_parallel() {
    local versions=("$@")
    local pids=()
    local results=()

    log_info "Starting parallel publishing with $PARALLEL_JOBS jobs..."

    # Create a temporary directory for job status
    local job_dir=$(mktemp -d)

    for version in "${versions[@]}"; do
        # Wait if we've reached the maximum number of parallel jobs
        while [ ${#pids[@]} -ge $PARALLEL_JOBS ]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    wait "${pids[$i]}"
                    local exit_code=$?
                    results[$i]=$exit_code

                    if [ $exit_code -eq 0 ]; then
                        COMPLETED_VERSIONS=$((COMPLETED_VERSIONS + 1))
                        log_success "Completed ${versions[$i]} in parallel job"
                    else
                        FAILED_VERSIONS=$((FAILED_VERSIONS + 1))
                        log_error "Failed ${versions[$i]} in parallel job"
                    fi

                    unset pids[$i]
                fi
            done
            sleep 1
        done

        # Start publishing this version in the background
        (
            publish_version "$version"
            echo $? > "$job_dir/result-$version"
        ) &

        pids+=($!)
        log_info "Started background job for Scala $version (PID: $!)"
    done

    # Wait for all remaining jobs to complete
    for i in "${!pids[@]}"; do
        wait "${pids[$i]}"
        local version="${versions[$i]}"
        local exit_code=$(cat "$job_dir/result-$version" 2>/dev/null || echo "1")

        if [ "$exit_code" -eq 0 ]; then
            COMPLETED_VERSIONS=$((COMPLETED_VERSIONS + 1))
            log_success "Completed $version"
        else
            FAILED_VERSIONS=$((FAILED_VERSIONS + 1))
            log_error "Failed $version"
        fi
    done

    # Cleanup
    rm -rf "$job_dir"
}

# Function to publish versions sequentially
publish_sequential() {
    local versions=("$@")

    for version in "${versions[@]}"; do
        show_progress $((COMPLETED_VERSIONS + 1)) $TOTAL_VERSIONS "Scala $version" "Publishing..."

        if publish_version "$version"; then
            COMPLETED_VERSIONS=$((COMPLETED_VERSIONS + 1))
        else
            FAILED_VERSIONS=$((FAILED_VERSIONS + 1))
        fi

        show_progress $COMPLETED_VERSIONS $TOTAL_VERSIONS "Scala $version" "Completed"
        sleep 0.5  # Brief pause for visual feedback
    done
}

# Main execution starts here
echo
log_step "Initializing publishing process..."

# Create logs directory
mkdir -p logs

# Validate project and environment unless skipped
if [ "$SKIP_VALIDATION" = "false" ]; then
    validate_project_structure || exit 1
    check_docker_environment || exit 1
    validate_environment || exit 1
    ensure_nexus_running || exit 1
    test_sbt_container || exit 1
else
    log_warning "Skipping validation checks (--skip-validation specified)"
    source .env  # Still need to load environment variables
fi

# Get Scala versions
if [ -n "$SPECIFIC_VERSION" ]; then
    SCALA_VERSIONS=("$SPECIFIC_VERSION")
    log_info "Publishing specific version: $SPECIFIC_VERSION"
else
    readarray -t SCALA_VERSIONS <<< "$(get_scala_versions)"
    if [ $? -ne 0 ] || [ ${#SCALA_VERSIONS[@]} -eq 0 ]; then
        log_error "Failed to get Scala versions from build.sbt"
        exit 1
    fi
    log_info "Found Scala versions: ${SCALA_VERSIONS[*]}"
fi

TOTAL_VERSIONS=${#SCALA_VERSIONS[@]}

# Show publishing plan
echo
log_step "Publishing Plan"
echo "===================="
echo "Scala versions: ${SCALA_VERSIONS[*]}"
echo "Total versions: $TOTAL_VERSIONS"
echo "Publishing mode: $([ $PARALLEL_JOBS -gt 1 ] && echo "Parallel ($PARALLEL_JOBS jobs)" || echo "Sequential")"
echo "Max retries: $MAX_RETRIES"
echo "Retry delay: $RETRY_DELAY seconds"
echo "Dry run: $([ "$DRY_RUN" = "true" ] && echo "Yes" || echo "No")"
echo

# Confirm before proceeding (unless non-interactive)
if [ "$DRY_RUN" = "false" ] && [ -t 0 ]; then
    read -p "Proceed with publishing? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Publishing cancelled by user"
        exit 0
    fi
fi

echo
log_step "Starting publication process..."
echo "Time started: $(date)"
echo

# Publish based on configuration
if [ $PARALLEL_JOBS -gt 1 ] && [ ${#SCALA_VERSIONS[@]} -gt 1 ]; then
    publish_parallel "${SCALA_VERSIONS[@]}"
else
    publish_sequential "${SCALA_VERSIONS[@]}"
fi

# Final summary
echo
echo "=========================================================="
log_step "Publication Summary"
echo "===================="
echo "Total versions: $TOTAL_VERSIONS"
echo "Completed: $COMPLETED_VERSIONS"
echo "Failed: $FAILED_VERSIONS"
echo "Success rate: $((COMPLETED_VERSIONS * 100 / TOTAL_VERSIONS))%"
echo "Total time: $(get_elapsed_time)"
echo "Finished: $(date)"

if [ $FAILED_VERSIONS -eq 0 ]; then
    echo
    log_success "🎉 All Scala versions published successfully!"

    if [ "$DRY_RUN" = "false" ]; then
        echo
        echo "📦 Published artifacts can be found at:"
        echo "   Repository: $NEXUS_URL"
        echo "   Path: repository/maven-snapshots/org/openbankproject/"
        echo
        echo "📋 Artifact details:"
        for version in "${SCALA_VERSIONS[@]}"; do
            echo "   • obp-scala-library_$version:0.1.0-SNAPSHOT"
        done
    fi

    exit 0
else
    echo
    log_error "❌ Some publications failed!"
    echo
    echo "📋 Failed versions:"
    # We could track which specific versions failed, but for now just show the count
    echo "   • $FAILED_VERSIONS out of $TOTAL_VERSIONS versions failed"
    echo
    echo "🔍 Check log files in ./logs/ directory for detailed error information"
    echo "💡 You can retry failed versions individually with: $0 --version <scala-version>"

    exit 1
fi
