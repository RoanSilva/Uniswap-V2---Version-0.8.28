// scripts/deploy/createPair.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    
    // Carregar endereços
    const dexAddresses = require('../../dex-addresses.json');
    const tokenAddresses = require('../../token-addresses.json');
    
    console.log("Creating SPB/BPS pair...");
    
    // Conectar à factory
    const factory = await ethers.getContractAt("UniswapV2Factory", dexAddresses.UniswapV2Factory);
    
    // Criar par SPB/BPS
    const tx = await factory.createPair(tokenAddresses.SPBToken, tokenAddresses.BPSToken);
    await tx.wait();
    
    // Obter endereço do par
    const pairAddress = await factory.getPair(tokenAddresses.SPBToken, tokenAddresses.BPSToken);
    
    console.log("SPB/BPS pair created at:", pairAddress);
    
    // Salvar endereço do par
    const pairData = {
        SPB_BPS_Pair: pairAddress
    };
    
    const fs = require('fs');
    fs.writeFileSync(
        'pair-addresses.json',
        JSON.stringify(pairData, null, 2)
    );
    
    console.log("✅ Pair created successfully!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
