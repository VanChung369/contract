// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "../common/ReentrancyGuard.sol";
import {IProxy} from "../interfaces/IProxy.sol";

contract Collection721 is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter tokenId_;
    Counters.Counter outsideId_;

    address public controller;
    string public baseURI;

    struct Owned {
        bytes[] nftIds;
        mapping(bytes => uint256[]) tokenIds;
    }

    struct Owner {
        bytes nftId;
        address owner;
        uint256 updatedAt;
    }

    struct NFT {
        uint256[] tokenIds;
        mapping(uint256 => address) mintedBy;
    }

    struct OwnedDetail {
        bytes nftId;
        uint256[] tokenIds;
        uint256[] updatedAt;
    }

    mapping(address => Owned) owned;
    mapping(bytes => NFT) nfts;
    mapping(uint256 => Owner) owners;
    mapping(bytes => uint256) lastestUpdatedByNFT;

    modifier onlyControllers() {
        require(
            msg.sender == controller ||
                msg.sender == owner() ||
                msg.sender == address(this),
            "Collection721: Only controllers"
        );
        _;
    }

    constructor(
        address _controller,
        string memory _uri
    ) ERC721("ERC721", "721") {
        setController(_controller);
        setBaseURI(_uri);
        tokenId_._value = 100000;
    }

    function setController(address _newController) public onlyOwner {
        require(
            _newController != address(0),
            "Collection721: New controller is zero address"
        );
        controller = _newController;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setLastUpdated(
        bytes memory _nftId,
        uint256 _time
    ) public onlyControllers {
        require(
            _time > lastestUpdatedByNFT[_nftId],
            "Collection721: Can not update to the past, you dweeb"
        );
        lastestUpdatedByNFT[_nftId] = _time;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function _checkOwnedNFTID(
        bytes memory _nftId,
        address _account
    ) internal view returns (bool) {
        Owned storage data = owned[_account];
        for (uint256 i = 0; i < data.nftIds.length; i++) {
            if (bytes32(data.nftIds[i]) == bytes32(_nftId)) return true;
        }
        return false;
    }

    function _handleMint(
        address _account,
        address _caller,
        bytes memory _nftId,
        bytes memory _data
    ) internal returns (uint256) {
        tokenId_.increment();
        uint256 _tokenId = tokenId_.current();
        _safeMint(_account, _tokenId, _data);

        Owned storage data = owned[_account];
        if (!_checkOwnedNFTID(_nftId, _account)) {
            data.nftIds.push(_nftId);
        }
        data.tokenIds[_nftId].push(_tokenId);

        Owner storage owner_ = owners[_tokenId];
        owner_.nftId = _nftId;
        owner_.owner = _account;
        owner_.updatedAt = block.timestamp;

        lastestUpdatedByNFT[_nftId] = owner_.updatedAt;

        NFT storage nft = nfts[_nftId];
        nft.tokenIds.push(_tokenId);
        nft.mintedBy[_tokenId] = _caller;

        return _tokenId;
    }

    function _handleTransfer(
        address from_,
        address to_,
        uint256 id_,
        bytes memory data_
    ) internal {
        _safeTransfer(from_, to_, id_, data_);

        Owner storage owner_ = owners[id_];
        bytes memory nftId_ = owner_.nftId;

        Owned storage seller = owned[from_];

        uint256[] storage tokenIdsSeller = seller.tokenIds[nftId_];

        for (uint256 i = 0; i < tokenIdsSeller.length; i++) {
            if (tokenIdsSeller[i] == id_) {
                tokenIdsSeller[i] = tokenIdsSeller[tokenIdsSeller.length - 1];
                tokenIdsSeller.pop();
                break;
            }
        }

        if (tokenIdsSeller.length == 0) {
            for (uint256 i = 0; i < seller.nftIds.length; i++) {
                if (bytes32(seller.nftIds[i]) == bytes32(nftId_)) {
                    seller.nftIds[i] = seller.nftIds[seller.nftIds.length - 1];
                    seller.nftIds.pop();
                    break;
                }
            }
        }

        Owned storage buyer = owned[to_];
        if (buyer.tokenIds[nftId_].length == 0) {
            buyer.nftIds.push(nftId_);
        }
        buyer.tokenIds[nftId_].push(id_);

        owner_.owner = to_;
        owner_.updatedAt = block.timestamp;
    }

    function burn(
        address _account,
        uint256 _tokenId
    ) public virtual nonReentrant {
        require(
            _account == _msgSender() ||
                isApprovedForAll(_account, _msgSender()),
            "Collection721: caller is not owner nor approved"
        );
        _burn(_tokenId);

        Owner storage owner_ = owners[_tokenId];
        bytes memory nftId_ = owner_.nftId;

        Owned storage seller = owned[_account];

        NFT storage nft = nfts[nftId_];

        for (uint256 i = 0; i < nft.tokenIds.length; i++) {
            if (nft.tokenIds[i] == _tokenId) {
                nft.tokenIds[i] = nft.tokenIds[nft.tokenIds.length - 1];
                nft.tokenIds.pop();
                break;
            }
        }

        uint256[] storage tokenIdsSeller = seller.tokenIds[nftId_];

        for (uint256 i = 0; i < tokenIdsSeller.length; i++) {
            if (tokenIdsSeller[i] == _tokenId) {
                tokenIdsSeller[i] = tokenIdsSeller[tokenIdsSeller.length - 1];
                tokenIdsSeller.pop();
                break;
            }
        }

        if (tokenIdsSeller.length == 0) {
            for (uint256 i = 0; i < seller.nftIds.length; i++) {
                if (bytes32(seller.nftIds[i]) == bytes32(nftId_)) {
                    seller.nftIds[i] = seller.nftIds[seller.nftIds.length - 1];
                    seller.nftIds.pop();
                    break;
                }
            }
        }

        delete owner_.owner;
        owner_.updatedAt = block.timestamp;
    }

    function mint(
        address _account,
        address _caller,
        bytes memory _nftId,
        uint256 _totalSupply,
        bytes memory _data
    )
        public
        onlyControllers
        nonReentrant
        returns (uint256 tokenId, uint256 totalSupply, uint256 totalMinted)
    {
        NFT storage nft = nfts[_nftId];

        require(
            nft.tokenIds.length < _totalSupply,
            "Collection721: Mint request cannot exceed the limit"
        );

        tokenId = _handleMint(_account, _caller, _nftId, _data);

        totalSupply = _totalSupply;
        totalMinted = nft.tokenIds.length;
    }

    /**
     * @dev Handle admin mint request
     */
    function mintBatch(
        address _account,
        address _caller,
        bytes memory _nftId,
        uint256 _totalSupply,
        uint256 _amount,
        bytes memory _data
    )
        public
        onlyControllers
        nonReentrant
        returns (uint256[] memory, uint256 totalSupply, uint256 totalMinted)
    {
        NFT storage nft = nfts[_nftId];

        require(
            nft.tokenIds.length + _amount <= _totalSupply,
            "Collection721: Mint request cannot exceed the limit"
        );

        uint256[] memory tokenIds = new uint256[](_amount);

        for (uint256 i = 0; i < _amount; i++) {
            tokenIds[i] = _handleMint(_account, _caller, _nftId, _data);
        }

        totalSupply = _totalSupply;
        totalMinted = nft.tokenIds.length;

        return (tokenIds, totalSupply, totalMinted);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override nonReentrant {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _handleTransfer(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override nonReentrant {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _handleTransfer(from, to, tokenId, "");
    }

    function getNFTIDfromTokenID(
        uint256 _tokenId
    ) public view returns (bytes memory) {
        return owners[_tokenId].nftId;
    }

    function getUpdatedAtfromTokenID(
        uint256 _tokenId
    ) public view returns (uint256) {
        return owners[_tokenId].updatedAt;
    }

    function getOwned(address _account) internal view returns (bytes[] memory) {
        Owned storage data = owned[_account];

        return data.nftIds;
    }

    function getOwnedNFT(
        address _account,
        bytes memory _nftId
    ) public view returns (uint256[] memory, uint256[] memory) {
        Owned storage data = owned[_account];
        uint256[] memory tokenIds = data.tokenIds[_nftId];
        uint256[] memory updatedAt = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            Owner storage owner_ = owners[tokenIds[i]];
            updatedAt[i] = owner_.updatedAt;
        }

        return (tokenIds, updatedAt);
    }

    function getOwnedNFTDetail(
        address account_
    ) public view returns (bytes[] memory, uint256[] memory, uint256[] memory) {
        bytes[] memory nftIds = getOwned(account_);
        uint256 len = nftIds.length;
        uint256[] memory tokenIds;
        uint256[] memory amountOfTokensPerNFT = new uint256[](len);
        uint256[] memory lastestUpdated = new uint256[](len);

        for (uint256 i = 0; i < nftIds.length; i++) {
            (tokenIds, ) = getOwnedNFT(account_, nftIds[i]);
            amountOfTokensPerNFT[i] = tokenIds.length;
            lastestUpdated[i] = lastestUpdatedByNFT[nftIds[i]];
        }

        return (nftIds, amountOfTokensPerNFT, lastestUpdated);
    }

    function getNFT(
        bytes memory _nftId
    )
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            address[] memory,
            address[] memory,
            bool[] memory,
            bool[] memory
        )
    {
        NFT storage nft = nfts[_nftId];
        uint256 len = nft.tokenIds.length;
        uint256[] memory updatedAt = new uint256[](len);
        address[] memory ownerList = new address[](len);
        address[] memory mintedBy = new address[](len);
        bool[] memory isAdmin = new bool[](len);
        bool[] memory isMintedByAdmin = new bool[](len);

        for (uint256 i = 0; i < len; i++) {
            ownerList[i] = owners[nft.tokenIds[i]].owner;
            isAdmin[i] = IProxy(controller).isAdmin(ownerList[i]);
            mintedBy[i] = nft.mintedBy[nft.tokenIds[i]];
            isMintedByAdmin[i] = IProxy(controller).isAdmin(mintedBy[i]);
            updatedAt[i] = owners[nft.tokenIds[i]].updatedAt;
        }

        return (
            nft.tokenIds,
            updatedAt,
            ownerList,
            mintedBy,
            isAdmin,
            isMintedByAdmin
        );
    }
}
