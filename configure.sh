#!/bin/bash

# Gold Financial Books - Automatic Configuration Script
# This script automatically sets up the entire application

set -e  # Exit on any error

echo "🏆 Gold Financial Books - Automatic Setup"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if Node.js is installed
check_nodejs() {
    print_status "Checking Node.js installation..."
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install Node.js 18+ first."
        exit 1
    fi
    
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_error "Node.js version 18+ is required. Current version: $(node -v)"
        exit 1
    fi
    
    print_success "Node.js $(node -v) is installed"
}

# Generate secure JWT secret
generate_jwt_secret() {
    print_status "Generating secure JWT secret..."
    JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || node -e "console.log(require('crypto').randomBytes(32).toString('base64'))")
    print_success "JWT secret generated"
}

# Create environment files
create_env_files() {
    print_status "Creating environment configuration..."
    
    # Development environment
    cat > .env.local << EOF
# Development Environment Configuration
NODE_ENV=development
DATABASE_PATH=./data/dev-gold-books.db
JWT_SECRET=${JWT_SECRET}
PORT=3000
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Development Settings
DEBUG=true
LOG_LEVEL=debug
EOF

    # Production environment template
    cat > .env.production << EOF
# Production Environment Configuration
NODE_ENV=production
DATABASE_PATH=/var/lib/gold-books/production.db
JWT_SECRET=${JWT_SECRET}
PORT=3000
NEXT_PUBLIC_APP_URL=https://your-domain.com

# Production Settings
DEBUG=false
LOG_LEVEL=info
EOF

    print_success "Environment files created"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    npm install
    print_success "Dependencies installed"
}

# Create data directory
create_directories() {
    print_status "Creating application directories..."
    mkdir -p data
    mkdir -p logs
    chmod 755 data logs
    print_success "Directories created"
}

# Initialize database
init_database() {
    print_status "Initializing database..."
    
    # Run database creation script
    if [ -f "scripts/01-create-tables.sql" ]; then
        node -e "
        const Database = require('better-sqlite3');
        const fs = require('fs');
        const path = require('path');
        
        const dbPath = './data/dev-gold-books.db';
        const db = new Database(dbPath);
        
        console.log('Creating database tables...');
        const sql = fs.readFileSync('./scripts/01-create-tables.sql', 'utf8');
        db.exec(sql);
        
        console.log('Database initialized successfully');
        db.close();
        "
        print_success "Database tables created"
    else
        print_warning "Database creation script not found"
    fi
}

# Seed development data
seed_dev_data() {
    print_status "Seeding development data..."
    
    if [ -f "scripts/seed-dev-data.js" ]; then
        node scripts/seed-dev-data.js
        print_success "Development data seeded"
    else
        print_warning "Development seed script not found"
    fi
}

# Create systemd service (for production)
create_systemd_service() {
    if [ "$1" = "production" ]; then
        print_status "Creating systemd service..."
        
        sudo tee /etc/systemd/system/gold-books.service > /dev/null << EOF
[Unit]
Description=Gold Financial Books Application
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$(pwd)
Environment=NODE_ENV=production
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload
        sudo systemctl enable gold-books
        print_success "Systemd service created"
    fi
}

# Build application
build_app() {
    print_status "Building application..."
    npm run build
    print_success "Application built"
}

# Main setup function
main() {
    echo
    print_status "Starting automatic configuration..."
    echo
    
    # Detect environment
    ENV_TYPE="development"
    if [ "$1" = "production" ] || [ "$1" = "prod" ]; then
        ENV_TYPE="production"
        print_status "Setting up for PRODUCTION environment"
    else
        print_status "Setting up for DEVELOPMENT environment"
    fi
    
    # Run setup steps
    check_nodejs
    generate_jwt_secret
    create_env_files
    create_directories
    install_dependencies
    init_database
    
    if [ "$ENV_TYPE" = "development" ]; then
        seed_dev_data
    fi
    
    build_app
    
    if [ "$ENV_TYPE" = "production" ]; then
        create_systemd_service production
    fi
    
    echo
    print_success "🎉 Gold Financial Books setup completed successfully!"
    echo
    echo "Next steps:"
    if [ "$ENV_TYPE" = "development" ]; then
        echo "  • Run: npm run dev"
        echo "  • Open: http://localhost:3000"
        echo "  • Login with: admin@goldbooks.com / admin123"
    else
        echo "  • Update .env.production with your domain"
        echo "  • Run: sudo systemctl start gold-books"
        echo "  • Check status: sudo systemctl status gold-books"
    fi
    echo
}

# Run main function with arguments
main "$@"
