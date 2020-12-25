// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IETHPriceOracle.sol";
import "./interfaces/IHegicETHOptionV888.sol";
import "./interfaces/IHegicETHPoolV888.sol";
import "./libraries/Math.sol";

contract DeriOneV1HegicV888 is Ownable {
    using SafeMath for uint256;

    IETHPriceOracle private ETHPriceOracleInstance;
    IHegicETHOptionV888 private HegicETHOptionV888Instance;
    IHegicETHPoolV888 private HegicETHPoolV888Instance;

    IHegicETHOptionV888.OptionType constant putOptionType =
        IHegicETHOptionV888.OptionType.Put;
    IHegicETHOptionV888.OptionType constant callOptionType =
        IHegicETHOptionV888.OptionType.Call;

    struct TheCheapestETHPutOptionInHegicV888 {
        uint256 expiry;
        uint256 strike;
        uint256 premium;
    }
    TheCheapestETHPutOptionInHegicV888 theCheapestETHPutOptionInHegicV888;

    event NewETHPriceOracleAddressRegistered(address ETHPriceOracleAddress);
    event NewHegicETHOptionV888AddressRegistered(
        address hegicETHOptionV888Address
    );
    event NewHegicETHPoolV888AddressRegistered(address hegicETHPoolV888Address);

    constructor(
        address _ETHPriceOracleAddress,
        address _hegicETHOptionV888Address,
        address _hegicETHPoolV888Address
    ) public {
        instantiateETHPriceOracle(_ETHPriceOracleAddress);
        instantiateHegicETHOptionV888(_hegicETHOptionV888Address);
        instantiateHegicETHPoolV888(_hegicETHPoolV888Address);
    }

    /// @notice instantiate the ETHPriceOracle contract
    /// @param _ETHPriceOracleAddress ETHPriceOracleAddress
    function instantiateETHPriceOracle(address _ETHPriceOracleAddress)
        public
        onlyOwner
    {
        ETHPriceOracleInstance = IETHPriceOracle(_ETHPriceOracleAddress);
        emit NewETHPriceOracleAddressRegistered(_ETHPriceOracleAddress);
    }

    /// @notice instantiate the HegicETHOptionV888 contract
    /// @param _hegicETHOptionV888Address HegicETHOptionV888Address
    function instantiateHegicETHOptionV888(address _hegicETHOptionV888Address)
        public
        onlyOwner
    {
        HegicETHOptionV888Instance = IHegicETHOptionV888(
            _hegicETHOptionV888Address
        );
        emit NewHegicETHOptionV888AddressRegistered(_hegicETHOptionV888Address);
    }

    /// @notice instantiate the HegicETHPoolV888 contract
    /// @param _hegicETHPoolV888Address HegicETHPoolV888Address
    function instantiateHegicETHPoolV888(address _hegicETHPoolV888Address)
        public
        onlyOwner
    {
        HegicETHPoolV888Instance = IHegicETHPoolV888(_hegicETHPoolV888Address);
        emit NewHegicETHPoolV888AddressRegistered(_hegicETHPoolV888Address);
    }

    /// @notice get the implied volatility
    function _getHegicV888ImpliedVolatility() private view returns (uint256) {
        uint256 impliedVolatilityRate =
            HegicETHOptionV888Instance.impliedVolRate();
        return impliedVolatilityRate;
    }

    /// @notice get the underlying asset price
    function _getHegicV888ETHPrice() private view returns (uint256) {
        (, int256 latestPrice, , , ) = ETHPriceOracleInstance.latestRoundData();
        uint256 ETHPrice = uint256(latestPrice);
        return ETHPrice;
    }

    /// @notice check if there is enough liquidity in Hegic pool
    /// @param _optionSizeInWEI the size of an option to buy in WEI
    function _hasEnoughETHLiquidityInHegicV888(uint256 _optionSizeInWEI)
        private
        view
        returns (bool)
    {
        uint256 maxOptionSize =
            HegicETHPoolV888Instance.totalBalance().mul(8).div(10) -
                (HegicETHPoolV888Instance.totalBalance() -
                    HegicETHPoolV888Instance.lockedAmount());
        if (maxOptionSize > _optionSizeInWEI) {
            return true;
        } else if (maxOptionSize <= _optionSizeInWEI) {
            return false;
        }
    }

    /// @notice calculate the premium and get the cheapest ETH put option in Hegic v888
    /// @param _minExpiry minimum expiration date
    /// @param _minStrike minimum strike price
    /// @param _optionSizeInWEI option size in WEI
    /// @dev does _minExpiry and _minStrike always give the cheapest premium? why? is this true?
    function getTheCheapestETHPutOptionInHegicV888(
        uint256 _minExpiry,
        uint256 _minStrike,
        uint256 _optionSizeInWEI
    ) internal {
        require(
            _hasEnoughETHLiquidityInHegicV888(_optionSizeInWEI) == true,
            "your size is too big for liquidity in the Hegic V888"
        );
        uint256 impliedVolatility = _getHegicV888ImpliedVolatility();
        uint256 ETHPrice = _getHegicV888ETHPrice();
        uint256 minimumPremiumToPayInWEI =
            Math.sqrt(_minExpiry).mul(impliedVolatility).mul(
                _minStrike.div(ETHPrice)
            );
        theCheapestETHPutOptionInHegicV888 = TheCheapestETHPutOptionInHegicV888(
            minimumPremiumToPayInWEI,
            _minExpiry,
            _minStrike
        );
    }

    /// @notice creates a new option in Hegic V888
    /// @param _expiry option period in seconds (1 days <= period <= 4 weeks)
    /// @param _amount option amount
    /// @param _strike strike price of the option
    function buyETHPutOptionInHegicV888(
        uint256 _expiry,
        uint256 _amount,
        uint256 _strike
    ) internal {
        HegicETHOptionV888Instance.create(
            _expiry,
            _amount,
            _strike,
            putOptionType
        );
    }
}
