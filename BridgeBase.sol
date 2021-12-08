// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";

abstract contract BridgeBase is EIP712, Pausable, Ownable {
    
    event TransferTokenToOnchain(
        address indexed sender,
        uint256 indexed nonce,
        address indexed to,
        uint256 amount,
        uint256 deadline,
        address[] validators
    );
    event TransferTokenToOffchain(
        address indexed sender,
        uint256 indexed nonce,
        uint256 amount
    );
    event ValidatorAdded(address indexed sender,address validator);

    IERC20 public token;
    mapping(uint256 => bool) public offchainNonces;
    uint256 public nonce;
    address[] public validators;

    constructor(address _token) {
        require(_token != address(0), "token address cannot be zero");
        token = IERC20(_token);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function transferTokenToOnchain(
        address to,
        uint256 amount,
        uint256 offchainNonce,
        uint256 deadline,
        bytes[] calldata signatures
    ) external onlyOwner {
        require(deadline > block.timestamp, "deadline");
        require(signatures.length == validators.length && signatures.length > 0, "invalid signatures");
        require(offchainNonces[offchainNonce] == false, "nonce already used");
        offchainNonces[offchainNonce] = true;

        for (uint i = 0; i < signatures.length; i++) {

            bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
                keccak256("mint(address to,uint256 amount,uint256 nonce,address owner,uint256 deadline)"),
                to,
                amount,
                offchainNonce,
                validators[i],
                deadline
            )));
            
            address signer = ECDSA.recover(digest, signatures[i]);
            require(signer != address(0), "ECDSA: invalid signature");
            require(signer == validators[i], "ECDSA: invalid validator");
        }

        token.mint(to, amount);

        emit TransferTokenToOnchain(msg.sender,offchainNonce, to, amount, deadline, validators);
    }

    function transferTokenToOffchain(uint256 amount) external whenNotPaused {
        token.burnFrom(msg.sender, amount);
        nonce++;

        emit TransferTokenToOffchain(msg.sender, nonce, amount);
    }

    function addValidator(address validator) external onlyOwner {
        validators.push(validator);
        emit ValidatorAdded(msg.sender, validator);
    }

}