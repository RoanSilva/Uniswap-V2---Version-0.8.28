/**
 * @file hardhat.config.js
 * @description Configuração do Hardhat para o projeto de implantação de contratos inteligentes.
 *              Otimizado para Solidity 0.8.28, com suporte a redes locais e de produção,
 *              verificações de segurança e integração com ferramentas modernas.
 * @author [Seu Nome ou Nome da Empresa]
 * @version 1.0.2
 * @date 2025-06-19
 */

require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ignition-ethers");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-deploy");
require("hardhat-contract-sizer");
require("hardhat-abi-exporter");
require("hardhat-tracer");
require("hardhat-storage-layout");
require("dotenv").config();

/**
 * @notice Valida as variáveis de ambiente necessárias para redes de produção
 * @returns {boolean} - Retorna true se todas as variáveis necessárias estiverem definidas
 * @throws {Error} - Lança erro se alguma variável obrigatória estiver ausente
 */
function validateEnvVariables() {
  const requiredEnvVars = [
    { name: "PRIVATE_KEY", networks: ["mumbai", "polygon", "sepolia", "mainnet"] },
    { name: "POLYGONSCAN_API_KEY", networks: ["mumbai", "polygon"] },
    { name: "ETHERSCAN_API_KEY", networks: ["sepolia", "mainnet"] }
  ];

  for (const envVar of requiredEnvVars) {
    if (!process.env[envVar.name] && envVar.networks.includes(process.env.HARDHAT_NETWORK)) {
      throw new Error(`Erro: Variável de ambiente ${envVar.name} não definida para a rede ${process.env.HARDHAT_NETWORK}`);
    }
  }
  return true;
}

// Valida variáveis de ambiente ao carregar o arquivo
validateEnvVariables();

module.exports = {
  /**
   * @notice Configuração do compilador Solidity
   */
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true, // Ativa o otimizador para reduzir custos de gás
        runs: 200, // Balanceia de tamanho de código e custo de gás
        details: {
          yul: true, // Usa Yul como intermediário para otimizações avançadas
          yulDetails: {
            stackAllocation: true, // Otimização de alocação de pilha
            optimizerSteps: "dhfoDsv" // Sequência personalizada de otimização
          }
        }
      },
      viaIR: true, // Usa pipeline IR para melhor otimização
      evmVersion: "cancun", // Compatível com a EVM Cancun
      outputSelection: {
        "*": {
          "*": ["abi", "evm.bytecode", "evm.deployedBytecode", "storageLayout"],
          "": ["ast"] // Inclui árvore sintática abstrata
        }
      },
      metadata: {
        appendCBOR: true, // Adiciona metadados CBOR
        useLiteralContent: true // Usa conteúdo literal para metadados
      }
    }
  },

  /**
   * @notice Configuração das redes suportadas
   */
  networks: {
    hardhat: {
      chainId: 31337,
      blockGasLimit: 30000000, // Limite de gás por bloco
      allowUnlimitedContractSize: false, // Restringe tamanho do contrato
      mining: {
        auto: true, // Mineração automática para desenvolvimento
        interval: 0 // Mineração sob demanda
      },
      accounts: {
        mnemonic: process.env.MNEMONIC || "test test test test test test test test test test test junk",
        count: 20, // Número de contas geradas
        initialIndex: 0,
        path: "m/44'/60'/0'/0", // Caminho de derivação HD
        accountsBalance: "10000000000000000000000" // Saldo inicial: 10k ETH
      },
      forking: process.env.FORK_MAINNET === "true" ? {
        url: process.env.MAINNET_RPC_URL || "https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY",
        blockNumber: process.env.FORK_BLOCK_NUMBER ? parseInt(process.env.FORK_BLOCK_NUMBER) : undefined
      } : undefined
    },
    localhost: {
      name: "localhost", // Nome explícito para evitar problemas de identificação
      url: "http://127.0.0.1:8545",
      chainId: 31337,
      accounts: {
        mnemonic: process.env.MNEMONIC || "test test test test test test test test test test test junk",
        count: 20,
        initialIndex: 0,
        path: "m/44'/60'/0'/0",
        accountsBalance: "10000000000000000000000" // Saldo inicial: 10k ETH
      },
      gas: 5000000 // Limite de gás por transação
    },
    mumbai: {
      url: process.env.MUMBAI_RPC_URL || "https://rpc-mumbai.maticvigil.com",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 80001,
      gasPrice: "auto", // Usa preço de gás dinâmico
      gasMultiplier: 1.2, // Aumenta estimativa de gás em 20%
      timeout: 60000, // Timeout de 60 segundos
      confirmations: 2 // Aguarda 2 confirmações
    },
    polygon: {
      url: process.env.POLYGON_RPC_URL || "https://polygon-rpc.com",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 137,
      gasPrice: "auto", // Usa preço de gás dinâmico
      gasMultiplier: 1.5, // Aumenta estimativa de gás em 50%
      timeout: 120000, // Timeout de 120 segundos
      confirmations: 3 // Aguarda 3 confirmações
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "https://rpc.sepolia.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11155111,
      gasPrice: "auto", // Usa preço de gás dinâmico
      timeout: 180000, // Timeout de 180 segundos
      confirmations: 2 // Aguarda 2 confirmações
    },
    mainnet: {
      url: process.env.MAINNET_RPC_URL || "https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 1,
      gasPrice: "auto", // Usa preço de gás dinâmico
      timeout: 300000, // Timeout de 300 segundos
      confirmations: 5 // Aguarda 5 confirmações
    }
  },

  /**
   * @notice Configuração para verificação de contratos em exploradores de blockchain
   */
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.POLYGONSCAN_API_KEY || "",
      polygon: process.env.POLYGONSCAN_API_KEY || "",
      sepolia: process.env.ETHERSCAN_API_KEY || "",
      mainnet: process.env.ETHERSCAN_API_KEY || ""
    },
    customChains: [
      {
        network: "mumbai",
        chainId: 80001,
        urls: {
          apiURL: "https://api-mumbai.polygonscan.com/api",
          browserURL: "https://mumbai.polygonscan.com"
        }
      },
      {
        network: "polygon",
        chainId: 137,
        urls: {
          apiURL: "https://api.polygonscan.com/api",
          browserURL: "https://polygonscan.com"
        }
      }
    ]
  },

  /**
   * @notice Configuração do relatório de consumo de gás
   */
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    currency: "USD",
    outputFile: "./reports/gas-report.txt",
    noColors: true,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY || "",
    token: "MATIC", // Token padrão para redes como Polygon
    gasPriceApi: "https://api.polygonscan.com/api?module=proxy&action=eth_gasPrice",
    reportFormat: "markdown",
    showTimeSpent: true,
    excludeContracts: ["TestContract"],
    src: "./contracts"
  },

  /**
   * @notice Configuração do framework de testes Mocha
   */
  mocha: {
    timeout: 100000, // Timeout de 100 segundos para testes
    bail: false, // Continua execução mesmo após falhas
    reporter: "spec", // Formato de relatório de testes
    slow: 1000 // Marca testes lentos acima de 1 segundo
  },

  /**
   * @notice Configuração de caminhos do projeto
   */
  paths: {
    sources: "./contracts", // Diretório dos contratos
    tests: "./test", // Diretório dos testes
    cache: "./cache", // Diretório de cache
    artifacts: "./artifacts", // Diretório de artefatos compilados
    deployments: "./deployments", // Diretório de implantações
    imports: "./imports" // Diretório para imports personalizados
  },

  /**
   * @notice Configuração do plugin Hardhat Deploy
   */
  namedAccounts: {
    deployer: {
      default: 0, // Primeira conta como deployer
      137: process.env.DEPLOYER_ADDRESS || "0xYourDeployerAddress", // Endereço para Polygon
      80001: process.env.DEPLOYER_ADDRESS || "0xYourDeployerAddress" // Endereço para Mumbai
    },
    user: {
      default: 1 // Segunda conta como usuário
    }
  },

  /**
   * @notice Configuração do plugin Hardhat Contract Sizer
   */
  contractSizer: {
    alphaSort: true, // Ordena contratos alfabeticamente
    runOnCompile: false, // Executa apenas manualmente
    disambiguatePaths: false, // Evita caminhos ambíguos
    strict: true, // Falha se tamanho exceder limite
    except: ["Test"] // Exclui contratos com "Test" no nome
  },

  /**
   * @notice Configuração do plugin Hardhat ABI Exporter
   */
  abiExporter: {
    path: "./abis", // Diretório para exportar ABIs
    runOnCompile: true, // Exporta automaticamente ao compilar
    clear: true, // Limpa diretório antes de exportar
    flat: false, // Usa estrutura hierárquica
    except: ["Test"], // Exclui contratos de teste
    spacing: 2, // Espaçamento JSON
    pretty: true, // Formata ABIs de forma legível
    rename: (sourceName, contractName) => {
      return `${sourceName.replace(/[\/\\]/g, '_').replace('.sol', '')}_${contractName}`;
    }
  },

  /**
   * @notice Configuração do plugin Hardhat Tracer
   */
  tracer: {
    enabled: true, // Ativa rastreamento de transações
    gasCost: true, // Mostra custo de gás
    showAddresses: true, // Exibe endereços
    decodeLogs: true // Decodifica logs
  },

  /**
   * @notice Configuração do plugin Hardhat Storage Layout
   */
  storageLayout: {
    contracts: [], // Contratos específicos para layout de armazenamento
    full: true // Inclui layout completo
  },

  /**
   * @notice Configuração do plugin Hardhat Ignition
   */
  ignition: {
    strategy: "basic", // Estratégia de implantação
    maxFeePerGas: 1000000000, // 1 gwei em wei
    maxPriorityFeePerGas: 1000000000, // 1 gwei em wei
    blockConfirmations: 2, // Confirmações para implantação
    moduleDir: "./ignition/modules" // Diretório dos módulos Ignition
  },

  /**
   * @notice Configuração do plugin TypeChain
   */
  typechain: {
    outDir: "typechain-types", // Diretório de saída
    target: "ethers-v6", // Alvo para geração de tipos
    alwaysGenerateOverloads: true, // Gera sobrecargas
    discriminateTypes: true, // Discrimina tipos
    tsNocheck: false // Evita adicionar @ts-nocheck
  },

  /**
   * @notice Configuração de dependências externas
   */
  external: {
    contracts: [
      {
        artifacts: "node_modules/@openzeppelin/contracts/build/contracts" // Artefatos da OpenZeppelin
      }
    ],
    deployments: {} // Removido referência a pacotes inexistentes
  },

  /**
   * @notice Configuração do plugin Hardhat Docgen
   */
  docgen: {
    path: "./docs", // Diretório de saída
    clear: true, // Limpa antes de gerar
    runOnCompile: false, // Gera apenas manualmente
    except: ["Test"] // Exclui contratos de teste
  }
};
