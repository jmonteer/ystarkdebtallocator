# StarkDebtAllocator
The objective of this PoC is decentralizing even more the process to choose strategy weights within a vault. 

StarkDebtAllocator is the contract in charge of receiving and validating debt ratio proposals, that will come from any proposer.   

It uses (zk-)STARKS through Starware's Cairo, SHARP prover and L1 verifier to generate proofs that make it possible to be sure that they are valid solutions without spending a ton of gas running the computation on-chain.

To incentivize people running the calculations and proposing solutions, the solution proposer will earn rewards during the time their solution is used. 

## Intro
Currently, debt ratios are proposed by vault managers and approved by multisig. Vault managers analyze how each of the strategies is performing, checking their different APYs and then come up with a set of debt ratios, which are set manually.
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
- verifySolution(bytes32[] programOutput): 
	- parses programOutput to the following values: bytes32 inputsHash, uint256 newAPY, uint256 arrayLength, address[] strategyArray, uint256[] debtRatioArray 
	- checks that the inputsHash has been saved before as is not stale
	- checks that the CairoVerifier from Starkware has received the proof and confirmed it is correct
	- checks that the new solution is better than the previous solution
	- sets the new winning solution

apy_calculator.cairo is the Cairo program that takes a set of debt ratios for certain strategies and calculates the weighted average APY for the whole set of strategies. 

This Cairo program will compute a hash of all the inputs it has used to calculate APYs to send it to the L1 smart contract, so inputs can be validated. 

## Details
![Diagram](./starkdebtallocator.png)
