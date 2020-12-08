pragma solidity 0.6.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./interfaces/IETHPriceOracle.sol";
import "./interfaces/IHegicETHOption.sol";
import "./interfaces/IOpynExchangeV1.sol";
import "./interfaces/IOpynOptionsFactoryV1.sol";
import "./interfaces/IOpynOTokenV1.sol";

contract DeriOne is Ownable {
    IETHPriceOracle private IETHPriceOracleInstance;
    IHegicETHOption private IHegicETHOptionInstance;
    IOpynExchangeV1 private IOpynExchangeV1Instance;
    IOpynOptionsFactoryV1 private IOpynOptionsFactoryV1Instance;
    IOpynOTokenV1 private IOpynOTokenV1Instance;

    address oTokenAddressList [];

    event NewETHPriceOracleAddressRegistered(address ETHPriceOracleAddress);
    event NewHegicETHOptionAddressRegistered(address hegicETHOptionAddress);
    event NewOpynExchangeV1AddressRegistered(address opynExchangeV1Address);
    event NewOpynOptionsFactoryV1AddressRegistered(address opynOptionsFactoryV1Address);
    event NewOpynOTokenV1AddressRegistered(address opynOTokenV1Address);
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

    setOpynExchangeV1Address(address _opynExchangeV1Address) public onlyOwner {
        opynExchangeV1Address = _opynExchangeV1Address;
        IOpynExchangeV1Instance = IOpynExchangeV1(opynExchangeV1Address);

        emit NewOpynExchangeV1AddressRegistered(opynExchangeV1Address);
    }

    setOpynOptionsFactoryV1Address(address _opynOptionsFactoryV1Address) public onlyOwner {
        opynOptionsFactoryV1Address = _opynOptionsFactoryV1Address;
        IOpynOptionsFactoryV1Instance = IOpynExchangeV1(opynOptionsFactoryV1Address);

        emit NewOpynOptionsFactoryV1AddressRegistered(opynOptionsFactoryV1Address);
    }

    setOpynOTokenV1Address(address _opynOTokenV1Address) public onlyOwner {
        opynOTokenV1Address = _opynOTokenV1Address;
        IOpynOTokenV1Instance = IOpynOTokenV1(opynOTokenV1Address);

        emit NewOpynOTokenV1AddressRegistered(opynOTokenV1Address);
    }

    function getOTokenAddressList() public onlyOwner {
        oTokenAddressList = IOpynOptionsFactoryV1Instance.optionsContracts();
    }
    /** 
    * oTokenAddress is oToken contract's address
    * paymentTokenAddress is 0 because paying with ETH 
    * 100 oDai protects 100 * 10^-14 Dai i.e. 10^-12 Dai.
    */
    function getOpynPremium(oTokenAddress, oTokensToBuy)　{
        uint256 premiumToPayInETH = IOpynExchangeV1Instance.premiumToPay(oTokenAddress, address(0), oTokensToBuy); 
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

    /** 
    * calculate the premium in hegic
    */
    function getHegicPremium(period, strike) {
        uint256 impliedVolatility = getImpliedVolatility();
        uint256 ETHPrice = getETHPrice();
        uint256 premiumToPayInETH = sqrt(period) * impliedVolatility * strike / ETHPrice;
        return premiumToPayInETH;
    }
}
