const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("🔍 DIAGNÓSTICO COMPLETO DE LIQUIDEZ");
  console.log("=====================================");
  console.log("Ethers version:", ethers.version);
  console.log("Deployer Address:", deployer.address);
  console.log("Block Number:", await ethers.provider.getBlockNumber());

  // Carregar endereços
  const dexAddresses = require('../../dex-addresses.json');
  const tokenAddresses = require('../../token-addresses.json');

  console.log("\n📋 ENDEREÇOS DOS CONTRATOS:");
  console.log("Dex Addresses:", dexAddresses);
  console.log("Token Addresses:", tokenAddresses);

  try {
    // Conectar aos contratos
    const router = await ethers.getContractAt("UniswapV2Router02", dexAddresses.UniswapV2Router02);
    const factory = await ethers.getContractAt("UniswapV2Factory", dexAddresses.UniswapV2Factory);
    const spbToken = await ethers.getContractAt("SPBToken", tokenAddresses.SPBToken);
    const bpsToken = await ethers.getContractAt("BPSToken", tokenAddresses.BPSToken);

    console.log("\n✅ CONTRATOS CONECTADOS:");
    console.log("Router:", router.target);
    console.log("Factory:", factory.target);
    console.log("SPB Token:", spbToken.target);
    console.log("BPS Token:", bpsToken.target);

    // 1. TESTE BÁSICO DOS CONTRATOS
    console.log("\n🧪 TESTE 1: FUNCIONALIDADE BÁSICA DOS CONTRATOS");
    console.log("=====================================================");
    
    try {
      const spbName = await spbToken.name();
      const spbSymbol = await spbToken.symbol();
      const spbDecimals = await spbToken.decimals();
      console.log(`✅ SPB Token: ${spbName} (${spbSymbol}) - ${spbDecimals} decimals`);
    } catch (e) {
      console.log("❌ SPB Token com problema:", e.message);
      return;
    }

    try {
      const bpsName = await bpsToken.name();
      const bpsSymbol = await bpsToken.symbol();
      const bpsDecimals = await bpsToken.decimals();
      console.log(`✅ BPS Token: ${bpsName} (${bpsSymbol}) - ${bpsDecimals} decimals`);
    } catch (e) {
      console.log("❌ BPS Token com problema:", e.message);
      return;
    }

    try {
      const routerFactory = await router.factory();
      const routerWETH = await router.WETH();
      console.log(`✅ Router: Factory=${routerFactory}, WETH=${routerWETH}`);
    } catch (e) {
      console.log("❌ Router com problema:", e.message);
      return;
    }

    try {
      const factoryFeeToSetter = await factory.feeToSetter();
      console.log(`✅ Factory: FeeToSetter=${factoryFeeToSetter}`);
    } catch (e) {
      console.log("❌ Factory com problema:", e.message);
      return;
    }

    // 2. VERIFICAR SALDOS E ALLOWANCES
    console.log("\n💰 TESTE 2: SALDOS E ALLOWANCES");
    console.log("================================");
    
    const spbBalance = await spbToken.balanceOf(deployer.address);
    const bpsBalance = await bpsToken.balanceOf(deployer.address);
    console.log("SPB Balance:", ethers.formatEther(spbBalance));
    console.log("BPS Balance:", ethers.formatEther(bpsBalance));

    const spbAllowance = await spbToken.allowance(deployer.address, router.target);
    const bpsAllowance = await bpsToken.allowance(deployer.address, router.target);
    console.log("SPB Allowance:", ethers.formatEther(spbAllowance));
    console.log("BPS Allowance:", ethers.formatEther(bpsAllowance));

    // 3. VERIFICAR ESTADO DO PAR
    console.log("\n🔗 TESTE 3: ESTADO DO PAR");
    console.log("=========================");
    
    let pairAddress = await factory.getPair(spbToken.target, bpsToken.target);
    console.log("Pair Address:", pairAddress);

    if (pairAddress === ethers.ZeroAddress) {
      console.log("⚠️  Par não existe - tentando criar...");
      try {
        const createTx = await factory.createPair(spbToken.target, bpsToken.target);
        await createTx.wait();
        pairAddress = await factory.getPair(spbToken.target, bpsToken.target);
        console.log("✅ Par criado:", pairAddress);
      } catch (e) {
        console.log("❌ Erro ao criar par:", e.message);
        return;
      }
    }

    // Verificar se o par funciona
    try {
      const pair = await ethers.getContractAt("UniswapV2Pair", pairAddress);
      const reserves = await pair.getReserves();
      const totalSupply = await pair.totalSupply();
      const token0 = await pair.token0();
      const token1 = await pair.token1();
      
      console.log("✅ Par funcionando:");
      console.log("  Token0:", token0);
      console.log("  Token1:", token1);
      console.log("  Reserve0:", ethers.formatEther(reserves._reserve0));
      console.log("  Reserve1:", ethers.formatEther(reserves._reserve1));
      console.log("  Total Supply:", ethers.formatEther(totalSupply));
    } catch (e) {
      console.log("❌ Par com problema:", e.message);
      return;
    }

    // 4. TESTE DE APROVAÇÃO INDIVIDUAL
    console.log("\n✅ TESTE 4: APROVAÇÕES INDIVIDUAIS");
    console.log("===================================");
    
    const testAmount = ethers.parseEther("1");
    
    try {
      console.log("Testando aprovação SPB...");
      const approveTx1 = await spbToken.approve(router.target, testAmount);
      await approveTx1.wait();
      const newAllowance1 = await spbToken.allowance(deployer.address, router.target);
      console.log("✅ SPB aprovado:", ethers.formatEther(newAllowance1));
    } catch (e) {
      console.log("❌ Erro ao aprovar SPB:", e.message);
      return;
    }

    try {
      console.log("Testando aprovação BPS...");
      const approveTx2 = await bpsToken.approve(router.target, testAmount);
      await approveTx2.wait();
      const newAllowance2 = await bpsToken.allowance(deployer.address, router.target);
      console.log("✅ BPS aprovado:", ethers.formatEther(newAllowance2));
    } catch (e) {
      console.log("❌ Erro ao aprovar BPS:", e.message);
      return;
    }

    // 5. TESTE DE TRANSFERÊNCIA DIRETA
    console.log("\n💸 TESTE 5: TRANSFERÊNCIAS DIRETAS");
    console.log("===================================");
    
    try {
      console.log("Testando transferência SPB...");
      const transferTx1 = await spbToken.transfer(deployer.address, ethers.parseEther("0.1"));
      await transferTx1.wait();
      console.log("✅ SPB transferência funcionando");
    } catch (e) {
      console.log("❌ Erro na transferência SPB:", e.message);
      return;
    }

    try {
      console.log("Testando transferência BPS...");
      const transferTx2 = await bpsToken.transfer(deployer.address, ethers.parseEther("0.1"));
      await transferTx2.wait();
      console.log("✅ BPS transferência funcionando");
    } catch (e) {
      console.log("❌ Erro na transferência BPS:", e.message);
      return;
    }

    // 6. TESTE DE TRANSFERFROM
    console.log("\n🔄 TESTE 6: TRANSFERFROM");
    console.log("========================");
    
    try {
      console.log("Testando transferFrom SPB...");
      const transferFromTx1 = await spbToken.transferFrom(
        deployer.address, 
        deployer.address, 
        ethers.parseEther("0.1")
      );
      await transferFromTx1.wait();
      console.log("✅ SPB transferFrom funcionando");
    } catch (e) {
      console.log("❌ Erro no transferFrom SPB:", e.message);
      // Não retorna aqui, pode ser problema de allowance
    }

    // 7. VERIFICAR CÓDIGOS DOS CONTRATOS
    console.log("\n📝 TESTE 7: CÓDIGOS DOS CONTRATOS");
    console.log("=================================");
    
    const routerCode = await ethers.provider.getCode(router.target);
    const factoryCode = await ethers.provider.getCode(factory.target);
    const spbCode = await ethers.provider.getCode(spbToken.target);
    const bpsCode = await ethers.provider.getCode(bpsToken.target);
    const pairCode = await ethers.provider.getCode(pairAddress);

    console.log("Router code length:", routerCode.length);
    console.log("Factory code length:", factoryCode.length);
    console.log("SPB code length:", spbCode.length);
    console.log("BPS code length:", bpsCode.length);
    console.log("Pair code length:", pairCode.length);

    if (routerCode === "0x" || factoryCode === "0x" || spbCode === "0x" || bpsCode === "0x" || pairCode === "0x") {
      console.log("❌ Um ou mais contratos não possuem código!");
      return;
    }

    // 8. TESTE SIMPLIFICADO DE ADDLIQUIDITY
    console.log("\n🧪 TESTE 8: ADDLIQUIDITY SIMPLIFICADO");
    console.log("======================================");
    
    // Preparar valores pequenos para teste
    const smallSpbAmount = ethers.parseEther("1");
    const smallBpsAmount = ethers.parseEther("1");
    
    // Aprovar quantidades exatas
    console.log("Aprovando quantidades pequenas...");
    await spbToken.approve(router.target, smallSpbAmount);
    await bpsToken.approve(router.target, smallBpsAmount);
    
    // Determinar ordem dos tokens
    let tokenA, tokenB, amountADesired, amountBDesired;
    if (spbToken.target.toLowerCase() < bpsToken.target.toLowerCase()) {
      tokenA = spbToken.target;
      tokenB = bpsToken.target;
      amountADesired = smallSpbAmount;
      amountBDesired = smallBpsAmount;
    } else {
      tokenA = bpsToken.target;
      tokenB = spbToken.target;
      amountADesired = smallBpsAmount;
      amountBDesired = smallSpbAmount;
    }

    const deadline = Math.floor(Date.now() / 1000) + 60 * 30;

    console.log("Parâmetros do teste:");
    console.log("  TokenA:", tokenA);
    console.log("  TokenB:", tokenB);
    console.log("  AmountA:", ethers.formatEther(amountADesired));
    console.log("  AmountB:", ethers.formatEther(amountBDesired));
    console.log("  Deadline:", deadline);

    try {
      console.log("Executando callStatic...");
      const result = await router.addLiquidity.staticCall(
        tokenA,
        tokenB,
        amountADesired,
        amountBDesired,
        0, // amountAMin
        0, // amountBMin
        deployer.address,
        deadline
      );
      
      console.log("✅ CallStatic bem-sucedido!");
      console.log("  AmountA:", ethers.formatEther(result[0]));
      console.log("  AmountB:", ethers.formatEther(result[1]));
      console.log("  Liquidity:", ethers.formatEther(result[2]));
      
      // Se chegou aqui, o problema foi resolvido!
      console.log("\n🎉 DIAGNÓSTICO CONCLUÍDO COM SUCESSO!");
      console.log("O problema foi identificado e resolvido durante os testes.");
      console.log("Você pode executar o script de addLiquidity novamente.");
      
    } catch (error) {
      console.log("❌ CallStatic ainda falhando:");
      console.log("  Mensagem:", error.message);
      console.log("  Data:", error.data);
      
      // Análise final
      console.log("\n🔍 ANÁLISE FINAL:");
      console.log("================");
      
      if (error.message.includes("InsufficientAmount")) {
        console.log("🎯 PROBLEMA: Quantidade insuficiente");
        console.log("SOLUÇÃO: Verifique se os valores não são zero");
      } else if (error.message.includes("InsufficientBalance")) {
        console.log("🎯 PROBLEMA: Saldo insuficiente");
        console.log("SOLUÇÃO: Verifique os saldos dos tokens");
      } else if (error.message.includes("TransferFailed")) {
        console.log("🎯 PROBLEMA: Falha na transferência");
        console.log("SOLUÇÃO: Problema nos contratos dos tokens");
      } else if (error.data === "0x") {
        console.log("🎯 PROBLEMA: Revert sem mensagem");
        console.log("POSSÍVEIS CAUSAS:");
        console.log("  1. Problema na implementação do Router");
        console.log("  2. Problema na implementação da Factory");
        console.log("  3. Problema nos contratos dos tokens");
        console.log("  4. Estado inconsistente do par");
        console.log("  5. Problema de gas ou outras limitações da rede");
      }
      
      console.log("\n💡 PRÓXIMOS PASSOS:");
      console.log("1. Verificar se todos os contratos foram deployados corretamente");
      console.log("2. Verificar se não há problemas de compatibilidade");
      console.log("3. Testar com valores ainda menores");
      console.log("4. Considerar re-deploy dos contratos");
    }

  } catch (error) {
    console.error("\n💥 ERRO GERAL NO DIAGNÓSTICO:");
    console.error("Mensagem:", error.message);
    console.error("Stack:", error.stack);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
