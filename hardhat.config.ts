import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.6.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.10",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ]
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    bevm_testnet: {
      url: "https://canary-testnet.bevm.io",
      accounts: [process.env.PRIVATE_KEY || ""],
    },
    goerli: {
      url: "https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161",
      accounts: [process.env.PRIVATE_KEY || ""],
      gas: 5000000,
    },
    sepolia: {
      url: "https://sepolia.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161",
      accounts: [process.env.PRIVATE_KEY || ""],
      gas: 5000000,
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    bob: { default: 1 },
    alice: { default: 2 },
    sam: { default: 3 },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: {
      bevm_testnet: "3SGTMB5DR8ZHNSBZUXZRQCB5M3PV6FZYKA"
    },
    customChains: [
      {
        network: "bevm_testnet",
        chainId: 1502,
        urls: {
          apiURL: "https://canary-testnet.bevm.io",
          browserURL: "https://scan-canary-testnet.bevm.io/"
        }
      }
    ]
  },
  mocha: {
    timeout: 0,
    bail: true,
  },
  sourcify: {
    enabled: true
  },
};

export default config;