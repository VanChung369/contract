// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {SaleOrder, BuyRequest} from "../common/Structs.sol";
import {SignatureUtils} from "../utils/SignatureUtils.sol";
import {Upgradeable} from "../common/Upgradeable.sol";

import {IERC20} from "../interfaces/IERC20.sol";
import {IERC721} from "../interfaces/IERC721.sol";
import {IERC1155} from "../interfaces/IERC1155.sol";
import {IProxy} from "../interfaces/IProxy.sol";

contract BuyHandler is Upgradeable {
    constructor(address _proxy) Upgradeable(_proxy) {}

    event BuyNFTEvent(bytes transactionId);

    using SignatureUtils for SaleOrder;
    using SignatureUtils for BuyRequest;

    function handleBuyRequest(
        uint256[] memory _data,
        address[] memory _addr,
        bytes[] memory _internalTxId,
        bytes[] memory _signatures
    ) public payable notBlocked notAdmins nonReentrant {
        SaleOrder memory saleOrder = SaleOrder({
            onSaleQuantity: _data[1],
            price: _data[2],
            tokenType: _data[3],
            saleOrderType: _data[6],
            start: _data[7],
            end: _data[8],
            seller: _addr[1],
            saleOrderId: _internalTxId[0]
        });

        BuyRequest memory buyRequest = BuyRequest({
            tokenId: _data[0],
            amount: _data[4],
            buyer: _addr[0],
            tokenAddress: _addr[3],
            saleOrderSignature: _signatures[0],
            transactionId: _internalTxId[1]
        });

        {
            if (saleOrder.saleOrderType == 0) {
                require(
                    block.timestamp >= saleOrder.start &&
                        block.timestamp <= saleOrder.end,
                    "BuyRequest: Sale order has expired"
                );
            }
        }
        {
            require(
                msg.sender == buyRequest.buyer,
                "BuyRequest: Caller is not buyer"
            );

            require(
                !blackList[saleOrder.seller],
                "BuyRequest: Seller is blacklisted"
            );

            require(
                saleOrder.onSaleQuantity > 0,
                "BuyRequest: Sale order supply must be greater than 0"
            );

            require(
                saleOrder.price > 0,
                "BuyRequest: Price must be greater than 0"
            );

            require(
                buyRequest.amount > 0,
                "BuyRequest: Amount must be greater than 0"
            );

            require(
                _data[5] <= 50000,
                "BuyRequest: Royalty ratio is more than 50%"
            );

            require(
                !invalidSaleOrder[buyRequest.saleOrderSignature],
                "BuyHandler: Sale order has been canceled"
            );

            require(_addr[2] == signer, "BuyHandler: Only admin's signature");
        }

        {
            if (saleOrder.tokenType == 0) {
                // ERC721
                require(
                    saleOrder.onSaleQuantity == 1,
                    "BuyRequest: Sale order supply of 721 items cannot exceed 1"
                );
                require(
                    buyRequest.amount == 1,
                    "BuyRequest: Amount to buy of 721 items cannot exceed 1"
                );

                require(
                    soldQuantityBySaleOrder[buyRequest.saleOrderSignature] == 0,
                    "BuyRequest: Sold out"
                );
            } else {
                // ERC1155

                require(
                    IERC1155(collection1155).balanceOf(
                        saleOrder.seller,
                        buyRequest.tokenId
                    ) -
                        buyRequest.amount >=
                        0,
                    "BuyRequest: Not enough copy of this item"
                );

                require(
                    saleOrder.onSaleQuantity -
                        soldQuantityBySaleOrder[
                            buyRequest.saleOrderSignature
                        ] >=
                        buyRequest.amount,
                    "BuyRequest: Not enough item to buy"
                );
            }

            {
                require(
                    saleOrder.verifySaleOrder(_signatures[0], _addr[2]),
                    "BuyRequest: Verify sale order failed"
                );
            }
        }

        uint256 transferAmount = buyRequest.amount * saleOrder.price;
        uint256 fee = (transferAmount * _data[5]) / 100000;

        if (buyRequest.tokenAddress == address(0)) {
            require(msg.value == transferAmount, "BuyRequest: Invalid value");
            payable(recipient).transfer(fee);
            payable(saleOrder.seller).transfer(transferAmount - fee);
        } else {
            require(
                IERC20(buyRequest.tokenAddress).transferFrom(
                    buyRequest.buyer,
                    saleOrder.seller,
                    transferAmount - fee
                ),
                "BuyRequest: Failed to transfer ERC-20 token"
            );

            require(
                IERC20(buyRequest.tokenAddress).transferFrom(
                    buyRequest.buyer,
                    recipient,
                    fee
                ),
                "BuyRequest: Failed to transfer ERC-20 token"
            );
        }

        soldQuantityBySaleOrder[buyRequest.saleOrderSignature] += buyRequest
            .amount;

        if (saleOrder.tokenType == 0) {
            IERC721(collection721).safeTransferFrom(
                saleOrder.seller,
                buyRequest.buyer,
                buyRequest.tokenId,
                buyRequest.transactionId
            );
            bytes memory nftId = IERC721(collection721).getNFTIDfromTokenID(
                buyRequest.tokenId
            );
            uint256 lastestUpdate = IERC721(collection721)
                .getUpdatedAtfromTokenID(buyRequest.tokenId);
            IERC721(collection721).setLastUpdated(nftId, lastestUpdate);
        } else {
            IERC1155(collection1155).safeTransferFrom(
                saleOrder.seller,
                buyRequest.buyer,
                buyRequest.tokenId,
                buyRequest.amount,
                buyRequest.transactionId
            );
        }

        emit BuyNFTEvent(buyRequest.transactionId);
    }
}
