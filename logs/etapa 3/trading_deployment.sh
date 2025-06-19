# ===================================
# ETAPA 3: DEPLOYMENT E EXECUÇÃO
# Scripts de Instalação e Configuração
# ===================================

#!/bin/bash

# ARQUIVO 1: setup-trading.sh
# Script de setup completo para a Etapa 3

echo "🚀 CONFIGURANDO ETAPA 3 - BOTS DE TRADING"
echo "=========================================="

# 1. Criar estrutura de diretórios
echo "📁 Criando estrutura de diretórios..."
mkdir -p scripts/trading
mkdir -p test/trading
mkdir -p data/analytics
mkdir -p logs/trading
mkdir -p config/trading

# 2. Instalar dependências adicionais
echo "📦 Instalando dependências..."
npm install --save-dev chai-as-promised
npm install --save axios ws node-cron
npm install --save lodash moment

# 3. Criar arquivos de configuração
echo "⚙️  Criando arquivos de configuração..."

# Config principal dos bots
cat > config/trading/bots.json << 'EOF'
{
  "buyBot": {
    "name": "SPB Buy Bot",
    "enabled": true,
    "interval": 30,
    "minTradeAmount": "10",
    "maxTradeAmount": "100",
    "slippage": 5,
    "gasLimit": 200000
  },
  "sellBot": {
    "name": "SPB Sell Bot", 
    "enabled": true,
    "interval": 45,
    "minTradeAmount": "10",
    "maxTradeAmount": "100",
    "slippage": 5,
    "gasLimit": 200000
  },
  "monitor": {
    "enabled": true,
    "interval": 30,
    "alerts": {
      "priceChange": 5,
      "volumeSpike": 200,
      "liquidityDrop": 50
    }
  }
}
EOF

# Configuração de rede
cat > config/trading/networks.json << 'EOF'
{
  "localhost": {
    "name": "Hardhat Local",
    "rpc": "http://127.0.0.1:8545",
    "chainId": 31337,
    "gasPrice": 20000000000,
    "confirmations": 1
  },
  "bscTestnet": {
    "name": "BSC Testnet",
    "rpc": "https://data-seed-prebsc-1-s1.binance.org:8545",
    "chainId": 97,
    "gasPrice": 10000000000,
    "confirmations": 3
  }
}
EOF

# 4. Configurar logs
echo "📝 Configurando sistema de logs..."
cat > scripts/trading/logger.js << 'EOF'
const fs = require('fs');
const path = require('path');

class Logger {
    constructor(service) {
        this.service = service;
        this.logDir = path.join(__dirname, '../../logs/trading');
        
        // Criar diretório se não existir
        if (!fs.existsSync(this.logDir)) {
            fs.mkdirSync(this.logDir, { recursive: true });
        }
    }

    log(level, message, data = null) {
        const timestamp = new Date().toISOString();
        const logEntry = {
            timestamp,
            service: this.service,
            level,
            message,
            data
        };

        // Console output
        const emoji = this.getEmoji(level);
        console.log(`${emoji} [${timestamp}] ${this.service}: ${message}`);
        if (data) console.log(data);

        // File output
        const filename = `${this.service}-${new Date().toISOString().split('T')[0]}.log`;
        const filepath = path.join(this.logDir, filename);
        fs.appendFileSync(filepath, JSON.stringify(logEntry) + '\n');
    }

    getEmoji(level) {
        const emojis = {
            info: 'ℹ️',
            success: '✅',
            warning: '⚠️',
            error: '❌',
            trade: '💱',
            price: '💰'
        };
        return emojis[level] || 'ℹ️';
    }

    info(message, data) { this.log('info', message, data); }
    success(message, data) { this.log('success', message, data); }
    warning(message, data) { this.log('warning', message, data); }
    error(message, data) { this.log('error', message, data); }
    trade(message, data) { this.log('trade', message, data); }
    price(message, data) { this.log('price', message, data); }
}

module.exports = Logger;
EOF

# 5. Script de verificação de ambiente
cat > scripts/trading/checkEnvironment.js << 'EOF'
const { ethers } = require("hardhat");
const fs = require('fs');
const path = require('path');

async function checkEnvironment() {
    console.log("🔍 VERIFICANDO AMBIENTE PARA TRADING");
    console.log("====================================");
    
    let allChecksPass = true;

    // 1. Verificar conexão com a rede
    try {
        const provider = ethers.provider;
        const network = await provider.getNetwork();
        console.log(`✅ Conectado à rede: ${network.name} (Chain ID: ${network.chainId})`);
    } catch (error) {
        console.error("❌ Erro de conexão com a rede:", error.message);
        allChecksPass = false;
    }

    // 2. Verificar contratos deployados
    try {
        const deployFile = path.join(__dirname, '../deployments/localhost.json');
        if (fs.existsSync(deployFile)) {
            const contracts = JSON.parse(fs.readFileSync(deployFile, 'utf8'));
            console.log("✅ Contratos encontrados:");
            console.log(`   SPB Token: ${contracts.SPBToken}`);
            console.log(`   BPS Token: ${contracts.BPSToken}`);
            console.log(`   Router: ${contracts.UniswapV2Router}`);
        } else {
            console.error("❌ Arquivo de deployment não encontrado");
            allChecksPass = false;
        }
    } catch (error) {
        console.error("❌ Erro ao verificar contratos:", error.message);
        allChecksPass = false;
    }

    // 3. Verificar saldos das contas
    try {
        const [owner] = await ethers.getSigners();
        const balance = await owner.getBalance();
        console.log(`✅ Saldo da conta principal: ${ethers.utils.formatEther(balance)} ETH`);
        
        if (balance.lt(ethers.utils.parseEther("1"))) {
            console.warn("⚠️  Saldo baixo de ETH para gas");
        }
    } catch (error) {
        console.error("❌ Erro ao verificar saldos:", error.message);
        allChecksPass = false;
    }

    // 4. Verificar dependências
    try {
        require('../trading/tradingBots.js');
        console.log("✅ Scripts de trading carregados");
    } catch (error) {
        console.error("❌ Erro ao carregar scripts:", error.message);
        allChecksPass = false;
    }

    console.log("\n" + "=".repeat(40));
    if (allChecksPass) {
        console.log("✅ AMBIENTE PRONTO PARA TRADING!");
    } else {
        console.log("❌ PROBLEMAS ENCONTRADOS - VERIFIQUE OS ERROS ACIMA");
    }
    console.log("=".repeat(40));

    return allChecksPass;
}

if (require.main === module) {
    checkEnvironment().catch(console.error);
}

module.exports = { checkEnvironment };
EOF

# 6. Script de inicialização rápida
cat > scripts/trading/quickStart.js << 'EOF'
const { TradingBotManager } = require('./tradingBots.js');
const { checkEnvironment } = require('./checkEnvironment.js');
const Logger = require('./logger.js');

async function quickStart() {
    const logger = new Logger('QuickStart');
    
    logger.info("🚀 INÍCIO RÁPIDO - BOTS DE TRADING");
    
    // 1. Verificar ambiente
    const envOk = await checkEnvironment();
    if (!envOk) {
        logger.error("Ambiente não está pronto");
        process.exit(1);
    }

    // 2. Inicializar sistema
    const manager = new TradingBotManager();
    await manager.initialize();
    
    // 3. Configuração rápida
    logger.info("Aplicando configurações rápidas...");
    
    // Volumes menores para teste rápido
    manager.CONFIG.TRADING_AMOUNTS.MIN_TRADE = ethers.utils.parseEther("5");
    manager.CONFIG.TRADING_AMOUNTS.MAX_TRADE = ethers.utils.parseEther("25");
    
    // Intervalos mais frequentes
    manager.CONFIG.TRADING_INTERVALS.BUY_BOT = 20;
    manager.CONFIG.TRADING_INTERVALS.SELL_BOT = 30;
    
    // 4. Iniciar trading
    await manager.start();
    
    logger.success("Sistema iniciado! Executando por 5 minutos...");
    
    // 5. Executar por 5 minutos para demonstração
    setTimeout(async () => {
        logger.info("Parando sistema...");
        manager.stop();
        await manager.getStats();
        logger.success("Demonstração concluída!");
        process.exit(0);
    }, 5 * 60 * 1000); // 5 minutos
}

if (require.main === module) {
    quickStart().catch(console.error);
}

module.exports = { quickStart };
EOF

echo "✅ Setup da Etapa 3 concluído!"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "=================="
echo "1. npm run compile"
echo "2. npm run deploy:localhost" 
echo "3. npm run bots:start"
echo ""
echo "🔧 COMANDOS DISPONÍVEIS:"
echo "========================"
echo "npm run bots:start       # Iniciar bots básicos"
echo "npm run bots:advanced    # Iniciar sistema avançado"
echo "npm run trading:simulate # Simulação completa"
echo "npm run trading:test     # Testes dos bots"
echo ""
echo "📊 MONITORAMENTO:"
echo "================="
echo "npm run analytics:report # Relatório de performance"
echo "npm run analytics:export # Exportar dados"
echo ""

# ===================================
# ARQUIVO 2: Dockerfile para Ambiente de Trading
# ===================================

cat > Dockerfile.trading << 'EOF'
FROM node:16-alpine

# Instalar dependências do sistema
RUN apk add --no-cache git python3 make g++

# Criar diretório de trabalho
WORKDIR /app

# Copiar arquivos de configuração
COPY package*.json ./
COPY hardhat.config.js ./

# Instalar dependências
RUN npm install

# Copiar código fonte
COPY . .

# Compilar contratos
RUN npm run compile

# Criar diretórios necessários
RUN mkdir -p logs/trading data/analytics

# Expor porta para monitoramento
EXPOSE 3000

# Comando padrão
CMD ["npm", "run", "bots:start"]
EOF

# ===================================
# ARQUIVO 3: docker-compose.yml para Stack Completa
# ===================================

cat > docker-compose.trading.yml << 'EOF'
version: '3.8'

services:
  hardhat-node:
    image: node:16-alpine
    ports:
      - "8545:8545"
    volumes:
      - .:/app
    working_dir: /app
    command: npx hardhat node
    networks:
      - trading-network

  trading-bots:
    build:
      context: .
      dockerfile: Dockerfile.trading
    depends_on:
      - hardhat-node
    volumes:
      - ./logs:/app/logs
      - ./data:/app/data
    environment:
      - HARDHAT_NETWORK=localhost
      - RPC_URL=http://hardhat-node:8545
    networks:
      - trading-network

  monitor:
    image: node:16-alpine
    depends_on:
      - hardhat-node
      - trading-bots
    volumes:
      - .:/app
    working_dir: /app
    command: npm run bots:monitor
    networks:
      - trading-network

networks:
  trading-network:
    driver: bridge
EOF

# ===================================
# ARQUIVO 4: Makefile para Automação
# ===================================

cat > Makefile << 'EOF'
.PHONY: setup compile deploy trading test clean

# Setup inicial
setup:
	@echo "🏗️  Configurando projeto..."
	npm install
	chmod +x setup-trading.sh
	./setup-trading.sh

# Compilar contratos
compile:
	@echo "🔨 Compilando contratos..."
	npm run compile

# Deploy completo
deploy:
	@echo "🚀 Fazendo deploy..."
	npm run node &
	sleep 5
	npm run deploy:localhost
	
# Iniciar trading
trading:
	@echo "💱 Iniciando sistema de trading..."
	npm run bots:advanced

# Simulação rápida
quick:
	@echo "⚡ Simulação rápida..."
	node scripts/trading/quickStart.js

# Testes
test:
	@echo "🧪 Executando testes..."
	npm test
	npm run trading:test

# Limpeza
clean:
	@echo "🧹 Limpando..."
	rm -rf artifacts cache logs/trading/* data/analytics/*
	npm run clean

# Stack Docker completa
docker-up:
	@echo "🐳 Iniciando stack Docker..."
	docker-compose -f docker-compose.trading.yml up -d

docker-down:
	@echo "🐳 Parando stack Docker..."
	docker-compose -f docker-compose.trading.yml down

# Monitoramento
monitor:
	@echo "📊 Iniciando monitoramento..."
	npm run analytics:report

# Relatório final
report:
	@echo "📋 Gerando relatório final..."
	npm run analytics:export
	@echo "Relatório salvo em data/analytics/"
EOF

# ===================================
# ARQUIVO 5: README da Etapa 3
# ===================================

cat > ETAPA3-README.md << 'EOF'
# 🤖 ETAPA 3: Bots de Trading

Sistema completo de bots para simular volume e atividade de trading entre os tokens SPB e BPS.

## 🚀 Início Rápido

```bash
# 1. Setup inicial
make setup

# 2. Compilar e fazer deploy
make compile
make deploy

# 3. Iniciar trading
make trading
```

## 📋 Funcionalidades Implementadas

### ✅ Bots de Trading
- **Buy Bot**: Executa compras de SPB usando BPS
- **Sell Bot**: Executa vendas de SPB por BPS  
- **Intervalos configuráveis**: 30s (compra) e 45s (venda)
- **Volumes aleatórios**: Entre 10-100 tokens por trade

### ✅ Sistema de Monitoramento
- **Análise de preço**: Tracking de mudanças em tempo real
- **Métricas de volume**: Acompanhamento de volume de trading
- **Alertas**: Notificações para movimentos significativos
- **Relatórios**: Estatísticas detalhadas de performance

### ✅ Gerenciamento de Liquidez
- **Auto-add**: Adiciona liquidez automaticamente quando necessário
- **Monitoring**: Monitora reservas do pool constantemente
- **Balanceamento**: Mantém ratio adequado entre tokens

### ✅ Analytics Avançado
- **Histórico de preços**: Coleta e armazena dados históricos
- **Cálculo de métricas**: Volume, sucesso, gas, etc.
- **Exportação**: Dados em JSON para análise externa
- **Dashboards**: Relatórios visuais em tempo real

## 🎯 Objetivos da Etapa 3

1. **Simular Volume Real**: Criar aparência de trading ativo
2. **Manipular Preços**: Controlar direção e volatilidade
3. **Criar Narrativa**: Histórico de crescimento consistente
4. **Preparar Liquidação**: Base para próximas etapas

## 📊 Configurações

### Volumes de Trading
- **Mínimo**: 10 tokens por trade
- **Máximo**: 100 tokens por trade
- **Meta diária**: 10.000 tokens
- **Volatilidade**: 2% de variação

### Timing
- **Buy Bot**: A cada 30 segundos
- **Sell Bot**: A cada 45 segundos
- **Monitor**: A cada 30 