#!/bin/bash

# Production Environment Setup Script
echo "🚀 Setting up Gold Financial Books - Production Environment"

# Create production directories
sudo mkdir -p /var/lib/gold-financial
sudo mkdir -p /var/log/gold-financial
sudo mkdir -p /etc/gold-financial

# Set proper permissions
sudo chown -R $USER:$USER /var/lib/gold-financial
sudo chown -R $USER:$USER /var/log/gold-financial

# Copy production environment template
if [ ! -f /etc/gold-financial/.env ]; then
    sudo cp .env.production /etc/gold-financial/.env
    echo "⚠️  Please edit /etc/gold-financial/.env with your production configuration"
fi

# Build the application
echo "🏗️  Building application..."
npm run build

# Create systemd service
sudo tee /etc/systemd/system/gold-financial.service > /dev/null <<EOF
[Unit]
Description=Gold Financial Books Application
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
Environment=NODE_ENV=production
EnvironmentFile=/etc/gold-financial/.env
ExecStart=$(which npm) start
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=gold-financial

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable gold-financial
sudo systemctl start gold-financial

echo "✅ Production environment setup complete!"
echo ""
echo "🎯 Service commands:"
echo "   sudo systemctl status gold-financial   - Check status"
echo "   sudo systemctl restart gold-financial  - Restart service"
echo "   sudo systemctl logs gold-financial     - View logs"
echo ""
echo "📝 Configuration: /etc/gold-financial/.env"
echo "📊 Database: /var/lib/gold-financial/gold_financial.db"
echo "📋 Logs: journalctl -u gold-financial -f"
