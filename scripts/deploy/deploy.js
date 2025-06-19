async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying with address:", deployer.address);

  const SPBToken = await ethers.getContractFactory("SPBToken");
  const spb = await SPBToken.deploy();
  await spb.waitForDeployment();
  console.log("SPB deployed to:", await spb.getAddress());

  const BPSToken = await ethers.getContractFactory("BPSToken");
  const bps = await BPSToken.deploy();
  await bps.waitForDeployment();
  console.log("BPS deployed to:", await bps.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


// deploymento dos tokens SPB & BPS
