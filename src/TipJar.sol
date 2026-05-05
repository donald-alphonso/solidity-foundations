// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.24;

contract TipJar {
    address public immutable owner;
    uint256 public totalTips; // total ETH reçu, en wei
    uint256 public tipCount; // nombre de tips reçus

    struct Tip {
        address from;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    Tip[] public tips;
    mapping(address => uint256) public tipsByAddress; // total wei donné par adresse

    error NotOwner();
    error NoTipsToWithDraw();
    error TransferFailed();
    error EmptyMessage();

    event TipReceived(address indexed from, uint256 amount, string message);
    event Withdrawn(address indexed to, uint256 amount);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
    }
}