pragma solidity 0.6.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./interfaces/IETHPriceOracle.sol";
import "./interfaces/IHegicETHOptionV888.sol";
import "./interfaces/IHegicETHPoolV888.sol";
import "./interfaces/IOpynExchangeV1.sol";
import "./interfaces/IOpynOptionsFactoryV1.sol";
import "./interfaces/IOpynOTokenV1.sol";

/// @author tai
/// @title A contract for getting the best options price
/// @notice For now, this contract gets the best ETH put options price from Opyn and Hegic
contract DeriOne is Ownable {
    using SafeMath for uint256;

    IETHPriceOracle private IETHPriceOracleInstance;
    IHegicETHOptionV888 private IHegicETHOptionV888Instance;
    IHegicETHPoolV888 private IHegicETHPoolV888Instance;
    IOpynExchangeV1 private IOpynExchangeV1Instance;
    IOpynOptionsFactoryV1 private IOpynOptionsFactoryV1Instance;
    IOpynOTokenV1 private IOpynOTokenV1Instance;

    address constant USDCTokenAddress = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48;
    address constant WETHTokenAddress = 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;

    address oTokenAddressList [];
    address WETHPutOptionOTokenAddressList [];
    address filteredWETHPutOptionOTokenAddressList [];

    struct WETHPutOptionOTokensV1 {
        address address;
        uint256 expiry;
        uint256 strike;
        uint256 premium;
    }
    WETHPutOptionOTokensV1[] WETHPutOptionOTokenListV1;
    WETHPutOptionOTokensV1[] filteredWETHPutOptionOTokenListV1;

    struct TheCheapestWETHPutOptionInOpynV1 {
        address oTokenAddress;
        address paymentTokenAddress;
        uint256 expiry;
        uint256 strike;
        uint256 amount;
        uint256 premium;
    }
    TheCheapestWETHPutOptionInOpynV1 theCheapestWETHPutOptionInOpynV1;

    struct TheCheapestETHPutOptionInHegicV888 {
        uint256 expiry;
        uint256 strike;
        uint256 amount;
        uint256 premium;
    }
    TheCheapestETHPutOptionInHegicV888 theCheapestETHPutOptionInHegicV888;

    struct TheCheapestETHPutOption {
        string protocol;
        address oTokenAddress;
        address paymentTokenAddress;
        uint256 expiry;
        uint256 strike;
        uint256 amount;
        uint256 premium;
    }
    TheCheapestETHPutOption theCheapestETHPutOption;

    event NewETHPriceOracleAddressRegistered(address ETHPriceOracleAddress);
    event NewHegicETHOptionV888AddressRegistered(address hegicETHOptionV888Address);
    event NewHegicETHPoolV888AddressRegistered(address hegicETHPoolV888Address);
    event NewOpynExchangeV1AddressRegistered(address opynExchangeV1Address);
    event NewOpynOptionsFactoryV1AddressRegistered(address opynOptionsFactoryV1Address);
    event NewOpynOTokenV1AddressRegistered(address opynOTokenV1Address);
    constructor(_ETHPriceOracleAddress, _hegicETHOptionV888Address, _hegicETHPoolV888Address, _opynExchangeV1Address, _opynOptionsFactoryV1Address, _opynOTokenV1Address) {
        setETHPriceOracleAddress(_ETHPriceOracleAddress);
        setHegicETHOptionV888Address(_hegicETHOptionV888Address);
        setHegicETHPoolV888Address(_hegicETHPoolV888Address);
        setOpynExchangeV1Address(_opynExchangeV1Address);
        setOpynOptionsFactoryV1Address(_opynOptionsFactoryV1Address);
        setOpynOTokenV1Address(_opynOTokenV1Address)
    }

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

    setHegicETHPoolV888Address(address _hegicETHPoolV888Address) public onlyOwner {
        hegicETHPoolV888Address = _hegicETHPoolV888Address;
        IHegicETHPoolV888Instance = IHegicETHPoolV888(hegicETHPoolV888Address);

        emit NewHegicETHPoolV888AddressRegistered(hegicETHPoolV888Address);
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

    function constructFilteredWETHPutOptionOTokenListV1() {
        for (uint i = 0; i < filteredWETHPutOptionOTokenAddressList.length; i++) {
            IOpynOTokenV1Instance = setOpynOTokenV1Address(filteredWETHPutOptionOTokenAddressList[i]);
            filteredWETHPutOptionOTokenListV1[i].address = filteredWETHPutOptionOTokenAddressList[i];
            filteredWETHPutOptionOTokenListV1[i].expiry = IOpynOTokenV1Instance._expiry;
            filteredWETHPutOptionOTokenListV1[i].strike = IOpynOTokenV1Instance._strikePrice;
            filteredWETHPutOptionOTokenListV1[i].premium = getOpynV1Premium(IOpynOTokenV1Instance._expiry, IOpynOTokenV1Instance._strikePrice);
        }
    }
    
    function getTheCheapestETHPutOptionInOpynV1() {
        uint256 minimumPremium = filteredWETHPutOptionOTokenListV1[0].premium;
        for (uint256 i = 0; i < filteredWETHPutOptionOTokenListV1.length; i++) {
            if(filteredWETHPutOptionOTokenListV1[i].premium > filteredWETHPutOptionOTokenListV1[i + 1].premium) {
                minimumPremium = filteredWETHPutOptionOTokenListV1[i + 1].premium;
            }
        }

        for (uint256 i = 0; i < filteredWETHPutOptionOTokenListV1.length; i++) {
            if(minimumPremium == filteredWETHPutOptionOTokenListV1[i].premium) {
                theCheapestWETHPutOptionInOpynV1 = filteredWETHPutOptionOTokenListV1[i];
                theCheapestWETHPutOptionInOpynV1.premium = minimumPremium;
            }
        }        
    }

    /// @notice get the implied volatility
    function getHegicImpliedVolatility()　{
        uint256 impliedVolatilityRate = IHegicETHOptionV888Instance.impliedVolRate();
        return impliedVolatilityRate;
    }

    /// @notice get the underlying asset price
    function getHegicETHPrice()　{
        (, int latestPrice, , , ) = IETHPriceOracleInstance.latestRoundData();
        uint256 ETHPrice = uint256(latestPrice);
        return ETHPrice;
    }

    /// @notice babylonian method
    /// @param y unsigned integer 256
    /// modified https://github.com/Uniswap/uniswap-v2-core/blob/4dd59067c76dea4a0e8e4bfdda41877a6b16dedc/contracts/libraries/Math.sol#L11
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y.div(2) + 1;
            while (x < z) {
                z = x;
                x = (y.div(x) + x).div(2);
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /// @notice calculate the premium and get the cheapest ETH put option in Hegic v888
    /// @param expiry expiration date
    /// @param strike strike/execution price
    /// @dev use the safemath library
    function getHegicPremium(expiry, strike) {
        uint256 impliedVolatility = getHegicImpliedVolatility();
        uint256 ETHPrice = getETHPrice();
        uint256 premiumToPayInETH = sqrt(expiry).mul(impliedVolatility).mul(strike.div(ETHPrice));
        return premiumToPayInETH;
    function getTheCheapestETHPutOptionInHegicV888(uint256 minExpiry, uint256 minStrike) {
        uint256 impliedVolatility = getHegicV888ImpliedVolatility();
        uint256 ETHPrice = getHegicV888ETHPrice();
        uint256 minimumPremiumToPayInETH = sqrt(minExpiry).mul(impliedVolatility).mul(minStrike.div(ETHPrice));
        theCheapestETHPutOptionInHegicV888.premium = minimumPremiumToPayInETH;
        theCheapestETHPutOptionInHegicV888.expiry = minExpiry;
        theCheapestETHPutOptionInHegicV888.strike = minStrike;
        // does minExpiry and minStrike always give the cheapest premium? why? is this true?
    }

    /// @dev you need to think how premium is denominated. in opyn, it is USDC? in hegic, it's WETH?
    function getTheCheapestETHPutOption() {
        if (theCheapestETHPutOptionInHegicV888.premium > theCheapestWETHPutOptionInOpynV1.premium) {
            theCheapestETHPutOption = theCheapestETHPutOptionInHegicV888;
            theCheapestETHPutOption.protocol = "hegicV888";
        } else if (theCheapestETHPutOptionInHegicV888.premium < theCheapestWETHPutOptionInOpynV1.premium) {
            theCheapestETHPutOption = theCheapestWETHPutOptionInOpynV1;
            theCheapestETHPutOption.protocol = "opynV1";
        } else {
            
        } 
    }

    /// @notice creates a new option in Hegic V888
    /// @param expiry option period in seconds (1 days <= period <= 4 weeks)
    /// @param amount option amount
    /// @param strike strike price of the option
    function BuyETHPutOptionInHegicV888(uint256 expiry, uint256 amount, uint256 strike) {
        IHegicETHOptionV888Instance.create(expiry, amount, strike, OptionType.Put);
    }

    /// @notice buy an ETH put option in Opyn V1 
    /// @param receiver the account that will receive the oTokens
    /// @param oTokenAddress the address of the oToken that is being bought
    /// @param paymentTokenAddress the address of the token you are paying for oTokens with
    /// @param oTokensToBuy the number of oTokens to buy
    function BuyETHPutOptionInOpynV1(address receiver, address oTokenAddress, address paymentTokenAddress, uint256 oTokensToBuy) {
        IOpynExchangeV1Instance.buyOTokens(receiver, oTokenAddress, paymentTokenAddress, oTokensToBuy)
    }


    /// @notice check if there is enough liquidity in Hegic pool
    /// @param optionSize the size of an option to buy
    function hasEnoughETHLiquidityInHegicV888(uint256 optionSize) {
        uint256 maxOptionSize = IHegicETHPoolV888Instance.totalBalance().mul(0.8) - (IHegicETHPoolV888Instance.totalBalance() - IHegicETHPoolV888Instance.lockedAmount());
        if(maxOptionSize > optionSize ){
            return true;
        } else if (maxOptionSize <= optionSize ) {
            return false;
        }
    }

    /// @notice check if there is enough liquidity in Opyn pool
    function hasEnoughETHLiquidityInOpynV1(uint256 optionSizeInETH) {
        uint256 oTokenLiquidity = IOpynOTokenV1Instance.
        uint256 optionSizeInOToken = optionSizeInETH.mul(IOpynOTokenV1Instance.oTokenExchangeRate());
        if (oTokenLiquidity > 0) {
            return true;
        } else {
            return false;
        }
        // optionSize needs to be smaller than oTokenLiquidity and that is in ETH
    }

    /// @notice buy the best ETH put option 
    /// @param receiver the account that will receive the oTokens
    function buyTheCheapestETHPutOption(receiver) {
        getTheCheapestETHPutOption();
        if(theCheapestETHPutOption.protocol == "hegicV888") {
            require(hasEnoughETHLiquidityInHegicV888(theCheapestETHPutOption.amount) == true, "your size is too big");
            BuyETHPutOptionInHegicV888(theCheapestETHPutOption.expiry, theCheapestETHPutOption.amount, theCheapestETHPutOption.strike);
        } else if(theCheapestETHPutOption.protocol == "opynV1") {
            require(hasEnoughETHLiquidityInOpynV1(theCheapestETHPutOption.amount) == true, "your size is too big");
            BuyETHPutOptionInOpynV1(receiver, theCheapestETHPutOption.oTokenAddress, theCheapestETHPutOption.paymentTokenAddress, theCheapestETHPutOption.amount);
        } else {
            // there is no options
        }
    }
}
