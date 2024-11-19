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
        user1 = address(0x1);
        token = new Token("Test Token", "TTK");
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), 1); // initial mint of 1 token to deployer
        assertEq(token.balanceOf(deployer), 1);
    }

    function testDeployerCanMint() public {
        token.mint(user1, 1000);
        assertEq(token.totalSupply(), 1001);
        assertEq(token.balanceOf(user1), 1000);
    }

    function testNonDeployerCannotMint(address nonDeployer) public {
        vm.assume(nonDeployer != deployer);
        vm.prank(nonDeployer);
        vm.expectRevert(Token.OnlyDeployerCanMint.selector);
        token.mint(user1, 1000);
    }

    function testBurn() public {
        token.mint(user1, 1000);
        vm.prank(user1);
        token.burn(500);
        assertEq(token.balanceOf(user1), 500);
        assertEq(token.totalSupply(), 501); // 1 initial + 1000 - 500 burned
    }

    function testBurnFrom() public {
        token.mint(user1, 1000);
        vm.prank(user1);
        token.approve(deployer, 500);
        token.burnFrom(user1, 500);
        assertEq(token.balanceOf(user1), 500);
        assertEq(token.totalSupply(), 501);
    }
}
