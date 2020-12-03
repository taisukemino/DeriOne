const HDWalletProvider = require("@truffle/hdwallet-provider");
require("dotenv").config();

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      gas: 5000000,
      network_id: "*",
      skipDryRun: true
    },
    mainnet: {
      provider: new HDWalletProvider(
        process.env.DEPLOYMENT_ACCOUNT_KEY,
        "https://mainnet.infura.io/v3/" + process.env.INFURA_API_KEY
      ),
      network_id: 1,
      gas: 5000000,
      gasPrice: 5000000000 // 5 Gwei
    }
  },
  compilers: {
    solc: {
      version: "^0.6.0"
    }
  }
};
