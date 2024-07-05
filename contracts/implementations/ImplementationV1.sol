// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Implementation} from "./Implementation.sol";
import {SignatureUtils} from "../utils/SignatureUtils.sol";
import {SaleOrder, MintRequest} from "../common/Structs.sol";

contract ImplementationV1 is Implementation {
    constructor(address _proxy) Implementation(_proxy) {}

    function handleMintRequest(
        uint256[] memory,
        address[] memory,
        bytes[] memory,
        bytes[] memory
    ) public payable {
        _delegatecall(mintHandler);
    }

    function handleBuyRequest(
        uint256[] memory,
        address[] memory,
        bytes[] memory,
        bytes[] memory
    ) public payable {
        _delegatecall(buyHandler);
    }

    function handleCancelOrder(
        uint256[] memory,
        address[] memory,
        bytes[] memory,
        bytes[] memory
    ) public {
        _delegatecall(cancelHandler);
    }

    function handleMintRequestByAdmin(
        address,
        bytes[] memory,
        uint256[] memory,
        uint256[] memory,
        uint256[] memory
    ) public {
        _delegatecall(adminMintHandler);
    }
}
