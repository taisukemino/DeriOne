pragma solidity ^0.6.0;

interface IHegicETHOption {
    event Create(
        uint256 indexed id,
        address indexed account,
        uint256 settlementFee,
        uint256 totalFee
    );

    event Exercise(uint256 indexed id, uint256 profit);
    event Expire(uint256 indexed id, uint256 premium);
    enum State {Inactive, Active, Exercised, Expired}
    enum OptionType {Invalid, Put, Call}

    struct Option {
        State state;
        address payable holder;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        OptionType optionType;
    }

    function options(uint256)
        external
        view
        returns (
            State state,
            address payable holder,
            uint256 strike,
            uint256 amount,
            uint256 lockedAmount,
            uint256 premium,
            uint256 expiration,
            OptionType optionType
        );
}
