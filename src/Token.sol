// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20Burnable, ERC20} from "lib/openzeppelin-solidity/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @title Token Contract
/// @notice A burnable ERC20 token with a deployer-controlled minting mechanism.
contract Token is ERC20Burnable {
    /// @notice Address of the deployer with exclusive minting rights.
    address private immutable i_deployer;

    /// @dev Custom error for unauthorized minting attempts.
    error OnlyDeployerCanMint();

    /**
     * @notice Constructor to initialize the token with a name, symbol, and a single minted token.
     * @dev Mints 1 token to the deployer upon deployment to prevent division by zero errors in token operations.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        i_deployer = msg.sender;
    }

    /**
     * @notice Mints a specified amount of tokens to a given address.
     * @dev This function can only be called by the deployer.
     * @param to The address to receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external {
        require(msg.sender == i_deployer, OnlyDeployerCanMint());
        _mint(to, amount);
    }

    fallback() external {
        revert();
    }
}
