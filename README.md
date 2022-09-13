# StarkDebtAllocator
The objective of this PoC is decentralizing even more the process to choose strategy weights within a vault. 

StarkDebtAllocator is the contract in charge of receiving and validating debt ratio proposals, that will come from any proposer.   

It uses (zk-)STARKS through Starware's Cairo, SHARP prover and L1 verifier to generate proofs that make it possible to be sure that they are valid solutions without spending a ton of gas running the computation on-chain.

To incentivize people running the calculations and proposing solutions, the solution proposer will earn rewards during the time their solution is used. 

## Intro
Currently, debt ratios are proposed by vault managers and approved by a multisig. Vault managers analyze how each of the strategies is performing, checking their different APYs and then come up with a set of debt ratios, which are set manually. 
{
    "strategy1": 2500, 
    "strategy2": 2500,
    "strategy3": 3500,
    "strategy4": 1500
}

This process requires manual intervention and brings a lot of overhead with it.

## Solution
The PoC is composed of 2 parts: L1 smart contract and Cairo Program

StarkDebtAllocator is one Ethereum L1 smart contract. 

It implements two (main) functions:
- saveSnapshot(): reads all the on-chain data that will be used as inputs for the Cairo Program and hashes them all, then saves the hash
- verifySolution(uint256[] programOutput): 
	- parses programOutput to the following values: uint256 inputsHash, uint256[] debtRatios, uint256 newAPY, 
	- checks that the inputsHash has been saved before as is not stale and that it corresponds to the inputsHash used in the cairo program (from programOutput). Note that cairo felt isn't big enought to support 256 bits (252 bits max), that's why 2 slot of the programOutput are used to calculate the input hash from strategies input, 128 bits each.
	- checks that each debt ratio is not bigger than the maxValue stored for the associated strategy
	- checks that the CairoVerifier from Starkware has received the proof and confirmed it is correct
	- checks that the new solution is better than the previous solution
	- sets the new winning solution, the new debt ratio array and store the address of the user.

apy_calculator.cairo is the Cairo program that takes a set of debt ratios for certain strategies and calculates the weighted average APY for the whole set of strategies. 

This Cairo program will compute a hash of all the inputs it has used to calculate APYs to send it to the L1 smart contract, so inputs can be validated. 

## Details
![Diagram](./starkdebtallocator.png)


## Test

Follow these steps: 
- Deploy DebtAllocator.sol providing the cairo verifier address (currently 0xAB43bA48c9edF4C2C4bB01237348D1D7B28ef168 on Goerli, there is no way to try it in local)

- Invoke updateCairoProgramHash providing this hash  0x0015ed2b5183dcaa8ca8ccfb01b3f861d74a88f02747d651ac5f1846ebebd492. If you modify the cairoProgram, just run sh programhash.sh to get the new one.

- Invoke saveSnapshot(), everything is hard coded rightnow, you don't even need to add strategies. The function returns the strategies input tab, use it to fill apy_calculator_input.json. 

- Choose a new debt ratio configuration for the stratgies and add it in apy_calculator_input.json ("debt_ratio":[2000, 7500, 500] for exemple).Compile, run the cairo program and send its proof to the SHARP, you can use sh run.sh to do it in one step.
![Terminal](./cairoOutput.png)

- Invoke verifySolution providing the output you got from the last step. You should see a new APY value! 