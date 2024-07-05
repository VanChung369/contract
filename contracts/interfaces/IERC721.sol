// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IERC721 {
    function getNFTIDfromTokenID(
        uint256 _tokenId
    ) external returns (bytes memory);
    function getUpdatedAtfromTokenID(
        uint256 _tokenId
    ) external returns (uint256);
    function setLastUpdated(bytes calldata _nftId, uint256 _time) external;

    function mint(
        address _account,
        address _caller,
        bytes calldata _nftId,
        uint256 _totalSupply,
        bytes calldata _data
    )
        external
        returns (uint256 tokenId, uint256 totalSupply, uint256 totalMinted);

    function mintBatch(
        address _account,
        address _caller,
        bytes calldata _nftId,
        uint256 _totalSupply,
        uint256 _amount,
        bytes calldata _data
    )
        external
        returns (uint256[] memory, uint256 totalSupply, uint256 totalMinted);

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
