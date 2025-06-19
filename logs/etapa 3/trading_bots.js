// ===================================
// ETAPA 3: BOTS DE TRADING
// Society Token Project
// ===================================

const { ethers } = require("hardhat");
const fs = require('fs');
const path = require('path');

// Configurações dos Bots
const CONFIG = {
    // Intervalos de trading (em segundos)
    TRADING_INTERVALS: {
        BUY_BOT: 30,  // Bot de compra executa a cada 30s
        SELL_BOT: 45  // Bot de venda executa a cada 45s
    },
    
    // Valores de trading (em tokens)
    TRADING_AMOUNTS: {
        MIN_TRADE: ethers.utils.parseEther("10"),
        MAX_TRADE: ethers.utils.parseEther("100"),
        VOLUME_TARGET_DAILY: ethers.utils.parseEther("10000") // Meta diária
    },
    
    // Parâmetros de preço
    PRICE_SIMULATION: {
        VOLATILITY: 0.02, // 2% de volatilidade
        TREND_DIRECTION: 1, // 1 = alta, -1 = baixa, 0 = lateral
        PRICE_IMPACT: 0.001 // Impacto do volume no preço
    }
};

class TradingBot {
    constructor(name, tokenA, tokenB, router, signer) {
        this.name = name;
        this.tokenA = tokenA;
        this.tokenB = tokenB;
        this.router = router;
        this.signer = signer;
        this.isRunning = false;
        this.stats = {
            totalTrades: 0,
            totalVolume: ethers.BigNumber.from(0),
            successfulTrades: 0,
            failedTrades: 0,
            startTime: Date.now()
        };
    }

    async initialize() {
        console.log(`🤖 Inicializando ${this.name}...`);
        
        // Verificar aprovações
        await this.ensureApprovals();
        
        // Verificar saldos
        await this.checkBalances();
        
        console.log(`✅ ${this.name} inicializado com sucesso!`);
    }

    async ensureApprovals() {
        const maxApproval = ethers.constants.MaxUint256;
        
        // Aprovar TokenA para o Router
        const allowanceA = await this.tokenA.allowance(this.signer.address, this.router.address);
        if (allowanceA.lt(ethers.utils.parseEther("1000000"))) {
            console.log(`📝 Aprovando ${await this.tokenA.symbol()} para o Router...`);
            const tx = await this.tokenA.approve(this.router.address, maxApproval);
            await tx.wait();
            console.log(`✅ Aprovação de ${await this.tokenA.symbol()} concluída`);
        }

        // Aprovar TokenB para o Router
        const allowanceB = await this.tokenB.allowance(this.signer.address, this.router.address);
        if (allowanceB.lt(ethers.utils.parseEther("1000000"))) {
            console.log(`📝 Aprovando ${await this.tokenB.symbol()} para o Router...`);
            const tx = await this.tokenB.approve(this.router.address, maxApproval);
            await tx.wait();
            console.log(`✅ Aprovação de ${await this.tokenB.symbol()} concluída`);
        }
    }

    async checkBalances() {
        const balanceA = await this.tokenA.balanceOf(this.signer.address);
        const balanceB = await this.tokenB.balanceOf(this.signer.address);
        
        console.log(`💰 Saldos do ${this.name}:`);
        console.log(`   ${await this.tokenA.symbol()}: ${ethers.utils.formatEther(balanceA)}`);
        console.log(`   ${await this.tokenB.symbol()}: ${ethers.utils.formatEther(balanceB)}`);
        
        return { balanceA, balanceB };
    }

    generateRandomAmount() {
        const min = CONFIG.TRADING_AMOUNTS.MIN_TRADE;
        const max = CONFIG.TRADING_AMOUNTS.MAX_TRADE;
        const range = max.sub(min);
        const random = Math.random();
        const randomAmount = range.mul(Math.floor(random * 1000)).div(1000);
        return min.add(randomAmount);
    }

    async executeTrade(amountIn, tokenIn, tokenOut, isReverseTrade = false) {
        try {
            const path = [tokenIn.address, tokenOut.address];
            const to = this.signer.address;
            const deadline = Math.floor(Date.now() / 1000) + 60 * 20; // 20 minutos

            // Calcular quantidade mínima a receber (com slippage de 5%)
            const amounts = await this.router.getAmountsOut(amountIn, path);
            const amountOutMin = amounts[1].mul(95).div(100); // 5% slippage

            console.log(`🔄 ${this.name} executando trade:`);
            console.log(`   Input: ${ethers.utils.formatEther(amountIn)} ${await tokenIn.symbol()}`);
            console.log(`   Output esperado: ${ethers.utils.formatEther(amounts[1])} ${await tokenOut.symbol()}`);

            const tx = await this.router.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );

            const receipt = await tx.wait();
            
            // Atualizar estatísticas
            this.stats.totalTrades++;
            this.stats.successfulTrades++;
            this.stats.totalVolume = this.stats.totalVolume.add(amountIn);

            console.log(`✅ Trade executado com sucesso! Gas usado: ${receipt.gasUsed}`);
            
            return true;
        } catch (error) {
            console.error(`❌ Erro no trade do ${this.name}:`, error.message);
            this.stats.failedTrades++;
            return false;
        }
    }

    async start(interval) {
        if (this.isRunning) {
            console.log(`⚠️  ${this.name} já está rodando!`);
            return;
        }

        this.isRunning = true;
        console.log(`🚀 Iniciando ${this.name} com intervalo de ${interval}s`);

        const tradingLoop = async () => {
            if (!this.isRunning) return;

            try {
                await this.executeTradingLogic();
            } catch (error) {
                console.error(`❌ Erro no loop do ${this.name}:`, error.message);
            }

            // Agendar próxima execução
            setTimeout(tradingLoop, interval * 1000);
        };

        // Iniciar o loop
        tradingLoop();
    }

    stop() {
        this.isRunning = false;
        console.log(`🛑 ${this.name} parado!`);
        this.printStats();
    }

    printStats() {
        const runtime = (Date.now() - this.stats.startTime) / 1000 / 60; // minutos
        console.log(`\n📊 Estatísticas do ${this.name}:`);
        console.log(`   Tempo de execução: ${runtime.toFixed(2)} minutos`);
        console.log(`   Total de trades: ${this.stats.totalTrades}`);
        console.log(`   Trades bem-sucedidos: ${this.stats.successfulTrades}`);
        console.log(`   Trades falhados: ${this.stats.failedTrades}`);
        console.log(`   Volume total: ${ethers.utils.formatEther(this.stats.totalVolume)} tokens`);
        console.log(`   Taxa de sucesso: ${((this.stats.successfulTrades / this.stats.totalTrades) * 100).toFixed(2)}%`);
    }
}

// Bot de Compra: BPS → SPB
class BuyBot extends TradingBot {
    constructor(spbToken, bpsToken, router, signer) {
        super("BUY BOT (BPS → SPB)", bpsToken, spbToken, router, signer);
    }

    async executeTradingLogic() {
        const { balanceA: balanceBPS } = await this.checkBalances();
        
        // Verificar se tem saldo suficiente de BPS
        const minBalance = CONFIG.TRADING_AMOUNTS.MIN_TRADE.mul(2);
        if (balanceBPS.lt(minBalance)) {
            console.log(`⚠️  ${this.name}: Saldo insuficiente de BPS para trade`);
            return;
        }

        // Gerar quantidade aleatória para comprar SPB
        const amountBPS = this.generateRandomAmount();
        
        // Executar trade: BPS → SPB
        await this.executeTrade(amountBPS, this.tokenA, this.tokenB);
    }
}

// Bot de Venda: SPB → BPS
class SellBot extends TradingBot {
    constructor(spbToken, bpsToken, router, signer) {
        super("SELL BOT (SPB → BPS)", spbToken, bpsToken, router, signer);
    }

    async executeTradingLogic() {
        const { balanceA: balanceSPB } = await this.checkBalances();
        
        // Verificar se tem saldo suficiente de SPB
        const minBalance = CONFIG.TRADING_AMOUNTS.MIN_TRADE.mul(2);
        if (balanceSPB.lt(minBalance)) {
            console.log(`⚠️  ${this.name}: Saldo insuficiente de SPB para trade`);
            return;
        }

        // Gerar quantidade aleatória para vender SPB
        const amountSPB = this.generateRandomAmount();
        
        // Executar trade: SPB → BPS
        await this.executeTrade(amountSPB, this.tokenA, this.tokenB);
    }
}

// Classe principal para gerenciar os bots
class TradingBotManager {
    constructor() {
        this.bots = [];
        this.isRunning = false;
    }

    async initialize() {
        console.log("🏗️  Inicializando Trading Bot Manager...");
        
        // Conectar com os contratos
        await this.connectContracts();
        
        // Criar carteiras para os bots
        await this.createBotWallets();
        
        // Criar os bots
        await this.createBots();
        
        console.log("✅ Trading Bot Manager inicializado com sucesso!");
    }

    async connectContracts() {
        // Carregar endereços dos contratos deployados
        const deployedContracts = JSON.parse(
            fs.readFileSync(path.join(__dirname, '../deployments/localhost.json'), 'utf8')
        );

        // Conectar com os tokens
        this.spbToken = await ethers.getContractAt("SPBToken", deployedContracts.SPBToken);
        this.bpsToken = await ethers.getContractAt("BPSToken", deployedContracts.BPSToken);
        this.router = await ethers.getContractAt("IUniswapV2Router02", deployedContracts.UniswapV2Router);

        console.log("✅ Contratos conectados:");
        console.log(`   SPB Token: ${this.spbToken.address}`);
        console.log(`   BPS Token: ${this.bpsToken.address}`);
        console.log(`   Router: ${this.router.address}`);
    }

    async createBotWallets() {
        const [owner] = await ethers.getSigners();
        
        // Criar carteiras para os bots
        this.buyBotWallet = ethers.Wallet.createRandom().connect(ethers.provider);
        this.sellBotWallet = ethers.Wallet.createRandom().connect(ethers.provider);

        console.log("👛 Carteiras dos bots criadas:");
        console.log(`   Buy Bot: ${this.buyBotWallet.address}`);
        console.log(`   Sell Bot: ${this.sellBotWallet.address}`);

        // Transferir ETH para gas
        const ethAmount = ethers.utils.parseEther("1.0");
        await owner.sendTransaction({
            to: this.buyBotWallet.address,
            value: ethAmount
        });
        await owner.sendTransaction({
            to: this.sellBotWallet.address,
            value: ethAmount
        });

        // Transferir tokens iniciais
        const initialTokens = ethers.utils.parseEther("50000");
        
        // Buy Bot precisa de BPS
        await this.bpsToken.transfer(this.buyBotWallet.address, initialTokens);
        
        // Sell Bot precisa de SPB
        await this.spbToken.transfer(this.sellBotWallet.address, initialTokens);

        console.log("💰 Tokens iniciais distribuídos para os bots");
    }

    async createBots() {
        // Conectar contratos com as carteiras dos bots
        const spbForBuyBot = this.spbToken.connect(this.buyBotWallet);
        const bpsForBuyBot = this.bpsToken.connect(this.buyBotWallet);
        const routerForBuyBot = this.router.connect(this.buyBotWallet);

        const spbForSellBot = this.spbToken.connect(this.sellBotWallet);
        const bpsForSellBot = this.bpsToken.connect(this.sellBotWallet);
        const routerForSellBot = this.router.connect(this.sellBotWallet);

        // Criar bots
        this.buyBot = new BuyBot(spbForBuyBot, bpsForBuyBot, routerForBuyBot, this.buyBotWallet);
        this.sellBot = new SellBot(spbForSellBot, bpsForSellBot, routerForSellBot, this.sellBotWallet);

        this.bots = [this.buyBot, this.sellBot];

        // Inicializar bots
        await this.buyBot.initialize();
        await this.sellBot.initialize();
    }

    async start() {
        if (this.isRunning) {
            console.log("⚠️  Bots já estão rodando!");
            return;
        }

        this.isRunning = true;
        console.log("🚀 Iniciando todos os bots de trading...");

        // Iniciar bots com intervalos diferentes
        await this.buyBot.start(CONFIG.TRADING_INTERVALS.BUY_BOT);
        await this.sellBot.start(CONFIG.TRADING_INTERVALS.SELL_BOT);

        console.log("✅ Todos os bots estão rodando!");
    }

    stop() {
        this.isRunning = false;
        console.log("🛑 Parando todos os bots...");
        
        this.bots.forEach(bot => bot.stop());
        
        console.log("✅ Todos os bots foram parados!");
    }

    async getStats() {
        console.log("\n📊 RELATÓRIO GERAL DOS BOTS:");
        console.log("================================");
        
        for (const bot of this.bots) {
            bot.printStats();
            console.log("--------------------------------");
        }

        // Estatísticas do pool
        await this.printPoolStats();
    }

    async printPoolStats() {
        try {
            const pairAddress = await this.router.factory.getPair(
                this.spbToken.address, 
                this.bpsToken.address
            );
            
            const pair = await ethers.getContractAt("IUniswapV2Pair", pairAddress);
            const reserves = await pair.getReserves();
            
            console.log("💧 Estatísticas do Pool SPB/BPS:");
            console.log(`   Reserve SPB: ${ethers.utils.formatEther(reserves[0])}`);
            console.log(`   Reserve BPS: ${ethers.utils.formatEther(reserves[1])}`);
            console.log(`   Preço SPB/BPS: ${(reserves[1] / reserves[0]).toFixed(6)}`);
        } catch (error) {
            console.log("⚠️  Não foi possível obter estatísticas do pool");
        }
    }
}

// Script principal
async function main() {
    const manager = new TradingBotManager();
    
    try {
        await manager.initialize();
        
        // Iniciar bots
        await manager.start();
        
        // Executar por 10 minutos (para teste)
        const RUNTIME_MINUTES = 10;
        console.log(`⏰ Executando bots por ${RUNTIME_MINUTES} minutos...`);
        
        setTimeout(async () => {
            manager.stop();
            await manager.getStats();
            process.exit(0);
        }, RUNTIME_MINUTES * 60 * 1000);
        
        // Relatório a cada 2 minutos
        setInterval(async () => {
            if (manager.isRunning) {
                await manager.getStats();
            }
        }, 2 * 60 * 1000);
        
    } catch (error) {
        console.error("❌ Erro fatal:", error);
        process.exit(1);
    }
}

// Exportar classes para uso externo
module.exports = {
    TradingBot,
    BuyBot,
    SellBot,
    TradingBotManager,
    CONFIG
};

// Executar se chamado diretamente
if (require.main === module) {
    main().catch((error) => {
        console.error(error);
        process.exit(1);
    });
}