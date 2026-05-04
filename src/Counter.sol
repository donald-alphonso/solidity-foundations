// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    address public immutable owner;
    uint256 public number;

    error NotOwner();
    error CannotDecrementBelowZero();

    event NumberChanged(uint256 indexed oldValue, uint256 indexed newValue, address indexed by);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setNumber(uint256 newNumber) external onlyOwner {
        emit NumberChanged(number, newNumber, msg.sender);
        number = newNumber;
    }

    function increment() external {
        emit NumberChanged(number, number + 1, msg.sender);
        number++;
    }

    function decrement() external {
        if (number == 0) revert CannotDecrementBelowZero();
        emit NumberChanged(number, number - 1, msg.sender);
        number--;
    }
}
