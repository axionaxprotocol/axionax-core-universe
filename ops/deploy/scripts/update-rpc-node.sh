#!/bin/bash
# Update RPC Node with newly built image

set -e

echo "🔄 Updating RPC Node to use local image..."

# Stop current RPC node
echo "⏹️  Stopping current RPC node..."
cd /opt/axionax-deploy
docker-compose -f docker-compose.vps.yml stop rpc-node

# Remove old container
echo "🗑️  Removing old container..."
docker-compose -f docker-compose.vps.yml rm -f rpc-node

# Start with new image
echo "🚀 Starting RPC node with new image..."
docker-compose -f docker-compose.vps.yml up -d rpc-node

# Wait for startup
echo "⏳ Waiting for RPC node to start..."
sleep 10

# Check status
echo "✅ Checking RPC node status..."
docker ps | grep axionax-rpc
docker logs axionax-rpc --tail=20

echo ""
echo "✅ RPC Node update complete!"
echo "Test with: curl -X POST http://localhost:8545 -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}'"
