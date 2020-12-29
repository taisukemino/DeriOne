// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./DeriOneV1HegicV888.sol";
import "./DeriOneV1OpynV1.sol";

/// @author tai
/// @title A contract for getting the cheapest options price
/// @notice For now, this contract gets the cheapest ETH/WETH put options price from Opyn and Hegic
contract DeriOneV1Main is DeriOneV1HegicV888, DeriOneV1OpynV1 {
    enum Protocol {HegicV888, OpynV1}
    struct TheCheapestETHPutOption {
        Protocol protocol;
        address oTokenAddress;
        address paymentTokenAddress;
        uint256 expiry;
        uint256 optionSizeInWEI;
        uint256 premiumInWEI;
        uint256 strikeInUSD;
    }

    // the cheapest ETH put option across options protocols
    TheCheapestETHPutOption theCheapestETHPutOption;

    event TheCheapestETHPutOptionGot(string protocolName);
    event ETHPutOptionBought(string protocolName);

    constructor(
        address _ETHPriceOracleAddress,
        address _hegicETHOptionV888Address,
        address _hegicETHPoolV888Address,
        address _opynExchangeV1Address,
        address _opynOptionsFactoryV1Address,
        address _uniswapFactoryV1Address
    )
        public
        DeriOneV1HegicV888(
            _ETHPriceOracleAddress,
            _hegicETHOptionV888Address,
            _hegicETHPoolV888Address
        )
        DeriOneV1OpynV1(
            _opynExchangeV1Address,
            _opynOptionsFactoryV1Address,
            _uniswapFactoryV1Address
        )
    {}

    /// @dev what is decimal place of usd value?
    function getTheCheapestETHPutOption(
        uint256 _minExpiry,
        uint256 _maxExpiry,
        uint256 _minStrikeInUSD,
        uint256 _maxStrikeInUSD,
        uint256 _optionSizeInWEI
    ) public {
        getTheCheapestETHPutOptionInHegicV888(
            _minExpiry,
            _minStrikeInUSD,
            _optionSizeInWEI
        );
        getTheCheapestETHPutOptionInOpynV1(
            _minExpiry,
            _maxExpiry,
            _minStrikeInUSD,
            _maxStrikeInUSD,
            _optionSizeInWEI
        );
        if (
            theCheapestETHPutOptionInHegicV888.premiumInWEI <
            theCheapestWETHPutOptionInOpynV1.premiumInWEI
        ) {
            theCheapestETHPutOption = TheCheapestETHPutOption(
                Protocol.HegicV888,
                address(0),
                address(0),
                theCheapestETHPutOptionInHegicV888.expiry,
                0,
                theCheapestETHPutOptionInHegicV888.premiumInWEI,
                theCheapestETHPutOptionInHegicV888.strikeInUSD
            );
            emit TheCheapestETHPutOptionGot("hegic v888");
        } else if (
            theCheapestETHPutOptionInHegicV888.premiumInWEI >
            theCheapestWETHPutOptionInOpynV1.premiumInWEI
        ) {
            theCheapestETHPutOption = TheCheapestETHPutOption(
                Protocol.OpynV1,
                theCheapestWETHPutOptionInOpynV1.oTokenAddress,
                address(0),
                theCheapestWETHPutOptionInOpynV1.expiry,
                0,
                theCheapestWETHPutOptionInOpynV1.premiumInWEI,
                theCheapestWETHPutOptionInOpynV1.strikeInUSD
            );
            emit TheCheapestETHPutOptionGot("opyn v1");
        } else {
            emit TheCheapestETHPutOptionGot("no matches");
        }
    }

    function buyTheCheapestETHPutOption(
        uint256 _minExpiry,
        uint256 _maxExpiry,
        uint256 _minStrikeInUSD,
        uint256 _maxStrikeInUSD,
        uint256 _optionSizeInWEI,
        address _receiver
    ) public {
        getTheCheapestETHPutOption(
            _minExpiry,
            _maxExpiry,
            _minStrikeInUSD,
            _maxStrikeInUSD,
            _optionSizeInWEI
        );
        if (theCheapestETHPutOption.protocol == Protocol.HegicV888) {
            buyETHPutOptionInHegicV888(
                theCheapestETHPutOption.expiry,
                theCheapestETHPutOption.optionSizeInWEI,
                theCheapestETHPutOption.strikeInUSD
            );
            emit ETHPutOptionBought("Hegic v888");
        } else if (theCheapestETHPutOption.protocol == Protocol.OpynV1) {
            buyETHPutOptionInOpynV1(
                _receiver,
                theCheapestETHPutOption.oTokenAddress,
                theCheapestETHPutOption.paymentTokenAddress,
                theCheapestETHPutOption.optionSizeInWEI
            );
            emit ETHPutOptionBought("opyn v1");
        } else {
            emit ETHPutOptionBought("no match");
        }
    }
}

// watch new eth put options being created? we could do this every time a user calls and update the list?
// we could make two functions: one gets some options and the other gets only one option
// make two functions. one that takes a range and the other that takes a fixed value. what to return when there is none?
// there are two functions: fixed expiry and strike function. in opyn, it is either nothing or exist. in hegic, it always returns only one.
// fixed values: in opyn, it is like that you can get options. in hegic, np.
// explicitly state the data location for all variables of struct, array or mapping types (including function parameters)
// adjust visibility of variables. they should be all private by default i guess
// the way i handle otoken instances are wrong. this needs to be fixed.
// can i declare a variable or struct to convert it for calculation?
// gas optimization. what consumes a lot of gas?
// check all the value and see which currency it is denominated
