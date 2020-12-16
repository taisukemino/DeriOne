pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IETHPriceOracle.sol";
import "./interfaces/IHegicETHOptionV888.sol";
import "./interfaces/IHegicETHPoolV888.sol";
import "./interfaces/IOpynExchangeV1.sol";
import "./interfaces/IOpynOptionsFactoryV1.sol";
import "./interfaces/IOpynOTokenV1.sol";
import "./interfaces/IUniswapFactoryV1.sol";

/// @author tai
/// @title A contract for getting the cheapest options price
/// @notice For now, this contract gets the cheapest ETH/WETH put options price from Opyn and Hegic
contract DeriOne is Ownable {
    using SafeMath for uint256;

    IETHPriceOracle private IETHPriceOracleInstance;
    IHegicETHOptionV888 private IHegicETHOptionV888Instance;
    IHegicETHPoolV888 private IHegicETHPoolV888Instance;
    IOpynExchangeV1 private IOpynExchangeV1Instance;
    IOpynOptionsFactoryV1 private IOpynOptionsFactoryV1Instance;
    IOpynOTokenV1 private IOpynOTokenV1Instance;
    IUniswapFactoryV1 private IUniswapFactoryV1Instance;

    address constant USDCTokenAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETHTokenAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address[] private oTokenAddressList;
    address[] private WETHPutOptionOTokenAddressList;
    address[] private filteredWETHPutOptionOTokenAddressList;

    enum OptionType {Invalid, Put, Call}
    OptionType private optionType;

    struct WETHPutOptionOTokensV1 {
        address oTokenAddress;
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
    event NewHegicETHOptionV888AddressRegistered(
        address hegicETHOptionV888Address
    );
    event NewHegicETHPoolV888AddressRegistered(address hegicETHPoolV888Address);
    event NewOpynExchangeV1AddressRegistered(address opynExchangeV1Address);
    event NewOpynOptionsFactoryV1AddressRegistered(
        address opynOptionsFactoryV1Address
    );
    event NewOpynOTokenV1AddressRegistered(address opynOTokenV1Address);
    event NewUniswapFactoryV1AddressRegistered(address uniswapFactoryV1Address);
    event NotWETHPutOptionsOTokenAddress(address oTokenAddress);
    event NewOptionBought();

    constructor(
        address _ETHPriceOracleAddress,
        address _hegicETHOptionV888Address,
        address _hegicETHPoolV888Address,
        address _opynExchangeV1Address,
        address _opynOptionsFactoryV1Address,
        address _opynOTokenV1Address,
        address _uniswapFactoryV1Address
    ) public {
        setETHPriceOracleAddress(_ETHPriceOracleAddress);
        setHegicETHOptionV888Address(_hegicETHOptionV888Address);
        setHegicETHPoolV888Address(_hegicETHPoolV888Address);
        setOpynExchangeV1Address(_opynExchangeV1Address);
        setOpynOptionsFactoryV1Address(_opynOptionsFactoryV1Address);
        setOpynOTokenV1Address(_opynOTokenV1Address);
        setUniswapFactoryV1Address(_uniswapFactoryV1Address);
    }

    /// @notice instantiate the ETHPriceOracle contract
    /// @param _ETHPriceOracleAddress ETHPriceOracleAddress
    function setETHPriceOracleAddress(address _ETHPriceOracleAddress)
        public
        onlyOwner
    {
        IETHPriceOracleInstance = IETHPriceOracle(_ETHPriceOracleAddress);
        emit NewETHPriceOracleAddressRegistered(_ETHPriceOracleAddress);
    }

    /// @notice instantiate the HegicETHOptionV888 contract
    /// @param _hegicETHOptionV888Address HegicETHOptionV888Address
    function setHegicETHOptionV888Address(address _hegicETHOptionV888Address)
        public
        onlyOwner
    {
        IHegicETHOptionV888Instance = IHegicETHOptionV888(
            _hegicETHOptionV888Address
        );
        emit NewHegicETHOptionV888AddressRegistered(_hegicETHOptionV888Address);
    }

    /// @notice instantiate the HegicETHPoolV888 contract
    /// @param _hegicETHPoolV888Address HegicETHPoolV888Address
    function setHegicETHPoolV888Address(address _hegicETHPoolV888Address)
        public
        onlyOwner
    {
        IHegicETHPoolV888Instance = IHegicETHPoolV888(_hegicETHPoolV888Address);
        emit NewHegicETHPoolV888AddressRegistered(_hegicETHPoolV888Address);
    }

    /// @notice instantiate the OpynExchangeV1 contract
    /// @param _opynExchangeV1Address OpynExchangeV1Address
    function setOpynExchangeV1Address(address _opynExchangeV1Address)
        public
        onlyOwner
    {
        IOpynExchangeV1Instance = IOpynExchangeV1(_opynExchangeV1Address);
        emit NewOpynExchangeV1AddressRegistered(_opynExchangeV1Address);
    }

    /// @notice instantiate the OpynOptionsFactoryV1 contract
    /// @param _opynOptionsFactoryV1Address OpynOptionsFactoryV1Address
    function setOpynOptionsFactoryV1Address(
        address _opynOptionsFactoryV1Address
    ) public onlyOwner {
        IOpynOptionsFactoryV1Instance = IOpynExchangeV1(
            _opynOptionsFactoryV1Address
        );
        emit NewOpynOptionsFactoryV1AddressRegistered(
            _opynOptionsFactoryV1Address
        );
    }

    /// @notice instantiate the OpynOTokenV1 contract
    /// @param _opynOTokenV1Address OpynOTokenV1Address
    function setOpynOTokenV1Address(address _opynOTokenV1Address)
        public
        onlyOwner
    {
        IOpynOTokenV1Instance = IOpynOTokenV1(_opynOTokenV1Address);
        emit NewOpynOTokenV1AddressRegistered(_opynOTokenV1Address);
    }

    /// @notice instantiate the UniswapFactoryV1 contract
    /// @param _uniswapFactoryV1Address UniswapFactoryV1Address
    function setUniswapFactoryV1Address(address _uniswapFactoryV1Address)
        public
        onlyOwner
    {
        IUniswapFactoryV1Instance = IUniswapFactoryV1(_uniswapFactoryV1Address);
        emit NewUniswapFactoryV1AddressRegistered(_uniswapFactoryV1Address);
    }

    /// @notice get the list of oToken addresses
    function _getOTokenAddressList() private {
        oTokenAddressList = IOpynOptionsFactoryV1Instance.optionsContracts();
    }

    /// @notice get the list of WETH put option oToken addresses
    /// @dev in the Opyn V1, there are only put options and thus no need to filter a type
    /// @dev we don't use ETH put options because the Opyn V1 has vulnerability there
    function _getWETHPutOptionsOTokenAddressList() private {
        for (uint256 i = 0; i < oTokenAddressList.length; i++) {
            IOpynOTokenV1Instance = setOpynOTokenV1Address(
                oTokenAddressList[i]
            );
            if (
                IOpynOTokenV1Instance.underlying() == WETHTokenAddress &&
                IOpynOTokenV1Instance.expiry() > block.timestamp
            ) {
                WETHPutOptionOTokenAddressList.push(oTokenAddressList[i]);
            } else {
                emit NotWETHPutOptionsOTokenAddress(oTokenAddressList[i]);
            }
        }
    }

    /// @notice get WETH Put Options that meet expiry and strike conditions
    /// @param minExpiry minimum expiration date
    /// @param maxExpiry maximum expiration date
    /// @param strike strike price
    function _filterWETHPutOptionsOTokenAddresses(
        uint256 minExpiry,
        uint256 maxExpiry,
        uint256 strike
    ) private {
        for (uint256 i = 0; i < WETHPutOptionOTokenListV1.length; i++) {
            IOpynOTokenV1Instance = setOpynOTokenV1Address(
                WETHPutOptionOTokenListV1[i]
            );
            if (
                minExpiry < IOpynOTokenV1Instance.expiry < maxExpiry &&
                IOpynOTokenV1Instance.strike == strike
            ) {
                filteredWETHPutOptionOTokenAddressList.push(
                    WETHPutOptionOTokenListV1[i]
                );
            }
        }
    }

    /// @notice get the premium in the Opyn V1
    /// @param expiry expiration date
    /// @param strike strike price
    function _getOpynV1Premium(
        uint256 expiry,
        uint256 strike,
        uint256 oTokensToBuy
    ) private {
        address oTokenAddress;
        for (uint256 i = 0; i < filteredWETHPutOptionOTokenListV1.length; i++) {
            if (
                filteredWETHPutOptionOTokenListV1[i].expiry == expiry &&
                filteredWETHPutOptionOTokenListV1[i].strike == strike
            ) {
                oTokenAddress = filteredWETHPutOptionOTokenListV1[i]
                    .oTokenAddress;
            } else {}
        }
        uint256 premiumToPayInETH = IOpynExchangeV1Instance.premiumToPay(
            oTokenAddress,
            address(0),
            oTokensToBuy
        );
        return premiumToPayInETH;
    }

    function _constructFilteredWETHPutOptionOTokenListV1() private {
        _filterWETHPutOptionsOTokenAddresses();
        for (
            uint256 i = 0;
            i < filteredWETHPutOptionOTokenAddressList.length;
            i++
        ) {
            IOpynOTokenV1Instance = setOpynOTokenV1Address(
                filteredWETHPutOptionOTokenAddressList[i]
            );
            filteredWETHPutOptionOTokenListV1[i]
                .oTokenAddress = filteredWETHPutOptionOTokenAddressList[i];
            filteredWETHPutOptionOTokenListV1[i].expiry = IOpynOTokenV1Instance
                ._expiry;
            filteredWETHPutOptionOTokenListV1[i].strike = IOpynOTokenV1Instance
                ._strikePrice;
            filteredWETHPutOptionOTokenListV1[i].premium = _getOpynV1Premium(
                IOpynOTokenV1Instance._expiry,
                IOpynOTokenV1Instance._strikePrice
            );
        }
    }

    function _getTheCheapestETHPutOptionInOpynV1() private {
        _constructFilteredWETHPutOptionOTokenListV1();
        uint256 minimumPremium = filteredWETHPutOptionOTokenListV1[0].premium;
        for (uint256 i = 0; i < filteredWETHPutOptionOTokenListV1.length; i++) {
            if (
                filteredWETHPutOptionOTokenListV1[i].premium >
                filteredWETHPutOptionOTokenListV1[i + 1].premium
            ) {
                minimumPremium = filteredWETHPutOptionOTokenListV1[i + 1]
                    .premium;
            }
        }

        for (uint256 i = 0; i < filteredWETHPutOptionOTokenListV1.length; i++) {
            if (
                minimumPremium == filteredWETHPutOptionOTokenListV1[i].premium
            ) {
                theCheapestWETHPutOptionInOpynV1 = filteredWETHPutOptionOTokenListV1[i];
                theCheapestWETHPutOptionInOpynV1.premium = minimumPremium;
            }
        }
    }

    /// @notice get the implied volatility
    function _getHegicV888ImpliedVolatility() private {
        uint256 impliedVolatilityRate = IHegicETHOptionV888Instance
            .impliedVolRate();
        return impliedVolatilityRate;
    }

    /// @notice get the underlying asset price
    function _getHegicV888ETHPrice() private {
        (, int256 latestPrice, , , ) = IETHPriceOracleInstance
            .latestRoundData();
        uint256 ETHPrice = uint256(latestPrice);
        return ETHPrice;
    }

    /// @notice babylonian method
    /// @param y unsigned integer 256
    /// modified https://github.com/Uniswap/uniswap-v2-core/blob/4dd59067c76dea4a0e8e4bfdda41877a6b16dedc/contracts/libraries/Math.sol#L11
    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y.div(2) + 1;
            while (x < z) {
                z = x;
                x = (y.div(x) + x).div(2);
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /// @notice calculate the premium and get the cheapest ETH put option in Hegic v888
    /// @param minExpiry minimum expiration date
    /// @param minStrike minimum strike price
    /// @dev does minExpiry and minStrike always give the cheapest premium? why? is this true?
    function _getTheCheapestETHPutOptionInHegicV888(
        uint256 minExpiry,
        uint256 minStrike
    ) private {
        uint256 impliedVolatility = _getHegicV888ImpliedVolatility();
        uint256 ETHPrice = _getHegicV888ETHPrice();
        uint256 minimumPremiumToPayInETH = _sqrt(minExpiry)
            .mul(impliedVolatility)
            .mul(minStrike.div(ETHPrice));
        theCheapestETHPutOptionInHegicV888.premium = minimumPremiumToPayInETH;
        theCheapestETHPutOptionInHegicV888.expiry = minExpiry;
        theCheapestETHPutOptionInHegicV888.strike = minStrike;
    }

    /// @dev you need to think how premium is denominated. in opyn, it is USDC? in hegic, it's WETH?
    function getTheCheapestETHPutOption() internal {
        _getTheCheapestETHPutOptionInOpynV1();
        _getTheCheapestETHPutOptionInHegicV888();
        if (
            theCheapestETHPutOptionInHegicV888.premium >
            theCheapestWETHPutOptionInOpynV1.premium
        ) {
            theCheapestETHPutOption = theCheapestETHPutOptionInHegicV888;
            theCheapestETHPutOption.protocol = "hegicV888";
        } else if (
            theCheapestETHPutOptionInHegicV888.premium <
            theCheapestWETHPutOptionInOpynV1.premium
        ) {
            theCheapestETHPutOption = theCheapestWETHPutOptionInOpynV1;
            theCheapestETHPutOption.protocol = "opynV1";
        } else {}
    }

    /// @notice creates a new option in Hegic V888
    /// @param expiry option period in seconds (1 days <= period <= 4 weeks)
    /// @param amount option amount
    /// @param strike strike price of the option
    function _buyETHPutOptionInHegicV888(
        uint256 expiry,
        uint256 amount,
        uint256 strike
    ) private {
        IHegicETHOptionV888Instance.create(
            expiry,
            amount,
            strike,
            optionType.Put
        );
    }

    /// @notice buy an ETH put option in Opyn V1
    /// @param receiver the account that will receive the oTokens
    /// @param oTokenAddress the address of the oToken that is being bought
    /// @param paymentTokenAddress the address of the token you are paying for oTokens with
    /// @param oTokensToBuy the number of oTokens to buy
    function _buyETHPutOptionInOpynV1(
        address receiver,
        address oTokenAddress,
        address paymentTokenAddress,
        uint256 oTokensToBuy
    ) private {
        IOpynExchangeV1Instance.buyOTokens(
            receiver,
            oTokenAddress,
            paymentTokenAddress,
            oTokensToBuy
        );
    }

    /// @notice check if there is enough liquidity in Hegic pool
    /// @param optionSizeInETH the size of an option to buy in ETH
    function _hasEnoughETHLiquidityInHegicV888(uint256 optionSizeInETH)
        private
    {
        uint256 maxOptionSize = IHegicETHPoolV888Instance.totalBalance().mul(
            0.8
        ) -
            (IHegicETHPoolV888Instance.totalBalance() -
                IHegicETHPoolV888Instance.lockedAmount());
        if (maxOptionSize > optionSizeInETH) {
            return true;
        } else if (maxOptionSize <= optionSizeInETH) {
            return false;
        }
    }

    /// @notice check if there is enough liquidity in Opyn V1 pool
    /// @param optionSizeInETH the size of an option to buy in ETH
    function _hasEnoughOTokenLiquidityInOpynV1(uint256 optionSizeInETH)
        private
    {
        address uniswapExchangeContractAddress = IUniswapFactoryV1Instance
            .getExchange(theCheapestETHPutOption.oTokenAddress);
        IOpynOTokenV1Instance = setOpynOTokenV1Address(
            theCheapestETHPutOption.oTokenAddress
        );
        uint256 oTokenLiquidity = IOpynOTokenV1Instance.balanceOf(
            uniswapExchangeContractAddress
        );
        uint256 optionSizeInOToken = optionSizeInETH.mul(
            IOpynOTokenV1Instance.oTokenExchangeRate()
        );
        if (0 < optionSizeInOToken < oTokenLiquidity) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice buy the cheapest ETH put option
    /// @param receiver the account that will receive the oTokens
    function buyTheCheapestETHPutOption(address receiver) public {
        getTheCheapestETHPutOption();
        if (theCheapestETHPutOption.protocol == "hegicV888") {
            require(
                _hasEnoughETHLiquidityInHegicV888(
                    theCheapestETHPutOption.amount
                ) == true,
                "your size is too big"
            );
            _buyETHPutOptionInHegicV888(
                theCheapestETHPutOption.expiry,
                theCheapestETHPutOption.amount,
                theCheapestETHPutOption.strike
            );
        } else if (theCheapestETHPutOption.protocol == "opynV1") {
            require(
                _hasEnoughOTokenLiquidityInOpynV1(
                    theCheapestETHPutOption.amount
                ) == true,
                "your size is too big"
            );
            _buyETHPutOptionInOpynV1(
                receiver,
                theCheapestETHPutOption.oTokenAddress,
                theCheapestETHPutOption.paymentTokenAddress,
                theCheapestETHPutOption.amount
            );
        } else {
            // there is no options
        }
    }
}
