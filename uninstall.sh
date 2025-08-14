#!/bin/bash

# Gold Financial Books - Ubuntu Uninstall Script
# This script removes the Gold Financial Books application from Ubuntu

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="gold-financial-books"
APP_USER="goldbooks"
APP_DIR="/opt/$APP_NAME"
SERVICE_NAME="gold-financial-books"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to confirm uninstallation
confirm_uninstall() {
    echo -e "${YELLOW}WARNING: This will completely remove Gold Financial Books and all data!${NC}"
    echo -e "${YELLOW}Make sure you have backed up your database before proceeding.${NC}"
    echo
    read -p "Are you sure you want to uninstall? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Uninstallation cancelled."
        exit 0
    fi
}

# Function to stop and disable service
stop_service() {
    print_status "Stopping and disabling service..."
    
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        sudo systemctl stop $SERVICE_NAME
    fi
    
    if sudo systemctl is-enabled --quiet $SERVICE_NAME; then
        sudo systemctl disable $SERVICE_NAME
    fi
    
    # Remove service file
    sudo rm -f /etc/systemd/system/$SERVICE_NAME.service
    sudo systemctl daemon-reload
    
    print_success "Service stopped and disabled"
}

# Function to remove nginx configuration
remove_nginx_config() {
    print_status "Removing nginx configuration..."
    
    sudo rm -f /etc/nginx/sites-available/$APP_NAME
    sudo rm -f /etc/nginx/sites-enabled/$APP_NAME
    
    # Restart nginx
    sudo systemctl restart nginx
    
    print_success "Nginx configuration removed"
}

# Function to remove application directory
remove_app_directory() {
    print_status "Removing application directory..."
    
    sudo rm -rf $APP_DIR
    
    print_success "Application directory removed"
}

# Function to remove application user
remove_app_user() {
    print_status "Removing application user..."
    
    if id "$APP_USER" &>/dev/null; then
        sudo userdel $APP_USER
        print_success "User $APP_USER removed"
    else
        print_warning "User $APP_USER does not exist"
    fi
}

# Function to remove backup script and cron job
remove_backup_script() {
    print_status "Removing backup script and cron job..."
    
    sudo rm -f /usr/local/bin/backup-gold-books
    sudo rm -f /etc/cron.d/gold-books-backup
    
    print_success "Backup script and cron job removed"
}

# Function to remove backups (optional)
remove_backups() {
    if [ -d "/var/backups/gold-financial-books" ]; then
        read -p "Do you want to remove all backups? (yes/no): " -r
        if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            sudo rm -rf /var/backups/gold-financial-books
            print_success "Backups removed"
        else
            print_warning "Backups preserved in /var/backups/gold-financial-books"
        fi
    fi
}

# Main uninstall function
main() {
    echo -e "${RED}=== Gold Financial Books Ubuntu Uninstaller ===${NC}"
    echo
    
    confirm_uninstall
    
    print_status "Starting uninstallation process..."
    
    stop_service
    remove_nginx_config
    remove_app_directory
    remove_app_user
    remove_backup_script
    remove_backups
    
    print_success "Gold Financial Books has been completely uninstalled!"
    echo
    print_warning "Note: Node.js, nginx, and other system packages were not removed."
    print_warning "You can remove them manually if they are no longer needed."
}

# Run main function
main "$@"
