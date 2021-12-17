// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IERC20.sol";

abstract contract BridgeBase is EIP712, Pausable, AccessControl {
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
    event TrustedValidatorGranted(
        address indexed sender,
        address trustedValidator
    );
    event TrustedValidatorRevoked(
        address indexed sender,
        address trustedValidator
    );

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    IERC20 public token;
    mapping(uint256 => bool) public offchainNonces;
    mapping(address => bool) public trustedValidators;
    mapping(address => mapping(uint256 => bool)) public isConfirmed;
    uint256 public nonce;
    uint256 public trustedValidatorCount;

    constructor(address _token) {
        require(_token != address(0), "token address cannot be zero");
        token = IERC20(_token);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function transferTokenToOnchain(
        address to,
        uint256 amount,
        uint256 offchainNonce,
        uint256 deadline,
        bytes[] calldata signatures
    ) external whenNotPaused {
        require(deadline > block.timestamp, "deadline");
        require(
            trustedValidatorCount >= 3,
            "require at least 3 trusted validators"
        );
        require(
            signatures.length > trustedValidatorCount / 2 + 1,
            "require at least half of trusted validators to be validated"
        );
        require(offchainNonces[offchainNonce] == false, "nonce already used");
        offchainNonces[offchainNonce] = true;

        address[] memory _validators = new address[](signatures.length);
        for (uint256 i = 0; i < signatures.length; i++) {
            bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "mint(address to,uint256 amount,uint256 nonce,uint256 deadline)"
                        ),
                        to,
                        amount,
                        offchainNonce,
                        deadline
                    )
                )
            );

            address signer = ECDSA.recover(digest, signatures[i]);
            require(
                trustedValidators[signer],
                "signer is not trusted validator"
            );
            require(
                !isConfirmed[signer][offchainNonce],
                "signer already confirmed"
            );
            isConfirmed[signer][offchainNonce] = true;
            _validators[i] = signer;
        }
        
        token.mint(to, amount);

        emit TransferTokenToOnchain(
            msg.sender,
            offchainNonce,
            to,
            amount,
            deadline,
            _validators
        );
    }

    function transferTokenToOffchain(uint256 amount) external whenNotPaused {
        token.burnFrom(msg.sender, amount);
        nonce++;

        emit TransferTokenToOffchain(msg.sender, nonce, amount);
    }

    function grantTrustedValidator(address _trustedValidator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            !trustedValidators[_trustedValidator],
            "trusted validator already granted"
        );
        trustedValidators[_trustedValidator] = true;
        trustedValidatorCount++;
        emit TrustedValidatorGranted(msg.sender, _trustedValidator);
    }

    function revokeTrustedValidator(address _trustedValidator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(trustedValidators[_trustedValidator], "trusted validator not found");
        trustedValidators[_trustedValidator] = false;
        trustedValidatorCount--;
        emit TrustedValidatorRevoked(msg.sender, _trustedValidator);
    }
}
