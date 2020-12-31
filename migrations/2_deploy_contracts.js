const DeriOneV1Main = artifacts.require("DeriOneV1Main.sol");

module.exports = function (deployer, network) {
  if (network === "development") {
    deployer.deploy(DeriOneV1Main, arg1, arg2);
  } else if (network === "mainnet") {
    // const variables for the constructor
    const ETHPriceOracleAddress = "";
    const ETHPriceOracleAddress = "";
    const hegicETHPoolV888Address = "";
    const opynExchangeV1Address = "";
    const opynOptionsFactoryV1Address = "";
    const uniswapFactoryV1Address = "";
    // deploy the DeriOneV1Main contract with constructor arguments
    deployer.deploy(
      DeriOneV1Main,
      ETHPriceOracleAddress,
      ETHPriceOracleAddress,
      hegicETHPoolV888Address,
      opynExchangeV1Address,
      opynOptionsFactoryV1Address,
      uniswapFactoryV1Address
    );
  }
};
