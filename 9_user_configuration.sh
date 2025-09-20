#!/bin/bash

# Script to install Node.js, download artifact, set environment variables and run the application
set -e  # Exit on any error

# Service user configuration
SERVICE_USER="myapp"
SERVICE_GROUP="myapp"

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

# Function to create service user and group
create_service_user() {
    echo "Step 0: Creating service user and group..."
    
    # Check if group already exists
    if getent group "$SERVICE_GROUP" >/dev/null; then
        echo "✅ Group '$SERVICE_GROUP' already exists"
    else
        echo "Creating group '$SERVICE_GROUP'..."
        sudo groupadd "$SERVICE_GROUP"
        echo "✅ Group '$SERVICE_GROUP' created successfully"
    fi
    
    # Check if user already exists
    if id "$SERVICE_USER" &>/dev/null; then
        echo "✅ User '$SERVICE_USER' already exists"
    else
        echo "Creating user '$SERVICE_USER'..."
        sudo useradd -r -s /bin/false -g "$SERVICE_GROUP" "$SERVICE_USER"
        echo "✅ User '$SERVICE_USER' created successfully"
    fi
    
    # Display user information
    echo "Service user details:"
    id "$SERVICE_USER"
    echo ""
}

# Function to setup log directory with proper permissions
setup_log_directory() {
    local log_dir="$1"
    
    echo "Step 1: Setting up log directory..."
    
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
        sudo mkdir -p "$log_dir"
        
        if [ $? -eq 0 ]; then
            echo "✅ Log directory created successfully: $log_dir"
        else
            echo "❌ Error: Failed to create log directory: $log_dir"
            exit 1
        fi
    fi
    
    # Set ownership to service user
    echo "Setting ownership of log directory to $SERVICE_USER:$SERVICE_GROUP..."
    sudo chown "$SERVICE_USER:$SERVICE_GROUP" "$log_dir"
    sudo chmod 755 "$log_dir"
    
    # Set the LOG_DIR environment variable
    export LOG_DIR="$log_dir"
    echo "✅ Environment variable set: LOG_DIR=$LOG_DIR"
    
    # Create app.log file with proper permissions
    sudo touch "$LOG_DIR/app.log"
    sudo chown "$SERVICE_USER:$SERVICE_GROUP" "$LOG_DIR/app.log"
    sudo chmod 644 "$LOG_DIR/app.log"
    
    echo "✅ app.log file created with proper permissions"
}

# Function to install Node.js and npm
install_nodejs() {
    echo "Step 2: Installing Node.js and npm..."
    
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
    echo "Step 3: Installed versions:"
    echo "Node.js version: $(node --version)"
    echo "npm version: $(npm --version)"
    echo ""
}

# Function to download and extract artifact
download_artifact() {
    echo "Step 4: Downloading artifact..."
    
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
    echo "Step 5: Extracting artifact..."
    tar -xzf "$ARTIFACT_FILE"
    
    if [ ! -d "package" ]; then
        echo "Error: Extraction failed or didn't create 'package' directory"
        exit 1
    fi
    
    echo "✅ Artifact extracted successfully"
    
    # Set ownership of package directory to service user
    echo "Setting ownership of package directory to $SERVICE_USER:$SERVICE_GROUP..."
    sudo chown -R "$SERVICE_USER:$SERVICE_GROUP" package
    echo "✅ Package directory ownership set"
}

# Function to install npm dependencies as service user
install_dependencies() {
    echo "Step 6: Installing npm dependencies as $SERVICE_USER..."
    
    # Change ownership of npm cache directory to allow service user to install
    if [ -d ~/.npm ]; then
        sudo chown -R "$SERVICE_USER" ~/.npm
    fi
    
    # Install dependencies as service user
    sudo -u "$SERVICE_USER" sh -c "cd package && npm install"
    
    if [ $? -eq 0 ]; then
        echo "✅ Dependencies installed successfully"
    else
        echo "❌ Error: Failed to install dependencies"
        exit 1
    fi
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
        if [ -f "package/npm-debug.log" ]; then
            echo "Found npm debug log. Last few lines:"
            tail -5 package/npm-debug.log
        fi
        
        # Check log file for errors
        if [ ! -z "$LOG_DIR" ] && [ -f "$LOG_DIR/app.log" ]; then
            echo "Log file content:"
            tail -10 "$LOG_DIR/app.log"
        fi
        
        exit 1
    fi
    
    # Extract process info
    PID=$(echo "$APP_PROCESS" | awk '{print $2}')
    USER=$(echo "$APP_PROCESS" | awk '{print $1}')
    CPU=$(echo "$APP_PROCESS" | awk '{print $3}')
    MEM=$(echo "$APP_PROCESS" | awk '{print $4}')
    COMMAND=$(echo "$APP_PROCESS" | awk '{for(i=11;i<=NF;i++) printf $i" "; print ""}')
    
    # Verify it's running as the service user
    if [ "$USER" != "$SERVICE_USER" ]; then
        echo "⚠️  Warning: Application is running as $USER instead of $SERVICE_USER"
    else
        echo "✅ Application successfully started as service user: $SERVICE_USER"
    fi
    
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
    
    # Check using ss (if available) - more modern alternative to netstat
    if command -v ss &> /dev/null; then
        ss -tlnp 2>/dev/null | grep "$PID/node" || echo "No listening ports found yet"
    fi
    
    # Check log directory status
    echo ""
    echo "=== LOG DIRECTORY STATUS ==="
    if [ ! -z "$LOG_DIR" ]; then
        echo "Log directory: $LOG_DIR"
        echo "Ownership: $(ls -ld "$LOG_DIR" | awk '{print $3":"$4}')"
        echo "app.log status: $(ls -la "$LOG_DIR/app.log" 2>/dev/null || echo "Not found")"
        
        # Check if logs are being written
        if [ -f "$LOG_DIR/app.log" ]; then
            echo "Recent log entries:"
            sudo tail -3 "$LOG_DIR/app.log" 2>/dev/null || echo "No log content yet or permission denied"
        fi
    else
        echo "Using default log location"
    fi
    
    echo ""
    echo "=== APPLICATION STATUS: RUNNING ✅ ==="
    echo "The Node.js application is successfully running as user: $USER"
    echo "Process ID: $PID"
    echo "Use 'sudo kill $PID' to stop the application when needed"
}

# Function to set environment variables and run application
setup_and_run() {
    echo "Step 7: Setting environment variables..."
    
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
    
    echo "Step 8: Starting the Node.js application as $SERVICE_USER..."
    echo "=== Application Output ==="
    
    # Run the application as service user with environment variables
    sudo -u "$SERVICE_USER" \
        APP_ENV="$APP_ENV" \
        DB_USER="$DB_USER" \
        DB_PWD="$DB_PWD" \
        LOG_DIR="$LOG_DIR" \
        sh -c "cd package && node server.js" &
    
    APP_PID=$!
    
    # Store the PID so we can check it later
    echo $APP_PID > /tmp/node_app.pid
}

# Main execution
main() {
    local log_directory="$1"
    
    create_service_user
    setup_log_directory "$log_directory"
    install_nodejs
    print_versions
    download_artifact
    install_dependencies
    setup_and_run
    check_application_status
    
    echo ""
    echo "=== Setup Complete ==="
    echo "The application is running in the background as user: $SERVICE_USER"
    echo "To stop it, use: sudo kill $(cat /tmp/node_app.pid 2>/dev/null)"
    
    if [ ! -z "$LOG_DIR" ]; then
        echo "Logs are being written to: $LOG_DIR/app.log"
        echo "To view logs: sudo tail -f \"$LOG_DIR/app.log\""
    fi
    
    echo ""
    echo "Service user information:"
    echo "  Username: $SERVICE_USER"
    echo "  Group: $SERVICE_GROUP"
    echo "  Home directory: $(getent passwd "$SERVICE_USER" | cut -d: -f6)"
}

# Cleanup function
cleanup() {
    if [ -f "/tmp/node_app.pid" ]; then
        PID=$(cat /tmp/node_app.pid)
        if ps -p $PID > /dev/null; then
            sudo kill $PID 2>/dev/null || true
        fi
        rm -f /tmp/node_app.pid
    fi
}

# Set trap to cleanup on script exit
trap cleanup EXIT

# Run the main function with first argument as log directory
main "$1"