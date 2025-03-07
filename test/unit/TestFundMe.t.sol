// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @notice This file tests whether code works or not, it isn't the actual code used to run the funding
 */

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "src/FundMe.sol";
import {DeployFundMe} from "script/DeployFundMe.s.sol";

contract TestFundMe is Test {
    FundMe fundMe; // TestFundMe is the deployer of FundMe

    /// @dev makeAddr is from the forge-std library and creates address based on the name given
    address USER = makeAddr("user");
    // address OWNER = makeAddr("owner");

    uint256 constant SEND_VALUE = 1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    uint8 constant AGGREGATOR_INTERFACE_VERSION = 4; // Version of AggregatorV3Interface

    modifier fundedTest() {
        hoax(USER, STARTING_BALANCE);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    /**
     * @dev Tests if i_owner is the msg.sender (this contract)
     */
    function testIfOwnerIsMsgSender() public view {
        console.log(fundMe.getOwner(), msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    /**
     * @notice fundMe.MINIMMUM_USD() is supposed to be $5 (5e18 in decimal format)
     */
    function testIfMinimumUsdIsFiveDollars() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
        console.log("Minimum USD:", fundMe.MINIMUM_USD());
    }

    /**
     * @dev Tests if the priceFeed version used is accurate
     */
    function testIfPriceFeedVersionIsCorrect() public view {
        uint256 aggregatorV3InterfaceVersion = fundMe.getVersion();
        assertEq(aggregatorV3InterfaceVersion, AGGREGATOR_INTERFACE_VERSION);
    }

    /**
     * @dev Tests the MINIMUM_USD variable to see if it reverts if there's no value/value <$5 being sent when funding
     */
    function testIfFundingRevertsIfNotEnoughValueIsSent() public {
        vm.expectRevert(); // Expect revert
        fundMe.fund(); // No value sent (Reverts)
        // fubdMe.fund{value: 10e18}();
    }

    /**
     * @dev Checks to see if the funder's mapping increased when funding
     */
    function testIfFundingChangesFundingDataStructures() public fundedTest {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);

        console.log("USER:", USER);
        console.log("USER amount funded:", amountFunded);

        assertEq(amountFunded, SEND_VALUE);
    }

    function testIfFundingAddsFunderToArrayOfFunders() public fundedTest {
        uint256 newFunderArray = fundMe.getFunderArray().length;
        address newFunder = fundMe.getFunder(0);

        assertEq(newFunderArray, 1);
        assertEq(newFunder, USER);
    }

    function testOnlyOwnerCanWithdraw() public fundedTest {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawalsWithOneFunder() public fundedTest {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;

        assertEq(
            startingOwnerBalance + startingContractBalance,
            endingOwnerBalance
        );
        assertEq(endingContractBalance, 0);
    }

    function testWithdrawalsWithManyFunders() public fundedTest {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), STARTING_BALANCE);

            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        uint256 startingFunderArrayLength = fundMe.getFunderArray().length;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        uint256 endingFunderArrayLength = fundMe.getFunderArray().length;

        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
        assertEq(endingFunderArrayLength, 0);
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFunderArrayLength, 10);
    }

    // Cheaper withdraw: 523,624, Regular withdraw: 524,480

    // Prints storage data in FundMe
    function testPrintStorageData() public view {
        for (uint256 i = 0; i < 3; i++) {
            bytes32 value = vm.load(address(fundMe), bytes32(i));

            console.log("Value at location", i, ":");
            console.logBytes32(value);
        }

        console.log("PriceFeed address:", address(fundMe.getPriceFeed()));
    }
}
