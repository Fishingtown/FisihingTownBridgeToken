// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";

contract BridgeBase is Ownable {

    event Mint(
        address indexed sender,
        uint256 indexed id,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );

    IERC20 public token;
    mapping(uint256 => bool) public nonces;

    constructor(address _token) {
        require(_token != address(0), "token address cannot be zero");

        token = IERC20(_token);
    }

    function mint(
        uint256 nonce,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(nonces[nonce] == false, "nonce already used");
        nonces[nonce] = true;
        token.mint(to, amount);
        emit Mint(msg.sender, nonce, to, amount, block.timestamp);
    }

}
