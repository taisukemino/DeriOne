// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./DeriOneV1HegicV888.sol";
import "./DeriOneV1OpynV1.sol";

/// @author tai
/// @title A contract for getting the cheapest options price
/// @notice For now, this contract gets the cheapest ETH/WETH put options price from Opyn and Hegic
/// @dev can i put a contract instance in struct?
contract DeriOneV1Main is DeriOneV1HegicV888, DeriOneV1OpynV1 {
    enum Protocol {HegicV888, OpynV1}
    struct TheCheapestETHPutOption {
        Protocol protocol;
        address oTokenAddress;
        address paymentTokenAddress;
        uint256 expiry;
        uint256 strike; // which token?
        uint256 premium; // which token?
        uint256 optionSizeInWEI;
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

    /// @dev you need to think how premium is denominated. in opyn, it is USDC? in hegic, it's WETH?
    function getTheCheapestETHPutOption(
        uint256 _minExpiry,
        uint256 _maxExpiry,
        uint256 _minStrike,
        uint256 _maxStrike,
        uint256 _optionSizeInWEI
    ) public {
        getTheCheapestETHPutOptionInHegicV888(
            _minExpiry,
            _minStrike,
            _optionSizeInWEI
        );
        getTheCheapestETHPutOptionInOpynV1(
            _minExpiry,
            _maxExpiry,
            _minStrike,
            _maxStrike,
            _optionSizeInWEI
        );
        if (
            theCheapestETHPutOptionInHegicV888.premium <
            theCheapestWETHPutOptionInOpynV1.premium
        ) {
            theCheapestETHPutOption = TheCheapestETHPutOption(
                Protocol.HegicV888,
                address(0),
                address(0),
                theCheapestETHPutOptionInHegicV888.expiry,
                theCheapestETHPutOptionInHegicV888.strike,
                theCheapestETHPutOptionInHegicV888.premium,
                0
            );
            emit TheCheapestETHPutOptionGot("hegic v888");
        } else if (
            theCheapestETHPutOptionInHegicV888.premium >
            theCheapestWETHPutOptionInOpynV1.premium
        ) {
            theCheapestETHPutOption = TheCheapestETHPutOption(
                Protocol.OpynV1,
                theCheapestWETHPutOptionInOpynV1.oTokenAddress,
                address(0),
                theCheapestWETHPutOptionInOpynV1.expiry,
                theCheapestWETHPutOptionInOpynV1.strike,
                theCheapestWETHPutOptionInOpynV1.premium,
                0
            );
            emit TheCheapestETHPutOptionGot("opyn v1");
        } else {
            emit TheCheapestETHPutOptionGot("no matches");
        }
    }

    function buyTheCheapestETHPutOption(
        uint256 _minExpiry,
        uint256 _maxExpiry,
        uint256 _minStrike,
        uint256 _maxStrike,
        uint256 _optionSizeInWEI,
        address _receiver
    ) public {
        getTheCheapestETHPutOption(
            _minExpiry,
            _maxExpiry,
            _minStrike,
            _maxStrike,
            _optionSizeInWEI
        );
        if (theCheapestETHPutOption.protocol == Protocol.HegicV888) {
            buyETHPutOptionInHegicV888(
                theCheapestETHPutOption.expiry,
                theCheapestETHPutOption.optionSizeInWEI,
                theCheapestETHPutOption.strike
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
// how do you compare options?
// what happens after our user buy? don't they want to exercise?
// we could make two functions: one gets some options and the other gets only one option
// console log solidity https://medium.com/nomic-labs-blog/better-solidity-debugging-console-log-is-finally-here-fc66c54f2c4a
// event, logx or
// truffle console log?
// make two functions. one that takes a range and the other that takes a fixed value. what to return when there is none?
// ask them: mazzi, gammahammer are both options traders irl. attm is a maths phd that prices options for living
// there are two functions: fixed expiry and strike function. in opyn, it is either nothing or exist. in hegic, it always returns only one.
// fixed values: in opyn, it is like that you can get options. in hegic, np.
// people perhaps want to buy the most liquid one so that they can make sure that they can sell it later?
// specify data location
// enforce state changes of state variables with a function by adding a storage keyword? i dont think so.
// why say memory or calldata in a parameter?
// calldata and stack dont understand
// value type and reference type?
// stack and heap?
// think of a new way to structure your variables
// you cannot rely on abi to interface converter. it is not good. i made more than enough mistakes in the interfaces.
// explicitly state the data location for all variables of struct, array or mapping types (including function parameters)
// adjust visibility of variables. they should be all private by default i guess
// the way i handle otoken instances are wrong. this needs to be fixed.

// What to do with that strikePrice that returns two values. What do they do?
//    /* represents floting point numbers, where number = value * 10 ** exponent
//     i.e 0.1 = 10 * 10 ** -3 */
//     struct Number {
//         uint256 value;
//         int32 exponent;
//     }

// refer to uniswap factory contract to manage registry?

// inheritance contract, abstract contract

// i need to figure out how to convert between otoken and wei

// how to deal with floating number exchange rate. can i use bignumber?

// can i declare a variable or struct to convert it for calculation?

// gas optimization. what consumes a lot of gas?

// you can generalize this to support more tokens and calls

// support more protocols

// how do you expand from here?

// support opyn v2
