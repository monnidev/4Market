// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// we could add erc20s, ownership, upgradability, fees, appeal system, other types of markets, web ui, tests
// resolver can be a eoa, an oracle, a llm....
// consider rewriting in yul with differential testing

import {Market} from "./Market.sol";

contract FourMarket {
    /// @notice Mapping of market IDs to their respective Market contracts.
    mapping(uint256 => Market) public markets;

    /// @dev Tracks the next market ID to be assigned.
    uint256 private s_nextMarketId;

    /// @notice Event emitted upon the creation of a new market.
    /// @param marketId The ID of the newly created market.
    /// @param question The question associated with the market.
    /// @param details Additional details about the market.
    /// @param deadline The closing timestamp for new participants.
    /// @param resolutionTime Expected resolution timestamp for the market.
    /// @param resolver Address of the entity responsible for resolving the market.
    event MarketCreated(
        uint256 indexed marketId,
        string question,
        string details,
        uint256 deadline,
        uint256 resolutionTime,
        address indexed resolver
    );

    /// @dev Custom error for cases where a market ID does not exist.
    error MarketIdDoesNotExist();

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
    ) external {
        uint256 _nextMarketId = s_nextMarketId;
        Market market = new Market(_nextMarketId, _question, _details, _deadline, _resolutionTime, _resolver);
        markets[_nextMarketId] = market;
        s_nextMarketId++;

        // Emit the MarketCreated event with relevant details
        emit MarketCreated(_nextMarketId, _question, _details, _deadline, _resolutionTime, _resolver);
    }

    /**
     * @notice Retrieves the details of a deployed market by its ID.
     * @dev Due to this function --via-ir is required to avoid 'Stack too deep' errors.
     * @param _marketId The ID of the market to retrieve.
     * @return i_router Address of the router associated with the market.
     * @return i_marketId ID of the market.
     * @return s_balance Current balance of the market.
     * @return s_question The question being addressed in the market.
     * @return s_details Additional details about the market.
     * @return i_deadline Deadline timestamp for market participation.
     * @return i_resolutionTime Time at which the market is expected to be resolved.
     * @return i_resolver Address of the resolver for the market.
     * @return s_resolved Indicates if the market has been resolved.
     * @return s_resolvedDate Timestamp of when the market was resolved.
     * @return s_finalResolution The final resolution outcome of the market.
     * @return s_yesToken Address of the "yes" token for the market.
     * @return s_noToken Address of the "no" token for the market.
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
        require(_marketId < s_nextMarketId, MarketIdDoesNotExist());
        return markets[_marketId].getMarketDetails();
    }

    fallback() external {
        revert();
    }
}
