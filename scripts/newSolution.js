const hre = require("hardhat");
require('dotenv').config();

async function main() {
  const DEBTALLOCATOR_ADDRESS = process.env.DEBT_ALLOCATOR;

  //cairoProgramOutput
  const PROGRAM_OUTPUT = [214294432856748954646218952614427488837,282686271226971945777497920751595672460,2,5000,5000,7];

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const debtAllocator = await hre.ethers.getContractAt("DebtAllocator", DEBTALLOCATOR_ADDRESS);
  await debtAllocator.deployed();
  console.log(
    `DebtAllocator loaded to ${debtAllocator.address}`
  );

  // function verifySolution(uint256[] memory programOutput) external
  const newSolution = await debtAllocator.verifySolution(PROGRAM_OUTPUT)
  const receipt = await newSolution.wait()
  const newSolutionEvent = receipt.events.find(x => x.event === "NewSolution");

  console.log(newSolutionEvent.args.newApy)
  console.log(newSolutionEvent.args.newDebtRatio)
  console.log(newSolutionEvent.args.proposer)
  console.log(newSolutionEvent.args.timestamp)

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
