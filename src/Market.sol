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
    error Market__ResolveTooEarly();
    error Market__ResolveTooLate();
    error Market__AlreadyResolved();
    error Market__NotResolved();
    error Market__NoTokensToClaim();
    error Market__InactivityPeriodNotReached();

    // Events
    event BetPlaced(address indexed user, outcomeType outcome, uint256 amount);
    event MarketResolved(outcomeType finalOutcome, uint256 resolvedDate);
    event RewardsDistributed(address indexed user, uint256 rewardAmount);
    event MarketCancelled(uint256 cancelledDate);

    // bytes32 constant BetPlacedEventTopic = 0x9d0a25ce916e80804f775f0493f1f2d81653bd094ead4388dbdf5ea28c35c8d2;
    // bytes32 constant MarketResolvedEventTopic = 0x55c41031e6fc864f2a00cf7433177f109b38f4ede57664c97dba0d7c138bffb4;
    // bytes32 constant MarketCancelledEventTopic = 0x9d0a25ce916e80804f775f0493f1f2d81653bd094ead4388dbdf5ea28c35c8d2;
    // bytes32 constant RewardsDistributedEventTopic = 0xdf29796aad820e4bb192f3a8d631b76519bcd2cbe77cc85af20e9df53cece086;

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
        require(block.timestamp < i_deadline, Market__BettingClosed());
        require(_betOutcome != outcomeType.Neither, Market__InvalidBetOutcome());
        assembly {
            sstore(s_balance.slot, add(sload(s_balance.slot), callvalue()))
        }
        if (_betOutcome == outcomeType.Yes) {
            s_yesToken.mint(msg.sender, msg.value);
        } else if (_betOutcome == outcomeType.No) {
            s_noToken.mint(msg.sender, msg.value);
        } else {
            revert();
        }
        emit BetPlaced(msg.sender, _betOutcome, msg.value);
        // assembly{
        //     log4(0x00, 0x00, BetPlacedEventTopic, caller(), _betOutcome, callvalue())
        // }
    }

    /// @notice Resolves the market with the final outcome.
    /// @param _finalResolution The final outcome of the market.
    function resolve(outcomeType _finalResolution) external {
        require(block.timestamp >= i_deadline, Market__ResolveTooEarly());
        require(block.timestamp <= i_deadline + i_resolutionTime, Market__ResolveTooLate());
        require(!s_resolved, Market__AlreadyResolved());

        s_finalResolution = _finalResolution;
        s_resolvedDate = block.timestamp;
        s_resolved = true;
        emit MarketResolved(_finalResolution, s_resolvedDate);
        // assembly{
        //     log3(0x00, 0x00, MarketResolvedEventTopic, _finalResolution, sload(s_resolvedDate.slot))
        // }
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
        s_balance -= _rewardAmount;
        emit RewardsDistributed(msg.sender, _rewardAmount);
    }

    /// @notice Cancels the market due to inactivity.
    function inactivityCancel() external {
        require(block.timestamp > i_deadline + i_resolutionTime, Market__InactivityPeriodNotReached());
        require(!s_resolved, Market__AlreadyResolved());

        assembly {
            sstore(s_finalResolution.slot, 0)
            sstore(s_resolvedDate.slot, timestamp())
            sstore(s_resolved.slot, 1)
            // log2(0x00, 0x00, MarketCancelledEventTopic, sload(s_resolvedDate.slot))
        }
        emit MarketCancelled(s_resolvedDate);
        

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
