// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {SaleOrder, MintRequest} from "../common/Structs.sol";
import {SignatureUtils} from "../utils/SignatureUtils.sol";
import {Upgradeable} from "../common/Upgradeable.sol";

import {IERC20} from "../interfaces/IERC20.sol";
import {IERC721} from "../interfaces/IERC721.sol";
import {IERC1155} from "../interfaces/IERC1155.sol";
import {IProxy} from "../interfaces/IProxy.sol";

contract MintHandler is Upgradeable {
    constructor(address _proxy) Upgradeable(_proxy) {}

    using SignatureUtils for SaleOrder;
    using SignatureUtils for MintRequest;

    event MintNFTEvent(
        bytes transactionId,
        uint256[] tokenId,
        uint256 totalSupply,
        uint256 totalMinted
    );

    function handleMintRequest(
        uint256[] memory _data,
        address[] memory _addr,
        bytes[] memory _internalTxId,
        bytes[] memory _signatures
    ) public payable notBlocked notAdmins nonReentrant {
        SaleOrder memory saleOrder = SaleOrder({
            onSaleQuantity: _data[1],
            price: _data[2],
            tokenType: _data[3],
            saleOrderType: _data[5],
            start: _data[6],
            end: _data[7],
            seller: _addr[1],
            saleOrderId: _internalTxId[1]
        });

        MintRequest memory mintRequest = MintRequest({
            totalCopies: _data[0],
            amount: _data[4],
            buyer: _addr[0],
            tokenAddress: _addr[3],
            nftId: _internalTxId[0],
            saleOrderSignature: _signatures[0],
            transactionId: _internalTxId[2]
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
                msg.sender == mintRequest.buyer,
                "MintHandler: Caller is not buyer"
            );

            require(
                !blackList[saleOrder.seller],
                "MintHandler: Seller is blacklisted"
            );

            require(
                saleOrder.onSaleQuantity > 0,
                "MintHandler: Sale order supply must be greater than 0"
            );

            require(
                saleOrder.price > 0,
                "MintHandler: Price must be greater than 0"
            );

            require(
                mintRequest.totalCopies > 0,
                "MintHandler: Total copies must be greater than 0"
            );

            require(
                mintRequest.amount > 0,
                "MintHandler: Amount must be greater than 0"
            );

            require(
                !invalidSaleOrder[mintRequest.saleOrderSignature],
                "MintHandler: Sale order has been canceled"
            );

            require(_addr[2] == signer, "MintHandler: Only admin's signature");
        }

        {
            require(
                mintRequest.totalCopies -
                    soldQuantity[mintRequest.nftId] +
                    soldQuantityBySaleOrder[mintRequest.saleOrderSignature] >=
                    saleOrder.onSaleQuantity,
                "MintHandler: Not enough copy of this item"
            );

            require(
                saleOrder.onSaleQuantity -
                    soldQuantityBySaleOrder[mintRequest.saleOrderSignature] >=
                    mintRequest.amount,
                "MintHandler: Not enough item to buy"
            );

            {
                require(
                    saleOrder.verifySaleOrder(_signatures[0], _addr[2]),
                    "MintHandler: Verify sale order failed"
                );

                require(
                    mintRequest.verifyMintRequest(_signatures[1], _addr[2]),
                    "MintHandler: Verify mint request failed"
                );
            }
        }

        uint256 transferAmount = mintRequest.amount * saleOrder.price;

        if (mintRequest.tokenAddress == address(0)) {
            require(msg.value == transferAmount, "MintHandler: Invalid value");
            payable(recipient).transfer(transferAmount);
        } else {
            require(
                IERC20(mintRequest.tokenAddress).transferFrom(
                    mintRequest.buyer,
                    recipient,
                    transferAmount
                )
            );
        }

        soldQuantity[mintRequest.nftId] += mintRequest.amount;
        soldQuantityBySaleOrder[mintRequest.saleOrderSignature] += mintRequest
            .amount;

        uint256[] memory tokenIds;
        if (saleOrder.tokenType == 0) {
            tokenIds = new uint256[](mintRequest.amount);
        } else {
            tokenIds = new uint256[](1);
        }

        uint256 totalSupply;
        uint256 totalMinted;

        if (saleOrder.tokenType == 0) {
            (tokenIds, totalSupply, totalMinted) = IERC721(collection721)
                .mintBatch(
                    mintRequest.buyer,
                    mintRequest.buyer,
                    mintRequest.nftId,
                    mintRequest.totalCopies,
                    mintRequest.amount,
                    mintRequest.transactionId
                );
        } else {
            (tokenIds[0], totalSupply, totalMinted) = IERC1155(collection1155)
                .mint(
                    mintRequest.buyer,
                    mintRequest.nftId,
                    mintRequest.totalCopies,
                    mintRequest.amount,
                    mintRequest.transactionId
                );
        }

        emit MintNFTEvent(
            mintRequest.transactionId,
            tokenIds,
            totalSupply,
            totalMinted
        );
    }
}
