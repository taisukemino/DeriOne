const HDWalletProvider = require("@truffle/hdwallet-provider");
require("dotenv").config();

module.exports = {
  networks: {
    mainnet_forking: {
      url:
        "https://sandbox.truffleteams.com/c3fa3fb4-612e-44d0-9480-fb491f3187e7",
      network_id: 1
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
