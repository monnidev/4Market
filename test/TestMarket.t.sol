// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "lib/forge-std/src/Test.sol";
import "../src/FourMarket.sol";
import "../src/Market.sol";
import "../src/Token.sol";

contract MarketTest is Test {
    FourMarket public fourMarket;
    Market public market;
    Token public yesToken;
    Token public noToken;

    address public deployer = address(this);
    address public user1;
    address public user2;
    address public resolver;

    uint256 public deadline;
    uint256 public resolutionTime;

    function setUp() public {
        // Generate addresses to avoid using reserved addresses
        user1 = vm.addr(1);
        user2 = vm.addr(2);
        resolver = vm.addr(3);

        // Deploy the FourMarket contract
        fourMarket = new FourMarket();

        // Set up market parameters
        string memory question = "Will it rain tomorrow?";
        string memory details = "Weather forecast for city XYZ";
        deadline = block.timestamp + 1 days;
        resolutionTime = 2 days; // Must be greater than 1 day as per contract requirement

        // Create a new market
        market = fourMarket.createMarket(question, details, deadline, resolutionTime, resolver);

        // Retrieve the Yes and No tokens
        (,,,,,,,,,,, address yesTokenAddress, address noTokenAddress) = market.getMarketDetails();

        yesToken = Token(yesTokenAddress);
        noToken = Token(noTokenAddress);

        // Exclude the Token contracts from fuzzing
        excludeContract(address(yesToken));
        excludeContract(address(noToken));

        // Register the market contract for invariant testing
        targetContract(address(market));
    }

    /// @notice Test distributing rewards for "Yes" outcome
    function testDistributeYesOutcome() public {
        // User1 bets on Yes
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        market.bet{value: 1 ether}(Market.outcomeType.Yes);

        // User2 bets on No
        vm.deal(user2, 1 ether);
        vm.prank(user2);
        market.bet{value: 1 ether}(Market.outcomeType.No);

        // Fast forward to after the deadline
        vm.warp(deadline + 1);

        // Resolver resolves the market to "Yes"
        vm.prank(resolver);
        market.resolve(Market.outcomeType.Yes);

        // User1 approves the market to burn tokens
        vm.startPrank(user1);
        yesToken.approve(address(market), yesToken.balanceOf(user1));

        // User1 claims reward
        uint256 user1BalanceBefore = user1.balance;
        market.distribute();
        uint256 user1BalanceAfter = user1.balance;

        vm.stopPrank();

        // User1 should receive the entire market balance (since User2 bet on the losing outcome)
        assertApproxEqRel(user1BalanceAfter - user1BalanceBefore, 2 ether, 0.01e18);

        // User2 tries to claim but has no winning tokens
        vm.startPrank(user2);
        vm.expectRevert(Market.Market__NoTokensToClaim.selector);
        market.distribute();
        vm.stopPrank();
    }

    /// @notice Test placing a bet on "Yes" outcome
    function testBetYes() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        market.bet{value: 1 ether}(Market.outcomeType.Yes);

        uint256 userBalance = yesToken.balanceOf(user1);
        assertEq(userBalance, 1 ether);

        uint256 marketBalance = address(market).balance;
        assertEq(marketBalance, 1 ether);
    }

    /// @notice Test placing a bet on "No" outcome
    function testBetNo() public {
        vm.deal(user2, 1 ether);
        vm.prank(user2);
        market.bet{value: 1 ether}(Market.outcomeType.No);

        uint256 userBalance = noToken.balanceOf(user2);
        assertEq(userBalance, 1 ether);

        uint256 marketBalance = address(market).balance;
        assertEq(marketBalance, 1 ether);
    }

    /// @notice Test betting after the deadline
    function testBetAfterDeadline() public {
        vm.warp(deadline + 1);
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vm.expectRevert(Market.Market__BettingClosed.selector);
        market.bet{value: 1 ether}(Market.outcomeType.Yes);
    }

    /// @notice Test resolving the market too early
    function testResolveTooEarly() public {
        vm.prank(resolver);
        vm.expectRevert(Market.Market__ResolveTooEarly.selector);
        market.resolve(Market.outcomeType.Yes);
    }

    /// @notice Test resolving the market within the resolution time
    function testResolve() public {
        vm.warp(deadline + 1);
        vm.prank(resolver);
        market.resolve(Market.outcomeType.Yes);

        (,,,,,,,, bool resolved,,,,) = market.getMarketDetails();
        assertTrue(resolved);
    }

    /// @notice Test resolving the market too late
    function testResolveTooLate() public {
        vm.warp(deadline + resolutionTime + 1);
        vm.prank(resolver);
        vm.expectRevert(Market.Market__ResolveTooLate.selector);
        market.resolve(Market.outcomeType.Yes);
    }

    /// @notice Test distributing rewards before the market is resolved
    function testDistributeBeforeResolution() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        market.bet{value: 1 ether}(Market.outcomeType.Yes);

        vm.startPrank(user1);
        vm.expectRevert(Market.Market__NotResolved.selector);
        market.distribute();
        vm.stopPrank();
    }

    /// @notice Test inactivity cancellation
    function testInactivityCancel() public {
        vm.warp(deadline + resolutionTime + 1);
        vm.prank(user1);
        market.inactivityCancel();

        (,,,,,,,, bool resolved,, Market.outcomeType finalOutcome,,) = market.getMarketDetails();
        assertTrue(resolved);
        assertEq(uint8(finalOutcome), uint8(Market.outcomeType.Neither));
    }

    /// @notice Fuzz test for placing bets
    function testFuzzBet(uint256 amount) public {
        vm.assume(amount >= 0.1 ether && amount <= 1000 ether);
        vm.deal(user1, amount);
        vm.prank(user1);
        market.bet{value: amount}(Market.outcomeType.Yes);

        uint256 userBalance = yesToken.balanceOf(user1);
        assertEq(userBalance, amount);

        uint256 marketBalance = address(market).balance;
        assertEq(marketBalance, amount);
    }

    /// @notice Fuzz test for resolving with different outcomes
    function testFuzzResolve(uint8 outcome) public {
        vm.assume(outcome <= uint8(Market.outcomeType.No));

        vm.warp(deadline + 1);
        vm.prank(resolver);
        market.resolve(Market.outcomeType(outcome));

        (,,,,,,,, bool resolved,, Market.outcomeType finalOutcome,,) = market.getMarketDetails();
        assertTrue(resolved);
        assertEq(uint8(finalOutcome), outcome);
    }

    /// @notice Test that only deployer can mint tokens
    function testOnlyDeployerCanMint() public {
        vm.prank(user1);
        vm.expectRevert(Token.OnlyDeployerCanMint.selector);
        yesToken.mint(user1, 100);
    }

    /// @notice Test approving and burning tokens correctly
    function testApproveAndBurnTokens() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        market.bet{value: 1 ether}(Market.outcomeType.Yes);

        vm.warp(deadline + 1);
        vm.prank(resolver);
        market.resolve(Market.outcomeType.Yes);

        uint256 userTokenBalance = yesToken.balanceOf(user1);

        vm.startPrank(user1);
        yesToken.approve(address(market), userTokenBalance);
        market.distribute();
        vm.stopPrank();

        uint256 userTokenBalanceAfter = yesToken.balanceOf(user1);
        assertEq(userTokenBalanceAfter, 0);
    }

    /// @notice Test that burning tokens without approval fails
    function testBurnWithoutApproval() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        market.bet{value: 1 ether}(Market.outcomeType.Yes);

        vm.warp(deadline + 1);
        vm.prank(resolver);
        market.resolve(Market.outcomeType.Yes);

        vm.prank(user1);
        vm.expectRevert();
        market.distribute();
    }
}
