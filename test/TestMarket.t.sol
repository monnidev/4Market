// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "src/Market.sol";
import "src/Token.sol";

contract MarketTest is Test {
    Market market;
    Token yesToken;
    Token noToken;
    address user1;
    address user2;
    address resolver;
    uint256 marketId;
    string question;
    string details;
    uint256 deadline;
    uint256 resolutionTime;

    function setUp() public {
        user1 = address(0x1);
        user2 = address(0x2);
        resolver = address(0x3);
        marketId = 1;
        question = "Will it rain tomorrow?";
        details = "Some details";
        deadline = block.timestamp + 1 days;
        resolutionTime = 1 days + 1; // needs to be greater than 1 day

        market = new Market(marketId, question, details, deadline, resolutionTime, resolver);

        yesToken = market.s_yesToken();
        noToken = market.s_noToken();

        // Provide some initial balance to users
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    function testCannotBetAfterDeadline() public {
        vm.warp(deadline + 1);
        vm.prank(user1);
        vm.expectRevert(Market.Market__BettingClosed.selector);
        market.bet{value: 1 ether}(Market.outcomeType.Yes);
    }

    function testCannotBetOnNeither() public {
        vm.prank(user1);
        vm.expectRevert(Market.Market__InvalidBetOutcome.selector);
        market.bet{value: 1 ether}(Market.outcomeType.Neither);
    }

    function testBetYes() public {
        vm.prank(user1);
        market.bet{value: 1 ether}(Market.outcomeType.Yes);
        assertEq(yesToken.balanceOf(user1), 1 ether);
        assertEq(market.s_balance(), 1 ether);
    }

    function testBetNo() public {
        vm.prank(user1);
        market.bet{value: 1 ether}(Market.outcomeType.No);
        assertEq(noToken.balanceOf(user1), 1 ether);
        assertEq(market.s_balance(), 1 ether);
    }

    function testResolveTooEarly() public {
        vm.prank(resolver);
        vm.expectRevert(Market.Market__ResolveTooEarly.selector);
        market.resolve(Market.outcomeType.Yes);
    }

    function testResolveTooLate() public {
        vm.warp(deadline + resolutionTime + 1);
        vm.prank(resolver);
        vm.expectRevert(Market.Market__ResolveTooLate.selector);
        market.resolve(Market.outcomeType.Yes);
    }

    function testResolve() public {
        vm.warp(deadline);
        vm.prank(resolver);
        market.resolve(Market.outcomeType.Yes);
        (,,,,,,,, bool resolved,,,,) = market.getMarketDetails();
        assertTrue(resolved);
    }

    function testCannotResolveTwice() public {
        vm.warp(deadline);
        vm.prank(resolver);
        market.resolve(Market.outcomeType.Yes);
        vm.prank(resolver);
        vm.expectRevert(Market.Market__AlreadyResolved.selector);
        market.resolve(Market.outcomeType.No);
    }

    function testDistributeRewardsYesWins() public {
        vm.prank(user1);
        market.bet{value: 1 ether}(Market.outcomeType.Yes);
        vm.prank(user2);
        market.bet{value: 1 ether}(Market.outcomeType.No);

        vm.warp(deadline);
        vm.prank(resolver);
        market.resolve(Market.outcomeType.Yes);

        vm.prank(user1);
        uint256 balanceBefore = user1.balance;
        market.distribute();
        uint256 balanceAfter = user1.balance;
        assertEq(balanceAfter - balanceBefore, 2 ether); // Should get the whole pot
    }

    function testDistributeRewardsNoWins() public {
        vm.prank(user1);
        market.bet{value: 1 ether}(Market.outcomeType.Yes);
        vm.prank(user2);
        market.bet{value: 1 ether}(Market.outcomeType.No);

        vm.warp(deadline);
        vm.prank(resolver);
        market.resolve(Market.outcomeType.No);

        vm.prank(user2);
        uint256 balanceBefore = user2.balance;
        market.distribute();
        uint256 balanceAfter = user2.balance;
        assertEq(balanceAfter - balanceBefore, 2 ether);
    }

    function testDistributeRewardsNeither() public {
        vm.prank(user1);
        market.bet{value: 1 ether}(Market.outcomeType.Yes);
        vm.prank(user2);
        market.bet{value: 1 ether}(Market.outcomeType.No);

        vm.warp(deadline + resolutionTime + 1);
        market.inactivityCancel();

        vm.prank(user1);
        uint256 balanceBefore1 = user1.balance;
        market.distribute();
        uint256 balanceAfter1 = user1.balance;
        assertEq(balanceAfter1 - balanceBefore1, 1 ether);

        vm.prank(user2);
        uint256 balanceBefore2 = user2.balance;
        market.distribute();
        uint256 balanceAfter2 = user2.balance;
        assertEq(balanceAfter2 - balanceBefore2, 1 ether);
    }

    function testCannotDistributeTwice() public {
        vm.prank(user1);
        market.bet{value: 1 ether}(Market.outcomeType.Yes);

        vm.warp(deadline);
        vm.prank(resolver);
        market.resolve(Market.outcomeType.Yes);

        vm.prank(user1);
        market.distribute();

        vm.prank(user1);
        vm.expectRevert(Market.Market__NoTokensToClaim.selector);
        market.distribute();
    }

    function testCannotDistributeIfNotResolved() public {
        vm.prank(user1);
        market.bet{value: 1 ether}(Market.outcomeType.Yes);

        vm.prank(user1);
        vm.expectRevert(Market.Market__NotResolved.selector);
        market.distribute();
    }

    function testInactivityCancelTooEarly() public {
        vm.warp(deadline + resolutionTime - 1);
        vm.expectRevert(Market.Market__InactivityPeriodNotReached.selector);
        market.inactivityCancel();
    }

    function testInactivityCancelAfterPeriod() public {
        vm.warp(deadline + resolutionTime + 1);
        market.inactivityCancel();
        (,,,,,,,, bool resolved,,,,) = market.getMarketDetails();
        assertTrue(resolved);
    }

    function testFuzzBet(uint256 amount) public {
        vm.assume(amount > 0 && amount < 100 ether);
        vm.prank(user1);
        market.bet{value: amount}(Market.outcomeType.Yes);
        assertEq(yesToken.balanceOf(user1), amount);
        assertEq(market.s_balance(), amount);
    }

    function testFuzzDistribute(uint256 amountYes, uint256 amountNo) public {
        vm.assume(amountYes > 0 && amountYes < 100 ether);
        vm.assume(amountNo > 0 && amountNo < 100 ether);

        vm.prank(user1);
        market.bet{value: amountYes}(Market.outcomeType.Yes);
        vm.prank(user2);
        market.bet{value: amountNo}(Market.outcomeType.No);

        vm.warp(deadline);
        vm.prank(resolver);
        market.resolve(Market.outcomeType.Yes);

        vm.prank(user1);
        uint256 balanceBefore = user1.balance;
        market.distribute();
        uint256 balanceAfter = user1.balance;
        assertEq(balanceAfter - balanceBefore, amountYes + amountNo);
    }

    function invariant_s_balanceNonNegative() public {
        assertTrue(market.s_balance() >= 0);
    }

    function invariant_TotalSupplyConsistency() public {
        uint256 totalSupplyYes = yesToken.totalSupply();
        uint256 totalSupplyNo = noToken.totalSupply();
        // Total tokens minus initial mints should not exceed s_balance
        uint256 adjustedSupplyYes = totalSupplyYes > 1 ? totalSupplyYes - 1 : 0;
        uint256 adjustedSupplyNo = totalSupplyNo > 1 ? totalSupplyNo - 1 : 0;
        uint256 totalAdjustedSupply = adjustedSupplyYes + adjustedSupplyNo;
        assertTrue(totalAdjustedSupply <= market.s_balance());
    }
}
