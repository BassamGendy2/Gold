#!/bin/bash

# Development Environment Setup Script
echo "🚀 Setting up Gold Financial Books - Development Environment"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version 18+ required. Current version: $(node -v)"
    exit 1
fi

echo "✅ Node.js $(node -v) detected"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Create local environment file if it doesn't exist
if [ ! -f .env.local ]; then
    echo "📝 Creating .env.local file..."
    cp .env.local .env.local.example 2>/dev/null || echo "# Copy from .env.local and customize" > .env.local
    echo "⚠️  Please edit .env.local with your configuration"
fi

# Reset development database
echo "🗄️  Setting up development database..."
npm run db:reset

# Seed development data
echo "🌱 Seeding development data..."
npm run db:seed

echo ""
echo "✅ Development environment setup complete!"
echo ""
echo "🎯 Next steps:"
echo "   1. Edit .env.local with your configuration"
echo "   2. Run 'npm run dev' to start development server"
echo "   3. Visit http://localhost:3000"
echo "   4. Login with: test@example.com / password123"
echo ""
echo "🛠️  Available commands:"
echo "   npm run dev      - Start development server"
echo "   npm run db:reset - Reset development database"
echo "   npm run db:seed  - Seed development data"
echo ""
