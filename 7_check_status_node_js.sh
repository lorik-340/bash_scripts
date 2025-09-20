#!/bin/bash

# Script to install Node.js, download artifact, set environment variables and run the application
set -e  # Exit on any error

echo "=== Starting Node.js Installation and Application Setup ==="

# Function to install Node.js and npm
install_nodejs() {
    echo "Step 1: Installing Node.js and npm..."
    
    # Check if Node.js is already installed
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        echo "Node.js and npm are already installed"
        return 0
    fi
    
    # Linux installation
    if command -v apt &> /dev/null; then
        # Ubuntu/Debian
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs npm
    else
        echo "Unsupported Linux distribution. Please install Node.js manually."
        exit 1
    fi
    
    echo "✅ Node.js and npm installed successfully"
}

# Function to print installed versions
print_versions() {
    echo ""
    echo "Step 2: Installed versions:"
    echo "Node.js version: $(node --version)"
    echo "npm version: $(npm --version)"
    echo ""
}

# Function to download and extract artifact
download_artifact() {
    echo "Step 3: Downloading artifact..."
    
    ARTIFACT_URL="https://node-envvars-artifact.s3.eu-west-2.amazonaws.com/bootcamp-node-envvars-project-1.0.0.tgz"
    ARTIFACT_FILE="bootcamp-node-envvars-project-1.0.0.tgz"
    
    # Download using curl (fallback to wget if curl not available)
    if command -v curl &> /dev/null; then
        curl -o "$ARTIFACT_FILE" "$ARTIFACT_URL"
    elif command -v wget &> /dev/null; then
        wget -O "$ARTIFACT_FILE" "$ARTIFACT_URL"
    else
        echo "Error: Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    # Check if download was successful
    if [ ! -f "$ARTIFACT_FILE" ]; then
        echo "Error: Failed to download artifact"
        exit 1
    fi
    
    echo "✅ Artifact downloaded successfully"
    
    # Extract the tar.gz file
    echo "Step 4: Extracting artifact..."
    tar -xzf "$ARTIFACT_FILE"
    
    if [ ! -d "package" ]; then
        echo "Error: Extraction failed or didn't create 'package' directory"
        exit 1
    fi
    
    echo "✅ Artifact extracted successfully"
}

# Function to check if application is running
check_application_status() {
    echo ""
    echo "Step 9: Checking application status..."
    sleep 3  # Give the application a moment to start
    
    # Find the Node.js process running server.js
    APP_PROCESS=$(ps aux | grep "[n]ode server.js" | head -n 1)
    
    if [ -z "$APP_PROCESS" ]; then
        echo "❌ ERROR: Application failed to start - no Node.js process found"
        echo "Checking for error messages..."
        
        # Look for any error in the package directory
        if [ -f "npm-debug.log" ]; then
            echo "Found npm debug log. Last few lines:"
            tail -5 npm-debug.log
        fi
        
        exit 1
    fi
    
    # Extract process info
    PID=$(echo "$APP_PROCESS" | awk '{print $2}')
    USER=$(echo "$APP_PROCESS" | awk '{print $1}')
    CPU=$(echo "$APP_PROCESS" | awk '{print $3}')
    MEM=$(echo "$APP_PROCESS" | awk '{print $4}')
    COMMAND=$(echo "$APP_PROCESS" | awk '{for(i=11;i<=NF;i++) printf $i" "; print ""}')
    
    echo "✅ Application successfully started!"
    echo ""
    echo "=== APPLICATION PROCESS INFO ==="
    echo "Process ID (PID): $PID"
    echo "Running as user: $USER"
    echo "CPU usage: $CPU%"
    echo "Memory usage: $MEM%"
    echo "Command: $COMMAND"
    
    # Check what port the application is listening on
    echo ""
    echo "=== NETWORK LISTENING PORTS ==="
    
    # Check using netstat (if available)
    if command -v netstat &> /dev/null; then
        echo "Netstat output:"
        netstat -tlnp 2>/dev/null | grep "$PID/node" || echo "No netstat listening info found"
    fi
    
    # Check using ss (if available) - more modern alternative to netstat
    if command -v ss &> /dev/null; then
        echo ""
        echo "SS output:"
        ss -tlnp 2>/dev/null | grep "$PID/node" || echo "No ss listening info found"
    fi
    
    # Alternative: check what ports Node.js might be listening on
    echo ""
    echo "Checking for listening Node.js processes:"
    lsof -i -P -n 2>/dev/null | grep "node" | grep "LISTEN" || echo "No lsof listening info found"
    
    # Try to find port from process environment or command line
    PORT_INFO=$(ps -p $PID -o command= | grep -o "port[ =]\?[0-9]*" | head -1)
    if [ ! -z "$PORT_INFO" ]; then
        echo ""
        echo "Port information from process: $PORT_INFO"
    fi
    
    echo ""
    echo "=== APPLICATION STATUS: RUNNING ✅ ==="
    echo "The Node.js application is successfully running as process ID: $PID"
    echo "Use 'kill $PID' to stop the application when needed"
}

# Function to set environment variables and run application
setup_and_run() {
    echo "Step 5: Setting environment variables..."
    
    # Set environment variables
    export APP_ENV=dev
    export DB_USER=db_user
    export DB_PWD=mysecret
    
    echo "Environment variables set:"
    echo "  APP_ENV=$APP_ENV"
    echo "  DB_USER=$DB_USER"
    echo "  DB_PWD=******"  # Don't print the actual password
    
    # Change to package directory
    echo "Step 6: Changing to package directory..."
    cd package
    
    if [ ! -f "package.json" ]; then
        echo "Error: package.json not found in the extracted directory"
        exit 1
    fi
    
    echo "Step 7: Installing npm dependencies..."
    npm install
    
    echo "Step 8: Starting the Node.js application..."
    echo "=== Application Output ==="
    
    # Run the application in background so we can check its status
    node server.js &
    APP_PID=$!
    
    # Store the PID so we can check it later
    echo $APP_PID > /tmp/node_app.pid
    
    # Give it a moment to start, then check status
    sleep 2
}

# Main execution
main() {
    install_nodejs
    print_versions
    download_artifact
    setup_and_run
    check_application_status
    
    echo ""
    echo "=== Setup Complete ==="
    echo "The application is running in the background."
    echo "To stop it, use: kill $(cat /tmp/node_app.pid 2>/dev/null)"
    echo "To view logs, check the terminal output above."
}

# Cleanup function
cleanup() {
    if [ -f "/tmp/node_app.pid" ]; then
        kill $(cat /tmp/node_app.pid) 2>/dev/null || true
        rm -f /tmp/node_app.pid
    fi
}

# Set trap to cleanup on script exit
trap cleanup EXIT

# Run the main function
main