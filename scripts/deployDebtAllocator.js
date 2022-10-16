const hre = require("hardhat");

async function main() {
  const CAIRO_VERIFIER = "0x47312450B3Ac8b5b8e247a6bB6d523e7605bDb60";
  const CAIRO_PROGRAM_HASH = "0x00bfd3c17a344350521b3f4c254de74e98ef52cbb2a305be36c72f8af8b6b282";
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  const DebtAllocator = await hre.ethers.getContractFactory("DebtAllocator");
  const debtAllocator = await DebtAllocator.deploy( CAIRO_VERIFIER, CAIRO_PROGRAM_HASH );
  await debtAllocator.deployed();
  console.log(
    `DebtAllocator deployed to ${debtAllocator.address}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
