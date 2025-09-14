#!/bin/bash

echo "========================================="
echo "    Ubuntu System Information"
echo "========================================="
echo

# 1. Distribution Information
echo "1. DISTRIBUTION:"
cat /etc/os-release | grep -E "NAME=|VERSION="
echo

# 2. Package Manager Information
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

# 3. CLI Editor Configuration
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

# 4. Software Center
echo "4. SOFTWARE CENTER:"

if command -v mintinstall &>/dev/null; then
    echo "Linux Mint Software Manager (mintinstall) is available"
elif command -v gnome-software &>/dev/null; then
    echo "GNOME Software Center is available"
else
    echo "No GUI software manager found"
fi
echo

# 5. User's Shell
echo "5. USER'S SHELL:"
echo "Default Login Shell: $SHELL"
echo
echo "========================================="