#!/bin/bash

# Gold Financial Books - Enhanced Quick Installer
echo "🏆 Gold Financial Books - Quick Installer"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_user() {
    if [ "$EUID" -eq 0 ]; then
        print_status "Running as root user - this is allowed for system-wide installation"
        INSTALL_AS_ROOT=true
    else
        INSTALL_AS_ROOT=false
    fi
}

get_installation_path() {
    echo
    print_status "Choose installation location:"
    echo "1) Current directory ($(pwd))"
    echo "2) /opt/gold-books (system-wide)"
    echo "3) /var/www/gold-books (web server directory)"
    echo "4) / (root directory)"
    echo "5) Custom path"
    echo
    
    while true; do
        read -p "Select option (1-5): " choice
        case $choice in
            1)
                INSTALL_PATH="$(pwd)/gold-books"
                break
                ;;
            2)
                INSTALL_PATH="/opt/gold-books"
                if [ "$INSTALL_AS_ROOT" = false ]; then
                    print_error "Root privileges required for /opt installation"
                    print_status "Please run with sudo or choose another location"
                    continue
                fi
                break
                ;;
            3)
                INSTALL_PATH="/var/www/gold-books"
                if [ "$INSTALL_AS_ROOT" = false ]; then
                    print_error "Root privileges required for /var/www installation"
                    print_status "Please run with sudo or choose another location"
                    continue
                fi
                break
                ;;
            4)
                INSTALL_PATH="/"
                if [ "$INSTALL_AS_ROOT" = false ]; then
                    print_error "Root privileges required for root directory installation"
                    print_status "Please run with sudo or choose another location"
                    continue
                fi
                print_status "⚠️  Installing to root directory - files will be placed directly in /"
                read -p "Are you sure? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    break
                else
                    continue
                fi
                ;;
            5)
                read -p "Enter custom installation path: " custom_path
                if [ -z "$custom_path" ]; then
                    print_error "Path cannot be empty"
                    continue
                fi
                INSTALL_PATH="$custom_path"
                break
                ;;
            *)
                print_error "Invalid option. Please choose 1-5."
                ;;
        esac
    done
    
    print_success "Installation path: $INSTALL_PATH"
}

create_install_directory() {
    if [ "$INSTALL_PATH" != "/" ]; then
        print_status "Creating installation directory..."
        if [ "$INSTALL_AS_ROOT" = true ]; then
            mkdir -p "$INSTALL_PATH"
            chown -R www-data:www-data "$INSTALL_PATH" 2>/dev/null || true
        else
            mkdir -p "$INSTALL_PATH"
        fi
        print_success "Directory created: $INSTALL_PATH"
    fi
}

install_application() {
    print_status "Installing Gold Financial Books..."
    
    # Check if git is available
    if command -v git &> /dev/null; then
        print_status "📥 Cloning repository..."
        if [ "$INSTALL_PATH" = "/" ]; then
            # Install directly to root
            git clone https://github.com/yourusername/gold-financial-books.git /tmp/gold-books-temp
            cp -r /tmp/gold-books-temp/* /
            rm -rf /tmp/gold-books-temp
            cd /
        else
            git clone https://github.com/yourusername/gold-financial-books.git "$INSTALL_PATH"
            cd "$INSTALL_PATH"
        fi
    else
        print_error "Git is not installed. Please install git first:"
        echo "  sudo apt update && sudo apt install git"
        exit 1
    fi
}

setup_environment() {
    print_status "Setting up environment..."
    
    # Update paths in configuration if not installing to root
    if [ "$INSTALL_PATH" != "/" ]; then
        # Update any hardcoded paths in configuration files
        if [ -f "configure.sh" ]; then
            sed -i "s|DATABASE_PATH=./data/|DATABASE_PATH=$INSTALL_PATH/data/|g" configure.sh
        fi
    fi
    
    # Set proper permissions
    if [ "$INSTALL_AS_ROOT" = true ]; then
        print_status "Setting up permissions for system installation..."
        chown -R www-data:www-data . 2>/dev/null || true
        chmod +x configure.sh 2>/dev/null || true
        chmod +x scripts/*.sh 2>/dev/null || true
    fi
}

# Main installation process
main() {
    echo
    check_user
    get_installation_path
    create_install_directory
    install_application
    setup_environment
    
    # Run automatic setup
    print_status "🔧 Running automatic setup..."
    if [ "$INSTALL_AS_ROOT" = true ] && [ "$INSTALL_PATH" != "/" ]; then
        # For system-wide installations, run as www-data if possible
        if command -v sudo &> /dev/null; then
            sudo -u www-data ./configure.sh 2>/dev/null || ./configure.sh
        else
            ./configure.sh
        fi
    else
        ./configure.sh
    fi
    
    echo
    print_success "🎉 Installation complete!"
    echo
    echo "Installation Details:"
    echo "  📁 Location: $INSTALL_PATH"
    echo "  👤 User: $(whoami)"
    echo "  🔧 Configuration: Complete"
    echo
    echo "Next Steps:"
    if [ "$INSTALL_PATH" = "/" ]; then
        echo "  • Run: npm run dev (from root directory)"
        echo "  • Open: http://localhost:3000"
    else
        echo "  • Navigate: cd $INSTALL_PATH"
        echo "  • Run: npm run dev"
        echo "  • Open: http://localhost:3000"
    fi
    echo "  • Login: admin@goldbooks.com / admin123"
    echo
}

# Run main function
main "$@"
