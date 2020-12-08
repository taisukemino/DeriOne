pragma solidity 0.6.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./interfaces/IETHPriceOracle.sol";
import "./interfaces/IHegicETHOptionV888.sol";
import "./interfaces/IOpynExchangeV1.sol";
import "./interfaces/IOpynOptionsFactoryV1.sol";
import "./interfaces/IOpynOTokenV1.sol";

/// @title A contract for getting the best options price
/// @author Tai
/// @notice For now, this contract gets the best ETH put options price from Opyn and Hegic
contract DeriOne is Ownable {
    IETHPriceOracle private IETHPriceOracleInstance;
    IHegicETHOptionV888 private IHegicETHOptionV888Instance;
    IOpynExchangeV1 private IOpynExchangeV1Instance;
    IOpynOptionsFactoryV1 private IOpynOptionsFactoryV1Instance;
    IOpynOTokenV1 private IOpynOTokenV1Instance;

    address oTokenAddressList [];

    event NewETHPriceOracleAddressRegistered(address ETHPriceOracleAddress);
    event NewHegicETHOptionV888AddressRegistered(address hegicETHOptionV888Address);
    event NewOpynExchangeV1AddressRegistered(address opynExchangeV1Address);
    event NewOpynOptionsFactoryV1AddressRegistered(address opynOptionsFactoryV1Address);
    event NewOpynOTokenV1AddressRegistered(address opynOTokenV1Address);
    setETHPriceOracleAddress(address _ETHPriceOracleAddress) public onlyOwner {
        ETHPriceOracleAddress = _ETHPriceOracleAddress;
        IETHPriceOracleInstance = IETHPriceOracle(ETHPriceOracleAddress);

        emit NewETHPriceOracleAddressRegistered(ETHPriceOracleAddress);
    }

    setHegicETHOptionV888Address(address _hegicETHOptionV888Address) public onlyOwner {
        hegicETHOptionV888Address = _hegicETHOptionV888Address;
        IHegicETHOptionV888Instance = IHegicETHOptionV888(hegicETHOptionV888Address);

        emit NewHegicETHOptionV888AddressRegistered(hegicETHOptionV888Address);
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

    /// @notice get the list of oToken addresses
    function getOTokenAddressList() public onlyOwner {
        oTokenAddressList = IOpynOptionsFactoryV1Instance.optionsContracts();
    }
    /// @notice get the premium in opyn
    /// @param oTokenAddress oToken contract's address.
    /// @param oTokensToBuy the amount of oTokens to buy
    /// @return the premium in ETH
    function getOpynPremium(oTokenAddress, oTokensToBuy)　{
        uint256 premiumToPayInETH = IOpynExchangeV1Instance.premiumToPay(oTokenAddress, address(0), oTokensToBuy); 
        return premiumToPayInETH;
    }

    /// @notice get the implied volatility
    function getImpliedVolatility()　{
        uint256 impliedVolatilityRate = IHegicETHOptionV888Instance.impliedVolRate();
        return impliedVolatilityRate;
    }

    /// @notice get the underlying asset price
    function getETHPrice()　{
        (, int latestPrice, , , ) = IETHPriceOracleInstance.latestRoundData();
        uint256 ETHPrice = uint256(latestPrice);
        return ETHPrice;
    }

    /// @notice calculate the premium in hegic
    function getHegicPremium(period, strike) {
        uint256 impliedVolatility = getImpliedVolatility();
        uint256 ETHPrice = getETHPrice();
        uint256 premiumToPayInETH = sqrt(period) * impliedVolatility * strike / ETHPrice;
        return premiumToPayInETH;
    }
}
