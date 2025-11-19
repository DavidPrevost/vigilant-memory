#!/bin/bash
# Setup Baby Monitor Backend

set -e

echo "🔧 Setting up Baby Monitor Backend..."

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | grep -oP '\d+\.\d+')
REQUIRED_VERSION="3.10"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Python $REQUIRED_VERSION or higher required. Found: $PYTHON_VERSION"
    exit 1
fi

echo "✓ Python $PYTHON_VERSION found"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first."
    exit 1
fi

echo "✓ Docker found"

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose not found. Please install Docker Compose first."
    exit 1
fi

echo "✓ Docker Compose found"

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
else
    echo "✓ Virtual environment already exists"
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
echo "📦 Upgrading pip..."
pip install --upgrade pip > /dev/null

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt

# Create .env if it doesn't exist
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "⚠️  Please edit .env with your configuration!"
else
    echo "✓ .env file exists"
fi

# Create logs directory
mkdir -p logs

# Start Docker services
echo "🐳 Starting Docker services..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Check service health
echo "🏥 Checking service health..."

if docker-compose ps | grep -q "postgres.*Up"; then
    echo "✓ PostgreSQL is running"
else
    echo "⚠️  PostgreSQL may not be ready"
fi

if docker-compose ps | grep -q "timescaledb.*Up"; then
    echo "✓ TimescaleDB is running"
else
    echo "⚠️  TimescaleDB may not be ready"
fi

if docker-compose ps | grep -q "mosquitto.*Up"; then
    echo "✓ MQTT (Mosquitto) is running"
else
    echo "⚠️  MQTT may not be ready"
fi

if docker-compose ps | grep -q "redis.*Up"; then
    echo "✓ Redis is running"
else
    echo "⚠️  Redis may not be ready"
fi

if docker-compose ps | grep -q "minio.*Up"; then
    echo "✓ MinIO is running"
else
    echo "⚠️  MinIO may not be ready"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env with your configuration"
echo "2. Run './start.sh' to start the backend"
echo ""
echo "Useful commands:"
echo "  ./start.sh              - Start the backend"
echo "  docker-compose ps       - Check service status"
echo "  docker-compose logs     - View logs"
echo "  docker-compose down     - Stop services"
echo ""
