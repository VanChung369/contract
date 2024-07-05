// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

struct SaleOrder {
    uint256 onSaleQuantity;
    uint256 price;
    uint256 tokenType;
    address seller;
    uint256 saleOrderType;
    uint256 start;
    uint256 end;
    bytes saleOrderId; // internalTxId
}

struct MintRequest {
    uint256 totalCopies;
    uint256 amount;
    address buyer;
    address tokenAddress;
    bytes nftId;
    bytes saleOrderSignature;
    bytes transactionId; // internalTxId
}

struct BuyRequest {
    uint256 tokenId;
    uint256 amount;
    address buyer;
    address tokenAddress;
    bytes saleOrderSignature;
    bytes transactionId; // internalTxId
}
