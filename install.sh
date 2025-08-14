#!/bin/bash

# Gold Financial Books - Ubuntu Installation Script
# This script installs and configures the Gold Financial Books application on Ubuntu

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
PORT=3000

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

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Function to check Ubuntu version
check_ubuntu() {
    if ! grep -q "Ubuntu" /etc/os-release; then
        print_error "This script is designed for Ubuntu. Other distributions may not be supported."
        exit 1
    fi
    
    print_success "Ubuntu detected"
}

# Function to install Node.js
install_nodejs() {
    print_status "Installing Node.js..."
    
    # Check if Node.js is already installed
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_warning "Node.js is already installed: $NODE_VERSION"
        
        # Check if version is compatible (v18 or higher)
        if [[ $(echo $NODE_VERSION | cut -d'v' -f2 | cut -d'.' -f1) -lt 18 ]]; then
            print_warning "Node.js version is too old. Installing newer version..."
        else
            print_success "Node.js version is compatible"
            return 0
        fi
    fi
    
    # Install Node.js 20.x
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    print_success "Node.js installed: $(node --version)"
    print_success "npm installed: $(npm --version)"
}

# Function to install system dependencies
install_dependencies() {
    print_status "Installing system dependencies..."
    
    sudo apt-get update
    sudo apt-get install -y \
        curl \
        wget \
        git \
        build-essential \
        python3 \
        python3-pip \
        sqlite3 \
        nginx \
        ufw \
        certbot \
        python3-certbot-nginx
    
    print_success "System dependencies installed"
}

# Function to create application user
create_app_user() {
    print_status "Creating application user..."
    
    if id "$APP_USER" &>/dev/null; then
        print_warning "User $APP_USER already exists"
    else
        sudo useradd --system --shell /bin/bash --home-dir $APP_DIR --create-home $APP_USER
        print_success "User $APP_USER created"
    fi
}

# Function to setup application directory
setup_app_directory() {
    print_status "Setting up application directory..."
    
    # Create directory if it doesn't exist
    sudo mkdir -p $APP_DIR
    
    # Copy application files
    sudo cp -r . $APP_DIR/
    
    # Set ownership
    sudo chown -R $APP_USER:$APP_USER $APP_DIR
    
    # Set permissions
    sudo chmod -R 755 $APP_DIR
    
    print_success "Application directory setup complete"
}

# Function to install npm dependencies
install_npm_dependencies() {
    print_status "Installing npm dependencies..."
    
    cd $APP_DIR
    sudo -u $APP_USER npm install --production
    
    print_success "npm dependencies installed"
}

# Function to build the application
build_application() {
    print_status "Building the application..."
    
    cd $APP_DIR
    sudo -u $APP_USER npm run build
    
    print_success "Application built successfully"
}

# Function to setup database
setup_database() {
    print_status "Setting up database..."
    
    cd $APP_DIR
    
    # Create database directory
    sudo -u $APP_USER mkdir -p data
    
    # Initialize database with schema
    sudo -u $APP_USER sqlite3 data/gold_financial.db < scripts/01-create-tables.sql
    
    # Set proper permissions
    sudo chmod 660 data/gold_financial.db
    sudo chown $APP_USER:$APP_USER data/gold_financial.db
    
    print_success "Database setup complete"
}

# Function to create environment file
create_env_file() {
    print_status "Creating environment configuration..."
    
    # Generate a random JWT secret
    JWT_SECRET=$(openssl rand -base64 32)
    
    cat << EOF | sudo tee $APP_DIR/.env > /dev/null
# Gold Financial Books Configuration
NODE_ENV=production
PORT=$PORT
JWT_SECRET=$JWT_SECRET
DATABASE_PATH=./data/gold_financial.db

# Application URLs
NEXT_PUBLIC_APP_URL=http://localhost:$PORT
EOF
    
    sudo chown $APP_USER:$APP_USER $APP_DIR/.env
    sudo chmod 600 $APP_DIR/.env
    
    print_success "Environment file created"
}

# Function to create systemd service
create_systemd_service() {
    print_status "Creating systemd service..."
    
    cat << EOF | sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null
[Unit]
Description=Gold Financial Books Application
After=network.target

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
ExecStart=/usr/bin/npm start
Restart=on-failure
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
    
    print_success "Systemd service created and enabled"
}

# Function to configure nginx
configure_nginx() {
    print_status "Configuring nginx..."
    
    cat << EOF | sudo tee /etc/nginx/sites-available/$APP_NAME > /dev/null
server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
    
    # Enable the site
    sudo ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
    
    # Remove default nginx site
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test nginx configuration
    sudo nginx -t
    
    # Restart nginx
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    
    print_success "Nginx configured and restarted"
}

# Function to configure firewall
configure_firewall() {
    print_status "Configuring firewall..."
    
    # Enable UFW
    sudo ufw --force enable
    
    # Allow SSH
    sudo ufw allow ssh
    
    # Allow HTTP and HTTPS
    sudo ufw allow 'Nginx Full'
    
    # Show status
    sudo ufw status
    
    print_success "Firewall configured"
}

# Function to start services
start_services() {
    print_status "Starting services..."
    
    # Start the application
    sudo systemctl start $SERVICE_NAME
    
    # Check status
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        print_success "Gold Financial Books service started successfully"
    else
        print_error "Failed to start Gold Financial Books service"
        sudo systemctl status $SERVICE_NAME
        exit 1
    fi
}

# Function to create backup script
create_backup_script() {
    print_status "Creating backup script..."
    
    cat << 'EOF' | sudo tee /usr/local/bin/backup-gold-books > /dev/null
#!/bin/bash

# Gold Financial Books Backup Script
BACKUP_DIR="/var/backups/gold-financial-books"
APP_DIR="/opt/gold-financial-books"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
cp $APP_DIR/data/gold_financial.db $BACKUP_DIR/gold_financial_$DATE.db

# Backup environment file
cp $APP_DIR/.env $BACKUP_DIR/env_$DATE.backup

# Keep only last 30 backups
find $BACKUP_DIR -name "*.db" -mtime +30 -delete
find $BACKUP_DIR -name "*.backup" -mtime +30 -delete

echo "Backup completed: $DATE"
EOF
    
    sudo chmod +x /usr/local/bin/backup-gold-books
    
    # Create daily backup cron job
    echo "0 2 * * * root /usr/local/bin/backup-gold-books" | sudo tee /etc/cron.d/gold-books-backup > /dev/null
    
    print_success "Backup script created and scheduled"
}

# Function to display final information
display_final_info() {
    print_success "Installation completed successfully!"
    echo
    echo -e "${GREEN}=== Gold Financial Books Installation Summary ===${NC}"
    echo -e "Application Directory: ${BLUE}$APP_DIR${NC}"
    echo -e "Service Name: ${BLUE}$SERVICE_NAME${NC}"
    echo -e "Application User: ${BLUE}$APP_USER${NC}"
    echo -e "Port: ${BLUE}$PORT${NC}"
    echo -e "Database: ${BLUE}$APP_DIR/data/gold_financial.db${NC}"
    echo
    echo -e "${GREEN}=== Access Information ===${NC}"
    echo -e "Local Access: ${BLUE}http://localhost${NC}"
    echo -e "Direct Access: ${BLUE}http://localhost:$PORT${NC}"
    echo
    echo -e "${GREEN}=== Useful Commands ===${NC}"
    echo -e "Start service: ${BLUE}sudo systemctl start $SERVICE_NAME${NC}"
    echo -e "Stop service: ${BLUE}sudo systemctl stop $SERVICE_NAME${NC}"
    echo -e "Restart service: ${BLUE}sudo systemctl restart $SERVICE_NAME${NC}"
    echo -e "Check status: ${BLUE}sudo systemctl status $SERVICE_NAME${NC}"
    echo -e "View logs: ${BLUE}sudo journalctl -u $SERVICE_NAME -f${NC}"
    echo -e "Backup database: ${BLUE}sudo /usr/local/bin/backup-gold-books${NC}"
    echo
    echo -e "${YELLOW}=== Next Steps ===${NC}"
    echo "1. Access the application at http://localhost"
    echo "2. Create your first user account"
    echo "3. Start managing your gold portfolio!"
    echo
    echo -e "${YELLOW}=== Security Notes ===${NC}"
    echo "- Change the default JWT secret in $APP_DIR/.env"
    echo "- Consider setting up SSL with: sudo certbot --nginx"
    echo "- Regular backups are scheduled daily at 2 AM"
}

# Main installation function
main() {
    echo -e "${GREEN}=== Gold Financial Books Ubuntu Installer ===${NC}"
    echo
    
    check_root
    check_ubuntu
    
    print_status "Starting installation process..."
    
    install_dependencies
    install_nodejs
    create_app_user
    setup_app_directory
    install_npm_dependencies
    build_application
    setup_database
    create_env_file
    create_systemd_service
    configure_nginx
    configure_firewall
    create_backup_script
    start_services
    
    display_final_info
}

# Run main function
main "$@"
