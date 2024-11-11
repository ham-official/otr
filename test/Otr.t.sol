// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IFloatiesRegistry} from "../src/interface/IFloatiesRegistry.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {Otr} from "../src/Otr/Otr.sol";
import {OtrProxy} from "../src/Otr/OtrProxy.sol";

contract OtrTest is Test {
    IFloatiesRegistry floatiesRegistry = IFloatiesRegistry(0xddbdb3d1cd151c65Eff370f09578Cd8FdA6535E3);
    IERC20 tn100x = IERC20(0xE8DD44d0791B73afe9066C3A77721f42d0844bEB);
    address deployer = 0x16760803046fFa4D05878333B0953bBDDc0C20Cb;
    address dead = 0x000000000000000000000000000000000000dEaD;
    address feeReceiver = address(69);
    bytes tippingSymbol = hex"24544950";
    Otr otr;

    function setUp() public {
        vm.deal(deployer, 1 ether);
        vm.deal(dead, 1 ether);
        vm.startPrank(deployer);
        
        Otr otrImplementation = new Otr();
        OtrProxy otrProxy = new OtrProxy(
            address(otrImplementation),
            deployer,
            abi.encodeWithSelector(
                Otr.initialize.selector,
                address(floatiesRegistry),
                feeReceiver
            )
        );
        otr = Otr(address(otrProxy));
        floatiesRegistry.updateWl(address(otr), true);
        vm.stopPrank();
    }

    function testRegister() public {
        address sender = address(420);
        vm.deal(sender, 1 ether);
        vm.prank(dead);
        tn100x.transfer(sender, 250_000 ether);

        vm.startPrank(sender);
        tn100x.approve(address(otr), 250_000 ether);
        address madeUpTokenAddress = address(111);
        uint balance = tn100x.balanceOf(sender);
        assertEq(balance, 250_000 ether);
        otr.register(madeUpTokenAddress, tippingSymbol, 0, address(0));

        // Expect balance of sender to be 0
        balance = tn100x.balanceOf(sender);
        assertEq(balance, 0);

        // Expect balance of vault to contain fee
        balance = tn100x.balanceOf(feeReceiver);
        assertEq(balance, 250_000 ether);
    }

    function testRegisterWithFee() public {
        address sender = address(420);
        vm.deal(sender, 1 ether);
        vm.prank(dead);
        tn100x.transfer(sender, 250_000 ether);
        vm.startPrank(sender);
        tn100x.approve(address(otr), 250_000 ether);
        address madeUpTokenAddress = address(111);
        address uiFeeReceiver = address(222);
        otr.register(madeUpTokenAddress, tippingSymbol, 1000, uiFeeReceiver);

        // Expect balance of sender to be 0
        uint balance = tn100x.balanceOf(sender);
        assertEq(balance, 0);

        // Expect balance of vault to contain fee
        balance = tn100x.balanceOf(feeReceiver);
        assertEq(balance, 250_000 ether - 25_000 ether);

        // Expect ui fee receiver to have gotten fee
        balance = tn100x.balanceOf(uiFeeReceiver);
        assertEq(balance, 25_000 ether);
    }

    function testThrowIfFeeTooHigh() public {
        address sender = address(420);
        vm.deal(sender, 1 ether);
        vm.prank(dead);
        tn100x.transfer(sender, 250_000 ether);
        vm.startPrank(sender);
        tn100x.approve(address(otr), 250_000 ether);
        address madeUpTokenAddress = address(111);
        address uiFeeReceiver = address(222);
        vm.expectRevert(Otr.FeeTooHigh.selector);
        otr.register(madeUpTokenAddress, tippingSymbol, 1001, uiFeeReceiver);
    }
}

// forge test --fork-url https://rpc.ham.fun --match-path ./test/Otr.t.sol -vvvv
