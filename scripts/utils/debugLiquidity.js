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
  
  // 5. Teste de aprovação
  console.log("\n5. Testando aprovação pequena...");
  try {
    const testAmount = ethers.parseEther("1");
    const approveTx = await spbToken.approve(router.target, testAmount);
    await approveTx.wait();
    console.log("✅ Aprovação de teste OK");
  } catch (e) {
    console.log("❌ Erro na aprovação:", e.message);
  }
  
  // 6. Teste de addLiquidity com valores mínimos
  console.log("\n6. Testando addLiquidity com valores mínimos...");
  try {
    const minAmount = ethers.parseEther("0.001"); // Valores muito pequenos
    const deadline = Math.floor(Date.now() / 1000) + 60 * 30;
    
    // Aprovar primeiro
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
    
    console.log("Tentando com:");
    console.log("TokenA:", tokenA);
    console.log("TokenB:", tokenB);
    console.log("AmountA:", ethers.formatEther(amountA));
    console.log("AmountB:", ethers.formatEther(amountB));
    
    const gasEstimate = await router.addLiquidity.estimateGas(
      tokenA,
      tokenB,
      amountA,
      amountB,
      0, // amountAMin
      0, // amountBMin
      deployer.address,
      deadline
    );
    
    console.log("✅ Gas estimate OK:", gasEstimate.toString());
    
    // Executar transação real com valores pequenos
    const tx = await router.addLiquidity(
      tokenA,
      tokenB,
      amountA,
      amountB,
      0,
      0,
      deployer.address,
      deadline,
      { gasLimit: gasEstimate * 2n }
    );
    
    const receipt = await tx.wait();
    console.log("✅ AddLiquidity de teste OK! Hash:", receipt.hash);
    
  } catch (e) {
    console.log("❌ Erro no addLiquidity:", e.message);
    if (e.data) {
      console.log("Dados do erro:", e.data);
    }
  }
  
  console.log("\n=== FIM DO DIAGNÓSTICO ===");
}

main().catch(console.error);