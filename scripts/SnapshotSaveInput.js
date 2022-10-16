const hre = require("hardhat");
require('dotenv').config();

async function main() {
    const DEBTALLOCATOR_ADDRESS = process.env.DEBT_ALLOCATOR;
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

  const debtAllocator = await hre.ethers.getContractAt("DebtAllocator", DEBTALLOCATOR_ADDRESS);
  await debtAllocator.deployed();
  console.log(
    `DebtAllocator loaded to ${debtAllocator.address}`
  );

  // saveSnapshot() external returns(uint256[][] memory strategiesInput_)
  const newSnapshot = await debtAllocator.saveSnapshot()
  const receipt = await newSnapshot.wait()
  const newSnapshotEvent = receipt.events.find(x => x.event === "NewSnapshot");
  
  console.log(newSnapshotEvent.args.inputStrategies)
  console.log(newSnapshotEvent.args.calculation)
  console.log(newSnapshotEvent.args.inputHash)
  console.log(newSnapshotEvent.args.timestamp)
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
