// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "lib/forge-std/src/Test.sol";
import "src/FourMarket.sol";
import "src/Market.sol";

contract FourMarketTest is Test {
    FourMarket fourMarket;
    address router;

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
        router = address(fourMarket);
    }

    function testCreateMarkets(
        uint256 amountOfMarkets,
        address user,
        string memory question,
        string memory details,
        uint256 deadline,
        uint256 resolutionTime,
        address resolver
    ) public {
        vm.assume(amountOfMarkets < 100);
        for (uint256 i = 0; i < amountOfMarkets; i++) {
            vm.deal(user, 10 ether);

            vm.prank(user);

            if (deadline <= block.timestamp || resolutionTime <= 1 days) {
                vm.expectRevert();
                fourMarket.createMarket(question, details, deadline, resolutionTime, resolver);
            } else {
                vm.expectEmit();
                emit MarketCreated(i, question, details, deadline, resolutionTime, resolver);
                Market market = fourMarket.createMarket(question, details, deadline, resolutionTime, resolver);

                // Retrieve and check all parameters from getMarketDetails()
                (
                    address _router1,
                    ,
                    ,
                    string memory _question1,
                    string memory _details1,
                    uint256 _deadline1,
                    uint256 _resolutionTime1,
                    address _resolver1,
                    ,
                    ,
                    ,
                    ,
                ) = market.getMarketDetails();

                // Check all retrieved parameters
                assertEq(_router1, router);
                assertEq(_question1, question);
                assertEq(_details1, details);
                assertEq(_deadline1, deadline);
                assertEq(_resolutionTime1, resolutionTime);
                assertEq(_resolver1, resolver);

                // Repeat the checks for the deployed market directly from FourMarket
                (
                    address _router2,
                    ,
                    ,
                    string memory _question2,
                    string memory _details2,
                    uint256 _deadline2,
                    uint256 _resolutionTime2,
                    address _resolver2,
                    ,
                    ,
                    ,
                    ,
                ) = fourMarket.getDeployedMarket(i);

                // Verify the market data retrieved from FourMarket
                assertEq(_router2, router);
                assertEq(_question2, question);
                assertEq(_details2, details);
                assertEq(_deadline2, deadline);
                assertEq(_resolutionTime2, resolutionTime);
                assertEq(_resolver2, resolver);
            }
        }
    }
}
