pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {Otr} from "../../src/Otr/Otr.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {Tippy} from "../../src/mock/Tippy.sol";
import {FloatiesRegistry} from "../../src/FloatiesRegistry.sol";
import {OtrProxy} from "../../src/Otr/OtrProxy.sol";
import {TippingToken} from "../../src/TippingToken/TippingToken.sol";

contract Run is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_PROD");
        vm.startBroadcast(deployerPrivateKey);
        address sender = vm.addr(deployerPrivateKey);
        Tippy tippy = new Tippy();
        Otr otr =  Otr(0x0181795609a431A8C39eF020ad58f20fE77E8525);
        IERC20(otr.PAYMENT_TOKEN()).approve(address(otr), 250_000 ether);

        // CHANGE THESE TWO VARIABLES
        address token = address(tippy);
        bytes memory sym = hex"245449505059";
        // ------

       address tippingToken = otr.register(token, sym, 0, address(0));
        IERC20(address(tippy)).approve(address(tippingToken), 10_000_000 ether);
        TippingToken(tippingToken).mint(10_000_000 ether);
    }
}

/*
    OTR: 0x0181795609a431A8C39eF020ad58f20fE77E8525
  */
