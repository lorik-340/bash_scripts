# EXERCISE 1: Linux Ubuntu Virtual Machine

Create a Linux Ubuntu Virtual Machine on your computer. Check the distribution, which package manager it uses (yum, apt, apt-get). Which CLI editor is configured (Nano, Vi, Vim). What software center/software manager it uses. Which shell is configured for your user.

### Solution:
```
#!/bin/bash

echo "========================================="
echo "    Ubuntu System Information"
echo "========================================="
echo


echo "1. DISTRIBUTION:"
cat /etc/os-release | grep -E "NAME=|VERSION="
echo

echo "2. PACKAGE MANAGER:"
if command -v apt &>/dev/null; then
    echo "apt is available"
fi
if command -v apt-get &>/dev/null; then
    echo "apt-get is available"
fi
if command -v yum &>/dev/null; then
    echo "yum is available"
fi
echo

# Check for the lower-level dpkg as well
if command -v dpkg &> /dev/null; then
    echo "Underlying Tool: DPKG ($(dpkg --version | head -n 1))"
fi
echo

# Check for universal package managers common on Ubuntu
echo "Also available:"
if command -v snap &> /dev/null; then
    echo " - Snap: $(snap --version | head -n 1)"
fi
if command -v flatpak &> /dev/null; then
    echo " - Flatpak: $(flatpak --version | head -n 1)"
fi
echo


echo "3. CONFIGURED CLI EDITOR:"
# Check environment variables first
if [ -n "$EDITOR" ]; then
    echo "EDITOR variable is set to: $EDITOR"
elif [ -n "$VISUAL" ]; then
    echo "VISUAL variable is set to: $VISUAL"
else
    echo "Neither \$EDITOR nor \$VISUAL are set. Checking common editors..."
    # Check which editors are installed to guess the default
    for editor in nano vim vi nvim; do
        if command -v $editor &> /dev/null; then
            echo " Found installed editor: $(which $editor)"
        else
            echo "$editor not found"
        fi
    done
    echo " (On Ubuntu, the default is usually 'nano')"
fi
echo


echo "4. SOFTWARE CENTER:"

if command -v mintinstall &>/dev/null; then
    echo "Linux Mint Software Manager (mintinstall) is available"
elif command -v gnome-software &>/dev/null; then
    echo "GNOME Software Center is available"
else
    echo "No GUI software manager found"
fi
echo


echo "5. USER'S SHELL:"
echo "Default Login Shell: $SHELL"
echo
echo "========================================="
```

# EXERCISE 2: Bash Script - Install Java
Write a bash script using Vim editor that installs the latest java version and checks whether java was installed successfully by executing a java -version command. Checks if it was successful and prints a success message, if not prints a failure message.

### Solution:
```

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
```