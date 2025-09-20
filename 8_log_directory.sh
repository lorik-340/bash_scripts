#!/bin/bash

# Script to install Node.js, download artifact, set environment variables and run the application
set -e  # Exit on any error

# Function to display usage
usage() {
    echo "Usage: $0 [log_directory]"
    echo "  log_directory: Directory where application will write logs (optional)"
    echo "  If not provided, logs will be written to default location"
    exit 1
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

echo "=== Starting Node.js Installation and Application Setup ==="

# Function to setup log directory
setup_log_directory() {
    local log_dir="$1"
    
    echo "Step 0: Setting up log directory..."
    
    # If no log directory provided, use default and skip setup
    if [ -z "$log_dir" ]; then
        echo "No log directory specified. Using application default."
        return 0
    fi
    
    # Check if it's an absolute path, if not make it absolute
    if [[ "$log_dir" != /* ]]; then
        log_dir="$(pwd)/$log_dir"
        echo "Converted to absolute path: $log_dir"
    fi
    
    # Check if the path exists and is a directory
    if [ -e "$log_dir" ]; then
        if [ -d "$log_dir" ]; then
            echo "✅ Log directory already exists: $log_dir"
        else
            echo "❌ Error: '$log_dir' exists but is not a directory"
            exit 1
        fi
    else
        # Create the directory and parent directories
        echo "Creating log directory: $log_dir"
        mkdir -p "$log_dir"
        
        if [ $? -eq 0 ]; then
            echo "✅ Log directory created successfully: $log_dir"
        else
            echo "❌ Error: Failed to create log directory: $log_dir"
            exit 1
        fi
    fi
    
    # Check if we have write permissions
    if [ ! -w "$log_dir" ]; then
        echo "❌ Error: No write permission for log directory: $log_dir"
        exit 1
    fi
    
    # Set the LOG_DIR environment variable
    export LOG_DIR="$log_dir"
    echo "✅ Environment variable set: LOG_DIR=$LOG_DIR"
    
    # Create app.log file if it doesn't exist and ensure writable
    touch "$LOG_DIR/app.log" 2>/dev/null || true
    if [ ! -w "$LOG_DIR/app.log" ] 2>/dev/null; then
        echo "⚠️  Warning: Cannot write to app.log in log directory"
    else
        echo "✅ app.log file is writable in log directory"
    fi
}

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
    echo "Step 8: Checking application status..."
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
    
    # Check log directory status
    echo ""
    echo "=== LOG DIRECTORY STATUS ==="
    if [ ! -z "$LOG_DIR" ]; then
        echo "Log directory: $LOG_DIR"
        echo "app.log status: $(ls -la "$LOG_DIR/app.log" 2>/dev/null || echo "Not found")"
        
        # Check if logs are being written
        if [ -f "$LOG_DIR/app.log" ]; then
            echo "Recent log entries:"
            tail -3 "$LOG_DIR/app.log" 2>/dev/null || echo "No log content yet"
        fi
    else
        echo "Using default log location (check application output)"
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
    
    if [ ! -z "$LOG_DIR" ]; then
        echo "  LOG_DIR=$LOG_DIR"
    fi
    
    # Change to package directory
    echo "Step 6: Changing to package directory..."
    cd package
    
    if [ ! -f "package.json" ]; then
        echo "Error: package.json not found in the extracted directory"
        exit 1
    fi
    
    echo "Step 7: Installing npm dependencies..."
    npm install
    
    echo "Starting the Node.js application..."
    echo "=== Application Output ==="
    
    # Run the application in background so we can check its status
    node server.js &
    APP_PID=$!
    
    # Store the PID so we can check it later
    echo $APP_PID > /tmp/node_app.pid
}

# Main execution
main() {
    local log_directory="$1"
    
    setup_log_directory "$log_directory"
    install_nodejs
    print_versions
    download_artifact
    setup_and_run
    check_application_status
    
    echo ""
    echo "=== Setup Complete ==="
    echo "The application is running in the background."
    echo "To stop it, use: kill $(cat /tmp/node_app.pid 2>/dev/null)"
    
    if [ ! -z "$LOG_DIR" ]; then
        echo "Logs are being written to: $LOG_DIR/app.log"
        echo "To view logs in real-time: tail -f \"$LOG_DIR/app.log\""
    fi
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

# Run the main function with first argument as log directory
main "$1"