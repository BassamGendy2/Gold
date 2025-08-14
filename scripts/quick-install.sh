#!/bin/bash

# Gold Financial Books - Sequential Quick Installer
echo "🏆 Gold Financial Books - Sequential Quick Installer"
echo "=================================================="

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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# ============================================================================
# CONFIGURATION COLLECTION - ALL QUESTIONS ASKED UPFRONT
# ============================================================================

collect_all_configuration() {
    echo
    echo "📋 CONFIGURATION SETUP"
    echo "======================"
    print_status "Please answer the following questions to configure your installation:"
    echo

    # 1. Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_status "✅ Running as root - system-wide installation available"
        INSTALL_AS_ROOT=true
    else
        INSTALL_AS_ROOT=false
    fi

    # 2. Check if already in repository
    if [ -f "package.json" ] && [ -f "configure.sh" ] && [ -d "app" ] && [ -d "components" ]; then
        print_success "✅ Already in Gold Financial Books repository!"
        ALREADY_IN_REPO=true
        CURRENT_PATH="$(pwd)"
    else
        ALREADY_IN_REPO=false
    fi

    # 3. Installation Path
    echo "📁 INSTALLATION LOCATION:"
    if [ "$ALREADY_IN_REPO" = true ]; then
        echo "   Current location: $CURRENT_PATH"
        echo "   1) Install here (current directory)"
        echo "   2) Copy to /opt/gold-books"
        echo "   3) Copy to /var/www/gold-books"
        echo "   4) Copy to custom path"
        echo
        while true; do
            read -p "   Select option (1-4): " path_choice
            case $path_choice in
                1) INSTALL_PATH="$CURRENT_PATH"; SKIP_CLONE=true; break ;;
                2) INSTALL_PATH="/opt/gold-books"; SKIP_CLONE=false; break ;;
                3) INSTALL_PATH="/var/www/gold-books"; SKIP_CLONE=false; break ;;
                4) read -p "   Enter custom path: " INSTALL_PATH; SKIP_CLONE=false; break ;;
                *) print_error "   Invalid option. Please choose 1-4." ;;
            esac
        done
    else
        echo "   1) Current directory ($(pwd)/gold-books)"
        echo "   2) /opt/gold-books (system-wide)"
        echo "   3) /var/www/gold-books (web server)"
        echo "   4) Custom path"
        echo
        while true; do
            read -p "   Select option (1-4): " path_choice
            case $path_choice in
                1) INSTALL_PATH="$(pwd)/gold-books"; break ;;
                2) INSTALL_PATH="/opt/gold-books"; break ;;
                3) INSTALL_PATH="/var/www/gold-books"; break ;;
                4) read -p "   Enter custom path: " INSTALL_PATH; break ;;
                *) print_error "   Invalid option. Please choose 1-4." ;;
            esac
        done
        SKIP_CLONE=false
    fi

    # 4. Domain Configuration
    echo
    echo "🌐 DOMAIN & ACCESS CONFIGURATION:"
    echo "   1) Local access only (localhost:3000)"
    echo "   2) Domain name (example.com)"
    echo "   3) IP address access"
    echo "   4) Custom port"
    echo
    while true; do
        read -p "   Select access method (1-4): " access_choice
        case $access_choice in
            1) 
                DOMAIN="localhost"
                PORT="3000"
                ACCESS_TYPE="local"
                break 
                ;;
            2) 
                read -p "   Enter your domain name (e.g., goldbooks.com): " DOMAIN
                PORT="80"
                ACCESS_TYPE="domain"
                break 
                ;;
            3) 
                DOMAIN=$(hostname -I | awk '{print $1}')
                read -p "   Enter port (default 3000): " custom_port
                PORT="${custom_port:-3000}"
                ACCESS_TYPE="ip"
                break 
                ;;
            4) 
                DOMAIN="localhost"
                read -p "   Enter custom port: " PORT
                ACCESS_TYPE="custom"
                break 
                ;;
            *) 
                print_error "   Invalid option. Please choose 1-4." 
                ;;
        esac
    done

    # 5. SSL Configuration (only for domain)
    if [ "$ACCESS_TYPE" = "domain" ]; then
        echo
        read -p "🔒 Enable SSL/HTTPS? (y/N): " ssl_choice
        if [[ $ssl_choice =~ ^[Yy]$ ]]; then
            ENABLE_SSL=true
            PORT="443"
        else
            ENABLE_SSL=false
            PORT="80"
        fi
    else
        ENABLE_SSL=false
    fi

    # 6. Database Configuration
    echo
    echo "💾 DATABASE CONFIGURATION:"
    echo "   1) SQLite (recommended for single server)"
    echo "   2) External database (MySQL/PostgreSQL)"
    echo
    while true; do
        read -p "   Select database type (1-2): " db_choice
        case $db_choice in
            1) 
                DB_TYPE="sqlite"
                DB_PATH="$INSTALL_PATH/data/goldbooks.db"
                break 
                ;;
            2) 
                DB_TYPE="external"
                read -p "   Enter database URL: " DB_URL
                break 
                ;;
            *) 
                print_error "   Invalid option. Please choose 1-2." 
                ;;
        esac
    done

    # 7. Admin User Configuration
    echo
    echo "👤 ADMIN USER SETUP:"
    read -p "   Admin email (default: admin@goldbooks.com): " admin_email
    ADMIN_EMAIL="${admin_email:-admin@goldbooks.com}"
    
    read -s -p "   Admin password (default: admin123): " admin_password
    echo
    ADMIN_PASSWORD="${admin_password:-admin123}"

    # 8. Service Configuration
    echo
    if [ "$INSTALL_AS_ROOT" = true ]; then
        read -p "🔧 Install as system service (auto-start)? (Y/n): " service_choice
        if [[ $service_choice =~ ^[Nn]$ ]]; then
            INSTALL_SERVICE=false
        else
            INSTALL_SERVICE=true
        fi
    else
        INSTALL_SERVICE=false
    fi

    # Configuration Summary
    echo
    echo "📋 CONFIGURATION SUMMARY:"
    echo "========================="
    echo "   📁 Installation Path: $INSTALL_PATH"
    echo "   🌐 Access: $ACCESS_TYPE ($DOMAIN:$PORT)"
    echo "   🔒 SSL: $([ "$ENABLE_SSL" = true ] && echo "Enabled" || echo "Disabled")"
    echo "   💾 Database: $DB_TYPE"
    echo "   👤 Admin: $ADMIN_EMAIL"
    echo "   🔧 System Service: $([ "$INSTALL_SERVICE" = true ] && echo "Yes" || echo "No")"
    echo
    
    read -p "Proceed with installation? (Y/n): " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        print_error "Installation cancelled by user"
        exit 1
    fi
}

# ============================================================================
# AUTOMATED INSTALLATION PROCESS - NO MORE PROMPTS
# ============================================================================

install_dependencies() {
    print_status "📦 Installing system dependencies..."
    
    if [ "$INSTALL_AS_ROOT" = true ]; then
        # Update package list
        apt update -qq
        
        # Install Node.js if not present
        if ! command -v node &> /dev/null; then
            print_status "Installing Node.js..."
            curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
            apt install -y nodejs
        fi
        
        # Install additional tools
        apt install -y git sqlite3 nginx certbot python3-certbot-nginx
        
        # Install PM2 globally
        npm install -g pm2
    else
        print_warning "Non-root installation - some features may be limited"
        if ! command -v node &> /dev/null; then
            print_error "Node.js not found. Please install Node.js first."
            exit 1
        fi
    fi
}

setup_application() {
    print_status "🏗️  Setting up application..."
    
    # Create installation directory
    if [ "$SKIP_CLONE" = false ]; then
        if [ "$INSTALL_PATH" != "/" ]; then
            mkdir -p "$INSTALL_PATH"
        fi
        
        # Clone or copy files
        if [ "$ALREADY_IN_REPO" = true ]; then
            print_status "Copying files from current repository..."
            cp -r "$CURRENT_PATH"/* "$INSTALL_PATH"/
        else
            print_status "Cloning repository..."
            git clone https://github.com/yourusername/gold-financial-books.git "$INSTALL_PATH"
        fi
        
        cd "$INSTALL_PATH"
    fi
    
    # Install npm dependencies
    print_status "Installing application dependencies..."
    npm install --production
    
    # Set permissions
    if [ "$INSTALL_AS_ROOT" = true ]; then
        chown -R www-data:www-data .
        chmod +x configure.sh
        chmod +x scripts/*.sh
    fi
}

configure_environment() {
    print_status "⚙️  Configuring environment..."
    
    # Create environment file
    cat > .env.production << EOF
NODE_ENV=production
PORT=$PORT
DATABASE_PATH=$DB_PATH
JWT_SECRET=$(openssl rand -base64 32)
NEXT_PUBLIC_APP_URL=http$([ "$ENABLE_SSL" = true ] && echo "s")://$DOMAIN$([ "$PORT" != "80" ] && [ "$PORT" != "443" ] && echo ":$PORT")
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD
EOF

    # Configure database
    if [ "$DB_TYPE" = "sqlite" ]; then
        mkdir -p "$(dirname "$DB_PATH")"
        print_status "Initializing SQLite database..."
        npm run db:init
        npm run db:seed
    fi
}

setup_web_server() {
    if [ "$INSTALL_AS_ROOT" = true ] && [ "$ACCESS_TYPE" = "domain" ]; then
        print_status "🌐 Configuring Nginx..."
        
        # Create Nginx configuration
        cat > /etc/nginx/sites-available/goldbooks << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
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
        
        # Enable site
        ln -sf /etc/nginx/sites-available/goldbooks /etc/nginx/sites-enabled/
        nginx -t && systemctl reload nginx
        
        # Setup SSL if requested
        if [ "$ENABLE_SSL" = true ]; then
            print_status "🔒 Setting up SSL certificate..."
            certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$ADMIN_EMAIL"
        fi
    fi
}

setup_system_service() {
    if [ "$INSTALL_SERVICE" = true ]; then
        print_status "🔧 Setting up system service..."
        
        # Create systemd service
        cat > /etc/systemd/system/goldbooks.service << EOF
[Unit]
Description=Gold Financial Books Application
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$INSTALL_PATH
Environment=NODE_ENV=production
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        
        # Enable and start service
        systemctl daemon-reload
        systemctl enable goldbooks
        systemctl start goldbooks
    fi
}

build_application() {
    print_status "🔨 Building application..."
    npm run build
}

start_application() {
    if [ "$INSTALL_SERVICE" = true ]; then
        print_status "🚀 Application started as system service"
    else
        print_status "🚀 Starting application..."
        if command -v pm2 &> /dev/null; then
            pm2 start npm --name "goldbooks" -- start
            pm2 save
        else
            nohup npm start > goldbooks.log 2>&1 &
            echo $! > goldbooks.pid
        fi
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    echo
    
    # Step 1: Collect all configuration upfront
    collect_all_configuration
    
    echo
    print_status "🚀 Starting automated installation..."
    echo "    This will take a few minutes. Please wait..."
    echo
    
    # Step 2: Run all installation steps automatically
    install_dependencies
    setup_application
    configure_environment
    build_application
    setup_web_server
    setup_system_service
    start_application
    
    # Step 3: Installation complete
    echo
    print_success "🎉 Installation Complete!"
    echo
    echo "📋 INSTALLATION SUMMARY:"
    echo "========================"
    echo "   📁 Location: $INSTALL_PATH"
    echo "   🌐 Access URL: http$([ "$ENABLE_SSL" = true ] && echo "s")://$DOMAIN$([ "$PORT" != "80" ] && [ "$PORT" != "443" ] && echo ":$PORT")"
    echo "   👤 Admin Login: $ADMIN_EMAIL"
    echo "   🔑 Admin Password: $ADMIN_PASSWORD"
    echo "   💾 Database: $DB_TYPE"
    echo "   🔧 Service: $([ "$INSTALL_SERVICE" = true ] && echo "System Service" || echo "Manual Start")"
    echo
    echo "🚀 NEXT STEPS:"
    echo "   • Open your browser and navigate to the access URL above"
    echo "   • Login with the admin credentials"
    echo "   • Start managing your gold financial records!"
    echo
    if [ "$INSTALL_SERVICE" = false ]; then
        echo "📝 MANUAL COMMANDS:"
        echo "   • Start: cd $INSTALL_PATH && npm start"
        echo "   • Stop: pkill -f 'npm start' or pm2 stop goldbooks"
        echo "   • Logs: tail -f goldbooks.log or pm2 logs goldbooks"
        echo
    fi
    
    print_success "Gold Financial Books is ready to use! 🏆"
}

# Run main function
main "$@"
