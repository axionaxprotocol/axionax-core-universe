const express = require('express');
const app = express();

const PORT = process.env.PORT || 8545;
const WS_PORT = process.env.WS_PORT || 8546;
const CHAIN_ID = process.env.CHAIN_ID || '888';
const NETWORK = process.env.NETWORK || 'axionax-testnet-1';

app.use(express.json({ strict: false, type: 'application/json' }));

// Mock blockchain state
let blockNumber = 1000;
let accounts = {};
let transactions = {};
let blockCache = {};

// Generate mock address
function generateAddress() {
  return '0x' + Math.random().toString(16).substr(2, 40);
}

// Generate mock transaction hash
function generateTxHash() {
  return '0x' + Math.random().toString(16).substr(2, 64);
}

// JSON-RPC 2.0 Response Helper
function jsonRpcResponse(id, result) {
  return {
    jsonrpc: '2.0',
    id: id,
    result: result
  };
}

function jsonRpcError(id, code, message) {
  return {
    jsonrpc: '2.0',
    id: id,
    error: { code, message }
  };
}

// Initialize with some mock accounts
function initMockAccounts() {
  for (let i = 0; i < 10; i++) {
    const address = generateAddress();
    accounts[address] = {
      balance: '0x' + (Math.floor(Math.random() * 1000000) * 1e18).toString(16),
      nonce: 0
    };
  }
}

initMockAccounts();

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    network: NETWORK,
    chainId: CHAIN_ID,
    blockNumber: blockNumber,
    timestamp: Date.now()
  });
});

// Main RPC endpoint
app.post('/', (req, res) => {
  const { jsonrpc, method, params, id } = req.body;

  if (jsonrpc !== '2.0') {
    return res.json(jsonRpcError(id, -32600, 'Invalid Request'));
  }

  console.log(`[RPC] ${method}`, params);

  try {
    switch (method) {
      // Network
      case 'net_version':
        return res.json(jsonRpcResponse(id, CHAIN_ID));

      case 'eth_chainId':
        return res.json(jsonRpcResponse(id, '0x' + parseInt(CHAIN_ID).toString(16)));

      // Block info
      case 'eth_blockNumber':
        blockNumber++; // Simulate block progression
        return res.json(jsonRpcResponse(id, '0x' + blockNumber.toString(16)));

      case 'eth_getBlockByNumber': {
        const [blockNum, fullTx] = params;
        const num = blockNum === 'latest' ? blockNumber : parseInt(blockNum, 16);
        
        if (!blockCache[num]) {
          blockCache[num] = {
            number: '0x' + num.toString(16),
            hash: generateTxHash(),
            parentHash: num > 0 ? generateTxHash() : '0x0000000000000000000000000000000000000000000000000000000000000000',
            timestamp: '0x' + Math.floor(Date.now() / 1000).toString(16),
            gasLimit: '0x1c9c380',
            gasUsed: '0x5208',
            miner: generateAddress(),
            difficulty: '0x1',
            totalDifficulty: '0x' + num.toString(16),
            size: '0x' + (500 + Math.floor(Math.random() * 500)).toString(16),
            transactions: fullTx ? [] : [],
            transactionsRoot: generateTxHash(),
            stateRoot: generateTxHash(),
            receiptsRoot: generateTxHash()
          };
        }
        
        return res.json(jsonRpcResponse(id, blockCache[num]));
      }

      case 'eth_getBlockByHash': {
        const [hash, fullTx] = params;
        const mockBlock = {
          number: '0x' + blockNumber.toString(16),
          hash: hash,
          parentHash: generateTxHash(),
          timestamp: '0x' + Math.floor(Date.now() / 1000).toString(16),
          gasLimit: '0x1c9c380',
          gasUsed: '0x5208',
          miner: generateAddress(),
          difficulty: '0x1',
          totalDifficulty: '0x' + blockNumber.toString(16),
          size: '0x' + (500 + Math.floor(Math.random() * 500)).toString(16),
          transactions: fullTx ? [] : [],
          transactionsRoot: generateTxHash(),
          stateRoot: generateTxHash(),
          receiptsRoot: generateTxHash()
        };
        
        return res.json(jsonRpcResponse(id, mockBlock));
      }

      // Account info
      case 'eth_getBalance': {
        const [address, block] = params;
        const balance = accounts[address]?.balance || '0x0';
        return res.json(jsonRpcResponse(id, balance));
      }

      case 'eth_getTransactionCount': {
        const [address, block] = params;
        const nonce = accounts[address]?.nonce || 0;
        return res.json(jsonRpcResponse(id, '0x' + nonce.toString(16)));
      }

      // Gas
      case 'eth_gasPrice':
        return res.json(jsonRpcResponse(id, '0x3b9aca00')); // 1 Gwei

      case 'eth_estimateGas': {
        const [txObj] = params;
        const gasEstimate = '0x5208'; // 21000 gas
        return res.json(jsonRpcResponse(id, gasEstimate));
      }

      // Transactions
      case 'eth_sendRawTransaction': {
        const [signedTx] = params;
        const txHash = generateTxHash();
        
        transactions[txHash] = {
          hash: txHash,
          nonce: '0x' + Math.floor(Math.random() * 100).toString(16),
          blockHash: null,
          blockNumber: null,
          transactionIndex: null,
          from: generateAddress(),
          to: generateAddress(),
          value: '0x' + (Math.floor(Math.random() * 1000) * 1e18).toString(16),
          gas: '0x5208',
          gasPrice: '0x3b9aca00',
          input: '0x',
          v: '0x1b',
          r: generateTxHash(),
          s: generateTxHash()
        };
        
        // Simulate mining after 3 seconds
        setTimeout(() => {
          if (transactions[txHash]) {
            transactions[txHash].blockHash = generateTxHash();
            transactions[txHash].blockNumber = '0x' + blockNumber.toString(16);
            transactions[txHash].transactionIndex = '0x0';
          }
        }, 3000);
        
        return res.json(jsonRpcResponse(id, txHash));
      }

      case 'eth_getTransactionByHash': {
        const [txHash] = params;
        const tx = transactions[txHash] || null;
        return res.json(jsonRpcResponse(id, tx));
      }

      case 'eth_getTransactionReceipt': {
        const [txHash] = params;
        const tx = transactions[txHash];
        
        if (!tx || !tx.blockHash) {
          return res.json(jsonRpcResponse(id, null));
        }
        
        const receipt = {
          transactionHash: txHash,
          transactionIndex: tx.transactionIndex,
          blockHash: tx.blockHash,
          blockNumber: tx.blockNumber,
          from: tx.from,
          to: tx.to,
          cumulativeGasUsed: '0x5208',
          gasUsed: '0x5208',
          contractAddress: null,
          logs: [],
          logsBloom: '0x' + '0'.repeat(512),
          status: '0x1' // Success
        };
        
        return res.json(jsonRpcResponse(id, receipt));
      }

      // Call
      case 'eth_call': {
        const [txObj, block] = params;
        return res.json(jsonRpcResponse(id, '0x')); // Empty response
      }

      // Unsupported method
      default:
        console.log(`[RPC] Unsupported method: ${method}`);
        return res.json(jsonRpcError(id, -32601, `Method ${method} not found`));
    }
  } catch (error) {
    console.error(`[RPC Error] ${method}:`, error);
    return res.json(jsonRpcError(id, -32603, 'Internal error'));
  }
});

// WebSocket support (basic)
const http = require('http');
const WebSocket = require('ws');

const server = http.createServer(app);
const wss = new WebSocket.Server({ port: WS_PORT });

wss.on('connection', (ws) => {
  console.log('[WebSocket] Client connected');
  
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      console.log('[WebSocket] Received:', data.method);
      
      // Handle subscription requests
      if (data.method === 'eth_subscribe') {
        const subscriptionId = '0x' + Math.random().toString(16).substr(2, 32);
        ws.send(JSON.stringify(jsonRpcResponse(data.id, subscriptionId)));
        
        // Send periodic updates for newHeads
        if (data.params[0] === 'newHeads') {
          const interval = setInterval(() => {
            if (ws.readyState === WebSocket.OPEN) {
              blockNumber++;
              ws.send(JSON.stringify({
                jsonrpc: '2.0',
                method: 'eth_subscription',
                params: {
                  subscription: subscriptionId,
                  result: {
                    number: '0x' + blockNumber.toString(16),
                    hash: generateTxHash(),
                    parentHash: generateTxHash(),
                    timestamp: '0x' + Math.floor(Date.now() / 1000).toString(16)
                  }
                }
              }));
            } else {
              clearInterval(interval);
            }
          }, 3000);
        }
      } else {
        // Handle regular RPC calls over WebSocket
        ws.send(JSON.stringify(jsonRpcResponse(data.id, null)));
      }
    } catch (error) {
      console.error('[WebSocket Error]:', error);
    }
  });
  
  ws.on('close', () => {
    console.log('[WebSocket] Client disconnected');
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`
╔═══════════════════════════════════════════════════════════╗
║  AxionAX Mock RPC Server                                  ║
╠═══════════════════════════════════════════════════════════╣
║  Network:        ${NETWORK.padEnd(40)}║
║  Chain ID:       ${CHAIN_ID.padEnd(40)}║
║  HTTP RPC:       http://0.0.0.0:${PORT.toString().padEnd(33)}║
║  WebSocket RPC:  ws://0.0.0.0:${WS_PORT.toString().padEnd(35)}║
║  Health Check:   http://0.0.0.0:${PORT}/health${' '.repeat(20)}║
╠═══════════════════════════════════════════════════════════╣
║  Status: READY - Accepting JSON-RPC 2.0 requests          ║
╚═══════════════════════════════════════════════════════════╝
  `);
  console.log(`[INFO] Mock RPC server started with ${Object.keys(accounts).length} mock accounts`);
});

process.on('SIGTERM', () => {
  console.log('[INFO] SIGTERM received, shutting down gracefully...');
  server.close(() => {
    console.log('[INFO] Server closed');
    process.exit(0);
  });
});
