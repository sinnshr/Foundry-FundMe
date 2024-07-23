// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "..//../src/FundMe.sol";
import {DeployFundMe} from "..//../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");

    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    // uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinUSD() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersion() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFails() public {
        vm.expectRevert(); // next line should revert
        fundMe.fund();
    }

    function testFundUpdates() public {
        vm.prank(USER); //The next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArray() public {
        vm.prank(USER);

        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        _;
    }

    function testOnlyOwnerWithdraws() public funded {
        vm.expectRevert();
        vm.prank(USER);

        fundMe.withdraw();
    }

    function testWithdrawSingleFunder() public funded {
        //arrange

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //act

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawMultipleFunders() public funded {
        uint160 numOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numOfFunders; i++) {
            // vm.prank new address
            // vm.deal new address

            // hoax is prank + deal
            hoax(address(i), SEND_VALUE);

            // fund the fundMe

            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        // uint256 gasStart = gasleft(); // we have 1000 gas
        //vm.txGasPrice(GAS_PRICE); //tells the contract to spend gas
        vm.startPrank(fundMe.getOwner()); //we spent 200 gas

        fundMe.withdraw();

        // uint256 gasEnd = gasleft(); //we have 800 gas left
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; //gasprice: tells the current gas price

        // console.log(gasUsed);

        vm.stopPrank();

        //assert

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
