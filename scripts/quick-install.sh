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

# Generate random string for database credentials
generate_random_string() {
    local length=${1:-16}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
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

    # 3. Domain Configuration (REQUIRED)
    echo "🌐 DOMAIN CONFIGURATION:"
    read -p "   Enter your domain name (e.g., goldbooks.com): " DOMAIN
    while [ -z "$DOMAIN" ]; do
        print_error "   Domain name is required!"
        read -p "   Enter your domain name (e.g., goldbooks.com): " DOMAIN
    done

    # 4. Application Path Configuration
    echo
    echo "📁 APPLICATION PATH:"
    echo "   How do you want to access your Gold Financial Books application?"
    echo "   1) Root domain ($DOMAIN)"
    echo "   2) Subdirectory ($DOMAIN/gold)"
    echo "   3) Custom subdirectory ($DOMAIN/your-path)"
    echo
    while true; do
        read -p "   Select option (1-3): " path_choice
        case $path_choice in
            1) 
                APP_PATH=""
                APP_URL_PATH=""
                break 
                ;;
            2) 
                APP_PATH="/gold"
                APP_URL_PATH="/gold"
                break 
                ;;
            3) 
                read -p "   Enter custom path (e.g., /books, /finance): " custom_path
                # Ensure path starts with /
                if [[ ! $custom_path == /* ]]; then
                    custom_path="/$custom_path"
                fi
                APP_PATH="$custom_path"
                APP_URL_PATH="$custom_path"
                break 
                ;;
            *) 
                print_error "   Invalid option. Please choose 1-3." 
                ;;
        esac
    done

    # 5. Installation Directory
    echo
    echo "📂 INSTALLATION DIRECTORY:"
    if [ "$ALREADY_IN_REPO" = true ]; then
        echo "   Current location: $CURRENT_PATH"
        echo "   1) Install here (current directory)"
        echo "   2) Copy to /opt/gold-books"
        echo "   3) Copy to /var/www/gold-books"
        echo "   4) Copy to custom directory"
        echo
        while true; do
            read -p "   Select option (1-4): " dir_choice
            case $dir_choice in
                1) INSTALL_PATH="$CURRENT_PATH"; SKIP_CLONE=true; break ;;
                2) INSTALL_PATH="/opt/gold-books"; SKIP_CLONE=false; break ;;
                3) INSTALL_PATH="/var/www/gold-books"; SKIP_CLONE=false; break ;;
                4) read -p "   Enter custom directory: " INSTALL_PATH; SKIP_CLONE=false; break ;;
                *) print_error "   Invalid option. Please choose 1-4." ;;
            esac
        done
    else
        INSTALL_PATH="/opt/gold-books"
        SKIP_CLONE=false
        print_status "Will install to: $INSTALL_PATH"
    fi

    # 6. SSL Configuration
    echo
    read -p "🔒 Enable SSL/HTTPS with Let's Encrypt? (Y/n): " ssl_choice
    if [[ $ssl_choice =~ ^[Nn]$ ]]; then
        ENABLE_SSL=false
        PROTOCOL="http"
        PORT="80"
    else
        ENABLE_SSL=true
        PROTOCOL="https"
        PORT="443"
    fi

    # 7. Database Configuration (Auto-generated credentials)
    echo
    echo "💾 DATABASE CONFIGURATION:"
    echo "   1) SQLite (recommended for single server)"
    echo "   2) MySQL (requires existing MySQL server)"
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
                DB_TYPE="mysql"
                # Generate random database credentials
                DB_NAME="goldbooks_$(generate_random_string 8)"
                DB_USER="gold_$(generate_random_string 8)"
                DB_PASS="$(generate_random_string 24)"
                read -p "   MySQL root password: " -s mysql_root_pass
                echo
                MYSQL_ROOT_PASS="$mysql_root_pass"
                break 
                ;;
            *) 
                print_error "   Invalid option. Please choose 1-2." 
                ;;
        esac
    done

    # 8. Admin User Configuration
    echo
    echo "👤 ADMIN USER SETUP:"
    read -p "   Admin email (default: admin@$DOMAIN): " admin_email
    ADMIN_EMAIL="${admin_email:-admin@$DOMAIN}"
    
    # Generate random admin password
    ADMIN_PASSWORD="$(generate_random_string 16)"
    print_status "Generated secure admin password: $ADMIN_PASSWORD"

    # 9. Service Configuration
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
    echo "   🌐 Domain: $DOMAIN"
    echo "   📁 App Path: $DOMAIN$APP_PATH"
    echo "   📂 Install Dir: $INSTALL_PATH"
    echo "   🔒 SSL: $([ "$ENABLE_SSL" = true ] && echo "Enabled" || echo "Disabled")"
    echo "   💾 Database: $DB_TYPE"
    if [ "$DB_TYPE" = "mysql" ]; then
        echo "   📊 DB Name: $DB_NAME"
        echo "   👤 DB User: $DB_USER"
        echo "   🔑 DB Pass: $DB_PASS"
    fi
    echo "   👤 Admin: $ADMIN_EMAIL"
    echo "   🔑 Admin Pass: $ADMIN_PASSWORD"
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
        
        # Install MySQL if selected
        if [ "$DB_TYPE" = "mysql" ]; then
            apt install -y mysql-server
        fi
        
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

setup_database() {
    if [ "$DB_TYPE" = "mysql" ]; then
        print_status "🗄️  Setting up MySQL database..."
        
        # Create database and user
        mysql -u root -p"$MYSQL_ROOT_PASS" << EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
        
        DB_URL="mysql://$DB_USER:$DB_PASS@localhost:3306/$DB_NAME"
        print_success "MySQL database created: $DB_NAME"
    else
        print_status "📁 Using SQLite database"
        mkdir -p "$(dirname "$DB_PATH")"
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
PORT=3000
$([ "$DB_TYPE" = "sqlite" ] && echo "DATABASE_PATH=$DB_PATH" || echo "DATABASE_URL=$DB_URL")
JWT_SECRET=$(openssl rand -base64 32)
NEXT_PUBLIC_APP_URL=$PROTOCOL://$DOMAIN$APP_PATH
NEXT_PUBLIC_BASE_PATH=$APP_URL_PATH
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD
EOF

    # Update Next.js config for subdirectory if needed
    if [ -n "$APP_URL_PATH" ]; then
        print_status "Configuring Next.js for subdirectory deployment..."
        cat > next.config.mjs << EOF
/** @type {import('next').NextConfig} */
const nextConfig = {
  basePath: '$APP_URL_PATH',
  assetPrefix: '$APP_URL_PATH',
  trailingSlash: true,
  output: 'standalone'
}

export default nextConfig
EOF
    fi

    # Initialize database
    print_status "Initializing database..."
    npm run db:init 2>/dev/null || print_warning "Database initialization skipped (will be created on first run)"
}

setup_web_server() {
    if [ "$INSTALL_AS_ROOT" = true ]; then
        print_status "🌐 Configuring Nginx..."
        
        # Remove default nginx site to avoid conflicts
        rm -f /etc/nginx/sites-enabled/default
        
        cat > /etc/nginx/sites-available/goldbooks << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location $APP_PATH/ {
        proxy_pass http://localhost:3000$APP_PATH/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_redirect off;
    }
    
    $([ -n "$APP_PATH" ] && echo "
    # Redirect root to app path
    location = / {
        return 301 \$scheme://\$server_name$APP_PATH/;
    }")
}
EOF
        
        # Enable site and test configuration
        ln -sf /etc/nginx/sites-available/goldbooks /etc/nginx/sites-enabled/
        
        if ! nginx -t; then
            print_error "Nginx configuration test failed"
            exit 1
        fi
        
        # Reload nginx with HTTP configuration
        systemctl reload nginx
        print_success "Nginx HTTP configuration applied successfully"
        
        if [ "$ENABLE_SSL" = true ]; then
            print_status "🔒 Setting up SSL certificate..."
            
            # Get SSL certificate
            if certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$ADMIN_EMAIL" --redirect; then
                print_success "SSL certificate installed successfully"
                
                cat > /etc/nginx/sites-available/goldbooks << EOF
# HTTP server - redirect to HTTPS
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS server
server {
    listen 443 ssl;
    http2 on;
    server_name $DOMAIN;
    
    # SSL configuration managed by Certbot
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    location $APP_PATH/ {
        proxy_pass http://localhost:3000$APP_PATH/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_redirect off;
    }
    
    $([ -n "$APP_PATH" ] && echo "
    # Redirect root to app path
    location = / {
        return 301 \$scheme://\$server_name$APP_PATH/;
    }")
}
EOF
                
                # Test and reload final configuration
                if nginx -t; then
                    systemctl reload nginx
                    print_success "SSL configuration applied successfully"
                else
                    print_error "SSL configuration test failed, reverting to HTTP"
                    # Revert to HTTP configuration
                    certbot delete --cert-name "$DOMAIN" --non-interactive
                    ENABLE_SSL=false
                    PROTOCOL="http"
                fi
            else
                print_warning "SSL certificate installation failed, continuing with HTTP"
                ENABLE_SSL=false
                PROTOCOL="http"
            fi
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
    setup_database
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
    echo "   📂 Location: $INSTALL_PATH"
    echo "   🌐 Access URL: $PROTOCOL://$DOMAIN$APP_PATH"
    echo "   👤 Admin Login: $ADMIN_EMAIL"
    echo "   🔑 Admin Password: $ADMIN_PASSWORD"
    echo "   💾 Database: $DB_TYPE"
    if [ "$DB_TYPE" = "mysql" ]; then
        echo "   📊 DB Name: $DB_NAME"
        echo "   👤 DB User: $DB_USER"
        echo "   🔑 DB Pass: $DB_PASS"
    fi
    echo "   🔧 Service: $([ "$INSTALL_SERVICE" = true ] && echo "System Service" || echo "Manual Start")"
    echo
    echo "🚀 NEXT STEPS:"
    echo "   • Open your browser and navigate to: $PROTOCOL://$DOMAIN$APP_PATH"
    echo "   • Login with the admin credentials above"
    echo "   • Start managing your gold financial records!"
    echo
    if [ "$INSTALL_SERVICE" = false ]; then
        echo "📝 MANUAL COMMANDS:"
        echo "   • Start: cd $INSTALL_PATH && npm start"
        echo "   • Stop: pkill -f 'npm start' or pm2 stop goldbooks"
        echo "   • Logs: tail -f goldbooks.log or pm2 logs goldbooks"
        echo
    fi
    
    # Save credentials to file
    cat > "$INSTALL_PATH/CREDENTIALS.txt" << EOF
Gold Financial Books - Installation Credentials
==============================================

Access URL: $PROTOCOL://$DOMAIN$APP_PATH
Admin Email: $ADMIN_EMAIL
Admin Password: $ADMIN_PASSWORD

$([ "$DB_TYPE" = "mysql" ] && echo "Database Credentials:
Database Name: $DB_NAME
Database User: $DB_USER
Database Password: $DB_PASS")

Installation Date: $(date)
EOF
    
    print_success "Credentials saved to: $INSTALL_PATH/CREDENTIALS.txt"
    print_success "Gold Financial Books is ready to use! 🏆"
}

# Run main function
main "$@"
