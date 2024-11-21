// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "lib/forge-std/src/Test.sol";
import "src/Token.sol";

contract TokenTest is Test {
    Token token;
    address deployer;
    address user1;

    function setUp() public {
        deployer = address(this);
        user1 = address(0x500);
        token = new Token("Test Token", "TTK");
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), 0);
    }

    function testDeployerCanMint(address user, uint256 amount) public {
        vm.assume(user != address(0x0));
        token.mint(user, amount);
        assertEq(token.totalSupply(), amount);
        assertEq(token.balanceOf(user), amount);
    }

    function testNonDeployerCannotMint(address nonDeployer, address user, uint256 amount) public {
        vm.assume(user != address(0x0) && nonDeployer != address(0x0));
        vm.assume(nonDeployer != deployer);
        vm.prank(nonDeployer);
        vm.expectRevert(Token.OnlyDeployerCanMint.selector);
        token.mint(user, amount);
    }

    function testBurn(address user, uint256 amount, uint256 burnAmount) public {
        vm.assume(user != address(0x0));
        token.mint(user, amount);
        vm.prank(user);
        if (burnAmount > amount) {
            vm.expectRevert();
            token.burn(burnAmount);
        } else {
            token.burn(burnAmount);
            assertEq(token.balanceOf(user), amount - burnAmount);
            assertEq(token.totalSupply(), amount - burnAmount);
        }
    }

    function testBurnFrom(address user, uint256 amount, uint256 burnAmount) public {
        vm.assume(user != address(0x0));
        token.mint(user, amount);
        vm.prank(user);
        token.approve(deployer, amount);
        if (burnAmount > amount) {
            vm.expectRevert();
            token.burnFrom(user, burnAmount);
        } else {
            token.burnFrom(user, burnAmount);
            assertEq(token.balanceOf(user), amount - burnAmount);
            assertEq(token.totalSupply(), amount - burnAmount);
        }
    }
}
