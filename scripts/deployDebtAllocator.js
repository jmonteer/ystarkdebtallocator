const hre = require("hardhat");

async function main() {
  const CAIRO_VERIFIER = "0x47312450B3Ac8b5b8e247a6bB6d523e7605bDb60";
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  const DebtAllocator = await hre.ethers.getContractFactory("DebtAllocator");
  const debtAllocator = await DebtAllocator.deploy( CAIRO_VERIFIER );
  await debtAllocator.deployed();
  console.log(
    `DebtAllocator deployed to ${debtAllocator.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
