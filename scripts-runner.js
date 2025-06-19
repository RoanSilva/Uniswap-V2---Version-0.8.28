//# (opcional) Menu CLI interativo p/ rodar scripts
//# DEBUGGINN

#!/usr/bin/env node

const { execSync } = require('child_process');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function showMenu() {
  console.log('\n🏦 ===== SOCIETY TOKEN PROJECT MANAGER =====');
  console.log('');
  console.log('📋 OPÇÕES DISPONÍVEIS:');
  console.log('');
  console.log('1️⃣  Compilar contratos');
  console.log('2️⃣  Executar testes');
  console.log('3️⃣  Iniciar node local');
  console.log('4️⃣  Deploy em rede local');
  console.log('5️⃣  Deploy em testnet');
  console.log('6️⃣  Limpar artifacts');
  console.log('7️⃣  Relatório de cobertura');
  console.log('8️⃣  Relatório de gas');
  console.log('9️⃣  Verificar contratos');
  console.log('🔟  Console do Hardhat');
  console.log('');
  console.log('0️⃣  Sair');
  console.log('');
  console.log('===============================================');
}

function executeCommand(command, description) {
  console.log(`\n🚀 ${description}...\n`);
  try {
    execSync(command, { stdio: 'inherit' });
    console.log(`\n✅ ${description} concluído com sucesso!\n`);
  } catch (error) {
    console.log(`\n❌ Erro ao executar ${description}:`);
    console.log(error.message);
  }
}

function handleChoice(choice) {
  switch(choice) {
    case '1':
      executeCommand('npx hardhat compile', 'Compilação dos contratos');
      break;
    
    case '2':
      executeCommand('npx hardhat test', 'Execução dos testes');
      break;
    
    case '3':
      console.log('\n🌐 Iniciando node local do Hardhat...');
      console.log('💡 Mantenha este terminal aberto e use outro terminal para deploy');
      console.log('🔗 RPC URL: http://127.0.0.1:8545');
      console.log('🆔 Chain ID: 31337\n');
      executeCommand('npx hardhat node', 'Node local');
      break;
    
    case '4':
      executeCommand('npx hardhat run scripts/deploy/deployTokens.js --network localhost', 'Deploy em rede local');
      break;
    
    case '5':
      console.log('\n⚠️  Certifique-se de que o arquivo .env está configurado corretamente!');
      rl.question('Continuar com deploy em testnet? (y/N): ', (answer) => {
        if (answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes') {
          executeCommand('npx hardhat run scripts/deploy/deployTokens.js --network bscTestnet', 'Deploy em BSC Testnet');
        } else {
          console.log('❌ Deploy cancelado');
        }
        showMenuAndWait();
      });
      return;
    
    case '6':
      executeCommand('npx hardhat clean', 'Limpeza de artifacts');
      break;
    
    case '7':
      executeCommand('npx hardhat coverage', 'Relatório de cobertura');
      break;
    
    case '8':
      executeCommand('REPORT_GAS=true npx hardhat test', 'Relatório de gas');
      break;
    
    case '9':
      console.log('\n📝 Para verificar contratos, use:');
      console.log('npx hardhat verify --network <network> <contract-address> <constructor-args>');
      console.log('\nExemplo:');
      console.log('npx hardhat verify --network bscTestnet 0x... "SOCIETY PROJECT BANK" "SPB" 1000000 "0x..."');
      break;
    
    case '10':
      executeCommand('npx hardhat console', 'Console do Hardhat');
      break;
    
    case '0':
      console.log('\n👋 Encerrando Society Token Project Manager...');
      console.log('🚀 Obrigado por usar nosso sistema!\n');
      rl.close();
      return;
    
    default:
      console.log('\n❌ Opção inválida! Tente novamente.');
  }
  
  showMenuAndWait();
}

function showMenuAndWait() {
  showMenu();
  rl.question('🎯 Escolha uma opção: ', handleChoice);
}

function showProjectStatus() {
  console.log('\n🏦 SOCIETY TOKEN PROJECT');
  console.log('========================');
  console.log('📁 Projeto: Society Project Bank & Bank Project Society');
  console.log('🪙 Tokens: SPB & BPS');
  console.log('⚡ Funcionalidades: Tax (1%), Mintable, Burnable, Pausable');
  console.log('🔧 Framework: Hardhat + OpenZeppelin');
  console.log('📊 Status: ETAPA 1 Concluída - Tokens Implementados');
  console.log('🎯 Próximo: ETAPA 2 - Pool de Liquidez SPB/BPS');
  console.log('========================');
}

// Função para mostrar informações úteis
function showHelp() {
  console.log('\n📚 INFORMAÇÕES ÚTEIS:');
  console.log('');
  console.log('🔧 COMANDOS MANUAIS:');
  console.log('  npx hardhat compile          - Compilar contratos');
  console.log('  npx hardhat test             - Executar testes');
  console.log('  npx hardhat node             - Iniciar node local');
  console.log('  npx hardhat console          - Console interativo');
  console.log('  npx hardhat clean            - Limpar artifacts');
  console.log('');
  console.log('🌐 REDES CONFIGURADAS:');
  console.log('  localhost  - Rede local (Chain ID: 31337)');
  console.log('  bscTestnet - BSC Testnet (Chain ID: 97)');
  console.log('  sepolia    - Ethereum Sepolia Testnet');
  console.log('');
  console.log('📋 ESTRUTURA DOS TOKENS:');
  console.log('  SPB - SOCIETY PROJECT BANK');
  console.log('  BPS - BANK PROJECT SOCIETY');
  console.log('  Supply: 1.000.000 cada');
  console.log('  Taxa: 1% por transação');
  console.log('');
  console.log('🔐 SEGURANÇA:');
  console.log('  - Nunca compartilhe sua PRIVATE_KEY');
  console.log('  - Use sempre testnets para desenvolvimento');
  console.log('  - Mantenha o arquivo .env em .gitignore');
  console.log('');
}

// Inicialização
console.clear();
showProjectStatus();

// Verificar se há argumentos de linha de comando
const args = process.argv.slice(2);
if (args.includes('--help') || args.includes('-h')) {
  showHelp();
  process.exit(0);
}

// Iniciar menu interativo
showMenuAndWait();

// Manipular saída do programa
process.on('SIGINT', () => {
  console.log('\n\n👋 Encerrando Society Token Project Manager...');
  console.log('🚀 Obrigado por usar nosso sistema!\n');
  rl.close();
  process.exit(0);
});
