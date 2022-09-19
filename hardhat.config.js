require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: `https://goerli.infura.io/v3/309820d3955640ec9cda472d998479ef`,
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    },
    mainnet: {
      url: `https://rpc.ankr.com/eth`,
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    }
  }
};
