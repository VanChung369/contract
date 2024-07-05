// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Upgradeable} from "../common/Upgradeable.sol";
import {IERC721} from "../interfaces/IERC721.sol";
import {IERC1155} from "../interfaces/IERC1155.sol";

contract AdminMintHandler is Upgradeable {
    constructor(address _proxy) Upgradeable(_proxy) {}

    event AdminMintEvent(
        bytes transactionId,
        uint256[] tokenIds,
        uint256 totalSupply,
        uint256 totalMinted
    );

    function handleMintRequestByAdmin(
        address _account,
        bytes[] memory _ids,
        uint256[] memory _data,
        uint256[] memory _totalCopies,
        uint256[] memory _amounts
    ) public onlyAdmins nonReentrant {
        uint256[] memory tokenIds = new uint256[](_data[1]);
        uint256 totalSupply;
        uint256 totalMinted;
        if (_data[0] == 0) {
            (tokenIds, totalSupply, totalMinted) = IERC721(collection721)
                .mintBatch(
                    _account,
                    msg.sender,
                    _ids[0],
                    _totalCopies[0],
                    _data[1],
                    _ids[1]
                );
        } else {
            (tokenIds[0], totalSupply, totalMinted) = IERC1155(collection1155)
                .mint(_account, _ids[0], _totalCopies[0], _amounts[0], _ids[1]);
        }

        emit AdminMintEvent(_ids[1], tokenIds, totalSupply, totalMinted);
    }
}
