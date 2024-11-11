pragma solidity 0.8.23;

import {ERC20} from "../ERC20.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

interface IFidMap {
    function fids(uint256 fid) external view returns (address);
    function ownerFid(address owner) external view returns (uint256);
}

contract TippingToken is ERC20, Owned, Initializable {
    address public tokenAddress;
    mapping(address => bool) public controller;
    mapping(uint256 => mapping(address => uint256)) public received;
    uint256 public nonce;

    error OnlyController();
    error AlreadyReceived();
    error Invalid();

    event ControllerUpdated(address controller, bool value);

    modifier onlyController() {
        if (!controller[msg.sender]) {
            revert OnlyController();
        }
        _;
    }

    constructor() ERC20("", "", 0) Owned(address(0)) {
        _disableInitializers();
    }

    function initialize(address _tokenAddress) public initializer {
        decimals = 18;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();

        tokenAddress = _tokenAddress;
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);

        nonce = 1;
        controller[msg.sender] = true;
        emit ControllerUpdated(msg.sender, true);
    }

    function name() public view override returns (string memory) {
        if (tokenAddress == address(0)) return "";
        try ERC20(tokenAddress).name() returns (string memory result) {
            return string.concat("t", result);
        } catch {
            return "";
        }
    }

    function symbol() public view override returns (string memory) {
        if (tokenAddress == address(0)) return "";
        try ERC20(tokenAddress).symbol() returns (string memory result) {
            return string.concat("t", result);
        } catch {
            return "";
        }
    }

    function updateController(address _controller, bool _value) public onlyOwner {
        controller[_controller] = _value;
        emit ControllerUpdated(_controller, _value);
    }

    event Convert(address indexed from, uint256 amount);

    function convert(uint256 amount) public {
        _burn(msg.sender, amount);
        ERC20(tokenAddress).transfer(msg.sender, amount);
        emit Convert(msg.sender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if (!controller[msg.sender]) {
            uint256 allowed = allowance[from][msg.sender];

            if (allowed != type(uint256).max) {
                allowance[from][msg.sender] = allowed - amount;
            }
        }

        balanceOf[from] -= amount;

        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function transferFromFid(uint256 fromFid, uint256 toFid, uint256 amount) public returns (bool) {
        IFidMap map = IFidMap(0xCca2e3e860079998622868843c9A00dEbb591D30);
        return transferFrom(map.fids(fromFid), map.fids(toFid), amount);
    }

    error MessagePaidError();

    function payMessage(
        address fromAddress,
        address toAddress,
        uint256 amount,
        uint256 fromId,
        uint256 toId,
        string memory messageId,
        string memory parentId,
        bool shouldRevert
    ) public onlyController {
        if (paidMessage[messageId]) {
            if (shouldRevert) {
                revert MessagePaidError();
            } else {
                return;
            }
        }
        if (fromAddress == address(0) || balanceOf[fromAddress] < amount || toAddress == address(0)) {
            if (shouldRevert) {
                revert Invalid();
            } else {
                return;
            }
        }
        paidMessage[messageId] = true;
        transferFrom(fromAddress, toAddress, amount);
        emit MessagePaid(fromId, toId, parentId, messageId, amount, fromAddress, toAddress);
    }

    function transferFromAddressToFid(
        address fromAddress,
        uint256 toFid,
        uint256 amount,
        string memory messageId,
        string memory parentId,
        bool shouldRevert
    ) public onlyController {
        if (paidMessage[messageId]) {
            if (shouldRevert) {
                revert MessagePaidError();
            } else {
                return;
            }
        }
        uint256 fromFid = IFidMap(0xCca2e3e860079998622868843c9A00dEbb591D30).ownerFid(fromAddress);
        address toAddress = IFidMap(0xCca2e3e860079998622868843c9A00dEbb591D30).fids(toFid);
        if (fromAddress == address(0) || balanceOf[fromAddress] < amount || toAddress == address(0)) {
            if (shouldRevert) {
                revert Invalid();
            } else {
                return;
            }
        }
        paidMessage[messageId] = true;
        transferFrom(fromAddress, toAddress, amount);
        emit MessagePaid(fromFid, toFid, parentId, messageId, amount, fromAddress, toAddress);
    }

    event MessagePaid(
        uint256 indexed fromSocialId,
        uint256 indexed toSocialId,
        string indexed parentId,
        string messageId,
        uint256 amount,
        address from,
        address to
    );

    function balanceOfFid(uint256 fid) public view returns (uint256) {
        return balanceOf[IFidMap(0xCca2e3e860079998622868843c9A00dEbb591D30).fids(fid)];
    }

    error InvalidAmountReceived();

    function mint(uint256 amount) public {
        uint256 balanceBefore = ERC20(tokenAddress).balanceOf(address(this));
        ERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        if (ERC20(tokenAddress).balanceOf(address(this)) - balanceBefore != amount) {
            revert InvalidAmountReceived();
        }
        _mint(msg.sender, amount);
    }

    function withdrawEth(uint256 amount) public onlyOwner {
        Address.sendValue(payable(owner), amount);
    }

    mapping(string => bool) public paidMessage;
}
