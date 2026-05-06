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
    error NoTipsToWithdraw();
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

    function tip(string calldata message) external payable {
        if (msg.value == 0) revert NoTipsToWithdraw(); // pas de tip à 0
        if (bytes(message).length == 0) revert EmptyMessage();

        tips.push(Tip({
            from: msg.sender,
            amount: msg.value,
            message: message,
            timestamp: block.timestamp
        }));

        tipsByAddress[msg.sender] += msg.value;
        totalTips += msg.value;
        tipCount++;

        emit TipReceived(msg.sender, msg.value, message);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoTipsToWithdraw();

        (bool success, ) = payable(owner).call{value: balance}("");
        if (!success) revert TransferFailed();

        emit Withdrawn(owner, balance);
    }

    function getTipCount() external view returns (uint256) {
        return tips.length;
    }

    // Reçoit de l'ETH envoyé sans data (ex: wallet qui envoie juste de l'ETH)
    receive() external payable {
        tips.push(Tip({
            from: msg.sender,
            amount: msg.value,
            message: "(no message)",
            timestamp: block.timestamp
        }));
        tipsByAddress[msg.sender] += msg.value;
        totalTips += msg.value;
        tipCount++;

        emit TipReceived(msg.sender, msg.value, "(no message)");
    }

    // Fallback : appelé si la signature ne match aucune fonction
    fallback() external payable {
        revert("Unknown function called");
    }
}
