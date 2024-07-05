import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    polygonTestnet: {
      url: process.env.MUMBAI_RPC,
      accounts: [process.env.PRIVATE_KEY!],
      gasPrice: 50000000000,
    },
  },
  etherscan: {
    apiKey: process.env.API_KEY,
  },
};

export default config;
