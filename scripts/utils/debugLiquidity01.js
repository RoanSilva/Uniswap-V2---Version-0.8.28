const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  // Carregar endereços
  const dexAddresses = require('../../dex-addresses.json');
  const tokenAddresses = require('../../token-addresses.json');
  
  // Conectar aos contratos
  const router = await ethers.getContractAt("UniswapV2Router02", dexAddresses.UniswapV2Router02);
  const factory = await ethers.getContractAt("UniswapV2Factory", dexAddresses.UniswapV2Factory);
  const spbToken = await ethers.getContractAt("SPBToken", tokenAddresses.SPBToken);
  const bpsToken = await ethers.getContractAt("BPSToken", tokenAddresses.BPSToken);
  
  console.log("=== DIAGNÓSTICO COMPLETO ===\n");
  
  // 1. Verificar contratos
  console.log("1. Verificando contratos...");
  try {
    const routerFactory = await router.factory();
    const routerWETH = await router.WETH();
    console.log("✅ Router OK - Factory:", routerFactory, "WETH:", routerWETH);
  } catch (e) {
    console.log("❌ Router com problema:", e.message);
  }
  
  try {
    const spbName = await spbToken.name();
    const spbSymbol = await spbToken.symbol();
    console.log(`✅ SPB Token OK - ${spbName} (${spbSymbol})`);
  } catch (e) {
    console.log("❌ SPB Token com problema:", e.message);
  }
  
  try {
    const bpsName = await bpsToken.name();
    const bpsSymbol = await bpsToken.symbol();
    console.log(`✅ BPS Token OK - ${bpsName} (${bpsSymbol})`);
  } catch (e) {
    console.log("❌ BPS Token com problema:", e.message);
  }
  
  // 2. Verificar saldos
  console.log("\n2. Verificando saldos...");
  const spbBalance = await spbToken.balanceOf(deployer.address);
  const bpsBalance = await bpsToken.balanceOf(deployer.address);
  console.log("SPB Balance:", ethers.formatEther(spbBalance));
  console.log("BPS Balance:", ethers.formatEther(bpsBalance));
  
  // 3. Verificar allowances
  console.log("\n3. Verificando allowances...");
  const spbAllowance = await spbToken.allowance(deployer.address, router.target);
  const bpsAllowance = await bpsToken.allowance(deployer.address, router.target);
  console.log("SPB Allowance:", ethers.formatEther(spbAllowance));
  console.log("BPS Allowance:", ethers.formatEther(bpsAllowance));
  
  // 4. Verificar par
  console.log("\n4. Verificando par...");
  const pairAddress = await factory.getPair(spbToken.target, bpsToken.target);
  console.log("Pair Address:", pairAddress);
  
  if (pairAddress !== ethers.ZeroAddress) {
    const pair = await ethers.getContractAt("UniswapV2Pair", pairAddress);
    const reserves = await pair.getReserves();
    const token0 = await pair.token0();
    const token1 = await pair.token1();
    console.log("Token0:", token0);
    console.log("Token1:", token1);
    console.log("Reserve0:", ethers.formatEther(reserves._reserve0));
    console.log("Reserve1:", ethers.formatEther(reserves._reserve1));
  }
  
  // 5. Verificar se os tokens têm funções necessárias
  console.log("\n5. Verificando funções dos tokens...");
  try {
    const spbDecimals = await spbToken.decimals();
    const bpsDecimals = await bpsToken.decimals();
    console.log("SPB Decimals:", spbDecimals.toString());
    console.log("BPS Decimals:", bpsDecimals.toString());
  } catch (e) {
    console.log("❌ Erro ao verificar decimals:", e.message);
  }
  
  // 6. Testar transferência simples
  console.log("\n6. Testando transferências...");
  try {
    const testAmount = ethers.parseEther("1");
    
    // Transferir para própria conta (teste)
    const transferTx1 = await spbToken.transfer(deployer.address, 0);
    await transferTx1.wait();
    console.log("✅ SPB transfer teste OK");
    
    const transferTx2 = await bpsToken.transfer(deployer.address, 0);
    await transferTx2.wait();
    console.log("✅ BPS transfer teste OK");
    
  } catch (e) {
    console.log("❌ Erro no teste de transfer:", e.message);
  }
  
  // 7. Teste de aprovação incremental
  console.log("\n7. Testando aprovações...");
  try {
    // Reset approvals
    await spbToken.approve(router.target, 0);
    await bpsToken.approve(router.target, 0);
    console.log("✅ Reset approvals OK");
    
    const testAmount = ethers.parseEther("1");
    const approveTx1 = await spbToken.approve(router.target, testAmount);
    await approveTx1.wait();
    console.log("✅ SPB approve teste OK");
    
    const approveTx2 = await bpsToken.approve(router.target, testAmount);
    await approveTx2.wait();
    console.log("✅ BPS approve teste OK");
    
  } catch (e) {
    console.log("❌ Erro no teste de approve:", e.message);
  }
  
  // 8. Verificar factory e criação de par
  console.log("\n8. Verificando factory...");
  try {
    await factory.createPair(spbToken.target, bpsToken.target);
    console.log("✅ Par já existe ou criado com sucesso");
  } catch (e) {
    console.log("ℹ️  Par provavelmente já existe:", e.message);
  }
  
  // 9. Teste de addLiquidity com chamada estática
  console.log("\n9. Testando addLiquidity com callStatic...");
  try {
    const minAmount = ethers.parseEther("1");
    const deadline = Math.floor(Date.now() / 1000) + 60 * 30;
    
    // Aprovar quantidades suficientes
    await spbToken.approve(router.target, minAmount);
    await bpsToken.approve(router.target, minAmount);
    
    // Ordenar tokens
    let tokenA, tokenB, amountA, amountB;
    if (spbToken.target.toLowerCase() < bpsToken.target.toLowerCase()) {
      tokenA = spbToken.target;
      tokenB = bpsToken.target;
      amountA = minAmount;
      amountB = minAmount;
    } else {
      tokenA = bpsToken.target;
      tokenB = spbToken.target;
      amountA = minAmount;
      amountB = minAmount;
    }
    
    console.log("Testando com callStatic:");
    console.log("TokenA:", tokenA);
    console.log("TokenB:", tokenB);
    console.log("AmountA:", ethers.formatEther(amountA));
    console.log("AmountB:", ethers.formatEther(amountB));
    
    // Usar callStatic para testar sem executar
    const result = await router.addLiquidity.staticCall(
      tokenA,
      tokenB,
      amountA,
      amountB,
      0, // amountAMin
      0, // amountBMin
      deployer.address,
      deadline
    );
    
    console.log("✅ CallStatic OK! Resultado:", {
      amountA: ethers.formatEther(result[0]),
      amountB: ethers.formatEther(result[1]),
      liquidity: ethers.formatEther(result[2])
    });
    
  } catch (e) {
    console.log("❌ Erro no callStatic:", e.message);
    if (e.data) {
      console.log("Dados do erro:", e.data);
    }
    
    // Tentar decodificar o erro
    try {
      if (e.data && e.data !== '0x') {
        console.log("Tentando decodificar erro...");
        // Erros comuns do Uniswap
        const errorSelectors = {
          '0x8c379a00': 'Error(string)', // revert with message
          '0x4e487b71': 'Panic(uint256)', // panic
          '0xe6c4247b': 'InsufficientAmount()',
          '0xf4d678b8': 'InsufficientLiquidity()',
        };
        
        const selector = e.data.slice(0, 10);
        if (errorSelectors[selector]) {
          console.log("Erro identificado:", errorSelectors[selector]);
        }
      }
    } catch (decodeError) {
      console.log("Não foi possível decodificar o erro");
    }
  }
  
  console.log("\n=== FIM DO DIAGNÓSTICO ===");
}

main().catch(console.error);
