// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TipJar} from "../src/TipJar.sol";

contract RejectsEth {
    TipJar public jar;

    constructor() {
        jar = new TipJar();
    }

    function callWithdraw() external {
        jar.withdraw();
    }
}

contract TipJarTest is Test {
    TipJar public jar;
    address public owner;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    event TipReceived(address indexed from, uint256 amount, string message);

    receive() external payable {}

    function setUp() public {
        owner = address(this);
        jar = new TipJar();
        // Donne 10 ETH à Alice et Bob pour qu'ils puissent tip
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function test_TipIncreasesTotal() public {
        vm.prank(alice);
        jar.tip{value: 1 ether}("Nice contract");

        assertEq(jar.totalTips(), 1 ether);
        assertEq(jar.tipCount(), 1);
        assertEq(jar.tipsByAddress(alice), 1 ether);
        assertEq(address(jar).balance, 1 ether);
    }

    function test_TipRevertWithZeroValue() public {
        vm.prank(alice);
        vm.expectRevert(TipJar.NoTipsToWithdraw.selector);
        jar.tip{value: 0}("hi");
    }

    function test_TipRevertsWithEmptyMessage() public {
        vm.prank(alice);
        vm.expectRevert(TipJar.EmptyMessage.selector);
        jar.tip{value: 1 ether}("");
    }

    function test_WithdrawSendsBalanceToOwner() public {
        vm.prank(alice);
        jar.tip{value: 2 ether}("for you");

        uint256 ownerBalanceBefore = owner.balance;
        jar.withdraw();
        uint256 ownerBalanceAfter = owner.balance;

        assertEq(ownerBalanceAfter - ownerBalanceBefore, 2 ether);
        assertEq(address(jar).balance, 0);
    }

    function test_WithdrawRevertsWhenTransferFails() public {
        RejectsEth rejector = new RejectsEth();
        TipJar jar2 = rejector.jar();

        vm.deal(alice, 1 ether);
        vm.prank(alice);
        jar2.tip{value: 1 ether}("hi");

        vm.expectRevert(TipJar.TransferFailed.selector);
        rejector.callWithdraw();
    }

    function test_WithdrawRevertsWhenBalanceIsZero() public {
        vm.expectRevert(TipJar.NoTipsToWithdraw.selector);
        jar.withdraw();
    }

    function test_GetTipCountReturnsTipsLength() public {
        assertEq(jar.getTipCount(), 0);

        vm.prank(alice);
        jar.tip{value: 1 ether}("hi");

        assertEq(jar.getTipCount(), 1);
    }

    function test_WithdrawRevertsForNonOwner() public {
        vm.prank(alice);
        jar.tip{value: 1 ether}("hi");

        vm.prank(bob);
        vm.expectRevert(TipJar.NotOwner.selector);
        jar.withdraw();
    }

    function test_ReceiveAcceptsRawEth() public {
        vm.prank(alice);
        (bool success,) = address(jar).call{value: 0.5 ether}("");
        assertTrue(success);
        assertEq(jar.totalTips(), 0.5 ether);
        assertEq(jar.tipCount(), 1);
    }

    function test_FallbackReverts() public {
        vm.prank(alice);
        (bool success,) = address(jar).call{value: 1 ether}(abi.encodeWithSignature("inexistantFunction()"));
        assertFalse(success);
    }

    function testFuzz_TipAmounts(uint96 amount) public {
        vm.assume(amount > 0);
        vm.deal(alice, amount);
        vm.prank(alice);
        jar.tip{value: amount}("fuzz");

        assertEq(jar.totalTips(), amount);
        assertEq(address(jar).balance, amount);
    }

    function test_GetRecentTipsWithNoTips() public view {
        TipJar.Tip[] memory recent = jar.getRecentTips(5);

        assertEq(recent.length, 0);
    }

    function test_GetRecentTipsWithOneTip() public {
        vm.prank(alice);
        jar.tip{value: 1 ether}("hello");

        TipJar.Tip[] memory recent = jar.getRecentTips(1);

        assertEq(recent.length, 1);
        assertEq(recent[0].from, alice);
        assertEq(recent[0].amount, 1 ether);
        assertEq(recent[0].message, "hello");
    }

    function test_GetRecentTipsReturnsMostRecentFirst() public {
        vm.prank(alice);
        jar.tip{value: 1 ether}("first");

        vm.prank(bob);
        jar.tip{value: 2 ether}("second");

        TipJar.Tip[] memory recent = jar.getRecentTips(2);

        assertEq(recent.length, 2);

        // Le plus récent doit être bob
        assertEq(recent[0].from, bob);
        assertEq(recent[0].amount, 2 ether);
        assertEq(recent[0].message, "second");

        // Puis alice
        assertEq(recent[1].from, alice);
        assertEq(recent[1].amount, 1 ether);
        assertEq(recent[1].message, "first");
    }

    function test_GetRecentTipsWhenNExceedsTipCount() public {
        vm.prank(alice);
        jar.tip{value: 1 ether}("only tip");

        TipJar.Tip[] memory recent = jar.getRecentTips(10);

        assertEq(recent.length, 1);
        assertEq(recent[0].from, alice);
    }

    function test_TopTipperWithNoTips() public view {
        (address top, uint256 amount) = jar.topTipper();

        assertEq(top, address(0));
        assertEq(amount, 0);
    }

    function test_TopTipperReturnsHighestContributor() public {
        vm.prank(alice);
        jar.tip{value: 1 ether}("a");

        vm.prank(bob);
        jar.tip{value: 3 ether}("b");

        (address top, uint256 amount) = jar.topTipper();

        assertEq(top, bob);
        assertEq(amount, 3 ether);
    }

    function test_TopTipperAccumulatesMultipleTips() public {
        vm.prank(alice);
        jar.tip{value: 2 ether}("first");

        vm.prank(alice);
        jar.tip{value: 2 ether}("second");

        vm.prank(bob);
        jar.tip{value: 3 ether}("third");

        (address top, uint256 amount) = jar.topTipper();

        // Alice = 4 ETH total
        // Bob = 3 ETH total
        assertEq(top, alice);
        assertEq(amount, 4 ether);
    }
}
