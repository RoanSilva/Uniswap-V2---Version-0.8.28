// scripts/deploy/deployTokens.js
const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying with address:", deployer.address);

  const SPBToken = await ethers.getContractFactory("SPBToken");
  const spb = await SPBToken.deploy();
  await spb.waitForDeployment();
  const spbAddress = await spb.getAddress();
  console.log("SPB deployed to:", spbAddress);

  const BPSToken = await ethers.getContractFactory("BPSToken");
  const bps = await BPSToken.deploy();
  await bps.waitForDeployment();
  const bpsAddress = await bps.getAddress();
  console.log("BPS deployed to:", bpsAddress);

  // Salvar os endereços em token-addresses.json
  const tokenData = {
    SPBToken: spbAddress,
    BPSToken: bpsAddress
  };

  fs.writeFileSync(
    "token-addresses.json",
    JSON.stringify(tokenData, null, 2)
  );

  console.log("✅ Token addresses saved to token-addresses.json");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

