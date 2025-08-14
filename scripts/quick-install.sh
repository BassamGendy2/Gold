#!/bin/bash

# Gold Financial Books - Multi-Instance Sequential Quick Installer
echo "🏆 Gold Financial Books - Multi-Instance Sequential Quick Installer"
echo "=================================================================="

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

# Find next available port starting from 3000
find_available_port() {
    local port=3000
    while netstat -tuln | grep -q ":$port "; do
        ((port++))
    done
    echo $port
}

check_path_availability() {
    local path="$1"
    if [ -f "/etc/nginx/sites-available/goldbooks" ]; then
        if grep -q "location $path" /etc/nginx/sites-available/goldbooks; then
            return 1  # Path already in use
        fi
    fi
    return 0  # Path available
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
    echo "   How do you want to access this Gold Financial Books instance?"
    echo "   Examples: /gold, /finance, /books, /trading, /portfolio"
    echo
    
    if [ -f "/etc/nginx/sites-available/goldbooks" ]; then
        print_status "Existing instances detected:"
        grep -o "location [^{]*" /etc/nginx/sites-available/goldbooks | grep -v "location /" | sed 's/location /   • /'
        echo
    fi
    
    while true; do
        read -p "   Enter path for this instance (e.g., /gold): " custom_path
        
        # Ensure path starts with /
        if [[ ! $custom_path == /* ]]; then
            custom_path="/$custom_path"
        fi
        
        if ! check_path_availability "$custom_path"; then
            print_error "   Path $custom_path is already in use. Please choose a different path."
            continue
        fi
        
        APP_PATH="$custom_path"
        APP_URL_PATH="$custom_path"
        break
    done

    # 5. Installation Directory - Use path-specific directory
    echo
    echo "📂 INSTALLATION DIRECTORY:"
    INSTANCE_NAME=$(echo "$APP_PATH" | sed 's/\///g')  # Remove slashes for directory name
    
    if [ "$ALREADY_IN_REPO" = true ]; then
        echo "   Current location: $CURRENT_PATH"
        echo "   1) Copy to /opt/gold-books-$INSTANCE_NAME"
        echo "   2) Copy to /var/www/gold-books-$INSTANCE_NAME"
        echo "   3) Copy to custom directory"
        echo
        while true; do
            read -p "   Select option (1-3): " dir_choice
            case $dir_choice in
                1) INSTALL_PATH="/opt/gold-books-$INSTANCE_NAME"; SKIP_CLONE=false; break ;;
                2) INSTALL_PATH="/var/www/gold-books-$INSTANCE_NAME"; SKIP_CLONE=false; break ;;
                3) read -p "   Enter custom directory: " INSTALL_PATH; SKIP_CLONE=false; break ;;
                *) print_error "   Invalid option. Please choose 1-3." ;;
            esac
        done
    else
        INSTALL_PATH="/opt/gold-books-$INSTANCE_NAME"
        SKIP_CLONE=false
        print_status "Will install to: $INSTALL_PATH"
    fi

    APP_PORT=$(find_available_port)
    print_status "Assigned port: $APP_PORT"

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

    # 7. Database Configuration - Auto-generated unique credentials
    echo
    echo "💾 DATABASE CONFIGURATION:"
    echo "   1) SQLite (recommended for multiple instances)"
    echo "   2) MySQL (requires existing MySQL server)"
    echo
    while true; do
        read -p "   Select database type (1-2): " db_choice
        case $db_choice in
            1) 
                DB_TYPE="sqlite"
                DB_NAME="goldbooks_${INSTANCE_NAME}_$(generate_random_string 8).db"
                DB_PATH="$INSTALL_PATH/data/$DB_NAME"
                print_status "Generated SQLite database: $DB_NAME"
                break 
                ;;
            2) 
                DB_TYPE="mysql"
                DB_NAME="goldbooks_${INSTANCE_NAME}_$(generate_random_string 8)"
                DB_USER="gold_${INSTANCE_NAME}_$(generate_random_string 6)"
                DB_PASS="$(generate_random_string 24)"
                print_status "Generated MySQL credentials:"
                print_status "  Database: $DB_NAME"
                print_status "  User: $DB_USER"
                print_status "  Password: $DB_PASS"
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
    read -p "   Admin email (default: admin-$INSTANCE_NAME@$DOMAIN): " admin_email
    ADMIN_EMAIL="${admin_email:-admin-$INSTANCE_NAME@$DOMAIN}"
    
    # Generate random admin password
    ADMIN_PASSWORD="$(generate_random_string 16)"
    print_status "Generated secure admin password: $ADMIN_PASSWORD"

    # 9. Service Configuration - Instance-specific service name
    echo
    if [ "$INSTALL_AS_ROOT" = true ]; then
        read -p "🔧 Install as system service (auto-start)? (Y/n): " service_choice
        if [[ $service_choice =~ ^[Nn]$ ]]; then
            INSTALL_SERVICE=false
        else
            INSTALL_SERVICE=true
            SERVICE_NAME="goldbooks-$INSTANCE_NAME"
        fi
    else
        INSTALL_SERVICE=false
    fi

    # Configuration Summary
    echo
    echo "📋 CONFIGURATION SUMMARY:"
    echo "========================="
    echo "   🏷️  Instance: $INSTANCE_NAME"
    echo "   🌐 Domain: $DOMAIN"
    echo "   📁 App Path: $DOMAIN$APP_PATH"
    echo "   🔌 Port: $APP_PORT"
    echo "   📂 Install Dir: $INSTALL_PATH"
    echo "   🔒 SSL: $([ "$ENABLE_SSL" = true ] && echo "Enabled" || echo "Disabled")"
    echo "   💾 Database: $DB_TYPE"
    if [ "$DB_TYPE" = "mysql" ]; then
        echo "   📊 DB Name: $DB_NAME"
        echo "   👤 DB User: $DB_USER"
        echo "   🔑 DB Pass: $DB_PASS"
    elif [ "$DB_TYPE" = "sqlite" ]; then
        echo "   📁 DB File: $DB_NAME"
    fi
    echo "   👤 Admin: $ADMIN_EMAIL"
    echo "   🔑 Admin Pass: $ADMIN_PASSWORD"
    echo "   🔧 System Service: $([ "$INSTALL_SERVICE" = true ] && echo "$SERVICE_NAME" || echo "No")"
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
        apt install -y git sqlite3 nginx certbot python3-certbot-nginx net-tools
        
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
    
    cat > .env.production << EOF
NODE_ENV=production
PORT=$APP_PORT
$([ "$DB_TYPE" = "sqlite" ] && echo "DATABASE_PATH=$DB_PATH" || echo "DATABASE_URL=$DB_URL")
JWT_SECRET=$(openssl rand -base64 32)
NEXT_PUBLIC_APP_URL=$PROTOCOL://$DOMAIN$APP_PATH
NEXT_PUBLIC_BASE_PATH=$APP_URL_PATH
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD
EOF

    # Update Next.js config for subdirectory
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

    # Initialize database
    print_status "Initializing database..."
    npm run db:init 2>/dev/null || print_warning "Database initialization skipped (will be created on first run)"
}

setup_web_server() {
    if [ "$INSTALL_AS_ROOT" = true ]; then
        print_status "🌐 Configuring Nginx..."
        
        if [ -f "/etc/nginx/sites-available/goldbooks" ]; then
            print_status "Adding new instance to existing nginx configuration..."
            
            # Backup existing config
            cp /etc/nginx/sites-available/goldbooks /etc/nginx/sites-available/goldbooks.backup.$(date +%s)
            
            # Add new location block before the closing brace of the server block
            sed -i "/^}$/i\\
\\
    # $INSTANCE_NAME instance\\
    location $APP_PATH {\\
        return 301 \$scheme://\$server_name$APP_PATH/;\\
    }\\
\\
    location $APP_PATH/ {\\
        proxy_pass http://localhost:$APP_PORT/;\\
        proxy_http_version 1.1;\\
        proxy_set_header Upgrade \$http_upgrade;\\
        proxy_set_header Connection 'upgrade';\\
        proxy_set_header Host \$host;\\
        proxy_set_header X-Real-IP \$remote_addr;\\
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\\
        proxy_set_header X-Forwarded-Proto \$scheme;\\
        proxy_set_header X-Forwarded-Prefix $APP_PATH;\\
        proxy_cache_bypass \$http_upgrade;\\
        proxy_redirect off;\\
\\
        # Handle static assets\\
        location ~* $APP_PATH/(_next/static|favicon\.ico) {\\
            proxy_pass http://localhost:$APP_PORT;\\
            expires 1y;\\
            add_header Cache-Control \"public, immutable\";\\
        }\\
    }" /etc/nginx/sites-available/goldbooks
            
        else
            print_status "Creating new nginx configuration..."
            # Remove default nginx site to avoid conflicts
            rm -f /etc/nginx/sites-enabled/default
            
            cat > /etc/nginx/sites-available/goldbooks << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    # $INSTANCE_NAME instance
    location $APP_PATH {
        return 301 \$scheme://\$server_name$APP_PATH/;
    }
    
    location $APP_PATH/ {
        proxy_pass http://localhost:$APP_PORT/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Prefix $APP_PATH;
        proxy_cache_bypass \$http_upgrade;
        proxy_redirect off;
        
        # Handle static assets
        location ~* $APP_PATH/(_next/static|favicon\.ico) {
            proxy_pass http://localhost:$APP_PORT;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF
        fi
        
        # Enable site and test configuration
        ln -sf /etc/nginx/sites-available/goldbooks /etc/nginx/sites-enabled/
        
        if ! nginx -t; then
            print_error "Nginx configuration test failed"
            cat /var/log/nginx/error.log | tail -10
            exit 1
        fi
        
        # Reload nginx with HTTP configuration
        systemctl reload nginx
        print_success "Nginx HTTP configuration applied successfully"
        
        if [ "$ENABLE_SSL" = true ] && ! grep -q "ssl_certificate" /etc/nginx/sites-available/goldbooks; then
            print_status "🔒 Setting up SSL certificate..."
            
            # Get SSL certificate
            if certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$ADMIN_EMAIL" --redirect; then
                print_success "SSL certificate installed successfully"
            else
                print_warning "SSL certificate installation failed, continuing with HTTP"
                ENABLE_SSL=false
                PROTOCOL="http"
            fi
        elif [ "$ENABLE_SSL" = true ]; then
            print_status "SSL already configured for domain"
        fi
    fi
}

setup_system_service() {
    if [ "$INSTALL_SERVICE" = true ]; then
        print_status "🔧 Setting up system service: $SERVICE_NAME..."
        
        cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Gold Financial Books Application - $INSTANCE_NAME
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$INSTALL_PATH
Environment=NODE_ENV=production
Environment=PORT=$APP_PORT
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        
        # Enable and start service
        systemctl daemon-reload
        systemctl enable $SERVICE_NAME
        systemctl start $SERVICE_NAME
    fi
}

build_application() {
    print_status "🔨 Building application..."
    
    if ! grep -q '"build"' package.json; then
        print_status "Adding build script to package.json..."
        npm pkg set scripts.build="next build"
        npm pkg set scripts.start="next start"
        npm pkg set scripts.dev="next dev"
    fi
    
    # Build the application
    if ! npm run build; then
        print_error "Application build failed!"
        print_status "Checking for common issues..."
        
        # Check if Next.js is installed
        if ! npm list next &>/dev/null; then
            print_status "Installing Next.js..."
            npm install next@latest react@latest react-dom@latest
        fi
        
        # Try building again
        if ! npm run build; then
            print_error "Build failed again. Check the logs above."
            exit 1
        fi
    fi
    
    print_success "Application built successfully"
}

start_application() {
    print_status "🚀 Starting application..."
    
    if [ "$INSTALL_SERVICE" = true ]; then
        systemctl start $SERVICE_NAME
        
        # Wait for service to start and check status
        sleep 5
        if systemctl is-active --quiet $SERVICE_NAME; then
            print_success "Application started as system service: $SERVICE_NAME"
        else
            print_error "System service failed to start"
            systemctl status $SERVICE_NAME
            journalctl -u $SERVICE_NAME --no-pager -n 20
            exit 1
        fi
    else
        PM2_NAME="goldbooks-$INSTANCE_NAME"
        
        if command -v pm2 &> /dev/null; then
            pm2 delete $PM2_NAME 2>/dev/null || true
            cd "$INSTALL_PATH"
            PORT=$APP_PORT pm2 start npm --name "$PM2_NAME" -- start
            pm2 save
            
            # Wait and check if PM2 process is running
            sleep 5
            if pm2 list | grep -q "$PM2_NAME.*online"; then
                print_success "Application started with PM2: $PM2_NAME"
            else
                print_error "PM2 startup failed"
                pm2 logs $PM2_NAME --lines 20
                exit 1
            fi
        else
            # Start with nohup as fallback
            cd "$INSTALL_PATH"
            nohup PORT=$APP_PORT npm start > goldbooks-$INSTANCE_NAME.log 2>&1 &
            echo $! > goldbooks-$INSTANCE_NAME.pid
            
            # Wait and check if process is running
            sleep 5
            if kill -0 $(cat goldbooks-$INSTANCE_NAME.pid 2>/dev/null) 2>/dev/null; then
                print_success "Application started with nohup"
            else
                print_error "Application startup failed"
                cat goldbooks-$INSTANCE_NAME.log | tail -20
                exit 1
            fi
        fi
    fi
    
    print_status "Performing health check..."
    for i in {1..30}; do
        if curl -s http://localhost:$APP_PORT >/dev/null 2>&1; then
            print_success "Application is responding on port $APP_PORT"
            break
        fi
        if [ $i -eq 30 ]; then
            print_error "Application health check failed - not responding on port $APP_PORT"
            print_status "Checking application logs..."
            if [ "$INSTALL_SERVICE" = true ]; then
                journalctl -u $SERVICE_NAME --no-pager -n 20
            elif command -v pm2 &> /dev/null; then
                pm2 logs $PM2_NAME --lines 20
            else
                tail -20 goldbooks-$INSTANCE_NAME.log
            fi
            exit 1
        fi
        sleep 2
    done
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
    echo "   🏷️  Instance: $INSTANCE_NAME"
    echo "   📂 Location: $INSTALL_PATH"
    echo "   🌐 Access URL: $PROTOCOL://$DOMAIN$APP_PATH"
    echo "   🔌 Port: $APP_PORT"
    echo "   👤 Admin Login: $ADMIN_EMAIL"
    echo "   🔑 Admin Password: $ADMIN_PASSWORD"
    echo "   💾 Database: $DB_TYPE"
    if [ "$DB_TYPE" = "mysql" ]; then
        echo "   📊 DB Name: $DB_NAME"
        echo "   👤 DB User: $DB_USER"
        echo "   🔑 DB Pass: $DB_PASS"
    elif [ "$DB_TYPE" = "sqlite" ]; then
        echo "   📁 DB File: $DB_NAME"
    fi
    echo "   🔧 Service: $([ "$INSTALL_SERVICE" = true ] && echo "$SERVICE_NAME" || echo "PM2: goldbooks-$INSTANCE_NAME")"
    echo
    echo "🚀 NEXT STEPS:"
    echo "   • Open your browser and navigate to: $PROTOCOL://$DOMAIN$APP_PATH"
    echo "   • Login with the admin credentials above"
    echo "   • Start managing your gold financial records!"
    echo
    if [ "$INSTALL_SERVICE" = false ]; then
        echo "📝 MANUAL COMMANDS:"
        echo "   • Start: cd $INSTALL_PATH && PORT=$APP_PORT npm start"
        echo "   • Stop: pm2 stop goldbooks-$INSTANCE_NAME"
        echo "   • Logs: pm2 logs goldbooks-$INSTANCE_NAME"
        echo
    fi
    
    cat > "$INSTALL_PATH/CREDENTIALS-$INSTANCE_NAME.txt" << EOF
Gold Financial Books - Instance: $INSTANCE_NAME
==============================================

Access URL: $PROTOCOL://$DOMAIN$APP_PATH
Admin Email: $ADMIN_EMAIL
Admin Password: $ADMIN_PASSWORD
Port: $APP_PORT

$([ "$DB_TYPE" = "mysql" ] && echo "Database Credentials:
Database Name: $DB_NAME
Database User: $DB_USER
Database Password: $DB_PASS" || echo "Database File: $DB_NAME")

Installation Date: $(date)
Installation Path: $INSTALL_PATH
Service Name: $([ "$INSTALL_SERVICE" = true ] && echo "$SERVICE_NAME" || echo "PM2: goldbooks-$INSTANCE_NAME")
EOF
    
    print_success "Credentials saved to: $INSTALL_PATH/CREDENTIALS-$INSTANCE_NAME.txt"
    print_success "Gold Financial Books instance '$INSTANCE_NAME' is ready to use! 🏆"
    
    # Show all instances if multiple exist
    if [ -f "/etc/nginx/sites-available/goldbooks" ]; then
        echo
        print_status "All instances on this server:"
        grep -o "location [^{]*" /etc/nginx/sites-available/goldbooks | grep -v "location /" | sed "s/location /   • $PROTOCOL:\/\/$DOMAIN/"
    fi
}

# Run main function
main "$@"
