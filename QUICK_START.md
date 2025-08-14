# 🏆 Gold Financial Books - Quick Start Guide

## Automatic Setup (Recommended)

### For Development
\`\`\`bash
# Clone or download the application
# Navigate to the project directory
npm run setup
npm run dev
\`\`\`

### For Production
\`\`\`bash
# On your Ubuntu server
npm run setup:prod
sudo systemctl start gold-books
\`\`\`

## Manual Setup (Advanced Users)

### Prerequisites
- Node.js 18+
- Ubuntu 20.04+ (for production)

### Development Setup
1. **Install dependencies:**
   \`\`\`bash
   npm install
   \`\`\`

2. **Create environment file:**
   \`\`\`bash
   cp .env.example .env.local
   # Edit .env.local with your settings
   \`\`\`

3. **Initialize database:**
   \`\`\`bash
   npm run db:migrate
   npm run db:seed
   \`\`\`

4. **Start development server:**
   \`\`\`bash
   npm run dev
   \`\`\`

### Production Setup
1. **Run production setup:**
   \`\`\`bash
   chmod +x configure.sh
   ./configure.sh production
   \`\`\`

2. **Update production config:**
   \`\`\`bash
   nano .env.production
   # Update NEXT_PUBLIC_APP_URL with your domain
   \`\`\`

3. **Start service:**
   \`\`\`bash
   sudo systemctl start gold-books
   sudo systemctl enable gold-books
   \`\`\`

## Default Login
- **Email:** admin@goldbooks.com
- **Password:** admin123

## Features
- ✅ Portfolio tracking
- ✅ Transaction management
- ✅ Real-time gold valuation
- ✅ Secure authentication
- ✅ Responsive design
- ✅ Local SQLite database
- ✅ Production-ready deployment

## Support
For issues or questions, check the logs:
\`\`\`bash
# Development
npm run dev

# Production
sudo journalctl -u gold-books -f
