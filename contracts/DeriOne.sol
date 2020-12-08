pragma solidity 0.6.0;

import "./interfaces/IHegicETHOption.sol";
import "./interfaces/IETHPriceOracle.sol";
import "./interfaces/IOpynExchange.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract DeriOne is Ownable {
    IHegicETHOption private IHegicETHOptionInstance;
    IETHPriceOracle private IETHPriceOracleInstance;
    IOpynExchange private IOpynExchangeInstance;

    event NewHegicETHOptionAddressRegistered(address hegicETHOptionAddress);
    event NewETHPriceOracleAddressRegistered(address ETHPriceOracleAddress);
    event NewOpynExchangeAddressRegistered(address opynExchangeAddress);
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

    setOpynExchangeAddress(address _opynExchangeAddress) public onlyOwner {
        opynExchangeAddress = _opynExchangeAddress;
        IOpynExchangeInstance = IOpynExchange(opynExchangeAddress);

        emit NewOpynExchangeAddressRegistered(opynExchangeAddress);
    }

    /** 
    * oTokenAddress is oToken contract's address
    * paymentTokenAddress is 0 because paying with ETH 
    * 100 oDai protects 100 * 10^-14 Dai i.e. 10^-12 Dai.
    */
    function getOpynPremium(oTokenAddress, oTokensToBuy)　{
        uint256 premiumToPayInETH = IOpynExchangeInstance.premiumToPay(oTokenAddress, address(0), oTokensToBuy); 
        return premiumToPayInETH;           
    }

}
