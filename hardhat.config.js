require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-solhint");
require("hardhat-gas-reporter");
require("hardhat-interface-generator");
require("solidity-coverage");
require("dotenv").config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  paths: {
    artifacts: "./src/artifacts",
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    rinkeby: {
      url: process.env.INFURA_URL,
      accounts: [process.env.ACCOUNT],
      chainId: 4,
    },
    goerli: {
      url: process.env.ALCHEMY_API_URL_GOERLI,
      accounts: { mnemonic: process.env.MNEMONIC },
      chainId: 5,
    },
    hardhat: {
      chainId: 1337,
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  gasReporter: {
    enabled: false,
    currency: "EUR",
    // gasPriceApi: process.env.ETHERSCAN_API_KEY,
    gasPrice: 33,
    coinmarketcap: process.env.COIN_MCAP_API_KEY,
  },
};
