require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ethers");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      hardfork: "london",
    },
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/olE9Qt0KukfSueB6tRfl5D0VDP5MwFCD",
      accounts: [`0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`],
      chainId: 11155111,
      blockConfirmations: 6,
    },
    hardhat: {
      hardfork: "london",
    },
  },
};
