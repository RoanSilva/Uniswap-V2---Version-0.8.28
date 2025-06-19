// ===================================
// ARQUIVO 1: scripts/trading/advancedBot.js
// Bot Avançado com Estratégias
// ===================================

const { ethers } = require("hardhat");
const { TradingBotManager } = require('./tradingBots.js');

class AdvancedTradingBot extends TradingBotManager {
    constructor() {
        super();
        this.strategies = {
            volumeSimulation: true,
            priceManipulation: true,
            liquidityMining: false,
            arbitrage: false
        };
    }

    // Estratégia de Simulação de Volume
    async executeVolumeSimulation() {
        const targetVolume = ethers.utils.parseEther("5000"); // 5k tokens por hora
        const hourlyTrades = 120; // 1 trade a cada 30s
        const averageTradeSize = targetVolume.div(hourlyTrades);

        console.log("📈 Executando estratégia de simulação de volume");
        console.log(`🎯 Meta: ${ethers.utils.formatEther(targetVolume)} tokens/hora`);
        console.log(`🔄 Trades médios: ${ethers.utils.formatEther(averageTradeSize)} tokens`);

        // Ajustar configurações dos bots
        this.buyBot.targetTradeSize = averageTradeSize;
        this.sellBot.targetTradeSize = averageTradeSize;
    }

    // Estratégia de Manipulação de Preço
    async executePriceManipulation(direction = 'up') {
        console.log(`📊 Executando manipulação de preço: ${direction}`);
        
        if (direction === 'up') {
            // Mais compras que vendas
            this.buyBot.interval = 20; // Mais frequente
            this.sellBot.interval = 60; // Menos frequente
        } else {
            // Mais vendas que compras
            this.buyBot.interval = 60;
            this.sellBot.interval = 20;
        }
    }
}

// ===================================
// ARQUIVO 2: scripts/trading/monitorBot.js
// Bot de Monitoramento
// ===================================

class MonitoringBot {
    constructor(spbToken, bpsToken, pair) {
        this.spbToken = spbToken;
        this.bpsToken = bpsToken;
        this.pair = pair;
        this.priceHistory = [];
        this.volumeHistory = [];
    }

    async startMonitoring() {
        console.log("📊 Iniciando monitoramento do mercado...");
        
        setInterval(async () => {
            await this.collectMarketData();
            await this.analyzeMarket();
        }, 30000); // A cada 30 segundos
    }

    async collectMarketData() {
        try {
            const reserves = await this.pair.getReserves();
            const price = reserves[1].mul(ethers.utils.parseEther("1")).div(reserves[0]);
            const timestamp = Date.now();

            this.priceHistory.push({ price, timestamp });
            
            // Manter apenas últimas 100 leituras
            if (this.priceHistory.length > 100) {
                this.priceHistory.shift();
            }

            console.log(`💰 Preço atual SPB/BPS: ${ethers.utils.formatEther(price)}`);
        } catch (error) {
            console.error("❌ Erro ao coletar dados:", error.message);
        }
    }

    async analyzeMarket() {
        if (this.priceHistory.length < 2) return;

        const currentPrice = this.priceHistory[this.priceHistory.length - 1].price;
        const previousPrice = this.priceHistory[this.priceHistory.length - 2].price;
        
        const priceChange = currentPrice.sub(previousPrice);
        const priceChangePercent = priceChange.mul(10000).div(previousPrice); // Base 10000 para 2 decimais

        if (priceChangePercent.abs().gt(100)) { // > 1%
            const direction = priceChange.gt(0) ? "📈 ALTA" : "📉 BAIXA";
            console.log(`🚨 Movimento significativo: ${direction} (${ethers.utils.formatEther(priceChangePercent.abs())}%)`);
        }
    }

    generateDailyReport() {
        const now = Date.now();
        const oneDayAgo = now - 24 * 60 * 60 * 1000;
        
        const dayPrices = this.priceHistory.filter(entry => entry.timestamp > oneDayAgo);
        
        if (dayPrices.length === 0) return;

        const prices = dayPrices.map(entry => parseFloat(ethers.utils.formatEther(entry.price)));
        const high = Math.max(...prices);
        const low = Math.min(...prices);
        const open = prices[0];
        const close = prices[prices.length - 1];
        const change = ((close - open) / open * 100).toFixed(2);

        console.log("\n📊 RELATÓRIO DIÁRIO SPB/BPS:");
        console.log("================================");
        console.log(`🔴 Abertura: ${open.toFixed(6)}`);
        console.log(`🟢 Fechamento: ${close.toFixed(6)}`);
        console.log(`⬆️  Máxima: ${high.toFixed(6)}`);
        console.log(`⬇️  Mínima: ${low.toFixed(6)}`);
        console.log(`📈 Variação: ${change}%`);
        console.log("================================\n");
    }
}

// ===================================
// ARQUIVO 3: scripts/trading/liquidityBot.js
// Bot de Gerenciamento de Liquidez
// ===================================

class LiquidityBot {
    constructor(spbToken, bpsToken, router, signer) {
        this.spbToken = spbToken;
        this.bpsToken = bpsToken;
        this.router = router;
        this.signer = signer;
        this.minLiquidity = ethers.utils.parseEther("10000"); // Liquidez mínima
    }

    async maintainLiquidity() {
        console.log("💧 Verificando liquidez do pool...");
        
        try {
            const pairAddress = await this.router.factory().getPair(
                this.spbToken.address,
                this.bpsToken.address
            );
            
            const pair = await ethers.getContractAt("IUniswapV2Pair", pairAddress);
            const reserves = await pair.getReserves();
            
            const reserve0 = reserves[0]; // SPB
            const reserve1 = reserves[1]; // BPS
            
            console.log(`💰 Liquidez atual: ${ethers.utils.formatEther(reserve0)} SPB, ${ethers.utils.formatEther(reserve1)} BPS`);
            
            // Verificar se precisa adicionar liquidez
            if (reserve0.lt(this.minLiquidity) || reserve1.lt(this.minLiquidity)) {
                await this.addLiquidity();
            }
            
        } catch (error) {
            console.error("❌ Erro ao verificar liquidez:", error.message);
        }
    }

    async addLiquidity() {
        const amountSPB = ethers.utils.parseEther("5000");
        const amountBPS = ethers.utils.parseEther("500");
        
        console.log("💧 Adicionando liquidez ao pool...");
        
        try {
            // Aprovar tokens
            await this.spbToken.approve(this.router.address, amountSPB);
            await this.bpsToken.approve(this.router.address, amountBPS);
            
            // Adicionar liquidez
            const deadline = Math.floor(Date.now() / 1000) + 60 * 20;
            
            const tx = await this.router.addLiquidity(
                this.spbToken.address,
                this.bpsToken.address,
                amountSPB,
                amountBPS,
                amountSPB.mul(95).div(100), // 5% slippage
                amountBPS.mul(95).div(100),
                this.signer.address,
                deadline
            );
            
            await tx.wait();
            console.log("✅ Liquidez adicionada com sucesso!");
            
        } catch (error) {
            console.error("❌ Erro ao adicionar liquidez:", error.message);
        }
    }
}

// ===================================
// ARQUIVO 4: scripts/trading/runBots.js
// Script Principal para Executar Bots
// ===================================

async function runTradingSystem() {
    console.log("🚀 INICIANDO SISTEMA DE TRADING");
    console.log("================================");
    
    try {
        // Inicializar gerenciador principal
        const manager = new AdvancedTradingBot();
        await manager.initialize();
        
        // Inicializar bot de monitoramento
        const monitor = new MonitoringBot(
            manager.spbToken,
            manager.bpsToken,
            manager.pair
        );
        
        // Inicializar bot de liquidez
        const liquidityBot = new LiquidityBot(
            manager.spbToken,
            manager.bpsToken,
            manager.router,
            manager.signer
        );
        
        // Executar estratégias
        await manager.executeVolumeSimulation();
        await manager.executePriceManipulation('up');
        
        // Iniciar monitoramento
        await monitor.startMonitoring();
        
        // Iniciar sistema de trading
        await manager.start();
        
        // Manutenção de liquidez a cada 10 minutos
        setInterval(async () => {
            await liquidityBot.maintainLiquidity();
        }, 10 * 60 * 1000);
        
        // Relatório diário
        setInterval(() => {
            monitor.generateDailyReport();
        }, 24 * 60 * 60 * 1000);
        
        console.log("✅ Sistema de trading iniciado com sucesso!");
        console.log("💡 Pressione Ctrl+C para parar");
        
        // Graceful shutdown
        process.on('SIGINT', async () => {
            console.log("\n🛑 Parando sistema de trading...");
            manager.stop();
            console.log("✅ Sistema parado com segurança!");
            process.exit(0);
        });
        
    } catch (error) {
        console.error("❌ Erro fatal no sistema:", error);
        process.exit(1);
    }
}

// ===================================
// ARQUIVO 5: scripts/trading/config.js
// Configurações Avançadas
// ===================================

const TRADING_CONFIG = {
    // Configurações de Volume
    VOLUME_SIMULATION: {
        DAILY_TARGET: ethers.utils.parseEther("50000"), // 50k tokens/dia
        HOURLY_TRADES: 120, // 2 trades por minuto
        VOLATILITY_FACTOR: 0.15, // 15% de variação
        TREND_STRENGTH: 0.05 // 5% de tendência
    },
    
    // Configurações de Preço
    PRICE_MANAGEMENT: {
        TARGET_PRICE_SPB: ethers.utils.parseEther("0.1"), // 1 SPB = 0.1 BPS
        PRICE_TOLERANCE: 0.02, // 2% de tolerância
        MANIPULATION_STRENGTH: 0.1, // 10% de força
        RECOVERY_TIME: 30 * 60 // 30 minutos para recuperar
    },
    
    // Configurações de Liquidez
    LIQUIDITY_MANAGEMENT: {
        MIN_LIQUIDITY_SPB: ethers.utils.parseEther("50000"),
        MIN_LIQUIDITY_BPS: ethers.utils.parseEther