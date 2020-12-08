interface IOpynV1OptionsFactory {
    function tokens(string) external view returns (address);

    function changeAsset(string _asset, address _addr) external;

    function optionsExchange() external view returns (address);

    function renounceOwnership() external;

    function getNumberOfOptionsContracts() external view returns (uint256);

    function owner() external view returns (address);

    function isOwner() external view returns (bool);

    function createOptionsContract(
        string _collateralType,
        int32 _collateralExp,
        string _underlyingType,
        int32 _underlyingExp,
        int32 _oTokenExchangeExp,
        uint256 _strikePrice,
        int32 _strikeExp,
        string _strikeAsset,
        uint256 _expiry,
        uint256 _windowSize
    ) external returns (address);

    function oracleAddress() external view returns (address);

    function addAsset(string _asset, address _addr) external;

    function supportsAsset(string _asset) external view returns (bool);

    function deleteAsset(string _asset) external;

    function optionsContracts(uint256) external view returns (address);

    function transferOwnership(address newOwner) external;
}
