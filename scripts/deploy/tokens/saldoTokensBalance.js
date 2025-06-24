/**
 * @file checkTokenBalances.js
 * @description Script para verificação de saldos dos tokens SPBToken e BPSToken.
 *              Inclui validações robustas, formatação de valores, logs detalhados
 *              e compatibilidade com Solidity 0.8.28. Otimizado para uso com Hardhat e ethers.js v6.
 * @author [Seu Nome ou Nome da Empresa]
 * @version 1.0.0
 * @date 2025-06-22
 */

const { ethers } = require("hardhat");
const fs = require("fs").promises;
const path = require("path");

/**
 * @notice Configurações globais do script
 * @type {Object}
 */
const CONFIG = {
  DEPLOYMENTS_DIR: "./deployments", // Diretório dos arquivos de implantação
  ADDRESS_FILE: "token-addresses.json", // Arquivo com endereços dos contratos
  BALANCE_LOG_FILE: "balance-check-logs.json", // Arquivo para logs de verificação
  DEFAULT_DECIMALS: 18, // Decimais padrão para tokens ERC20
  BATCH_SIZE: 10, // Tamanho do lote para consultas em massa
  RETRY_ATTEMPTS: 3, // Tentativas de reconexão em caso de falha
  RETRY_DELAY: 1000 // Delay entre tentativas (ms)
};

/**
 * @notice Carrega os endereços dos contratos do arquivo de implantação
 * @returns {Promise<Object>} - Objeto com os endereços dos contratos
 * @throws {Error} - Lança erro se o arquivo não for encontrado ou for inválido
 */
async function loadContractAddresses() {
  try {
    const filePath = path.join(CONFIG.DEPLOYMENTS_DIR, CONFIG.ADDRESS_FILE);
    const fileContent = await fs.readFile(filePath, "utf8");
    const addresses = JSON.parse(fileContent);
    
    if (!addresses.SPBToken || !addresses.BPSToken) {
      throw new Error("Endereços dos contratos SPBToken ou BPSToken não encontrados no arquivo");
    }
    
    console.log(`✅ Endereços carregados de: ${filePath}`);
    console.log(`📍 SPBToken: ${addresses.SPBToken}`);
    console.log(`📍 BPSToken: ${addresses.BPSToken}`);
    
    return addresses;
  } catch (error) {
    throw new Error(`Falha ao carregar endereços dos contratos: ${error.message}`);
  }
}

/**
 * @notice Valida se um endereço Ethereum é válido
 * @param {string} address - Endereço a ser validado
 * @returns {boolean} - Retorna true se o endereço for válido
 */
function isValidAddress(address) {
  return ethers.isAddress(address);
}

/**
 * @notice Obtém uma instância do contrato de token
 * @param {string} tokenAddress - Endereço do contrato do token
 * @param {ethers.Signer} signer - Signer para interagir com o contrato
 * @returns {Promise<ethers.Contract>} - Instância do contrato
 */
async function getTokenContract(tokenAddress, signer) {
  // ABI mínima para tokens ERC20
  const tokenABI = [
    "function name() view returns (string)",
    "function symbol() view returns (string)",
    "function decimals() view returns (uint8)",
    "function totalSupply() view returns (uint256)",
    "function balanceOf(address owner) view returns (uint256)",
    "function allowance(address owner, address spender) view returns (uint256)"
  ];
  
  return new ethers.Contract(tokenAddress, tokenABI, signer);
}

/**
 * @notice Obtém informações básicas do token
 * @param {ethers.Contract} tokenContract - Contrato do token
 * @param {string} tokenName - Nome identificador do token (SPB ou BPS)
 * @returns {Promise<Object>} - Informações do token
 */
async function getTokenInfo(tokenContract, tokenName) {
  try {
    const [name, symbol, decimals, totalSupply] = await Promise.all([
      tokenContract.name(),
      tokenContract.symbol(),
      tokenContract.decimals(),
      tokenContract.totalSupply()
    ]);
    
    return {
      name: name,
      symbol: symbol,
      decimals: Number(decimals),
      totalSupply: totalSupply.toString(),
      totalSupplyFormatted: ethers.formatUnits(totalSupply, decimals),
      address: await tokenContract.getAddress()
    };
  } catch (error) {
    throw new Error(`Falha ao obter informações do token ${tokenName}: ${error.message}`);
  }
}

/**
 * @notice Verifica o saldo de um token para um endereço específico
 * @param {ethers.Contract} tokenContract - Contrato do token
 * @param {string} address - Endereço da conta
 * @param {number} decimals - Decimais do token
 * @returns {Promise<Object>} - Saldo em wei e formatado
 */
async function checkTokenBalance(tokenContract, address, decimals) {
  try {
    const balance = await tokenContract.balanceOf(address);
    return {
      raw: balance.toString(),
      formatted: ethers.formatUnits(balance, decimals),
      address: address
    };
  } catch (error) {
    throw new Error(`Falha ao verificar saldo para ${address}: ${error.message}`);
  }
}

/**
 * @notice Verifica saldos de múltiplos endereços para um token
 * @param {ethers.Contract} tokenContract - Contrato do token
 * @param {string[]} addresses - Array de endereços
 * @param {number} decimals - Decimais do token
 * @returns {Promise<Object[]>} - Array com saldos de cada endereço
 */
async function checkMultipleBalances(tokenContract, addresses, decimals) {
  const balances = [];
  
  for (let i = 0; i < addresses.length; i += CONFIG.BATCH_SIZE) {
    const batch = addresses.slice(i, i + CONFIG.BATCH_SIZE);
    const batchPromises = batch.map(address => 
      checkTokenBalance(tokenContract, address, decimals)
    );
    
    try {
      const batchResults = await Promise.all(batchPromises);
      balances.push(...batchResults);
      console.log(`✅ Processado lote ${Math.floor(i / CONFIG.BATCH_SIZE) + 1}/${Math.ceil(addresses.length / CONFIG.BATCH_SIZE)}`);
    } catch (error) {
      console.warn(`⚠️ Erro no lote ${Math.floor(i / CONFIG.BATCH_SIZE) + 1}: ${error.message}`);
    }
  }
  
  return balances;
}

/**
 * @notice Obtém lista de endereços para verificação
 * @returns {Promise<string[]>} - Array de endereços válidos
 */
async function getAddressesToCheck() {
  const [deployer] = await ethers.getSigners();
  const addresses = [deployer.address];
  
  // Adiciona endereços das variáveis de ambiente se estiverem definidas
  if (process.env.CHECK_ADDRESSES) {
    const envAddresses = process.env.CHECK_ADDRESSES.split(",")
      .map(addr => addr.trim())
      .filter(addr => isValidAddress(addr));
    addresses.push(...envAddresses);
  }
  
  // Remove duplicatas
  return [...new Set(addresses)];
}

/**
 * @notice Salva logs da verificação de saldos
 * @param {Object} logData - Dados do log
 * @returns {Promise<void>}
 */
async function saveBalanceCheckLogs(logData) {
  try {
    const filePath = path.join(CONFIG.DEPLOYMENTS_DIR, CONFIG.BALANCE_LOG_FILE);
    await fs.mkdir(CONFIG.DEPLOYMENTS_DIR, { recursive: true });
    
    // Carrega logs existentes
    let existingLogs = [];
    try {
      const existingData = await fs.readFile(filePath, "utf8");
      existingLogs = JSON.parse(existingData);
      if (!Array.isArray(existingLogs)) {
        existingLogs = [];
      }
    } catch (error) {
      // Arquivo não existe, inicia com array vazio
    }
    
    // Adiciona novo log
    existingLogs.push(logData);
    await fs.writeFile(filePath, JSON.stringify(existingLogs, null, 2));
    console.log(`✅ Logs salvos em: ${filePath}`);
  } catch (error) {
    console.warn(`⚠️ Falha ao salvar logs: ${error.message}`);
  }
}

/**
 * @notice Formata e exibe os resultados da verificação
 * @param {Object} tokenInfo - Informações do token
 * @param {Object[]} balances - Array com saldos
 * @param {string} tokenName - Nome do token
 */
function displayResults(tokenInfo, balances, tokenName) {
  console.log(`\n📊 === RESULTADOS ${tokenName} ===`);
  console.log(`🏷️  Nome: ${tokenInfo.name}`);
  console.log(`🔤 Símbolo: ${tokenInfo.symbol}`);
  console.log(`🔢 Decimais: ${tokenInfo.decimals}`);
  console.log(`📈 Supply Total: ${tokenInfo.totalSupplyFormatted} ${tokenInfo.symbol}`);
  console.log(`📍 Endereço: ${tokenInfo.address}`);
  
  console.log(`\n💰 SALDOS:`);
  balances.forEach((balance, index) => {
    const hasBalance = parseFloat(balance.formatted) > 0;
    const icon = hasBalance ? "💵" : "💸";
    console.log(`${icon} ${balance.address}: ${balance.formatted} ${tokenInfo.symbol}`);
  });
  
  // Calcula estatísticas
  const totalBalance = balances.reduce((sum, balance) => {
    return sum + parseFloat(balance.formatted);
  }, 0);
  
  const accountsWithBalance = balances.filter(balance => 
    parseFloat(balance.formatted) > 0
  ).length;
  
  console.log(`\n📈 ESTATÍSTICAS:`);
  console.log(`🔢 Total de contas verificadas: ${balances.length}`);
  console.log(`💰 Contas com saldo: ${accountsWithBalance}`);
  console.log(`📊 Saldo total verificado: ${totalBalance.toFixed(6)} ${tokenInfo.symbol}`);
}

/**
 * @notice Função principal para verificação de saldos
 * @returns {Promise<void>}
 */
async function main() {
  try {
    // Obtém informações da rede
    const network = await ethers.provider.getNetwork();
    const networkName = hre.network.name || "unknown";
    const [signer] = await ethers.getSigners();
    
    console.log(`\n🔍 Iniciando verificação de saldos na rede: ${networkName} (chainId: ${network.chainId})`);
    console.log(`👤 Conta conectada: ${signer.address}`);
    
    // Carrega endereços dos contratos
    const contractAddresses = await loadContractAddresses();
    
    // Obtém endereços para verificação
    const addressesToCheck = await getAddressesToCheck();
    console.log(`📋 Endereços a verificar: ${addressesToCheck.length}`);
    addressesToCheck.forEach((addr, index) => {
      console.log(`   ${index + 1}. ${addr}`);
    });
    
    // Obtém contratos dos tokens
    const spbContract = await getTokenContract(contractAddresses.SPBToken, signer);
    const bpsContract = await getTokenContract(contractAddresses.BPSToken, signer);
    
    // Obtém informações dos tokens
    console.log(`\n📡 Obtendo informações dos tokens...`);
    const [spbInfo, bpsInfo] = await Promise.all([
      getTokenInfo(spbContract, "SPB"),
      getTokenInfo(bpsContract, "BPS")
    ]);
    
    // Verifica saldos
    console.log(`\n🔍 Verificando saldos...`);
    const [spbBalances, bpsBalances] = await Promise.all([
      checkMultipleBalances(spbContract, addressesToCheck, spbInfo.decimals),
      checkMultipleBalances(bpsContract, addressesToCheck, bpsInfo.decimals)
    ]);
    
    // Exibe resultados
    displayResults(spbInfo, spbBalances, "SPBToken");
    displayResults(bpsInfo, bpsBalances, "BPSToken");
    
    // Prepara dados para log
    const logData = {
      timestamp: new Date().toISOString(),
      network: {
        name: networkName,
        chainId: network.chainId.toString()
      },
      signer: signer.address,
      addressesChecked: addressesToCheck.length,
      tokens: {
        SPBToken: {
          ...spbInfo,
          balances: spbBalances,
          totalCheckedBalance: spbBalances.reduce((sum, b) => sum + parseFloat(b.formatted), 0)
        },
        BPSToken: {
          ...bpsInfo,
          balances: bpsBalances,
          totalCheckedBalance: bpsBalances.reduce((sum, b) => sum + parseFloat(b.formatted), 0)
        }
      }
    };
    
    // Salva logs
    await saveBalanceCheckLogs(logData);
    
    console.log(`\n🎉 Verificação de saldos concluída com sucesso!`);
    
  } catch (error) {
    console.error("❌ Erro durante a verificação de saldos:", error.message);
    throw error;
  }
}

// Executa a função principal e lida com erros
main()
  .then(() => {
    console.log("✅ Script de verificação concluído.");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Falha no script:", error);
    process.exit(1);
  });
