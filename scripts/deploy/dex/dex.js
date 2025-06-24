/**
 * @file deployDex.js
 * @description Script para implantação dos contratos WETH9, UniswapV2Factory e UniswapV2Router02.
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
  ADDRESS_FILE: "dex-addresses.json", // Arquivo para endereços dos contratos
  LOG_FILE: "dex-deployment-logs.json", // Arquivo para logs detalhados
  REQUIRED_CONFIRMATIONS: 1, // Número de confirmações para transações
  GAS_SETTINGS: {
    maxPriorityFeePerGas: ethers.parseUnits("2", "gwei"), // Taxa de prioridade
    maxFeePerGas: ethers.parseUnits("50", "gwei") // Taxa máxima de gás
  },
  MINIMUM_BALANCE: ethers.parseEther("0.1"), // Saldo mínimo (0.1 ETH)
  MAX_BYTECODE_SIZE: 24576, // Limite de tamanho do bytecode (24 KB, per EIP-170)
  VALID_CHAIN_IDS: [31337, 80001, 137, 11155111, 1] // hardhat, localhost, mumbai, polygon, sepolia, mainnet
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
 * @notice Verifica se a rede atual é válida para implantação
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
 * @param {ethers.Signer} deployer - Signer da conta que realizará a implantação
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
 * @notice Verifica o tamanho do bytecode do contrato
 * @param {ethers.ContractFactory} factory - Fábrica do contrato
 * @param {string} contractName - Nome do contrato
 * @returns {Promise<boolean>} - Retorna true se o tamanho for válido
 * @throws {Error} - Lança erro se o bytecode exceder o limite
 */
async function validateBytecodeSize(factory, contractName) {
  const bytecode = factory.bytecode;
  const bytecodeSize = (bytecode.length - 2) / 2; // Remove '0x' e divide por 2 (bytes)
  if (bytecodeSize > CONFIG.MAX_BYTECODE_SIZE) {
    throw new Error(
      `Bytecode do contrato ${contractName} excede o limite de ${CONFIG.MAX_BYTECODE_SIZE} bytes. ` +
      `Tamanho atual: ${bytecodeSize} bytes`
    );
  }
  console.log(`✅ Bytecode de ${contractName} validado: ${bytecodeSize} bytes`);
  return true;
}

/**
 * @notice Implanta um contrato e aguarda confirmações
 * @param {string} contractName - Nome do contrato a ser implantado
 * @param {ethers.Signer} deployer - Signer da conta que realizará a implantação
 * @param {Object} [args={}] - Argumentos do construtor do contrato
 * @returns {Promise<Object>} - Objeto com o contrato, endereço e detalhes da transação
 */
async function deployContract(contractName, deployer, args = {}) {
  console.log(`\n📝 Implantando contrato ${contractName}...`);
  const factory = await ethers.getContractFactory(contractName, deployer);
  
  // Valida o tamanho do bytecode
  await validateBytecodeSize(factory, contractName);

  // Implanta o contrato
  const contract = await factory.deploy(...Object.values(args), {
    ...CONFIG.GAS_SETTINGS
  });
  await contract.waitForDeployment();
  
  const address = await contract.getAddress();
  const tx = contract.deploymentTransaction();
  const receipt = await tx.wait(CONFIG.REQUIRED_CONFIRMATIONS);

  console.log(`✅ ${contractName} implantado em: ${address}`);
  console.log(`🔗 Hash da transação: ${tx.hash}`);
  console.log(`📍 Bloco: ${receipt.blockNumber}, Gás usado: ${receipt.gasUsed.toString()}`);

  return { contract, address, txHash: tx.hash, blockNumber: receipt.blockNumber, gasUsed: receipt.gasUsed };
}

/**
 * @notice Salva os endereços dos contratos em um arquivo JSON
 * @param {Object} addressData - Objeto com os endereços dos contratos
 * @param {string} filePath - Caminho do arquivo de saída
 * @returns {Promise<void>}
 */
async function saveAddresses(addressData, filePath) {
  try {
    await fs.mkdir(CONFIG.OUTPUT_DIR, { recursive: true });
    await fs.writeFile(filePath, JSON.stringify(addressData, null, 2));
    console.log(`✅ Endereços salvos em: ${filePath}`);
  } catch (error) {
    throw new Error(`Falha ao salvar endereços: ${error.message}`);
  }
}

/**
 * @notice Salva logs detalhados da implantação em um arquivo JSON
 * @param {Object} logData - Objeto com informações detalhadas da implantação
 * @returns {Promise<void>}
 */
async function saveDeploymentLogs(logData) {
  try {
    const filePath = path.join(CONFIG.OUTPUT_DIR, CONFIG.LOG_FILE);
    await fs.mkdir(CONFIG.OUTPUT_DIR, { recursive: true });
    
    // Carrega logs existentes, se houver
    let existingLogs = [];
    try {
      const existingData = await fs.readFile(filePath, "utf8");
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
 * @notice Função principal para implantação dos contratos da DEX
 * @returns {Promise<void>}
 */
async function main() {
  try {
    // Obtém o deployer e informações da rede
    const [deployer] = await ethers.getSigners();
    const network = await ethers.provider.getNetwork();
    const networkName = hre.network.name || "unknown";

    console.log(`\n🚀 Iniciando implantação da DEX na rede: ${networkName} (chainId: ${network.chainId})`);
    console.log(`👤 Deployer: ${deployer.address}`);

    // Validações iniciais
    await validateEnvVariables(networkName);
    await validateNetwork({ name: networkName, chainId: network.chainId });
    await checkDeployerBalance(deployer);

    // Obtém o saldo inicial do deployer
    const initialBalance = await ethers.provider.getBalance(deployer.address);
    console.log(`💰 Saldo inicial: ${ethers.formatEther(initialBalance)} ETH`);

    // 1. Implanta WETH9
    const wethDeployment = await deployContract("WETH9", deployer);

    // 2. Implanta UniswapV2Factory
    const factoryDeployment = await deployContract("UniswapV2Factory", deployer, {
      feeToSetter: deployer.address
    });

    // 3. Implanta UniswapV2Router02
    const routerDeployment = await deployContract("UniswapV2Router02", deployer, {
      factory: factoryDeployment.address,
      weth: wethDeployment.address
    });

    // Coleta informações detalhadas da rede e dos contratos
    const wethCode = await ethers.provider.getCode(wethDeployment.address);
    const factoryCode = await ethers.provider.getCode(factoryDeployment.address);
    const routerCode = await ethers.provider.getCode(routerDeployment.address);
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
      contracts: {
        WETH9: {
          address: wethDeployment.address,
          txHash: wethDeployment.txHash,
          blockNumber: wethDeployment.blockNumber,
          gasUsed: wethDeployment.gasUsed.toString(),
          bytecodeSize: (wethCode.length - 2) / 2 // Remove '0x' e divide por 2 (bytes)
        },
        UniswapV2Factory: {
          address: factoryDeployment.address,
          txHash: factoryDeployment.txHash,
          blockNumber: factoryDeployment.blockNumber,
          gasUsed: factoryDeployment.gasUsed.toString(),
          bytecodeSize: (factoryCode.length - 2) / 2
        },
        UniswapV2Router02: {
          address: routerDeployment.address,
          txHash: routerDeployment.txHash,
          blockNumber: routerDeployment.blockNumber,
          gasUsed: routerDeployment.gasUsed.toString(),
          bytecodeSize: (routerCode.length - 2) / 2
        }
      }
    };

    // Salva os endereços dos contratos
    const addressData = {
      WETH9: wethDeployment.address,
      UniswapV2Factory: factoryDeployment.address,
      UniswapV2Router02: routerDeployment.address,
      network: networkName,
      chainId: network.chainId.toString(),
      timestamp: new Date().toISOString()
    };
    const addressFilePath = path.join(CONFIG.OUTPUT_DIR, CONFIG.ADDRESS_FILE);
    await saveAddresses(addressData, addressFilePath);

    // Salva os logs detalhados
    await saveDeploymentLogs(logData);

    // Verifica o saldo final do deployer
    const finalBalance = await ethers.provider.getBalance(deployer.address);
    console.log(`💸 Saldo final: ${ethers.formatEther(finalBalance)} ETH`);
    console.log(`📉 ETH gasto: ${ethers.formatEther(initialBalance - finalBalance)} ETH`);

    console.log("\n🎉 Implantação da DEX concluída com sucesso!");
  } catch (error) {
    console.error("❌ Erro durante a implantação:", error.message);
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
