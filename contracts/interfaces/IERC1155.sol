// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IERC1155 {
    function soldQuantity(uint256 tokenId) external returns (uint256);

    function mint(
        address to_,
        bytes calldata nftId_,
        uint256 totalCopies_,
        uint256 amount_,
        bytes calldata data_
    )
        external
        returns (uint256 tokenId, uint256 totalSupply, uint256 totalMinted);

    function mintBatch(
        address to_,
        bytes[] calldata nftIds_,
        uint256[] calldata totalCopies_,
        uint256[] calldata amounts_,
        bytes calldata data_
    ) external returns (uint256[] memory, uint256[] memory, uint256[] memory);

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}
