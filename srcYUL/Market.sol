// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Token} from "./Token.sol";

/// @title Prediction Market Contract
/// @notice Allows users to bet on outcomes and distribute rewards accordingly.
contract Market {
    enum outcomeType {
        Neither,
        Yes,
        No
    }

    /// @notice The address of the router.
    address immutable i_router;
    /// @notice The unique ID of the market.
    uint256 immutable i_marketId;
    /// @notice The timestamp when betting closes.
    uint256 immutable i_deadline;
    /// @notice The time window for resolution.
    uint256 immutable i_resolutionTime;
    /// @notice The address responsible for resolving the market.
    address immutable i_resolver;

    /// @notice The total balance of the market.
    uint256 public s_balance;
    /// @notice The question being bet on.
    string private s_question;
    /// @notice Additional details about the market.
    string private s_details;
    /// @notice Indicates whether the market has been resolved.
    bool private s_resolved;
    /// @notice The final outcome of the market.
    outcomeType private s_finalResolution;
    /// @notice The timestamp when the market was resolved.
    uint256 private s_resolvedDate;
    /// @notice The token representing "Yes" bets.
    Token public s_yesToken;
    /// @notice The token representing "No" bets.
    Token public s_noToken;

    // Custom errors
    error Market__InvalidDeadline();
    error Market__InvalidResolutionTime();
    error Market__BettingClosed();
    error Market__InvalidBetOutcome();
    error Market__OnlyResolverCanResolve();
    error Market__ResolveTooEarly();
    error Market__ResolveTooLate();
    error Market__AlreadyResolved();
    error Market__NotResolved();
    error Market__NoTokensToClaim();
    error Market__InactivityPeriodNotReached();

    bytes4 constant Market__InvalidDeadlineErrorSelector = 0x70f87fad;
    bytes4 constant Market__InvalidResolutionTimeSelector = 0x8f5593f4;
    bytes4 constant Market__BettingClosedErrorSelector = 0xeb408886;
    bytes4 constant Market__InvalidBetOutcomeErrorSelector = 0xe8931e5e;
    bytes4 constant Market__OnlyResolverCanResolveErrorSelector = 0xcb2fc03f;
    bytes4 constant Market__ResolveTooEarlyErrorSelector = 0x90218b41;
    bytes4 constant Market__ResolveTooLateErrorSelector = 0xecf10b84;
    bytes4 constant Market__AlreadyResolvedErrorSelector = 0x3f94c6d6;
    bytes4 constant Market__NotResolvedErrorSelector = 0x07738aa3;
    bytes4 constant Market__NoTokensToClaimErrorSelector = 0x9f3ae793;
    bytes4 constant Market__InactivityPeriodNotReachedErrorSelector = 0x2a7b73b8;



    // Events
    // event BetPlaced(address indexed user, outcomeType outcome, uint256 amount);
    // event MarketResolved(outcomeType finalOutcome, uint256 resolvedDate);
    // event RewardsDistributed(address indexed user, uint256 rewardAmount);
    // event MarketCancelled(uint256 cancelledDate);

    bytes32 constant BetPlacedEventTopic = 0x9d0a25ce916e80804f775f0493f1f2d81653bd094ead4388dbdf5ea28c35c8d2;
    bytes32 constant MarketResolvedEventTopic = 0x55c41031e6fc864f2a00cf7433177f109b38f4ede57664c97dba0d7c138bffb4;
    bytes32 constant MarketCancelledEventTopic = 0x9d0a25ce916e80804f775f0493f1f2d81653bd094ead4388dbdf5ea28c35c8d2;
    bytes32 constant RewardsDistributedEventTopic = 0xdf29796aad820e4bb192f3a8d631b76519bcd2cbe77cc85af20e9df53cece086;

    /// @notice Initializes the market with given parameters.
    /// @param _marketId The unique ID of the market.
    /// @param _question The question being bet on.
    /// @param _details Additional details about the market.
    /// @param _deadline The timestamp when betting closes.
    /// @param _resolutionTime The time window for resolution.
    /// @param _resolver The address responsible for resolving the market.
    constructor(
        uint256 _marketId,
        string memory _question,
        string memory _details,
        uint256 _deadline,
        uint256 _resolutionTime,
        address _resolver
    ) {
        require(_deadline > block.timestamp, Market__InvalidDeadline());
        require(_resolutionTime > 1 days, Market__InvalidResolutionTime());
        i_router = msg.sender;
        i_marketId = _marketId;
        s_question = _question;
        s_details = _details;
        i_deadline = _deadline;
        i_resolutionTime = _resolutionTime;
        i_resolver = _resolver;
        s_yesToken = new Token(
            string(abi.encodePacked("Market ", i_marketId, ": Yes")), string(abi.encodePacked("MKT", i_marketId, "Y"))
        );
        s_noToken = new Token(
            string(abi.encodePacked("Market ", i_marketId, ": No")), string(abi.encodePacked("MKT", i_marketId, "N"))
        );
    }

    /// @notice Place a bet on the market.
    /// @param _betOutcome The outcome the user is betting on.
    function bet(outcomeType _betOutcome) public payable {
        address s_yesTokenAddress = address(s_yesToken);
        address s_noTokenAddress = address(s_noToken);
        uint256 deadline = i_deadline;

        assembly {
            if gt(timestamp(),deadline){
                mstore(0x00, Market__BettingClosedErrorSelector)
                revert(0x00, 0x04)
            }
            if iszero(_betOutcome){
                mstore(0x00, Market__InvalidBetOutcomeErrorSelector)
                revert(0x00, 0x04)
            }

            sstore(s_balance.slot, add(sload(s_balance.slot), callvalue()))
         
            mstore(0x00, 0x36e59c31) // 0x36e59c31 = functioin selector of mint
            mstore(0x20, caller())
            mstore(0x40, callvalue())
            
            switch _betOutcome
            case 0 {revert(0, 0)}
            case 1 {pop(staticcall(gas(), s_yesTokenAddress, 0x1c, 0x44, 0x00, 0x00))}
            case 2 {pop(staticcall(gas(), s_noTokenAddress, 0x1c, 0x44, 0x00, 0x00))}

            log4(0x00, 0x00, BetPlacedEventTopic, caller(), _betOutcome, callvalue())
        }
    }

    /// @notice Resolves the market with the final outcome.
    /// @param _finalResolution The final outcome of the market.
    function resolve(outcomeType _finalResolution) external {
        address resolver = i_resolver;
        uint256 deadline = i_deadline;
        uint256 resolutionTime = i_resolutionTime;


        assembly{
            if not(eq(caller(), resolver)){
                mstore(0x00, Market__OnlyResolverCanResolveErrorSelector)
                revert(0x00, 0x04)
            }
            if lt(timestamp(), deadline){
                mstore(0x00, Market__ResolveTooEarlyErrorSelector)
                revert(0x00, 0x04)
            }
            if gt(timestamp(), add(deadline, resolutionTime)){
                mstore(0x00, Market__ResolveTooLateErrorSelector)
                revert(0x00, 0x04)
            }
            if sload(s_resolved.slot){
                mstore(0x00, Market__AlreadyResolvedErrorSelector)
                revert(0x00, 0x04)
            }

            sstore(s_finalResolution.slot, _finalResolution)
            sstore(s_resolvedDate.slot, timestamp())
            sstore(s_resolved.slot, 1)
            log3(0x00, 0x00, MarketResolvedEventTopic, _finalResolution, sload(s_resolvedDate.slot))
        }
    }

    /// @notice Distributes rewards to users based on the final outcome.
    /// @notice .transfer uses a limited amount of gas therefore there is no reentrancy risk.
    function distribute() external {
        require(s_resolved, Market__NotResolved());
        
        uint256 _rewardAmount;
        
        if (s_finalResolution != outcomeType.Neither) {
            Token token = s_finalResolution == outcomeType.Yes ? s_yesToken: s_noToken;
            uint256 _userBalance = token.balanceOf(msg.sender);
            require(_userBalance > 0, Market__NoTokensToClaim());
            _rewardAmount = s_balance * _userBalance / token.totalSupply();
            token.burnFrom(msg.sender, _userBalance);
        } else {
            uint256 _yesUserBalance = s_yesToken.balanceOf(msg.sender);
            uint256 _noUserBalance = s_noToken.balanceOf(msg.sender);
            require(_yesUserBalance + _noUserBalance > 0, Market__NoTokensToClaim());
            _rewardAmount =
                (s_balance * (_yesUserBalance + _noUserBalance)) / (s_yesToken.totalSupply() + s_noToken.totalSupply());

            if (_yesUserBalance > 0) s_yesToken.burnFrom(msg.sender, _yesUserBalance);
            if (_noUserBalance > 0) s_noToken.burnFrom(msg.sender, _noUserBalance);
        }
        payable(msg.sender).transfer(_rewardAmount);
        assembly{
            sstore(s_balance.slot, sub(sload(s_balance.slot), _rewardAmount))
            log3(0x00, 0x00, RewardsDistributedEventTopic, caller(), _rewardAmount)
        }
    }

    /// @notice Cancels the market due to inactivity.
    function inactivityCancel() external {
        uint256 deadline = i_deadline;
        uint256 resolutionTime = i_resolutionTime;

        assembly {
            if not(gt(timestamp(), add(deadline, resolutionTime))){
                mstore(0x00,Market__InactivityPeriodNotReachedErrorSelector)
                revert(0x00, 0x04)
            }
            if sload(s_resolved.slot){
                mstore(0x00, Market__AlreadyResolvedErrorSelector)
                revert(0x00, 0x04)
            }
            sstore(s_finalResolution.slot, 0)
            sstore(s_resolvedDate.slot, timestamp())
            sstore(s_resolved.slot, 1)
            log2(0x00, 0x00, MarketCancelledEventTopic, sload(s_resolvedDate.slot))
        }
        

    }

    /// @notice Returns all the details of the market.
    /// @return The details of the market as a tuple.
    function getMarketDetails()
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
            outcomeType,
            address,
            address
        )
    {
        return (
            i_router,
            i_marketId,
            s_balance,
            s_question,
            s_details,
            i_deadline,
            i_resolutionTime,
            i_resolver,
            s_resolved,
            s_resolvedDate,
            s_finalResolution,
            address(s_yesToken),
            address(s_noToken)
        );
    }

    fallback() external {
        revert();
    }
}
