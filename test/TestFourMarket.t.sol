// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "src/FourMarket.sol";
import "src/Market.sol";

contract FourMarketTest is Test {
    FourMarket fourMarket;
    address user1;
    address user2;
    uint256 depositValue;

    event MarketCreated(
        uint256 indexed marketId,
        string question,
        string details,
        uint256 deadline,
        uint256 resolutionTime,
        address indexed resolver
    );

    function setUp() public {
        fourMarket = new FourMarket();
        user1 = address(0x1);
        user2 = address(0x2);
        depositValue = fourMarket.DEPOSIT_VALUE();
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    function testCreateMarket() public {
        vm.prank(user1);
        string memory question = "Will it rain tomorrow?";
        string memory details = "Some details";
        uint256 deadline = block.timestamp + 1 days;
        uint256 resolutionTime = 1 days + 1;
        address resolver = address(0x3);

        vm.expectEmit(true, true, true, true);
        emit MarketCreated(0, question, details, deadline, resolutionTime, resolver);

        fourMarket.createMarket{value: depositValue}(question, details, deadline, resolutionTime, resolver);

        (,,,,,,, address i_resolver,,,,,) = fourMarket.getDeployedMarket(0);
        assertEq(i_resolver, resolver);
    }

    function testCreateMarketWithoutDeposit() public {
        vm.prank(user1);
        string memory question = "Will it rain tomorrow?";
        string memory details = "Some details";
        uint256 deadline = block.timestamp + 1 days;
        uint256 resolutionTime = 1 days + 1;
        address resolver = address(0x3);

        vm.expectRevert();
        fourMarket.createMarket{value: 0}(question, details, deadline, resolutionTime, resolver);
    }

    function testRefundDeposit() public {
        vm.prank(user1);
        string memory question = "Will it rain tomorrow?";
        string memory details = "Some details";
        uint256 deadline = block.timestamp + 1 days;
        uint256 resolutionTime = 1 days + 1;
        address resolver = address(0x3);

        fourMarket.createMarket{value: depositValue}(question, details, deadline, resolutionTime, resolver);

        Market market = fourMarket.markets(0);

        vm.prank(user1);
        // Place a bet so that total supply of yesToken + noToken >= DEPOSIT_VALUE
        vm.prank(user1);
        market.bet{value: depositValue}(Market.outcomeType.Yes);

        // Now user1 should be able to refund deposit
        uint256 balanceBefore = user1.balance;
        vm.prank(user1);
        fourMarket.refundDeposit(market);
        uint256 balanceAfter = user1.balance;

        assertEq(balanceAfter - balanceBefore, depositValue);
    }

    function testCannotRefundDepositTooEarly() public {
        vm.prank(user1);
        string memory question = "Will it rain tomorrow?";
        string memory details = "Some details";
        uint256 deadline = block.timestamp + 1 days;
        uint256 resolutionTime = 1 days + 1;
        address resolver = address(0x3);

        fourMarket.createMarket{value: depositValue}(question, details, deadline, resolutionTime, resolver);

        Market market = fourMarket.markets(0);

        // No bets placed, total supply of yesToken + noToken < DEPOSIT_VALUE

        vm.prank(user1);
        vm.expectRevert();
        fourMarket.refundDeposit(market);
    }

    function testFuzzCreateMarket(
        string memory question,
        string memory details,
        uint256 deadlineOffset,
        uint256 resolutionTimeOffset
    ) public {
        vm.assume(deadlineOffset > 0 && deadlineOffset < 365 days);
        vm.assume(resolutionTimeOffset > 1 days && resolutionTimeOffset < 365 days);
        vm.prank(user1);
        uint256 deadline = block.timestamp + deadlineOffset;
        uint256 resolutionTime = resolutionTimeOffset;
        address resolver = address(0x3);

        fourMarket.createMarket{value: depositValue}(question, details, deadline, resolutionTime, resolver);
    }
}
