// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {SaleOrder, MintRequest, BuyRequest} from "../common/Structs.sol";

library Utils {
    function sizeOfSaleOrder(
        SaleOrder memory _item
    ) internal pure returns (uint256) {
        return ((0x20 * 3) + (0x14 * 1) + _item.saleOrderId.length);
    }

    function sizeOfMintRequest(
        MintRequest memory _item
    ) internal pure returns (uint256) {
        return ((0x20 * 2) +
            (0x14 * 2) +
            _item.nftId.length +
            _item.saleOrderSignature.length +
            _item.transactionId.length);
    }

    function sizeOfBuyRequest(
        BuyRequest memory _item
    ) internal pure returns (uint256) {
        return ((0x20 * 2) +
            (0x14 * 2) +
            _item.saleOrderSignature.length +
            _item.transactionId.length);
    }
}
