const DeriOneV1Main = artifacts.require("DeriOneV1Main.sol");

module.exports = function (deployer, network) {
  // const variables for the constructor
  const ETHPriceOracleAddress = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419";
  const hegicETHOptionV888Address =
    "0xEfC0eEAdC1132A12c9487d800112693bf49EcfA2";
  const hegicETHPoolV888Address = "";
  const opynExchangeV1Address = "0x39246c4f3f6592c974ebc44f80ba6dc69b817c71";
  const opynOptionsFactoryV1Address = "";
  const uniswapFactoryV1Address = "";

  if (network === "develop") {
    deployer.deploy(DeriOneV1Main, arg1, arg2);
  } else if (network === "mainnet") {
    // deploy the DeriOneV1Main contract with constructor arguments
    deployer.deploy(
      DeriOneV1Main,
      ETHPriceOracleAddress,
      hegicETHOptionV888Address,
      hegicETHPoolV888Address,
      opynExchangeV1Address,
      opynOptionsFactoryV1Address,
      uniswapFactoryV1Address
    );
  }
};
