// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "../common/ReentrancyGuard.sol";
import {IProxy} from "../interfaces/IProxy.sol";

contract Collection1155 is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter tokenId_;
    Counters.Counter outsideId_;

    struct Owned {
        bytes[] nftIds;
        mapping(bytes => uint256) tokenIds;
    }

    struct NFT {
        uint256 tokenId;
        uint256 amount;
        address[] owners;
    }

    address public controller;

    string private baseURI = "";

    mapping(address => Owned) owned;
    mapping(bytes => NFT) nfts;
    mapping(uint256 => bytes) nftIdByTokenId;
    mapping(bytes => mapping(uint256 => uint256)) lastUpdated;

    constructor(address _controller, string memory _baseURI) ERC1155(_baseURI) {
        setController(_controller);
        setURI(_baseURI);
        tokenId_._value = 100000;
    }

    modifier onlyControllers() {
        require(
            msg.sender == controller || msg.sender == owner(),
            "Collection721: Only controllers"
        );
        _;
    }

    function setController(address _newController) public onlyOwner {
        require(
            _newController != address(0),
            "Collection721: New controller is zero address"
        );

        require(
            _newController != controller,
            "Collection1155: Receive the same address as the old one"
        );
        controller = _newController;
    }

    function setURI(string memory uri_) public onlyOwner {
        baseURI = uri_;
    }

    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            bytes32(nftIdByTokenId[tokenId]) != bytes32(0x00),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function _handleMint(
        address to_,
        bytes memory nftId_,
        uint256 amount_,
        bytes memory data_
    ) internal returns (uint256) {
        Owned storage data = owned[to_];
        NFT storage nft = nfts[nftId_];

        uint256 tokenId = nft.tokenId;

        if (tokenId == 0) {
            tokenId_.increment();
            tokenId = tokenId_.current();
            nft.tokenId = tokenId;
        }

        if (balanceOf(to_, tokenId) == 0) {
            data.nftIds.push(nftId_);
            data.tokenIds[nftId_] = tokenId;

            nft.owners.push(to_);
        }

        lastUpdated[nftId_][tokenId] = block.timestamp;

        nft.amount += amount_;

        _mint(to_, tokenId, amount_, data_);

        nftIdByTokenId[tokenId] = nftId_;

        return tokenId;
    }

    function _handleTransfer(
        address from_,
        address to_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) internal {
        bytes memory nftId = nftIdByTokenId[id_];

        NFT storage nft = nfts[nftId];

        Owned storage buyer = owned[to_];

        if (balanceOf(to_, id_) == 0) {
            buyer.nftIds.push(nftId);
            buyer.tokenIds[nftId] = id_;
            nft.owners.push(to_);
        }

        _safeTransferFrom(from_, to_, id_, amount_, data_);

        Owned storage seller = owned[from_];
        uint256 len = seller.nftIds.length;

        if (balanceOf(from_, id_) == 0) {
            for (uint256 i = 0; i < len; i++) {
                if (bytes32(seller.nftIds[i]) == bytes32(nftId)) {
                    seller.nftIds[i] = seller.nftIds[len - 1];
                    seller.nftIds.pop();
                    break;
                }
            }

            for (uint256 i = 0; i < nft.owners.length; i++) {
                if (nft.owners[i] == from_) {
                    nft.owners[i] = nft.owners[nft.owners.length - 1];
                    nft.owners.pop();
                    break;
                }
            }
        }

        lastUpdated[nftId][id_] = block.timestamp;
    }

    function mint(
        address to_,
        bytes memory nftId_,
        uint256 totalCopies_,
        uint256 amount_,
        bytes memory data_
    )
        public
        onlyControllers
        nonReentrant
        returns (uint256 tokenId, uint256 totalSupply, uint256 totalMinted)
    {
        NFT storage nft = nfts[nftId_];

        require(
            nft.amount + amount_ <= totalCopies_,
            "Collection1155: Mint request cannot exceed the limit"
        );

        tokenId = _handleMint(to_, nftId_, amount_, data_);

        totalSupply = totalCopies_;
        totalMinted = nft.amount;
    }

    function mintBatch(
        address to_,
        bytes[] memory nftIds_,
        uint256[] memory totalCopies_,
        uint256[] memory amounts_,
        bytes memory data_
    )
        public
        onlyControllers
        nonReentrant
        returns (uint256[] memory, uint256[] memory, uint256[] memory)
    {
        uint256 len = nftIds_.length;
        uint256[] memory tokenIds = new uint256[](len);
        uint256[] memory totalSupply = new uint256[](len);
        uint256[] memory totalMinted = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            NFT storage nft = nfts[nftIds_[i]];

            require(
                nft.amount + amounts_[i] <= totalCopies_[i],
                "Collection1155: Mint request cannot exceed the limit"
            );

            tokenIds[i] = _handleMint(to_, nftIds_[i], amounts_[i], data_);

            totalSupply[i] = totalCopies_[i];
            totalMinted[i] = nft.amount;
        }

        return (tokenIds, totalSupply, totalMinted);
    }

    function burn(
        address account_,
        uint256 id_,
        uint256 amount_
    ) public virtual nonReentrant {
        require(
            account_ == _msgSender() ||
                isApprovedForAll(account_, _msgSender()),
            "Collection1155: caller is not owner nor approved"
        );

        _burn(account_, id_, amount_);

        bytes memory nftId = nftIdByTokenId[id_];

        Owned storage caller = owned[account_];

        NFT storage nft = nfts[nftId];

        if (balanceOf(account_, id_) == 0) {
            for (uint256 i = 0; i < caller.nftIds.length; i++) {
                if (bytes32(caller.nftIds[i]) == bytes32(nftId)) {
                    caller.nftIds[i] = caller.nftIds[caller.nftIds.length - 1];
                    caller.nftIds.pop();
                    break;
                }
            }

            for (uint256 i = 0; i < nft.owners.length; i++) {
                if (nft.owners[i] == account_) {
                    nft.owners[i] = nft.owners[nft.owners.length - 1];
                    nft.owners.pop();
                    break;
                }
            }
        }

        nft.amount -= amount_;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override nonReentrant {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _handleTransfer(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override nonReentrant {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            _handleTransfer(from, to, ids[i], amounts[i], data);
        }
    }

    function getOwned(
        address account_
    )
        internal
        view
        returns (bytes[] memory, uint256[] memory, uint256[] memory)
    {
        Owned storage data = owned[account_];

        uint256[] memory tokenIds = new uint256[](data.nftIds.length);
        uint256[] memory updated = new uint256[](data.nftIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            bytes memory nftId = data.nftIds[i];
            tokenIds[i] = data.tokenIds[nftId];
            updated[i] = lastUpdated[nftId][tokenIds[i]];
        }
        return (data.nftIds, tokenIds, updated);
    }

    function getOwnedNFT(
        address account_,
        bytes memory nftId_
    )
        public
        view
        returns (uint256 tokenId, uint256 amountOwned, uint256 updated)
    {
        tokenId = owned[account_].tokenIds[nftId_];
        amountOwned = balanceOf(account_, tokenId);
        updated = lastUpdated[nftId_][tokenId];
    }

    function getOwnedNFTDetail(
        address account_
    )
        public
        view
        returns (
            bytes[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        bytes[] memory nftIds;
        uint256[] memory tokenIds;
        uint256[] memory updated;
        (nftIds, tokenIds, updated) = getOwned(account_);

        uint256[] memory amountOwned = new uint256[](nftIds.length);

        for (uint256 i = 0; i < nftIds.length; i++) {
            amountOwned[i] = balanceOf(account_, tokenIds[i]);
        }

        return (nftIds, tokenIds, amountOwned, updated);
    }

    function getNFT(
        bytes memory nftId_
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256[] memory,
            address[] memory,
            bool[] memory
        )
    {
        NFT storage nft = nfts[nftId_];

        uint256 tokenId = nft.tokenId;
        uint256 updated = lastUpdated[nftId_][tokenId];
        address[] memory owners = nft.owners;
        uint256[] memory amount = new uint256[](owners.length);
        bool[] memory isAdmin = new bool[](owners.length);

        for (uint256 i = 0; i < owners.length; i++) {
            amount[i] = balanceOf(owners[i], tokenId);
            isAdmin[i] = IProxy(controller).isAdmin(owners[i]);
        }

        return (tokenId, updated, amount, owners, isAdmin);
    }
}
