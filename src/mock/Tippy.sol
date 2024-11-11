pragma solidity 0.8.23;

import {ERC20} from "../ERC20.sol";

contract Tippy is ERC20 {
    constructor() ERC20("TIPPY", "TIPPY", 18) {
        _mint(msg.sender, 10_000_000_000 ether);
    }
}
