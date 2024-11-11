// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {IFloatiesRegistry} from "../interface/IFloatiesRegistry.sol";

interface IFidMap {
    function ownerFid(address _address) external view returns (uint256);
    function fids(uint256 fid) external view returns (address);
}

contract Otr is Owned, Initializable {
    address public PAYMENT_TOKEN;
    address public REGISTRY;
    address public FEE_RECEIVER;
    uint256 public REGISTRATION_FEE;
    uint256 public MAX_UI_FEE;

    constructor() Owned(address(0)) {
        _disableInitializers();
    }

    function initialize(address registry, address feeReceiver) public initializer {
        owner = msg.sender;
        PAYMENT_TOKEN = 0xE8DD44d0791B73afe9066C3A77721f42d0844bEB;
        REGISTRY = registry;
        REGISTRATION_FEE = 250_000 ether;
        FEE_RECEIVER = feeReceiver;
        MAX_UI_FEE = 1000;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    error FeeTooHigh();

    /// @notice Function used to register new tipping tokens
    /// @dev Sender must approve fee before calling this method
    /// @param tokenAddress ERC20 token that will be tipped. A new corresponding tipping token contract will be deployed for this token.
    /// @param tippingSymbolHash Hashed tipping symbol ie viem.toHex("$TIP")
    /// @param bpsFee Optional UI registration fee using basis points ie 10% = 1000
    /// @param feeRecipient Optional recipient of UI fee
    function register(address tokenAddress, bytes calldata tippingSymbolHash, uint256 bpsFee, address feeRecipient)
        public
        returns (address)
    {
        if (bpsFee > MAX_UI_FEE) {
            revert FeeTooHigh();
        }
        uint256 fee = REGISTRATION_FEE * bpsFee / 10_000;
        uint256 costMinusFee = REGISTRATION_FEE - fee;
        IERC20(PAYMENT_TOKEN).transferFrom(msg.sender, FEE_RECEIVER, costMinusFee);
        if (fee > 0) {
            IERC20(PAYMENT_TOKEN).transferFrom(msg.sender, feeRecipient, fee);
        }
        address tippingToken = IFloatiesRegistry(REGISTRY).register(
            IFloatiesRegistry.RegistrationParams({
                token: tokenAddress,
                registrant: tokenAddress,
                floatyHash: tippingSymbolHash
            })
        );

        return tippingToken;
    }
}
