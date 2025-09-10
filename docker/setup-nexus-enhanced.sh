#!/bin/bash

# Enhanced Nexus Repository Setup Script
# This script configures Nexus with proper repositories, users, and permissions for SBT publishing

set -e

echo "=== Enhanced Nexus Repository Setup ==="

# Configuration
NEXUS_URL="http://nexus:8081"
NEXUS_ADMIN_USER="admin"
NEXUS_ADMIN_PASS="20b05303-d54d-434e-8aa6-48cc9ed3de20"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Wait for Nexus to be ready
log_info "Waiting for Nexus to be ready..."
timeout=300
counter=0
while ! curl -f -s "${NEXUS_URL}/service/rest/v1/status" > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        log_error "Timeout waiting for Nexus to be ready"
        exit 1
    fi
    echo "   Waiting... (${counter}s/${timeout}s)"
    sleep 5
    counter=$((counter + 5))
done
log_success "Nexus is ready!"

# Test initial authentication
log_info "Testing initial authentication..."
if curl -f -s -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASS}" "${NEXUS_URL}/service/rest/v1/status/check" > /dev/null 2>&1; then
    log_success "Initial authentication successful!"
else
    log_error "Initial authentication failed. Checking for setup wizard..."

    # Check if this is first run and admin password needs to be set
    if curl -f -s "${NEXUS_URL}/" | grep -q "Please sign in"; then
        log_warning "Nexus appears to be in setup mode. Attempting to complete setup..."

        # Try to complete initial setup
        setup_payload='{
            "username": "admin",
            "password": "'${NEXUS_ADMIN_PASS}'",
            "firstName": "Administrator",
            "lastName": "User",
            "email": "admin@example.com",
            "roles": ["nx-admin"]
        }'

        if curl -f -s -X POST -H "Content-Type: application/json" \
           -d "${setup_payload}" \
           "${NEXUS_URL}/service/rest/internal/ui/onboarding/complete-setup" > /dev/null 2>&1; then
            log_success "Setup wizard completed"
            sleep 5
        else
            log_warning "Could not complete setup wizard automatically"
        fi
    fi
fi

# Function to make authenticated API calls
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    local content_type=${4:-"application/json"}

    if [ -n "$data" ]; then
        curl -f -s -X "$method" \
             -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASS}" \
             -H "Content-Type: ${content_type}" \
             -d "$data" \
             "${NEXUS_URL}${endpoint}"
    else
        curl -f -s -X "$method" \
             -u "${NEXUS_ADMIN_USER}:${NEXUS_ADMIN_PASS}" \
             "${NEXUS_URL}${endpoint}"
    fi
}

# Function to check if repository exists
repository_exists() {
    local repo_name=$1
    api_call GET "/service/rest/v1/repositories/${repo_name}" > /dev/null 2>&1
    return $?
}

# Function to create or update repository
create_hosted_repository() {
    local repo_name=$1
    local write_policy=$2
    local version_policy=${3:-"MIXED"}

    log_info "Setting up repository: ${repo_name}"

    if repository_exists "$repo_name"; then
        log_warning "Repository ${repo_name} already exists, skipping creation"
        return 0
    fi

    local json_payload="{
        \"name\": \"${repo_name}\",
        \"online\": true,
        \"storage\": {
            \"blobStoreName\": \"default\",
            \"strictContentTypeValidation\": false,
            \"writePolicy\": \"${write_policy}\"
        },
        \"cleanup\": {
            \"policyNames\": []
        },
        \"component\": {
            \"proprietaryComponents\": true
        },
        \"maven\": {
            \"versionPolicy\": \"${version_policy}\",
            \"layoutPolicy\": \"STRICT\",
            \"contentDisposition\": \"ATTACHMENT\"
        }
    }"

    if api_call POST "/service/rest/v1/repositories/maven/hosted" "$json_payload"; then
        log_success "Repository ${repo_name} created successfully"
    else
        log_error "Failed to create repository ${repo_name}"
        return 1
    fi
}

# Function to create proxy repository
create_proxy_repository() {
    local repo_name=$1
    local remote_url=$2
    local version_policy=${3:-"RELEASE"}

    log_info "Setting up proxy repository: ${repo_name}"

    if repository_exists "$repo_name"; then
        log_warning "Repository ${repo_name} already exists, skipping creation"
        return 0
    fi

    local json_payload="{
        \"name\": \"${repo_name}\",
        \"online\": true,
        \"storage\": {
            \"blobStoreName\": \"default\",
            \"strictContentTypeValidation\": false
        },
        \"proxy\": {
            \"remoteUrl\": \"${remote_url}\",
            \"contentMaxAge\": 1440,
            \"metadataMaxAge\": 1440
        },
        \"negativeCache\": {
            \"enabled\": true,
            \"timeToLive\": 1440
        },
        \"httpClient\": {
            \"blocked\": false,
            \"autoBlock\": true,
            \"connection\": {
                \"retries\": 0,
                \"userAgentSuffix\": \"string\",
                \"timeout\": 60,
                \"enableCircularRedirects\": false,
                \"enableCookies\": false,
                \"useTrustStore\": false
            }
        },
        \"maven\": {
            \"versionPolicy\": \"${version_policy}\",
            \"layoutPolicy\": \"STRICT\"
        }
    }"

    if api_call POST "/service/rest/v1/repositories/maven/proxy" "$json_payload"; then
        log_success "Proxy repository ${repo_name} created successfully"
    else
        log_error "Failed to create proxy repository ${repo_name}"
        return 1
    fi
}

# Function to enable anonymous access
enable_anonymous_access() {
    log_info "Configuring security settings..."

    # Enable anonymous access for reading
    local anonymous_config='{
        "enabled": true,
        "userId": "anonymous",
        "realmName": "NexusAuthorizingRealm"
    }'

    if api_call PUT "/service/rest/v1/security/anonymous" "$anonymous_config"; then
        log_success "Anonymous access configured"
    else
        log_warning "Could not configure anonymous access"
    fi
}

# Function to create role with specific privileges
create_role() {
    local role_id=$1
    local role_name=$2
    local description=$3
    shift 3
    local privileges=("$@")

    log_info "Creating role: ${role_name}"

    # Convert privileges array to JSON array
    local priv_json="["
    for i in "${!privileges[@]}"; do
        if [ $i -ne 0 ]; then
            priv_json+=","
        fi
        priv_json+="\"${privileges[$i]}\""
    done
    priv_json+="]"

    local role_payload="{
        \"id\": \"${role_id}\",
        \"name\": \"${role_name}\",
        \"description\": \"${description}\",
        \"privileges\": ${priv_json},
        \"roles\": []
    }"

    if api_call POST "/service/rest/v1/security/roles" "$role_payload"; then
        log_success "Role ${role_name} created"
    else
        log_warning "Role ${role_name} may already exist or creation failed"
    fi
}

# Function to create user
create_user() {
    local user_id=$1
    local password=$2
    local first_name=$3
    local last_name=$4
    local email=$5
    shift 5
    local roles=("$@")

    log_info "Creating user: ${user_id}"

    # Convert roles array to JSON array
    local roles_json="["
    for i in "${!roles[@]}"; do
        if [ $i -ne 0 ]; then
            roles_json+=","
        fi
        roles_json+="\"${roles[$i]}\""
    done
    roles_json+="]"

    local user_payload="{
        \"userId\": \"${user_id}\",
        \"firstName\": \"${first_name}\",
        \"lastName\": \"${last_name}\",
        \"emailAddress\": \"${email}\",
        \"password\": \"${password}\",
        \"status\": \"active\",
        \"roles\": ${roles_json}
    }"

    if api_call POST "/service/rest/v1/security/users" "$user_payload"; then
        log_success "User ${user_id} created"
    else
        log_warning "User ${user_id} may already exist or creation failed"
    fi
}

# Create repositories
log_info "Creating repositories..."

# Maven Central proxy
create_proxy_repository "maven-central" "https://repo1.maven.org/maven2/" "RELEASE"

# Hosted repositories
create_hosted_repository "maven-releases" "ALLOW_ONCE" "RELEASE"
create_hosted_repository "maven-snapshots" "ALLOW" "SNAPSHOT"

# Configure security
enable_anonymous_access

# Create publisher role with necessary privileges
create_role "maven-publisher" "Maven Publisher" "Role for publishing Maven artifacts" \
    "nx-repository-view-maven2-maven-releases-*" \
    "nx-repository-view-maven2-maven-snapshots-*" \
    "nx-repository-admin-maven2-maven-releases-*" \
    "nx-repository-admin-maven2-maven-snapshots-*"

# Create publisher user
create_user "publisher" "publisher123" "Publisher" "User" "publisher@example.com" \
    "maven-publisher"

# Test repository accessibility
log_info "Testing repository accessibility..."

test_repository() {
    local repo_name=$1
    if api_call GET "/repository/${repo_name}/" > /dev/null 2>&1; then
        log_success "Repository ${repo_name} is accessible"
    else
        log_warning "Repository ${repo_name} may not be fully accessible"
    fi
}

test_repository "maven-central"
test_repository "maven-releases"
test_repository "maven-snapshots"

# Test authentication with publisher user
log_info "Testing publisher user authentication..."
if curl -f -s -u "publisher:publisher123" "${NEXUS_URL}/service/rest/v1/status" > /dev/null 2>&1; then
    log_success "Publisher user authentication works"
else
    log_warning "Publisher user authentication may have issues"
fi

# Create SBT credentials file
log_info "Creating SBT credentials configuration..."

cat > /tmp/nexus-credentials.sbt << 'EOF'
// Nexus Repository Credentials
// This file should be placed in ~/.sbt/1.0/ or project/ directory

credentials += Credentials(
  "Sonatype Nexus Repository Manager",
  "nexus",
  "admin",
  "20b05303-d54d-434e-8aa6-48cc9ed3de20"
)

// Alternative publisher credentials
// credentials += Credentials(
//   "Sonatype Nexus Repository Manager",
//   "nexus",
//   "publisher",
//   "publisher123"
// )
EOF

log_success "SBT credentials file created at /tmp/nexus-credentials.sbt"

echo ""
echo "================================================================="
log_success "Nexus setup completed successfully!"
echo "================================================================="
echo ""
log_info "Configuration Summary:"
echo "   📍 Nexus URL: ${NEXUS_URL}"
echo "   👤 Admin User: ${NEXUS_ADMIN_USER}"
echo "   🔐 Admin Password: ${NEXUS_ADMIN_PASS}"
echo "   👤 Publisher User: publisher"
echo "   🔐 Publisher Password: publisher123"
echo ""
log_info "Available Repositories:"
echo "   • maven-central (proxy) - Maven Central proxy for dependencies"
echo "   • maven-releases (hosted) - For publishing release versions"
echo "   • maven-snapshots (hosted) - For publishing snapshot versions"
echo ""
log_info "Web Interface:"
echo "   🌐 URL: http://localhost:8081"
echo "   👤 Login: admin / ${NEXUS_ADMIN_PASS}"
echo ""
log_info "SBT Integration:"
echo "   📄 Credentials file created: /tmp/nexus-credentials.sbt"
echo "   💡 Copy to ~/.sbt/1.0/ or use in your build.sbt"
echo ""
log_info "Next Steps:"
echo "   1. Update your build.sbt with proper publishTo settings"
echo "   2. Run 'sbt +publish' to test publishing"
echo "   3. Check repositories in Nexus web interface"
echo ""
echo "================================================================="
