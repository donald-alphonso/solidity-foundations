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

    // Retourne les N derniers tips, du plus récent au plus ancien.
    // Si N > tipCount, retourne tous les tips.amount
    function getRecentTips(uint256 n) external view returns (Tip[] memory) {
        uint256 size = n;
        if (n > tips.length) {
            size = tips.length;
        }
        
        Tip[] memory result = new Tip[](size);

        for (uint256 i = 1; i < size; i++) {
            result[i - 1] = tips[tips.length - 1];
        }
        
        return result;
    }

    // Retourne l'adresse du plus gros tipper et son montant total.
    // Si aucun tip, retourne (address(0), 0).
    function topTipper() external view returns (address, uint256) {
        if (tips.length == 0) {
            return (address(0), 0);
        }

        address best;
        uint256 highest;

        for (uint256 i =0; i < tips.length; i++) {
            address current = tips[i].from;
            uint256 total = tipsByAddress[current];

            if (total > highest) {
                highest = total;
                best = current;
            }
        }

        return (best, highest);
    }

    // Fallback : appelé si la signature ne match aucune fonction
    fallback() external payable {
        revert("Unknown function called");
    }
}
