// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Deploy4Market} from "../script/Deploy4Market.s.sol";
import {FourMarket} from "../src/Creator.sol";
import {Market} from "../src/Market.sol";
import {Token} from "../src/Token.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {Vm} from "../lib/forge-std/src/Vm.sol";
import {StdCheats} from "../lib/forge-std/src/StdCheats.sol";

contract FourMarketTest is StdCheats, Test {
    Deploy4Market public s_deployer;
    FourMarket public s_4Market;

    /// @notice Set up the environment for each test, deploying contracts and funding test accounts
    function setUp() external {
        s_deployer = new Deploy4Market();
        s_4Market = s_deployer.run();
    }

    function testSomething() external {}
}
