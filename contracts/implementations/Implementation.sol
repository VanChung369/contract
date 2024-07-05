// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Upgradeable} from "../common/Upgradeable.sol";
import "../interfaces/IProxy.sol";

contract Implementation is Upgradeable {
    constructor(address _proxy) Upgradeable(_proxy) {}

    function setCollection721(
        address _collection721
    )
        public
        notCurrentAddress(collection721, _collection721)
        notZeroAddress(_collection721)
        onlyOwner
    {
        collection721 = _collection721;
    }

    function setCollection1155(
        address _collection1155
    )
        public
        notCurrentAddress(collection1155, _collection1155)
        notZeroAddress(_collection1155)
        onlyOwner
    {
        collection1155 = _collection1155;
    }

    function setMintHandler(
        address _mintHandler
    )
        public
        notCurrentAddress(mintHandler, _mintHandler)
        notZeroAddress(_mintHandler)
        onlyOwner
    {
        mintHandler = _mintHandler;
    }

    function setAdminMintHandler(
        address _adminMintHandler
    )
        public
        notCurrentAddress(adminMintHandler, _adminMintHandler)
        notZeroAddress(_adminMintHandler)
        onlyOwner
    {
        adminMintHandler = _adminMintHandler;
    }

    function setBuyHandler(
        address _buyHandler
    )
        public
        notCurrentAddress(buyHandler, _buyHandler)
        notZeroAddress(_buyHandler)
        onlyOwner
    {
        buyHandler = _buyHandler;
    }

    function setCancelHandler(
        address _cancelHandler
    )
        public
        notCurrentAddress(cancelHandler, _cancelHandler)
        notZeroAddress(_cancelHandler)
        onlyOwner
    {
        cancelHandler = _cancelHandler;
    }

    function setAdminList(address _account, bool _value) public onlyOwner {
        adminList[_account] = _value;

        emit SetAdminEvent(_account, _value);
    }

    function setBlackList(address _account, bool _value) public onlyAdmins {
        blackList[_account] = _value;
    }

    function setWhiteList(address _account, bool _value) public onlyAdmins {
        whiteList[_account] = _value;
    }

    function setSigner(
        address _account
    )
        public
        notCurrentAddress(signer, _account)
        notZeroAddress(_account)
        onlyAdmins
    {
        signer = _account;
        emit SetSignerEvent(_account);
    }

    function setRecipient(
        address _account
    )
        public
        notCurrentAddress(recipient, _account)
        notZeroAddress(_account)
        onlyAdmins
    {
        recipient = _account;
    }

    function isAdmin(address _account) public view returns (bool) {
        return adminList[_account] || _account == IProxy(proxy).proxyOwner();
    }

    function isBlacklisted(address _account) public view returns (bool) {
        return blackList[_account];
    }

    function isWhitelisted(address _account) public view returns (bool) {
        return whiteList[_account];
    }

    function isSigner(address _account) public view returns (bool) {
        return signer == _account;
    }
}
