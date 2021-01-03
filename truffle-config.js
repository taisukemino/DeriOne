const HDWalletProvider = require("@truffle/hdwallet-provider");
require("dotenv").config();

module.exports = {
  networks: {
    develop: {
      host: "127.0.0.1",
      port: 8545,
      gas: 5000000,
      fork: "https://mainnet.infura.io/v3/" + process.env.INFURA_API_KEY,
      network_id: 1,
      skipDryRun: true
    },
    mainnet: {
      provider: () =>
        new HDWalletProvider({
          providerOrUrl:
            "https://mainnet.infura.io/v3/" + process.env.INFURA_API_KEY
        }),
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
