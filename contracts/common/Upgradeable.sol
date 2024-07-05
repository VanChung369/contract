// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Structs.sol";
import "../interfaces/IProxy.sol";

contract Upgradeable is ReentrancyGuard {
    constructor(address _proxy) {
        proxy = _proxy;
    }

    address public immutable proxy;
    address public collection721;
    address public collection1155;
    address public mintHandler;
    address public buyHandler;
    address public cancelHandler;
    address public adminMintHandler;
    address public recipient;
    address public signer;

    mapping(address => bool) adminList;
    mapping(address => bool) blackList;
    mapping(address => bool) whiteList;

    mapping(bytes => bool) public invalidSaleOrder;
    mapping(bytes => uint256) public soldQuantityBySaleOrder;
    mapping(bytes => uint256) public soldQuantity;

    modifier onlyOwner() {
        require(
            msg.sender == IProxy(proxy).proxyOwner(),
            "Implementation: Only owner"
        );
        _;
    }

    modifier onlyAdmins() {
        require(
            adminList[msg.sender] || msg.sender == IProxy(proxy).proxyOwner(),
            "Implementation: Only admins"
        );
        _;
    }

    modifier notBlocked() {
        require(!blackList[msg.sender], "Implementation: Caller was blocked");
        _;
    }

    modifier notZeroAddress(address _addr) {
        require(_addr != address(0), "Implemenation: Receive a zero address");
        _;
    }

    modifier notCurrentAddress(address _current, address _target) {
        require(
            _target != _current,
            "Implementation: Cannot set to the current address"
        );
        _;
    }

    modifier notAdmins() {
        require(!adminList[msg.sender], "Implementation: Not for admins");
        _;
    }

    event SetAdminEvent(address indexed account, bool value);

    event SetSignerEvent(address indexed account);

    function _delegatecall(address _impl) internal virtual {
        require(
            _impl != address(0),
            "Implementation: impl address is zero address"
        );
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                sub(gas(), 10000),
                _impl,
                ptr,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}
