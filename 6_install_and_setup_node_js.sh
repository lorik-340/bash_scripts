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
        sudo apt-get install -y nodejs 
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
    
    # Run the application (this will run in foreground)
    node server.js
}



# Main execution
main() {
    install_nodejs
    print_versions
    download_artifact
    setup_and_run
}

# Run the main function
main