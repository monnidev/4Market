// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// we could add erc20s, ownership, upgradability, fees, appeal system, other types of markets, web ui, tests
// resolver can be a eoa, an oracle, a llm....
// consider rewriting in yul with differential testing

import {Market} from "./Market.sol";

contract FourMarket {
    mapping(uint256 => Market) public markets;

    uint256 nextMarketId;

    constructor() {}

    function createMarket(
        string memory constQuestion,
        string memory constDetails,
        uint256 constDeadline,
        uint256 constResolutionTime,
        address constResolver
    ) external {
        Market market =
            new Market(nextMarketId, constQuestion, constDetails, constDeadline, constResolutionTime, constResolver);
        markets[nextMarketId] = market;
        nextMarketId++;
    }
}
