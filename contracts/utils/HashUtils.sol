// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {SaleOrder, MintRequest, BuyRequest} from "../common/Structs.sol";
import {Utils} from "./Utils.sol";
import {AssemblyUtils} from "./AssemblyUtils.sol";

library HashUtils {
    using Utils for MintRequest;
    using Utils for SaleOrder;
    using Utils for BuyRequest;
    using AssemblyUtils for uint256;

    function hashMintRequest(
        MintRequest memory _mintRequest
    ) internal pure returns (bytes32 hash) {
        uint256 size = _mintRequest.sizeOfMintRequest();
        bytes memory array = new bytes(size);
        uint256 index;

        assembly {
            index := add(array, 0x20)
        }

        index = index.writeUint256(_mintRequest.totalCopies);
        index = index.writeUint256(_mintRequest.amount);
        index = index.writeAddress(_mintRequest.buyer);
        index = index.writeAddress(_mintRequest.tokenAddress);
        index = index.writeBytes(_mintRequest.nftId);
        index = index.writeBytes(_mintRequest.saleOrderSignature);
        index = index.writeBytes(_mintRequest.transactionId);

        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
    }

    function hashBuyRequest(
        BuyRequest memory _buyRequest
    ) internal pure returns (bytes32 hash) {
        uint256 size = _buyRequest.sizeOfBuyRequest();
        bytes memory array = new bytes(size);
        uint256 index;

        assembly {
            index := add(array, 0x20)
        }
        index = index.writeUint256(_buyRequest.tokenId);
        index = index.writeUint256(_buyRequest.amount);
        index = index.writeAddress(_buyRequest.buyer);
        index = index.writeAddress(_buyRequest.tokenAddress);
        index = index.writeBytes(_buyRequest.saleOrderSignature);
        index = index.writeBytes(_buyRequest.transactionId);

        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
    }

    function hashSaleOrder(
        SaleOrder memory _saleOrder
    ) internal pure returns (bytes32 hash) {
        uint256 size = _saleOrder.sizeOfSaleOrder();
        bytes memory array = new bytes(size);
        uint256 index;

        assembly {
            index := add(array, 0x20)
        }

        index = index.writeUint256(_saleOrder.onSaleQuantity);
        index = index.writeUint256(_saleOrder.price);
        index = index.writeUint256(_saleOrder.tokenType);
        index = index.writeAddress(_saleOrder.seller);
        index = index.writeUint256(_saleOrder.saleOrderType);
        index = index.writeUint256(_saleOrder.start);
        index = index.writeUint256(_saleOrder.end);
        index = index.writeBytes(_saleOrder.saleOrderId);

        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
    }

    function getEthSignedHash(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function recoverSigner(
        bytes32 _hash,
        bytes memory _signature
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (_signature.length != 65) {
            return (address(0));
        }

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(_hash, v, r, s);
        }
    }
}
