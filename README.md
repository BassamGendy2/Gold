# Gold Financial Books

A stylish and simple gold financial books web application for managing precious metal investments. Built with Next.js, SQLite, and designed with a luxurious gold theme.

## Features

- **Portfolio Management**: Track your gold holdings with detailed information
- **Transaction History**: Record purchases and sales with comprehensive details
- **Real-time Valuation**: Monitor current portfolio value and profit/loss
- **Secure Authentication**: JWT-based authentication with encrypted passwords
- **Responsive Design**: Beautiful gold-themed interface that works on all devices
- **Local Database**: SQLite database for complete data ownership
- **Ubuntu Ready**: Automated installation script for Ubuntu servers

## Quick Start

### Prerequisites

- Ubuntu 18.04 or later
- Internet connection for downloading dependencies
- User account with sudo privileges

### Installation

1. **Download the application:**
   \`\`\`bash
   git clone <repository-url>
   cd gold-financial-books
   \`\`\`

2. **Run the installation script:**
   \`\`\`bash
   chmod +x install.sh
   ./install.sh
   \`\`\`

3. **Access the application:**
   Open your browser and navigate to `http://localhost`

The installation script will automatically:
- Install Node.js and system dependencies
- Set up the application and database
- Configure nginx as a reverse proxy
- Create systemd service for auto-start
- Set up firewall rules
- Schedule daily backups

### Manual Installation

If you prefer to install manually:

1. **Install Node.js 18+:**
   \`\`\`bash
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt-get install -y nodejs
   \`\`\`

2. **Install dependencies:**
   \`\`\`bash
   npm install
   \`\`\`

3. **Build the application:**
   \`\`\`bash
   npm run build
   \`\`\`

4. **Set up the database:**
   \`\`\`bash
   sqlite3 gold_financial.db < scripts/01-create-tables.sql
   \`\`\`

5. **Create environment file:**
   \`\`\`bash
   cp .env.example .env
   # Edit .env with your configuration
   \`\`\`

6. **Start the application:**
   \`\`\`bash
   npm start
   \`\`\`

## Usage

### First Time Setup

1. Navigate to the application URL
2. Click "Create Account" to register your first user
3. Log in with your credentials
4. Start adding your gold transactions

### Adding Gold Transactions

1. Go to the "Transactions" page
2. Click "Add Transaction"
3. Fill in the transaction details:
   - Transaction type (Buy/Sell)
   - Gold type (Bar, Coin, Jewelry, ETF)
   - Weight in grams
   - Price per gram
   - Purchase date
   - Additional details for purchases

### Managing Your Portfolio

- **Dashboard**: View portfolio summary and current holdings
- **Transactions**: Add new transactions and view history
- **Holdings Table**: Detailed view of all gold items with current values

## System Management

### Service Commands

\`\`\`bash
# Start the service
sudo systemctl start gold-financial-books

# Stop the service
sudo systemctl stop gold-financial-books

# Restart the service
sudo systemctl restart gold-financial-books

# Check service status
sudo systemctl status gold-financial-books

# View logs
sudo journalctl -u gold-financial-books -f
\`\`\`

### Database Backup

Automatic backups are scheduled daily at 2 AM. Manual backup:

\`\`\`bash
sudo /usr/local/bin/backup-gold-books
\`\`\`

Backups are stored in `/var/backups/gold-financial-books/`

### Configuration

Edit the environment file:
\`\`\`bash
sudo nano /opt/gold-financial-books/.env
\`\`\`

After making changes, restart the service:
\`\`\`bash
sudo systemctl restart gold-financial-books
\`\`\`

## Security

### SSL Setup

To enable HTTPS with Let's Encrypt:

\`\`\`bash
sudo certbot --nginx
\`\`\`

### Firewall

The installation script configures UFW firewall. To modify:

\`\`\`bash
# Check current rules
sudo ufw status

# Allow additional ports
sudo ufw allow <port>

# Remove rules
sudo ufw delete <rule-number>
\`\`\`

### Database Security

- Database file is owned by the application user
- File permissions are set to 660 (read/write for owner and group only)
- Regular backups are encrypted and stored securely

## Troubleshooting

### Service Won't Start

1. Check the service status:
   \`\`\`bash
   sudo systemctl status gold-financial-books
   \`\`\`

2. Check the logs:
   \`\`\`bash
   sudo journalctl -u gold-financial-books -n 50
   \`\`\`

3. Verify the environment file:
   \`\`\`bash
   sudo cat /opt/gold-financial-books/.env
   \`\`\`

### Database Issues

1. Check database file permissions:
   \`\`\`bash
   ls -la /opt/gold-financial-books/data/
   \`\`\`

2. Test database connection:
   \`\`\`bash
   sqlite3 /opt/gold-financial-books/data/gold_financial.db ".tables"
   \`\`\`

### Network Issues

1. Check if the application is listening:
   \`\`\`bash
   sudo netstat -tlnp | grep 3000
   \`\`\`

2. Test nginx configuration:
   \`\`\`bash
   sudo nginx -t
   \`\`\`

3. Check firewall rules:
   \`\`\`bash
   sudo ufw status verbose
   \`\`\`

## Uninstallation

To completely remove the application:

\`\`\`bash
chmod +x uninstall.sh
./uninstall.sh
\`\`\`

This will remove:
- Application files and directory
- Database (with confirmation)
- System service
- Nginx configuration
- Application user
- Backup scripts and cron jobs

## Development

### Local Development

1. Clone the repository
2. Install dependencies: `npm install`
3. Run development server: `npm run dev`
4. Access at `http://localhost:3000`

### Database Schema

The application uses SQLite with the following tables:
- `users`: User authentication and profiles
- `gold_holdings`: Individual gold items in portfolio
- `transactions`: Buy/sell transaction history
- `gold_prices`: Historical gold price data

### Technology Stack

- **Frontend**: Next.js 14, React, Tailwind CSS
- **Backend**: Next.js API routes, SQLite
- **Authentication**: JWT with bcrypt password hashing
- **Database**: better-sqlite3
- **Deployment**: Node.js, nginx, systemd

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review the logs for error messages
3. Ensure all dependencies are properly installed
4. Verify file permissions and ownership

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

**Gold Financial Books** - Manage your precious metal investments with elegance and precision.
