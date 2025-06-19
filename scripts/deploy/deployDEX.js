const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    
    console.log("Implantando DEX com a conta:", deployer.address);
    console.log("Saldo da conta:", (await ethers.provider.getBalance(deployer.address)).toString());

    // 1. Implantar WETH9
    console.log("\n1. Implantando WETH9...");
    const WETH9 = await ethers.getContractFactory("WETH9");
    const weth = await WETH9.deploy();
    // Aguardar a confirmação da transação
    const wethTx = await weth.deploymentTransaction().wait();
    console.log("WETH9 implantado em:", weth.target);

    // 2. Implantar UniswapV2Factory
    console.log("\n2. Implantando UniswapV2Factory...");
    const UniswapV2Factory = await ethers.getContractFactory("UniswapV2Factory");
    const factory = await UniswapV2Factory.deploy(deployer.address);
    // Aguardar a confirmação da transação
    const factoryTx = await factory.deploymentTransaction().wait();
    console.log("UniswapV2Factory implantado em:", factory.target);

    // 3. Implantar UniswapV2Router02
    console.log("\n3. Implantando UniswapV2Router02...");
    const UniswapV2Router02 = await ethers.getContractFactory("UniswapV2Router02");
    const router = await UniswapV2Router02.deploy(factory.target, weth.target);
    // Aguardar a confirmação da transação
    const routerTx = await router.deploymentTransaction().wait();
    console.log("UniswapV2Router02 implantado em:", router.target);

    // 4. Salvar endereços em arquivo
    const addresses = {
        WETH9: weth.target,
        UniswapV2Factory: factory.target,
        UniswapV2Router02: router.target
    };

    const fs = require('fs');
    fs.writeFileSync(
        'dex-addresses.json',
        JSON.stringify(addresses, null, 2)
    );

    console.log("\n✅ DEX implantado com sucesso!");
    console.log("Endereços salvos em dex-addresses.json");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
