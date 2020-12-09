pragma solidity ^0.6.0;

interface IHegicETHPoolV888 {
    struct LockedLiquidity {
        uint256 amount;
        uint256 premium;
        bool locked;
    }

    event Profit(uint256 indexed id, uint256 amount);
    event Loss(uint256 indexed id, uint256 amount);
    event Provide(address indexed account, uint256 amount, uint256 writeAmount);
    event Withdraw(
        address indexed account,
        uint256 amount,
        uint256 writeAmount
    );

    function unlock(uint256 id) external;

    function send(
        uint256 id,
        address payable account,
        uint256 amount
    ) external;

    function setLockupPeriod(uint256 value) external;

    function totalBalance() external view returns (uint256 amount);

    function revertTransfersInLockUpPeriod(bool value) external;

    function provide(uint256 minMint) external payable returns (uint256 mint);

    function withdraw(uint256 amount, uint256 maxBurn)
        external
        returns (uint256 burn);

    function lock(uint256 id, uint256 amount) external payable onlyOwner;

    function shareOf(address account) external view returns (uint256 share);

    function availableBalance() public view returns (uint256 balance);

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal;

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256);
}

