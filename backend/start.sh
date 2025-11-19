#!/bin/bash
# Start Baby Monitor Backend

set -e

echo "🚀 Starting Baby Monitor Backend..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Run setup.sh first."
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Copying from .env.example..."
    cp .env.example .env
    echo "⚠️  Please edit .env with your configuration!"
fi

# Check if Docker services are running
if ! docker-compose ps | grep -q "Up"; then
    echo "🐳 Starting Docker services..."
    docker-compose up -d
    echo "⏳ Waiting for services to be ready..."
    sleep 10
fi

# Create logs directory
mkdir -p logs

# Start Flask application
echo "✅ Starting Flask application..."
echo ""
echo "📡 API available at: http://localhost:5000"
echo "📊 MinIO console at: http://localhost:9001"
echo ""
echo "Press Ctrl+C to stop"
echo ""

python src/app.py
