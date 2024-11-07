// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "../lib/forge-std/src/Script.sol";
import {FourMarket} from "../src/Creator.sol";

contract Deploy4Market is Script {
    function run() external returns (FourMarket) {
        vm.startBroadcast();
        FourMarket _fourMarket = new FourMarket();
        vm.stopBroadcast();
        return (_fourMarket);
    }
}
