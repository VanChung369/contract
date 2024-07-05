// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {SaleOrder} from "../common/Structs.sol";
import {Upgradeable} from "../common/Upgradeable.sol";
import {SignatureUtils} from "../utils/SignatureUtils.sol";
import "../interfaces/IProxy.sol";

contract CancelHandler is Upgradeable {
    using SignatureUtils for SaleOrder;

    constructor(address _proxy) Upgradeable(_proxy) {}

    event CancelOrderEvent(bytes transactionId);

    function handleCancelOrder(
        uint256[] memory _data,
        address[] memory _addr,
        bytes[] memory _internalTxId,
        bytes[] memory _signatures
    ) public nonReentrant {
        SaleOrder memory saleOrder = SaleOrder({
            onSaleQuantity: _data[0],
            price: _data[1],
            tokenType: _data[2],
            saleOrderType: _data[3],
            start: _data[4],
            end: _data[5],
            seller: _addr[0],
            saleOrderId: _internalTxId[0]
        });

        address caller = _addr[1];

        if (caller != IProxy(proxy).proxyOwner()) {
            if (adminList[saleOrder.seller]) {
                require(
                    adminList[caller],
                    "CancelHandler: Only admin or proxy owner"
                );
            } else {
                require(
                    caller == saleOrder.seller,
                    "CancelHandler: Only NFT's owner"
                );
            }
        }

        require(
            soldQuantityBySaleOrder[_signatures[0]] < _data[0],
            "CancelHandler: Sold out"
        );

        require(
            !invalidSaleOrder[_signatures[0]],
            "CancelHandler: Sale order has been canceled"
        );

        require(
            saleOrder.verifySaleOrder(_signatures[0], _addr[2]),
            "CancelHandler: Verify sale order failed"
        );

        invalidSaleOrder[_signatures[0]] = true;

        emit CancelOrderEvent(_internalTxId[1]);
    }
}
