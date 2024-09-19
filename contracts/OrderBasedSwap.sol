// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Create an order-based swap contract that allows users to deposit various kinds of tokens. 
//These tokens can be purchased by others with another token specified by the depositors. 
// For example; Ada deposits 100 GUZ tokens; she wants in return, 20 W3B tokens for the 100 GUZ tokens.
// Note: This has nothing to do with Uniswap.

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OrderBasedSwap {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    struct Token {
        address tokenAddress;
        uint amount;
    }

    struct Order {
        address creator;
        Token sellToken;
        Token buyToken;
        bool isFulfilled;
    }

    mapping(uint => Order) public orders;
    uint public orderCount;

    event OrderCreated(uint orderId, address user, address sellToken, address buyToken, uint sellAmount, uint buyAmount);
    event OrderFulfilled(uint orderId, address user, address sellToken, address buyToken, uint sellAmount, uint buyAmount);

    function createOrder(address sellToken, address buyToken, uint sellAmount, uint buyAmount) external {
        require(msg.sender != address(0), "Invalid user address");
        require(sellToken != buyToken, "Sell and buy tokens must be different");
        require(sellAmount > 0 && buyAmount > 0, "Amounts must be greater than zero");

        orders[orderCount] = Order(msg.sender, Token(sellToken, sellAmount), Token(buyToken, buyAmount), false);

        // check if the user has approved the contract to spend the sell amount
        require(IERC20(sellToken).allowance(msg.sender, address(this)) >= sellAmount, "Insufficient allowance");

        // check if the user has enough balance to supply the sell amount
        require(IERC20(sellToken).balanceOf(msg.sender) >= sellAmount, "Insufficient creator request balance");

        IERC20(sellToken).approve(address(this), sellAmount);

        // transfer tokens from user to contract
        require(IERC20(sellToken).transferFrom(msg.sender, address(this), sellAmount), "Insufficient creator request balance");

        emit OrderCreated(orderCount, msg.sender, sellToken, buyToken, sellAmount, buyAmount);
        orderCount++;
    }

    function fulfillOrder(uint orderId) external {
        require(orderId < orderCount, "Invalid order ID");

        Order storage order = orders[orderId];

        // check the buyer has enough balance to supply the buy amount
        require(IERC20(order.buyToken.tokenAddress).balanceOf(msg.sender) >= order.buyToken.amount, "Insufficient buyer request balance");

        // check the buyer has approved the contract to spend the buy amount
        require(IERC20(order.buyToken.tokenAddress).allowance(msg.sender, address(this)) >= order.buyToken.amount, "Insufficient allowance");

        IERC20(order.buyToken.tokenAddress).approve(address(this), order.buyToken.amount);

        // transfer tokens from buyer to seller
        require(IERC20(order.buyToken.tokenAddress).transferFrom(msg.sender, order.creator, order.buyToken.amount), "Insufficient buyer request balance");

        // transfer tokens from contract to buyer
        require(IERC20(order.sellToken.tokenAddress).transfer(msg.sender, order.sellToken.amount), "Insufficient contract balance");

        emit OrderFulfilled(orderId, msg.sender, order.sellToken.tokenAddress, order.buyToken.tokenAddress, order.sellToken.amount, order.buyToken.amount);

        order.isFulfilled = true;
    }

    function getOrder(uint orderId) external view returns (Order memory) {
        require(orderId < orderCount, "Invalid order ID");
        return orders[orderId];
    }

    function getAllOrders() external view returns (Order[] memory) {
        require(orderCount > 0, "No orders found");

        Order[] memory allOrders = new Order[](orderCount);
        for (uint i = 0; i < orderCount; i++) {
            allOrders[i] = orders[i];
        }
        return allOrders;
    }

}