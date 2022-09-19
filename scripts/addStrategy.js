const hre = require("hardhat");
require('dotenv').config();

//  0x9bA00D6856a4eDF4665BcA2C2309936572473B7E  aUSDC aave
//  selector 1 : totalSupply() = 0x18160ddd
//  0x39AA39c021dfbaE8faC545936693aC917d5E7563  cUSDC coumpound
//  selector 1 : totalSupply() = 0x18160ddd
//  selector 2 : totalReserves() = 0x8f840ddd

//current program hash 0x02a7925118463c9679fce9aedeac8eca7bb27452f87c5477a65e88106a5ae3fe

async function main() {
  const DEBTALLOCATOR_ADDRESS = process.env.DEBT_ALLOCATOR;
  const MAX_DEBT_RATIO = 10000;
  const STRATEGY_ADDRESS = "0x39AA39c021dfbaE8faC545936693aC917d5E7563";
  const STRATEGY_CONTRACTS = ["0x39AA39c021dfbaE8faC545936693aC917d5E7563","0x39AA39c021dfbaE8faC545936693aC917d5E7563"];
  const STRATEGY_CHECKDATA = ["0x18160ddd","0x8f840ddd"];
  const NEW_CAIRO_PROGRAM_HASH = "0x02a7925118463c9679fce9aedeac8eca7bb27452f87c5477a65e88106a5ae3fe";
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const debtAllocator = await hre.ethers.getContractAt("DebtAllocator", DEBTALLOCATOR_ADDRESS);
  await debtAllocator.deployed();
  console.log(
    `DebtAllocator loaded to ${debtAllocator.address}`
  );

  // addStrategy(address strategy, uint16 maxDebtRatio,address[] memory contracts, bytes[] memory checkdata, bytes32 newCairoProgramHash)
  const newStrategy = await debtAllocator.addStrategy(STRATEGY_ADDRESS, MAX_DEBT_RATIO,STRATEGY_CONTRACTS, STRATEGY_CHECKDATA, NEW_CAIRO_PROGRAM_HASH)
  console.log("Trx hash:", newStrategy.hash);
  const receipt = await newStrategy.wait()
  const newCairoProgramHashEvent = receipt.events.find(x => x.event === "NewCairoProgramHash");
  const newStrategyEvent = receipt.events.find(x => x.event === "NewStrategy");


  console.log(newCairoProgramHashEvent.args.newCairoProgramHash)

  console.log(newStrategyEvent.args.newStrategy)
  console.log(newStrategyEvent.args.strategyContracts)
  console.log(newStrategyEvent.args.strategyCheckData)
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
