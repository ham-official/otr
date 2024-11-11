// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract TippingTokenProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _initialOwner, bytes memory _data)
        TransparentUpgradeableProxy(_logic, _initialOwner, _data)
    {}
}
