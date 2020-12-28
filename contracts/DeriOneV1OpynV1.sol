// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IOpynExchangeV1.sol";
import "./interfaces/IOpynOptionsFactoryV1.sol";
import "./interfaces/IOpynOTokenV1.sol";
import "./interfaces/IUniswapFactoryV1.sol";

contract DeriOneV1OpynV1 is Ownable {
    using SafeMath for uint256;

    IOpynExchangeV1 private OpynExchangeV1Instance;
    IOpynOptionsFactoryV1 private OpynOptionsFactoryV1Instance;
    IOpynOTokenV1[] private oTokenV1InstanceList;
    IOpynOTokenV1[] private WETHPutOptionOTokenV1InstanceList;
    IOpynOTokenV1[] private matchedWETHPutOptionOTokenV1InstanceList;
    IUniswapFactoryV1 private UniswapFactoryV1Instance;

    address constant USDCTokenAddress =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETHTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address[] private oTokenAddressList;
    address[] private unexpiredOTokenAddressList;

    struct MatchedWETHPutOptionOTokenV1 {
        address oTokenAddress;
        uint256 expiry;
        uint256 strikeInUSD; // need to do 10**7 to get the actual usd value. but what if it is not 10**7? it could be 10**8 depending on the values passed at the point of otoken contract deployment. is this because they use USDC? yes, their decimals are 6. you can get the strike underlying asset? and then get their decimal?
        uint256 premiumInWEI;
    }

    struct TheCheapestWETHPutOptionInOpynV1 {
        address oTokenAddress;
        uint256 expiry;
        uint256 strikeInUSD; // need to do 10**7 to get the actual usd value. but what if it is not 10**7? it could be 10**8 depending on the values passed at the point of otoken contract deployment. is this because they use USDC? yes, their decimals are 6.  you can get the strike underlying asset? and then get their decimal? this is scaled by 1e9 to avoid floating numbers.
        uint256 premiumInWEI;
    }

    // a matched oToken list with a buyer's expiry and strike price conditions
    // strike value is scaled by 1e9
    MatchedWETHPutOptionOTokenV1[] matchedWETHPutOptionOTokenListV1;

    // the cheaptest WETH put option in the Opyn V1
    TheCheapestWETHPutOptionInOpynV1 theCheapestWETHPutOptionInOpynV1;

    constructor(
        address _opynExchangeV1Address,
        address _opynOptionsFactoryV1Address,
        address _uniswapFactoryV1Address
    ) public {
        instantiateOpynExchangeV1(_opynExchangeV1Address);
        instantiateOpynOptionsFactoryV1(_opynOptionsFactoryV1Address);
        instantiateUniswapFactoryV1(_uniswapFactoryV1Address);
    }

    /// @notice instantiate the OpynExchangeV1 contract
    /// @param _opynExchangeV1Address OpynExchangeV1Address
    function instantiateOpynExchangeV1(address _opynExchangeV1Address)
        public
        onlyOwner
    {
        OpynExchangeV1Instance = IOpynExchangeV1(_opynExchangeV1Address);
    }

    /// @notice instantiate the OpynOptionsFactoryV1 contract
    /// @param _opynOptionsFactoryV1Address OpynOptionsFactoryV1Address
    function instantiateOpynOptionsFactoryV1(
        address _opynOptionsFactoryV1Address
    ) public onlyOwner {
        OpynOptionsFactoryV1Instance = IOpynOptionsFactoryV1(
            _opynOptionsFactoryV1Address
        );
    }

    /// @notice instantiate the UniswapFactoryV1 contract
    /// @param _uniswapFactoryV1Address UniswapFactoryV1Address
    function instantiateUniswapFactoryV1(address _uniswapFactoryV1Address)
        public
        onlyOwner
    {
        UniswapFactoryV1Instance = IUniswapFactoryV1(_uniswapFactoryV1Address);
    }

    /// @notice instantiate the OpynOTokenV1 contract
    /// @param _opynOTokenV1AddressList OpynOTokenV1Address
    function _instantiateOpynOTokenV1(address[] memory _opynOTokenV1AddressList)
        private
    {
        for (uint256 i = 0; i < _opynOTokenV1AddressList.length; i++) {
            oTokenV1InstanceList.push(
                IOpynOTokenV1(_opynOTokenV1AddressList[i])
            );
        }
    }

    /// @notice get the list of WETH put option oToken addresses
    /// @dev in the Opyn V1, there are only put options and thus no need to filter a type
    /// @dev we don't use ETH put options because the Opyn V1 has vulnerability there
    function _getWETHPutOptionsOTokenAddressList() private {
        oTokenAddressList = OpynOptionsFactoryV1Instance.optionsContracts();
        _instantiateOpynOTokenV1(oTokenAddressList);
        for (uint256 i = 0; i < oTokenV1InstanceList.length; i++) {
            if (
                oTokenV1InstanceList[i].underlying() == WETHTokenAddress &&
                oTokenV1InstanceList[i].expiry() > block.timestamp
            ) {
                WETHPutOptionOTokenV1InstanceList.push(oTokenV1InstanceList[i]);
                unexpiredOTokenAddressList[i] = oTokenAddressList[i];
            }
        }
    }

    /// @notice get WETH Put Options that meet expiry and strike conditions
    /// @param _minExpiry minimum expiration date
    /// @param _maxExpiry maximum expiration date
    /// @param _minStrike minimum strike price
    /// @param _maxStrike maximum strike price
    function _filterWETHPutOptionsOTokenAddresses(
        uint256 _minExpiry,
        uint256 _maxExpiry,
        uint256 _minStrike,
        uint256 _maxStrike
    ) private {
        for (uint256 i = 0; i < WETHPutOptionOTokenV1InstanceList.length; i++) {
            uint256 strike;
            (uint256 value, int32 exponent) =
                WETHPutOptionOTokenV1InstanceList[i].strikePrice();
            if (exponent >= 0) {
                strike = value.mul(uint256(10)**uint256(exponent)).mul(10**9);
            } else {
                strike = value
                    .mul(uint256(1).div(10**uint256(0 - exponent)))
                    .mul(10**9);
            }
            _minStrike.mul(10**9);
            // this could be done somewhere else for the sake of making the code DRY.

            if (
                _minStrike < strike &&
                strike < _maxStrike &&
                _minExpiry < WETHPutOptionOTokenV1InstanceList[i].expiry() &&
                WETHPutOptionOTokenV1InstanceList[i].expiry() < _maxExpiry
            ) {
                matchedWETHPutOptionOTokenV1InstanceList.push(
                    WETHPutOptionOTokenV1InstanceList[i]
                );
                matchedWETHPutOptionOTokenListV1[i]
                    .oTokenAddress = unexpiredOTokenAddressList[i];
            }
        }
    }

    /// @notice get the premium in the Opyn V1
    /// @param _expiry expiration date
    /// @param _strike strike price
    /// @param _oTokensToBuy the amount of oToken to buy
    function _getOpynV1Premium(
        uint256 _expiry,
        uint256 _strike,
        uint256 _oTokensToBuy
    ) private view returns (uint256) {
        address oTokenAddress;
        for (
            uint256 i = 0;
            i < matchedWETHPutOptionOTokenV1InstanceList.length;
            i++
        ) {
            uint256 strikePrice;
            (uint256 value, int32 exponent) =
                matchedWETHPutOptionOTokenV1InstanceList[i].strikePrice();
            if (exponent >= 0) {
                strikePrice = value.mul(uint256(10)**uint256(exponent)).mul(
                    10**9
                );
            } else {
                strikePrice = value
                    .mul(uint256(1).div(10**uint256(0 - exponent)))
                    .mul(10**9);
            }
            _strike.mul(10**9);
            // this could be done somewhere else for the sake of making the code DRY.

            if (
                matchedWETHPutOptionOTokenV1InstanceList[i].expiry() ==
                _expiry &&
                strikePrice == _strike
            ) {
                oTokenAddress = matchedWETHPutOptionOTokenListV1[i]
                    .oTokenAddress;
            }
        }
        uint256 premiumToPayInWEI =
            OpynExchangeV1Instance.premiumToPay(
                oTokenAddress,
                address(0), // pay with ETH
                _oTokensToBuy
            );
        return premiumToPayInWEI;
    }

    /// @notice construct the matchedWETHPutOptionOTokenListV1
    /// @param _optionSizeInWEI the size of an option to buy in WEI
    function _constructMatchedWETHPutOptionOTokenListV1(
        uint256 _optionSizeInWEI
    ) private {
        for (uint256 i = 0; i < matchedWETHPutOptionOTokenListV1.length; i++) {
            uint256 strikePrice;
            (uint256 value, int32 exponent) =
                matchedWETHPutOptionOTokenV1InstanceList[i].strikePrice();
            if (exponent >= 0) {
                strikePrice = value.mul(uint256(10)**uint256(exponent)).mul(
                    10**9
                );
            } else {
                strikePrice = value
                    .mul(uint256(1).div(10**uint256(0 - exponent)))
                    .mul(10**9);
            }
            // this could be done somewhere else for the sake of making the code DRY.

            uint256 oTokensToBuy = _optionSizeInWEI.mul();
            // calculate the otokens to buy from the wei. get the exchange rate.

            matchedWETHPutOptionOTokenListV1[
                i
            ] = MatchedWETHPutOptionOTokenV1(
                matchedWETHPutOptionOTokenListV1[i].oTokenAddress,
                matchedWETHPutOptionOTokenV1InstanceList[i].expiry(),
                strikePrice,
                _getOpynV1Premium(
                    matchedWETHPutOptionOTokenV1InstanceList[i].expiry(),
                    strikePrice,
                    oTokensToBuy // this should be oToken amount right?
                )
            );
        }
    }

    /// @notice check if there is enough liquidity in Opyn V1 pool
    /// @param _optionSizeInWEI the size of an option to buy in WEI
    /// @dev write a function for power operations. it might overflow? the SafeMath library doesn't support this yet.
    /// @dev add 10**9 to oTokenExchangeRate because it can be a floating number
    function _hasEnoughOTokenLiquidityInOpynV1(uint256 _optionSizeInWEI)
        private
        returns (bool)
    {
        address uniswapExchangeContractAddress =
            UniswapFactoryV1Instance.getExchange(
                theCheapestWETHPutOptionInOpynV1.oTokenAddress
            );
        IOpynOTokenV1 theCheapestOTokenV1Instance =
            IOpynOTokenV1(theCheapestWETHPutOptionInOpynV1.oTokenAddress);
        uint256 oTokenLiquidity =
            theCheapestOTokenV1Instance.balanceOf(
                uniswapExchangeContractAddress
            );

        uint256 oTokenExchangeRate;
        (uint256 value, int32 exponent) =
            theCheapestOTokenV1Instance.oTokenExchangeRate();
        if (exponent >= 0) {
            oTokenExchangeRate = value.mul(uint256(10)**uint256(exponent)).mul(
                10**9
            );
        } else {
            oTokenExchangeRate = value
                .mul(uint256(1).div(10**uint256(0 - exponent)))
                .mul(10**9);
        }
        uint256 optionSizeInOToken = _optionSizeInWEI.mul(oTokenExchangeRate);

        oTokenLiquidity.mul(10**9);

        if (optionSizeInOToken < oTokenLiquidity) {
            return true;
        } else {
            return false;
        }
    }

    function getTheCheapestETHPutOptionInOpynV1(
        uint256 _minExpiry,
        uint256 _maxExpiry,
        uint256 _minStrike,
        uint256 _maxStrike,
        uint256 _optionSizeInWEI
    ) internal {
        require(
            _hasEnoughOTokenLiquidityInOpynV1(_optionSizeInWEI) == true,
            "your size is too big for this oToken liquidity in the Opyn V1"
        );
        _getWETHPutOptionsOTokenAddressList();
        _filterWETHPutOptionsOTokenAddresses(
            _minExpiry,
            _maxExpiry,
            _minStrike,
            _maxStrike
        );
        _constructMatchedWETHPutOptionOTokenListV1(_optionSizeInWEI);
        uint256 minimumPremium = matchedWETHPutOptionOTokenListV1[0].premiumInWEI;
        for (uint256 i = 0; i < matchedWETHPutOptionOTokenListV1.length; i++) {
            if (
                matchedWETHPutOptionOTokenListV1[i].premiumInWEI >
                matchedWETHPutOptionOTokenListV1[i + 1].premiumInWEI
            ) {
                minimumPremium = matchedWETHPutOptionOTokenListV1[i + 1]
                    .premiumInWEI;
            }
        }

        for (uint256 i = 0; i < matchedWETHPutOptionOTokenListV1.length; i++) {
            if (minimumPremium == matchedWETHPutOptionOTokenListV1[i].premiumInWEI) {
                theCheapestWETHPutOptionInOpynV1 = TheCheapestWETHPutOptionInOpynV1(
                    matchedWETHPutOptionOTokenListV1[i].oTokenAddress,
                    matchedWETHPutOptionOTokenListV1[i].expiry,
                    matchedWETHPutOptionOTokenListV1[i].strikeInUSD,
                    minimumPremium
                );
            }
        }
    }

    /// @notice buy an ETH put option in Opyn V1
    /// @param _receiver the account that will receive the oTokens
    /// @param _oTokenAddress the address of the oToken that is being bought
    /// @param _paymentTokenAddress the address of the token you are paying for oTokens with
    /// @param _oTokensToBuy the number of oTokens to buy
    function buyETHPutOptionInOpynV1(
        address _receiver,
        address _oTokenAddress,
        address _paymentTokenAddress,
        uint256 _oTokensToBuy
    ) internal {
        // can i pass some values from storage variables?
        OpynExchangeV1Instance.buyOTokens(
            _receiver,
            _oTokenAddress,
            _paymentTokenAddress,
            _oTokensToBuy
        );
    }
}

// you need to calculate the oToken to buy from WEI
