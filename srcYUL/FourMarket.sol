// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// we could add erc20s, appeal system, other types of markets, web ui, tests, fees, deposit to prevent spam, bad stuff (ownable, uups)
// resolver can be a eoa, an oracle, a llm....
// consider rewriting in yul with differential testing

import {Market} from "./Market.sol";

contract FourMarket {
    /// @notice Mapping of market IDs to their respective Market contracts.
    mapping(uint256 => Market) public markets;

    /// @dev Tracks the next market ID to be assigned.
    uint256 public s_nextMarketId;

    // /// @notice Event emitted upon the creation of a new market.
    // /// @param marketId The ID of the newly created market.
    // /// @param question The question associated with the market.
    // /// @param details Additional details about the market.
    // /// @param deadline The closing timestamp for new participants.
    // /// @param resolutionTime Expected resolution timestamp for the market.
    // /// @param resolver Address of the entity responsible for resolving the market.
    // event MarketCreated(
    //     uint256 indexed marketId,
    //     string question,
    //     string details,
    //     uint256 deadline,
    //     uint256 resolutionTime,
    //     address indexed resolver
    // );
    bytes32 constant MarketCreatedEventTopic = 0xc7fae8c73c267c81d935ffafce8174b73c23106629b53942c363c53c2231be33;

    /// @dev Custom error for cases where a market ID does not exist.
    // error MarketIdDoesNotExist();
    bytes4 constant MarketIdDoesNotExistErrorSelector = 0xd2d9f43e;

    // address MarketContractAddess;
    // constructor() {
    //     MarketContractAddess = address(new Market);
    // }

    /**
     * @notice Creates a new market with the specified parameters.
     * @param _question The question for the market.
     * @param _details Additional details about the market.
     * @param _deadline The timestamp by which the market closes for new participants.
     * @param _resolutionTime The time by which the market is expected to be resolved.
     * @param _resolver Address of the entity responsible for resolving the market.
     */
    function createMarket(
        string memory _question,
        string memory _details,
        uint256 _deadline,
        uint256 _resolutionTime,
        address _resolver
    ) external returns (Market) {
        Market market = new Market(s_nextMarketId, _question, _details, _deadline, _resolutionTime, _resolver);
        assembly{
            // Assigns free memory pointer to `memptr`.
            let memptr := mload(0x40)

            // Store `_addr` in memory location `memptr`.
            mstore(memptr, sload(s_nextMarketId.slot))
            // Store the map's slot in memory location memptr+0x20.
            mstore(add(sload(s_nextMarketId.slot), 0x20), markets.slot)

            let marketSlot := keccak256(memptr, 0x40)
            sstore(marketSlot, market)

            // Emit the MarketCreated event with relevant details
            mstore(0x00, _question)
            mstore(0x20, _details)
            mstore(0x40, _deadline)
            mstore(0x60, _resolutionTime)
            mstore(0x80, _resolver)

            log2(0x40, 0x100, MarketCreatedEventTopic, sload(s_nextMarketId.slot))

            // increment s_nextMarketId
            sstore(s_nextMarketId.slot, add(sload(s_nextMarketId.slot), 1))

            // return market
            return(sload(market), 0x20)
        }

    }

    /**
     * @notice Retrieves the details of a deployed market by its ID.
     * @dev Due to this function --via-ir is required to avoid 'Stack too deep' errors.
     * @param _marketId The ID of the market to retrieve.
     * @return router Address of the router associated with the market.
     * @return marketId ID of the market.
     * @return balance Current balance of the market.
     * @return question The question being addressed in the market.
     * @return details Additional details about the market.
     * @return deadline Deadline timestamp for market participation.
     * @return resolutionTime Time at which the market is expected to be resolved.
     * @return resolver Address of the resolver for the market.
     * @return resolved Indicates if the market has been resolved.
     * @return resolvedDate Timestamp of when the market was resolved.
     * @return finalResolution The final resolution outcome of the market.
     * @return yesToken Address of the "yes" token for the market.
     * @return noToken Address of the "no" token for the market.
     */
    function getDeployedMarket(uint256 _marketId)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            string memory,
            string memory,
            uint256,
            uint256,
            address,
            bool,
            uint256,
            Market.outcomeType,
            address,
            address
        )
    {
        assembly {
            let numMarkets := sload(s_nextMarketId.slot)
            if not(lt(numMarkets,_marketId)){
                mstore(0x00, MarketIdDoesNotExistErrorSelector)
                revert(0x00, 0x04)
            }
        }
        return markets[_marketId].getMarketDetails();
    }

    fallback() external {
        revert();
    }
}
