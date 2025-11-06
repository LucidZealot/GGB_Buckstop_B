#!/bin/bash

# Unified AWS Deployment Script for BucStop
# This script configures the application for AWS deployment and then deploys it
# Will need to be edited to work with each new service.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_deploy() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

# Function to get the instance's public IP
get_instance_ip() {
    # Try multiple methods to get the public IP
    local ip=""
    
    # Method 1: AWS metadata service (most reliable for EC2)
    if command -v curl >/dev/null 2>&1; then
        ip=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "")
    fi
    
    # Method 2: Alternative metadata endpoint
    if [ -z "$ip" ] && command -v curl >/dev/null 2>&1; then
        ip=$(curl -s --max-time 5 http://checkip.amazonaws.com 2>/dev/null || echo "")
    fi
    
    # Method 3: Using dig and external service
    if [ -z "$ip" ] && command -v dig >/dev/null 2>&1; then
        ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null || echo "")
    fi
    
    # Method 4: Using wget
    if [ -z "$ip" ] && command -v wget >/dev/null 2>&1; then
        ip=$(wget -qO- --timeout=5 http://checkip.amazonaws.com 2>/dev/null || echo "")
    fi
    
    if [ -z "$ip" ]; then
        print_error "Could not determine instance IP address. Please provide it manually."
        echo "Usage: $0 [IP_ADDRESS]"
        echo "Example: $0 3.232.16.65"
        exit 1
    fi
    
    echo "$ip"
}

# Get IP address (from parameter or auto-detect)
if [ $# -eq 1 ]; then
    INSTANCE_IP="$1"
    print_status "Using provided IP address: $INSTANCE_IP"
else
    print_status "Auto-detecting instance IP address..."
    INSTANCE_IP=$(get_instance_ip)
    print_status "Detected IP address: $INSTANCE_IP"
fi

# Validate IP address format
if ! [[ $INSTANCE_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    print_error "Invalid IP address format: $INSTANCE_IP"
    exit 1
fi

# Required CLI tools
REQUIRED_CMDS=("git" "docker" "docker-compose")

# Check for required tools
check_requirements() {
    print_status "Checking required tools..."
    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! command -v $cmd >/dev/null 2>&1; then
            print_error "Missing required command: $cmd"
            exit 1
        fi
    done
    print_status "All required tools are available"
}

# Function to update appsettings file
update_appsettings() {
    local file_path="$1"
    local service_name="$2"
    local port="$3"
    
    if [ -f "$file_path" ]; then
        # Create backup
        cp "$file_path" "${file_path}.backup"
        print_status "Created backup: ${file_path}.backup"
        
        # Update MicroserviceUrls section
        if grep -q "MicroserviceUrls" "$file_path"; then
            # Update the service URL
            sed -i "s|http://[0-9.]*:[0-9]*/js/${service_name,,}.js|http://${INSTANCE_IP}:${port}/js/${service_name,,}.js|g" "$file_path"
            sed -i "s|http://[0-9.]*:[0-9]*/images/${service_name,,}.jpg|http://${INSTANCE_IP}:${port}/images/${service_name,,}.jpg|g" "$file_path"
            print_status "Updated $file_path with IP $INSTANCE_IP"
        fi
        
        # Update PublicUrls section (for API Gateway)
        if grep -q "PublicUrls" "$file_path"; then
            sed -i "s|http://[0-9.]*:[0-9]*|http://${INSTANCE_IP}:${port}|g" "$file_path"
            print_status "Updated PublicUrls in $file_path with IP $INSTANCE_IP"
        fi
    else
        print_warning "File not found: $file_path"
    fi
}

# Function to update API Gateway appsettings file (special handling for PublicUrls)
update_api_gateway_settings() {
    local file_path="$1"
    
    if [ -f "$file_path" ]; then
        # Create backup
        cp "$file_path" "${file_path}.backup"
        print_status "Created backup: ${file_path}.backup"
        
        # Update PublicUrls section with correct IPs for all services
        if grep -q "PublicUrls" "$file_path"; then
            # Update Snake URL
            sed -i "s|\"Snake\": \"http://[0-9.]*:[0-9]*\"|\"Snake\": \"http://${INSTANCE_IP}:8082\"|g" "$file_path"
            # Update Pong URL
            sed -i "s|\"Pong\": \"http://[0-9.]*:[0-9]*\"|\"Pong\": \"http://${INSTANCE_IP}:8083\"|g" "$file_path"
            # Update Tetris URL
            sed -i "s|\"Tetris\": \"http://[0-9.]*:[0-9]*\"|\"Tetris\": \"http://${INSTANCE_IP}:8084\"|g" "$file_path"
            # Update Buckart URL
            sed -i "s|\"BucKart\": \"http://[0-9.]*:[0-9]*\"|\"BucKart\": \"http://${INSTANCE_IP}:8085\"|g" "$file_path"
            # Update Gateway URL
            sed -i "s|\"Gateway\": \"http://[0-9.]*:[0-9]*\"|\"Gateway\": \"http://${INSTANCE_IP}:8081\"|g" "$file_path"
            
            print_status "Updated API Gateway PublicUrls in $file_path with IP $INSTANCE_IP"
        else
            print_warning "No PublicUrls section found in $file_path"
        fi
    else
        print_warning "File not found: $file_path"
    fi
}

# Cleanup function
cleanup() {
    print_deploy "Cleaning up processes..."
    
    if [ -n "$BUILD_PID" ]; then
        kill "$BUILD_PID" 2>/dev/null
    fi

    # Create Snapshot 
    create_snapshot() {
        print_deploy "Creating snapshot..."
        curl -X POST http://${INSTANCE_IP}:8080/snapshots/create -d "description=Automated snapshot before shutdown" 2>/dev/null || print_warning "Snapshot creation failed"
    }

    create_snapshot

    print_deploy "Stopping Docker containers..."
    docker-compose down

    print_deploy "Pruning unused Docker resources..."
    docker system prune -af --volumes | awk '
        /Deleted Images:/ { skip=1; next }
        /Deleted build cache objects:/ { skip=1; next }
        /^Total reclaimed space:/ {
            skip=0
            print "   🧽  " $0
            next
        }
        skip==0 { print }
    '
}

# Timer display during builds
timer() {
    local start_time=$(date +%s)
    local pid=$1

    echo -n "⏳  Building services... Elapsed time: 00:00"

    while kill -0 "$pid" 2>/dev/null; do
        sleep 1
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        local minutes=$((elapsed / 60))
        local seconds=$((elapsed % 60))
        printf "\r⏳  Building services... Elapsed time: %02d:%02d" "$minutes" "$seconds"
    done

    echo -e "\r✅  Services built in $minutes minutes and $seconds seconds.    "
}

# Bind cleanup to Ctrl+C and termination signals
trap cleanup SIGINT SIGTERM

# =============================================================================
# MAIN DEPLOYMENT PROCESS
# =============================================================================

print_status "Starting unified AWS deployment process for IP: $INSTANCE_IP"

# Change to the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

print_status "Working directory: $PROJECT_ROOT"

# 1. Check requirements
check_requirements

# 2. Pull latest repo updates
print_status "Checking repository status..."
pull_output=$(git pull)
if [[ "$pull_output" == "Already up to date." ]]; then
    print_status "Repo is already up to date."
else
    echo "$pull_output"
fi

# 3. Set environment variables
export env=containers
export GIT_COMMIT=$(git rev-parse HEAD)
print_status "Set environment: $env, Git commit: $GIT_COMMIT"

# 4. Update docker-compose.yml
print_status "Updating docker-compose.yml..."
if [ -f "docker-compose.yml" ]; then
    # Create backup
    cp docker-compose.yml docker-compose.yml.backup
    print_status "Created backup: docker-compose.yml.backup"
    
    # Replace containersLocal with containers
    sed -i 's/containersLocal/containers/g' docker-compose.yml
    print_status "Updated docker-compose.yml: changed containersLocal to containers"
else
    print_error "docker-compose.yml not found in project root"
    exit 1
fi

# 5. Update appsettings.containers.json files
print_status "Updating appsettings.containers.json files..."

# Update each service's appsettings.containers.json
update_appsettings "Team-3-BucStop_Snake/Snake/appsettings.containers.json" "Snake" "8082"
update_appsettings "Team-3-BucStop_Pong/Pong/appsettings.containers.json" "Pong" "8083"
update_appsettings "Team-3-BucStop_Tetris/Tetris/appsettings.containers.json" "Tetris" "8084"
update_appsettings "Team-3-BucStop_BucKart/BucKart/appsettings.containers.json" "BucKart" "8085"

# Update API Gateway appsettings.containers.json (special handling for PublicUrls)
update_api_gateway_settings "Team-3-BucStop_APIGateway/APIGateway/appsettings.containers.json"

# 6. Update main webapp appsettings if it has MicroserviceUrls
print_status "Checking main webapp appsettings..."
if [ -f "Bucstop WebApp/BucStop/appsettings.containers.json" ]; then
    if grep -q "MicroserviceUrls" "Bucstop WebApp/BucStop/appsettings.containers.json"; then
        update_appsettings "Bucstop WebApp/BucStop/appsettings.containers.json" "Main" "8080"
    else
        print_status "Main webapp appsettings doesn't contain MicroserviceUrls, skipping"
    fi
fi

# 7. Clean up Docker resources
print_deploy "Starting cleanup process..."
cleanup

# 8. Deploy the application
print_deploy "Launching microservices..."
(docker-compose up -d > /dev/null 2>&1) &
BUILD_PID=$!
timer $BUILD_PID
print_deploy "All containerized services started successfully!"

# 9. Display summary
print_status "Deployment completed successfully!"
echo ""
echo "Summary of changes:"
echo "==================="
echo "• docker-compose.yml: Changed environment from 'containersLocal' to 'containers'"
echo "• Updated all appsettings.containers.json files to use IP: $INSTANCE_IP"
echo "• Created backup files for all modified files"
echo "• Cleaned up Docker resources to save space"
echo "• Deployed all microservices"
echo ""
echo "Port mappings:"
echo "• Main WebApp: $INSTANCE_IP:8080"
echo "• API Gateway: $INSTANCE_IP:8081"
echo "• Snake Game: $INSTANCE_IP:8082"
echo "• Pong Game: $INSTANCE_IP:8083"
echo "• Tetris Game: $INSTANCE_IP:8084"
echo "• BucKart Game: $INSTANCE_IP:8085"
echo ""
echo "Next steps:"
echo "1. Verify services are accessible at the URLs above"
echo "2. Test the games to ensure they load properly"
echo "3. If issues occur, restore from backup files (remove .backup extension)"
echo ""
print_status "Unified deployment script completed successfully!"
