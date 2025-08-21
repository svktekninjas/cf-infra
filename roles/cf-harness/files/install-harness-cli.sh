#!/bin/bash

# Harness CLI Installation Script
# This script installs the Harness CLI on the local system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to detect OS and architecture
detect_system() {
    OS=$(uname -s)
    ARCH=$(uname -m)
    
    if [[ "$OS" == "Darwin" ]]; then
        if [[ "$ARCH" == "arm64" ]]; then
            PLATFORM="Darwin-arm64"
        else
            PLATFORM="Darwin-x86_64"
        fi
    elif [[ "$OS" == "Linux" ]]; then
        if [[ "$ARCH" == "x86_64" ]]; then
            PLATFORM="Linux-x86_64"
        elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
            PLATFORM="Linux-arm64"
        else
            PLATFORM="Linux-x86_64"
        fi
    else
        print_message $RED "Unsupported operating system: $OS"
        exit 1
    fi
    
    print_message $GREEN "Detected system: $OS $ARCH (Platform: $PLATFORM)"
}

# Function to check if Harness CLI is already installed
check_existing_installation() {
    if command -v harness &> /dev/null; then
        CURRENT_VERSION=$(harness --version 2>/dev/null || echo "unknown")
        print_message $YELLOW "Harness CLI is already installed (version: $CURRENT_VERSION)"
        read -p "Do you want to reinstall/update? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_message $GREEN "Installation cancelled."
            exit 0
        fi
    fi
}

# Function to download and install Harness CLI
install_harness_cli() {
    print_message $GREEN "Downloading Harness CLI for $PLATFORM..."
    
    # Get the latest release URL
    DOWNLOAD_URL="https://github.com/harness/harness-cli/releases/latest/download/harness-${PLATFORM}"
    
    # Download to temp location
    TEMP_FILE="/tmp/harness-cli-download"
    curl -L -o "$TEMP_FILE" "$DOWNLOAD_URL" || {
        print_message $RED "Failed to download Harness CLI"
        exit 1
    }
    
    # Make executable
    chmod +x "$TEMP_FILE"
    
    # Move to installation directory
    INSTALL_DIR="/usr/local/bin"
    if [[ -w "$INSTALL_DIR" ]]; then
        mv "$TEMP_FILE" "$INSTALL_DIR/harness"
    else
        print_message $YELLOW "Need sudo access to install to $INSTALL_DIR"
        sudo mv "$TEMP_FILE" "$INSTALL_DIR/harness"
    fi
    
    print_message $GREEN "Harness CLI installed successfully!"
}

# Function to verify installation
verify_installation() {
    if command -v harness &> /dev/null; then
        VERSION=$(harness --version)
        print_message $GREEN "✓ Harness CLI installed successfully"
        print_message $GREEN "  Version: $VERSION"
        print_message $GREEN "  Location: $(which harness)"
    else
        print_message $RED "✗ Installation verification failed"
        exit 1
    fi
}

# Function to configure Harness CLI
configure_harness_cli() {
    print_message $YELLOW "\nHarness CLI Configuration"
    print_message $YELLOW "========================="
    
    read -p "Do you want to configure Harness CLI now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your Harness Account ID: " ACCOUNT_ID
        read -sp "Enter your Harness API Key: " API_KEY
        echo
        
        if [[ -n "$ACCOUNT_ID" ]] && [[ -n "$API_KEY" ]]; then
            print_message $GREEN "Configuring Harness CLI..."
            harness login --api-key "$API_KEY" --account-id "$ACCOUNT_ID" || {
                print_message $RED "Failed to configure Harness CLI"
                print_message $YELLOW "You can configure it later using: harness login --api-key <key> --account-id <id>"
            }
        else
            print_message $YELLOW "Configuration skipped. You can configure later using:"
            print_message $YELLOW "  harness login --api-key <key> --account-id <id>"
        fi
    fi
}

# Main execution
main() {
    print_message $GREEN "========================================="
    print_message $GREEN "     Harness CLI Installation Script     "
    print_message $GREEN "========================================="
    echo
    
    detect_system
    check_existing_installation
    install_harness_cli
    verify_installation
    configure_harness_cli
    
    echo
    print_message $GREEN "========================================="
    print_message $GREEN "        Installation Complete!           "
    print_message $GREEN "========================================="
    print_message $GREEN "\nNext steps:"
    print_message $GREEN "  1. Run 'harness --help' to see available commands"
    print_message $GREEN "  2. Configure authentication if not done: harness login"
    print_message $GREEN "  3. Set default project: harness config set --project <project-id>"
    print_message $GREEN "  4. List resources: harness <resource> list"
    echo
}

# Run main function
main "$@"