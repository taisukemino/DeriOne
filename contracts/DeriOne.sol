pragma solidity 0.6.0;

import "./interfaces/IHegicETHOption.sol";
import "./interfaces/IETHPriceOracle.sol";
import "./interfaces/IOpynV1Exchange.sol";
import "./interfaces/IOpynOptionsFactory.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract DeriOne is Ownable {
    IHegicETHOption private IHegicETHOptionInstance;
    IETHPriceOracle private IETHPriceOracleInstance;
    IOpynV1Exchange private IOpynV1ExchangeInstance;
    IOpynOptionsFactory private IOpynV1OptionsFactoryInstance;


    event NewHegicETHOptionAddressRegistered(address hegicETHOptionAddress);
    event NewETHPriceOracleAddressRegistered(address ETHPriceOracleAddress);
    event NewOpynV1ExchangeAddressRegistered(address opynV1ExchangeAddress);
    event NewOpynV1OptionsFactoryAddressRegistered(address opynV1OptionsFactoryAddress);
    setETHPriceOracleAddress(address _ETHPriceOracleAddress) public onlyOwner {
        ETHPriceOracleAddress = _ETHPriceOracleAddress;
        IETHPriceOracleInstance = IETHPriceOracle(ETHPriceOracleAddress);

        emit NewETHPriceOracleAddressRegistered(ETHPriceOracleAddress);
    }

    setHegicETHOptionAddress(address _hegicETHOptionAddress) public onlyOwner {
        hegicETHOptionAddress = _hegicETHOptionAddress;
        IHegicETHOptionInstance = IHegicETHOption(hegicETHOptionAddress);

        emit NewHegicETHOptionAddressRegistered(hegicETHOptionAddress);
    }

    setOpynV1ExchangeAddress(address _opynV1ExchangeAddress) public onlyOwner {
        opynV1ExchangeAddress = _opynV1ExchangeAddress;
        IOpynV1ExchangeInstance = IOpynV1Exchange(opynV1ExchangeAddress);

        emit NewOpynV1ExchangeAddressRegistered(opynV1ExchangeAddress);
    }

    setOpynV1OptionsFactoryAddress(address _opynV1OptionsFactoryAddress) public onlyOwner {
        opynV1OptionsFactoryAddress = _opynV1OptionsFactoryAddress;
        IOpynV1OptionsFactoryInstance = IOpynV1Exchange(opynV1OptionsFactoryAddress);

        emit NewOpynV1OptionsFactoryAddressRegistered(opynV1OptionsFactoryAddress);
    }

    /** 
    * oTokenAddress is oToken contract's address
    * paymentTokenAddress is 0 because paying with ETH 
    * 100 oDai protects 100 * 10^-14 Dai i.e. 10^-12 Dai.
    */
    function getOpynPremium(oTokenAddress, oTokensToBuy)　{
        uint256 premiumToPayInETH = IOpynV1ExchangeInstance.premiumToPay(oTokenAddress, address(0), oTokensToBuy); 
        return premiumToPayInETH;           
    }

    /** 
    * calculate the premium in hegic
    */
    function getHegicPremium(period, strike) {
        uint256 impliedVolatility = getImpliedVolatility();
        uint256 ETHPrice = getETHPrice();
        uint256 premiumToPayInETH = sqrt(period) * impliedVolatility * strike / ETHPrice;
        return premiumToPayInETH;
    }

    /** 
    * get the implied volatility
    */
    function getImpliedVolatility()　{
        uint256 impliedVolatilityRate = IHegicETHOptionInstance.impliedVolRate();
        return impliedVolatilityRate;
    }

    /** 
    * get the underlying asset price
    */
    function getETHPrice()　{
        (, int latestPrice, , , ) = IETHPriceOracleInstance.latestRoundData();
        uint256 ETHPrice = uint256(latestPrice);
        return ETHPrice;
    }

}
