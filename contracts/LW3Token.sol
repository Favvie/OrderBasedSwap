// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import ERC20 standard sol file
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LW3Token is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, 10 * 10 ** 18);
    }
}