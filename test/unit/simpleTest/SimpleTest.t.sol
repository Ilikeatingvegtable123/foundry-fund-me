// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";

contract SimpleTest is Test {
    uint256 simpleNumber; // 0

    function setUp() external {
        simpleNumber = 5;
    }

    function testIfSimpleNumberIsFive() public view {
        console.log("Simple Number:", simpleNumber);
        assertEq(simpleNumber, 5);
    }
}
