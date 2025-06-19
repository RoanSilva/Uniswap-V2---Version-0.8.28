/**
 * @file deployAll.js
 * @description Orchestrates the complete deployment of tokens, DEX, pair creation, and liquidity addition.
 * @version 1.0.0
 * @requires hardhat, ethers, fs
 * @author [F-Society]
 * @date 2025-06-17
 */

const { ethers } = require("hardhat");
const fs = require("fs").promises;
const path = require("path");

// Configuration constants
const CONFIG = {
  OUTPUT_DIR: path.join(__dirname, "../../"),
  TOKEN_ADDRESSES_FILE: "token-addresses.json",
  DEX_ADDRESSES_FILE: "dex-addresses.json",
  PAIR_ADDRESSES_FILE: "pair-addresses.json",
  GAS_MULTIPLIER: 1.2,
  REQUIRED_CONFIRMATIONS: 1,
  LIQUIDITY: {
    SPB_AMOUNT: ethers.parseEther("100"),
    BPS_AMOUNT: ethers.parseEther("10"),
    DEADLINE_MINUTES: 20,
  },
};

/**
 * @class FullDeployer
 * @description Manages the complete deployment process for tokens, DEX, pair, and liquidity
 */
class FullDeployer {
  constructor() {
    this.signer = null;
    this.logger = console;
    this.addresses = {
      tokens: {},
      dex: {},
      pair: {},
    };
  }

  /**
   * @description Initializes the deployer with signer information
   * @throws {Error} If signer initialization fails
   */
  async initialize() {
    try {
      [this.signer] = await ethers.getSigners();
      this.logger.log(`Initializing full deployment with account: ${this.signer.address}`);
      this.logger.log(`Deployment timestamp: ${new Date().toISOString()}`);

      const balance = await ethers.provider.getBalance(this.signer.address);
      this.logger.log(`Account balance: ${ethers.formatEther(balance)} ETH`);
      if (balance === 0n) {
        throw new Error("Deployer account has zero balance");
      }

      this.logger.log("Initialization completed successfully");
    } catch (error) {
      throw new Error(`Initialization failed: ${error.message}`);
    }
  }

  /**
   * @description Loads and parses JSON file
   * @param {string} filePath - Path to JSON file
   * @returns {Object} Parsed JSON content
   */
  async loadJson(filePath) {
    try {
      const data = await fs.readFile(filePath, "utf8");
      return JSON.parse(data);
    } catch (error) {
      throw new Error(`Failed to load JSON from ${filePath}: ${error.message}`);
    }
  }

  /**
   * @description Saves addresses to JSON file
   * @param {Object} data - Data to save
   * @param {string} fileName - Output file name
   */
  async saveJson(data, fileName) {
    try {
      data.Deployer = this.signer.address;
      data.Timestamp = new Date().toISOString();
      await fs.writeFile(
        path.join(CONFIG.OUTPUT_DIR, fileName),
        JSON.stringify(data, null, 2),
        "utf8"
      );
      this.logger.log(`Data saved to ${fileName}`);
    } catch (error) {
      throw new Error(`Failed to save ${fileName}: ${error.message}`);
    }
  }

  /**
   * @description Deploys SPBToken and BPSToken
   * @returns {Object} Deployed token instances
   */
  async deployTokens() {
    this.logger.log("\n=== Deploying Tokens ===");
    try {
      const deployToken = async (contractName, tokenSymbol) => {
        this.logger.log(`\nDeploying ${contractName}...`);
        const Token = await ethers.getContractFactory(contractName, this.signer);
        const gasEstimate = await Token.signer.estimateGas(Token.getDeployTransaction());
        const gasLimit = (gasEstimate * BigInt(Math.floor(100 * CONFIG.GAS_MULTIPLIER))) / 100n;
        const token = await Token.deploy({ gasLimit });
        const tx = await token.deploymentTransaction().wait(CONFIG.REQUIRED_CONFIRMATIONS);
        const address = await token.getAddress();
        this.logger.log(`${contractName} deployed at: ${address}`);
        this.logger.log(`Transaction hash: ${tx.transactionHash}`);
        return token;
      };

      const spb = await deployToken("SPBToken", "SPB");
      const bps = await deployToken("BPSToken", "BPS");

      // Verify tokens
      const spbName = await spb.name();
      const bpsName = await bps.name();
      if (!spbName || !bpsName) {
        throw new Error("Token name verification failed");
      }
      this.logger.log(`SPBToken name: ${spbName}`);
      this.logger.log(`BPSToken name: ${bpsName}`);

      this.addresses.tokens = {
        SPBToken: await spb.getAddress(),
        BPSToken: await bps.getAddress(),
      };
      await this.saveJson(this.addresses.tokens, CONFIG.TOKEN_ADDRESSES_FILE);

      return { spb, bps };
    } catch (error) {
      throw new Error(`Token deployment failed: ${error.message}`);
    }
  }

  /**
   * @description Deploys DEX contracts (WETH9, Factory, Router)
   * @returns {Object} Deployed DEX contract instances
   */
  async deployDEX() {
    this.logger.log("\n=== Deploying DEX ===");
    try {
      // Deploy WETH9
      this.logger.log("\nDeploying WETH9...");
      const WETH9 = await ethers.getContractFactory("WETH9", this.signer);
      const wethGasEstimate = await WETH9.signer.estimateGas(WETH9.getDeployTransaction());
      const wethGasLimit = (wethGasEstimate * BigInt(Math.floor(100 * CONFIG.GAS_MULTIPLIER))) / 100n;
      const weth = await WETH9.deploy({ gasLimit: wethGasLimit });
      const wethTx = await weth.deploymentTransaction().wait(CONFIG.REQUIRED_CONFIRMATIONS);
      this.logger.log(`WETH9 deployed at: ${weth.target}`);
      this.logger.log(`Transaction hash: ${wethTx.transactionHash}`);

      // Deploy Factory
      this.logger.log("\nDeploying UniswapV2Factory...");
      const Factory = await ethers.getContractFactory("UniswapV2Factory", this.signer);
      const factoryGasEstimate = await Factory.signer.estimateGas(Factory.getDeployTransaction(this.signer.address));
      const factoryGasLimit = (factoryGasEstimate * BigInt(Math.floor(100 * CONFIG.GAS_MULTIPLIER))) / 100n;
      const factory = await Factory.deploy(this.signer.address, { gasLimit: factoryGasLimit });
      const factoryTx = await factory.deploymentTransaction().wait(CONFIG.REQUIRED_CONFIRMATIONS);
      this.logger.log(`UniswapV2Factory deployed at: ${factory.target}`);
      this.logger.log(`Transaction hash: ${factoryTx.transactionHash}`);

      // Deploy Router
      this.logger.log("\nDeploying UniswapV2Router02...");
      const Router = await ethers.getContractFactory("UniswapV2Router02", this.signer);
      const routerGasEstimate = await Router.signer.estimateGas(Router.getDeployTransaction(factory.target, weth.target));
      const routerGasLimit = (routerGasEstimate * BigInt(Math.floor(100 * CONFIG.GAS_MULTIPLIER))) / 100n;
      const router = await Router.deploy(factory.target, weth.target, { gasLimit: routerGasLimit });
      const routerTx = await router.deploymentTransaction().wait(CONFIG.REQUIRED_CONFIRMATIONS);
      this.logger.log(`UniswapV2Router02 deployed at: ${router.target}`);
      this.logger.log(`Transaction hash: ${routerTx.transactionHash}`);

      // Verify DEX
      const feeSetter = await factory.feeToSetter();
      if (feeSetter.toLowerCase() !== this.signer.address.toLowerCase()) {
        throw new Error("Factory fee setter verification failed");
      }

      this.addresses.dex = {
        WETH9: weth.target,
        UniswapV2Factory: factory.target,
        UniswapV2Router02: router.target,
      };
      await this.saveJson(this.addresses.dex, CONFIG.DEX_ADDRESSES_FILE);

      return { weth, factory, router };
    } catch (error) {
      throw new Error(`DEX deployment failed: ${error.message}`);
    }
  }

  /**
   * @description Creates SPB/BPS trading pair
   * @param {Object} tokens - Deployed token instances
   * @returns {Object} Pair contract instance
   */
  async createPair(tokens) {
    this.logger.log("\n=== Creating Pair ===");
    try {
      const factory = await ethers.getContractAt("UniswapV2Factory", this.addresses.dex.UniswapV2Factory, this.signer);
      const spbAddress = await tokens.spb.getAddress();
      const bpsAddress = await tokens.bps.getAddress();

      // Check if pair exists
      const existingPair = await factory.getPair(spbAddress, bpsAddress);
      if (existingPair !== ethers.ZeroAddress) {
        throw new Error(`Pair already exists at ${existingPair}`);
      }

      // Create pair
      this.logger.log("\nCreating SPB/BPS pair...");
      const gasEstimate = await factory.createPair.estimateGas(spbAddress, bpsAddress);
      const gasLimit = (gasEstimate * BigInt(Math.floor(100 * CONFIG.GAS_MULTIPLIER))) / 100n;
      const tx = await factory.createPair(spbAddress, bpsAddress, { gasLimit });
      const receipt = await tx.wait(CONFIG.REQUIRED_CONFIRMATIONS);

      // Get pair address
      const pairAddress = await factory.getPair(spbAddress, bpsAddress);
      if (pairAddress === ethers.ZeroAddress) {
        throw new Error("Failed to retrieve pair address");
      }

      // Verify pair
      const pair = await ethers.getContractAt("UniswapV2Pair", pairAddress, this.signer);
      const token0 = await pair.token0();
      const token1 = await pair.token1();
      const expectedTokens = [spbAddress.toLowerCase(), bpsAddress.toLowerCase()].sort();
      const actualTokens = [token0.toLowerCase(), token1.toLowerCase()].sort();
      if (expectedTokens[0] !== actualTokens[0] || expectedTokens[1] !== actualTokens[1]) {
        throw new Error("Pair token verification failed");
      }

      this.logger.log(`SPB/BPS pair created at: ${pairAddress}`);
      this.logger.log(`Transaction hash: ${receipt.transactionHash}`);
      this.logger.log(`Pair tokens: ${token0}, ${token1}`);

      this.addresses.pair = { SPB_BPS_Pair: pairAddress };
      await this.saveJson(this.addresses.pair, CONFIG.PAIR_ADDRESSES_FILE);

      return pair;
    } catch (error) {
      throw new Error(`Pair creation failed: ${error.message}`);
    }
  }

  /**
   * @description Adds initial liquidity to SPB/BPS pair
   * @param {Object} tokens - Deployed token instances
   * @param {Object} pair - Deployed pair instance
   * @param {Object} router - Deployed router instance
   */
  async addLiquidity(tokens, pair, router) {
    this.logger.log("\n=== Adding Liquidity ===");
    try {
      const spbAddress = await tokens.spb.getAddress();
      const bpsAddress = await tokens.bps.getAddress();

      // Verify balances
      this.logger.log("\nVerifying token balances...");
      const spbBalance = await tokens.spb.balanceOf(this.signer.address);
      const bpsBalance = await tokens.bps.balanceOf(this.signer.address);
      this.logger.log(`SPB Balance: ${ethers.formatEther(spbBalance)}`);
      this.logger.log(`BPS Balance: ${ethers.formatEther(bpsBalance)}`);
      if (spbBalance < CONFIG.LIQUIDITY.SPB_AMOUNT || bpsBalance < CONFIG.LIQUIDITY.BPS_AMOUNT) {
        throw new Error("Insufficient token balances");
      }

      // Determine token order
      const token0 = await pair.token0();
      const isSPBToken0 = token0.toLowerCase() === spbAddress.toLowerCase();
      const tokenA = isSPBToken0 ? spbAddress : bpsAddress;
      const tokenB = isSPBToken0 ? bpsAddress : spbAddress;
      const amountA = isSPBToken0 ? CONFIG.LIQUIDITY.SPB_AMOUNT : CONFIG.LIQUIDITY.BPS_AMOUNT;
      const amountB = isSPBToken0 ? CONFIG.LIQUIDITY.BPS_AMOUNT : CONFIG.LIQUIDITY.SPB_AMOUNT;
      this.logger.log(`TokenA: ${tokenA}`);
      this.logger.log(`TokenB: ${tokenB}`);

      // Approve tokens
      this.logger.log("\nApproving tokens...");
      const approveGas1 = await tokens.spb.approve.estimateGas(router.target, CONFIG.LIQUIDITY.SPB_AMOUNT);
      const approveGas2 = await tokens.bps.approve.estimateGas(router.target, CONFIG.LIQUIDITY.BPS_AMOUNT);
      await (await tokens.spb.approve(router.target, CONFIG.LIQUIDITY.SPB_AMOUNT, { gasLimit: approveGas1 * BigInt(Math.floor(100 * CONFIG.GAS_MULTIPLIER)) / 100n })).wait(CONFIG.REQUIRED_CONFIRMATIONS);
      await (await tokens.bps.approve(router.target, CONFIG.LIQUIDITY.BPS_AMOUNT, { gasLimit: approveGas2 * BigInt(Math.floor(100 * CONFIG.GAS_MULTIPLIER)) / 100n })).wait(CONFIG.REQUIRED_CONFIRMATIONS);
      this.logger.log("Tokens approved");

      // Add liquidity
      this.logger.log("\nAdding liquidity...");
      const deadline = Math.floor(Date.now() / 1000) + 60 * CONFIG.LIQUIDITY.DEADLINE_MINUTES;
      const gasEstimate = await router.addLiquidity.estimateGas(
        tokenA,
        tokenB,
        amountA,
        amountB,
        0,
        0,
        this.signer.address,
        deadline
      );
      const gasLimit = (gasEstimate * BigInt(Math.floor(100 * CONFIG.GAS_MULTIPLIER))) / 100n;
      const tx = await router.addLiquidity(
        tokenA,
        tokenB,
        amountA,
        amountB,
        0,
        0,
        this.signer.address,
        deadline,
        { gasLimit }
      );
      const receipt = await tx.wait(CONFIG.REQUIRED_CONFIRMATIONS);
      this.logger.log(`Liquidity added! Transaction hash: ${receipt.transactionHash}`);

      // Verify reserves
      this.logger.log("\nVerifying pool reserves...");
      const reserves = await pair.getReserves();
      this.logger.log(`Reserve0: ${ethers.formatEther(reserves[0])}`);
      this.logger.log(`Reserve1: ${ethers.formatEther(reserves[1])}`);
    } catch (error) {
      throw new Error(`Liquidity addition failed: ${error.message}`);
    }
  }

  /**
   * @description Main execution flow
   */
  async execute() {
    try {
      await this.initialize();
      const tokens = await this.deployTokens();
      const dex = await this.deployDEX();
      const pair = await this.createPair(tokens);
      await this.addLiquidity(tokens, pair, dex.router);
      this.logger.log("\n✅ Full deployment completed successfully!");
      return this.addresses;
    } catch (error) {
      this.logger.error(`Full deployment failed: ${error.message}`);
      throw error;
    }
  }
}

/**
 * @description Main entry point for the script
 */
async function main() {
  const deployer = new FullDeployer();
  try {
    const addresses = await deployer.execute();
    console.log("\nDeployment Summary:");
    console.log(JSON.stringify(addresses, null, 2));
    process.exit(0);
  } catch (error) {
    process.exit(1);
  }
}

main();
