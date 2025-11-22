# AxionAX Mock RPC Server

Lightweight JSON-RPC 2.0 server for testing blockchain interactions without a full node.

## Features

- ✅ Standard Ethereum JSON-RPC 2.0 endpoints
- ✅ HTTP and WebSocket support
- ✅ Mock blockchain state with auto-incrementing blocks
- ✅ Transaction simulation with receipts
- ✅ Health check endpoint
- ✅ Docker support

## Supported RPC Methods

### Network
- `net_version` - Returns network/chain ID
- `eth_chainId` - Returns chain ID in hex

### Blocks
- `eth_blockNumber` - Returns latest block number
- `eth_getBlockByNumber` - Returns block by number
- `eth_getBlockByHash` - Returns block by hash

### Accounts
- `eth_getBalance` - Returns account balance
- `eth_getTransactionCount` - Returns account nonce

### Gas
- `eth_gasPrice` - Returns current gas price (1 Gwei)
- `eth_estimateGas` - Estimates gas for transaction (21000)

### Transactions
- `eth_sendRawTransaction` - Submits signed transaction
- `eth_getTransactionByHash` - Returns transaction details
- `eth_getTransactionReceipt` - Returns transaction receipt

### Calls
- `eth_call` - Executes contract call (returns empty)

### WebSocket Subscriptions
- `eth_subscribe` - Subscribe to events (newHeads supported)

## Environment Variables

- `PORT` - HTTP RPC port (default: 8545)
- `WS_PORT` - WebSocket port (default: 8546)
- `CHAIN_ID` - Network chain ID (default: 888)
- `NETWORK` - Network name (default: axionax-testnet-1)

## Usage

### Local Development

```bash
npm install
npm start
```

### Docker

```bash
# Build
docker build -t axionax-mock-rpc .

# Run
docker run -p 8545:8545 -p 8546:8546 axionax-mock-rpc
```

### Test Requests

```bash
# Get block number
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# Get balance
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb","latest"],"id":1}'

# Health check
curl http://localhost:8545/health
```

## Notes

- Transactions are "mined" after 3 seconds
- 10 mock accounts are pre-generated with random balances
- Blocks auto-increment on each `eth_blockNumber` call
- All data is in-memory and resets on restart
