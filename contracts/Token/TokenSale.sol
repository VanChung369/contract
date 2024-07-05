// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSale is Ownable {
    IERC20 public token;
    uint256 public rate = 2; // 1 MATIC = 2 tokens

    event TokensPurchased(
        address indexed purchaser,
        uint256 amountMATIC,
        uint256 amountTokens
    );

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
    }

    receive() external payable {
        buyTokens();
    }

    function buyTokens() public payable {
        uint256 maticAmount = msg.value;
        require(maticAmount > 0, "You need to send some MATIC");

        uint256 tokenAmount = maticAmount * rate;
        uint256 contractBalance = token.balanceOf(address(this));
        require(
            contractBalance >= tokenAmount,
            "Not enough tokens in the contract"
        );

        token.transfer(msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, maticAmount, tokenAmount);
    }

    function withdrawMATIC() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawTokens(uint256 amount) external onlyOwner {
        token.transfer(owner(), amount);
    }
}
