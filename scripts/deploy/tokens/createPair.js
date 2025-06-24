/**
 * @file createPair.js
 * @description Script para criação do par SPB/BPS usando UniswapV2Factory.
 *              Inclui verificações de segurança robustas, salvamento de endereços, logs detalhados
 *              e compatibilidade com Solidity 0.8.28. Otimizado para uso com Hardhat e ethers.js v6.
 * @author [Seu Nome ou Nome da Empresa]
 * @version 1.0.0
 * @date 2025-06-19
 */

const { ethers } = require("hardhat");
const fs = require("fs").promises;
const path = require("path");

/**
 * @notice Configurações globais do script
 * @type {Object}
 */
const CONFIG = {
  OUTPUT_DIR: "./deployments", // Diretório para salvar arquivos de saída
  ADDRESS_FILE: "pair-addresses.json", // Arquivo para endereços do par
  LOG_FILE: "pair-deployment-logs.json", // Arquivo para logs detalhados
  REQUIRED_CONFIRMATIONS: 1, // Número de confirmações para transações
  GAS_SETTINGS: {
    maxPriorityFeePerGas: ethers.parseUnits("2", "gwei"), // Taxa de prioridade
    maxFeePerGas: ethers.parseUnits("50", "gwei") // Taxa máxima de gás
  },
  MINIMUM_BALANCE: ethers.parseEther("0.1"), // Saldo mínimo (0.1 ETH)
  VALID_CHAIN_IDS: [31337, 80001, 137, 11155111, 1], // hardhat, localhost, mumbai, polygon, sepolia, mainnet
  DEX_ADDRESSES_FILE: "deployments/dex-addresses.json", // Arquivo com endereços da DEX
  TOKEN_ADDRESSES_FILE: "deployments/token-addresses.json" // Arquivo com endereços dos tokens
};

/**
 * @notice Valida as variáveis de ambiente necessárias para redes de produção
 * @param {string} networkName - Nome da rede atual
 * @returns {Promise<boolean>} - Retorna true se todas as variáveis estiverem definidas
 * @throws {Error} - Lança erro se alguma variável obrigatória estiver ausente
 */
async function validateEnvVariables(networkName) {
  const productionNetworks = ["mumbai", "polygon", "sepolia", "mainnet"];
  if (productionNetworks.includes(networkName)) {
    if (!process.env.PRIVATE_KEY) {
      throw new Error(`Erro: Variável de ambiente PRIVATE_KEY não definida para a rede ${networkName}`);
    }
  }
  return true;
}

/**
 * @notice Verifica se a rede atual é válida para criação do par
 * @param {Object} network - Objeto de configuração da rede
 * @returns {Promise<boolean>} - Retorna true se a rede for válida
 * @throws {Error} - Lança erro se a rede for inválida
 */
async function validateNetwork(network) {
  const chainId = Number(network.chainId);
  if (!CONFIG.VALID_CHAIN_IDS.includes(chainId)) {
    throw new Error(
      `Rede inválida: ${network.name || "unknown"} (chainId: ${chainId}). ` +
      `ChainIds permitidos: ${CONFIG.VALID_CHAIN_IDS.join(", ")}`
    );
  }
  console.log(`✅ Rede validada: ${network.name || "unknown"} (chainId: ${chainId})`);
  return true;
}

/**
 * @notice Verifica se a conta do deployer tem saldo suficiente
 * @param {ethers.Signer} deployer - Signer da conta que realizará a transação
 * @returns {Promise<boolean>} - Retorna true se o saldo for suficiente
 * @throws {Error} - Lança erro se o saldo for insuficiente
 */
async function checkDeployerBalance(deployer) {
  const balance = await ethers.provider.getBalance(deployer.address);
  if (balance < CONFIG.MINIMUM_BALANCE) {
    throw new Error(
      `Saldo insuficiente para deployer ${deployer.address}. ` +
      `Saldo atual: ${ethers.formatEther(balance)} ETH, ` +
      `Saldo mínimo necessário: ${ethers.formatEther(CONFIG.MINIMUM_BALANCE)} ETH`
    );
  }
  return true;
}

/**
 * @notice Valida os endereços dos contratos necessários
 * @param {Object} dexAddresses - Endereços da DEX
 * @param {Object} tokenAddresses - Endereços dos tokens
 * @returns {boolean} - Retorna true se os endereços forem válidos
 * @throws {Error} - Lança erro se algum endereço estiver ausente ou inválido
 */
function validateContractAddresses(dexAddresses, tokenAddresses) {
  if (!dexAddresses.UniswapV2Factory || !ethers.isAddress(dexAddresses.UniswapV2Factory)) {
    throw new Error("Endereço UniswapV2Factory inválido ou ausente em dex-addresses.json");
  }
  if (!tokenAddresses.SPBToken || !ethers.isAddress(tokenAddresses.SPBToken)) {
    throw new Error("Endereço SPBToken inválido ou ausente em token-addresses.json");
  }
  if (!tokenAddresses.BPSToken || !ethers.isAddress(tokenAddresses.BPSToken)) {
    throw new Error("Endereço BPSToken inválido ou ausente em token-addresses.json");
  }
  return true;
}

/**
 * @notice Cria o par de tokens usando a UniswapV2Factory
 * @param {ethers.Contract} factory - Instância do contrato UniswapV2Factory
 * @param {string} tokenA - Endereço do primeiro token
 * @param {string} tokenB - Endereço do segundo token
 * @param {ethers.Signer} deployer - Signer da conta que realizará a transação
 * @returns {Promise<Object>} - Objeto com endereço do par, hash da transação e detalhes
 */
async function createPair(factory, tokenA, tokenB, deployer) {
  console.log(`\n📝 Criando par ${tokenA}/${tokenB}...`);

  // Verifica se o par já existe
  const pairAddress = await factory.getPair(tokenA, tokenB);
  if (pairAddress !== ethers.ZeroAddress) {
    console.log(`⚠️ Par ${tokenA}/${tokenB} já existe em: ${pairAddress}`);
    return { pairAddress, txHash: null, gasUsed: "0", blockNumber: null };
  }

  // Cria o par
  const tx = await factory.connect(deployer).createPair(tokenA, tokenB, CONFIG.GAS_SETTINGS);
  const receipt = await tx.wait(CONFIG.REQUIRED_CONFIRMATIONS);

  // Obtém o endereço do par criado
  const newPairAddress = await factory.getPair(tokenA, tokenB);

  console.log(`✅ Par criado em: ${newPairAddress}`);
  console.log(`🔗 Hash da transação: ${tx.hash}`);
  console.log(`📍 Bloco: ${receipt.blockNumber}, Gás usado: ${receipt.gasUsed.toString()}`);

  return { pairAddress: newPairAddress, txHash: tx.hash, gasUsed: receipt.gasUsed, blockNumber: receipt.blockNumber };
}

/**
 * @notice Salva os endereços do par em um arquivo JSON
 * @param {Object} pairData - Objeto com os endereços do par
 * @param {string} filePath - Caminho do arquivo de saída
 * @returns {Promise<void>}
 */
async function savePairAddresses(pairData, filePath) {
  try {
    await fs.mkdir(CONFIG.OUTPUT_DIR, { recursive: true });
    await fs.writeFile(filePath, JSON.stringify(pairData, null, 2));
    console.log(`✅ Endereços salvos em: ${filePath}`);
  } catch (error) {
    throw new Error(`Falha ao salvar endereços: ${error.message}`);
  }
}

/**
 * @notice Salva logs detalhados da criação do par em um arquivo JSON
 * @param {Object} logData - Objeto com informações detalhadas da criação
 * @returns {Promise<void>}
 */
async function saveDeploymentLogs(logData) {
  try {
    const filePath = path.join(CONFIG.OUTPUT_DIR, CONFIG.LOG_FILE);
    await fs.mkdir(CONFIG.OUTPUT_DIR, { recursive: true });
    
    // Carrega logs existentes, se houver
    let existingLogs = [];
    try {
      const existingData = await fs.readFile(filePath);
      existingLogs = JSON.parse(existingData);
      if (!Array.isArray(existingLogs)) {
        existingLogs = [];
      }
    } catch (error) {
      // Arquivo não existe ou está vazio, inicia com array vazio
    }

    // Adiciona novo log
    existingLogs.push(logData);
    await fs.writeFile(filePath, JSON.stringify(existingLogs, null, 2));
    console.log(`✅ Logs salvos em: ${filePath}`);
  } catch (error) {
    throw new Error(`Falha ao salvar logs: ${error.message}`);
  }
}

/**
 * @notice Função principal para criação do par SPB/BPS
 * @returns {Promise<void>}
 */
async function main() {
  try {
    // Obtém o deployer e informações da rede
    const [deployer] = await ethers.getSigners();
    const network = await ethers.provider.getNetwork();
    const networkName = hre.network.name || "unknown";

    console.log(`\n🚀 Iniciando criação do par SPB/BPS na rede: ${networkName} (chainId: ${network.chainId})`);
    console.log(`👤 Deployer: ${deployer.address}`);

    // Validações iniciais
    await validateEnvVariables(networkName);
    await validateNetwork({ name: networkName, chainId: network.chainId });
    await checkDeployerBalance(deployer);

    // Obtém o saldo inicial do deployer
    const initialBalance = await ethers.provider.getBalance(deployer.address);
    console.log(`💰 Saldo inicial: ${ethers.formatEther(initialBalance)} ETH`);

    // Carrega endereços
    let dexAddresses, tokenAddresses;
    try {
      dexAddresses = JSON.parse(await fs.readFile(CONFIG.DEX_ADDRESSES_FILE));
      tokenAddresses = JSON.parse(await fs.readFile(CONFIG.TOKEN_ADDRESSES_FILE));
    } catch (error) {
      throw new Error(`Falha ao carregar arquivos de endereços: ${error.message}`);
    }

    // Valida endereços
    validateContractAddresses(dexAddresses, tokenAddresses);

    // Conecta à UniswapV2Factory
    const factory = await ethers.getContractAt("UniswapV2Factory", dexAddresses.UniswapV2Factory, deployer);

    // Cria o par SPB/BPS
    const pairResult = await createPair(factory, tokenAddresses.SPBToken, tokenAddresses.BPSToken, deployer);

    // Coleta informações detalhadas da rede
    const pairCode = await ethers.provider.getCode(pairResult.pairAddress);
    const block = await ethers.provider.getBlock("latest");

    const logData = {
      timestamp: new Date().toISOString(),
      network: {
        name: networkName,
        chainId: network.chainId.toString(),
        blockNumber: block.number,
        blockTimestamp: block.timestamp,
        gasLimit: block.gasLimit.toString()
      },
      deployer: {
        address: deployer.address,
        initialBalance: initialBalance.toString(),
        finalBalance: (await ethers.provider.getBalance(deployer.address)).toString()
      },
      pair: {
        tokens: {
          tokenA: tokenAddresses.SPBToken,
          tokenB: tokenAddresses.BPSToken
        },
        address: pairResult.pairAddress,
        txHash: pairResult.txHash,
        blockNumber: pairResult.blockNumber,
        gasUsed: pairResult.gasUsed.toString(),
        bytecodeSize: (pairCode.length - 2) / 2 // Remove '0x' e divide por 2 (bytes)
      }
    };

    // Salva os endereços do par
    const pairData = {
      SPB_BPS_Pair: pairResult.pairAddress,
      network: networkName,
      chainId: network.chainId.toString(),
      timestamp: new Date().toISOString()
    };
    const addressFilePath = path.join(CONFIG.OUTPUT_DIR, CONFIG.ADDRESS_FILE);
    await savePairAddresses(pairData, addressFilePath);

    // Salva os logs detalhados
    await saveDeploymentLogs(logData);

    // Verifica o saldo final do deployer
    const finalBalance = await ethers.provider.getBalance(deployer.address);
    console.log(`💸 Saldo final: ${ethers.formatEther(finalBalance)} ETH`);
    console.log(`📉 ETH gasto: ${ethers.formatEther(initialBalance - finalBalance)} ETH`);

    console.log("\n🎉 Criação do par SPB/BPS concluída com sucesso!");
  } catch (error) {
    console.error("❌ Erro durante a criação do par:", error.message);
    throw error;
  }
}

// Executa a função principal e lida com erros
main()
  .then(() => {
    console.log("✅ Script concluído.");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Falha no script:", error);
    process.exit(1);
  });
