// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;
    address public alice = makeAddr("alice");

    event NumberChanged(uint256 indexed oldValue, uint256 indexed newValue, address indexed by);

    function setUp() public {
        counter = new Counter();
        // Le deployeur du contrat est `address(this)` - le contrat de test lui même
    }

    function test_OwnerIsDeployer() public view {
        assertEq(counter.owner(), address(this));
    }

    function test_InitialNumberIsZero() public view {
        assertEq(counter.number(), 0);
    }

    function test_IncrementIncreasesNumber() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function test_DecrementRevertsWhenZero() public {
        vm.expectRevert(Counter.CannotDecrementBelowZero.selector);
        counter.decrement();
    }

    function test_SetNumberRevertsForNonOwner() public {
        vm.prank(alice); // la prochaine call vient de alice
        vm.expectRevert(Counter.NotOwner.selector);
        counter.setNumber(42);
    }

    function test_SetNumberEmitsEvent() public {
        vm.expectEmit(true, true, true, true, address(counter));
        emit NumberChanged(0, 42, address(this));
        counter.setNumber(42);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
