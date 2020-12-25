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
    IOpynOTokenV1[] private filteredWETHPutOptionOTokenV1InstanceList;
    IUniswapFactoryV1 private UniswapFactoryV1Instance;

    address constant USDCTokenAddress =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETHTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address[] private oTokenAddressList;

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
        uint256 expiry;
        uint256 strike;
        uint256 premium;
    }
    TheCheapestWETHPutOptionInOpynV1 theCheapestWETHPutOptionInOpynV1;

    event NewOpynExchangeV1AddressRegistered(address opynExchangeV1Address);
    event NewOpynOptionsFactoryV1AddressRegistered(
        address opynOptionsFactoryV1Address
    );
    event NewOpynOTokenV1AddressRegistered(address opynOTokenV1Address);
    event NewOpynWETHPutOptionOTokenV1AddressRegistered(
        address opynWETHPutOptionOTokenV1Address
    );
    event NewUniswapFactoryV1AddressRegistered(address uniswapFactoryV1Address);
    event NotWETHPutOptionsOToken(address oTokenAddress);

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
        emit NewOpynExchangeV1AddressRegistered(_opynExchangeV1Address);
    }

    /// @notice instantiate the OpynOptionsFactoryV1 contract
    /// @param _opynOptionsFactoryV1Address OpynOptionsFactoryV1Address
    function instantiateOpynOptionsFactoryV1(
        address _opynOptionsFactoryV1Address
    ) public onlyOwner {
        OpynOptionsFactoryV1Instance = IOpynOptionsFactoryV1(
            _opynOptionsFactoryV1Address
        );
        emit NewOpynOptionsFactoryV1AddressRegistered(
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
        emit NewUniswapFactoryV1AddressRegistered(_uniswapFactoryV1Address);
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
            emit NewOpynOTokenV1AddressRegistered(_opynOTokenV1AddressList[i]);
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
                WETHPutOptionOTokenListV1[i].oTokenAddress = oTokenAddressList[
                    i
                ];
            } else {
                emit NotWETHPutOptionsOToken(oTokenAddressList[i]);
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
            if (
                _minStrike <
                WETHPutOptionOTokenV1InstanceList[i].strikePrice() &&
                WETHPutOptionOTokenV1InstanceList[i].strikePrice() <
                _maxStrike &&
                _minExpiry < WETHPutOptionOTokenV1InstanceList[i].expiry() &&
                WETHPutOptionOTokenV1InstanceList[i].expiry() < _maxExpiry
            ) {
                filteredWETHPutOptionOTokenV1InstanceList.push(
                    WETHPutOptionOTokenV1InstanceList[i]
                );
                filteredWETHPutOptionOTokenListV1[i]
                    .oTokenAddress = WETHPutOptionOTokenListV1[i].oTokenAddress;
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
            i < filteredWETHPutOptionOTokenV1InstanceList.length;
            i++
        ) {
            if (
                filteredWETHPutOptionOTokenV1InstanceList[i].expiry() ==
                _expiry &&
                filteredWETHPutOptionOTokenV1InstanceList[i].strikePrice() ==
                _strike
            ) {
                oTokenAddress = filteredWETHPutOptionOTokenListV1[i]
                    .oTokenAddress;
            }
        }
        uint256 premiumToPayInWEI =
            OpynExchangeV1Instance.premiumToPay(
                oTokenAddress,
                address(0),
                _oTokensToBuy
            );
        return premiumToPayInWEI;
    }

    /// @notice construct the filteredWETHPutOptionOTokenListV1
    /// @param _optionSizeInWEI the size of an option to buy in WEI
    function _constructFilteredWETHPutOptionOTokenListV1(
        uint256 _optionSizeInWEI
    ) private {
        for (uint256 i = 0; i < filteredWETHPutOptionOTokenListV1.length; i++) {
            filteredWETHPutOptionOTokenListV1[i] = WETHPutOptionOTokensV1(
                filteredWETHPutOptionOTokenListV1[i].oTokenAddress,
                filteredWETHPutOptionOTokenV1InstanceList[i].expiry(),
                filteredWETHPutOptionOTokenV1InstanceList[i].strikePrice(),
                _getOpynV1Premium(
                    filteredWETHPutOptionOTokenV1InstanceList[i].expiry(),
                    filteredWETHPutOptionOTokenV1InstanceList[i].strikePrice(),
                    optionSizeInWEI
                    _optionSizeInWEI // this should be oToken amount right?
                )
            );
        }
    }

    /// @notice check if there is enough liquidity in Opyn V1 pool
    /// @param _optionSizeInWEI the size of an option to buy in WEI
    /// @dev write a function for power operations. the SafeMath library doesn't support this yet.
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
        (uint256 value, int32 exponent) =
            theCheapestOTokenV1Instance.oTokenExchangeRate();
        uint256 optionSizeInOToken =
            _optionSizeInWEI.mul(value.mul(10**exponent));
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
        _constructFilteredWETHPutOptionOTokenListV1(_optionSizeInWEI);
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
                theCheapestWETHPutOptionInOpynV1 = TheCheapestWETHPutOptionInOpynV1(
                    filteredWETHPutOptionOTokenListV1[i].oTokenAddress,
                    filteredWETHPutOptionOTokenListV1[i].expiry,
                    filteredWETHPutOptionOTokenListV1[i].strike,
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

// how do you deal with the Number struct?
// how to deal with float numbers in solidity
// you need to calculate the oToken to buy from WEI 
