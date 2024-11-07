// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20Burnable, ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Token is ERC20Burnable {
    address private immutable i_deployer;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        i_deployer = msg.sender;
        // 1 token is minted to avoid potential divisions by 0
        _mint(msg.sender, 1);
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == i_deployer);
        _mint(to, amount);
    }
}
