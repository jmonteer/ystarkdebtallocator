const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

describe("deploy debt allocator and 2 dummy", function () {
  async function deployTokenFixture() {
    const DebtAllocatorTest = await ethers.getContractFactory("DebtAllocatorTest");
    const dummy1 = await ethers.getContractFactory("dummy");
    const dummy2 = await ethers.getContractFactory("dummy");
    const [owner] = await ethers.getSigners();


    const CAIRO_VERIFIER = "0x47312450B3Ac8b5b8e247a6bB6d523e7605bDb60";
    const NEW_CAIRO_PROGRAM_HASH = "0x47312450B3Ac8b5b8e247a6bB6d523e7605bDb60";

    const starkDebtContract = await DebtAllocatorTest.deploy(CAIRO_VERIFIER, NEW_CAIRO_PROGRAM_HASH);
    await starkDebtContract.deployed();

    const dummy1Contract = await dummy1.deploy();
    await dummy1Contract.deployed();

    const dummy2Contract = await dummy2.deploy();
    await dummy2Contract.deployed();

    // Fixtures can return anything you consider useful for your tests
    return { starkDebtContract, dummy1Contract, dummy2Contract, owner };
  }

  it("Should assign the total supply of tokens to the owner", async function () {
    const { starkDebtContract, dummy1Contract, dummy2Contract } = await loadFixture(deployTokenFixture);
    const STRATEGY_ADDRESS = "0x39AA39c021dfbaE8faC545936693aC917d5E7563";
    const STRATEGY_CONTRACTS = ["0x39AA39c021dfbaE8faC545936693aC917d5E7563","0x39AA39c021dfbaE8faC545936693aC917d5E7563"];
    const STRATEGY_CHECKDATA = ["0x18160ddd","0x8f840ddd"];
    await starkDebtContract.balanceOf(owner.address);

    expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
  });

  it("Should transfer tokens between accounts", async function () {
    const { hardhatToken, owner, addr1, addr2 } = await loadFixture(
      deployTokenFixture
    );

    // Transfer 50 tokens from owner to addr1
    await expect(
      hardhatToken.transfer(addr1.address, 50)
    ).to.changeTokenBalances(hardhatToken, [owner, addr1], [-50, 50]);

    // Transfer 50 tokens from addr1 to addr2
    // We use .connect(signer) to send a transaction from another account
    await expect(
      hardhatToken.connect(addr1).transfer(addr2.address, 50)
    ).to.changeTokenBalances(hardhatToken, [addr1, addr2], [-50, 50]);
  });
});