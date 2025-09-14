#!/bin/bash

# Script: install_java.sh
# Description: Installs the latest Java JDK (from the default Ubuntu repo) and verifies the installation.

echo "========================================="
echo "Starting Java installation process..."
echo "========================================="

echo
# 1. Update the package list
echo "======== Step 1: Updating package lists... ========"
sudo apt update -y

echo

# 2. Install the latest Java JDK (OpenJDK)
# The 'default-jdk' package will pull in the latest stable version.
echo "======== Step 2: Installing the latest Java JDK... ========"
sudo apt install -y default-jdk

echo

# 3. Check if the installation was successful by checking the exit status of the apt command.
if [ $? -eq 0 ]; then
    echo "Package installation completed without errors."
else
    echo "ERROR: Package installation failed!" >&2
    exit 1
fi

echo

# 4. Verify the installation by checking the Java version
echo "======== Step 3: Verifying Java installation... ========"
java_version_output=$(java -version 2>&1) # Capture both standard output and standard error

# Check the exit status of the java -version command
if [ $? -eq 0 ]; then
    echo "SUCCESS: Java was installed successfully!"
    echo "Java Version Details:"
    echo "$java_version_output"
else
    echo "FAILURE: Java was not installed correctly. The 'java -version' command failed." >&2
    echo "Command output: $java_version_output" >&2
    exit 1
fi
echo
echo "----------------------------------------"
echo "Script execution finished."